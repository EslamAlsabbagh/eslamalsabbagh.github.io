import 'task_text.dart';

/// The password rule, the same as GoTrue's `minimum_password_length`
/// (the auth server's minimum length).
/// Counted in code points like [TaskText]. GoTrue counts bytes, and every
/// code point is at least one byte, so a password that passes here passes there.
abstract final class PasswordText {
  static const int min = 8;

  static bool isValid(String password) => TaskText.length(password) >= min;
}
