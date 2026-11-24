import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../offline/data/offline_store.dart';
import '../data/auth_repository.dart';
import '../data/staff.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Startup, while a saved session is being checked.
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class AuthSignedOut extends AuthState {
  const AuthSignedOut({this.failure});

  /// Why the last attempt failed; null after a normal sign-out.
  final AuthFailureKind? failure;

  @override
  List<Object?> get props => [failure];
}

final class AuthSigningIn extends AuthState {
  const AuthSigningIn();
}

final class AuthSignedIn extends AuthState {
  const AuthSignedIn(this.staff, {this.fromCopy = false});

  final Staff staff;

  /// The app started with the server out of reach, so this is the copy kept
  /// on this PC (ADR-0026). The first answer from the server replaces it.
  final bool fromCopy;

  @override
  List<Object?> get props => [staff, fromCopy];
}

/// Who is logged in. The router redirects on it (ADR-0011); roles are
/// enforced by RLS and the Postgres functions, not here.
///
/// A saved session keeps working through an outage: a counter PC restarted
/// while the server is down starts from a copy of the staff row, tied to the
/// session's user (ADR-0026). A new sign-in always needs the server.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._repository, {
    required this._store,
    this._serverWait = const Duration(seconds: 5),
  }) : super(const AuthUnknown()) {
    _signedOut = _repository.signedOut.listen(
      (_) {
        _store.deleteCache(_copyKey);
        if (state is AuthSignedIn) emit(const AuthSignedOut());
      },
      // A failed background refresh arrives here while the server is down. It
      // isn't a sign-out: the session stays.
      onError: (Object _) {},
    );
  }

  final AuthRepository _repository;
  final OfflineStore _store;

  /// How long a start waits for the server when it has a copy to fall back on:
  /// a refresh with no network retries for ~10 s.
  final Duration _serverWait;
  late final StreamSubscription<void> _signedOut;
  bool _confirming = false;

  static const _copyKey = 'me';

  /// Picks up a session saved by an earlier run.
  Future<void> restore() async {
    if (!_repository.hasSession) return emit(const AuthSignedOut());
    await _enter(copy: _readCopy());
  }

  /// The server answered: an app started from the copy reads the staff row
  /// again. A login no longer active is signed out; while the read fails, the
  /// copy stays and the next answer tries again.
  Future<void> confirm() async {
    final current = state;
    if (current is! AuthSignedIn || !current.fromCopy || _confirming) return;
    _confirming = true;
    try {
      final staff = await _repository.loadMe();
      if (isClosed || state != current) return;
      if (staff == null) {
        _store.deleteCache(_copyKey);
        await _repository.signOut();
        if (!isClosed) emit(const AuthSignedOut(failure: AuthFailureKind.accountInactive));
        return;
      }
      _saveCopy(staff);
      emit(AuthSignedIn(staff));
    } on AuthFailure {
      // The next answer tries again.
    } finally {
      _confirming = false;
    }
  }

  Staff? _readCopy() {
    final userId = _repository.currentUserId;
    final json = _store.readCache(_copyKey);
    if (userId == null || json is! Map<String, dynamic> || json['id'] != userId) return null;
    try {
      return Staff.fromRow(json, defaultLanguage: json['language'] as String);
    } on Object {
      // From an older app version: as if none.
      return null;
    }
  }

  void _saveCopy(Staff staff, {String? language}) =>
      _store.writeCache(_copyKey, staff.toRow(language: language), now: DateTime.now());

  Future<void> signIn(String username, String password) async {
    if (state is AuthSigningIn) return;
    if (username.trim().isEmpty || password.isEmpty) {
      return emit(const AuthSignedOut(failure: AuthFailureKind.missingFields));
    }
    emit(const AuthSigningIn());
    try {
      await _repository.signIn(username, password);
    } on AuthFailure catch (e) {
      return emit(AuthSignedOut(failure: e.kind));
    }
    await _enter();
  }

  Future<void> signOut() async {
    _store.deleteCache(_copyKey);
    await _repository.signOut();
    emit(const AuthSignedOut());
  }

  /// Saves a language the staff member picked. Best effort: if it fails, the
  /// switch still works on this PC and the server keeps the old choice.
  Future<void> saveLanguage(String languageCode) async {
    final current = state;
    if (current is! AuthSignedIn) return;
    _saveCopy(current.staff, language: languageCode);
    try {
      await _repository.setMyLanguage(languageCode);
    } on AuthFailure {
      // Nothing to show: the language already changed on screen.
    }
  }

  /// A session exists: load the staff row behind it. A login without an
  /// active staff row is signed out again. With the server out of reach, [copy]
  /// stands in for the row until it answers.
  Future<void> _enter({Staff? copy}) async {
    try {
      final read = _repository.loadMe();
      final staff = await (copy == null ? read : read.timeout(_serverWait));
      if (staff == null) {
        _store.deleteCache(_copyKey);
        await _repository.signOut();
        return emit(const AuthSignedOut(failure: AuthFailureKind.accountInactive));
      }
      _saveCopy(staff);
      emit(AuthSignedIn(staff));
    } on TimeoutException {
      emit(AuthSignedIn(copy!, fromCopy: true));
    } on AuthFailure catch (e) {
      if (copy != null && e.kind == AuthFailureKind.serverUnreachable) {
        return emit(AuthSignedIn(copy, fromCopy: true));
      }
      emit(AuthSignedOut(failure: e.kind));
    }
  }

  @override
  Future<void> close() async {
    await _signedOut.cancel();
    return super.close();
  }
}
