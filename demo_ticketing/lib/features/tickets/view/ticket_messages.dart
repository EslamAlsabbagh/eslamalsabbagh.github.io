import 'package:intl/intl.dart' show DateFormat;

import '../../../l10n/gen/app_localizations.dart';
import '../data/ticket_failure.dart';
import '../data/ticket_lookup.dart';

/// The one message for each way a lookup or an action can fail, and for why
/// an action is blocked.
String ticketFailureMessage(AppLocalizations l10n, TicketFailureKind kind) => switch (kind) {
      TicketFailureKind.ticketNotFound => l10n.ticketFailureNotFound,
      TicketFailureKind.noOpenShift => l10n.ticketFailureNoOpenShift,
      TicketFailureKind.ticketVoided => l10n.ticketFailureVoided,
      TicketFailureKind.ticketUsed => l10n.ticketFailureUsed,
      TicketFailureKind.ticketExpired => l10n.ticketFailureExpired,
      TicketFailureKind.notScanned => l10n.ticketFailureNotScanned,
      TicketFailureKind.alreadyReactivated => l10n.ticketFailureAlreadyReactivated,
      TicketFailureKind.reactivationLimitReached => l10n.ticketFailureReactivationLimit,
      TicketFailureKind.reactivationWindowPassed => l10n.ticketFailureReactivationWindow,
      TicketFailureKind.ticketNotPaid => l10n.ticketFailureNotPaid,
      TicketFailureKind.ticketAlreadyScanned => l10n.ticketFailureAlreadyScanned,
      TicketFailureKind.notSameShift => l10n.ticketFailureNotSameShift,
      TicketFailureKind.reasonTextRequired => l10n.actionReasonTextRequired,
      TicketFailureKind.serverUnreachable => l10n.errorServerUnreachable,
      TicketFailureKind.needsServer => l10n.needsServer,
      TicketFailureKind.invalidReason || TicketFailureKind.unexpected => l10n.errorUnexpected,
    };

String ticketActionName(AppLocalizations l10n, TicketAction action) => switch (action) {
      TicketAction.reactivate => l10n.actionReactivate,
      TicketAction.reprint => l10n.actionReprint,
      TicketAction.voidRefund => l10n.actionVoidRefund,
    };

String actionReasonName(AppLocalizations l10n, ActionReason reason) => switch (reason) {
      ActionReason.scannedNotPassed => l10n.reasonScannedNotPassed,
      ActionReason.gateDidNotOpen => l10n.reasonGateDidNotOpen,
      ActionReason.printFailed => l10n.reasonPrintFailed,
      ActionReason.ticketLost => l10n.reasonTicketLost,
      ActionReason.customerChangedMind => l10n.reasonCustomerChangedMind,
      ActionReason.wrongTicketType => l10n.reasonWrongTicketType,
      ActionReason.other => l10n.reasonOther,
    };

/// A logged reason as the lookup shows it: the reason's name, or the typed
/// text for "other" (and the cancel's and leave's own reasons).
String loggedReason(AppLocalizations l10n, TicketActionEntry entry) {
  final text = entry.reasonText;
  if (entry.reasonCode == 'other' && text != null) return text;
  return switch (entry.reasonCode) {
    'customer_did_not_pay' => l10n.cancelReasonNotPaid,
    'unpaid_timeout' => l10n.reasonUnpaidTimeout,
    final code => switch (ActionReason.fromKey(code)) {
        final reason? => actionReasonName(l10n, reason),
        null => text ?? '—',
      },
  };
}

/// A rejected scan's reason (`scan_reject_reason`).
String scanReasonName(AppLocalizations l10n, String? reason) => switch (reason) {
      'not_paid' => l10n.scanReasonNotPaid,
      'voided' => l10n.scanReasonVoided,
      'used_up' => l10n.scanReasonUsedUp,
      'not_yet_valid' => l10n.scanReasonNotYetValid,
      'expired' => l10n.scanReasonExpired,
      'gate_disabled' => l10n.scanReasonGateDisabled,
      _ => l10n.scanReasonNotFound,
    };

/// "اليوم 14:32" on [now]'s day, else "28/10 14:32"; [seconds] adds them.
/// Western digits in both languages.
String dayTime(AppLocalizations l10n, DateTime time, DateTime now, {bool seconds = false}) {
  final local = time.toLocal();
  final clock = DateFormat(seconds ? 'HH:mm:ss' : 'HH:mm').format(local);
  final today = local.year == now.year && local.month == now.month && local.day == now.day;
  return today ? l10n.todayAt(clock) : '${DateFormat('dd/MM').format(local)} $clock';
}
