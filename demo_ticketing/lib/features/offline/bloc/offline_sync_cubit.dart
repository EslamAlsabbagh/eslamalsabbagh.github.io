import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/clock.dart';
import '../../../core/connectivity/server_status_cubit.dart';
import '../../shift/bloc/shift_cubit.dart';
import '../data/offline_models.dart';
import '../data/offline_repository.dart';
import '../data/offline_store.dart';

class OfflineSyncState extends Equatable {
  const OfflineSyncState({
    this.queue = const QueueStatus(),
    this.freeCodes = 0,
    this.poolSize,
    this.uploading = false,
    this.poolFailure,
  });

  /// The open shift's offline orders not on the server yet.
  final QueueStatus queue;

  /// Pool codes this counter can still sell offline.
  final int freeCodes;

  /// `offline_pool_size` from the last top-up; null before one.
  final int? poolSize;

  /// An upload is running.
  final bool uploading;

  /// The last top-up failed (e.g. `counter_no_home_gate`); null once one
  /// succeeds.
  final OfflineFailureKind? poolFailure;

  OfflineSyncState copyWith({
    QueueStatus? queue,
    int? freeCodes,
    int? poolSize,
    bool? uploading,
    Object? poolFailure = _keep,
  }) =>
      OfflineSyncState(
        queue: queue ?? this.queue,
        freeCodes: freeCodes ?? this.freeCodes,
        poolSize: poolSize ?? this.poolSize,
        uploading: uploading ?? this.uploading,
        poolFailure: poolFailure == _keep ? this.poolFailure : poolFailure as OfflineFailureKind?,
      );

  static const _keep = Object();

  @override
  List<Object?> get props => [queue, freeCodes, poolSize, uploading, poolFailure];
}

/// Keeps the counter ready to sell offline and empties its queue (ADR-0015).
///
/// While the server answers and a shift is open at this counter, on every
/// health check: uploads the shift's queued offline orders
/// (`sync_offline_orders`) and logged actions (`sync_offline_actions`) in
/// batches, then tops the code pool up
/// (`reserve_offline_codes`) when it is due, and drops expired codes.
/// Nothing to press: it starts the moment the server is back.
class OfflineSyncCubit extends Cubit<OfflineSyncState> {
  OfflineSyncCubit({
    required this._store,
    required this._repository,
    required this._status,
    required this._shift,
    required this._refreshSession,
    this._clock = const Clock(),
    this._batchOrders = uploadBatchOrders,
    this._batchTickets = uploadBatchTickets,
    this._batchActions = uploadBatchActions,
  }) : super(const OfflineSyncState()) {
    _subscriptions = [
      _status.stream.listen((status) {
        // Back from an outage: the pool may have been released or expired.
        if (status == ServerStatus.online) _topUpDue = true;
      }),
      _status.answers.listen((_) => unawaited(sync())),
      _shift.stream.listen((_) {
        _topUpDue = true;
        refresh();
        unawaited(sync());
      }),
    ];
    refresh();
  }

  final OfflineStore _store;
  final OfflineRepository _repository;
  final ServerStatusCubit _status;
  final ShiftCubit _shift;

  /// Gets a new access token, for an upload after a long outage.
  final Future<void> Function() _refreshSession;
  final Clock _clock;
  final int _batchOrders;
  final int _batchTickets;
  final int _batchActions;

  /// Most orders in one `sync_offline_orders` call (2.13). The whole queue in
  /// one call fit only ~500 orders under the `authenticated` role's 8 s
  /// statement limit, and `offline_pool_size` goes up to 5000: a longer queue
  /// failed every time and the shift could never close. A full batch is timed
  /// in `supabase/perf/hot_paths.sql`. A size, not a setting: like
  /// [serverCallTimeout], it is about the transport, not a business limit.
  static const uploadBatchOrders = 100;

  /// A batch also closes once it holds this many tickets: the upload's cost
  /// is mostly per ticket. An order is never split (the server takes or
  /// refuses it whole), so a bigger one goes alone.
  static const uploadBatchTickets = 200;

  /// Most actions in one `sync_offline_actions` call.
  static const uploadBatchActions = 100;

  late final List<StreamSubscription<Object?>> _subscriptions;
  bool _running = false;
  bool _topUpDue = true;

  /// After a failed top-up, the next try waits until then, not every tick.
  DateTime? _nextTopUpAt;

  /// The open shift, when it is at this counter: offline selling only
  /// happens there.
  ShiftOpen? get _openHere => switch (_shift.state) {
        final ShiftOpen open when open.atThisCounter => open,
        _ => null,
      };

  /// Reads the queue and the pool again, e.g. after an offline sale.
  void refresh() {
    if (isClosed) return;
    final open = _openHere;
    if (open == null) return emit(state.copyWith(queue: const QueueStatus(), freeCodes: 0));
    emit(state.copyWith(
      queue: _store.queueStatus(open.shift.id),
      freeCodes: _store.freeCodes(open.shift.counterId, _clock.now()),
    ));
  }

  /// Uploads the queue and tops the pool up, if the server answers. Runs on
  /// every health check; "Upload now" on the close screen runs it early.
  Future<void> sync() async {
    final open = _openHere;
    if (_running || isClosed || open == null || _status.state != ServerStatus.online) return;
    _running = true;
    try {
      await _upload(open);
      await _topUp(open);
      _store.dropExpired(_clock.now());
    } on OfflineFailure catch (e) {
      switch (e.kind) {
        case OfflineFailureKind.sessionExpired:
          try {
            await _refreshSession();
          } on Exception {
            // The next health check tries again.
          }
        // Not reported to the health check: its next answer would start
        // another upload at once, and so on. It checks on its own.
        case OfflineFailureKind.noOpenShift || OfflineFailureKind.shiftNotOpen:
          // Closed from elsewhere: reloading it lets the router leave selling.
          unawaited(_shift.load());
        default:
          break;
      }
    } finally {
      _running = false;
      if (!isClosed) emit(state.copyWith(uploading: false));
      refresh();
    }
  }

  Future<void> _upload(ShiftOpen open) async {
    // Not while only refused ones go again: the banner would blink each check.
    if (state.queue.hasPending) emit(state.copyWith(uploading: true));
    // Each batch is marked as it returns: if a later one fails, the next
    // check sends only what's left.
    for (final batch in _orderBatches(_store.pendingUploads(open.shift.id))) {
      final results = await _repository.syncOfflineOrders(open.shift.id, batch);
      _store.markResults(results, now: _clock.now());
      refresh();
    }
    // After the orders: an action needs its order on the server.
    final actions = _store.pendingActionUploads(open.shift.id);
    for (var start = 0; start < actions.length; start += _batchActions) {
      final batch = actions.sublist(start, min(start + _batchActions, actions.length));
      final results = await _repository.syncOfflineActions(open.shift.id, batch);
      _store.markActionResults(results, now: _clock.now());
      refresh();
    }
  }

  /// [orders] in sale order, cut at [_batchOrders] orders or once a batch
  /// holds [_batchTickets] tickets.
  List<List<Map<String, Object?>>> _orderBatches(List<Map<String, Object?>> orders) {
    final batches = <List<Map<String, Object?>>>[];
    var batch = <Map<String, Object?>>[];
    var tickets = 0;
    for (final order in orders) {
      final count = (order['tickets']! as List).length;
      if (batch.isNotEmpty &&
          (batch.length == _batchOrders || tickets + count > _batchTickets)) {
        batches.add(batch);
        batch = [];
        tickets = 0;
      }
      batch.add(order);
      tickets += count;
    }
    if (batch.isNotEmpty) batches.add(batch);
    return batches;
  }

  Future<void> _topUp(ShiftOpen open) async {
    final now = _clock.now();
    final poolSize = state.poolSize;
    final low = poolSize != null && poolSize > 0 && state.freeCodes < poolSize / 2;
    if (!_topUpDue && !low) return;
    if (_nextTopUpAt case final next? when now.isBefore(next)) return;
    try {
      final pool = await _repository.reserveOfflineCodes();
      _store.mergePool(pool);
      _topUpDue = false;
      _nextTopUpAt = null;
      if (!isClosed) emit(state.copyWith(poolSize: pool.poolSize, poolFailure: null));
    } on OfflineFailure catch (e) {
      if (e.kind == OfflineFailureKind.serverUnreachable ||
          e.kind == OfflineFailureKind.sessionExpired) {
        rethrow;
      }
      // E.g. no home gate: an admin has to fix it; try again in a minute.
      _nextTopUpAt = now.add(const Duration(minutes: 1));
      if (!isClosed) emit(state.copyWith(poolFailure: e.kind));
    }
  }

  @override
  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    return super.close();
  }
}
