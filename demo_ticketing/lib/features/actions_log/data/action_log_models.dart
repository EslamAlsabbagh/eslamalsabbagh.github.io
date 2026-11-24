import 'package:equatable/equatable.dart';

/// The log's periods (`actions_log`'s `p_period`). The server works out the
/// venue-day bounds; the app can't convert a zone name.
enum ActionsPeriod {
  today('today'),
  yesterday('yesterday'),
  week('week'),

  /// Every flagged row not reviewed yet, whatever its date.
  review('review'),

  /// Every action of one shift (from the Shifts page).
  shift('shift');

  const ActionsPeriod(this.key);

  final String key;
}

/// `ticket_action_type`. [unknown] keeps a value added later readable.
enum LoggedAction {
  reprint('reprint'),
  reactivate('reactivate'),
  voidRefund('void_refund'),
  cancelOrder('cancel_order'),
  leftUnprinted('left_unprinted'),
  offlineOrderAdjusted('offline_order_adjusted'),
  testOpen('test_open'),
  settingsChange('settings_change'),
  unknown('');

  const LoggedAction(this.key);

  final String key;

  static LoggedAction fromKey(String key) {
    for (final action in values) {
      if (action.key == key) return action;
    }
    return unknown;
  }
}

/// The type chips. [offline] is the offline time adjustments; reprints made
/// offline are under [reprint] with their own flag.
enum ActionsTypeFilter {
  all,
  reprint,
  reactivate,
  voidRefund,
  cancelOrder,
  leftUnprinted,
  offline,

  /// Ticket type changes (4.5), and settings changes (4.8).
  settings;

  bool matches(LoggedAction action) => switch (this) {
    all => true,
    reprint => action == LoggedAction.reprint,
    reactivate => action == LoggedAction.reactivate,
    voidRefund => action == LoggedAction.voidRefund,
    cancelOrder => action == LoggedAction.cancelOrder,
    leftUnprinted => action == LoggedAction.leftUnprinted,
    offline => action == LoggedAction.offlineOrderAdjusted,
    settings => action == LoggedAction.settingsChange,
  };
}

/// `action_flag`. [unknown] keeps a value added later readable.
enum ActionFlag {
  otherReason('other_reason'),
  tooManyActions('too_many_actions'),
  tooManyPrints('too_many_prints'),
  reactivatedOtherGate('reactivated_other_gate'),
  unprintedTicket('unprinted_ticket'),
  offlineTimeAdjusted('offline_time_adjusted'),
  offlineReprint('offline_reprint'),
  unknown('');

  const ActionFlag(this.key);

  final String key;

  static ActionFlag fromKey(String key) {
    for (final flag in values) {
      if (flag.key == key) return flag;
    }
    return unknown;
  }
}

/// One `actions_log` row. No gate code: [codeTail] is its last 3 digits.
class ActionLogRow extends Equatable {
  const ActionLogRow({
    required this.id,
    required this.createdAt,
    required this.action,
    required this.actionKey,
    this.actorId,
    this.actorName,
    this.shiftId,
    this.shiftNumber,
    this.counterName,
    this.orderNumber,
    this.typeNameAr,
    this.typeNameEn,
    this.codeTail,
    this.copyNumber,
    this.amountPiastres,
    this.paymentMethod,
    this.reasonCode,
    this.reasonText,
    this.actorShiftActions,
    this.undoneGateName,
    this.claimedSoldAt,
    this.storedSoldAt,
    this.adjustReasons = const [],
    this.gateName,
    this.testOpenResult,
    this.change,
    this.flags = const [],
    this.flagKeys = const [],
    this.reviewedBy,
    this.reviewedByName,
    this.reviewedAt,
  });

  factory ActionLogRow.fromJson(Map<String, dynamic> json) {
    final actionKey = json['action'] as String;
    final flagKeys = [for (final f in (json['flags'] as List<dynamic>? ?? const [])) f as String];
    return ActionLogRow(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      action: LoggedAction.fromKey(actionKey),
      actionKey: actionKey,
      actorId: json['actor_id'] as String?,
      actorName: json['actor_name'] as String?,
      shiftId: json['shift_id'] as String?,
      shiftNumber: json['shift_number'] as int?,
      counterName: json['counter_name'] as String?,
      orderNumber: json['order_number'] as int?,
      typeNameAr: json['type_name_ar'] as String?,
      typeNameEn: json['type_name_en'] as String?,
      codeTail: json['code_tail'] as String?,
      copyNumber: json['copy_number'] as int?,
      amountPiastres: json['amount_piastres'] as int?,
      paymentMethod: json['payment_method'] as String?,
      reasonCode: json['reason_code'] as String?,
      reasonText: json['reason_text'] as String?,
      actorShiftActions: json['actor_shift_actions'] as int?,
      undoneGateName: json['undone_gate_name'] as String?,
      claimedSoldAt: _time(json['claimed_sold_at']),
      storedSoldAt: _time(json['stored_sold_at']),
      adjustReasons: [
        for (final r in (json['adjust_reasons'] as List<dynamic>? ?? const [])) r as String,
      ],
      gateName: json['gate_name'] as String?,
      testOpenResult: json['test_open_result'] as String?,
      change: switch (json['change']) {
        final Map<String, dynamic> change => SettingsChange.fromJson(change),
        _ => null,
      },
      flags: [for (final f in flagKeys) ActionFlag.fromKey(f)],
      flagKeys: flagKeys,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedByName: json['reviewed_by_name'] as String?,
      reviewedAt: _time(json['reviewed_at']),
    );
  }

  final String id;
  final DateTime createdAt;
  final LoggedAction action;

  /// As the server sent it, for an [LoggedAction.unknown].
  final String actionKey;

  /// Null only for the automatic cancel of an unpaid order.
  final String? actorId;
  final String? actorName;
  final String? shiftId;
  final int? shiftNumber;
  final String? counterName;
  final int? orderNumber;
  final String? typeNameAr;
  final String? typeNameEn;
  final String? codeTail;

  /// A reprint's copy: 2 for the first reprint.
  final int? copyNumber;
  final int? amountPiastres;
  final String? paymentMethod;
  final String? reasonCode;
  final String? reasonText;

  /// The actor's actions in that shift, for the "too many actions" text.
  final int? actorShiftActions;
  final String? undoneGateName;
  final DateTime? claimedSoldAt;
  final DateTime? storedSoldAt;
  final List<String> adjustReasons;
  final String? gateName;

  /// A test open's outcome (`gate_command_result`): waiting, opened, failed
  /// or no_answer (4.6).
  final String? testOpenResult;

  /// What a [LoggedAction.settingsChange] changed; null for a subject this
  /// app doesn't know.
  final SettingsChange? change;
  final List<ActionFlag> flags;

  /// As the server sent them, for an [ActionFlag.unknown] and the CSV.
  final List<String> flagKeys;
  final String? reviewedBy;
  final String? reviewedByName;
  final DateTime? reviewedAt;

  bool get flagged => flags.isNotEmpty;
  bool get reviewed => reviewedAt != null;
  bool get needsReview => flagged && !reviewed;

  @override
  List<Object?> get props => [id, createdAt, actionKey, flagKeys, reviewedBy, reviewedAt];
}

/// One changed value: [from] is null for a new type or an empty old value.
class ChangedValue extends Equatable {
  const ChangedValue(this.from, this.to);

  final Object? from;
  final Object? to;

  @override
  List<Object?> get props => [from, to];
}

/// A settings_change row's `change` (`settings_change_summary`): a ticket
/// type's change, the peak schedule or today's peak switch (4.5).
class SettingsChange extends Equatable {
  const SettingsChange({
    required this.subject,
    this.nameAr,
    this.nameEn,
    this.name,
    this.created = false,
    this.changes = const {},
    this.day,
  });

  factory SettingsChange.fromJson(Map<String, dynamic> json) => SettingsChange(
    subject: json['subject'] as String,
    nameAr: json['name_ar'] as String?,
    nameEn: json['name_en'] as String?,
    name: json['name'] as String?,
    created: json['created'] as bool? ?? false,
    changes: {
      for (final MapEntry(:key, :value)
          in (json['changes'] as Map<String, dynamic>? ?? const {}).entries)
        if (value case final Map<String, dynamic> v) key: ChangedValue(v['old'], v['new']),
    },
    day: switch (json['day']) {
      final String day => DateTime.tryParse(day),
      _ => null,
    },
  );

  /// `ticket_type`, `peak_times`, `peak_override`, `gate` or `controller`.
  final String subject;
  final String? nameAr;
  final String? nameEn;

  /// A gate's or controller's name (4.6).
  final String? name;

  /// A new type: every value is in [changes] with a null [ChangedValue.from].
  final bool created;

  /// By field key (`price_piastres`, `active`, ...).
  final Map<String, ChangedValue> changes;

  /// The venue day a `peak_override` was for.
  final DateTime? day;

  @override
  List<Object?> get props => [subject, nameAr, nameEn, name, created, changes, day];
}

class StaffOption extends Equatable {
  const StaffOption(this.id, this.name);

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// The shift a log is narrowed to, for its chip.
class LogShift extends Equatable {
  const LogShift({
    required this.id,
    required this.number,
    required this.cashierName,
    required this.counterName,
  });

  final String id;
  final int number;
  final String cashierName;
  final String counterName;

  @override
  List<Object?> get props => [id, number, cashierName, counterName];
}

/// The flag thresholds in effect (`settings`), for the rules box.
class FlagRules extends Equatable {
  const FlagRules({
    required this.otherReason,
    required this.actionsPerShift,
    required this.printsPerTicket,
  });

  final bool otherReason;
  final int actionsPerShift;
  final int printsPerTicket;

  @override
  List<Object?> get props => [otherReason, actionsPerShift, printsPerTicket];
}

/// One `actions_log` answer.
class ActionsLog extends Equatable {
  const ActionsLog({
    required this.now,
    required this.day,
    required this.period,
    required this.total,
    required this.reviewCount,
    required this.counts,
    required this.refundCount,
    required this.refundPiastres,
    required this.rules,
    required this.staff,
    required this.counters,
    required this.rows,
    this.shift,
  });

  factory ActionsLog.fromJson(Map<String, dynamic> json) {
    final rules = json['rules'] as Map<String, dynamic>;
    final shift = json['shift'] as Map<String, dynamic>?;
    return ActionsLog(
      now: DateTime.parse(json['now'] as String),
      day: DateTime.parse(json['day'] as String),
      period: json['period'] as String,
      total: json['total'] as int,
      reviewCount: json['review_count'] as int,
      counts: {
        for (final e in (json['counts'] as Map<String, dynamic>).entries)
          LoggedAction.fromKey(e.key): e.value as int,
      },
      refundCount: json['refund_count'] as int,
      refundPiastres: json['refund_piastres'] as int,
      rules: FlagRules(
        otherReason: rules['flag_other_reason'] as bool,
        actionsPerShift: rules['flag_actions_per_shift'] as int,
        printsPerTicket: rules['flag_prints_per_ticket'] as int,
      ),
      staff: [
        for (final s in json['staff'] as List<dynamic>)
          StaffOption((s as Map<String, dynamic>)['id'] as String, s['full_name'] as String),
      ],
      counters: [
        for (final c in json['counters'] as List<dynamic>)
          StaffOption((c as Map<String, dynamic>)['id'] as String, c['name'] as String),
      ],
      rows: [
        for (final r in json['rows'] as List<dynamic>) ActionLogRow.fromJson(r as Map<String, dynamic>),
      ],
      shift: shift == null
          ? null
          : LogShift(
              id: shift['id'] as String,
              number: shift['number'] as int,
              cashierName: shift['cashier_name'] as String,
              counterName: shift['counter_name'] as String,
            ),
    );
  }

  final DateTime now;

  /// The venue's day (date only).
  final DateTime day;
  final String period;

  /// Rows matching the filters; [rows] may hold fewer (the limit).
  final int total;

  /// Every open review, whatever the filters.
  final int reviewCount;
  final Map<LoggedAction, int> counts;
  final int refundCount;
  final int refundPiastres;
  final FlagRules rules;
  final List<StaffOption> staff;

  /// Counters, as id and name.
  final List<StaffOption> counters;
  final List<ActionLogRow> rows;
  final LogShift? shift;

  bool get truncated => rows.length < total;

  @override
  List<Object?> get props => [
    now, day, period, total, reviewCount, counts, refundCount, refundPiastres, rules, staff,
    counters, rows, shift,
  ];
}

DateTime? _time(Object? value) => value is String ? DateTime.parse(value) : null;
