/// The database's matching keys, for lists the app already holds (the brand
/// field filters the loaded topics, the linked-lease field the loaded
/// contracts). Keep these in step with `public.normalize_ar` and
/// `public.unit_code_key`; everything the server matches uses those.
library;

final RegExp _marks = RegExp('[ً-ْٰـ]');
final RegExp _spaces = RegExp(r'\s+');
final RegExp _codeSeparators = RegExp(r'[\s_/\\.,،–—-]');

const Map<String, String> _letters = {
  'أ': 'ا',
  'إ': 'ا',
  'آ': 'ا',
  'ٱ': 'ا',
  'ة': 'ه',
  'ى': 'ي',
};

/// `public.normalize_ar`: lowercase, no tashkeel or tatweel, أ/إ/آ/ٱ → ا,
/// ة → ه, ى → ي, runs of spaces as one, trimmed.
String normalizeAr(String input) {
  final stripped = input.toLowerCase().replaceAll(_marks, '');
  final buffer = StringBuffer();
  for (final char in stripped.split('')) {
    buffer.write(_letters[char] ?? char);
  }
  return buffer.toString().replaceAll(_spaces, ' ').trim();
}

/// `public.unit_code_key`: [normalizeAr], Arabic-Indic and Persian digits as
/// ASCII, no spaces or `_ / \ . , ، – — -`, uppercase. So «c14 gf u02» and
/// `C14-GF-U02` have the same key.
String unitCodeKey(String code) {
  final buffer = StringBuffer();
  for (final rune in normalizeAr(code).runes) {
    if (rune >= 0x0660 && rune <= 0x0669) {
      buffer.writeCharCode(0x30 + rune - 0x0660);
    } else if (rune >= 0x06F0 && rune <= 0x06F9) {
      buffer.writeCharCode(0x30 + rune - 0x06F0);
    } else {
      buffer.writeCharCode(rune);
    }
  }
  return buffer.toString().replaceAll(_codeSeparators, '').toUpperCase();
}
