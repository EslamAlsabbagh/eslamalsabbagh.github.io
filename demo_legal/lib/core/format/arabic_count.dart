import 'app_formats.dart';

/// The design's Arabic plural rule for counted phrases (spec §1):
/// 1 → [one] («يوم»), 2 → [two] («يومين»), 3–10 → [few] («٣ أيام»),
/// 11+ → [many] («١١ يومًا»). [few] and [many] get the count already
/// formatted with locale digits, or with [format] (the exported register
/// writes Western digits).
///
/// Built in Dart, not as ICU plurals: gen-l10n formats ICU numbers with the
/// `ar` locale, which gives Western digits.
String arabicCount(
  int count, {
  required String one,
  required String two,
  required String Function(String count) few,
  required String Function(String count) many,
  String Function(int count) format = _localeDigits,
}) {
  assert(count >= 1, 'a counted phrase needs at least one');
  if (count == 1) return one;
  if (count == 2) return two;
  if (count <= 10) return few(format(count));
  return many(format(count));
}

String _localeDigits(int count) => AppFormats.number(count);
