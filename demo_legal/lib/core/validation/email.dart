/// Loose email format check for forms: one `@`, no spaces, and a dot in the
/// domain. The server is the real authority; this only catches typos early.
bool looksLikeEmail(String input) => _email.hasMatch(input.trim());

final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
