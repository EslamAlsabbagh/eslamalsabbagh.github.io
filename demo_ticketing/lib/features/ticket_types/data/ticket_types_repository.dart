import 'dart:async';

import '../../../demo/backend.dart';

import '../../../core/server_call.dart';
import '../../sell/data/peak_schedule.dart';
import 'admin_ticket_type.dart';
import 'peak_state.dart';

enum TicketTypesFailureKind {
  notAllowed,
  invalidName,
  invalidPrice,
  invalidEntries,
  invalidValidityHours,
  nameArTaken,
  nameEnTaken,

  /// `save_peak_times`: a day outside 1..7.
  invalidWeekdays,

  /// `save_peak_times`: one end of the daily range, or the start not before
  /// the end.
  invalidPeakHours,

  /// `save_peak_times`: the range ends after the closing time (ADR-0038).
  peakHoursAfterClosing,

  /// The type was there when the page read it, and isn't now.
  notFound,
  serverUnreachable,
  unexpected,
}

class TicketTypesFailure implements Exception {
  const TicketTypesFailure(this.kind);

  final TicketTypesFailureKind kind;

  @override
  String toString() => 'TicketTypesFailure($kind)';
}

enum MoveDirection {
  up('up'),
  down('down');

  const MoveDirection(this.key);

  final String key;
}

/// The Ticket types page's data (4.5). Every staff role reads the table; only
/// the two admin functions write it, and `save_ticket_type` logs each change.
class TicketTypesRepository {
  TicketTypesRepository(this._client, {this._timeout = serverCallTimeout});

  final DemoBackend _client;

  /// How long a call waits for an answer ([serverCallTimeout], ADR-0039).
  final Duration _timeout;

  /// Every type, on sale or not, in the sell screen's order. Throws
  /// [TicketTypesFailure].
  Future<List<AdminTicketType>> list() => _guard(() async {
    final rows = await _client
        .from('ticket_types')
        .select(
          'id, name_ar, name_en, price_piastres, entries_allowed, validity_kind, '
          'validity_hours, active, sort_order, sale_period',
        )
        // order() sorts descending unless told otherwise.
        .order('sort_order', ascending: true)
        .order('name_en', ascending: true);
    return [for (final row in rows) AdminTicketType.fromRow(row)];
  });

  /// Adds a type ([id] null) or changes one. Returns the saved row. Throws
  /// [TicketTypesFailure].
  Future<AdminTicketType> save({String? id, required TicketTypeDraft draft}) => _guard(() async {
    final result = await _client.rpc<Map<String, dynamic>>(
      'save_ticket_type',
      params: {
        'p_id': id,
        'p_name_ar': draft.nameAr,
        'p_name_en': draft.nameEn,
        'p_price_piastres': draft.pricePiastres,
        'p_entries_allowed': draft.entriesAllowed,
        'p_validity_kind': validityKey(draft.validity),
        'p_validity_hours': draft.validity == TicketValidity.hoursFromSale
            ? draft.validityHours
            : null,
        'p_active': draft.active,
        'p_sale_period': draft.salePeriod.key,
      },
    );
    return AdminTicketType.fromRow(result);
  });

  /// One place up or down on the sell screen. Throws [TicketTypesFailure].
  Future<void> move(String id, MoveDirection direction) => _guard(
    () => _client.rpc<void>('move_ticket_type', params: {'p_id': id, 'p_direction': direction.key}),
  );

  /// Peak now, the schedule and today's switch (ADR-0033). Any staff.
  Future<PeakState> peakState() =>
      _guard(() async => PeakState.fromJson(await _client.rpc<Map<String, dynamic>>('peak_state')));

  /// The peak schedule (admin). [fromSeconds] and [toSeconds] both null for
  /// no daily range.
  Future<PeakState> savePeakTimes({required Set<int> weekdays, int? fromSeconds, int? toSeconds}) =>
      _guard(
        () async => PeakState.fromJson(
          await _client.rpc<Map<String, dynamic>>(
            'save_peak_times',
            params: {
              'p_weekdays': (weekdays.toList()..sort()),
              'p_from': PeakSchedule.timeText(fromSeconds),
              'p_to': PeakSchedule.timeText(toSeconds),
            },
          ),
        ),
      );

  /// Today's switch (supervisor, admin).
  Future<PeakState> setPeakOverride(PeakMode mode) => _guard(
    () async => PeakState.fromJson(
      await _client.rpc<Map<String, dynamic>>('set_peak_override', params: {'p_mode': mode.key}),
    ),
  );

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call().timeout(_timeout);
    } on Exception catch (e) {
      throw TicketTypesFailure(failureKindFor(e));
    } on TypeError {
      // A field of the wrong type in the answer.
      throw const TicketTypesFailure(TicketTypesFailureKind.unexpected);
    }
  }

  static TicketTypesFailureKind failureKindFor(Exception error) => switch (error) {
    PostgrestException(code: 'P0001', :final message) => switch (message) {
      'not_allowed' || 'not_staff' => TicketTypesFailureKind.notAllowed,
      'invalid_name' => TicketTypesFailureKind.invalidName,
      'invalid_price' => TicketTypesFailureKind.invalidPrice,
      'invalid_entries' => TicketTypesFailureKind.invalidEntries,
      'invalid_validity_hours' => TicketTypesFailureKind.invalidValidityHours,
      'name_ar_taken' => TicketTypesFailureKind.nameArTaken,
      'name_en_taken' => TicketTypesFailureKind.nameEnTaken,
      'not_found' => TicketTypesFailureKind.notFound,
      'invalid_weekdays' => TicketTypesFailureKind.invalidWeekdays,
      'invalid_hours' => TicketTypesFailureKind.invalidPeakHours,
      'peak_hours_after_closing' => TicketTypesFailureKind.peakHoursAfterClosing,
      _ => TicketTypesFailureKind.unexpected,
    },
    // A direct write the grants refuse.
    PostgrestException(code: '42501') => TicketTypesFailureKind.notAllowed,
    PostgrestException() || FormatException() => TicketTypesFailureKind.unexpected,
    // No answer within the timeout: the server may still have done it.
    TimeoutException() => TicketTypesFailureKind.serverUnreachable,
    AuthRetryableFetchException() => TicketTypesFailureKind.serverUnreachable,
    AuthException() => TicketTypesFailureKind.unexpected,
    _ => TicketTypesFailureKind.serverUnreachable,
  };
}
