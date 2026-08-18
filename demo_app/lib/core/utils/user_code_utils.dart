/// Extracts the user code from a Supabase auth email.
///
/// Emails follow the format `{userCode}@demo.local`, where `userCode` is a 6- or
/// 8-digit numeric employee code. Returns `null` when the email is missing or
/// the local-part is not a valid 6/8-digit number.
///
/// This was previously duplicated across `main.dart` and `login_content.dart`;
/// it now lives here so the [AuthGate] and the login screen agree on exactly
/// what counts as a valid, navigable session.
String? extractUserCodeFromEmail(String? email) {
  if (email == null || email.isEmpty) return null;
  // Extract the part before @ symbol
  final atIndex = email.indexOf('@');
  if (atIndex == -1) return null;
  final code = email.substring(0, atIndex);
  // Validate that it's a valid numeric code (6 or 8 digits)
  if ((code.length == 6 || code.length == 8) && int.tryParse(code) != null) {
    return code;
  }
  return null;
}
