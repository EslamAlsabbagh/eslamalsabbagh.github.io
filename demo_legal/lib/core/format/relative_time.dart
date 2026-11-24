import '../../l10n/gen/app_localizations.dart';
import 'app_formats.dart';
import 'arabic_count.dart';
import 'due_label.dart';

/// How long ago something happened, for update times in the task drawer
/// (spec §5): «الآن», «منذ ٥ دقائق», «منذ ساعتين», «أمس», «منذ ٣ أيام»,
/// then the date.
///
/// Uses the device clock and time zone: this is a display nicety, not a
/// business rule like urgency (which comes from the Cairo date in the DB).
abstract final class RelativeTime {
  static String format(AppLocalizations l10n, DateTime time, {required DateTime now}) {
    final elapsed = now.difference(time);
    // A clock slightly behind the server's can make a new update look future.
    if (elapsed.inMinutes < 1) return l10n.timeNow;
    if (elapsed.inMinutes < 60) return l10n.timeAgo(_minutes(l10n, elapsed.inMinutes));

    final days = _calendarDays(time, now);
    if (days == 0) return l10n.timeAgo(_hours(l10n, elapsed.inHours));
    if (days == 1) return l10n.timeYesterday;
    if (days < 7) return l10n.timeAgo(DueLabel.days(l10n, days));
    return time.year == now.year ? AppFormats.dayMonth(time) : AppFormats.fullDate(time);
  }

  /// Whole calendar days from [from] to [to], ignoring the time of day.
  /// UTC dates, so a DST change can't shorten a day.
  static int _calendarDays(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  static String _minutes(AppLocalizations l10n, int count) => arabicCount(
        count,
        one: l10n.minuteOne,
        two: l10n.minuteTwo,
        few: l10n.minutesFew,
        many: l10n.minutesMany,
      );

  static String _hours(AppLocalizations l10n, int count) => arabicCount(
        count,
        one: l10n.hourOne,
        two: l10n.hourTwo,
        few: l10n.hoursFew,
        many: l10n.hoursMany,
      );
}
