import 'package:equatable/equatable.dart';

/// The caller's open shift.
class OpenShift extends Equatable {
  const OpenShift({
    required this.id,
    required this.number,
    required this.counterId,
    required this.counterName,
    required this.openedAt,
  });

  final String id;
  final int number;
  final String counterId;
  final String counterName;
  final DateTime openedAt;

  /// A `shifts` row with `counter:counters(name)` embedded.
  factory OpenShift.fromRow(Map<String, dynamic> row) => OpenShift(
        id: row['id'] as String,
        number: row['number'] as int,
        counterId: row['counter_id'] as String,
        counterName: (row['counter'] as Map<String, dynamic>)['name'] as String,
        openedAt: DateTime.parse(row['opened_at'] as String).toLocal(),
      );

  /// What `open_shift` returns.
  factory OpenShift.fromOpenShiftResult(Map<String, dynamic> result) => OpenShift(
        id: result['shift_id'] as String,
        number: result['shift_number'] as int,
        counterId: result['counter_id'] as String,
        counterName: result['counter_name'] as String,
        openedAt: DateTime.parse(result['opened_at'] as String).toLocal(),
      );

  /// What [fromOpenShiftResult] reads back: the copy for a start with the
  /// server down.
  Map<String, Object> toJson() => {
        'shift_id': id,
        'shift_number': number,
        'counter_id': counterId,
        'counter_name': counterName,
        'opened_at': openedAt.toUtc().toIso8601String(),
      };

  @override
  List<Object?> get props => [id, number, counterId, counterName, openedAt];
}

/// The counter this PC sits at (`counters` row; staff can read it).
class CounterInfo extends Equatable {
  const CounterInfo({
    required this.id,
    required this.name,
    required this.active,
    required this.printerHost,
    required this.printerPort,
    required this.paperWidthMm,
    required this.hasHomeGate,
    this.homeGateName,
  });

  final String id;
  final String name;
  final bool active;

  /// Null when no printer is set for the counter.
  final String? printerHost;
  final int printerPort;
  final int paperWidthMm;

  /// `open_shift` refuses a counter without one (`counter_no_home_gate`).
  final bool hasHomeGate;

  /// The home gate's name, for the test page's sample ticket.
  final String? homeGateName;

  factory CounterInfo.fromRow(Map<String, dynamic> row) => CounterInfo(
        id: row['id'] as String,
        name: row['name'] as String,
        active: row['active'] as bool,
        printerHost: _host(row['printer_ip'] as String?),
        printerPort: row['printer_port'] as int,
        paperWidthMm: row['paper_width_mm'] as int,
        hasHomeGate: row['entry_gate_id'] != null,
        homeGateName: (row['entry_gate'] as Map<String, dynamic>?)?['name'] as String?,
      );

  /// What [fromRow] reads back: the copy kept for offline selling.
  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'active': active,
        'printer_ip': printerHost,
        'printer_port': printerPort,
        'paper_width_mm': paperWidthMm,
        // Only whether there is one matters here.
        'entry_gate_id': hasHomeGate ? 'set' : null,
        'entry_gate': homeGateName == null ? null : {'name': homeGateName},
      };

  /// `inet` may come back with a prefix length ("10.20.0.21/32").
  static String? _host(String? inet) => inet?.split('/').first;

  @override
  List<Object?> get props =>
      [id, name, active, printerHost, printerPort, paperWidthMm, hasHomeGate, homeGateName];
}

/// The `settings` the open shift screen reads.
class OpenShiftSettings extends Equatable {
  const OpenShiftSettings({required this.quickAmountsPiastres, required this.venueName});

  final List<int> quickAmountsPiastres;
  final String venueName;

  factory OpenShiftSettings.fromRow(Map<String, dynamic> row) => OpenShiftSettings(
        quickAmountsPiastres: (row['opening_float_quick_amounts_piastres'] as List).cast<int>(),
        venueName: row['venue_name'] as String,
      );

  @override
  List<Object?> get props => [quickAmountsPiastres, venueName];
}
