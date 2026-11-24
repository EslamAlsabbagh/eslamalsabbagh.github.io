import 'dart:async';

import '../../../demo/backend.dart';

import '../../../core/server_call.dart';
import 'settings_models.dart';

enum SettingsFailureKind {
  notAllowed,

  /// A setting the server refused; [SettingsFailure.field] names it.
  invalidSetting,
  invalidName,
  nameTaken,
  invalidIp,
  invalidPort,
  invalidPaperWidth,

  /// An active counter needs a home gate (ADR-0015).
  homeGateRequired,
  homeGateNotEntry,
  gateNotFound,

  /// A counter with an open shift can't be switched off.
  counterHasOpenShift,

  /// The counter was there when the page read it, and isn't now.
  notFound,

  /// A venue day start or closing time that would leave the daily peak hours
  /// outside opening hours (ADR-0038); [SettingsFailure.field] names which.
  peakHoursOutsideOpening,
  serverUnreachable,
  unexpected,
}

class SettingsFailure implements Exception {
  const SettingsFailure(this.kind, {this.field});

  final SettingsFailureKind kind;

  /// The setting's column name, for [SettingsFailureKind.invalidSetting].
  final String? field;

  @override
  String toString() => 'SettingsFailure($kind, $field)';
}

/// The Settings page's data (4.8). Admins only: settings change through
/// `save_settings` and counters through `save_counter`, both logged (ADR-0037).
class SettingsRepository {
  SettingsRepository(this._client, {this._timeout = serverCallTimeout});

  final DemoBackend _client;

  /// How long a call waits for an answer ([serverCallTimeout], ADR-0039).
  final Duration _timeout;

  /// Throws [SettingsFailure].
  Future<SettingsOverview> overview() => _guard(
    () async =>
        SettingsOverview.fromJson(await _client.rpc<Map<String, dynamic>>('settings_overview')),
  );

  /// Saves [changes] (only the keys that changed, `settingsChanges`). Returns
  /// the page as it is now. Throws [SettingsFailure].
  Future<SettingsOverview> saveSettings(Map<String, Object> changes) => _guard(
    () async => SettingsOverview.fromJson(
      await _client.rpc<Map<String, dynamic>>('save_settings', params: {'p_changes': changes}),
    ),
  );

  /// Adds a counter ([id] null) or changes one. Returns its id. Throws
  /// [SettingsFailure].
  Future<String> saveCounter({String? id, required CounterDraft draft}) => _guard(() async {
    final row = await _client.rpc<Map<String, dynamic>>(
      'save_counter',
      params: {
        'p_id': id,
        'p_name': draft.name,
        'p_printer_ip': draft.printerIp,
        'p_printer_port': draft.printerPort,
        'p_paper_width_mm': draft.paperWidthMm,
        'p_entry_gate_id': draft.entryGateId,
        'p_active': draft.active,
      },
    );
    return row['id'] as String;
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on Exception catch (e) {
      throw failureFor(e);
    } on TypeError {
      // A field of the wrong type in the answer.
      throw const SettingsFailure(SettingsFailureKind.unexpected);
    }
  }

  static SettingsFailure failureFor(Exception error) => switch (error) {
    PostgrestException(code: 'P0001', message: 'invalid_setting', :final details) =>
      SettingsFailure(
        SettingsFailureKind.invalidSetting,
        field: details is String ? details : null,
      ),
    PostgrestException(code: 'P0001', message: 'peak_hours_outside_opening', :final details) =>
      SettingsFailure(
        SettingsFailureKind.peakHoursOutsideOpening,
        field: details is String ? details : 'venue_day_starts_at',
      ),
    PostgrestException(code: 'P0001', :final message) => SettingsFailure(switch (message) {
      'not_allowed' || 'not_staff' => SettingsFailureKind.notAllowed,
      'invalid_name' => SettingsFailureKind.invalidName,
      'name_taken' => SettingsFailureKind.nameTaken,
      'invalid_ip' => SettingsFailureKind.invalidIp,
      'invalid_port' => SettingsFailureKind.invalidPort,
      'invalid_paper_width' => SettingsFailureKind.invalidPaperWidth,
      'home_gate_required' => SettingsFailureKind.homeGateRequired,
      'home_gate_not_entry' => SettingsFailureKind.homeGateNotEntry,
      'gate_not_found' => SettingsFailureKind.gateNotFound,
      'counter_has_open_shift' => SettingsFailureKind.counterHasOpenShift,
      'not_found' => SettingsFailureKind.notFound,
      // unknown_setting, invalid_input: the app sent something it shouldn't.
      _ => SettingsFailureKind.unexpected,
    }),
    PostgrestException(code: '42501') => const SettingsFailure(SettingsFailureKind.notAllowed),
    PostgrestException() ||
    FormatException() => const SettingsFailure(SettingsFailureKind.unexpected),
    // No answer within the timeout: the server may still have done it.
    TimeoutException() => const SettingsFailure(SettingsFailureKind.serverUnreachable),
    AuthRetryableFetchException() => const SettingsFailure(SettingsFailureKind.serverUnreachable),
    AuthException() => const SettingsFailure(SettingsFailureKind.unexpected),
    _ => const SettingsFailure(SettingsFailureKind.serverUnreachable),
  };
}
