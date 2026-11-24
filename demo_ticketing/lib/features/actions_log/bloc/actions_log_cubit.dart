import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/action_log_models.dart';
import '../data/actions_log_repository.dart';

class ActionsLogState extends Equatable {
  const ActionsLogState({
    this.period = ActionsPeriod.today,
    this.type = ActionsTypeFilter.all,
    this.actorId,
    this.counterId,
    this.shiftId,
    this.log,
    this.failure,
    this.reviewing,
  });

  final ActionsPeriod period;

  /// Filters the rows in the app; the tiles count the whole period.
  final ActionsTypeFilter type;
  final String? actorId;
  final String? counterId;

  /// Set with [ActionsPeriod.shift].
  final String? shiftId;

  /// The last answer for these filters; kept when a later refresh fails.
  final ActionsLog? log;

  /// Why the last load failed; null after a good one.
  final ActionsLogFailureKind? failure;

  /// The row whose review is in flight.
  final String? reviewing;

  List<ActionLogRow> get rows => [
    for (final row in log?.rows ?? const <ActionLogRow>[])
      if (type.matches(row.action)) row,
  ];

  ActionsLogState copyWith({
    ActionsPeriod? period,
    ActionsTypeFilter? type,
    String? Function()? actorId,
    String? Function()? counterId,
    String? Function()? shiftId,
    ActionsLog? Function()? log,
    ActionsLogFailureKind? Function()? failure,
    String? Function()? reviewing,
  }) => ActionsLogState(
    period: period ?? this.period,
    type: type ?? this.type,
    actorId: actorId != null ? actorId() : this.actorId,
    counterId: counterId != null ? counterId() : this.counterId,
    shiftId: shiftId != null ? shiftId() : this.shiftId,
    log: log != null ? log() : this.log,
    failure: failure != null ? failure() : this.failure,
    reviewing: reviewing != null ? reviewing() : this.reviewing,
  );

  @override
  List<Object?> get props => [period, type, actorId, counterId, shiftId, log, failure, reviewing];
}

/// The Actions log page (4.3). No Realtime and no poll, like the Shifts page:
/// it reads on entry, on a filter change, after a review and on Refresh.
/// [onPendingCount] hears every count of open reviews, for the menu badge.
class ActionsLogCubit extends Cubit<ActionsLogState> {
  ActionsLogCubit(this._repository, {String? shiftId, this.onPendingCount})
    : super(
        shiftId == null
            ? const ActionsLogState()
            : ActionsLogState(period: ActionsPeriod.shift, shiftId: shiftId),
      );

  final ActionsLogRepository _repository;
  final void Function(int count)? onPendingCount;

  // Answers to an older request are dropped.
  int _request = 0;

  Future<void> start() => refresh();

  Future<void> setPeriod(ActionsPeriod period) async {
    if (period == ActionsPeriod.shift || period == state.period) return;
    emit(state.copyWith(period: period, shiftId: () => null, log: () => null, failure: () => null));
    await refresh();
  }

  /// Leaves a shift's log for today's.
  Future<void> clearShift() async {
    if (state.period != ActionsPeriod.shift) return;
    emit(
      state.copyWith(
        period: ActionsPeriod.today,
        shiftId: () => null,
        log: () => null,
        failure: () => null,
      ),
    );
    await refresh();
  }

  void setType(ActionsTypeFilter type) => emit(state.copyWith(type: type));

  Future<void> setActor(String? actorId) async {
    if (actorId == state.actorId) return;
    emit(state.copyWith(actorId: () => actorId));
    await refresh();
  }

  Future<void> setCounter(String? counterId) async {
    if (counterId == state.counterId) return;
    emit(state.copyWith(counterId: () => counterId));
    await refresh();
  }

  Future<void> refresh() async {
    final request = ++_request;
    try {
      final log = await _load(ActionsLogRepository.pageLimit);
      if (isClosed || request != _request) return;
      onPendingCount?.call(log.reviewCount);
      emit(state.copyWith(log: () => log, failure: () => null));
    } on ActionsLogFailure catch (e) {
      if (isClosed || request != _request) return;
      emit(state.copyWith(failure: () => e.kind));
    }
  }

  /// Every row for the current filters, uncapped, for the CSV. Throws
  /// [ActionsLogFailure].
  Future<List<ActionLogRow>> allRows() async {
    final log = await _load(null);
    return [for (final row in log.rows) if (state.type.matches(row.action)) row];
  }

  Future<ActionsLog> _load(int? limit) => _repository.load(
    period: state.period,
    actorId: state.actorId,
    counterId: state.counterId,
    shiftId: state.shiftId,
    limit: limit,
  );

  /// Marks a flagged row reviewed, then reads again: also after a refusal
  /// such as "already reviewed", since the screen is out of date then. Null
  /// when it went through.
  Future<ActionsLogFailureKind?> markReviewed(String actionId) async {
    if (state.reviewing != null) return null;
    emit(state.copyWith(reviewing: () => actionId));
    ActionsLogFailureKind? failure;
    try {
      await _repository.markReviewed(actionId);
    } on ActionsLogFailure catch (e) {
      failure = e.kind;
    }
    if (isClosed) return failure;
    emit(state.copyWith(reviewing: () => null));
    if (failure != ActionsLogFailureKind.serverUnreachable) await refresh();
    return failure;
  }
}

/// The menu badge: flagged actions not reviewed yet. A failed read leaves the
/// last count.
class PendingReviewsCubit extends Cubit<int?> {
  PendingReviewsCubit(this._repository) : super(null);

  final ActionsLogRepository _repository;

  Future<void> load() async {
    try {
      final count = await _repository.pendingCount();
      if (!isClosed) emit(count);
    } on ActionsLogFailure {
      // Keep the last count.
    }
  }

  void set(int count) => emit(count);
}
