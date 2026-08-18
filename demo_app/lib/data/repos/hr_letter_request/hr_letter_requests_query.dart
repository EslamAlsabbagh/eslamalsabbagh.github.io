import 'package:equatable/equatable.dart';

/// Which of the three HR-letter lists to page through.
///
/// [wire] values are the `p_source` argument of `list_user_hr_letter_requests`.
///
/// There are three of these but only two `HrLetterRequestSourceType` values,
/// and that is deliberate. The source type is a ROUTING concept — which page the
/// user opened — and both entry pages
/// (user_hr_letter_requests_page.dart / team_hr_letter_requests_page.dart) are
/// built around it. The Actionable/Processed split inside the team page used to
/// be a client-side predicate over one whole-table fetch; server-side it is two
/// different queries, so it needs its own value here.
enum HrLetterRequestScope {
  /// The caller's own requests, every status.
  my('my'),

  /// The HR queue: pending or acknowledged, excluding the caller's own rows.
  /// Restricted to the `hr` group server-side, which the old whole-table read
  /// did not do — see the FIX note in the migration.
  team('team'),

  /// Completed, declined or cancelled. Also `hr`-only.
  processed('processed');

  const HrLetterRequestScope(this.wire);

  final String wire;
}

/// Sortable columns, as understood by the server.
///
/// [wire] values MUST match the whitelist in `list_user_hr_letter_requests` —
/// the RPC rejects anything else with SQLSTATE 22023 rather than interpolating
/// it, so a mismatch surfaces as a hard error, not a silent wrong sort. The rpc
/// test asserts every value here appears in the migration.
///
/// Exactly the two the sort dropdown offers today
/// (user_hr_letter_requests_content.dart:410-411).
enum HrLetterRequestSortKey {
  createdAt('created_at'),
  status('status');

  const HrLetterRequestSortKey(this.wire);

  final String wire;
}

/// Everything that decides *which* rows a page contains — i.e. everything
/// except the offset and limit.
///
/// Value equality is load-bearing: the bloc compares an incoming query against
/// the current one to decide whether a filter change actually needs a refetch,
/// which is what stops a rebuild from re-issuing an identical request.
class HrLetterRequestsQuery extends Equatable {
  const HrLetterRequestsQuery({
    required this.scope,
    this.search = '',
    this.status = 'all',
    this.month,
    this.sortKey = HrLetterRequestSortKey.createdAt,
    this.sortAscending = false,
    this.locale = 'en',
  });

  final HrLetterRequestScope scope;

  /// Matched against the employee's name (both languages), their short code,
  /// their national ID and the letter purpose.
  final String search;

  /// `'all'` means no status filter. Otherwise one of
  /// `pending | acknowledged | completed | declined | cancelled`.
  final String status;

  /// Any day inside the target month; `null` means no month filter. Compared
  /// against `created_at` — HR letters have no request-date column, and that is
  /// what the month picker has always filtered on.
  final DateTime? month;

  final HrLetterRequestSortKey sortKey;
  final bool sortAscending;

  /// `'ar'` or `'en'`. Accepted for symmetry with the other list RPCs; HR-letter
  /// search matches both name columns regardless, mirroring the Dart it
  /// replaces.
  final String locale;

  HrLetterRequestsQuery copyWith({
    HrLetterRequestScope? scope,
    String? search,
    String? status,
    DateTime? month,
    bool clearMonth = false,
    HrLetterRequestSortKey? sortKey,
    bool? sortAscending,
    String? locale,
  }) {
    return HrLetterRequestsQuery(
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
