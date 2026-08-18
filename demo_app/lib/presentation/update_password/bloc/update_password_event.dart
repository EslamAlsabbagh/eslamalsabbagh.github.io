abstract class UpdatePasswordEvent {
  const UpdatePasswordEvent();
}

class UpdatePasswordRequested extends UpdatePasswordEvent {
  final String code;
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  const UpdatePasswordRequested({
    required this.code,
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
  });
}
