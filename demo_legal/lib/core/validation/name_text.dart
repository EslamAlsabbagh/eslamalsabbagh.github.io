import 'task_text.dart';

/// A file or topic name's limit, the same as the database's
/// `files_name_length` / `topics_name_length` checks. Counted in code points
/// like [TaskText]; the field caps with `CodePointLimitFormatter(NameText.max)`.
abstract final class NameText {
  static const int max = 100;

  /// Not blank and within [max] once trimmed.
  static bool isValid(String name) {
    final trimmed = name.trim();
    return trimmed.isNotEmpty && TaskText.length(trimmed) <= max;
  }
}
