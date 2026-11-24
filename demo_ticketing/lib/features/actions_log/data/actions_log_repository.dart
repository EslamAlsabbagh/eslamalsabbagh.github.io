import 'dart:async';

import '../../../demo/backend.dart';

import '../../../core/server_call.dart';
import 'action_log_models.dart';

enum ActionsLogFailureKind {
  notAllowed,
  serverUnreachable,

  /// Nobody reviews their own action (ADR-0018).
  ownAction,
  alreadyReviewed,
  notFlagged,
  notFound,
  unexpected,
}

class ActionsLogFailure implements Exception {
  const ActionsLogFailure(this.kind);

  final ActionsLogFailureKind kind;

  @override
  String toString() => 'ActionsLogFailure($kind)';
}

/// The Actions log page's data (4.3): `actions_log` and `mark_action_reviewed`.
/// No gate code reaches the app: a row carries the last 3 digits only.
class ActionsLogRepository {
  ActionsLogRepository(this._client, {this._timeout = serverCallTimeout});

  final DemoBackend _client;

  /// How long a call waits for an answer ([serverCallTimeout], ADR-0039).
  final Duration _timeout;

  /// The rows cap of the page. The CSV asks for every row ([limit] null).
  static const pageLimit = 2000;

  /// Throws [ActionsLogFailure].
  Future<ActionsLog> load({
    required ActionsPeriod period,
    String? actorId,
    String? counterId,
    String? shiftId,
    int? limit = pageLimit,
  }) => _call(() async {
    final result = await _client.rpc<Map<String, dynamic>>(
      'actions_log',
      params: {
        'p_period': period.key,
        'p_actor_id': actorId,
        'p_counter_id': counterId,
        'p_shift_id': shiftId,
        'p_limit': limit,
      },
    );
    return ActionsLog.fromJson(result);
  });

  Future<void> markReviewed(String actionId) => _call(() async {
    await _client.rpc<dynamic>('mark_action_reviewed', params: {'p_action_id': actionId});
  });

  /// Flagged actions not reviewed yet, for the menu badge. A count of ids.
  Future<int> pendingCount() => _call(() async {
    final response = await _client
        .from('ticket_actions')
        .select('id')
        .neq('flags', '{}')
        .isFilter('reviewed_at', null)
        .count(CountOption.exact);
    return response.count;
  });

  Future<T> _call<T>(Future<T> Function() body) async {
    try {
      return await body().timeout(_timeout);
    } on Exception catch (e) {
      throw ActionsLogFailure(failureKindFor(e));
    } on TypeError {
      // A field of the wrong type in the answer.
      throw const ActionsLogFailure(ActionsLogFailureKind.unexpected);
    }
  }

  static ActionsLogFailureKind failureKindFor(Exception error) => switch (error) {
    PostgrestException(code: 'P0001', :final message) => switch (message) {
      'not_allowed' || 'not_staff' => ActionsLogFailureKind.notAllowed,
      'cannot_review_own_action' => ActionsLogFailureKind.ownAction,
      'action_already_reviewed' => ActionsLogFailureKind.alreadyReviewed,
      'action_not_flagged' => ActionsLogFailureKind.notFlagged,
      'action_not_found' || 'shift_not_found' => ActionsLogFailureKind.notFound,
      _ => ActionsLogFailureKind.unexpected,
    },
    PostgrestException() || FormatException() => ActionsLogFailureKind.unexpected,
    // No answer within the timeout: the server may still have done it.
    TimeoutException() => ActionsLogFailureKind.serverUnreachable,
    AuthRetryableFetchException() => ActionsLogFailureKind.serverUnreachable,
    AuthException() => ActionsLogFailureKind.unexpected,
    _ => ActionsLogFailureKind.serverUnreachable,
  };
}
