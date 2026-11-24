import 'package:flutter/services.dart';

/// A task's title, description and update limits, the same as the database's
/// `tasks_title_length` / `tasks_description_length` / `task_updates_body_length`
/// checks.
///
/// Lengths are code points (`runes`), as Postgres `char_length` counts them:
/// each tashkeel mark is one. Dart's `String.length` (UTF-16 units) and
/// Flutter's `maxLength` (grapheme clusters) would both disagree with it.
abstract final class TaskText {
  static const int titleMax = 200;
  static const int descriptionMax = 10000;
  static const int updateMax = 5000;

  static int length(String text) => text.runes.length;

  /// Not blank and within [titleMax] once trimmed.
  static bool isValidTitle(String title) {
    final trimmed = title.trim();
    return trimmed.isNotEmpty && length(trimmed) <= titleMax;
  }

  /// Within [descriptionMax] once trimmed; empty is fine.
  static bool isValidDescription(String description) => length(description.trim()) <= descriptionMax;

  /// Not blank and within [updateMax] once trimmed.
  static bool isValidUpdate(String body) {
    final trimmed = body.trim();
    return trimmed.isNotEmpty && length(trimmed) <= updateMax;
  }
}

/// Caps a field at [max] code points (see [TaskText]).
///
/// Like Flutter's `LengthLimitingTextInputFormatter`: typing at the cap
/// changes nothing, and a paste that goes over is cut at the cap.
class CodePointLimitFormatter extends TextInputFormatter {
  const CodePointLimitFormatter(this.max);

  final int max;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (TaskText.length(newValue.text) <= max) return newValue;
    if (TaskText.length(oldValue.text) >= max) return oldValue;
    final text = String.fromCharCodes(newValue.text.runes.take(max));
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
