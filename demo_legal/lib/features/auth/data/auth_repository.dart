import '../../../demo/demo_store.dart';
import 'auth_user.dart';
import 'sign_in_failure.dart';
import 'user_profile.dart';

/// The signed-in user and their profile.
///
/// Demo build: the session lives in [DemoStore]. Every seeded account signs
/// in with [DemoStore.password]; the demo bar's role buttons switch account
/// without the login screen.
class AuthRepository {
  AuthRepository(this._store);

  final DemoStore _store;

  /// User from the session restored at startup, or null.
  AuthUser? get currentUser => _store.currentAuthUser;

  /// Emits on every sign-in, sign-out and account switch.
  Stream<AuthUser?> get userChanges => _store.authChanges;

  /// Signs in; the new user arrives through [userChanges].
  ///
  /// Throws [SignInException] on failure.
  Future<void> signInWithPassword({required String email, required String password}) async {
    await _store.latency();
    final match = _store.profiles.where((p) => p.email.toLowerCase() == email.trim().toLowerCase()).firstOrNull;
    if (match == null || match.password != password) {
      throw const SignInException(SignInFailure.invalidCredentials);
    }
    if (!match.isActive) throw const SignInException(SignInFailure.accountDisabled);
    _store.signInAs(match.id);
  }

  /// The user's own profile, or null when the account is deactivated.
  Future<UserProfile?> fetchProfile(String userId) async {
    final p = _store.profile(userId);
    if (p == null || !p.isActive) return null;
    return UserProfile(id: p.id, displayName: p.displayName, role: p.role);
  }

  Future<void> signOut() async => _store.signOut();
}
