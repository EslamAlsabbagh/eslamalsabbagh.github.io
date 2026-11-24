import 'dart:async';

import '../../../demo/backend.dart';

import '../../../core/server_call.dart';
import 'user_models.dart';

enum UsersFailureKind {
  notAllowed,
  nameRequired,
  invalidUsername,
  usernameTaken,
  passwordTooShort,
  passwordTooLong,

  /// An admin's own role or active (ADR-0036).
  cannotChangeOwnAccount,

  /// Deactivating someone whose shift is still open.
  staffHasOpenShift,

  /// The user was there when the page read it, and isn't now.
  notFound,
  serverUnreachable,
  unexpected,
}

class UsersFailure implements Exception {
  const UsersFailure(this.kind);

  final UsersFailureKind kind;

  @override
  String toString() => 'UsersFailure($kind)';
}

/// The Users page's data (4.7). Admins only: users change through
/// `save_staff`, which also makes or renames the login, and passwords through
/// `reset_staff_password`. Both log each change (ADR-0036).
class UsersRepository {
  UsersRepository(this._client, {this._timeout = serverCallTimeout});

  final DemoBackend _client;

  /// How long a call waits for an answer ([serverCallTimeout], ADR-0039).
  final Duration _timeout;

  /// Throws [UsersFailure].
  Future<UsersOverview> overview() => _guard(
    () async => UsersOverview.fromJson(await _client.rpc<Map<String, dynamic>>('users_overview')),
  );

  /// Adds a user ([id] null, with [UserDraft.password]) or changes one.
  /// Returns its id. Throws [UsersFailure].
  Future<String> save({String? id, required UserDraft draft}) => _guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'save_staff',
      params: {
        'p_id': id,
        'p_full_name': draft.fullName,
        'p_username': draft.username,
        'p_role': draft.role.name,
        'p_active': draft.active,
        if (id == null) 'p_password': draft.password,
      },
    );
    return row['id'] as String;
  });

  /// Sets [id]'s password and ends their sessions. Throws [UsersFailure].
  Future<void> resetPassword(String id, String password) => _guard(
    () => _client.rpc<void>(
      'reset_staff_password',
      params: {'p_staff_id': id, 'p_password': password},
    ),
  );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on Exception catch (e) {
      throw UsersFailure(failureKindFor(e));
    } on TypeError {
      // A field of the wrong type in the answer.
      throw const UsersFailure(UsersFailureKind.unexpected);
    } on ArgumentError {
      // A role this app doesn't know.
      throw const UsersFailure(UsersFailureKind.unexpected);
    }
  }

  static UsersFailureKind failureKindFor(Exception error) => switch (error) {
    PostgrestException(code: 'P0001', :final message) => switch (message) {
      'not_allowed' || 'not_staff' => UsersFailureKind.notAllowed,
      'name_required' => UsersFailureKind.nameRequired,
      'invalid_username' => UsersFailureKind.invalidUsername,
      'username_taken' => UsersFailureKind.usernameTaken,
      'password_too_short' => UsersFailureKind.passwordTooShort,
      'password_too_long' => UsersFailureKind.passwordTooLong,
      'cannot_change_own_account' => UsersFailureKind.cannotChangeOwnAccount,
      'staff_has_open_shift' => UsersFailureKind.staffHasOpenShift,
      'not_found' => UsersFailureKind.notFound,
      _ => UsersFailureKind.unexpected,
    },
    PostgrestException(code: '42501') => UsersFailureKind.notAllowed,
    PostgrestException() || FormatException() => UsersFailureKind.unexpected,
    // No answer within the timeout: the server may still have done it.
    TimeoutException() => UsersFailureKind.serverUnreachable,
    AuthRetryableFetchException() => UsersFailureKind.serverUnreachable,
    AuthException() => UsersFailureKind.unexpected,
    _ => UsersFailureKind.serverUnreachable,
  };
}
