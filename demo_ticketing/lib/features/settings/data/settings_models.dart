import 'package:equatable/equatable.dart';

import '../../../core/money.dart';
import '../../../core/venue_day.dart';

/// The settings the page edits (`editable_settings()`, 4.8), by their column
/// names, each a whole number in a range. The ranges are `save_settings`'s.
const settingRanges = <String, ({int min, int max})>{
  'gate_code_length': (min: 4, max: 9),
  'unpaid_order_timeout_min': (min: 1, max: 1440),
  'reactivation_window_min': (min: 1, max: 1440),
  'reactivation_max': (min: 0, max: 10),
  'flag_actions_per_shift': (min: 1, max: 1000),
  'flag_prints_per_ticket': (min: 1, max: 100),
  'offline_pool_size': (min: 0, max: 5000),
  'offline_health_check_seconds': (min: 2, max: 120),
  'gate_offline_after_seconds': (min: 10, max: 3600),
  'test_open_timeout_seconds': (min: 5, max: 60),
};

/// The settings that are lists of amounts in piastres. Quick amounts are kept
/// smallest first, each once; denominations in the order typed (the close
/// screen's order), each once, at least one.
const amountListSettings = [
  'tip_quick_amounts_piastres',
  'opening_float_quick_amounts_piastres',
  'received_quick_amounts_piastres',
  'cash_denominations_piastres',
];

const switchSettings = [
  'refund_before_scan_only',
  'refund_same_shift_only',
  'flag_other_reason',
  'tips_enabled',
];

/// Every editable setting in the page's order (`editable_settings()`).
const settingsOrder = [
  'venue_name',
  'venue_day_starts_at',
  'closing_time',
  'default_language',
  'gate_code_length',
  'unpaid_order_timeout_min',
  'reactivation_window_min',
  'reactivation_max',
  'refund_before_scan_only',
  'refund_same_shift_only',
  'flag_actions_per_shift',
  'flag_prints_per_ticket',
  'flag_other_reason',
  'tips_enabled',
  'tip_quick_amounts_piastres',
  'opening_float_quick_amounts_piastres',
  'received_quick_amounts_piastres',
  'cash_denominations_piastres',
  'offline_pool_size',
  'offline_health_check_seconds',
  'gate_offline_after_seconds',
  'test_open_timeout_seconds',
];

/// How many amounts each list may hold (`save_settings`): as many buttons as
/// their screens show in the design. The tip grids (payment: 4 a row with
/// "none" and the typed field; close shift: 3 a row) hold 6 in two rows; the
/// open shift screen's row holds 4. The payment screen shows the first 3
/// amounts received above the order's total, so 8 still serve other totals.
const maxAmountsFor = {
  'tip_quick_amounts_piastres': 6,
  'opening_float_quick_amounts_piastres': 4,
  'received_quick_amounts_piastres': 8,
  'cash_denominations_piastres': 12,
};

/// Each amount up to 100,000 EGP (`amount_list_ok`).
const maxAmountPiastres = 10000000;
const maxVenueName = 60;

/// Why a typed setting can't be saved.
enum SettingError {
  required,
  outOfRange,

  /// Not a list of amounts like "5, 10, 20".
  badList,
  tooMany,
  tooBig,
  duplicate,

  /// Denominations: at least one.
  empty,

  /// The server refused it (`invalid_setting`).
  refused,

  /// A venue day start the daily peak hours would cross (ADR-0038).
  crossesPeakHours,

  /// A closing time before the daily peak hours end (ADR-0038).
  cutsPeakHours,
}

/// The venue's settings as the page edits them (`settings_overview`'s
/// `settings`). [toJson] gives `save_settings`' keys and values.
class AdminSettings extends Equatable {
  const AdminSettings({
    required this.venueName,
    required this.dayStartSeconds,
    required this.closingSeconds,
    required this.defaultLanguage,
    required this.numbers,
    required this.switches,
    required this.amountLists,
  });

  factory AdminSettings.fromJson(Map<String, dynamic> json) => AdminSettings(
    venueName: json['venue_name'] as String,
    dayStartSeconds: parseTimeOfDay(json['venue_day_starts_at'] as String),
    closingSeconds: parseTimeOfDay(json['closing_time'] as String),
    defaultLanguage: json['default_language'] as String,
    numbers: {for (final key in settingRanges.keys) key: (json[key] as num).toInt()},
    switches: {for (final key in switchSettings) key: json[key] as bool},
    amountLists: {
      for (final key in amountListSettings)
        key: [for (final a in json[key] as List<dynamic>) (a as num).toInt()],
    },
  );

  final String venueName;

  /// When a venue day starts (ADR-0038), as seconds after midnight.
  final int dayStartSeconds;

  /// The venue's closing time, as seconds after midnight. At or before
  /// [dayStartSeconds] it is the night after.
  final int closingSeconds;

  /// The venue day these settings give, for the page's hints and warning.
  VenueDay get venueDay => VenueDay(
    start: VenueTime.ofSeconds(dayStartSeconds),
    closing: VenueTime.ofSeconds(closingSeconds),
  );

  /// `ar` or `en`.
  final String defaultLanguage;

  /// By column name: the [settingRanges] keys.
  final Map<String, int> numbers;

  /// By column name: the [switchSettings] keys.
  final Map<String, bool> switches;

  /// By column name: the [amountListSettings] keys, in piastres.
  final Map<String, List<int>> amountLists;

  Map<String, Object> toJson() => {
    'venue_name': venueName,
    'venue_day_starts_at': timeOfDayText(dayStartSeconds),
    'closing_time': timeOfDayText(closingSeconds),
    'default_language': defaultLanguage,
    ...numbers,
    ...switches,
    ...amountLists,
  };

  @override
  List<Object?> get props => [
    venueName,
    dayStartSeconds,
    closingSeconds,
    defaultLanguage,
    numbers,
    switches,
    amountLists,
  ];
}

/// What differs between [loaded] and [edited], as `save_settings` takes it:
/// only the keys that changed, so another admin's save of other settings
/// isn't undone.
Map<String, Object> settingsChanges(AdminSettings loaded, AdminSettings edited) {
  final before = loaded.toJson();
  bool same(Object? a, Object b) => switch ((a, b)) {
    (final List<int> x, final List<int> y) =>
      x.length == y.length && [for (var i = 0; i < x.length; i++) x[i] == y[i]].every((e) => e),
    _ => a == b,
  };
  return {
    for (final MapEntry(:key, :value) in edited.toJson().entries)
      if (!same(before[key], value)) key: value,
  };
}

/// "23:00:00" or "23:00" as seconds after midnight.
int parseTimeOfDay(String text) {
  final parts = text.split(':');
  if (parts.length < 2) throw FormatException('not a time: $text');
  return int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60;
}

/// "23:00:00" from seconds after midnight.
String timeOfDayText(int seconds) =>
    '${(seconds ~/ 3600).toString().padLeft(2, '0')}:'
    '${(seconds % 3600 ~/ 60).toString().padLeft(2, '0')}:00';

/// A typed whole number in its range, or why not.
({int? value, SettingError? error}) parseSettingNumber(String key, String text) {
  final range = settingRanges[key]!;
  final trimmed = text.trim();
  if (trimmed.isEmpty) return (value: null, error: SettingError.required);
  final value = int.tryParse(trimmed);
  if (value == null || value < range.min || value > range.max) {
    return (value: null, error: SettingError.outOfRange);
  }
  return (value: value, error: null);
}

/// "5, 10, 20" (pounds, a Latin or Arabic comma) as piastres, normalized as
/// the server stores it, or why not.
({List<int>? value, SettingError? error}) parseAmountList(String key, String text) {
  final denominations = key == 'cash_denominations_piastres';
  final parts = text.split(RegExp('[,،]')).map((p) => p.trim()).toList();
  final amounts = <int>[];
  if (!(parts.length == 1 && parts.single.isEmpty)) {
    for (final part in parts) {
      final piastres = parsePiastres(part);
      if (piastres == null || piastres <= 0) return (value: null, error: SettingError.badList);
      amounts.add(piastres);
    }
  }
  if (amounts.any((a) => a > maxAmountPiastres)) return (value: null, error: SettingError.tooBig);
  if (amounts.length > maxAmountsFor[key]!) return (value: null, error: SettingError.tooMany);
  if (denominations) {
    if (amounts.isEmpty) return (value: null, error: SettingError.empty);
    if (amounts.toSet().length != amounts.length) {
      return (value: null, error: SettingError.duplicate);
    }
    return (value: amounts, error: null);
  }
  return (value: (amounts.toSet().toList()..sort()), error: null);
}

/// An amount list as its field shows it: "5, 10, 20".
String amountListText(List<int> piastres) => piastres.map(piastresText).join(', ');

class AdminCounter extends Equatable {
  const AdminCounter({
    required this.id,
    required this.name,
    required this.printerIp,
    required this.printerPort,
    required this.paperWidthMm,
    required this.entryGateId,
    required this.entryGateName,
    required this.active,
    required this.hasOpenShift,
  });

  factory AdminCounter.fromJson(Map<String, dynamic> json) => AdminCounter(
    id: json['id'] as String,
    name: json['name'] as String,
    printerIp: json['printer_ip'] as String?,
    printerPort: json['printer_port'] as int,
    paperWidthMm: json['paper_width_mm'] as int,
    entryGateId: json['entry_gate_id'] as String?,
    entryGateName: json['entry_gate_name'] as String?,
    active: json['active'] as bool,
    hasOpenShift: json['has_open_shift'] as bool,
  );

  final String id;
  final String name;
  final String? printerIp;
  final int printerPort;
  final int paperWidthMm;

  /// The home gate (ADR-0015).
  final String? entryGateId;
  final String? entryGateName;
  final bool active;
  final bool hasOpenShift;

  CounterDraft get draft => CounterDraft(
    name: name,
    printerIp: printerIp,
    printerPort: printerPort,
    paperWidthMm: paperWidthMm,
    entryGateId: entryGateId,
    active: active,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    printerIp,
    printerPort,
    paperWidthMm,
    entryGateId,
    entryGateName,
    active,
    hasOpenShift,
  ];
}

/// The counter dialog's values, as `save_counter` takes them.
class CounterDraft extends Equatable {
  const CounterDraft({
    required this.name,
    required this.printerIp,
    required this.printerPort,
    required this.paperWidthMm,
    required this.entryGateId,
    required this.active,
  });

  final String name;
  final String? printerIp;
  final int printerPort;
  final int paperWidthMm;
  final String? entryGateId;
  final bool active;

  bool sameAs(CounterDraft other) => this == other;

  @override
  List<Object?> get props => [name, printerIp, printerPort, paperWidthMm, entryGateId, active];
}

/// An entry gate a counter can have as its home gate.
class EntryGateOption extends Equatable {
  const EntryGateOption({required this.id, required this.name, required this.enabled});

  factory EntryGateOption.fromJson(Map<String, dynamic> json) => EntryGateOption(
    id: json['id'] as String,
    name: json['name'] as String,
    enabled: json['enabled'] as bool,
  );

  final String id;
  final String name;
  final bool enabled;

  @override
  List<Object?> get props => [id, name, enabled];
}

/// `settings_overview`: the page in one answer.
class SettingsOverview extends Equatable {
  const SettingsOverview({
    required this.settings,
    required this.timezone,
    required this.updatedAt,
    required this.updatedByName,
    required this.peakWeekdays,
    required this.peakFromSeconds,
    required this.peakToSeconds,
    required this.counters,
    required this.entryGates,
  });

  factory SettingsOverview.fromJson(Map<String, dynamic> json) {
    final settings = json['settings'] as Map<String, dynamic>;
    final peak = json['peak'] as Map<String, dynamic>;
    return SettingsOverview(
      settings: AdminSettings.fromJson(settings),
      timezone: settings['timezone'] as String,
      updatedAt: DateTime.parse(settings['updated_at'] as String),
      updatedByName: settings['updated_by_name'] as String?,
      peakWeekdays: [for (final d in peak['weekdays'] as List<dynamic>) (d as num).toInt()],
      peakFromSeconds: switch (peak['from']) {
        final String t => parseTimeOfDay(t),
        _ => null,
      },
      peakToSeconds: switch (peak['to']) {
        final String t => parseTimeOfDay(t),
        _ => null,
      },
      counters: [
        for (final c in json['counters'] as List<dynamic>)
          AdminCounter.fromJson(c as Map<String, dynamic>),
      ],
      entryGates: [
        for (final g in json['entry_gates'] as List<dynamic>)
          EntryGateOption.fromJson(g as Map<String, dynamic>),
      ],
    );
  }

  final AdminSettings settings;
  final String timezone;
  final DateTime updatedAt;

  /// Who last changed the settings; null before anyone did (the seed).
  final String? updatedByName;
  final List<int> peakWeekdays;
  final int? peakFromSeconds;
  final int? peakToSeconds;
  final List<AdminCounter> counters;
  final List<EntryGateOption> entryGates;

  AdminCounter? counter(String? id) {
    for (final c in counters) {
      if (c.id == id) return c;
    }
    return null;
  }

  @override
  List<Object?> get props => [
    settings,
    timezone,
    updatedAt,
    updatedByName,
    peakWeekdays,
    peakFromSeconds,
    peakToSeconds,
    counters,
    entryGates,
  ];
}
