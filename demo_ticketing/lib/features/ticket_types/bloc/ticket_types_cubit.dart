import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/admin_ticket_type.dart';
import '../data/ticket_types_repository.dart';

class TicketTypesState extends Equatable {
  const TicketTypesState({
    this.types,
    this.selectedId,
    this.creating = false,
    this.loadFailure,
    this.loading = false,
    this.saving = false,
    this.moving,
  });

  /// Null until the first good read; kept when a later one fails.
  final List<AdminTicketType>? types;

  /// The type in the edit panel; ignored while [creating].
  final String? selectedId;

  /// The panel holds a new type.
  final bool creating;

  /// Why the last read failed; null after a good one.
  final TicketTypesFailureKind? loadFailure;
  final bool loading;
  final bool saving;

  /// The type being moved, so the arrows wait for it.
  final String? moving;

  AdminTicketType? get selected {
    if (creating) return null;
    for (final type in types ?? const <AdminTicketType>[]) {
      if (type.id == selectedId) return type;
    }
    return null;
  }

  TicketTypesState copyWith({
    List<AdminTicketType>? Function()? types,
    String? Function()? selectedId,
    bool? creating,
    TicketTypesFailureKind? Function()? loadFailure,
    bool? loading,
    bool? saving,
    String? Function()? moving,
  }) => TicketTypesState(
    types: types != null ? types() : this.types,
    selectedId: selectedId != null ? selectedId() : this.selectedId,
    creating: creating ?? this.creating,
    loadFailure: loadFailure != null ? loadFailure() : this.loadFailure,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    moving: moving != null ? moving() : this.moving,
  );

  @override
  List<Object?> get props => [types, selectedId, creating, loadFailure, loading, saving, moving];
}

/// The Ticket types page (4.5): the list, the type in the edit panel, saving
/// and moving. Reads on entry, after each save or move, and on Refresh.
class TicketTypesCubit extends Cubit<TicketTypesState> {
  TicketTypesCubit(this._repository) : super(const TicketTypesState());

  final TicketTypesRepository _repository;

  // Answers to an older read are dropped.
  int _request = 0;

  Future<void> start() => refresh();

  Future<void> refresh() async {
    final request = ++_request;
    emit(state.copyWith(loading: true));
    try {
      final types = await _repository.list();
      if (isClosed || request != _request) return;
      final ids = {for (final type in types) type.id};
      // The first type when nothing is picked yet, or the picked one is gone.
      final keep = state.selectedId != null && ids.contains(state.selectedId);
      emit(
        state.copyWith(
          types: () => types,
          selectedId: () => keep ? state.selectedId : (types.isEmpty ? null : types.first.id),
          creating: state.creating || types.isEmpty,
          loadFailure: () => null,
          loading: false,
        ),
      );
    } on TicketTypesFailure catch (e) {
      if (isClosed || request != _request) return;
      emit(state.copyWith(loadFailure: () => e.kind, loading: false));
    }
  }

  void select(String id) => emit(state.copyWith(selectedId: () => id, creating: false));

  void startNew() => emit(state.copyWith(creating: true));

  /// Saves the panel: a new type while [TicketTypesState.creating], else the
  /// selected one. Null when saved, else why not.
  Future<TicketTypesFailureKind?> save(TicketTypeDraft draft) async {
    if (state.saving) return null;
    final id = state.creating ? null : state.selectedId;
    emit(state.copyWith(saving: true));
    try {
      final saved = await _repository.save(id: id, draft: draft);
      if (isClosed) return null;
      emit(state.copyWith(saving: false, selectedId: () => saved.id, creating: false));
      await refresh();
      return null;
    } on TicketTypesFailure catch (e) {
      if (isClosed) return null;
      emit(state.copyWith(saving: false));
      // Gone meanwhile: the list shows what's there now.
      if (e.kind == TicketTypesFailureKind.notFound) await refresh();
      return e.kind;
    }
  }

  /// Null when moved (or already first/last), else why not.
  Future<TicketTypesFailureKind?> move(String id, MoveDirection direction) async {
    if (state.moving != null) return null;
    emit(state.copyWith(moving: () => id));
    try {
      await _repository.move(id, direction);
      return null;
    } on TicketTypesFailure catch (e) {
      return e.kind;
    } finally {
      if (!isClosed) {
        emit(state.copyWith(moving: () => null));
        await refresh();
      }
    }
  }
}
