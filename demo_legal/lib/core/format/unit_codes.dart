import 'arabic_normalize.dart';

final RegExp _joiners = RegExp(r'\s*[+&]\s*');
final RegExp _segments = RegExp(r'\s*[-–—]\s*');

/// The units in a code the sheets write as several joined with `+` or `&`
/// (ADR-0013 amendment): each later part replaces as many trailing segments
/// of the code before it as it has, so `A21-GF-U04+U05` is `A21-GF-U04`,
/// `A21-GF-U05`, and `A40-GF-U03+U04+L1-U12` is `A40-GF-U03`, `A40-GF-U04`,
/// `A40-L1-U12`. A part with as many segments as the code before it, or
/// more, is a full code of its own.
///
/// One code (no joiner) comes back alone, trimmed. Repeats (by
/// [unitCodeKey]) and empty parts are dropped.
List<String> splitUnitCodes(String text) {
  final parts = text.trim().split(_joiners).where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return const [];
  final codes = <String>[parts.first];
  var base = parts.first.split(_segments);
  for (final part in parts.skip(1)) {
    final segments = part.split(_segments);
    if (segments.length >= base.length) {
      codes.add(part);
      base = segments;
    } else {
      base = [...base.take(base.length - segments.length), ...segments];
      codes.add(base.join('-'));
    }
  }
  final seen = <String>{};
  return [
    for (final code in codes)
      if (seen.add(unitCodeKey(code))) code,
  ];
}

/// Whether [text] joins several unit codes with `+` or `&`.
bool joinsUnitCodes(String text) => splitUnitCodes(text).length > 1;
