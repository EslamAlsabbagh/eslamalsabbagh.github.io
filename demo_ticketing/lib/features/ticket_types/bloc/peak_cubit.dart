import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/peak_state.dart';
import '../data/ticket_types_repository.dart';

class PeakCardState extends Equatable {
  const PeakCardState({this.peak, this.loadFailure, this.busy = false});

  /// Null until the first good read; kept when a later one fails.
  final PeakState? peak;
  final TicketTypesFailureKind? loadFailure;

  /// A switch or a save is in flight.
  final bool busy;

  PeakCardState copyWith({
    PeakState? peak,
    TicketTypesFailureKind? Function()? loadFailure,
    bool? busy,
  }) => PeakCardState(
    peak: peak ?? this.peak,
    loadFailure: loadFailure != null ? loadFailure() : this.loadFailure,
    busy: busy ?? this.busy,
  );

  @override
  List<Object?> get props => [peak, loadFailure, busy];
}

/// The peak card (ADR-0033): peak now and why, today's switch, and (on the
/// Ticket types page) the schedule.
class PeakCubit extends Cubit<PeakCardState> {
  PeakCubit(this._repository) : super(const PeakCardState());

  final TicketTypesRepository _repository;

  Future<void> start() => refresh();

  Future<void> refresh() async {
    try {
      final peak = await _repository.peakState();
      if (isClosed) return;
      emit(state.copyWith(peak: peak, loadFailure: () => null));
    } on TicketTypesFailure catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loadFailure: () => e.kind));
    }
  }

  /// Null when switched, else why not.
  Future<TicketTypesFailureKind?> setMode(PeakMode mode) =>
      _run(() => _repository.setPeakOverride(mode));

  /// Null when saved, else why not.
  Future<TicketTypesFailureKind?> saveTimes({
    required Set<int> weekdays,
    int? fromSeconds,
    int? toSeconds,
  }) => _run(
    () => _repository.savePeakTimes(
      weekdays: weekdays,
      fromSeconds: fromSeconds,
      toSeconds: toSeconds,
    ),
  );

  Future<TicketTypesFailureKind?> _run(Future<PeakState> Function() call) async {
    if (state.busy) return null;
    emit(state.copyWith(busy: true));
    try {
      final peak = await call();
      if (!isClosed) emit(state.copyWith(peak: peak, busy: false, loadFailure: () => null));
      return null;
    } on TicketTypesFailure catch (e) {
      if (!isClosed) emit(state.copyWith(busy: false));
      return e.kind;
    }
  }
}
