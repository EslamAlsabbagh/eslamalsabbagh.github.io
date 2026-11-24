import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/clock.dart';
import '../data/dashboard_repository.dart';
import '../data/dashboard_snapshot.dart';

class DashboardState extends Equatable {
  const DashboardState({
    this.snapshot,
    this.live = false,
    this.failure,
    this.updatedAt,
    this.serverNow,
  });

  /// The last answer; kept when a later refresh fails.
  final DashboardSnapshot? snapshot;

  /// The Realtime channel is joined, so new scans show within seconds.
  /// Otherwise the screen still refreshes every [DashboardCubit.pollEvery].
  final bool live;

  /// Why the last refresh failed; null after a good one.
  final DashboardFailureKind? failure;

  /// This PC's time of the last good refresh.
  final DateTime? updatedAt;

  /// The server's time now, estimated from the last answer, for ages such as
  /// "last scan 12 s ago".
  final DateTime? serverNow;

  @override
  List<Object?> get props => [snapshot, live, failure, updatedAt, serverNow];
}

/// Keeps the dashboard current (ADR-0030): a scan heard on the Realtime
/// channel re-reads `dashboard_today`, at most once every [debounce]; a timer
/// re-reads it every [pollEvery] anyway, for gate heartbeats and a dropped
/// channel. These are screen refresh rates, not business limits.
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(
    this._repository, {
    this._clock = const Clock(),
    this._timer = Timer.new,
    this._periodic = Timer.periodic,
  }) : super(const DashboardState());

  static const debounce = Duration(seconds: 2);
  static const pollEvery = Duration(seconds: 15);
  static const tickEvery = Duration(seconds: 1);

  final DashboardRepository _repository;
  final Clock _clock;
  final Timer Function(Duration, void Function()) _timer;
  final Timer Function(Duration, void Function(Timer)) _periodic;

  StreamSubscription<LiveSignal>? _signals;
  Timer? _soon;
  Timer? _poll;
  Timer? _tick;
  bool _inFlight = false;
  bool _again = false;
  DateTime? _lastStart;
  DateTime? _fetchedAt;

  /// Loads now and starts listening for scans.
  void start() {
    _signals ??= _repository.watchScans().listen(_onSignal);
    unawaited(refresh());
  }

  void _onSignal(LiveSignal signal) {
    if (isClosed) return;
    switch (signal) {
      case LiveSignal.subscribed:
        _emit(live: true);
        // Scans may have been missed while the channel was down.
        _schedule();
      case LiveSignal.disconnected:
        _emit(live: false);
      case LiveSignal.changed:
        _schedule();
    }
  }

  /// A refresh as soon as [debounce] allows; many scans in a burst make one.
  void _schedule() {
    if (_inFlight) {
      _again = true;
      return;
    }
    if (_soon?.isActive ?? false) return;
    final since = _lastStart == null ? debounce : _clock.now().difference(_lastStart!);
    if (since >= debounce) {
      unawaited(refresh());
    } else {
      _soon = _timer(debounce - since, () => unawaited(refresh()));
    }
  }

  /// Re-reads `dashboard_today` now (also the screen's Retry).
  Future<void> refresh() async {
    if (isClosed) return;
    if (_inFlight) {
      _again = true;
      return;
    }
    _soon?.cancel();
    _poll?.cancel();
    _inFlight = true;
    _again = false;
    _lastStart = _clock.now();
    try {
      final snapshot = await _repository.load();
      if (isClosed) return;
      _fetchedAt = _clock.now();
      emit(
        DashboardState(
          snapshot: snapshot,
          live: state.live,
          updatedAt: _fetchedAt,
          serverNow: snapshot.now,
        ),
      );
    } on DashboardFailure catch (e) {
      if (isClosed) return;
      _emit(failure: e.kind);
    } finally {
      _inFlight = false;
    }
    _syncTick();
    _poll = _timer(pollEvery, () => unawaited(refresh()));
    if (_again) {
      _again = false;
      _schedule();
    }
  }

  /// Ticks only while something on screen shows an age, so a quiet screen
  /// does no work.
  void _syncTick() {
    final needed = state.snapshot?.hasAges ?? false;
    if (!needed) {
      _tick?.cancel();
      _tick = null;
    } else {
      _tick ??= _periodic(tickEvery, (_) {
        final snapshot = state.snapshot;
        final fetchedAt = _fetchedAt;
        if (isClosed || snapshot == null || fetchedAt == null) return;
        _emit(serverNow: snapshot.now.add(_clock.now().difference(fetchedAt)));
      });
    }
  }

  /// The current state with the given fields replaced. A good refresh is the
  /// only thing that clears [DashboardState.failure].
  void _emit({bool? live, DashboardFailureKind? failure, DateTime? serverNow}) => emit(
    DashboardState(
      snapshot: state.snapshot,
      live: live ?? state.live,
      failure: failure ?? state.failure,
      updatedAt: state.updatedAt,
      serverNow: serverNow ?? state.serverNow,
    ),
  );

  @override
  Future<void> close() async {
    _soon?.cancel();
    _poll?.cancel();
    _tick?.cancel();
    await _signals?.cancel();
    return super.close();
  }
}
