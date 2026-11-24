import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/user_models.dart';
import '../data/users_repository.dart';

class UsersState extends Equatable {
  const UsersState({
    this.overview,
    this.selectedId,
    this.creating = false,
    this.loadFailure,
    this.loading = false,
    this.saving = false,
  });

  /// Null until the first good read; kept when a later one fails.
  final UsersOverview? overview;

  /// The user in the edit panel; ignored while [creating].
  final String? selectedId;

  /// The panel holds a new user.
  final bool creating;
  final UsersFailureKind? loadFailure;
  final bool loading;

  /// A save or a password reset is on its way.
  final bool saving;

  AdminUser? get selected => creating ? null : overview?.user(selectedId);

  UsersState copyWith({
    UsersOverview? Function()? overview,
    String? Function()? selectedId,
    bool? creating,
    UsersFailureKind? Function()? loadFailure,
    bool? loading,
    bool? saving,
  }) => UsersState(
    overview: overview != null ? overview() : this.overview,
    selectedId: selectedId != null ? selectedId() : this.selectedId,
    creating: creating ?? this.creating,
    loadFailure: loadFailure != null ? loadFailure() : this.loadFailure,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
  );

  @override
  List<Object?> get props => [overview, selectedId, creating, loadFailure, loading, saving];
}

/// The Users page (4.7): every staff member, the one in the edit panel,
/// saving and password resets. Reads on entry, after each save, and on Refresh.
class UsersCubit extends Cubit<UsersState> {
  UsersCubit(this._repository) : super(const UsersState());

  final UsersRepository _repository;

  int _request = 0;

  Future<void> start() => refresh();

  Future<void> refresh() async {
    final request = ++_request;
    emit(state.copyWith(loading: true));
    try {
      final overview = await _repository.overview();
      if (isClosed || request != _request) return;
      final keep = overview.user(state.selectedId) != null;
      emit(
        state.copyWith(
          overview: () => overview,
          selectedId: () =>
              keep ? state.selectedId : (overview.users.isEmpty ? null : overview.users.first.id),
          creating: state.creating || overview.users.isEmpty,
          loadFailure: () => null,
          loading: false,
        ),
      );
    } on UsersFailure catch (e) {
      if (isClosed || request != _request) return;
      emit(state.copyWith(loadFailure: () => e.kind, loading: false));
    }
  }

  void select(String id) => emit(state.copyWith(selectedId: () => id, creating: false));

  void startNew() => emit(state.copyWith(creating: true));

  /// Saves the panel: a new user while [UsersState.creating], else the
  /// selected one. Null when saved, else why not.
  Future<UsersFailureKind?> save(UserDraft draft) async {
    if (state.saving) return null;
    final id = state.creating ? null : state.selectedId;
    emit(state.copyWith(saving: true));
    try {
      final saved = await _repository.save(id: id, draft: draft);
      if (isClosed) return null;
      emit(state.copyWith(saving: false, selectedId: () => saved, creating: false));
      await refresh();
      return null;
    } on UsersFailure catch (e) {
      if (isClosed) return null;
      emit(state.copyWith(saving: false));
      // The page's copy is behind: an open shift or a user it no longer has.
      if (e.kind == UsersFailureKind.notFound || e.kind == UsersFailureKind.staffHasOpenShift) {
        await refresh();
      }
      return e.kind;
    }
  }

  /// Null when [id]'s password is set, else why not.
  Future<UsersFailureKind?> resetPassword(String id, String password) async {
    if (state.saving) return null;
    emit(state.copyWith(saving: true));
    try {
      await _repository.resetPassword(id, password);
      if (!isClosed) emit(state.copyWith(saving: false));
      return null;
    } on UsersFailure catch (e) {
      if (isClosed) return null;
      emit(state.copyWith(saving: false));
      if (e.kind == UsersFailureKind.notFound) await refresh();
      return e.kind;
    }
  }
}
