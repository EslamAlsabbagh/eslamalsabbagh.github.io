import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/validation/password_text.dart';
import '../data/user_save_failure.dart';
import '../data/users_repository.dart';

/// The password modal: sets a new password for [userId]. Ends
/// [PasswordDialogStatus.saved], or goes back to editing with a failure.
class PasswordDialogBloc extends Bloc<PasswordSubmitted, PasswordDialogState> {
  PasswordDialogBloc({required this.userId, required this._usersRepository}) : super(const PasswordDialogState()) {
    on<PasswordSubmitted>(_onSubmitted);
  }

  final String userId;
  final UsersRepository _usersRepository;

  Future<void> _onSubmitted(PasswordSubmitted event, Emitter<PasswordDialogState> emit) async {
    if (state.status != PasswordDialogStatus.editing || !PasswordText.isValid(event.password)) return;
    emit(const PasswordDialogState(status: PasswordDialogStatus.saving));
    try {
      await _usersRepository.setPassword(userId, event.password);
      emit(const PasswordDialogState(status: PasswordDialogStatus.saved));
    } on UserSaveException catch (error) {
      emit(PasswordDialogState(failure: error.failure));
    }
  }
}

/// «حفظ» or Enter, with the typed password.
final class PasswordSubmitted extends Equatable {
  const PasswordSubmitted(this.password);

  final String password;

  @override
  List<Object?> get props => [password];
}

enum PasswordDialogStatus { editing, saving, saved }

final class PasswordDialogState extends Equatable {
  const PasswordDialogState({this.status = PasswordDialogStatus.editing, this.failure});

  final PasswordDialogStatus status;

  /// Why the last save failed; cleared by the next submit.
  final UserSaveFailure? failure;

  @override
  List<Object?> get props => [status, failure];
}
