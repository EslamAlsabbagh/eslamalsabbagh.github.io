import 'dart:async';

import 'package:intl/intl.dart' show DateFormat;
import '../../../demo/backend.dart';

import 'sales_report_models.dart';

enum ReportsFailureKind {
  notAllowed,
  invalidRange,

  /// Another report is running: one at a time, so scans come first (ADR-0032).
  busy,

  /// The report reached its time limit (120 s, `57014`).
  tooSlow,
  serverUnreachable,
  unexpected,
}

class ReportsFailure implements Exception {
  const ReportsFailure(this.kind);

  final ReportsFailureKind kind;

  @override
  String toString() => 'ReportsFailure($kind)';
}

/// The Reports page's data (4.4): `sales_report`, one call for every grouping.
class ReportsRepository {
  ReportsRepository(this._client, {this._timeout = const Duration(seconds: 130)});

  final DemoBackend _client;

  /// How long `sales_report` waits for an answer (ADR-0039). Longer than
  /// `serverCallTimeout`: the function's own `statement_timeout` is 120 s
  /// (ADR-0032), and its "took too long" answer must arrive first.
  final Duration _timeout;

  static final _date = DateFormat('yyyy-MM-dd');

  /// [from] and [to] (venue dates, both included) only with
  /// [ReportPeriod.range]. Throws [ReportsFailure].
  Future<SalesReport> load({required ReportPeriod period, DateTime? from, DateTime? to}) async {
    try {
      final result = await _client
          .rpc<Map<String, dynamic>>(
            'sales_report',
            params: {
              'p_period': period.key,
              if (period == ReportPeriod.range) ...{
                'p_from': from == null ? null : _date.format(from),
                'p_to': to == null ? null : _date.format(to),
              },
            },
          )
          .timeout(_timeout);
      return SalesReport.fromJson(result);
    } on Exception catch (e) {
      throw ReportsFailure(failureKindFor(e));
    } on TypeError {
      // A field of the wrong type in the answer.
      throw const ReportsFailure(ReportsFailureKind.unexpected);
    }
  }

  static ReportsFailureKind failureKindFor(Exception error) => switch (error) {
    PostgrestException(code: 'P0001', :final message) => switch (message) {
      'not_allowed' || 'not_staff' => ReportsFailureKind.notAllowed,
      'invalid_range' => ReportsFailureKind.invalidRange,
      'report_busy' => ReportsFailureKind.busy,
      _ => ReportsFailureKind.unexpected,
    },
    PostgrestException(code: '57014') => ReportsFailureKind.tooSlow,
    PostgrestException() || FormatException() => ReportsFailureKind.unexpected,
    // No answer within the timeout.
    TimeoutException() => ReportsFailureKind.serverUnreachable,
    AuthRetryableFetchException() => ReportsFailureKind.serverUnreachable,
    AuthException() => ReportsFailureKind.unexpected,
    _ => ReportsFailureKind.serverUnreachable,
  };
}
