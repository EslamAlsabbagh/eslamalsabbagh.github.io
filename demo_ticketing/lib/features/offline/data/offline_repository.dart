import 'dart:async';

import '../../../demo/backend.dart';

import '../../../core/server_call.dart';
import 'offline_models.dart';

/// Why an offline call failed.
enum OfflineFailureKind {
  noOpenShift,
  shiftNotOpen,
  counterNoHomeGate,
  gateCodeSpaceExhausted,

  /// The access token expired while the server was out of reach: the
  /// session must be refreshed before the next call.
  sessionExpired,
  serverUnreachable,
  unexpected,
}

class OfflineFailure implements Exception {
  const OfflineFailure(this.kind);

  final OfflineFailureKind kind;

  @override
  String toString() => 'OfflineFailure(${kind.name})';
}

/// The server's side of offline selling (ADR-0015): the health check, the
/// pool top-up (`reserve_offline_codes`) and the uploads
/// (`sync_offline_orders`, `sync_offline_actions`).
class OfflineRepository {
  OfflineRepository(this._client, {this._timeout = serverCallTimeout});

  final DemoBackend _client;

  /// How long the top-up and the uploads wait for an answer
  /// ([serverCallTimeout], ADR-0039). A hung upload kept `OfflineSyncCubit`
  /// running, so no later upload started and the shift couldn't close. A
  /// repeat is harmless: the uploads are idempotent by `client_id`.
  final Duration _timeout;

  /// Whether the server answers within [timeout]. Any answer counts, even a
  /// refusal (an expired token): only no answer at all means offline. It
  /// goes through PostgREST and the database, which selling needs, not only
  /// the auth service.
  Future<bool> ping({required Duration timeout}) async {
    try {
      await _client.from('settings').select('offline_health_check_seconds').limit(1).timeout(timeout);
      return true;
    } on PostgrestException {
      return true;
    } on AuthRetryableFetchException {
      return false;
    } on AuthException {
      return true;
    } on Exception {
      // A socket or HTTP client error, or the timeout.
      return false;
    }
  }

  /// Tops the counter's pool up to `offline_pool_size` and returns all its
  /// live codes.
  Future<ReservedPool> reserveOfflineCodes() => _guard(() async {
        final result = await _client.rpc<Map<String, dynamic>>('reserve_offline_codes');
        return ReservedPool.fromJson(result);
      });

  /// Uploads [orders] (`OfflineStore.pendingUploads`) into the caller's open
  /// shift [shiftId]. Each order is accepted or refused on its own;
  /// idempotent by `client_id`.
  Future<List<SyncResult>> syncOfflineOrders(String shiftId, List<Map<String, Object?>> orders) =>
      _guard(() async {
        final result = await _client.rpc<Map<String, dynamic>>('sync_offline_orders', params: {
          'p_shift_id': shiftId,
          'p_orders': orders,
        });
        return [
          for (final row in (result['results'] as List).cast<Map<String, dynamic>>())
            SyncResult.fromJson(row),
        ];
      });

  /// Uploads logged [actions] (`OfflineStore.pendingActionUploads`) into the
  /// caller's open shift [shiftId], each on its own; idempotent by `client_id`.
  Future<List<SyncResult>> syncOfflineActions(String shiftId, List<Map<String, Object?>> actions) =>
      _guard(() async {
        final result = await _client.rpc<Map<String, dynamic>>('sync_offline_actions', params: {
          'p_shift_id': shiftId,
          'p_actions': actions,
        });
        return [
          for (final row in (result['results'] as List).cast<Map<String, dynamic>>())
            SyncResult.fromJson(row),
        ];
      });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on Exception catch (e) {
      throw OfflineFailure(failureKindFor(e));
    }
  }

  /// As `SellRepository.failureKindFor`, plus an expired token (PostgREST's
  /// `PGRST301` / `PGRST303`), which a session refresh fixes.
  static OfflineFailureKind failureKindFor(Exception error) => switch (error) {
        PostgrestException(code: 'P0001', :final message) => switch (message) {
            'no_open_shift' || 'not_staff' => OfflineFailureKind.noOpenShift,
            'shift_not_open' => OfflineFailureKind.shiftNotOpen,
            'counter_no_home_gate' => OfflineFailureKind.counterNoHomeGate,
            'gate_code_space_exhausted' => OfflineFailureKind.gateCodeSpaceExhausted,
            _ => OfflineFailureKind.unexpected,
          },
        PostgrestException(code: 'PGRST301' || 'PGRST303') => OfflineFailureKind.sessionExpired,
        PostgrestException() || FormatException() => OfflineFailureKind.unexpected,
        // No answer within the timeout: the server may still have done it.
        TimeoutException() => OfflineFailureKind.serverUnreachable,
        AuthRetryableFetchException() => OfflineFailureKind.serverUnreachable,
        AuthException() => OfflineFailureKind.unexpected,
        _ => OfflineFailureKind.serverUnreachable,
      };
}
