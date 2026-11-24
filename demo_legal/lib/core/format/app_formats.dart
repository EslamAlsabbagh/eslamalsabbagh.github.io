import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Single place for number and date formatting.
///
/// `ar_EG` gives Arabic-Indic digits (١٢٣), as the design requires.
/// If the firm picks Western digits, change [locale] only.
abstract final class AppFormats {
  /// Switched by the demo's language toggle (`DemoStore.setLocale`).
  static String locale = 'en_US';

  static bool get _arabic => locale.startsWith('ar');

  /// Loads date symbols for both languages. Call once before using any formatter.
  static Future<void> init() async {
    await initializeDateFormatting('ar_EG');
    await initializeDateFormatting('en_US');
  }

  /// Full header date, e.g. "الثلاثاء، ١٣ أكتوبر ٢٠٢٦".
  static String headerDate(DateTime date) =>
      DateFormat(_arabic ? 'EEEE، d MMMM y' : 'EEEE, d MMMM y', locale).format(date);

  /// Day and month, e.g. "٢١ أكتوبر" (due dates a week or more away).
  static String dayMonth(DateTime date) => DateFormat('d MMMM', locale).format(date);

  /// Day, month and year, e.g. "١٣ أكتوبر ٢٠٢٦" (the drawer's due date field).
  static String fullDate(DateTime date) => DateFormat('d MMMM y', locale).format(date);

  /// A year with locale digits and no grouping, e.g. 2026 → "٢٠٢٦" (the
  /// contracts' «الموسم»).
  static String year(int value) => DateFormat('y', locale).format(DateTime(value));

  /// Integer with locale digits, e.g. 12 → "١٢".
  static String number(num value) => NumberFormat.decimalPattern(locale).format(value);
}
