import 'package:shared_preferences/shared_preferences.dart';

/// Remembers the last UI language on this counter PC, so the login screen
/// opens in it. Anon can't read `settings.default_language`, and after login
/// the staff member's own language takes over (task 2.1).
class LocaleStore {
  LocaleStore(this._prefs);

  final SharedPreferences _prefs;

  static const _key = 'ui_language';

  String? read() => _prefs.getString(_key);

  Future<void> write(String languageCode) => _prefs.setString(_key, languageCode);
}
