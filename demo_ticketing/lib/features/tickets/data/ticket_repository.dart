import 'dart:async';

import '../../../demo/backend.dart';

import '../../../core/server_call.dart';
import 'ticket_failure.dart';
import 'ticket_lookup.dart';

/// The ticket lookup and the cashier's ticket actions, without approval
/// (ADR-0009): `lookup_ticket`, `reprint_ticket`, `reactivate_ticket`,
/// `void_refund_ticket`. The limits are the server's; the screen only shows
/// them.
///
/// Every method throws [TicketFailure] rather than Supabase or network errors.
class TicketRepository {
  TicketRepository(this._client, {this._timeout = serverCallTimeout});

  final DemoBackend _client;

  /// How long a call waits for an answer before it counts as
  /// [TicketFailureKind.serverUnreachable], as `SellRepository` (ADR-0039): a
  /// dead server can leave a request waiting with no error at all.
  final Duration _timeout;

  /// `lookup_ticket`: [code] as scanned or typed.
  Future<TicketLookup> lookup(String code) => _guard(() async {
        final result =
            await _client.rpc<Map<String, dynamic>>('lookup_ticket', params: {'p_code': code});
        return TicketLookup.fromJson(result);
      });

  /// The settings the limit texts show.
  Future<TicketActionSettings> actionSettings() => _guard(() async {
        final row = await _client
            .from('settings')
            .select('reactivation_window_min, reactivation_max, refund_before_scan_only, '
                'refund_same_shift_only')
            .single();
        return TicketActionSettings.fromRow(row);
      });

  Future<ReprintedTicket> reprint(String ticketId, ActionReason reason, {String? reasonText}) =>
      _guard(() async {
        final result = await _client.rpc<Map<String, dynamic>>(
          'reprint_ticket',
          params: _params(ticketId, reason, reasonText),
        );
        return ReprintedTicket.fromJson(result);
      });

  Future<void> reactivate(String ticketId, ActionReason reason, {String? reasonText}) =>
      _guard(() async {
        await _client.rpc<Map<String, dynamic>>(
          'reactivate_ticket',
          params: _params(ticketId, reason, reasonText),
        );
      });

  Future<RefundResult> voidRefund(String ticketId, ActionReason reason, {String? reasonText}) =>
      _guard(() async {
        final result = await _client.rpc<Map<String, dynamic>>(
          'void_refund_ticket',
          params: _params(ticketId, reason, reasonText),
        );
        return RefundResult.fromJson(result);
      });

  static Map<String, dynamic> _params(String ticketId, ActionReason reason, String? reasonText) => {
        'p_ticket_id': ticketId,
        'p_reason': reason.key,
        'p_reason_text': reasonText,
      };

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on Exception catch (e) {
      throw TicketFailure(failureKindFor(e));
    }
  }

  /// As `SellRepository.failureKindFor`: business errors are P0001 with a
  /// snake_case key, any other server or parsing error is unexpected, and
  /// everything else means the server can't be reached.
  static TicketFailureKind failureKindFor(Exception error) => switch (error) {
        PostgrestException(code: 'P0001', :final message) => TicketFailureKind.fromKey(message),
        PostgrestException() || FormatException() => TicketFailureKind.unexpected,
        // No answer within the timeout: the server may still have done it.
        TimeoutException() => TicketFailureKind.serverUnreachable,
        AuthRetryableFetchException() => TicketFailureKind.serverUnreachable,
        AuthException() => TicketFailureKind.unexpected,
        _ => TicketFailureKind.serverUnreachable,
      };
}
