import 'package:equatable/equatable.dart';

/// One code of the counter's reserved pool (`offline_code_pool`, ADR-0015).
class PoolCode extends Equatable {
  const PoolCode(this.gateCode, this.expiresAt);

  final int gateCode;

  /// The end of the venue day it was reserved for: closing time.
  final DateTime expiresAt;

  @override
  List<Object?> get props => [gateCode, expiresAt];
}

/// What `reserve_offline_codes` returns: every live code of the counter's
/// pool for its current home gate, not only the new ones.
class ReservedPool extends Equatable {
  const ReservedPool({
    required this.counterId,
    required this.homeGateId,
    required this.homeGateName,
    required this.poolSize,
    required this.codes,
  });

  final String counterId;
  final String homeGateId;
  final String homeGateName;

  /// `offline_pool_size`; 0 turns offline selling off.
  final int poolSize;
  final List<PoolCode> codes;

  factory ReservedPool.fromJson(Map<String, dynamic> json) => ReservedPool(
        counterId: json['counter_id'] as String,
        homeGateId: json['home_gate_id'] as String,
        homeGateName: json['home_gate_name'] as String,
        poolSize: json['pool_size'] as int,
        codes: [
          for (final code in (json['codes'] as List).cast<Map<String, dynamic>>())
            PoolCode(
              code['gate_code'] as int,
              DateTime.parse(code['expires_at'] as String).toLocal(),
            ),
        ],
      );

  @override
  List<Object?> get props => [counterId, homeGateId, homeGateName, poolSize, codes];
}

/// `sync_offline_orders`' or `sync_offline_actions`' answer for one item.
/// [skipped]: an action with nothing to log (`left_unprinted` on a ticket
/// voided or already left). [cleared]: a supervisor cleared its refusal, so it
/// stays off the server (ADR-0026).
enum SyncOutcome { synced, alreadySynced, skipped, cleared, refused }

class SyncResult extends Equatable {
  const SyncResult({
    required this.clientId,
    required this.outcome,
    this.orderId,
    this.orderNumber,
    this.error,
  });

  final String clientId;
  final SyncOutcome outcome;

  /// The server's order, once uploaded.
  final String? orderId;
  final int? orderNumber;

  /// The error key of a refused order (`code_not_in_pool`, …).
  final String? error;

  factory SyncResult.fromJson(Map<String, dynamic> json) => SyncResult(
        clientId: json['client_id'] as String,
        outcome: switch (json['result'] as String) {
          'synced' => SyncOutcome.synced,
          'already_synced' => SyncOutcome.alreadySynced,
          'skipped' => SyncOutcome.skipped,
          'cleared' => SyncOutcome.cleared,
          'refused' => SyncOutcome.refused,
          final result => throw FormatException('Unknown sync result: $result'),
        },
        orderId: json['order_id'] as String?,
        orderNumber: json['order_number'] as int?,
        error: json['error'] as String?,
      );

  @override
  List<Object?> get props => [clientId, outcome, orderId, orderNumber, error];
}

/// An offline order the server refused: it stays in the queue with its
/// error key, and the shift can't close until a supervisor clears it
/// (ADR-0015, ADR-0026).
class RefusedOrder extends Equatable {
  const RefusedOrder({required this.localNumber, required this.soldAt, required this.error});

  final int localNumber;
  final DateTime soldAt;
  final String error;

  @override
  List<Object?> get props => [localNumber, soldAt, error];
}

/// What the counter logs while the server can't do it: a reprint, or a ticket
/// left unprinted (`sync_offline_actions`, ADR-0026). The database value.
enum QueuedActionKind {
  reprint('reprint'),
  leftUnprinted('left_unprinted');

  const QueuedActionKind(this.key);

  final String key;

  static QueuedActionKind fromKey(String key) =>
      values.firstWhere((kind) => kind.key == key);
}

/// One action in the queue. [orderId] is the server's order id, or the client
/// id of an offline order; the server takes either.
class QueuedAction extends Equatable {
  const QueuedAction({
    required this.clientId,
    required this.shiftId,
    required this.kind,
    required this.orderId,
    required this.gateCode,
    required this.at,
    required this.reason,
    this.reasonText,
  });

  final String clientId;
  final String shiftId;
  final QueuedActionKind kind;
  final String orderId;
  final int gateCode;
  final DateTime at;

  /// `action_reason`.
  final String reason;
  final String? reasonText;

  @override
  List<Object?> get props => [clientId, shiftId, kind, orderId, gateCode, at, reason, reasonText];
}

/// A queued action the server refused: as [RefusedOrder].
class RefusedAction extends Equatable {
  const RefusedAction({
    required this.kind,
    required this.gateCode,
    required this.at,
    required this.error,
  });

  final QueuedActionKind kind;
  final int gateCode;
  final DateTime at;
  final String error;

  @override
  List<Object?> get props => [kind, gateCode, at, error];
}

/// The shift's offline orders and logged actions not on the server yet.
class QueueStatus extends Equatable {
  const QueueStatus({
    this.pendingOrders = 0,
    this.refused = const [],
    this.unsyncedOrders = 0,
    this.unsyncedTickets = 0,
    this.pendingActions = 0,
    this.refusedActions = const [],
  });

  /// Waiting for their upload.
  final int pendingOrders;

  /// Refused by the server, oldest first.
  final List<RefusedOrder> refused;

  /// Pending and refused together: what the server's counts don't have yet.
  final int unsyncedOrders;
  final int unsyncedTickets;

  /// Logged actions waiting for their upload.
  final int pendingActions;

  /// Refused by the server, oldest first.
  final List<RefusedAction> refusedActions;

  /// Something waits for an upload rather than for a supervisor.
  bool get hasPending => pendingOrders > 0 || pendingActions > 0;

  bool get hasRefused => refused.isNotEmpty || refusedActions.isNotEmpty;

  bool get isEmpty => unsyncedOrders == 0 && pendingActions == 0 && refusedActions.isEmpty;

  @override
  List<Object?> get props =>
      [pendingOrders, refused, unsyncedOrders, unsyncedTickets, pendingActions, refusedActions];
}

/// One ticket of an offline sale, before its code is taken from the pool.
class OfflineTicketSpec extends Equatable {
  const OfflineTicketSpec({
    required this.ticketTypeId,
    required this.nameAr,
    required this.nameEn,
    required this.pricePiastres,
    required this.entriesLeft,
    required this.validUntil,
  });

  final String ticketTypeId;
  final String nameAr;
  final String nameEn;

  /// The price the counter showed; the upload uses the server's (ADR-0015).
  final int pricePiastres;
  final int entriesLeft;
  final DateTime validUntil;

  @override
  List<Object?> get props => [ticketTypeId, nameAr, nameEn, pricePiastres, entriesLeft, validUntil];
}

/// Why an offline sale can't be made.
enum OfflineSaleError {
  /// `offline_pool_size` is 0, or the counter has no pool yet.
  disabled,

  /// Fewer free pool codes than tickets.
  poolEmpty,
}

class OfflineSaleException implements Exception {
  const OfflineSaleException(this.error);

  final OfflineSaleError error;

  @override
  String toString() => 'OfflineSaleException(${error.name})';
}
