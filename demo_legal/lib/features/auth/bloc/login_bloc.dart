import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/auth_repository.dart';
import '../data/sign_in_failure.dart';

part 'login_event.dart';
part 'login_state.dart';

/// Submits the login form. Lives with the login page; on success `AuthBloc`
/// picks up the new user from the auth stream and replaces the page.
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required this._authRepository}) : super(const LoginState.idle()) {
    on<LoginSubmitted>(_onSubmitted);
  }

  final AuthRepository _authRepository;

  Future<void> _onSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    if (state.status == LoginStatus.submitting) return;
    emit(const LoginState.submitting());
    try {
      await _authRepository.signInWithPassword(
        email: event.email.trim(),
        password: event.password,
      );
      emit(const LoginState.idle());
    } on SignInException catch (e) {
      emit(LoginState.failure(e.failure));
    }
  }
}
