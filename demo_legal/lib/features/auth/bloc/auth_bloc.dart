import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../data/auth_user.dart';
import '../data/user_profile.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Tracks whether someone is signed in with an active account. Provided at
/// the app root.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  /// Callers pass `authRepository:`; Dart drops the underscore for the name.
  AuthBloc({required this._authRepository}) : super(const AuthState.unknown()) {
    on<AuthSubscriptionRequested>(_onSubscriptionRequested);
    // One at a time, in order: each change may wait on a profile fetch, and a
    // later sign-out must not be overtaken by an earlier sign-in.
    on<_AuthUserChanged>(_onUserChanged, transformer: (events, mapper) => events.asyncExpand(mapper));
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  final AuthRepository _authRepository;

  Future<void> _onSubscriptionRequested(
    AuthSubscriptionRequested event,
    Emitter<AuthState> emit,
  ) async {
    add(_AuthUserChanged(_authRepository.currentUser));
    await emit.onEach(_authRepository.userChanges, onData: (user) => add(_AuthUserChanged(user)));
  }

  Future<void> _onUserChanged(_AuthUserChanged event, Emitter<AuthState> emit) async {
    final user = event.user;

    if (user == null) {
      // Already signed out: keep any notice (e.g. the sign-out that follows
      // an inactive account must not clear «الحساب معطّل»).
      if (state.status != AuthStatus.unauthenticated) emit(const AuthState.unauthenticated());
      return;
    }

    // Token refreshes and the startup `initialSession` repeat the same user.
    if (state.status == AuthStatus.authenticated && state.user?.id == user.id) {
      emit(AuthState.authenticated(user, state.profile!));
      return;
    }

    final UserProfile? profile;
    try {
      profile = await _authRepository.fetchProfile(user.id);
    } catch (error, stackTrace) {
      log('Profile fetch failed', name: 'auth', error: error, stackTrace: stackTrace);
      if (!_isStillSignedInAs(user)) return;
      // Keep the session: the next sign-in, token refresh or reload retries.
      emit(const AuthState.unauthenticated(notice: AuthNotice.serverUnreachable));
      return;
    }

    if (!_isStillSignedInAs(user)) return;
    if (profile == null) {
      emit(const AuthState.unauthenticated(notice: AuthNotice.accountDisabled));
      await _authRepository.signOut();
    } else {
      emit(AuthState.authenticated(user, profile));
    }
  }

  /// False if the user signed out (or another user signed in) while a
  /// profile fetch was running; its result is then stale.
  bool _isStillSignedInAs(AuthUser user) => _authRepository.currentUser?.id == user.id;

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    // The new state arrives through userChanges.
    await _authRepository.signOut();
  }
}
