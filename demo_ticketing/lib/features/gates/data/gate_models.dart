import 'package:equatable/equatable.dart';

/// `gate_direction`.
enum GateDirection {
  entry('entry'),
  exit('exit');

  const GateDirection(this.key);

  final String key;

  static GateDirection fromKey(String key) => switch (key) {
    'entry' => entry,
    'exit' => exit,
    _ => throw FormatException('unknown gate direction: $key'),
  };
}

/// A gate's status on the Gates page: the dashboard's rule for an entry gate
/// (`gate_live_status`), or [exit] for an exit gate that is switched on (no
/// gate service runs there, so it never beats).
enum GateStatus {
  online,
  offline,
  neverSeen,
  disabled,
  exit;

  static GateStatus fromKey(String key) => switch (key) {
    'online' => online,
    'offline' => offline,
    'never_seen' => neverSeen,
    'disabled' => disabled,
    'exit' => exit,
    _ => throw FormatException('unknown gate status: $key'),
  };
}

/// A controller's status: its entry gates' newest heartbeat, or
/// [noEntryGate] when none of its doors is an entry gate.
enum ControllerStatus {
  online,
  offline,
  neverSeen,
  noEntryGate;

  static ControllerStatus fromKey(String key) => switch (key) {
    'online' => online,
    'offline' => offline,
    'never_seen' => neverSeen,
    'no_entry_gate' => noEntryGate,
    _ => throw FormatException('unknown controller status: $key'),
  };
}

DateTime? _time(Object? value) => value is String ? DateTime.parse(value) : null;

class AdminController extends Equatable {
  const AdminController({
    required this.id,
    required this.name,
    this.model,
    this.ip,
    required this.port,
    required this.doorCount,
    this.gateCount = 0,
    this.lastSeenAt,
    required this.status,
  });

  factory AdminController.fromJson(Map<String, dynamic> json) => AdminController(
    id: json['id'] as String,
    name: json['name'] as String,
    model: json['model'] as String?,
    ip: json['ip'] as String?,
    port: json['port'] as int,
    doorCount: json['door_count'] as int,
    gateCount: json['gate_count'] as int? ?? 0,
    lastSeenAt: _time(json['last_seen_at']),
    status: ControllerStatus.fromKey(json['status'] as String),
  );

  final String id;
  final String name;
  final String? model;

  /// One host's address, as plain text.
  final String? ip;
  final int port;
  final int doorCount;

  /// Gates wired to it, entry or exit.
  final int gateCount;
  final DateTime? lastSeenAt;
  final ControllerStatus status;

  /// "وحدة 1 · C3-400".
  String get label => [name, ?model].join(' · ');

  ControllerDraft get draft =>
      ControllerDraft(name: name, model: model, ip: ip, port: port, doorCount: doorCount);

  @override
  List<Object?> get props => [id, name, model, ip, port, doorCount, gateCount, lastSeenAt, status];
}

class AdminGate extends Equatable {
  const AdminGate({
    required this.id,
    required this.name,
    required this.direction,
    this.controllerId,
    this.controllerName,
    this.doorNumber,
    required this.openSeconds,
    this.reader,
    required this.enabled,
    required this.status,
    this.lastSeenAt,
    this.lastScanAt,
    this.entries = 0,
    this.rejected = 0,
    this.homeOf = const [],
  });

  factory AdminGate.fromJson(Map<String, dynamic> json) => AdminGate(
    id: json['id'] as String,
    name: json['name'] as String,
    direction: GateDirection.fromKey(json['direction'] as String),
    controllerId: json['controller_id'] as String?,
    controllerName: json['controller_name'] as String?,
    doorNumber: json['door_number'] as int?,
    openSeconds: json['open_seconds'] as int,
    reader: json['reader'] as String?,
    enabled: json['enabled'] as bool,
    status: GateStatus.fromKey(json['status'] as String),
    lastSeenAt: _time(json['last_seen_at']),
    lastScanAt: _time(json['last_scan_at']),
    entries: json['entries'] as int? ?? 0,
    rejected: json['rejected'] as int? ?? 0,
    homeOf: [for (final name in (json['home_of'] as List<dynamic>? ?? const [])) name as String],
  );

  final String id;
  final String name;
  final GateDirection direction;
  final String? controllerId;
  final String? controllerName;
  final int? doorNumber;
  final int openSeconds;
  final String? reader;
  final bool enabled;
  final GateStatus status;
  final DateTime? lastSeenAt;
  final DateTime? lastScanAt;

  /// Today's accepted and refused scans.
  final int entries;
  final int rejected;

  /// The counters whose home gate it is (ADR-0015): it must stay an entry gate.
  final List<String> homeOf;

  bool get wired => controllerId != null && doorNumber != null;

  /// A gate service runs only for an entry gate, and opens only a wired one.
  bool get canTestOpen => direction == GateDirection.entry && wired;

  GateDraft get draft => GateDraft(
    name: name,
    direction: direction,
    controllerId: controllerId,
    doorNumber: doorNumber,
    openSeconds: openSeconds,
    reader: reader,
    enabled: enabled,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    direction,
    controllerId,
    controllerName,
    doorNumber,
    openSeconds,
    reader,
    enabled,
    status,
    lastSeenAt,
    lastScanAt,
    entries,
    rejected,
    homeOf,
  ];
}

String? _blankToNull(String? text) {
  final trimmed = text?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// What the gate panel saves: `save_gate`'s values.
class GateDraft extends Equatable {
  const GateDraft({
    required this.name,
    required this.direction,
    this.controllerId,
    this.doorNumber,
    required this.openSeconds,
    this.reader,
    required this.enabled,
  });

  final String name;
  final GateDirection direction;
  final String? controllerId;
  final int? doorNumber;
  final int openSeconds;
  final String? reader;
  final bool enabled;

  /// Equal to [other] as the server would store it: trimmed text, a blank
  /// reader as none.
  bool sameAs(GateDraft other) =>
      name.trim() == other.name.trim() &&
      direction == other.direction &&
      controllerId == other.controllerId &&
      doorNumber == other.doorNumber &&
      openSeconds == other.openSeconds &&
      _blankToNull(reader) == _blankToNull(other.reader) &&
      enabled == other.enabled;

  @override
  List<Object?> get props => [
    name,
    direction,
    controllerId,
    doorNumber,
    openSeconds,
    reader,
    enabled,
  ];
}

/// What the controller dialog saves: `save_controller`'s values.
class ControllerDraft extends Equatable {
  const ControllerDraft({
    required this.name,
    this.model,
    this.ip,
    required this.port,
    required this.doorCount,
  });

  final String name;
  final String? model;
  final String? ip;
  final int port;
  final int doorCount;

  bool sameAs(ControllerDraft other) =>
      name.trim() == other.name.trim() &&
      _blankToNull(model) == _blankToNull(other.model) &&
      _blankToNull(ip) == _blankToNull(other.ip) &&
      port == other.port &&
      doorCount == other.doorCount;

  @override
  List<Object?> get props => [name, model, ip, port, doorCount];
}

/// `gates_overview`'s answer.
class GatesOverview extends Equatable {
  const GatesOverview({
    required this.now,
    required this.offlineAfterSeconds,
    required this.testOpenTimeoutSeconds,
    required this.controllers,
    required this.gates,
  });

  factory GatesOverview.fromJson(Map<String, dynamic> json) => GatesOverview(
    now: DateTime.parse(json['now'] as String),
    offlineAfterSeconds: json['offline_after_seconds'] as int,
    testOpenTimeoutSeconds: json['test_open_timeout_seconds'] as int,
    controllers: [
      for (final c in json['controllers'] as List<dynamic>)
        AdminController.fromJson(c as Map<String, dynamic>),
    ],
    gates: [
      for (final g in json['gates'] as List<dynamic>) AdminGate.fromJson(g as Map<String, dynamic>),
    ],
  );

  /// The server's clock when it answered.
  final DateTime now;
  final int offlineAfterSeconds;
  final int testOpenTimeoutSeconds;
  final List<AdminController> controllers;

  /// Entry gates first, then by name.
  final List<AdminGate> gates;

  AdminGate? gate(String? id) {
    for (final g in gates) {
      if (g.id == id) return g;
    }
    return null;
  }

  @override
  List<Object?> get props => [now, offlineAfterSeconds, testOpenTimeoutSeconds, controllers, gates];
}

/// What a test open came to (`gate_command_result`).
enum TestOpenResult {
  waiting,
  opened,
  failed,
  noAnswer;

  static TestOpenResult fromKey(String key) => switch (key) {
    'waiting' => waiting,
    'opened' => opened,
    'failed' => failed,
    'no_answer' => noAnswer,
    _ => throw FormatException('unknown test open result: $key'),
  };
}

/// `test_open_gate`'s answer.
class TestOpenRequest extends Equatable {
  const TestOpenRequest({
    required this.commandId,
    required this.openSeconds,
    required this.timeoutSeconds,
  });

  factory TestOpenRequest.fromJson(Map<String, dynamic> json) => TestOpenRequest(
    commandId: json['command_id'] as String,
    openSeconds: json['open_seconds'] as int,
    timeoutSeconds: json['timeout_seconds'] as int,
  );

  final String commandId;
  final int openSeconds;
  final int timeoutSeconds;

  @override
  List<Object?> get props => [commandId, openSeconds, timeoutSeconds];
}

/// `test_open_status`'s answer.
class TestOpenStatus extends Equatable {
  const TestOpenStatus({required this.result, this.detail});

  factory TestOpenStatus.fromJson(Map<String, dynamic> json) => TestOpenStatus(
    result: TestOpenResult.fromKey(json['result'] as String),
    detail: json['detail'] as String?,
  );

  final TestOpenResult result;

  /// The gate service's own words, for a failure.
  final String? detail;

  @override
  List<Object?> get props => [result, detail];
}
