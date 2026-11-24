import '../../../l10n/gen/app_localizations.dart';
import '../../actions_log/data/action_log_models.dart' show SettingsChange;
import '../../tickets/view/ticket_messages.dart' show dayTime;
import '../bloc/gates_cubit.dart';
import '../data/gate_models.dart';
import '../data/gates_repository.dart';

/// The Gates page's texts, shared with the actions log's change lines.

String gatesFailureMessage(AppLocalizations l10n, GatesFailureKind kind) => switch (kind) {
  GatesFailureKind.notAllowed => l10n.gatesNotAllowed,
  GatesFailureKind.invalidName => l10n.gatesInvalidName,
  GatesFailureKind.nameTaken => l10n.gatesNameTaken,
  GatesFailureKind.invalidOpenSeconds => l10n.gatesInvalidOpenSeconds,
  GatesFailureKind.invalidWiring => l10n.gatesInvalidWiring,
  GatesFailureKind.controllerNotFound => l10n.gatesControllerNotFound,
  GatesFailureKind.doorNotOnController => l10n.gatesDoorNotOnController,
  GatesFailureKind.doorTaken => l10n.gatesDoorTaken,
  GatesFailureKind.homeGateMustBeEntry => l10n.gatesHomeGateMustBeEntry,
  GatesFailureKind.invalidIp => l10n.gatesInvalidIp,
  GatesFailureKind.invalidPort => l10n.gatesInvalidPort,
  GatesFailureKind.invalidDoorCount => l10n.gatesInvalidDoorCount,
  GatesFailureKind.doorsInUse => l10n.gatesDoorsInUse,
  GatesFailureKind.notFound => l10n.gatesNotFound,
  GatesFailureKind.notEntryGate => l10n.gatesTestOpenExit,
  GatesFailureKind.gateNotWired => l10n.gatesTestOpenNotWired,
  GatesFailureKind.testOpenPending => l10n.gatesTestOpenPending,
  GatesFailureKind.serverUnreachable => l10n.errorServerUnreachable,
  GatesFailureKind.unexpected => l10n.gatesUnexpected,
};

String directionText(AppLocalizations l10n, GateDirection direction) => switch (direction) {
  GateDirection.entry => l10n.gateDirectionEntry,
  GateDirection.exit => l10n.gateDirectionExit,
};

/// "وحدة 1 · باب 2", or "مش متوصلة".
String wiringText(AppLocalizations l10n, String? controller, int? door) =>
    controller != null && door != null ? l10n.gatesWiring(controller, door) : l10n.gatesNotWired;

String gateStatusText(AppLocalizations l10n, GateStatus status) => switch (status) {
  GateStatus.online => l10n.gateOnline,
  GateStatus.offline => l10n.gateOffline,
  GateStatus.neverSeen => l10n.gateNeverSeen,
  GateStatus.disabled => l10n.gateDisabled,
  GateStatus.exit => l10n.gateStatusExit,
};

/// Under a gate's name: its last scan, or why there is no news of it.
/// [serverNow] is the server's clock (ages), [now] this PC's (dates).
String gateNote(AppLocalizations l10n, AdminGate gate, DateTime serverNow, DateTime now) {
  if (gate.status == GateStatus.exit) return l10n.gateExitNote;
  if (gate.status == GateStatus.offline) {
    return l10n.gateOfflineSince(
      gate.lastSeenAt == null ? '—' : dayTime(l10n, gate.lastSeenAt!, now),
    );
  }
  if (gate.status == GateStatus.neverSeen) return l10n.gateNeverSeenNote;
  final at = gate.lastScanAt;
  if (at == null) return l10n.gateNoScans;
  final age = serverNow.difference(at);
  if (age < const Duration(minutes: 1)) {
    return l10n.gateLastScanSeconds(age.inSeconds < 1 ? 1 : age.inSeconds);
  }
  if (age < const Duration(hours: 1)) return l10n.gateLastScanMinutes(age.inMinutes);
  return l10n.gateLastScanAt(dayTime(l10n, at, now));
}

String controllerStatusText(AppLocalizations l10n, AdminController controller, DateTime now) =>
    switch (controller.status) {
      ControllerStatus.online => l10n.controllerOnline,
      ControllerStatus.offline => l10n.controllerOfflineSince(
        controller.lastSeenAt == null ? '—' : dayTime(l10n, controller.lastSeenAt!, now),
      ),
      ControllerStatus.neverSeen => l10n.controllerNeverSeen,
      ControllerStatus.noEntryGate => l10n.controllerNoEntryGate,
    };

/// The panel's line for a test open, or null when there is none to show.
String? testOpenText(AppLocalizations l10n, TestOpenProgress progress) {
  final seconds = progress.openSeconds ?? 0;
  return switch (progress.phase) {
    TestOpenPhase.sending => l10n.gatesTestSending,
    TestOpenPhase.waiting => l10n.gatesTestWaiting(seconds),
    TestOpenPhase.opened => l10n.gatesTestOpened(seconds),
    TestOpenPhase.failed => l10n.gatesTestFailed(progress.detail ?? '—'),
    TestOpenPhase.noAnswer => l10n.gatesTestNoAnswer,
  };
}

/// A test open's result in the actions log, or null for none (an older row).
String? testOpenResultText(AppLocalizations l10n, String? key) => switch (key) {
  'waiting' => l10n.testOpenResultWaiting,
  'opened' => l10n.testOpenResultOpened,
  'failed' => l10n.testOpenResultFailed,
  'no_answer' => l10n.testOpenResultNoAnswer,
  _ => null,
};

int? _intOf(Object? value) => value is num ? value.toInt() : null;

/// A gate's or controller's settings_change for the actions log, as
/// `settingsChangeText` gives a ticket type's. Null for another subject.
({String title, List<String> lines})? gateChangeText(AppLocalizations l10n, SettingsChange change) {
  final name = change.name ?? '—';
  final c = change.changes;

  String text(Object? value) => value is String && value.isNotEmpty ? value : '—';
  String number(Object? value) => switch (_intOf(value)) {
    final n? => '$n',
    null => '—',
  };
  String seconds(Object? value) => switch (_intOf(value)) {
    final n? => l10n.gatesSecondsShort(n),
    null => '—',
  };
  String direction(Object? value) => switch (value) {
    'entry' => l10n.gateDirectionEntry,
    'exit' => l10n.gateDirectionExit,
    _ => '—',
  };
  String controller(Object? value) =>
      value is String && value.isNotEmpty ? value : l10n.gatesNotWired;
  String enabled(Object? value) => switch (value) {
    true => l10n.gatesStateOn,
    false => l10n.gateDisabled,
    _ => '—',
  };
  String doors(Object? value) => switch (_intOf(value)) {
    final n? => l10n.controllerDoors(n),
    null => '—',
  };

  if (change.subject == 'gate') {
    if (change.created) {
      final door = _intOf(c['door_number']?.to);
      final wired = c['controller']?.to;
      return (
        title: l10n.changeNewGate(name),
        lines: [
          [
            direction(c['direction']?.to),
            wiringText(l10n, wired is String ? wired : null, door),
            if (_intOf(c['open_seconds']?.to) case final n?) l10n.gatesOpenFor(n),
            if (c['reader']?.to case final String reader when reader.isNotEmpty) reader,
            if (c['enabled']?.to == false) l10n.gateDisabled,
          ].join(' · '),
        ],
      );
    }
    return (
      title: l10n.changeGateName(name),
      lines: [
        if (c['name'] case final v?) l10n.changeField(l10n.gatesName, text(v.from), text(v.to)),
        if (c['direction'] case final v?)
          l10n.changeField(l10n.gatesDirectionLabel, direction(v.from), direction(v.to)),
        if (c['controller'] case final v?)
          l10n.changeField(l10n.gatesController, controller(v.from), controller(v.to)),
        if (c['door_number'] case final v?)
          l10n.changeField(l10n.gatesDoor, number(v.from), number(v.to)),
        if (c['open_seconds'] case final v?)
          l10n.changeField(l10n.gatesOpenSeconds, seconds(v.from), seconds(v.to)),
        if (c['reader'] case final v?) l10n.changeField(l10n.gatesReader, text(v.from), text(v.to)),
        if (c['enabled'] case final v?)
          l10n.changeField(l10n.gatesEnabledLabel, enabled(v.from), enabled(v.to)),
      ],
    );
  }

  if (change.subject == 'controller') {
    if (change.created) {
      return (
        title: l10n.changeNewController(name),
        lines: [
          [
            if (c['model']?.to case final String model when model.isNotEmpty) model,
            if (c['ip']?.to case final String ip when ip.isNotEmpty) '\u2066$ip\u2069',
            if (_intOf(c['port']?.to) case final port?) '${l10n.controllerPort} $port',
            doors(c['door_count']?.to),
          ].join(' · '),
        ],
      );
    }
    String ip(Object? value) => value is String && value.isNotEmpty ? '\u2066$value\u2069' : '—';
    return (
      title: l10n.changeControllerName(name),
      lines: [
        if (c['name'] case final v?) l10n.changeField(l10n.gatesName, text(v.from), text(v.to)),
        if (c['model'] case final v?)
          l10n.changeField(l10n.controllerModel, text(v.from), text(v.to)),
        if (c['ip'] case final v?) l10n.changeField(l10n.controllerIp, ip(v.from), ip(v.to)),
        if (c['port'] case final v?)
          l10n.changeField(l10n.controllerPort, number(v.from), number(v.to)),
        if (c['door_count'] case final v?)
          l10n.changeField(l10n.controllerDoorsLabel, doors(v.from), doors(v.to)),
      ],
    );
  }
  return null;
}
