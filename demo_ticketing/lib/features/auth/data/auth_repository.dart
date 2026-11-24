import '../../../demo/backend.dart';

import 'staff.dart';

/// Why a login or session check failed. The login screen shows one message
/// per kind.
enum AuthFailureKind {
  missingFields,
  invalidCredentials,
  accountInactive,
  serverUnreachable,

  /// The server refused the saved session, and it's gone from this PC. Nothing
  /// is wrong: the staff member signs in again.
  sessionEnded,
  unexpected,
}

class AuthFailure implements Exception {
  const AuthFailure(this.kind);

  final AuthFailureKind kind;

  @override
  String toString() => 'AuthFailure(${kind.name})';
}

/// Supabase Auth plus the reads the app needs right after login.
///
/// Every method throws [AuthFailure] rather than Supabase or network errors.
class AuthRepository {
  AuthRepository(this._client);

  final DemoBackend _client;

  /// Staff auth emails are `<username>@staff.local` (ADR-0021).
  static const emailDomain = 'staff.local';

  /// Same pattern as the `staff.username` check.
  static final _username = RegExp(r'^[a-z0-9._-]{3,32}$');

  /// The auth email for a typed username, or null if it can't be one.
  static String? emailFor(String typed) {
    final username = typed.trim().toLowerCase();
    return _username.hasMatch(username) ? '$username@$emailDomain' : null;
  }

  /// A session was saved by an earlier run (supabase_flutter persists it).
  bool get hasSession => _client.currentUserId != null;

  /// The saved session's user. Known with the server down, even once its
  /// access token has expired.
  String? get currentUserId => _client.currentUserId;

  /// Fires when the session ends: the app's own sign-out, or a refresh token
  /// the server no longer accepts.
  Stream<void> get signedOut => _client.signedOutEvents;

  /// A new access token from the refresh token: after an outage longer than
  /// the token's life, the upload of offline sales needs one (ADR-0015).
  /// A refresh token the server no longer accepts signs out ([signedOut]).
  Future<void> refreshSession() async {
    // The demo's session never expires.
  }

  Future<void> signIn(String username, String password) async {
    final email = emailFor(username);
    // Not a possible username: same answer as a wrong password, no round trip.
    if (email == null) throw const AuthFailure(AuthFailureKind.invalidCredentials);
    try {
      await _client.signIn(email, password);
    } on AuthException {
      throw const AuthFailure(AuthFailureKind.invalidCredentials);
    } on ServerUnreachable {
      throw const AuthFailure(AuthFailureKind.serverUnreachable);
    }
  }

  /// The logged-in staff member, or null when the login has no active staff
  /// row (RLS returns nothing for inactive staff).
  Future<Staff?> loadMe() async {
    final userId = _client.currentUserId;
    if (userId == null) return null;
    try {
      return await _readMe(userId);
    } on PostgrestException catch (e) {
      if (e.code != 'PGRST301' && e.code != 'PGRST303') throw AuthFailure(_failureKindFor(e));
    } on Exception catch (e) {
      throw AuthFailure(_failureKindFor(e));
    }
    // PostgREST refused the access token (expired, or signed with other keys),
    // which the client can't see for itself. A new one may fix it; a refresh
    // token the server refuses too removes the session.
    try {
      // The demo's session never expires.
      return await _readMe(userId);
    } on Exception catch (e) {
      throw AuthFailure(_failureKindFor(e));
    }
  }

  /// A plain list, not `maybeSingle()`: that one reports every error by its
  /// HTTP status, which would hide the `PGRST301` that [loadMe] looks for.
  Future<Staff?> _readMe(String userId) async {
    final rows = await _client
        .from('staff')
        .select('id, full_name, username, role, language')
        .eq('id', userId);
    if (rows.isEmpty) return null;
    final settings = await _client.from('settings').select('default_language').single();
    return Staff.fromRow(rows.single, defaultLanguage: settings['default_language'] as String);
  }

  /// The client removes the session on any refresh the server refuses, and
  /// keeps it on a network or 5xx failure (retryable). So a refusal with no
  /// session left means the session ended, whatever the server's error code.
  AuthFailureKind _failureKindFor(Exception error) => switch (error) {
        AuthRetryableFetchException() => AuthFailureKind.serverUnreachable,
        AuthException() || PostgrestException() =>
          hasSession ? AuthFailureKind.unexpected : AuthFailureKind.sessionEnded,
        // Socket and HTTP client errors: the server can't be reached.
        _ => AuthFailureKind.serverUnreachable,
      };

  /// Saves the caller's own language (`set_my_language`).
  Future<void> setMyLanguage(String languageCode) async {
    try {
      await _client.rpc<void>('set_my_language', params: {'p_language': languageCode});
    } on Exception {
      throw const AuthFailure(AuthFailureKind.unexpected);
    }
  }

  /// Ends the session on this PC. The local session is removed first, so
  /// this works with the server down; telling the server is best effort.
  Future<void> signOut() async {
    try {
      await _client.signOut();
    } on Exception {
      // Already signed out locally.
    }
  }
}
