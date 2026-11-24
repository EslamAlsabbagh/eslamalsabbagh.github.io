import 'dart:async';

import '../../../demo/backend.dart';

import '../../../core/server_call.dart';
import 'gate_models.dart';

enum GatesFailureKind {
  notAllowed,
  invalidName,
  nameTaken,
  invalidOpenSeconds,

  /// A controller without a door, or a door without a controller.
  invalidWiring,
  controllerNotFound,
  doorNotOnController,
  doorTaken,

  /// A counter's home gate can't become an exit gate (ADR-0015).
  homeGateMustBeEntry,
  invalidIp,
  invalidPort,
  invalidDoorCount,

  /// Fewer doors than a wired gate's door number.
  doorsInUse,

  /// The gate or controller was there when the page read it, and isn't now.
  notFound,

  /// Test open: an exit gate, or one with no controller.
  notEntryGate,
  gateNotWired,

  /// Test open: one is already waiting for that gate.
  testOpenPending,
  serverUnreachable,
  unexpected,
}

class GatesFailure implements Exception {
  const GatesFailure(this.kind);

  final GatesFailureKind kind;

  @override
  String toString() => 'GatesFailure($kind)';
}

/// The Gates page's data (4.6). Admins only: gates and controllers change
/// through `save_gate` / `save_controller`, which log each change, and a test
/// open goes through `test_open_gate` to the gate's service (ADR-0035).
class GatesRepository {
  GatesRepository(this._client, {this._timeout = serverCallTimeout});

  final DemoBackend _client;

  /// How long a call waits for an answer ([serverCallTimeout], ADR-0039).
  final Duration _timeout;

  /// Throws [GatesFailure].
  Future<GatesOverview> overview() => _guard(
    () async => GatesOverview.fromJson(await _client.rpc<Map<String, dynamic>>('gates_overview')),
  );

  /// Adds a gate ([id] null) or changes one. Returns its id. Throws [GatesFailure].
  Future<String> saveGate({String? id, required GateDraft draft}) => _guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'save_gate',
      params: {
        'p_id': id,
        'p_name': draft.name,
        'p_direction': draft.direction.key,
        'p_controller_id': draft.controllerId,
        'p_door_number': draft.doorNumber,
        'p_open_seconds': draft.openSeconds,
        'p_reader': draft.reader,
        'p_enabled': draft.enabled,
      },
    );
    return row['id'] as String;
  });

  /// Adds a controller ([id] null) or changes one. Returns its id. Throws
  /// [GatesFailure].
  Future<String> saveController({String? id, required ControllerDraft draft}) => _guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'save_controller',
      params: {
        'p_id': id,
        'p_name': draft.name,
        'p_model': draft.model,
        'p_ip': draft.ip,
        'p_port': draft.port,
        'p_door_count': draft.doorCount,
      },
    );
    return row['id'] as String;
  });

  /// Asks the gate's service to open it once. Logged. Throws [GatesFailure].
  Future<TestOpenRequest> testOpen(String gateId) => _guard(
    () async => TestOpenRequest.fromJson(
      await _client.rpc<Map<String, dynamic>>('test_open_gate', params: {'p_gate_id': gateId}),
    ),
  );

  /// Throws [GatesFailure].
  Future<TestOpenStatus> testOpenStatus(String commandId) => _guard(
    () async => TestOpenStatus.fromJson(
      await _client.rpc<Map<String, dynamic>>(
        'test_open_status',
        params: {'p_command_id': commandId},
      ),
    ),
  );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on Exception catch (e) {
      throw GatesFailure(failureKindFor(e));
    } on TypeError {
      // A field of the wrong type in the answer.
      throw const GatesFailure(GatesFailureKind.unexpected);
    }
  }

  static GatesFailureKind failureKindFor(Exception error) => switch (error) {
    PostgrestException(code: 'P0001', :final message) => switch (message) {
      'not_allowed' || 'not_staff' => GatesFailureKind.notAllowed,
      'invalid_name' => GatesFailureKind.invalidName,
      'name_taken' => GatesFailureKind.nameTaken,
      'invalid_open_seconds' => GatesFailureKind.invalidOpenSeconds,
      'invalid_wiring' => GatesFailureKind.invalidWiring,
      'controller_not_found' => GatesFailureKind.controllerNotFound,
      'door_not_on_controller' => GatesFailureKind.doorNotOnController,
      'door_taken' => GatesFailureKind.doorTaken,
      'home_gate_must_be_entry' => GatesFailureKind.homeGateMustBeEntry,
      'invalid_ip' => GatesFailureKind.invalidIp,
      'invalid_port' => GatesFailureKind.invalidPort,
      'invalid_door_count' => GatesFailureKind.invalidDoorCount,
      'doors_in_use' => GatesFailureKind.doorsInUse,
      'not_found' || 'gate_not_found' || 'command_not_found' => GatesFailureKind.notFound,
      'not_entry_gate' => GatesFailureKind.notEntryGate,
      'gate_not_wired' => GatesFailureKind.gateNotWired,
      'test_open_pending' => GatesFailureKind.testOpenPending,
      _ => GatesFailureKind.unexpected,
    },
    PostgrestException(code: '42501') => GatesFailureKind.notAllowed,
    PostgrestException() || FormatException() => GatesFailureKind.unexpected,
    // No answer within the timeout: the server may still have done it.
    TimeoutException() => GatesFailureKind.serverUnreachable,
    AuthRetryableFetchException() => GatesFailureKind.serverUnreachable,
    AuthException() => GatesFailureKind.unexpected,
    _ => GatesFailureKind.serverUnreachable,
  };
}
