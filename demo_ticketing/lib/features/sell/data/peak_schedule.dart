import 'package:equatable/equatable.dart';

import '../../../core/venue_day.dart';

/// Why a moment is or isn't peak: `peak_source_at`'s keys.
enum PeakSource {
  manualOn('manual_on'),
  manualOff('manual_off'),
  weekend('weekend'),
  hours('hours'),
  none('none');

  const PeakSource(this.key);

  final String key;

  bool get peak => this == manualOn || this == weekend || this == hours;

  static PeakSource fromKey(String? key) =>
      values.firstWhere((s) => s.key == key, orElse: () => none);
}

/// The venue's peak times (ADR-0033), from `settings`: weekend days all day,
/// one daily range on the other days, and the manual switch for one day.
///
/// Mirrors `peak_source_at` so the sell screen can show the right types and
/// switch at a boundary, also offline. The server decides: `sell_tickets`
/// refuses a type that isn't on sale (`ticket_type_not_now`). Times are the
/// PC's, whose zone must be the venue's (checked against the pool, ADR-0025).
///
/// The weekday and the switch's day are the venue day's (ADR-0038): 01:00 on
/// Saturday is still Friday. The daily range lies on the venue day's timeline,
/// so 20:00-01:00 is one range with an 08:00 start.
class PeakSchedule extends Equatable {
  const PeakSchedule({
    this.weekdays = const {},
    this.fromSeconds,
    this.toSeconds,
    this.manual,
    this.manualDay,
  });

  /// No peak at all: an offline copy from before peak times existed.
  static const none = PeakSchedule();

  /// ISO weekdays (1 = Monday .. 7 = Sunday), peak all day.
  final Set<int> weekdays;

  /// The daily range on the other days, in seconds from midnight; the end
  /// excluded, and it may be past midnight (on the venue day's timeline).
  /// Both null for none.
  final int? fromSeconds;
  final int? toSeconds;

  /// The switch (`peak_override`): true = peak all [manualDay], false = no
  /// peak that day.
  final bool? manual;

  /// `peak_override_day`: a venue day, as a date only (local midnight).
  final DateTime? manualDay;

  /// Why [at] is or isn't peak, with [day] deciding which venue day [at] is
  /// on.
  PeakSource sourceAt(DateTime at, {VenueDay day = VenueDay.midnight}) {
    final local = at.toLocal();
    final venueDay = day.dayOf(at);
    final switchDay = manualDay;
    if (manual != null &&
        switchDay != null &&
        switchDay.year == venueDay.year &&
        switchDay.month == venueDay.month &&
        switchDay.day == venueDay.day) {
      return manual! ? PeakSource.manualOn : PeakSource.manualOff;
    }
    if (weekdays.contains(venueDay.weekday)) return PeakSource.weekend;
    final from = fromSeconds;
    final to = toSeconds;
    if (from != null && to != null) {
      final now = day.offsetSeconds(local.hour * 3600 + local.minute * 60 + local.second);
      if (now >= day.offsetSeconds(from) && now < day.offsetSeconds(to, end: true)) {
        return PeakSource.hours;
      }
    }
    return PeakSource.none;
  }

  bool isPeakAt(DateTime at, {VenueDay day = VenueDay.midnight}) => sourceAt(at, day: day).peak;

  /// The next moment after [at] when peak may start or end: the daily
  /// range's next start or end (after midnight too), or the next venue day's
  /// start (a new weekday, and the switch's day over). Local time.
  DateTime nextChangeAfter(DateTime at, {VenueDay day = VenueDay.midnight}) {
    final local = at.toLocal();
    DateTime next(int seconds) {
      final today = DateTime(local.year, local.month, local.day, 0, 0, seconds);
      return today.isAfter(local)
          ? today
          : DateTime(local.year, local.month, local.day + 1, 0, 0, seconds);
    }

    return [
      day.nextStartAfter(at),
      if (fromSeconds case final from?) next(from),
      if (toSeconds case final to?) next(to),
    ].reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// "16:00:00" → seconds from midnight.
  static int? parseTime(Object? value) {
    if (value is! String) return null;
    final parts = value.split(':');
    if (parts.length < 2) throw FormatException('Not a time: $value');
    final seconds = parts.length > 2 ? double.parse(parts[2]).floor() : 0;
    return int.parse(parts[0]) * 3600 + int.parse(parts[1]) * 60 + seconds;
  }

  static String? timeText(int? seconds) {
    if (seconds == null) return null;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(seconds ~/ 3600)}:${two(seconds % 3600 ~/ 60)}:${two(seconds % 60)}';
  }

  /// The `settings` columns; a row without them (an older offline copy) is
  /// [none].
  factory PeakSchedule.fromRow(Map<String, dynamic> row) {
    final day = row['peak_override_day'] as String?;
    return PeakSchedule(
      weekdays: {for (final d in (row['peak_weekdays'] as List? ?? const [])) d as int},
      fromSeconds: parseTime(row['peak_from']),
      toSeconds: parseTime(row['peak_to']),
      manual: row['peak_override'] as bool?,
      manualDay: day == null ? null : DateTime.parse(day),
    );
  }

  static const columns = 'peak_weekdays, peak_from, peak_to, peak_override, peak_override_day';

  Map<String, Object?> toRow() => {
    'peak_weekdays': (weekdays.toList()..sort()),
    'peak_from': timeText(fromSeconds),
    'peak_to': timeText(toSeconds),
    'peak_override': manual,
    'peak_override_day': manualDay == null
        ? null
        : '${manualDay!.year.toString().padLeft(4, '0')}-'
              '${manualDay!.month.toString().padLeft(2, '0')}-'
              '${manualDay!.day.toString().padLeft(2, '0')}',
  };

  @override
  List<Object?> get props => [weekdays, fromSeconds, toSeconds, manual, manualDay];
}
