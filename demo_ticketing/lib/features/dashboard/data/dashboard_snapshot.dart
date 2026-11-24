import 'package:equatable/equatable.dart';

/// A gate's state on the dashboard, decided by `dashboard_today` from its
/// heartbeat and `settings.gate_offline_after_seconds`.
enum GateLiveStatus {
  online,
  offline,
  neverSeen,
  disabled;

  static GateLiveStatus fromKey(String key) => switch (key) {
    'online' => online,
    'offline' => offline,
    'never_seen' => neverSeen,
    'disabled' => disabled,
    _ => throw FormatException('unknown gate status: $key'),
  };
}

class GateCard extends Equatable {
  const GateCard({
    required this.id,
    required this.name,
    required this.status,
    required this.lastSeenAt,
    required this.lastScanAt,
    required this.entries,
    required this.rejected,
  });

  factory GateCard.fromJson(Map<String, dynamic> json) => GateCard(
    id: json['id'] as String,
    name: json['name'] as String,
    status: GateLiveStatus.fromKey(json['status'] as String),
    lastSeenAt: _time(json['last_seen_at']),
    lastScanAt: _time(json['last_scan_at']),
    entries: json['entries'] as int,
    rejected: json['rejected'] as int,
  );

  final String id;
  final String name;
  final GateLiveStatus status;
  final DateTime? lastSeenAt;
  final DateTime? lastScanAt;

  /// Today's accepted and rejected scans.
  final int entries;
  final int rejected;

  @override
  List<Object?> get props => [id, name, status, lastSeenAt, lastScanAt, entries, rejected];
}

class HourCount extends Equatable {
  const HourCount(this.hour, this.entries);

  factory HourCount.fromJson(Map<String, dynamic> json) =>
      HourCount(json['hour'] as int, json['entries'] as int);

  /// 0–23 in the venue's time zone.
  final int hour;
  final int entries;

  @override
  List<Object?> get props => [hour, entries];
}

/// One row of the scan feed. The server sends no gate code (ADR-0030).
class FeedScan extends Equatable {
  const FeedScan({
    required this.id,
    required this.scannedAt,
    required this.gateName,
    required this.accepted,
    required this.reason,
    required this.typeNameAr,
    required this.typeNameEn,
    required this.poolCode,
  });

  factory FeedScan.fromJson(Map<String, dynamic> json) => FeedScan(
    id: json['scan_id'] as String,
    scannedAt: DateTime.parse(json['scanned_at'] as String),
    gateName: json['gate_name'] as String,
    accepted: json['result'] == 'accepted',
    reason: json['reason'] as String?,
    typeNameAr: json['type_name_ar'] as String?,
    typeNameEn: json['type_name_en'] as String?,
    poolCode: json['pool_code'] as bool,
  );

  final String id;
  final DateTime scannedAt;
  final String gateName;
  final bool accepted;

  /// `scan_reject_reason` when rejected.
  final String? reason;

  /// Null for an unknown code, or a pool code whose sale hasn't uploaded.
  final String? typeNameAr;
  final String? typeNameEn;

  /// An offline pool code (ADR-0015).
  final bool poolCode;

  @override
  List<Object?> get props => [
    id,
    scannedAt,
    gateName,
    accepted,
    reason,
    typeNameAr,
    typeNameEn,
    poolCode,
  ];
}

/// `dashboard_today`'s answer: the venue's day so far.
class DashboardSnapshot extends Equatable {
  const DashboardSnapshot({
    required this.now,
    required this.day,
    this.dayStartHour = 0,
    required this.currentHour,
    required this.entries,
    required this.firstEntryAt,
    required this.salesPiastres,
    required this.openCounters,
    required this.ticketsSold,
    required this.ticketsNotEntered,
    required this.rejected,
    required this.rejectedByReason,
    required this.gates,
    required this.hours,
    required this.feed,
  });

  factory DashboardSnapshot.fromJson(Map<String, dynamic> json) => DashboardSnapshot(
    now: DateTime.parse(json['now'] as String),
    day: DateTime.parse(json['day'] as String),
    dayStartHour: switch (json['day_starts_at']) {
      final String start => int.parse(start.split(':').first),
      _ => 0,
    },
    currentHour: json['current_hour'] as int,
    entries: json['entries'] as int,
    firstEntryAt: _time(json['first_entry_at']),
    salesPiastres: json['sales_piastres'] as int,
    openCounters: json['open_counters'] as int,
    ticketsSold: json['tickets_sold'] as int,
    ticketsNotEntered: json['tickets_not_entered'] as int,
    rejected: json['rejected'] as int,
    rejectedByReason: {
      for (final MapEntry(:key, :value)
          in (json['rejected_by_reason'] as Map<String, dynamic>).entries)
        key: value as int,
    },
    gates: [
      for (final gate in json['gates'] as List<dynamic>)
        GateCard.fromJson(gate as Map<String, dynamic>),
    ],
    hours: [
      for (final hour in json['hours'] as List<dynamic>)
        HourCount.fromJson(hour as Map<String, dynamic>),
    ],
    feed: [
      for (final scan in json['feed'] as List<dynamic>)
        FeedScan.fromJson(scan as Map<String, dynamic>),
    ],
  );

  /// The server's clock when it answered, so ages don't depend on this PC's.
  final DateTime now;

  /// The venue's day (date only).
  final DateTime day;

  /// The hour the venue day starts in (`day_starts_at`, ADR-0038): the
  /// chart's first hour, wrapping past midnight.
  final int dayStartHour;

  /// The hour now in the venue's time zone.
  final int currentHour;

  final int entries;
  final DateTime? firstEntryAt;

  /// Paid today minus refunded today.
  final int salesPiastres;

  /// Open shifts.
  final int openCounters;
  final int ticketsSold;
  final int ticketsNotEntered;
  final int rejected;
  final Map<String, int> rejectedByReason;
  final List<GateCard> gates;
  final List<HourCount> hours;
  final List<FeedScan> feed;

  /// Whether something on screen shows an age ("12 s ago") that needs a tick.
  bool get hasAges => gates.any((gate) => gate.lastScanAt != null);

  @override
  List<Object?> get props => [
    now,
    day,
    dayStartHour,
    currentHour,
    entries,
    firstEntryAt,
    salesPiastres,
    openCounters,
    ticketsSold,
    ticketsNotEntered,
    rejected,
    rejectedByReason,
    gates,
    hours,
    feed,
  ];
}

DateTime? _time(Object? value) => value == null ? null : DateTime.parse(value as String);
