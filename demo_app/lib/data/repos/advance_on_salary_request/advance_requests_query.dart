import 'package:equatable/equatable.dart';

/// Which of the eight advance-on-salary lists to page through.
///
/// [wire] values are the `p_source` argument of `list_user_advance_requests`.
///
/// Eight, because every tab was its own repo method with its own predicate —
/// including the two Finance-only tabs and the separate Settlement Review
/// screen. Leaving any of them on the whole-list read would leave it silently
/// truncated at PostgREST's max_rows.
enum AdvanceRequestScope {
  /// Requests the caller made or borrowed, plus ones their N+2 placed for a
  /// direct report.
  my('my'),

  /// The caller's approval queue: the N+2 stage, plus the HR and Finance
  /// queues if they are in those groups — decided server-side, not here.
  team('team'),

  /// Requests the caller has already acted on.
  processed('processed'),

  /// Finance: approved advances still being repaid.
  unsettled('unsettled'),

  /// Finance: approved advances fully repaid or manually settled.
  settled('settled'),

  /// The borrower's own "confirm the finance edit" queue.
  employeeConfirmation('employee_confirmation'),

  /// Finance: requests whose borrower has answered, awaiting acknowledgment.
  financeAcknowledgment('finance_acknowledgment'),

  /// The Settlement Review screen. Finance-only, which the old
  /// `get_settlement_review_requests()` never enforced.
  settlementReview('settlement_review');

  const AdvanceRequestScope(this.wire);

  final String wire;
}

/// Sortable columns, as understood by the server.
///
/// [wire] values MUST match the whitelist in `list_user_advance_requests` — the
/// RPC rejects anything else with SQLSTATE 22023 rather than interpolating it.
/// The rpc test asserts every value here appears in the migration.
enum AdvanceRequestSortKey {
  createdAt('created_at'),
  amount('amount'),
  status('status'),

  /// `effectivePeriodInMonths` — the finance-edited period when there is one.
  period('period'),

  /// Resolves server-side to the Arabic or English borrower name based on the
  /// query's [AdvanceRequestsQuery.locale].
  employeeName('employee_name'),

  // The three below are not offered by the advance-list sort dropdown.
  //
  // Note what they are NOT: an attempt to preserve a per-tab default order.
  // Each repo method did carry its own ORDER BY, but the content widget
  // re-sorted the whole list afterwards and always won, so every tab has always
  // displayed `created_at DESC`. Seeding these per tab reversed the Actionable
  // list. They stay because they are valid server sorts and one of them is used.
  /// `COALESCE(updated_payment_end_date, payment_end_date)`. Available, unused.
  paymentEndDate('payment_end_date'),

  /// Available, unused.
  employeeConfirmationDate('employee_confirmation_date'),

  /// The Settlement Review screen's order. That screen renders its rows with no
  /// client-side sort, so unlike the advance tabs its server ORDER BY really is
  /// what users see — see SettlementReviewBloc._loadPage.
  settlementReadyDate('settlement_ready_date');

  const AdvanceRequestSortKey(this.wire);

  final String wire;
}

/// Everything that decides *which* rows a page contains — i.e. everything
/// except the offset and limit.
///
/// Value equality is load-bearing: the bloc compares an incoming query against
/// the current one to decide whether a filter change actually needs a refetch,
/// which is what stops a rebuild from re-issuing an identical request.
class AdvanceRequestsQuery extends Equatable {
  const AdvanceRequestsQuery({
    required this.scope,
    this.search = '',
    this.status = 'all',
    this.month,
    this.sortKey = AdvanceRequestSortKey.createdAt,
    this.sortAscending = false,
    this.locale = 'en',
  });

  final AdvanceRequestScope scope;

  /// Matched against the borrower's name (both languages), their short code and
  /// the amount.
  ///
  /// Substring only. The old client-side matcher was fuzzy (Levenshtein
  /// similarity), searched the localized amount-in-letters, and AND-ed
  /// whitespace-separated terms; none of that survives server paging. See the
  /// migration header.
  final String search;

  /// `'all'` means no status filter. Beyond the real statuses
  /// (`pending | approved | declined | cancelled`) the dropdown offers
  /// `pending_employee_confirmation`, which is not a status in the table at all
  /// — the RPC translates it.
  final String status;

  /// Any day inside the target month; `null` means no month filter. Compared
  /// against `created_at`, which is what the month picker has always filtered
  /// on.
  final DateTime? month;

  final AdvanceRequestSortKey sortKey;
  final bool sortAscending;

  /// `'ar'` or `'en'`. Drives which name column the `employee_name` sort uses.
  final String locale;

  AdvanceRequestsQuery copyWith({
    AdvanceRequestScope? scope,
    String? search,
    String? status,
    DateTime? month,
    bool clearMonth = false,
    AdvanceRequestSortKey? sortKey,
    bool? sortAscending,
    String? locale,
  }) {
    return AdvanceRequestsQuery(
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
