import 'package:equatable/equatable.dart';

/// Which of the three overtime lists to page through.
///
/// [wire] values are the `p_source` argument of `list_user_overtime_requests`.
enum OvertimeRequestScope {
  /// The caller's own requests.
  my('my'),

  /// Requests awaiting the caller's approval (plus the HR queue, if the caller
  /// is in the `hr` group — decided server-side, not here).
  team('team'),

  /// Requests the caller has already acted on.
  processed('processed');

  const OvertimeRequestScope(this.wire);

  final String wire;
}

/// Sortable columns, as understood by the server.
///
/// [wire] values MUST match the whitelist in `list_user_overtime_requests` — the
/// RPC rejects anything else with SQLSTATE 22023 rather than interpolating it,
/// so a mismatch here surfaces as a hard error, not a silent wrong sort.
enum OvertimeRequestSortKey {
  createdAt('created_at'),
  date('date'),
  timeFrom('time_from'),
  timeTo('time_to'),
  reason('reason'),

  /// The column that *displays* `getLocalizedOvertimeType`. Its old in-memory
  /// comparator sorted on `reason` instead — see the FIX note in the migration.
  overtimeType('overtime_type'),

  status('status'),
  currentApprover('current_approver'),
  userId('user_id'),

  /// Resolves server-side to the Arabic or English name column based on the
  /// query's `locale`, matching what the table actually displays.
  employeeName('employee_name');

  const OvertimeRequestSortKey(this.wire);

  final String wire;
}

/// Everything that decides *which* rows a page contains — i.e. everything
/// except the offset and limit.
///
/// Value equality is load-bearing: `_OvertimeRequestsAsyncSource` compares the
/// incoming query against the current one to decide whether a filter change
/// actually needs a refetch, which is what stops a rebuild from re-issuing an
/// identical request.
class OvertimeRequestsQuery extends Equatable {
  const OvertimeRequestsQuery({
    required this.scope,
    this.search = '',
    this.status = 'all',
    this.month,
    this.sortKey = OvertimeRequestSortKey.createdAt,
    this.sortAscending = false,
    this.locale = 'en',
  });

  final OvertimeRequestScope scope;

  /// Matched against the employee's localized name and their user code.
  final String search;

  /// `'all'` means no status filter.
  final String status;

  /// Any day inside the target month; `null` means no month filter. Compared
  /// against the request's `date`, which is what the month picker has always
  /// filtered on.
  final DateTime? month;

  final OvertimeRequestSortKey sortKey;
  final bool sortAscending;

  /// `'ar'` or `'en'`. Drives which name column is searched and sorted.
  final String locale;

  OvertimeRequestsQuery copyWith({
    OvertimeRequestScope? scope,
    String? search,
    String? status,
    DateTime? month,
    bool clearMonth = false,
    OvertimeRequestSortKey? sortKey,
    bool? sortAscending,
    String? locale,
  }) {
    return OvertimeRequestsQuery(
      scope: scope ?? this.scope,
      search: search ?? this.search,
      status: status ?? this.status,
      month: clearMonth ? null : (month ?? this.month),
      sortKey: sortKey ?? this.sortKey,
      sortAscending: sortAscending ?? this.sortAscending,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [scope, search, status, month, sortKey, sortAscending, locale];
}
