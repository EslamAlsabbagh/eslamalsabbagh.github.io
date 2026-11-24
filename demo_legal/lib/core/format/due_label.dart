import '../../l10n/gen/app_localizations.dart';
import 'app_formats.dart';
import 'arabic_count.dart';

/// Due labels from `docs/design/DESIGN_SPEC.md` §1 "Numerals & dates".
///
/// [daysUntilDue] comes from the `task_list` view (due date minus the Cairo
/// date), so the device clock never decides what "today" is.
abstract final class DueLabel {
  /// «متأخرة منذ يومين», «اليوم», «غدًا», «بعد ٣ أيام», or «٢١ أكتوبر» from a
  /// week out.
  static String format(AppLocalizations l10n, {required int daysUntilDue, required DateTime dueDate}) {
    if (daysUntilDue < 0) return l10n.dueOverdueSince(days(l10n, -daysUntilDue));
    if (daysUntilDue == 0) return l10n.dueToday;
    if (daysUntilDue == 1) return l10n.dueTomorrow;
    if (daysUntilDue < 7) return l10n.dueIn(days(l10n, daysUntilDue));
    return AppFormats.dayMonth(dueDate);
  }

  /// Day phrase with the design's plural rule: 1 → يوم, 2 → يومين,
  /// 3–10 → «n أيام», 11+ → «n يومًا». [count] must be at least 1.
  static String days(AppLocalizations l10n, int count) => arabicCount(
        count,
        one: l10n.dayOne,
        two: l10n.dayTwo,
        few: l10n.daysFew,
        many: l10n.daysMany,
      );
}
