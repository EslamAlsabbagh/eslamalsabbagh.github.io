import 'package:intl/intl.dart' show DateFormat;

import '../../../core/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../tickets/data/ticket_lookup.dart';
import '../../gates/view/gates_messages.dart' show testOpenResultText;
import '../../ticket_types/view/ticket_types_messages.dart';
import '../../tickets/view/ticket_messages.dart';
import '../data/action_log_models.dart';
import '../data/actions_log_repository.dart';

/// The Actions log's texts, shared by the page and the CSV.

String actionsFailureMessage(AppLocalizations l10n, ActionsLogFailureKind kind) => switch (kind) {
  ActionsLogFailureKind.notAllowed => l10n.actionsNotAllowed,
  ActionsLogFailureKind.serverUnreachable => l10n.errorServerUnreachable,
  ActionsLogFailureKind.ownAction => l10n.actionsFailureOwnAction,
  ActionsLogFailureKind.alreadyReviewed => l10n.actionsFailureAlreadyReviewed,
  ActionsLogFailureKind.notFlagged => l10n.actionsFailureNotFlagged,
  ActionsLogFailureKind.notFound => l10n.actionsFailureNotFound,
  ActionsLogFailureKind.unexpected => l10n.actionsUnexpected,
};

String loggedActionName(AppLocalizations l10n, ActionLogRow row) => switch (row.action) {
  LoggedAction.reprint => l10n.actionReprint,
  LoggedAction.reactivate => l10n.actionReactivate,
  LoggedAction.voidRefund => l10n.actionVoidRefund,
  LoggedAction.cancelOrder => l10n.actionCancelOrder,
  LoggedAction.leftUnprinted => l10n.actionLeftUnprinted,
  LoggedAction.offlineOrderAdjusted => l10n.actionOfflineAdjusted,
  LoggedAction.testOpen => l10n.actionTestOpen,
  LoggedAction.settingsChange => l10n.actionSettingsChange,
  LoggedAction.unknown => row.actionKey,
};

String typeFilterName(AppLocalizations l10n, ActionsTypeFilter type) => switch (type) {
  ActionsTypeFilter.all => l10n.actionsTypeAll,
  ActionsTypeFilter.reprint => l10n.actionReprint,
  ActionsTypeFilter.reactivate => l10n.actionReactivate,
  ActionsTypeFilter.voidRefund => l10n.actionVoidRefund,
  ActionsTypeFilter.cancelOrder => l10n.actionCancelOrder,
  ActionsTypeFilter.leftUnprinted => l10n.actionLeftUnprinted,
  ActionsTypeFilter.offline => l10n.actionsTypeOffline,
  ActionsTypeFilter.settings => l10n.actionsTypeSettings,
};

/// The reason's name, without its typed text.
String? reasonName(AppLocalizations l10n, String? code) => switch (code) {
  null => null,
  'customer_did_not_pay' => l10n.cancelReasonNotPaid,
  'unpaid_timeout' => l10n.reasonUnpaidTimeout,
  'printed_after_all' => l10n.leaveReasonPrintedAfterAll,
  'customer_left' => l10n.leaveReasonCustomerLeft,
  final key => switch (ActionReason.fromKey(key)) {
    final reason? => actionReasonName(l10n, reason),
    null => key,
  },
};

/// The reason as the design writes it: `سبب آخر: "…"` for "other", else the
/// reason's name with any note after it. A settings change has no reason: its
/// line says what changed (the lines under it are [changeLines]).
String? reasonLine(AppLocalizations l10n, ActionLogRow row, [String languageCode = 'ar']) {
  if (settingsChangeText(l10n, row.change, languageCode) case final change?) return change.title;
  // A test open has no reason: its line is what came of it (4.6).
  if (testOpenResultText(l10n, row.testOpenResult) case final result?) return result;
  final text = row.reasonText;
  if (row.reasonCode == 'other' && text != null) return l10n.actionsOtherReason(text);
  final name = reasonName(l10n, row.reasonCode);
  if (text == null) return name;
  return [?name, l10n.actionsReasonNote(text)].join(' · ');
}

String adjustReasonName(AppLocalizations l10n, String key) => switch (key) {
  'clock_out_of_range' => l10n.adjustClockOutOfRange,
  'after_closing' => l10n.adjustAfterClosing,
  'code_expired' => l10n.adjustCodeExpired,
  _ => key,
};

String flagName(AppLocalizations l10n, ActionLogRow row, ActionFlag flag, FlagRules rules, String key) =>
    switch (flag) {
      ActionFlag.otherReason => l10n.flagOtherReason,
      ActionFlag.tooManyActions => l10n.flagTooManyActions(row.actorShiftActions ?? 0),
      ActionFlag.tooManyPrints => l10n.flagTooManyPrints(rules.printsPerTicket),
      ActionFlag.reactivatedOtherGate => l10n.flagReactivatedOtherGate,
      ActionFlag.unprintedTicket => l10n.flagUnprintedTicket,
      ActionFlag.offlineTimeAdjusted => l10n.flagOfflineTimeAdjusted,
      ActionFlag.offlineReprint => l10n.flagOfflineReprint,
      ActionFlag.unknown => key,
    };

/// Every flag of [row], joined by " · ".
String flagsLine(AppLocalizations l10n, ActionLogRow row, FlagRules rules) => [
  for (var i = 0; i < row.flags.length; i++) flagName(l10n, row, row.flags[i], rules, row.flagKeys[i]),
].join(' · ');

String? paymentMethodName(AppLocalizations l10n, String? method) => switch (method) {
  null => null,
  'cash' => l10n.paymentCash,
  'card' => l10n.paymentCard,
  'wallet' => l10n.paymentWallet,
  final other => other,
};

/// The ticket's type in the UI language.
String? typeName(ActionLogRow row, String languageCode) =>
    languageCode == 'ar' ? row.typeNameAr ?? row.typeNameEn : row.typeNameEn ?? row.typeNameAr;

/// A time on this PC's clock ("17:04"), with the date when it isn't [day]
/// ("27/10 17:04"). The PC's zone should be the venue's.
String logTime(DateTime at, DateTime day) {
  final local = at.toLocal();
  final sameDay = local.year == day.year && local.month == day.month && local.day == day.day;
  return DateFormat(sameDay ? 'HH:mm' : 'dd/MM HH:mm').format(local);
}

/// A settings change's values, one per line, under [reasonLine].
List<String> changeLines(AppLocalizations l10n, ActionLogRow row, String languageCode) =>
    settingsChangeText(l10n, row.change, languageCode)?.lines ?? const [];

/// An offline adjustment's two times and why, for the reason column.
String? offlineTimesLine(AppLocalizations l10n, ActionLogRow row, DateTime day) {
  final claimed = row.claimedSoldAt;
  final stored = row.storedSoldAt;
  if (claimed == null || stored == null) return null;
  return [
    '\u2066${l10n.actionsOfflineTimes(logTime(claimed, day), logTime(stored, day))}\u2069',
    for (final r in row.adjustReasons) adjustReasonName(l10n, r),
  ].join(' · ');
}

/// The CSV of [rows], headers in the UI language. Times are full local
/// date-times; amounts are numbers in pounds; the code is its last 3 digits.
List<List<Object?>> actionsCsvRows(
  AppLocalizations l10n,
  List<ActionLogRow> rows,
  FlagRules rules,
  String languageCode,
) {
  final time = DateFormat('yyyy-MM-dd HH:mm:ss');
  return [
    [
      l10n.csvTime, l10n.csvCashier, l10n.csvCounter, l10n.csvShift, l10n.csvAction, l10n.csvOrder,
      l10n.csvType, l10n.csvCode, l10n.csvCopy, l10n.csvAmount, l10n.csvMethod, l10n.csvReason,
      l10n.csvReasonText, l10n.csvDetails, l10n.csvFlags, l10n.csvReviewedBy, l10n.csvReviewedAt,
    ],
    for (final r in rows)
      [
        time.format(r.createdAt.toLocal()),
        r.actorName ?? (r.actorId == null ? l10n.actionsSystem : null),
        r.counterName,
        r.shiftNumber == null ? null : '#${r.shiftNumber}',
        loggedActionName(l10n, r),
        r.orderNumber == null ? null : '#${r.orderNumber}',
        typeName(r, languageCode),
        r.codeTail == null ? null : '***${r.codeTail}',
        r.copyNumber,
        if (r.amountPiastres case final a?) a % 100 == 0 ? a ~/ 100 : a / 100 else null,
        paymentMethodName(l10n, r.paymentMethod),
        reasonName(l10n, r.reasonCode),
        r.reasonText,
        [
          if (r.undoneGateName case final gate?) l10n.actionsUndoneGate(gate),
          if (r.claimedSoldAt != null && r.storedSoldAt != null)
            l10n.actionsOfflineTimes(
              time.format(r.claimedSoldAt!.toLocal()),
              time.format(r.storedSoldAt!.toLocal()),
            ),
          for (final a in r.adjustReasons) adjustReasonName(l10n, a),
          ?r.gateName,
          ?testOpenResultText(l10n, r.testOpenResult),
          ?settingsChangeText(l10n, r.change, languageCode)?.title,
          ...changeLines(l10n, r, languageCode),
        ].join(' · '),
        flagsLine(l10n, r, rules),
        r.reviewedByName,
        r.reviewedAt == null ? null : time.format(r.reviewedAt!.toLocal()),
      ],
  ];
}

/// "2 · 350 ج.م": a refund tile.
String refundTile(AppLocalizations l10n, int count, int piastres) =>
    count == 0 ? '0' : '$count · ${formatMoney(l10n, piastres)}';
