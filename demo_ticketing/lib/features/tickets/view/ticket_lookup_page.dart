import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/clock.dart';
import '../../../core/money.dart';
import '../../../core/printer/ticket_view.dart' show groupGateCode;
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../home/view/app_header.dart';
import '../../home/view/message_box.dart';
import '../bloc/ticket_action_cubit.dart';
import '../bloc/ticket_lookup_cubit.dart';
import '../data/ticket_failure.dart';
import '../data/ticket_lookup.dart';
import '../data/ticket_repository.dart';
import 'ticket_action_dialog.dart';
import 'ticket_messages.dart';

/// Ticket lookup (`TicketLookup.dc.html`): scan or type a code, see the
/// ticket, its sale and its scans, and open the action dialog for what the
/// cashier can still do.
///
/// Differs from the design:
/// - the status can also be "not paid" (pending) and "expired" (1.13);
/// - the order line is "#1028" only: the lookup returns no order total
///   (ADR-0008);
/// - the details add the ticket's home gate (ADR-0015);
/// - an action button shows only when the server allows that action; the
///   dialog says why the others are blocked;
/// - after an action, a notice above the ticket says what was done.
class TicketLookupPage extends StatelessWidget {
  const TicketLookupPage({super.key, required this.setup});

  /// For a reprint's copy: the venue and this counter's printer.
  final TicketPrintSetup setup;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TicketLookupCubit(context.read<TicketRepository>()),
      child: _LookupView(setup: setup),
    );
  }
}

class _LookupView extends StatefulWidget {
  const _LookupView({required this.setup});

  final TicketPrintSetup setup;

  @override
  State<_LookupView> createState() => _LookupViewState();
}

class _LookupViewState extends State<_LookupView> {
  final _code = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    await context.read<TicketLookupCubit>().search(_code.text);
    // Ready for the next scan.
    _code.selection = TextSelection(baseOffset: 0, extentOffset: _code.text.length);
    _focus.requestFocus();
  }

  Future<void> _act(TicketLookup ticket, TicketActionSettings settings, TicketAction action) async {
    final cubit = context.read<TicketLookupCubit>();
    final outcome = await TicketActionDialog.show(
      context,
      ticket: ticket,
      settings: settings,
      setup: widget.setup,
      initial: action,
    );
    // A blocked action may have been refused because the ticket changed: read
    // it again either way.
    if (outcome != null) {
      await cubit.actionDone(outcome);
    } else {
      await cubit.search(cubit.state.code);
    }
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = context.watch<TicketLookupCubit>().state;

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): () => context.pop()},
      // A mouse click outside the code field unfocuses it to this scope, under
      // the shortcuts, so Esc keeps working (as on the payment screen).
      child: FocusScope(
        child: Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppHeader(title: l10n.lookupTitle, subtitle: '', onBack: () => context.pop()),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SearchRow(
                          controller: _code,
                          focus: _focus,
                          loading: state.loading,
                          onSearch: _search,
                        ),
                        const SizedBox(height: 20),
                        if (state.outcome case final outcome?) ...[
                          _OutcomeNotice(outcome: outcome),
                          const SizedBox(height: 20),
                        ],
                        if (state.loading)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (state.failure case final failure?)
                          MessageBox.danger(
                            message: ticketFailureMessage(l10n, failure),
                            onRetry: failure == TicketFailureKind.serverUnreachable
                                ? _search
                                : null,
                          )
                        else if ((state.ticket, state.settings) case (final ticket?, final settings?))
                          _Result(
                            ticket: ticket,
                            onAction: (action) => _act(ticket, settings, action),
                          ),
                      ],
                    ),
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
}

class _SearchRow extends StatelessWidget {
  const _SearchRow({
    required this.controller,
    required this.focus,
    required this.loading,
    required this.onSearch,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool loading;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.lookupCodeLabel, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              SizedBox(
                height: 56,
                child: TextField(
                  key: const ValueKey('lookup-code'),
                  controller: controller,
                  focusNode: focus,
                  autofocus: true,
                  // A code is digits, read left to right in both languages.
                  textDirection: TextDirection.ltr,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => onSearch(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    filled: true,
                    fillColor: tokens.surface,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: tokens.primary, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: tokens.inputBorder),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          height: 56,
          child: FilledButton(
            key: const ValueKey('lookup-search'),
            onPressed: loading ? null : onSearch,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            child: Text(l10n.lookupSearch),
          ),
        ),
      ],
    );
  }
}

/// What the last action did.
class _OutcomeNotice extends StatelessWidget {
  const _OutcomeNotice({required this.outcome});

  final TicketActionOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    if (outcome.action == TicketAction.reprint && !outcome.printed) {
      return MessageBox.warning(message: l10n.outcomeReprintNotPrinted);
    }
    final text = switch (outcome.action) {
      TicketAction.reprint => l10n.outcomeReprinted,
      TicketAction.reactivate => l10n.outcomeReactivated,
      TicketAction.voidRefund => l10n.outcomeRefunded(
          refundHowText(l10n, outcome.refund?.method),
          formatMoney(l10n, outcome.refund?.amountPiastres ?? 0),
        ),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('lookup-outcome'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: tokens.successBg, borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: tokens.successDot),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tokens.successText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The ticket card and the scan history, side by side while both fit.
class _Result extends StatelessWidget {
  const _Result({required this.ticket, required this.onAction});

  final TicketLookup ticket;
  final void Function(TicketAction action) onAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 380 * 2 + 20;
        final card = _TicketCard(ticket: ticket, onAction: onAction);
        final scans = _ScanHistory(scans: ticket.scans);
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [card, const SizedBox(height: 20), scans],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: card),
            const SizedBox(width: 20),
            Expanded(child: scans),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: child,
    );
  }
}

class _TicketCard extends StatelessWidget {
  const _TicketCard({required this.ticket, required this.onAction});

  final TicketLookup ticket;
  final void Function(TicketAction action) onAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final now = context.read<Clock>().now();
    final t = ticket;
    final note = _note(l10n, now);

    final details = [
      (l10n.lookupOrder, '#${t.orderNumber}'),
      (l10n.lookupSold, '${dayTime(l10n, t.soldAt, now)} · ${t.counterName}'),
      (l10n.lookupCashier, t.soldByName),
      (l10n.lookupValidUntil, dayTime(l10n, t.validUntil, now)),
      (
        l10n.lookupEntriesLeft,
        t.status == TicketStatus.voided ? '—' : l10n.lookupEntriesValue(t.entriesLeft, t.entriesAllowed),
      ),
      (l10n.lookupPrintCount, '${t.printCount}'),
      if (t.homeGateName case final gate?) (l10n.lookupHomeGate, gate),
    ];

    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name(l10n.localeName), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(
                      groupGateCode(t.gateCode),
                      textDirection: TextDirection.ltr,
                      style: TextStyle(fontSize: 18, color: tokens.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _StatusPill(ticket: t),
            ],
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < details.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _Detail(label: details[i].$1, value: details[i].$2)),
                const SizedBox(width: 20),
                Expanded(
                  child: i + 1 < details.length
                      ? _Detail(label: details[i + 1].$1, value: details[i + 1].$2)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
          if (note case (final text, final danger)) ...[
            const SizedBox(height: 16),
            Container(
              key: const ValueKey('lookup-note'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: danger ? tokens.dangerBg : tokens.primaryTint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                text,
                style: TextStyle(fontSize: 14, color: danger ? tokens.dangerText : tokens.onPrimaryTint),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (t.can(TicketAction.reactivate))
                _CardButton(
                  key: const ValueKey('lookup-reactivate'),
                  label: l10n.actionReactivate,
                  filled: true,
                  onPressed: () => onAction(TicketAction.reactivate),
                ),
              if (t.can(TicketAction.reprint))
                _CardButton(
                  key: const ValueKey('lookup-reprint'),
                  label: l10n.actionReprint,
                  onPressed: () => onAction(TicketAction.reprint),
                ),
              if (t.can(TicketAction.voidRefund))
                _CardButton(
                  key: const ValueKey('lookup-void'),
                  label: l10n.actionVoidRefund,
                  danger: true,
                  onPressed: () => onAction(TicketAction.voidRefund),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// The note under the details, and whether it is a danger note.
  (String, bool)? _note(AppLocalizations l10n, DateTime now) {
    final t = ticket;
    switch (t.status) {
      case TicketStatus.voided:
        final entry = t.voidAction;
        if (entry == null) return (l10n.lookupNoteVoidedPlain, true);
        final time = dayTime(l10n, entry.createdAt, now);
        final actor = entry.actorName;
        if (actor == null) return (l10n.lookupNoteVoidedAuto(time), true);
        return (
          l10n.lookupNoteVoided(time, actor, entry.counterName ?? '—', loggedReason(l10n, entry)),
          true,
        );
      case TicketStatus.pending:
        return (l10n.lookupNotePending, false);
      case TicketStatus.expired:
        return (l10n.lookupNoteExpired(dayTime(l10n, t.validUntil, now)), false);
      case TicketStatus.used || TicketStatus.active:
        final until = t.allowance(TicketAction.reactivate).until;
        if (until == null) return null;
        // Whole minutes, rounded up: "1 minute left" until it closes.
        final left = math.max(1, (until.difference(now).inSeconds + 59) ~/ 60);
        return (l10n.lookupNoteReactivate(dayTime(l10n, until, now), left), false);
    }
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.ticket});

  final TicketLookup ticket;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final unused = ticket.scans.every((scan) => !scan.accepted);
    final (label, background, foreground) = switch (ticket.status) {
      TicketStatus.active => (
          unused ? l10n.statusActiveUnused : l10n.statusActive,
          tokens.primaryTint,
          tokens.onPrimaryTint,
        ),
      TicketStatus.used => (l10n.statusUsed, tokens.bg, tokens.text),
      TicketStatus.voided => (l10n.statusVoided, tokens.dangerBg, tokens.dangerText),
      TicketStatus.pending => (l10n.statusPending, tokens.warningBg, tokens.warningText),
      TicketStatus.expired => (l10n.statusExpired, tokens.bg, tokens.textSecondary),
    };
    return Container(
      key: const ValueKey('lookup-status'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
      child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: foreground)),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.danger = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    const text = TextStyle(fontSize: 16, fontWeight: FontWeight.w700);
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, minHeight: 52),
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(shape: shape, textStyle: text),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                shape: shape,
                textStyle: text.copyWith(fontWeight: FontWeight.w600),
                foregroundColor: danger ? tokens.dangerAction : tokens.text,
                side: BorderSide(
                  color: danger ? tokens.dangerAction.withValues(alpha: 0.4) : tokens.inputBorder,
                ),
              ),
              child: Text(label),
            ),
    );
  }
}

class _ScanHistory extends StatelessWidget {
  const _ScanHistory({required this.scans});

  final List<TicketScan> scans;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final now = context.read<Clock>().now();
    return _Section(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.lookupScansTitle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          if (scans.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: tokens.border, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.lookupNoScans,
                textAlign: TextAlign.center,
                style: TextStyle(color: tokens.textSecondary),
              ),
            ),
          for (final (i, scan) in scans.indexed) ...[
            if (i > 0) const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: tokens.inset, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scan.gateName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        Text(
                          dayTime(l10n, scan.scannedAt, now, seconds: true),
                          style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: ShapeDecoration(
                      color: scan.accepted ? tokens.successBg : tokens.dangerBg,
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      scan.accepted
                          ? l10n.scanAccepted
                          : l10n.scanRejected(scanReasonName(l10n, scan.reason)),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: scan.accepted ? tokens.successText : tokens.dangerText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
