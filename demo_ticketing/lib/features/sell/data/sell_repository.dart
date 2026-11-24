import 'dart:async';

import '../../../demo/backend.dart';

import '../../../core/server_call.dart';
import 'sell_draft.dart';
import 'sold_order.dart';
import 'ticket_type.dart';

/// Why a sell flow call failed. Each kind has one message on screen.
enum SellFailureKind {
  noOpenShift,
  counterNoHomeGate,
  ticketTypeUnavailable,

  /// The type isn't on sale at this time (peak times, ADR-0033).
  ticketTypeNotNow,
  afterClosingTime,
  gateCodeSpaceExhausted,
  orderNotFound,
  orderAlreadyPaid,
  orderCancelled,
  tipNotAllowed,
  invalidAmountReceived,
  serverUnreachable,
  unexpected,

  /// Offline selling (ADR-0015): `offline_pool_size` is 0.
  offlineDisabled,

  /// Offline: fewer pool codes left than tickets in the order.
  offlinePoolEmpty,

  /// Offline: the pool's expiry isn't closing time on this PC's clock, so
  /// its time zone isn't the venue's and same-day tickets can't be timed.
  offlineZoneMismatch,
}

class SellFailure implements Exception {
  const SellFailure(this.kind);

  final SellFailureKind kind;

  @override
  String toString() => 'SellFailure(${kind.name})';
}

/// The sell flow's reads (ticket types, settings, the shift's counts) and its
/// calls: `sell_tickets`, `confirm_payment`, `cancel_order` (ADR-0007), and
/// `leave_unprinted_tickets` (ADR-0024).
///
/// Every method throws [SellFailure] rather than Supabase or network errors.
class SellRepository {
  SellRepository(this._client, {this._timeout = serverCallTimeout});

  final DemoBackend _client;

  /// How long a call waits for an answer before it counts as
  /// [SellFailureKind.serverUnreachable] ([serverCallTimeout]). A dead server
  /// can leave a request waiting with no error at all, which kept the payment
  /// screen spinning (ADR-0039).
  final Duration _timeout;

  /// Active ticket types, in the admin's order.
  Future<List<TicketType>> ticketTypes() => _guard(() async {
        final rows = await _client
            .from('ticket_types')
            .select('id, name_ar, name_en, price_piastres, entries_allowed, validity_kind, '
                'validity_hours, sale_period')
            .eq('active', true)
            // order() sorts descending unless told otherwise.
            .order('sort_order', ascending: true)
            .order('name_en', ascending: true);
        return [for (final row in rows) TicketType.fromRow(row)];
      });

  /// `my_shift_counts`: the caller's open shift, counts only.
  Future<ShiftCounts> myShiftCounts() => _guard(() async {
        final result = await _client.rpc<Map<String, dynamic>>('my_shift_counts');
        return ShiftCounts.fromJson(result);
      });

  /// The settings the sell flow needs (see [SellSettings]).
  Future<SellSettings> sellSettings() => _guard(() async {
        final row = await _client.from('settings').select(SellSettings.columns).single();
        return SellSettings.fromRow(row);
      });

  /// `sell_tickets`: the order awaiting payment, with its pending tickets.
  Future<SoldOrder> sellTickets(SellDraft draft) => _guard(() async {
        final result = await _client
            .rpc<Map<String, dynamic>>('sell_tickets', params: {'p_items': draft.items});
        return SoldOrder.fromJson(result);
      });

  /// `confirm_payment`. Card and wallet pass no amount received and no tip.
  Future<PaymentResult> confirmPayment(
    String orderId,
    PaymentMethod method, {
    int? amountReceivedPiastres,
    int tipPiastres = 0,
  }) =>
      _guard(() async {
        final result = await _client.rpc<Map<String, dynamic>>('confirm_payment', params: {
          'p_order_id': orderId,
          'p_payment_method': method.name,
          'p_amount_received_piastres': amountReceivedPiastres,
          'p_tip_piastres': tipPiastres,
        });
        return PaymentResult.fromJson(result);
      });

  /// `cancel_order`: the order is cancelled and its printed tickets voided.
  Future<void> cancelOrder(String orderId, CancelReason reason, {String? reasonText}) =>
      _guard(() async {
        await _client.rpc<Map<String, dynamic>>('cancel_order', params: {
          'p_order_id': orderId,
          'p_reason': reason.key,
          'p_reason_text': reasonText,
        });
      });

  /// `leave_unprinted_tickets`: the cashier leaves the paid order [orderId]
  /// with [ticketIds] never printed. Logged and flagged for a supervisor
  /// (ADR-0024); a repeat writes nothing.
  Future<void> leaveUnprinted(
    String orderId,
    List<String> ticketIds,
    LeaveReason reason, {
    String? reasonText,
  }) =>
      _guard(() async {
        await _client.rpc<Map<String, dynamic>>('leave_unprinted_tickets', params: {
          'p_order_id': orderId,
          'p_ticket_ids': ticketIds,
          'p_reason': reason.key,
          'p_reason_text': reasonText,
        });
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on Exception catch (e) {
      throw SellFailure(failureKindFor(e));
    }
  }

  /// As `ShiftRepository.failureKindFor`: business errors are P0001 with a
  /// snake_case key, any other server or parsing error is unexpected, and
  /// everything else means the server can't be reached.
  static SellFailureKind failureKindFor(Exception error) => switch (error) {
        PostgrestException(code: 'P0001', :final message) => switch (message) {
            'no_open_shift' => SellFailureKind.noOpenShift,
            'counter_no_home_gate' => SellFailureKind.counterNoHomeGate,
            'ticket_type_unavailable' => SellFailureKind.ticketTypeUnavailable,
            'ticket_type_not_now' => SellFailureKind.ticketTypeNotNow,
            'after_closing_time' => SellFailureKind.afterClosingTime,
            'gate_code_space_exhausted' => SellFailureKind.gateCodeSpaceExhausted,
            'order_not_found' => SellFailureKind.orderNotFound,
            'order_already_paid' => SellFailureKind.orderAlreadyPaid,
            'order_cancelled' => SellFailureKind.orderCancelled,
            // The screen offers a tip only with cash and tips on; an admin
            // may have switched tips off meanwhile.
            'tip_requires_cash' || 'tips_disabled' || 'invalid_tip' => SellFailureKind.tipNotAllowed,
            'invalid_amount_received' => SellFailureKind.invalidAmountReceived,
            _ => SellFailureKind.unexpected,
          },
        PostgrestException() || FormatException() => SellFailureKind.unexpected,
        // No answer within the timeout: the server may still have done it.
        TimeoutException() => SellFailureKind.serverUnreachable,
        AuthRetryableFetchException() => SellFailureKind.serverUnreachable,
        AuthException() => SellFailureKind.unexpected,
        _ => SellFailureKind.serverUnreachable,
      };
}
