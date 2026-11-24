import 'dart:async';

import '../../../demo/backend.dart';

import '../../../core/server_call.dart';
import 'dashboard_snapshot.dart';

enum DashboardFailureKind { notAllowed, serverUnreachable, unexpected }

class DashboardFailure implements Exception {
  const DashboardFailure(this.kind);

  final DashboardFailureKind kind;

  @override
  String toString() => 'DashboardFailure($kind)';
}

/// What the Realtime channel on `scans` reports.
enum LiveSignal {
  /// The channel is joined: new scans will be heard.
  subscribed,

  /// The channel dropped or failed; the client rejoins on its own.
  disconnected,

  /// A scan was inserted.
  changed,
}

/// The live dashboard's data (ADR-0030): `dashboard_today` for the figures,
/// and a Realtime channel that only says a scan happened. The event itself is
/// never read; the figures always come from the function.
class DashboardRepository {
  DashboardRepository(this._client, {this._timeout = serverCallTimeout});

  final DemoBackend _client;

  /// How long a call waits for an answer ([serverCallTimeout], ADR-0039).
  final Duration _timeout;

  /// `dashboard_today`. Throws [DashboardFailure].
  Future<DashboardSnapshot> load() async {
    try {
      final result = await _client.rpc<Map<String, dynamic>>('dashboard_today').timeout(_timeout);
      return DashboardSnapshot.fromJson(result);
    } on Exception catch (e) {
      throw DashboardFailure(failureKindFor(e));
    } on TypeError {
      // A field of the wrong type in the answer.
      throw const DashboardFailure(DashboardFailureKind.unexpected);
    }
  }

  /// New scans as [LiveSignal]s, while listened to. Cancelling the
  /// subscription removes the channel.
  Stream<LiveSignal> watchScans() {
    // Production subscribes to inserts on `scans` over Realtime; the demo's
    // gate scanner announces its scans directly.
    late final StreamController<LiveSignal> controller;
    StreamSubscription<void>? scans;
    controller = StreamController<LiveSignal>(
      onListen: () {
        controller.add(LiveSignal.subscribed);
        scans = _client.scanEvents.listen((_) => controller.add(LiveSignal.changed));
      },
      onCancel: () async {
        await scans?.cancel();
        await controller.close();
      },
    );
    return controller.stream;
  }

  static DashboardFailureKind failureKindFor(Exception error) => switch (error) {
    PostgrestException(code: 'P0001', message: 'not_allowed' || 'not_staff') =>
      DashboardFailureKind.notAllowed,
    PostgrestException() || FormatException() => DashboardFailureKind.unexpected,
    // No answer within the timeout: the server may still have done it.
    TimeoutException() => DashboardFailureKind.serverUnreachable,
    AuthRetryableFetchException() => DashboardFailureKind.serverUnreachable,
    AuthException() => DashboardFailureKind.unexpected,
    _ => DashboardFailureKind.serverUnreachable,
  };
}
