import 'dart:async';

import '../../../demo/backend.dart';

import '../../../core/server_call.dart';
import 'shift_models.dart';

enum ShiftsFailureKind {
  notAllowed,
  serverUnreachable,

  /// The difference isn't 0 and there's no comment, or a refusal's clearing
  /// has none.
  commentRequired,

  /// Nobody approves, or clears a refusal of, their own shift (ADR-0017).
  ownShift,
  alreadyApproved,
  notClosed,
  refusalAlreadyClosed,
  notFound,
  unexpected,
}

class ShiftsFailure implements Exception {
  const ShiftsFailure(this.kind);

  final ShiftsFailureKind kind;

  @override
  String toString() => 'ShiftsFailure($kind)';
}

/// The Shifts page's data (4.2): `shifts_overview` for the list,
/// `shift_reconciliation` for one shift, `shift_offline_refusals`, and the two
/// supervisor actions. Every figure comes from the server; nothing is summed
/// here (ADR-0008).
class ShiftsRepository {
  ShiftsRepository(this._client, {this._timeout = serverCallTimeout});

  final DemoBackend _client;

  /// How long a call waits for an answer ([serverCallTimeout], ADR-0039).
  final Duration _timeout;

  /// Throws [ShiftsFailure].
  Future<ShiftsOverview> overview(ShiftsPeriod period) => _call(() async {
    final result = await _client.rpc<Map<String, dynamic>>(
      'shifts_overview',
      params: {'p_period': period.key},
    );
    return ShiftsOverview.fromJson(result);
  });

  /// One shift by `p_shift_id` (a PostgREST filter would compute every shift
  /// first, 1.12). Null when it doesn't exist.
  Future<ShiftRow?> shift(String id) => _call(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'shift_reconciliation',
      params: {'p_shift_id': id},
    );
    return rows.isEmpty ? null : ShiftRow.fromJson(rows.first as Map<String, dynamic>);
  });

  Future<List<OfflineRefusal>> refusals(String shiftId) => _call(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'shift_offline_refusals',
      params: {'p_shift_id': shiftId},
    );
    return [for (final row in rows) OfflineRefusal.fromJson(row as Map<String, dynamic>)];
  });

  /// `approve_shift`. A blank comment is sent as null.
  Future<void> approve(String shiftId, String comment) => _call(() async {
    final trimmed = comment.trim();
    await _client.rpc<dynamic>(
      'approve_shift',
      params: {'p_shift_id': shiftId, 'p_comment': trimmed.isEmpty ? null : trimmed},
    );
  });

  /// `resolve_offline_refusal`: clears a refusal so its shift can close.
  Future<void> resolveRefusal(String refusalId, String comment) => _call(() async {
    await _client.rpc<dynamic>(
      'resolve_offline_refusal',
      params: {'p_refusal_id': refusalId, 'p_comment': comment.trim()},
    );
  });

  /// Closed shifts not approved yet, for the menu badge. A count of ids, so no
  /// figure is computed.
  Future<int> pendingCount() => _call(() async {
    final response = await _client
        .from('shifts')
        .select('id')
        .eq('status', 'closed')
        .count(CountOption.exact);
    return response.count;
  });

  Future<T> _call<T>(Future<T> Function() body) async {
    try {
      return await body().timeout(_timeout);
    } on Exception catch (e) {
      throw ShiftsFailure(failureKindFor(e));
    } on TypeError {
      // A field of the wrong type in the answer.
      throw const ShiftsFailure(ShiftsFailureKind.unexpected);
    }
  }

  static ShiftsFailureKind failureKindFor(Exception error) => switch (error) {
    PostgrestException(code: 'P0001', :final message) => switch (message) {
      'not_allowed' || 'not_staff' => ShiftsFailureKind.notAllowed,
      'comment_required' => ShiftsFailureKind.commentRequired,
      'cannot_approve_own_shift' || 'cannot_resolve_own_shift' => ShiftsFailureKind.ownShift,
      'shift_already_approved' => ShiftsFailureKind.alreadyApproved,
      'shift_not_closed' => ShiftsFailureKind.notClosed,
      'refusal_already_closed' => ShiftsFailureKind.refusalAlreadyClosed,
      'shift_not_found' || 'refusal_not_found' => ShiftsFailureKind.notFound,
      _ => ShiftsFailureKind.unexpected,
    },
    PostgrestException() || FormatException() => ShiftsFailureKind.unexpected,
    // No answer within the timeout: the server may still have done it.
    TimeoutException() => ShiftsFailureKind.serverUnreachable,
    AuthRetryableFetchException() => ShiftsFailureKind.serverUnreachable,
    AuthException() => ShiftsFailureKind.unexpected,
    _ => ShiftsFailureKind.serverUnreachable,
  };
}
