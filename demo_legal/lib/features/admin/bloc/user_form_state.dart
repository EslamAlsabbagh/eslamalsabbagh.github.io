part of 'user_form_bloc.dart';

/// Which request is in flight; its button shows the spinner.
enum UserFormAction { save, active }

final class UserFormState extends Equatable {
  const UserFormState({
    required this.isActive,
    this.busyWith,
    this.failure,
    this.saved = false,
    this.changed = false,
    this.passwordSet = false,
  });

  /// The account's state now, after any toggle in this modal.
  final bool isActive;

  final UserFormAction? busyWith;

  /// Why the last request failed; cleared by the next one.
  final UserSaveFailure? failure;

  /// «حفظ» succeeded: the modal closes.
  final bool saved;

  /// Something was written while the modal was open, so the list reloads.
  final bool changed;

  /// The password modal set a new password (shown as a line).
  final bool passwordSet;

  bool get busy => busyWith != null;

  UserFormState copyWith({
    bool? isActive,
    UserFormAction? busy,
    bool clearBusy = false,
    UserSaveFailure? failure,
    bool clearFailure = false,
    bool? saved,
    bool? changed,
    bool? passwordSet,
  }) => UserFormState(
    isActive: isActive ?? this.isActive,
    busyWith: clearBusy ? null : (busy ?? busyWith),
    failure: clearFailure ? null : (failure ?? this.failure),
    saved: saved ?? this.saved,
    changed: changed ?? this.changed,
    passwordSet: passwordSet ?? this.passwordSet,
  );

  @override
  List<Object?> get props => [isActive, busyWith, failure, saved, changed, passwordSet];
}
