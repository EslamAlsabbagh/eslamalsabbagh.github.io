import 'package:hrms_demo/data/repos/storage/storage_keys.dart';
import 'package:hrms_demo/data/repos/storage/storage_repo.dart';
import 'package:hrms_demo/demo/demo_session.dart';
import 'package:flutter/foundation.dart';

/// Clears the demo session and every credential we persist.
///
/// In production this signs out of Supabase Auth. The demo has no identity
/// provider, so it clears [DemoSession] instead — which is what `AuthGate`
/// listens to, so the app swaps back to the login screen exactly as it does
/// against the real backend.
class AuthService {
  const AuthService({required DemoSession session, required StorageRepo storage})
    : _session = session,
      _storage = storage;

  final DemoSession _session;
  final StorageRepo _storage;

  /// Signs out and wipes stored credentials.
  ///
  /// Routing is owned by `AuthGate`: clearing the session fires its change
  /// stream, which makes the gate render the login screen. This method
  /// therefore never navigates.
  ///
  /// Never throws. Returns `true` when sign-out completed cleanly.
  Future<bool> signOutAndClearCredentials() async {
    try {
      _session.signOut();
      await _storage.delete(StorageKeys.userCode.key);
      await _storage.delete(StorageKeys.language.key);
      await _storage.delete('weak_password_flag');
      return true;
    } catch (e) {
      debugPrint('Logout error: $e');
      return false;
    }
  }
}
