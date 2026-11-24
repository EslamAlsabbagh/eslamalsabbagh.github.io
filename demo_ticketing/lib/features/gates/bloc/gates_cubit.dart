import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/gate_models.dart';
import '../data/gates_repository.dart';

/// Where the panel's test open is. [sending] until `test_open_gate` answers,
/// then the server's result until it is no longer waiting.
enum TestOpenPhase { sending, waiting, opened, failed, noAnswer }

class TestOpenProgress extends Equatable {
  const TestOpenProgress({
    required this.gateId,
    required this.phase,
    this.openSeconds,
    this.detail,
  });

  final String gateId;
  final TestOpenPhase phase;

  /// Known once the server took the request.
  final int? openSeconds;

  /// The gate service's own words, for a failure.
  final String? detail;

  bool get busy => phase == TestOpenPhase.sending || phase == TestOpenPhase.waiting;

  @override
  List<Object?> get props => [gateId, phase, openSeconds, detail];
}

class GatesState extends Equatable {
  const GatesState({
    this.overview,
    this.selectedId,
    this.creating = false,
    this.loadFailure,
    this.loading = false,
    this.saving = false,
    this.testOpen,
  });

  /// Null until the first good read; kept when a later one fails.
  final GatesOverview? overview;

  /// The gate in the edit panel; ignored while [creating].
  final String? selectedId;

  /// The panel holds a new gate.
  final bool creating;
  final GatesFailureKind? loadFailure;
  final bool loading;
  final bool saving;

  /// The last test open, for whichever gate it was.
  final TestOpenProgress? testOpen;

  AdminGate? get selected => creating ? null : overview?.gate(selectedId);

  GatesState copyWith({
    GatesOverview? Function()? overview,
    String? Function()? selectedId,
    bool? creating,
    GatesFailureKind? Function()? loadFailure,
    bool? loading,
    bool? saving,
    TestOpenProgress? Function()? testOpen,
  }) => GatesState(
    overview: overview != null ? overview() : this.overview,
    selectedId: selectedId != null ? selectedId() : this.selectedId,
    creating: creating ?? this.creating,
    loadFailure: loadFailure != null ? loadFailure() : this.loadFailure,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    testOpen: testOpen != null ? testOpen() : this.testOpen,
  );

  @override
  List<Object?> get props => [
    overview,
    selectedId,
    creating,
    loadFailure,
    loading,
    saving,
    testOpen,
  ];
}

/// The Gates page (4.6): controllers, gates, the gate in the edit panel,
/// saving, and a test open followed until the gate service answers. Reads on
/// entry, after each save, and on Refresh.
class GatesCubit extends Cubit<GatesState> {
  GatesCubit(this._repository, {this.pollInterval = const Duration(seconds: 1)})
    : super(const GatesState());

  final GatesRepository _repository;

  /// How often a test open's status is read.
  final Duration pollInterval;

  int _request = 0;

  Future<void> start() => refresh();

  Future<void> refresh() async {
    final request = ++_request;
    emit(state.copyWith(loading: true));
    try {
      final overview = await _repository.overview();
      if (isClosed || request != _request) return;
      final keep = overview.gate(state.selectedId) != null;
      emit(
        state.copyWith(
          overview: () => overview,
          selectedId: () =>
              keep ? state.selectedId : (overview.gates.isEmpty ? null : overview.gates.first.id),
          creating: state.creating || overview.gates.isEmpty,
          loadFailure: () => null,
          loading: false,
        ),
      );
    } on GatesFailure catch (e) {
      if (isClosed || request != _request) return;
      emit(state.copyWith(loadFailure: () => e.kind, loading: false));
    }
  }

  void select(String id) => emit(state.copyWith(selectedId: () => id, creating: false));

  void startNew() => emit(state.copyWith(creating: true));

  /// Saves the panel: a new gate while [GatesState.creating], else the
  /// selected one. Null when saved, else why not.
  Future<GatesFailureKind?> saveGate(GateDraft draft) async {
    if (state.saving) return null;
    final id = state.creating ? null : state.selectedId;
    emit(state.copyWith(saving: true));
    try {
      final saved = await _repository.saveGate(id: id, draft: draft);
      if (isClosed) return null;
      emit(state.copyWith(saving: false, selectedId: () => saved, creating: false));
      await refresh();
      return null;
    } on GatesFailure catch (e) {
      if (isClosed) return null;
      emit(state.copyWith(saving: false));
      if (e.kind == GatesFailureKind.notFound) await refresh();
      return e.kind;
    }
  }

  /// Adds a controller ([id] null) or changes one. Null when saved, else why not.
  Future<GatesFailureKind?> saveController(String? id, ControllerDraft draft) async {
    try {
      await _repository.saveController(id: id, draft: draft);
      if (!isClosed) await refresh();
      return null;
    } on GatesFailure catch (e) {
      if (!isClosed && e.kind == GatesFailureKind.notFound) await refresh();
      return e.kind;
    }
  }

  /// Asks [gateId]'s service to open it, then reads the result every
  /// [pollInterval] until the server stops saying it is waiting. Null when
  /// asked, else why not (the request itself was refused).
  Future<GatesFailureKind?> testOpen(String gateId) async {
    if (state.testOpen?.busy ?? false) return null;
    emit(
      state.copyWith(
        testOpen: () => TestOpenProgress(gateId: gateId, phase: TestOpenPhase.sending),
      ),
    );

    final TestOpenRequest request;
    try {
      request = await _repository.testOpen(gateId);
    } on GatesFailure catch (e) {
      if (!isClosed) emit(state.copyWith(testOpen: () => null));
      return e.kind;
    }
    if (isClosed) return null;
    emit(
      state.copyWith(
        testOpen: () => TestOpenProgress(
          gateId: gateId,
          phase: TestOpenPhase.waiting,
          openSeconds: request.openSeconds,
        ),
      ),
    );

    // The server answers no_answer by itself after twice the timeout; the
    // cap only guards against reads that keep failing.
    final maxPolls = 2 * request.timeoutSeconds + 5;
    for (var i = 0; i < maxPolls; i++) {
      await Future<void>.delayed(pollInterval);
      if (isClosed) return null;
      final TestOpenStatus status;
      try {
        status = await _repository.testOpenStatus(request.commandId);
      } on GatesFailure {
        continue; // a lost read: try again
      }
      if (isClosed) return null;
      if (status.result == TestOpenResult.waiting) continue;
      _finish(gateId, request, switch (status.result) {
        TestOpenResult.opened => TestOpenPhase.opened,
        TestOpenResult.failed => TestOpenPhase.failed,
        _ => TestOpenPhase.noAnswer,
      }, status.detail);
      return null;
    }
    _finish(gateId, request, TestOpenPhase.noAnswer, null);
    return null;
  }

  void _finish(String gateId, TestOpenRequest request, TestOpenPhase phase, String? detail) {
    emit(
      state.copyWith(
        testOpen: () => TestOpenProgress(
          gateId: gateId,
          phase: phase,
          openSeconds: request.openSeconds,
          detail: detail,
        ),
      ),
    );
  }
}
