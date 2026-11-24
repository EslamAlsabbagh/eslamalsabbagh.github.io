import 'dart:convert';

import '../../sell/data/sold_order.dart';
import 'offline_models.dart';

/// The counter's own store: cached copies, the reserved code pool, and the
/// queue of offline sales and actions waiting to upload (ADR-0015, ADR-0025).
///
/// Production keeps it in a SQLite file on the counter PC, so it survives a
/// restart during an outage. The demo runs in a browser, so this is the same
/// API over in-memory tables, with the same rules the SQL enforced: a code is
/// used once, the queue uploads in order, and an action waits for its order.
class OfflineStore {
  OfflineStore.inMemory();

  final _cache = <String, String>{};
  final _pool = <int, _PoolRow>{};
  final _orders = <String, _OrderRow>{};
  final _tickets = <String, List<_TicketRow>>{};
  final _actions = <String, _ActionRow>{};

  void close() {}

  // --- Cache -------------------------------------------------------------

  Object? readCache(String key) {
    final json = _cache[key];
    return json == null ? null : jsonDecode(json);
  }

  void writeCache(String key, Object? json, {required DateTime now}) => _cache[key] = jsonEncode(json);

  void deleteCache(String key) => _cache.remove(key);

  // --- Pool --------------------------------------------------------------

  /// Takes in the server's answer: codes it still holds for this counter are
  /// kept or refreshed; codes it dropped go, unless an unsynced sale used one.
  void mergePool(ReservedPool pool) {
    final live = {for (final code in pool.codes) code.gateCode};
    for (final code in pool.codes) {
      final row = _pool[code.gateCode];
      if (row != null && row.usedBy != null) continue;
      _pool[code.gateCode] = _PoolRow(code.gateCode, pool.counterId, pool.homeGateId, pool.homeGateName, code.expiresAt);
    }
    _pool.removeWhere((gateCode, row) {
      if (live.contains(gateCode)) return false;
      final usedBy = row.usedBy;
      if (usedBy == null) return true;
      final order = _orders[usedBy];
      return order == null || order.status == 'synced' || order.clearedAt != null;
    });
  }

  void dropExpired(DateTime now) => _pool.removeWhere((_, row) => row.usedBy == null && !row.expiresAt.isAfter(now));

  Iterable<_PoolRow> _free(String counterId, DateTime at) =>
      _pool.values.where((row) => row.counterId == counterId && row.usedBy == null && row.expiresAt.isAfter(at));

  int freeCodes(String counterId, DateTime at) => _free(counterId, at).length;

  DateTime? nextExpiry(String counterId, DateTime at) {
    final rows = _free(counterId, at).map((row) => row.expiresAt).toList()..sort();
    return rows.isEmpty ? null : rows.first;
  }

  // --- Selling -----------------------------------------------------------

  int nextLocalNumber(String shiftId) =>
      _orders.values.where((o) => o.shiftId == shiftId).fold(0, (m, o) => o.localNumber > m ? o.localNumber : m) + 1;

  /// Records a sale made offline, paid, with the next free pool codes.
  SoldOrder recordSale({
    required String clientId,
    required String shiftId,
    required String counterId,
    required DateTime soldAt,
    required String paymentMethod,
    required int? amountReceivedPiastres,
    required int tipPiastres,
    required List<OfflineTicketSpec> tickets,
  }) {
    final codes = _free(counterId, soldAt).toList()
      ..sort((a, b) {
        final byExpiry = a.expiresAt.compareTo(b.expiresAt);
        return byExpiry != 0 ? byExpiry : a.gateCode.compareTo(b.gateCode);
      });
    if (codes.length < tickets.length) throw const OfflineSaleException(OfflineSaleError.poolEmpty);
    final number = nextLocalNumber(shiftId);
    final total = tickets.fold(0, (sum, ticket) => sum + ticket.pricePiastres);
    _orders[clientId] = _OrderRow(
      clientId: clientId,
      shiftId: shiftId,
      localNumber: number,
      soldAt: soldAt,
      paymentMethod: paymentMethod,
      amountReceived: amountReceivedPiastres,
      tip: tipPiastres,
      total: total,
    );
    final rows = <_TicketRow>[];
    final sold = <SoldTicket>[];
    for (final (index, spec) in tickets.indexed) {
      final code = codes[index];
      code.usedBy = clientId;
      rows.add(_TicketRow(spec.ticketTypeId, code.gateCode));
      sold.add(SoldTicket(
        id: '$clientId/$index',
        gateCode: '${code.gateCode}',
        ticketTypeId: spec.ticketTypeId,
        nameAr: spec.nameAr,
        nameEn: spec.nameEn,
        pricePiastres: spec.pricePiastres,
        entriesLeft: spec.entriesLeft,
        validFrom: soldAt,
        validUntil: spec.validUntil,
        homeGateName: code.homeGateName,
      ));
    }
    _tickets[clientId] = rows;
    return SoldOrder(id: clientId, number: number, totalPiastres: total, createdAt: soldAt, tickets: sold, offline: true);
  }

  // --- Queue -------------------------------------------------------------

  Iterable<_OrderRow> _unsynced(String shiftId) =>
      _orders.values.where((o) => o.shiftId == shiftId && o.status != 'synced' && o.clearedAt == null);

  List<Map<String, Object?>> pendingUploads(String shiftId) {
    final orders = _unsynced(shiftId).toList()..sort((a, b) => a.localNumber.compareTo(b.localNumber));
    return [
      for (final order in orders)
        {
          'client_id': order.clientId,
          'sold_at': order.soldAt.toUtc().toIso8601String(),
          'payment_method': order.paymentMethod,
          'amount_received_piastres': order.amountReceived,
          'tip_piastres': order.tip,
          'tickets': [
            for (final t in _tickets[order.clientId]!) {'ticket_type_id': t.ticketTypeId, 'gate_code': t.gateCode},
          ],
        },
    ];
  }

  bool orderOnServer(String clientId) => _orders[clientId]?.status == 'synced';

  void recordActions(List<QueuedAction> actions) {
    for (final action in actions) {
      _actions[action.clientId] = _ActionRow(action);
    }
  }

  int queuedReprints(String orderId, int gateCode) => _actions.values
      .where((a) => a.action.orderId == orderId && a.action.gateCode == gateCode && a.action.kind == QueuedActionKind.reprint)
      .length;

  /// Actions whose order is already on the server, oldest first.
  List<Map<String, Object?>> pendingActionUploads(String shiftId) {
    final actions = _actions.values.where((a) {
      final order = _orders[a.action.orderId];
      final orderWaiting = order != null && order.status != 'synced' && order.clearedAt == null;
      return a.action.shiftId == shiftId && a.status != 'synced' && a.clearedAt == null && !orderWaiting;
    }).toList()
      ..sort((a, b) {
        final byTime = a.action.at.compareTo(b.action.at);
        return byTime != 0 ? byTime : a.action.clientId.compareTo(b.action.clientId);
      });
    return [
      for (final a in actions)
        {
          'client_id': a.action.clientId,
          'action': a.action.kind.key,
          'order_id': a.action.orderId,
          'gate_code': a.action.gateCode,
          'at': a.action.at.toUtc().toIso8601String(),
          'reason': a.action.reason,
          'reason_text': a.action.reasonText,
        },
    ];
  }

  void markActionResults(List<SyncResult> results, {required DateTime now}) {
    for (final result in results) {
      final row = _actions[result.clientId];
      if (row == null) continue;
      switch (result.outcome) {
        case SyncOutcome.synced || SyncOutcome.alreadySynced || SyncOutcome.skipped:
          row
            ..status = 'synced'
            ..error = null;
        case SyncOutcome.cleared:
          row.clearedAt = now;
        case SyncOutcome.refused:
          row
            ..status = 'refused'
            ..error = result.error ?? 'unexpected';
      }
    }
  }

  void markResults(List<SyncResult> results, {required DateTime now}) {
    for (final result in results) {
      final row = _orders[result.clientId];
      if (row == null) continue;
      switch (result.outcome) {
        case SyncOutcome.synced || SyncOutcome.alreadySynced || SyncOutcome.skipped:
          row
            ..status = 'synced'
            ..error = null
            ..serverOrderId = result.orderId
            ..serverOrderNumber = result.orderNumber
            ..syncedAt = now;
        case SyncOutcome.cleared:
          row.clearedAt = now;
        case SyncOutcome.refused:
          row
            ..status = 'refused'
            ..error = result.error ?? 'unexpected';
      }
    }
  }

  QueueStatus queueStatus(String shiftId) {
    final unsynced = _unsynced(shiftId).toList()..sort((a, b) => a.localNumber.compareTo(b.localNumber));
    final openActions = _actions.values.where((a) => a.action.shiftId == shiftId && a.clearedAt == null).toList()
      ..sort((a, b) => a.action.at.compareTo(b.action.at));
    return QueueStatus(
      pendingOrders: unsynced.where((o) => o.status == 'pending').length,
      unsyncedOrders: unsynced.length,
      unsyncedTickets: unsynced.fold(0, (sum, o) => sum + _tickets[o.clientId]!.length),
      refused: [
        for (final o in unsynced.where((o) => o.status == 'refused'))
          RefusedOrder(localNumber: o.localNumber, soldAt: o.soldAt, error: o.error!),
      ],
      pendingActions: openActions.where((a) => a.status == 'pending').length,
      refusedActions: [
        for (final a in openActions.where((a) => a.status == 'refused'))
          RefusedAction(kind: a.action.kind, gateCode: a.action.gateCode, at: a.action.at, error: a.error!),
      ],
    );
  }
}

class _PoolRow {
  _PoolRow(this.gateCode, this.counterId, this.homeGateId, this.homeGateName, this.expiresAt);

  final int gateCode;
  final String counterId;
  final String homeGateId;
  final String homeGateName;
  final DateTime expiresAt;
  String? usedBy;
}

class _OrderRow {
  _OrderRow({
    required this.clientId,
    required this.shiftId,
    required this.localNumber,
    required this.soldAt,
    required this.paymentMethod,
    required this.amountReceived,
    required this.tip,
    required this.total,
  });

  final String clientId;
  final String shiftId;
  final int localNumber;
  final DateTime soldAt;
  final String paymentMethod;
  final int? amountReceived;
  final int tip;
  final int total;
  String status = 'pending';
  String? error;
  String? serverOrderId;
  int? serverOrderNumber;
  DateTime? syncedAt;
  DateTime? clearedAt;
}

class _TicketRow {
  _TicketRow(this.ticketTypeId, this.gateCode);

  final String ticketTypeId;
  final int gateCode;
}

class _ActionRow {
  _ActionRow(this.action);

  final QueuedAction action;
  String status = 'pending';
  String? error;
  DateTime? clearedAt;
}
