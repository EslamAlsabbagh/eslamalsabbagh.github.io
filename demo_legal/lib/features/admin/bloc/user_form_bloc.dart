import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/user_role.dart';
import '../../../core/validation/email.dart';
import '../../../core/validation/name_text.dart';
import '../../../core/validation/password_text.dart';
import '../data/managed_user.dart';
import '../data/user_save_failure.dart';
import '../data/users_repository.dart';

part 'user_form_event.dart';
part 'user_form_state.dart';

/// The user modal: creates an account, or edits one's name, role and files,
/// and (edit only) deactivates or reactivates it.
///
/// The typed values stay in the modal's fields; the bloc gets them as a
/// [UserDraft] on submit. Saving closes the modal; toggling the account keeps
/// it open with the new state, so other edits can still be saved.
class UserFormBloc extends Bloc<UserFormEvent, UserFormState> {
  UserFormBloc({required this.user, required this.viewerId, required this._usersRepository})
    : super(UserFormState(isActive: user?.isActive ?? true)) {
    on<UserFormSubmitted>(_onSubmitted);
    on<UserActiveToggled>(_onActiveToggled);
    on<UserPasswordChanged>(_onPasswordChanged);
  }

  /// The account being edited; null when creating one.
  final ManagedUser? user;

  /// The signed-in admin, who can't change their own role or deactivate
  /// themselves (`profiles_guard`).
  final String viewerId;

  final UsersRepository _usersRepository;

  bool get isNew => user == null;
  bool get isSelf => user?.id == viewerId;

  /// The draft as the modal opens.
  UserDraft get initialDraft {
    final user = this.user;
    return user == null ? const UserDraft() : UserDraft(name: user.displayName, role: user.role, fileIds: user.fileIds);
  }

  /// Whether [draft] may be saved: every field valid and, on edit, something
  /// differs from the saved account.
  bool canSave(UserDraft draft) {
    if (!NameText.isValid(draft.name)) return false;
    if (isNew) return looksLikeEmail(draft.email) && PasswordText.isValid(draft.password);
    return isDirty(draft);
  }

  /// Whether [draft] differs from the saved account. Files count only for a
  /// lawyer, the only role whose files are saved.
  bool isDirty(UserDraft draft) {
    final user = this.user;
    if (user == null) {
      return draft.name.trim().isNotEmpty ||
          draft.email.trim().isNotEmpty ||
          draft.password.isNotEmpty ||
          draft.role != UserRole.lawyer ||
          draft.fileIds.isNotEmpty;
    }
    final role = _roleToSave(draft);
    return draft.name.trim() != user.displayName ||
        role != user.role ||
        (role.needsFiles && !_sameSet(draft.fileIds, user.fileIds));
  }

  /// The database refuses an admin's own role change, so their own account
  /// keeps its role whatever the draft says.
  UserRole _roleToSave(UserDraft draft) => isSelf ? user!.role : draft.role;

  Future<void> _onSubmitted(UserFormSubmitted event, Emitter<UserFormState> emit) async {
    if (state.busy || !canSave(event.draft)) return;
    final draft = event.draft;
    final user = this.user;
    final role = _roleToSave(draft);
    // Managers and admins see every file, so their memberships are left alone.
    final fileIds = role.needsFiles ? draft.fileIds : null;
    emit(state.copyWith(busy: UserFormAction.save, clearFailure: true));
    try {
      if (user == null) {
        await _usersRepository.createUser(
          email: draft.email.trim(),
          password: draft.password,
          displayName: draft.name.trim(),
          role: role,
          fileIds: fileIds,
        );
      } else {
        await _usersRepository.saveUser(
          user.id,
          displayName: draft.name.trim(),
          role: role,
          fileIds: fileIds,
        );
      }
      emit(state.copyWith(clearBusy: true, saved: true, changed: true));
    } on UserSaveException catch (error) {
      emit(state.copyWith(clearBusy: true, failure: error.failure));
    }
  }

  Future<void> _onActiveToggled(UserActiveToggled event, Emitter<UserFormState> emit) async {
    final user = this.user;
    if (user == null || isSelf || state.busy) return;
    final active = !state.isActive;
    emit(state.copyWith(busy: UserFormAction.active, clearFailure: true));
    try {
      await _usersRepository.setActive(user.id, active: active);
      emit(state.copyWith(clearBusy: true, isActive: active, changed: true));
    } on UserSaveException catch (error) {
      emit(state.copyWith(clearBusy: true, failure: error.failure));
    }
  }

  void _onPasswordChanged(UserPasswordChanged event, Emitter<UserFormState> emit) =>
      emit(state.copyWith(passwordSet: true, clearFailure: true));

  static bool _sameSet(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);
}
