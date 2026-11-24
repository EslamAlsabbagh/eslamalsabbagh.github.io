import 'package:equatable/equatable.dart';

/// A time of day in the venue's time zone, as `settings` keeps it
/// (`venue_day_starts_at`, `closing_time`).
///
/// The app has no time zone database: it uses the PC's zone, which must be
/// the venue's (ADR-0015). The pool's expiry checks it (ADR-0025).
class VenueTime extends Equatable {
  const VenueTime(this.hour, this.minute);

  static const midnight = VenueTime(0, 0);

  final int hour;
  final int minute;

  /// Minutes after midnight.
  int get minutes => hour * 60 + minute;

  /// Postgres sends a `time` as "23:00:00".
  factory VenueTime.parse(String value) {
    final parts = value.split(':');
    if (parts.length < 2) throw FormatException('Not a time: $value');
    return VenueTime(int.parse(parts[0]), int.parse(parts[1]));
  }

  /// Seconds after midnight, as the Settings page keeps a time.
  factory VenueTime.ofSeconds(int seconds) => VenueTime(seconds ~/ 3600, seconds % 3600 ~/ 60);

  /// Whether [instant], in the PC's time zone, falls at this time of day: a
  /// pool code expires at closing, so a mismatch means the PC's zone isn't
  /// the venue's.
  bool matches(DateTime instant) {
    final local = instant.toLocal();
    return local.hour == hour && local.minute == minute;
  }

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';

  @override
  List<Object?> get props => [hour, minute];
}

/// The venue day (ADR-0038): from [start] to the same time the next day.
/// A [closing] at or before [start] falls on the next calendar date, so a
/// 02:00 closing is the night after.
///
/// Mirrors the database's `venue_day_of`, `venue_day_start` and
/// `venue_day_closing`, on the PC's clock and zone.
class VenueDay extends Equatable {
  const VenueDay({required this.start, required this.closing});

  /// Days from midnight to midnight, closing at the end of the day: how the
  /// app worked before ADR-0038, and an offline copy from before it.
  static const midnight = VenueDay(start: VenueTime.midnight, closing: VenueTime.midnight);

  final VenueTime start;
  final VenueTime closing;

  /// Whether closing is on the calendar date after the day's own.
  bool get closesNextDate => closing.minutes <= start.minutes;

  /// The venue day [at] falls in, as a date (local midnight).
  DateTime dayOf(DateTime at) {
    final local = at.toLocal();
    final before = local.hour * 60 + local.minute < start.minutes;
    return DateTime(local.year, local.month, local.day - (before ? 1 : 0));
  }

  /// When venue day [day] starts.
  DateTime startOf(DateTime day) =>
      DateTime(day.year, day.month, day.day, start.hour, start.minute);

  /// When venue day [day] closes.
  DateTime closingOf(DateTime day) => DateTime(
    day.year,
    day.month,
    day.day + (closesNextDate ? 1 : 0),
    closing.hour,
    closing.minute,
  );

  /// Closing of the venue day [at] falls in: the end of a same-day ticket
  /// sold at [at].
  DateTime closingFor(DateTime at) => closingOf(dayOf(at));

  /// How long after the day's start the time of day [seconds] comes, from 0
  /// to 24 h, in seconds (`venue_day_offset`): with an 08:00 start, 20:00 is
  /// 12 h and 01:00 is 17 h. [end]: it ends a range, so the start itself is
  /// 24 h, the end of the day.
  int offsetSeconds(int seconds, {bool end = false}) {
    final offset = (seconds - start.minutes * 60) % Duration.secondsPerDay;
    return end && offset == 0 ? Duration.secondsPerDay : offset;
  }

  /// Whether a daily range from [fromSeconds] to [toSeconds] (seconds after
  /// midnight, the end excluded) lies inside one venue day: it may run past
  /// midnight, up to the next start, but not across the start.
  bool rangeFits(int fromSeconds, int toSeconds) =>
      offsetSeconds(fromSeconds) < offsetSeconds(toSeconds, end: true);

  /// Whether the daily peak range also ends by [closing] (`peak_hours_fit`):
  /// after closing nothing same-day sells, so peak hours there mean nothing.
  bool hoursFit(int fromSeconds, int toSeconds) =>
      rangeFits(fromSeconds, toSeconds) &&
      offsetSeconds(toSeconds, end: true) <= offsetSeconds(closing.minutes * 60, end: true);

  /// When the venue day after [at]'s starts.
  DateTime nextStartAfter(DateTime at) {
    final day = dayOf(at);
    return startOf(DateTime(day.year, day.month, day.day + 1));
  }

  @override
  List<Object?> get props => [start, closing];
}
