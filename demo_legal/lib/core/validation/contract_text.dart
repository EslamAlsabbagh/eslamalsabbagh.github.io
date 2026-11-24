import 'task_text.dart';

/// The contract register's text limits, the same as the database's checks
/// (`contracts_text_lengths`, `parties_name_length`, `units_code_length`,
/// `units_key_number`). Counted in code points like [TaskText]; fields cap
/// with `CodePointLimitFormatter`.
abstract final class ContractText {
  static const int subjectMax = 300;
  static const int activityMax = 300;
  static const int noteMax = 200;
  static const int reasonMax = 500;
  static const int notesMax = 5000;
  static const int partyMax = 200;
  static const int unitCodeMax = 50;
  static const int keyNumberMax = 20;

  /// A checklist item's label and detail (`contract_items_text_lengths`).
  static const int itemLabelMax = 200;
  static const int itemDetailMax = 500;

  /// Whether [text], trimmed, is within [max]; empty is fine.
  static bool fits(String text, int max) => TaskText.length(text.trim()) <= max;

  /// Not blank and within [max] once trimmed.
  static bool isFilled(String text, int max) => text.trim().isNotEmpty && fits(text, max);
}

final RegExp _area = RegExp(r'^\d{1,8}(\.\d{1,2})?$');

/// An area typed as m²: a comma, «،» or «٫» is the decimal point (the sheets
/// write `35,3`), Arabic-Indic digits are read, at most 8 digits before the
/// point and 2 after (`numeric(10, 2)`), never negative.
///
/// Null for blank text; `(value: null, valid: false)` for anything else that
/// isn't such a number.
({double? value, bool valid}) parseArea(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return (value: null, valid: true);
  final buffer = StringBuffer();
  for (final rune in trimmed.runes) {
    if (rune >= 0x0660 && rune <= 0x0669) {
      buffer.writeCharCode(0x30 + rune - 0x0660);
    } else if (rune == 0x2C || rune == 0x060C || rune == 0x066B) {
      buffer.write('.');
    } else {
      buffer.writeCharCode(rune);
    }
  }
  final ascii = buffer.toString();
  if (!_area.hasMatch(ascii)) return (value: null, valid: false);
  return (value: double.parse(ascii), valid: true);
}

final RegExp _annexNo = RegExp(r'^\d{1,4}$');

/// An annex number as typed, ASCII or Arabic-Indic digits: a whole number
/// above 0, or null for anything else.
int? parseAnnexNo(String text) {
  final buffer = StringBuffer();
  for (final rune in text.trim().runes) {
    buffer.writeCharCode(rune >= 0x0660 && rune <= 0x0669 ? 0x30 + rune - 0x0660 : rune);
  }
  final ascii = buffer.toString();
  if (!_annexNo.hasMatch(ascii)) return null;
  final number = int.parse(ascii);
  return number > 0 ? number : null;
}
