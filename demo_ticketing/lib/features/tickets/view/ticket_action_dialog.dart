import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/money.dart';
import '../../../core/printer/print_service.dart';
import '../../../core/printer/ticket_view.dart' show groupGateCode;
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../home/view/message_box.dart';
import '../../sell/data/sell_draft.dart';
import '../bloc/ticket_action_cubit.dart';
import '../data/ticket_lookup.dart';
import '../data/ticket_repository.dart';
import 'ticket_messages.dart';

/// Ticket action dialog (`Approval.dc.html`): reprint, reactivate or void &
/// refund, with a required reason and the limits shown. No supervisor login
/// (ADR-0009): the server enforces the limits and logs the action.
///
/// Differs from the design:
/// - an action the server says is blocked is disabled, and the reason shows
///   under the buttons;
/// - the refund box says how to hand the money back: cash, or back to the
///   card or wallet the order was paid with;
/// - after a reprint the dialog shows its copy printing, with Retry if that
///   print fails (the copy is logged once, ADR-0023's reasoning).
class TicketActionDialog extends StatelessWidget {
  const TicketActionDialog({super.key, required this.settings});

  final TicketActionSettings settings;

  /// The dialog for [ticket], starting on [initial] when it is allowed, else
  /// on the first allowed action. Pops the outcome, or null when nothing was
  /// done.
  static Future<TicketActionOutcome?> show(
    BuildContext context, {
    required TicketLookup ticket,
    required TicketActionSettings settings,
    required TicketPrintSetup setup,
    required TicketAction initial,
    ReprintedTicket Function(ActionReason reason, String? text)? queuedReprint,
  }) {
    final start = ticket.can(initial)
        ? initial
        : TicketAction.values.firstWhere(ticket.can, orElse: () => initial);
    return showDialog<TicketActionOutcome>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider(
        create: (_) => TicketActionCubit(
          repository: context.read<TicketRepository>(),
          printer: context.read<PrintService>(),
          ticket: ticket,
          setup: setup,
          initial: start,
          queuedReprint: queuedReprint,
        ),
        child: TicketActionDialog(settings: settings),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final cubit = context.read<TicketActionCubit>();
    final ticket = cubit.ticket;

    return BlocListener<TicketActionCubit, TicketActionState>(
      listenWhen: (previous, current) => previous.outcome == null && current.outcome != null,
      listener: (context, state) => Navigator.of(context).pop(state.outcome),
      child: BlocBuilder<TicketActionCubit, TicketActionState>(
        builder: (context, state) {
          final busy = state.submitting || state.print == ReprintPrint.printing;
          final allowance = ticket.allowance(state.action);
          final color = state.action == TicketAction.voidRefund ? tokens.dangerAction : tokens.primary;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            insetPadding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Title(ticket: ticket, enabled: !busy && state.reprinted == null),
                    const SizedBox(height: 20),
                    Text(l10n.actionLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final (i, action) in [
                          TicketAction.reactivate,
                          TicketAction.reprint,
                          TicketAction.voidRefund,
                        ].indexed) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: _ActionButton(
                              key: ValueKey('action-${action.key}'),
                              label: ticketActionName(l10n, action),
                              selected: action == state.action,
                              color: action == TicketAction.voidRefund
                                  ? tokens.dangerAction
                                  : tokens.primary,
                              onPressed: ticket.can(action) && !busy && !state.logged
                                  ? () => cubit.pickAction(action)
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _help(l10n, state.action),
                      style: TextStyle(fontSize: 14, color: tokens.textSecondary),
                    ),
                    for (final action in TicketAction.values)
                      if (ticket.allowance(action).blockedBy case final blocked?) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.actionBlocked(
                            ticketActionName(l10n, action),
                            ticketFailureMessage(l10n, blocked),
                          ),
                          key: ValueKey('blocked-${action.key}'),
                          style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                        ),
                      ],
                    const SizedBox(height: 20),
                    _LimitBox(
                      text: _limit(l10n, state.action),
                      warning: state.action == TicketAction.voidRefund,
                    ),
                    if (state.action == TicketAction.voidRefund) ...[
                      const SizedBox(height: 20),
                      _RefundBox(amountPiastres: ticket.pricePiastres, method: ticket.paymentMethod),
                    ],
                    const SizedBox(height: 20),
                    if (state.reprinted == null)
                      // Keyed by action: a new action starts with an empty note.
                      _ReasonInput(
                        key: ValueKey(state.action),
                        state: state,
                        enabled: allowance.allowed && !busy,
                      )
                    else
                      _CopyStatus(print: state.print),
                    if (state.failure case final failure?) ...[
                      const SizedBox(height: 16),
                      MessageBox.danger(message: ticketFailureMessage(l10n, failure)),
                    ],
                    const SizedBox(height: 20),
                    if (state.print == ReprintPrint.failed)
                      _Buttons(
                        backLabel: l10n.actionCloseCopy,
                        onBack: cubit.giveUpPrint,
                        confirmLabel: l10n.retry,
                        confirmColor: tokens.primary,
                        onConfirm: cubit.retryPrint,
                      )
                    else
                      _Buttons(
                        backLabel: l10n.cancelDialogKeep,
                        onBack: busy || state.logged ? null : () => Navigator.of(context).pop(),
                        confirmLabel: _confirm(l10n, state.action, ticket.pricePiastres),
                        confirmColor: color,
                        onConfirm: allowance.allowed && !busy && !state.logged ? cubit.submit : null,
                        busy: busy,
                      ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.actionFootnote,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static String _help(AppLocalizations l10n, TicketAction action) => switch (action) {
        TicketAction.reactivate => l10n.actionHelpReactivate,
        TicketAction.reprint => l10n.actionHelpReprint,
        TicketAction.voidRefund => l10n.actionHelpVoidRefund,
      };

  String _limit(AppLocalizations l10n, TicketAction action) => switch (action) {
        TicketAction.reactivate =>
          l10n.actionLimitReactivate(settings.reactivationMax, settings.reactivationWindowMin),
        TicketAction.reprint => l10n.actionLimitReprint,
        TicketAction.voidRefund => switch ((settings.refundBeforeScanOnly, settings.refundSameShiftOnly)) {
            (true, true) => l10n.actionLimitRefundBoth,
            (true, false) => l10n.actionLimitRefundBeforeScan,
            (false, true) => l10n.actionLimitRefundSameShift,
            (false, false) => l10n.actionLimitRefundAny,
          },
      };

  static String _confirm(AppLocalizations l10n, TicketAction action, int pricePiastres) =>
      switch (action) {
        TicketAction.reactivate => l10n.actionConfirmReactivate,
        TicketAction.reprint => l10n.actionConfirmReprint,
        TicketAction.voidRefund => l10n.actionConfirmVoidRefund(formatMoney(l10n, pricePiastres)),
      };
}

class _Title extends StatelessWidget {
  const _Title({required this.ticket, required this.enabled});

  final TicketLookup ticket;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.actionDialogTitle, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${l10n.actionDialogTicket(ticket.name(l10n.localeName))} · '),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Text(
                        groupGateCode(ticket.gateCode),
                        textDirection: TextDirection.ltr,
                        style: TextStyle(fontSize: 14, color: tokens.textSecondary),
                      ),
                    ),
                    TextSpan(text: ' · ${l10n.actionDialogOrder(ticket.orderNumber)}'),
                  ],
                ),
                style: TextStyle(fontSize: 14, color: tokens.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.close,
          onPressed: enabled ? () => Navigator.of(context).pop() : null,
          icon: const Icon(Icons.close),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    required this.selected,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      selected: selected,
      child: SizedBox(
        height: 52,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            backgroundColor: selected ? color : tokens.surface,
            foregroundColor: selected ? tokens.surface : tokens.text,
            disabledForegroundColor: selected ? tokens.surface : tokens.textSecondary,
            disabledBackgroundColor: selected ? color.withValues(alpha: 0.5) : tokens.inset,
            side: BorderSide(color: selected ? color : tokens.border, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          child: Text(label, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

class _LimitBox extends StatelessWidget {
  const _LimitBox({required this.text, required this.warning});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final foreground = warning ? tokens.warningText : tokens.onPrimaryTint;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: warning ? tokens.warningBg : tokens.primaryTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: foreground),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: foreground))),
        ],
      ),
    );
  }
}

/// The money to hand back: the ticket's own price, never an order total
/// (ADR-0008).
class _RefundBox extends StatelessWidget {
  const _RefundBox({required this.amountPiastres, required this.method});

  final int amountPiastres;
  final PaymentMethod? method;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: tokens.dangerBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              refundHowText(l10n, method),
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tokens.dangerText),
            ),
          ),
          Text(
            formatMoney(l10n, amountPiastres),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tokens.dangerText),
          ),
        ],
      ),
    );
  }
}

/// How a refund goes back: cash from the drawer, or to the card or wallet.
String refundHowText(AppLocalizations l10n, PaymentMethod? method) => switch (method) {
      PaymentMethod.card => l10n.refundToCard,
      PaymentMethod.wallet => l10n.refundToWallet,
      PaymentMethod.cash || null => l10n.refundInCash,
    };

class _ReasonInput extends StatefulWidget {
  const _ReasonInput({super.key, required this.state, required this.enabled});

  final TicketActionState state;
  final bool enabled;

  @override
  State<_ReasonInput> createState() => _ReasonInputState();
}

class _ReasonInputState extends State<_ReasonInput> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final cubit = context.read<TicketActionCubit>();
    final state = widget.state;
    final other = state.reason == ActionReason.other;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.actionReasonLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final reason in ActionReason.forAction(state.action))
              _ReasonChip(
                key: ValueKey('reason-${reason.key}'),
                label: actionReasonName(l10n, reason),
                selected: reason == state.reason,
                onPressed: widget.enabled ? () => cubit.pickReason(reason) : null,
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const ValueKey('action-reason-text'),
          controller: _text,
          enabled: widget.enabled,
          minLines: 2,
          maxLines: 3,
          maxLength: 200,
          onChanged: cubit.setText,
          decoration: InputDecoration(
            labelText: other ? l10n.actionReasonTextRequiredLabel : l10n.actionReasonNoteLabel,
            errorText: state.textMissing ? l10n.actionReasonTextRequired : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: other ? tokens.primary : tokens.inputBorder),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReasonChip extends StatelessWidget {
  const _ReasonChip({super.key, required this.label, required this.selected, required this.onPressed});

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      selected: selected,
      child: SizedBox(
        height: 44,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            backgroundColor: selected ? tokens.text : tokens.surface,
            foregroundColor: selected ? tokens.surface : tokens.text,
            disabledForegroundColor: selected ? tokens.surface : tokens.textSecondary,
            disabledBackgroundColor: selected ? tokens.textSecondary : tokens.surface,
            side: BorderSide(color: selected ? tokens.text : tokens.inputBorder),
            shape: const StadiumBorder(),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

/// After the reprint is logged: its copy printing, printed or failed.
class _CopyStatus extends StatelessWidget {
  const _CopyStatus({required this.print});

  final ReprintPrint print;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (print == ReprintPrint.failed) {
      return MessageBox.warning(message: l10n.actionCopyFailed);
    }
    return Row(
      children: [
        const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        const SizedBox(width: 12),
        Expanded(child: Text(l10n.actionCopyPrinting)),
      ],
    );
  }
}

class _Buttons extends StatelessWidget {
  const _Buttons({
    required this.backLabel,
    required this.onBack,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
    this.busy = false,
  });

  final String backLabel;
  final VoidCallback? onBack;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback? onConfirm;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: onBack,
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              child: Text(backLabel),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 56,
            child: FilledButton(
              key: const ValueKey('action-confirm'),
              onPressed: onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: confirmColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              child: busy
                  ? SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: tokens.surface),
                    )
                  : Text(confirmLabel),
            ),
          ),
        ),
      ],
    );
  }
}
