part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Start following the auth state. Added once, when the bloc is created.
final class AuthSubscriptionRequested extends AuthEvent {
  const AuthSubscriptionRequested();
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// The session's user, at startup or from the auth stream. Internal.
final class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);

  final AuthUser? user;

  @override
  List<Object?> get props => [user];
}
