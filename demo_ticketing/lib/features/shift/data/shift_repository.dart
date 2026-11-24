import 'dart:async';

import '../../../demo/backend.dart';

import '../../../core/printer/shift_receipt.dart';
import '../../../core/server_call.dart';
import 'close_shift.dart';
import 'open_shift.dart';

/// Why a shift call failed. Each kind has one message on screen.
enum ShiftFailureKind {
  shiftAlreadyOpen,
  invalidOpeningCash,
  counterUnavailable,
  counterNoHomeGate,
  counterBusy,

  /// Close shift (2.7).
  noOpenShift,
  invalidTip,
  tipsDisabled,
  invalidCashCount,
  ordersAwaitingPayment,

  /// A refused offline order or action no supervisor has cleared (ADR-0026).
  offlineRefusalsOpen,
  serverUnreachable,
  unexpected,
}

class ShiftFailure implements Exception {
  const ShiftFailure(this.kind);

  final ShiftFailureKind kind;

  @override
  String toString() => 'ShiftFailure(${kind.name})';
}

/// Shift reads, `open_shift`, and the close shift calls (2.7).
///
/// Every method throws [ShiftFailure] rather than Supabase or network errors.
class ShiftRepository {
  ShiftRepository(this._client, {this._timeout = serverCallTimeout});

  final DemoBackend _client;

  /// How long a call waits for an answer before it counts as
  /// [ShiftFailureKind.serverUnreachable], as `SellRepository` (ADR-0039): a
  /// dead server can leave a request waiting with no error at all.
  final Duration _timeout;

  /// The saved session's user: known with the server down.
  String? get currentUserId => _client.currentUserId;

  /// The caller's open shift, or null. RLS shows a cashier only their own
  /// open shift; supervisors see every shift, hence the cashier filter.
  Future<OpenShift?> myOpenShift() => _guard(() async {
        final userId = _client.currentUserId;
        if (userId == null) return null;
        final row = await _client
            .from('shifts')
            .select('id, number, counter_id, opened_at, counter:counters(name)')
            .eq('cashier_id', userId)
            .eq('status', 'open')
            .maybeSingle();
        return row == null ? null : OpenShift.fromRow(row);
      });

  /// The counter, or null when it doesn't exist.
  Future<CounterInfo?> counter(String counterId) => _guard(() async {
        final row = await _client
            .from('counters')
            .select('id, name, active, printer_ip, printer_port, paper_width_mm, entry_gate_id, '
                'entry_gate:gates(name)')
            .eq('id', counterId)
            .maybeSingle();
        return row == null ? null : CounterInfo.fromRow(row);
      });

  /// The settings the open shift screen needs: the quick float amounts, and
  /// the venue name for the test page's sample ticket.
  Future<OpenShiftSettings> openShiftSettings() => _guard(() async {
        final row = await _client
            .from('settings')
            .select('opening_float_quick_amounts_piastres, venue_name')
            .single();
        return OpenShiftSettings.fromRow(row);
      });

  /// When the counter's last shift closed (`last_shift_closed_at`), or null.
  Future<DateTime?> lastClosedAt(String counterId) => _guard(() async {
        final value =
            await _client.rpc<dynamic>('last_shift_closed_at', params: {'p_counter_id': counterId});
        return value == null ? null : DateTime.parse(value as String).toLocal();
      });

  /// `open_shift`. The counter comes from this PC's config.
  Future<OpenShift> openShift(String counterId, int openingCashPiastres) => _guard(() async {
        final result = await _client.rpc<Map<String, dynamic>>('open_shift', params: {
          'p_counter_id': counterId,
          'p_opening_cash_piastres': openingCashPiastres,
        });
        return OpenShift.fromOpenShiftResult(result);
      });

  /// The settings the close shift screen needs.
  Future<CloseShiftSettings> closeShiftSettings() => _guard(() async {
        final row = await _client
            .from('settings')
            .select('venue_name, tips_enabled, tip_quick_amounts_piastres, '
                'unpaid_order_timeout_min, cash_denominations_piastres')
            .single();
        return CloseShiftSettings.fromRow(row);
      });

  /// `my_shift_tips`: the open shift's tips, oldest first.
  Future<List<ShiftTip>> myShiftTips() => _guard(() async {
        final result = await _client.rpc<List<dynamic>>('my_shift_tips');
        return [for (final row in result.cast<Map<String, dynamic>>()) ShiftTip.fromJson(row)];
      });

  /// `add_tip`: a tip without an order, in the caller's open shift. Returns
  /// it as `my_shift_tips` lists it.
  Future<ShiftTip> addTip(int amountPiastres) => _guard(() async {
        final result = await _client
            .rpc<Map<String, dynamic>>('add_tip', params: {'p_amount_piastres': amountPiastres});
        return ShiftTip.fromJson(result);
      });

  /// `close_shift` with the count per denomination (piastres → count). Only
  /// counts above 0 are sent; the server stores no zero rows anyway.
  Future<ShiftReceipt> closeShift(Map<int, int> counts, {required String venueName}) =>
      _guard(() async {
        final result = await _client.rpc<Map<String, dynamic>>('close_shift', params: {
          'p_counts': [
            for (final MapEntry(key: denomination, value: count) in counts.entries)
              if (count > 0) {'denomination_piastres': denomination, 'count': count},
          ],
        });
        return ShiftReceipt.fromCloseShift(result, venueName: venueName);
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on Exception catch (e) {
      throw ShiftFailure(failureKindFor(e));
    }
  }

  /// Business errors are P0001 with a snake_case key. Any other server or
  /// parsing error is unexpected; everything else (socket, HTTP client) means
  /// the server can't be reached.
  static ShiftFailureKind failureKindFor(Exception error) => switch (error) {
        PostgrestException(code: 'P0001', :final message) => switch (message) {
            'shift_already_open' => ShiftFailureKind.shiftAlreadyOpen,
            'invalid_opening_cash' => ShiftFailureKind.invalidOpeningCash,
            'counter_unavailable' => ShiftFailureKind.counterUnavailable,
            'counter_no_home_gate' => ShiftFailureKind.counterNoHomeGate,
            'counter_busy' => ShiftFailureKind.counterBusy,
            'no_open_shift' => ShiftFailureKind.noOpenShift,
            'invalid_tip' => ShiftFailureKind.invalidTip,
            'tips_disabled' => ShiftFailureKind.tipsDisabled,
            'invalid_cash_count' => ShiftFailureKind.invalidCashCount,
            'orders_awaiting_payment' => ShiftFailureKind.ordersAwaitingPayment,
            'offline_refusals_open' => ShiftFailureKind.offlineRefusalsOpen,
            _ => ShiftFailureKind.unexpected,
          },
        PostgrestException() || FormatException() => ShiftFailureKind.unexpected,
        // No answer within the timeout: the server may still have done it.
        TimeoutException() => ShiftFailureKind.serverUnreachable,
        AuthRetryableFetchException() => ShiftFailureKind.serverUnreachable,
        AuthException() => ShiftFailureKind.unexpected,
        _ => ShiftFailureKind.serverUnreachable,
      };
}
