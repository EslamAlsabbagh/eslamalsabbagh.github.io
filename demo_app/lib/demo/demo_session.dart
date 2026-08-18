import 'dart:async';

import 'package:hrms_demo/demo/demo_seed.dart';
import 'package:hrms_demo/demo/demo_store.dart';

/// Stands in for the Supabase auth session.
///
/// `AuthGate` routes on two things: whether a session exists, and the email on
/// it (from which the employee code is parsed). This object provides exactly
/// that, plus a change stream so the gate re-renders on sign-in and sign-out.
///
/// The demo signs itself in on startup — a portfolio visitor should land in the
/// product, not on a login wall — but the login screen stays reachable through
/// logout so the flow is still demonstrable.
class DemoSession {
  DemoSession({bool autoSignIn = true}) {
    if (autoSignIn) _code = DemoSeed.defaultUserCode;
  }

  final StreamController<void> _controller = StreamController<void>.broadcast();

  int? _code;

  /// Fires whenever the session appears or disappears.
  Stream<void> get changes => _controller.stream;

  bool get isSignedIn => _code != null;

  /// Mirrors `supabase.auth.currentUser?.email`; the app parses the employee
  /// code back out of this, so the shape has to match production.
  String? get email => _code == null ? null : '$_code@demo.local';

  int? get currentCode => _code;

  void signIn(int code) {
    _code = code;
    DemoStore.instance.switchUser(code);
    _controller.add(null);
  }

  void signOut() {
    _code = null;
    _controller.add(null);
  }

  /// Used by the role switcher: swaps identity without leaving the app.
  void switchTo(int code) => signIn(code);

  void dispose() => _controller.close();
}
