part of 'login_bloc.dart';

enum LoginStatus { idle, submitting, failure }

final class LoginState extends Equatable {
  const LoginState._({required this.status, this.failure});

  const LoginState.idle() : this._(status: LoginStatus.idle);

  const LoginState.submitting() : this._(status: LoginStatus.submitting);

  const LoginState.failure(SignInFailure failure)
      : this._(status: LoginStatus.failure, failure: failure);

  final LoginStatus status;

  /// Set only when [status] is [LoginStatus.failure].
  final SignInFailure? failure;

  @override
  List<Object?> get props => [status, failure];
}
