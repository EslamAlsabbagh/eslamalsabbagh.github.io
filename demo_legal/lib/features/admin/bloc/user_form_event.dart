part of 'user_form_bloc.dart';

/// What the modal's fields hold. [email] and [password] are used only when
/// creating; [fileIds] only for a lawyer.
final class UserDraft extends Equatable {
  const UserDraft({
    this.name = '',
    this.email = '',
    this.password = '',
    this.role = UserRole.lawyer,
    this.fileIds = const {},
  });

  final String name;
  final String email;
  final String password;
  final UserRole role;
  final Set<String> fileIds;

  @override
  List<Object?> get props => [name, email, password, role, fileIds];
}

sealed class UserFormEvent extends Equatable {
  const UserFormEvent();

  @override
  List<Object?> get props => [];
}

/// «حفظ» or Enter.
final class UserFormSubmitted extends UserFormEvent {
  const UserFormSubmitted(this.draft);

  final UserDraft draft;

  @override
  List<Object?> get props => [draft];
}

/// «تعطيل الحساب» (after its confirm dialog) or «إعادة تفعيل الحساب».
final class UserActiveToggled extends UserFormEvent {
  const UserActiveToggled();
}

/// The password modal saved a new password.
final class UserPasswordChanged extends UserFormEvent {
  const UserPasswordChanged();
}
