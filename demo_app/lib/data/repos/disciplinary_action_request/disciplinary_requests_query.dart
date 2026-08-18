import 'package:equatable/equatable.dart';

/// Which of the four disciplinary lists to page through.
///
/// [wire] values are the `p_source` argument of
/// `list_user_disciplinary_requests`.
///
/// Four, not three. The UI's two processed tabs both loaded `processedRequests`
/// and then filtered by entity type client-side, so every processed page was
/// silently shrunk by the filter. Splitting them server-side removes that.
enum DisciplinaryRequestScope {
  /// Actions raised by the caller or against them, plus investigations they
  /// requested or are investigated in.
  ///
  /// Note these are HR/manager-created, not employee-submitted: the subject
  /// acknowledges an action, they do not request one. "My requests" therefore
  /// means "raised BY me or AGAINST me".
  my('my'),

  /// The caller's approval queue across both tables — the N+2 stage plus the
  /// HR, Legal and Top-Management queues they belong to. Group membership is
  /// decided server-side, not here.
  team('team'),

  /// Disciplinary actions the caller has already acted on. Investigations are
  /// excluded server-side.
  processedDisciplinary('processed_disciplinary'),

  /// Investigations the caller has already acted on. Disciplinary actions are
  /// excluded server-side.
  processedInvestigations('processed_investigations');

  const DisciplinaryRequestScope(this.wire);

  final String wire;
}

/// Sortable columns, as understood by the server.
///
/// [wire] values MUST match the whitelist in
/// `list_user_disciplinary_requests` — the RPC rejects anything else with
/// SQLSTATE 22023. The rpc test asserts every value here appears in the
/// migration.
///
/// There is deliberately no `employee_name`: the sort dropdown does not offer
/// it, and the two branches disagree on cardinality — an investigation has an
/// ARRAY of investigated employees, so "the employee name" is not one value.
enum DisciplinaryRequestSortKey {
  createdAt('created_at'),
  status('status'),
  violationDate('violation_date'),

  /// Disciplinary rows sort on their real `action_type`; investigations project
  /// the literal `'investigation'`, which groups them together deterministically.
  /// The old comparator returned -1/+1 for mixed pairs, which is not a
  /// consistent ordering — see the FIX note in the migration.
  actionType('action_type');

  const DisciplinaryRequestSortKey(this.wire);

  final String wire;
}

/// Everything that decides *which* rows a page contains — i.e. everything
/// except the offset and limit.
///
/// Value equality is load-bearing: the bloc compares an incoming query against
/// the current one to decide whether a filter change actually needs a refetch.
class DisciplinaryRequestsQuery extends Equatable {
  const DisciplinaryRequestsQuery({
    required this.scope,
    this.search = '',
    this.status = 'all',
    this.month,
    this.sortKey = DisciplinaryRequestSortKey.createdAt,
    this.sortAscending = false,
    this.locale = 'en',
  });

  final DisciplinaryRequestScope scope;

  /// Matched against the incident description, the action type, the investigated
  /// employees' names (both languages) and their short codes.
  ///
  /// Note the asymmetry the server reproduces: codes match by PREFIX and only
  /// when the query parses as an integer, while text matches by substring. The
  /// relevance-bucket sort that used to accompany this is gone.
  final String search;

  /// `'all'` means no status filter. `'cancelled'` reads the disciplinary
  /// table's boolean `cancelled` column and the investigation table's
  /// `status = 'cancelled'` — they express it differently.
  final String status;

  /// Any day inside the target month; `null` means no month filter. Compared
  /// against `created_at` on both branches, which is what the month picker has
  /// always filtered on.
  final DateTime? month;

  final DisciplinaryRequestSortKey sortKey;
  final bool sortAscending;

  /// `'ar'` or `'en'`. Accepted for symmetry with the other list RPCs;
  /// disciplinary search matches both name columns regardless.
  final String locale;

  DisciplinaryRequestsQuery copyWith({
    DisciplinaryRequestScope? scope,
    String? search,
    String? status,
    DateTime? month,
    bool clearMonth = false,
    DisciplinaryRequestSortKey? sortKey,
    bool? sortAscending,
    String? locale,
  }) {
    return DisciplinaryRequestsQuery(
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
