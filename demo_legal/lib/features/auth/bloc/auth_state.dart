part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Why the user is signed out, shown on the login screen.
enum AuthNotice {
  /// Signed in, but the profile is hidden by RLS: the account is deactivated.
  accountDisabled,

  /// Signed in, but the profile couldn't be loaded. The session is kept.
  serverUnreachable,
}

final class AuthState extends Equatable {
  const AuthState._({required this.status, this.user, this.profile, this.notice});

  /// Before the stored session and its profile have been checked.
  const AuthState.unknown() : this._(status: AuthStatus.unknown);

  const AuthState.authenticated(AuthUser user, UserProfile profile)
      : this._(status: AuthStatus.authenticated, user: user, profile: profile);

  const AuthState.unauthenticated({AuthNotice? notice})
      : this._(status: AuthStatus.unauthenticated, notice: notice);

  final AuthStatus status;

  /// Set only when [status] is [AuthStatus.authenticated].
  final AuthUser? user;

  /// Set only when [status] is [AuthStatus.authenticated].
  final UserProfile? profile;

  /// Set only when [status] is [AuthStatus.unauthenticated], and only when
  /// there is something to tell the user.
  final AuthNotice? notice;

  @override
  List<Object?> get props => [status, user, profile, notice];
}
