import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/connectivity/server_status_cubit.dart';
import '../../../core/money.dart';
import '../../../core/printer/ticket_view.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../home/view/app_header.dart';
import '../../home/view/message_box.dart';
import '../../offline/bloc/offline_sync_cubit.dart';
import '../../offline/data/offline_store.dart';
import '../../offline/view/offline_banner.dart';
import '../../shift/bloc/shift_cubit.dart';
import '../../tickets/bloc/ticket_action_cubit.dart';
import '../../tickets/data/ticket_lookup.dart';
import '../../tickets/view/open_ticket_actions.dart';
import '../../tickets/view/ticket_action_dialog.dart' show TicketActionDialog, refundHowText;
import '../bloc/checkout_cubit.dart';
import '../bloc/sell_cubit.dart';
import '../data/sell_draft.dart';
import '../data/sold_order.dart';
import 'sell_messages.dart';

/// Order review (`Printed.dc.html`): the order is paid and its tickets are
/// active; each ticket's print, with a retry for those that failed.
///
/// Differs from the design:
/// - Reprint is on each printed ticket's row, not one button at the bottom:
///   an order has several tickets. It opens the action dialog (2.6), where a
///   reprint needs a reason and is logged (ADR-0009). Retry is not a
///   reprint: that copy never printed (ADR-0023);
/// - a failed ticket can also be void-refunded from its row, for a customer
///   who won't wait for the printer;
/// - a failed print says "print failed": raw TCP can't tell paper-out from
///   another fault;
/// - New order waits until every ticket has had its print. With a failed
///   print it asks first: retry, or leave anyway with a reason, which is
///   logged for a supervisor (ADR-0024);
/// - New order sits in a bar fixed at the bottom, as on the payment screen,
///   so a long order never pushes it out of view;
/// - an offline order (2.8, ADR-0015; no design) is titled as one;
/// - while offline, or before an offline order has uploaded (ADR-0026), Reprint
///   and "Leave anyway" go in the counter's queue, and Void & refund is
///   disabled: it needs the server.
class ReviewView extends StatelessWidget {
  const ReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final checkout = context.read<CheckoutCubit>();
    final state = context.watch<CheckoutCubit>().state;
    final order = state.order;
    if (order == null) return const SizedBox.shrink();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final shift = context.watch<ShiftCubit>().state;
    final busy = state.printing || state.submitting;
    // Rebuilds when the server goes away or the order uploads.
    context.select((ServerStatusCubit cubit) => cubit.isOffline);
    context.select((OfflineSyncCubit cubit) => cubit.state.queue.unsyncedOrders);
    final serverHasIt = _serverHasOrder(context, order);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () => _newOrder(context),
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () => _newOrder(context),
      },
      // A scope, not a plain Focus: on Windows a mouse click outside a text
      // field unfocuses it to the nearest scope. Here that is this one, under
      // the shortcuts, so Enter / F12 / Esc keep working.
      child: FocusScope(
        autofocus: true,
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeader(
                title: order.offline
                    ? l10n.reviewTitleOffline(order.number)
                    : l10n.reviewTitle(order.number),
                subtitle: switch (shift) {
                  ShiftOpen(:final shift) => l10n.reviewSubtitle(
                    shift.counterName,
                    shift.number,
                    DateFormat.Hm(locale).format(order.createdAt),
                  ),
                  _ => '',
                },
              ),
              const OfflineBanner(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 880),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _Banner(),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                            decoration: BoxDecoration(
                              color: tokens.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: tokens.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  l10n.reviewTickets,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                                for (final (index, ticket) in order.tickets.indexed) ...[
                                  const SizedBox(height: 10),
                                  _TicketRow(
                                    key: ValueKey('ticket-row-$index'),
                                    index: index,
                                    typeName: ticket.name(l10n.localeName),
                                    gateCode: ticket.gateCode,
                                    status: state.prints[index],
                                    enabled: !busy,
                                    refundAllowed: serverHasIt,
                                    onRetry: () => checkout.retry(index),
                                    onAction: (action) => _act(context, index, action),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Text(
                                  serverHasIt ? l10n.reviewReprintNote : l10n.reviewOfflineNote,
                                  style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Always in view, as on the payment screen.
              Container(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 10),
                decoration: BoxDecoration(
                  color: tokens.surface,
                  border: Border(top: BorderSide(color: tokens.border)),
                ),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 880),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.failure case final failure?) ...[
                          MessageBox.danger(message: sellFailureMessage(l10n, failure)),
                          const SizedBox(height: 10),
                        ],
                        SizedBox(
                          height: 60,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Every failed ticket again in one press (no
                              // server call, ADR-0023), e.g. after the
                              // printer was off for the whole order.
                              if (state.failedCount > 0) ...[
                                Expanded(
                                  child: OutlinedButton(
                                    key: const ValueKey('review-retry-all'),
                                    onPressed: busy ? null : checkout.retryFailed,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: tokens.primary,
                                      side: BorderSide(color: tokens.primary, width: 2),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    child: Text(l10n.retryAllFailed(state.failedCount)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                  key: const ValueKey('review-new-order'),
                                  onPressed: busy ? null : () => _newOrder(context),
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: state.submitting
                                      ? SizedBox.square(
                                          dimension: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: tokens.surface,
                                          ),
                                        )
                                      : Text(l10n.newOrder),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.reviewShortcutsHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Whether server calls can reach this order's tickets now: the server
  /// answers, and has the order (an offline one once it uploaded).
  static bool _serverHasOrder(BuildContext context, SoldOrder order) =>
      !context.read<ServerStatusCubit>().isOffline &&
      (!order.offline || context.read<OfflineStore>().orderOnServer(order.id));

  /// New order, or with a failed print the question first: retry, or leave
  /// anyway with a reason (ADR-0024).
  static Future<void> _newOrder(BuildContext context) async {
    final checkout = context.read<CheckoutCubit>();
    final state = checkout.state;
    if (state.printing || state.submitting) return;
    final failed = state.failedCount;
    if (failed == 0) return checkout.finish();
    // Logged on the server (ADR-0024), or in the queue (ADR-0026) while offline
    // and for an offline order, whose ticket ids the app doesn't have.
    final queued =
        (state.order?.offline ?? false) || context.read<ServerStatusCubit>().isOffline;
    final shift = context.read<ShiftCubit>().state;
    final choice = await showDialog<_UnprintedChoice>(
      context: context,
      builder: (context) => _UnprintedDialog(count: failed, queued: queued),
    );
    if (!context.mounted) return;
    switch (choice) {
      case null:
        return;
      case _Retry():
        await checkout.retryFailed();
      case _Leave(:final reason, :final text):
        await checkout.leaveUnprinted(
          reason,
          reasonText: text,
          queueInShift: queued && shift is ShiftOpen ? shift.shift.id : null,
        );
        if (queued && context.mounted) context.read<OfflineSyncCubit>().refresh();
    }
  }

  /// A printed ticket's Reprint, or a failed ticket's Void & refund: the
  /// action dialog, after a fresh lookup. When the server can't be asked about
  /// this order, a reprint goes in the queue instead (ADR-0026).
  static Future<void> _act(BuildContext context, int index, TicketAction action) async {
    final checkout = context.read<CheckoutCubit>();
    final order = checkout.state.order;
    if (order == null) return;
    final sell = context.read<SellCubit>().state;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final setup = TicketPrintSetup(
      venueName: sell.settings?.venueName ?? '',
      printer: sell.printerTarget,
    );
    final shift = context.read<ShiftCubit>().state;
    final TicketActionOutcome? outcome;
    if (_serverHasOrder(context, order)) {
      outcome = await openTicketActions(
        context,
        code: order.tickets[index].gateCode,
        setup: setup,
        initial: action,
      );
    } else {
      if (action != TicketAction.reprint || shift is! ShiftOpen) return;
      final auth = context.read<AuthCubit>().state;
      final store = context.read<OfflineStore>();
      final ticket = order.tickets[index];
      final sync = context.read<OfflineSyncCubit>();
      outcome = await TicketActionDialog.show(
        context,
        ticket: TicketLookup.queued(
          order: order,
          ticket: ticket,
          paymentMethod: checkout.state.payment?.method,
          soldByName: auth is AuthSignedIn ? auth.staff.fullName : '',
          counterName: shift.shift.counterName,
          printCount: 1 + store.queuedReprints(order.id, int.parse(ticket.gateCode)),
        ),
        settings: TicketActionSettings.reprintOnly,
        setup: setup,
        initial: TicketAction.reprint,
        queuedReprint: (reason, text) =>
            checkout.queueReprint(index, reason, reasonText: text, shiftId: shift.shift.id),
      );
      sync.refresh();
    }
    if (outcome == null) return;
    final message = switch (outcome.action) {
      TicketAction.voidRefund => l10n.outcomeRefunded(
          refundHowText(l10n, outcome.refund?.method),
          formatMoney(l10n, outcome.refund?.amountPiastres ?? 0),
        ),
      TicketAction.reprint => outcome.printed ? l10n.outcomeReprinted : l10n.outcomeReprintNotPrinted,
      TicketAction.reactivate => l10n.outcomeReactivated,
    };
    if (outcome.action == TicketAction.voidRefund) checkout.markRefunded(index);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Paid and printed, still printing, some tickets failed, some or all
/// refunded from the review, or some left unprinted; and the change.
class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final state = context.watch<CheckoutCubit>().state;
    final payment = state.payment;
    if (payment == null) return const SizedBox.shrink();
    final failed = state.failedCount;
    final refunded = state.refundedCount;
    final allRefunded = refunded > 0 && refunded == state.prints.length;
    final (title, subtitle) = state.printing
        ? (l10n.reviewPrintingTitle, l10n.printStatusHint)
        : failed > 0
        ? (l10n.printStatusFailed(failed), l10n.reviewFailedSubtitle)
        : allRefunded
        ? (l10n.reviewAllRefundedTitle(refunded), l10n.reviewAllRefundedSubtitle(refunded))
        : refunded > 0
        ? (
            l10n.reviewPaidShortTitle,
            l10n.reviewPartlyRefundedSubtitle(state.prints.length - refunded, refunded),
          )
        : state.leftCount > 0
        ? (l10n.reviewPaidShortTitle, l10n.reviewLeftSubtitle(state.printedCount, state.leftCount))
        : (
            l10n.reviewPaidTitle,
            l10n.reviewPaidSubtitle(
              state.printedCount,
              formatMoney(l10n, payment.totalPiastres),
              paymentMethodName(l10n, payment.method),
            ),
          );
    final (background, border, foreground, icon) = state.printing || (failed == 0 && !allRefunded)
        ? (
            tokens.successBg,
            tokens.successDot.withValues(alpha: 0.35),
            tokens.successText,
            tokens.successDot,
          )
        : allRefunded
        ? (tokens.dangerBg, tokens.dangerAction.withValues(alpha: 0.35), tokens.dangerText, tokens.dangerAction)
        : (tokens.warningBg, tokens.warningBorder, tokens.warningText, tokens.warningText);
    final iconData = state.printing
        ? Icons.check
        : failed > 0
        ? Icons.priority_high
        : allRefunded
        ? Icons.close
        : Icons.check;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: icon, shape: BoxShape.circle),
                  child: Icon(
                    iconData,
                    key: const ValueKey('review-banner-icon'),
                    size: 28,
                    color: tokens.surface,
                  ),
                ),
                const SizedBox(width: 14),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: foreground,
                        ),
                      ),
                      Text(subtitle, style: TextStyle(fontSize: 15, color: foreground)),
                    ],
                  ),
                ),
              ],
            ),
            if (payment.method == PaymentMethod.cash)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    l10n.changeLabel,
                    style: TextStyle(fontSize: 14, color: tokens.textSecondary),
                  ),
                  Text(
                    formatMoney(l10n, payment.changePiastres),
                    key: const ValueKey('review-change'),
                    style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({
    super.key,
    required this.index,
    required this.typeName,
    required this.gateCode,
    required this.status,
    required this.enabled,
    required this.refundAllowed,
    required this.onRetry,
    required this.onAction,
  });

  final int index;
  final String typeName;
  final String gateCode;
  final TicketPrintStatus status;

  /// False while a print or a call runs.
  final bool enabled;

  /// Void & refund needs the server to have the order. Reprint always works:
  /// it goes in the queue otherwise.
  final bool refundAllowed;
  final VoidCallback onRetry;
  final void Function(TicketAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final failed = status == TicketPrintStatus.failed;
    final (label, background, foreground) = switch (status) {
      TicketPrintStatus.printed => (l10n.ticketPrinted, tokens.successBg, tokens.successText),
      TicketPrintStatus.failed => (l10n.ticketPrintFailed, tokens.dangerBg, tokens.dangerText),
      TicketPrintStatus.printing => (l10n.ticketPrinting, tokens.primaryTint, tokens.onPrimaryTint),
      TicketPrintStatus.waiting => (l10n.ticketWaiting, tokens.inset, tokens.textSecondary),
      TicketPrintStatus.refunded => (l10n.ticketRefunded, tokens.dangerBg, tokens.dangerText),
      TicketPrintStatus.left => (l10n.ticketLeftUnprinted, tokens.warningBg, tokens.warningText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.inset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: failed ? tokens.dangerAction.withValues(alpha: 0.4) : tokens.border,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 96),
                child: Text(
                  typeName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                groupGateCode(gateCode),
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 15,
                  color: tokens.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: foreground),
                ),
              ),
              if (status == TicketPrintStatus.printed) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  key: ValueKey('ticket-reprint-$index'),
                  onPressed: enabled ? () => onAction(TicketAction.reprint) : null,
                  child: Text(l10n.reprint),
                ),
              ],
              if (failed) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  key: ValueKey('ticket-refund-$index'),
                  onPressed:
                      enabled && refundAllowed ? () => onAction(TicketAction.voidRefund) : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.dangerAction,
                    side: BorderSide(color: tokens.dangerAction.withValues(alpha: 0.4)),
                  ),
                  child: Text(l10n.actionVoidRefund),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  key: ValueKey('ticket-retry-$index'),
                  onPressed: enabled ? onRetry : null,
                  child: Text(l10n.retry),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// What the cashier chose on [_UnprintedDialog].
sealed class _UnprintedChoice {
  const _UnprintedChoice();
}

class _Retry extends _UnprintedChoice {
  const _Retry();
}

class _Leave extends _UnprintedChoice {
  const _Leave(this.reason, this.text);

  final LeaveReason reason;
  final String? text;
}

/// New order with tickets that never printed: once the order is left their
/// codes are on no paper, so nothing can print them. Retry, or leave anyway
/// with a reason, which is logged and flagged (ADR-0024). No reason is
/// picked at first: the cashier must say which.
class _UnprintedDialog extends StatefulWidget {
  const _UnprintedDialog({required this.count, required this.queued});

  final int count;

  /// The leave goes in the offline queue, not to the server (ADR-0026).
  final bool queued;

  @override
  State<_UnprintedDialog> createState() => _UnprintedDialogState();
}

class _UnprintedDialogState extends State<_UnprintedDialog> {
  LeaveReason? _reason;
  final _text = TextEditingController();
  var _textMissing = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _leave() {
    final reason = _reason;
    if (reason == null) return;
    final text = _text.text.trim();
    if (reason == LeaveReason.other && text.isEmpty) {
      return setState(() => _textMissing = true);
    }
    Navigator.of(context).pop(_Leave(reason, text.isEmpty ? null : text));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return AlertDialog(
      title: Text(l10n.unprintedDialogTitle(widget.count)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.unprintedDialogBody, style: TextStyle(color: tokens.textSecondary)),
              const SizedBox(height: 12),
              Text(
                l10n.unprintedDialogReason,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              RadioGroup<LeaveReason>(
                groupValue: _reason,
                onChanged: (reason) => setState(() {
                  _reason = reason;
                  _textMissing = false;
                }),
                child: Column(
                  children: [
                    RadioListTile(
                      key: const ValueKey('leave-printed_after_all'),
                      value: LeaveReason.printedAfterAll,
                      title: Text(l10n.leaveReasonPrintedAfterAll),
                    ),
                    RadioListTile(
                      key: const ValueKey('leave-customer_left'),
                      value: LeaveReason.customerLeft,
                      title: Text(l10n.leaveReasonCustomerLeft),
                    ),
                    RadioListTile(
                      key: const ValueKey('leave-other'),
                      value: LeaveReason.other,
                      title: Text(l10n.reasonOther),
                    ),
                  ],
                ),
              ),
              if (_reason == LeaveReason.other)
                TextField(
                  key: const ValueKey('leave-reason-text'),
                  controller: _text,
                  autofocus: true,
                  maxLength: 200,
                  onChanged: (_) {
                    if (_textMissing) setState(() => _textMissing = false);
                  },
                  onSubmitted: (_) => _leave(),
                  decoration: InputDecoration(
                    labelText: l10n.cancelReasonTextLabel,
                    errorText: _textMissing ? l10n.cancelReasonTextRequired : null,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                widget.queued ? l10n.unprintedDialogOffline : l10n.unprintedDialogLogged,
                key: widget.queued ? const ValueKey('leave-offline-note') : null,
                style: TextStyle(fontSize: 13, color: tokens.textSecondary),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelDialogKeep),
        ),
        OutlinedButton(
          key: const ValueKey('leave-anyway'),
          onPressed: _reason == null ? null : _leave,
          child: Text(l10n.unprintedLeave),
        ),
        FilledButton(
          key: const ValueKey('leave-retry'),
          onPressed: () => Navigator.of(context).pop(const _Retry()),
          child: Text(l10n.retry),
        ),
      ],
    );
  }
}
