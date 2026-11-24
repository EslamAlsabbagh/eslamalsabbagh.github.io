import 'package:equatable/equatable.dart';

import '../../../core/venue_day.dart';
import '../../sell/data/peak_schedule.dart';

export '../../sell/data/peak_schedule.dart' show PeakSource;

/// The manual switch for today (`set_peak_override`).
enum PeakMode {
  auto('auto'),
  on('on'),
  off('off');

  const PeakMode(this.key);

  final String key;

  static PeakMode fromKey(String? key) =>
      values.firstWhere((m) => m.key == key, orElse: () => auto);
}

/// `peak_state()`: peak now and why, the schedule, and today's switch.
class PeakState extends Equatable {
  const PeakState({
    required this.peak,
    required this.source,
    required this.weekdays,
    this.fromSeconds,
    this.toSeconds,
    this.dayStartSeconds = 0,
    this.closingSeconds = 0,
    this.switchDay,
    required this.mode,
  });

  factory PeakState.fromJson(Map<String, dynamic> json) => PeakState(
    peak: json['peak'] as bool,
    source: PeakSource.fromKey(json['source'] as String?),
    weekdays: {for (final d in json['weekdays'] as List) d as int},
    fromSeconds: PeakSchedule.parseTime(json['from']),
    toSeconds: PeakSchedule.parseTime(json['to']),
    dayStartSeconds: PeakSchedule.parseTime(json['day_starts_at']) ?? 0,
    closingSeconds: PeakSchedule.parseTime(json['closing_time']) ?? 0,
    switchDay: switch (json['switch_day']) {
      final String day => DateTime.parse(day),
      _ => null,
    },
    mode: PeakMode.fromKey(json['override'] as String?),
  );

  final bool peak;
  final PeakSource source;

  /// ISO weekdays (1 = Monday .. 7 = Sunday), peak all day.
  final Set<int> weekdays;

  /// The daily range on the other days, seconds from midnight; null for none.
  final int? fromSeconds;
  final int? toSeconds;

  /// `venue_day_starts_at`: the range lies on the venue day from here
  /// (ADR-0038), so it may run past midnight up to it.
  final int dayStartSeconds;

  /// `closing_time`: the range ends by it (ADR-0038).
  final int closingSeconds;

  /// The venue day the switch acts on (`peak_switch_day`): today's, or the
  /// coming one once today's has closed. Null from an older server.
  final DateTime? switchDay;
  final PeakMode mode;

  /// Opening hours, which the daily range lies inside.
  VenueDay get venueDay => VenueDay(
    start: VenueTime.ofSeconds(dayStartSeconds),
    closing: VenueTime.ofSeconds(closingSeconds),
  );

  @override
  List<Object?> get props => [
    peak,
    source,
    weekdays,
    fromSeconds,
    toSeconds,
    dayStartSeconds,
    closingSeconds,
    switchDay,
    mode,
  ];
}
