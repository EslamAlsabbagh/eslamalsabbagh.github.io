import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/shift_models.dart';
import '../data/shifts_repository.dart';

class ShiftsState extends Equatable {
  const ShiftsState({
    this.period = ShiftsPeriod.today,
    this.overview,
    this.failure,
    this.selectedId,
    this.detail,
    this.refusals,
    this.detailFailure,
    this.busy = false,
  });

  final ShiftsPeriod period;

  /// The last list for [period]; kept when a later refresh fails.
  final ShiftsOverview? overview;

  /// Why the last list load failed; null after a good one.
  final ShiftsFailureKind? failure;

  final String? selectedId;

  /// The selected shift read again by id (fresher than its list row).
  final ShiftRow? detail;

  /// The selected shift's refused offline orders and actions; null while
  /// loading.
  final List<OfflineRefusal>? refusals;
  final ShiftsFailureKind? detailFailure;

  /// An approval or a clearing is in flight.
  final bool busy;

  /// The selected shift: its own read, or its list row until that arrives.
  ShiftRow? get selected {
    final id = selectedId;
    if (id == null) return null;
    if (detail?.id == id) return detail;
    for (final row in overview?.shifts ?? const <ShiftRow>[]) {
      if (row.id == id) return row;
    }
    return null;
  }

  ShiftsState copyWith({
    ShiftsPeriod? period,
    ShiftsOverview? Function()? overview,
    ShiftsFailureKind? Function()? failure,
    String? Function()? selectedId,
    ShiftRow? Function()? detail,
    List<OfflineRefusal>? Function()? refusals,
    ShiftsFailureKind? Function()? detailFailure,
    bool? busy,
  }) => ShiftsState(
    period: period ?? this.period,
    overview: overview != null ? overview() : this.overview,
    failure: failure != null ? failure() : this.failure,
    selectedId: selectedId != null ? selectedId() : this.selectedId,
    detail: detail != null ? detail() : this.detail,
    refusals: refusals != null ? refusals() : this.refusals,
    detailFailure: detailFailure != null ? detailFailure() : this.detailFailure,
    busy: busy ?? this.busy,
  );

  @override
  List<Object?> get props => [
    period, overview, failure, selectedId, detail, refusals, detailFailure, busy,
  ];
}

/// The Shifts page (4.2). No Realtime and no poll: it reads on entry, on a
/// period change, after each action and on Refresh. [onPendingCount] hears
/// every count of shifts to approve, for the menu badge.
class ShiftsCubit extends Cubit<ShiftsState> {
  ShiftsCubit(this._repository, {this.onPendingCount}) : super(const ShiftsState());

  final ShiftsRepository _repository;
  final void Function(int count)? onPendingCount;

  // Answers to an older request are dropped.
  int _listRequest = 0;
  int _detailRequest = 0;

  Future<void> start() => refresh();

  Future<void> setPeriod(ShiftsPeriod period) async {
    if (period == state.period) return;
    emit(state.copyWith(period: period, overview: () => null, failure: () => null));
    await refresh();
  }

  /// Reads the list again, then the selected shift.
  Future<void> refresh() async {
    final request = ++_listRequest;
    final period = state.period;
    try {
      final overview = await _repository.overview(period);
      if (isClosed || request != _listRequest) return;
      onPendingCount?.call(overview.pendingCount);
      final ids = {for (final row in overview.shifts) row.id};
      final keep = state.selectedId != null && ids.contains(state.selectedId);
      final selectedId = keep ? state.selectedId : _defaultSelection(overview);
      emit(
        state.copyWith(
          overview: () => overview,
          failure: () => null,
          selectedId: () => selectedId,
          detail: keep ? null : () => null,
          refusals: keep ? null : () => null,
          detailFailure: keep ? null : () => null,
        ),
      );
      if (selectedId != null) await _loadDetail(selectedId);
    } on ShiftsFailure catch (e) {
      if (isClosed || request != _listRequest) return;
      emit(state.copyWith(failure: () => e.kind));
    }
  }

  /// The first shift waiting for approval, else the newest.
  static String? _defaultSelection(ShiftsOverview overview) {
    for (final row in overview.shifts) {
      if (row.needsApproval) return row.id;
    }
    return overview.shifts.isEmpty ? null : overview.shifts.first.id;
  }

  Future<void> select(String shiftId) async {
    if (shiftId == state.selectedId) return;
    emit(
      state.copyWith(
        selectedId: () => shiftId,
        detail: () => null,
        refusals: () => null,
        detailFailure: () => null,
      ),
    );
    await _loadDetail(shiftId);
  }

  Future<void> _loadDetail(String shiftId) async {
    final request = ++_detailRequest;
    try {
      final (detail, refusals) = await (
        _repository.shift(shiftId),
        _repository.refusals(shiftId),
      ).wait;
      if (isClosed || request != _detailRequest || state.selectedId != shiftId) return;
      emit(
        state.copyWith(
          detail: () => detail,
          refusals: () => refusals,
          detailFailure: () => null,
        ),
      );
    } on ParallelWaitError<(ShiftRow?, List<OfflineRefusal>?), (AsyncError?, AsyncError?)> catch (e) {
      if (isClosed || request != _detailRequest || state.selectedId != shiftId) return;
      final error = e.errors.$1?.error ?? e.errors.$2?.error;
      emit(
        state.copyWith(
          detailFailure: () =>
              error is ShiftsFailure ? error.kind : ShiftsFailureKind.unexpected,
        ),
      );
    } on ShiftsFailure catch (e) {
      // Thrown before either call returned a future.
      if (isClosed || request != _detailRequest || state.selectedId != shiftId) return;
      emit(state.copyWith(detailFailure: () => e.kind));
    }
  }

  /// Approves the selected shift. Null when it went through.
  Future<ShiftsFailureKind?> approve(String comment) async {
    final shift = state.selected;
    if (shift == null || state.busy) return null;
    return _act(() => _repository.approve(shift.id, comment));
  }

  /// Clears a refusal of the selected shift. Null when it went through.
  Future<ShiftsFailureKind?> resolveRefusal(String refusalId, String comment) async {
    if (state.selected == null || state.busy) return null;
    return _act(() => _repository.resolveRefusal(refusalId, comment));
  }

  /// Runs an action, then reads everything again: also after a refusal such
  /// as "already approved", since the screen is out of date then.
  Future<ShiftsFailureKind?> _act(Future<void> Function() action) async {
    emit(state.copyWith(busy: true));
    ShiftsFailureKind? failure;
    try {
      await action();
    } on ShiftsFailure catch (e) {
      failure = e.kind;
    }
    if (isClosed) return failure;
    emit(state.copyWith(busy: false));
    if (failure != ShiftsFailureKind.serverUnreachable) await refresh();
    return failure;
  }
}

/// The menu badge: closed shifts not approved yet. A failed read leaves the
/// last count.
class PendingShiftsCubit extends Cubit<int?> {
  PendingShiftsCubit(this._repository) : super(null);

  final ShiftsRepository _repository;

  Future<void> load() async {
    try {
      final count = await _repository.pendingCount();
      if (!isClosed) emit(count);
    } on ShiftsFailure {
      // Keep the last count.
    }
  }

  void set(int count) => emit(count);
}
