sealed class LoginEvent {
  const LoginEvent();
}

class LoginRequested extends LoginEvent {
  final String code;
  final String password;

  const LoginRequested({required this.code, required this.password});
}
