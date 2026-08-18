import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/advance_on_salary_request_model.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_requests_query.dart';

/// The wire contract for `list_user_advance_requests`.
///
/// Kept out of the repo so it can be tested without a Supabase client: the
/// repo's own job shrinks to "call `rpc`, hand the result here". Every rule that
/// has to agree with
/// `supabase/migrations/20260804150000_advance_requests_pagination.sql` lives in
/// this one place.
abstract final class AdvanceRequestsRpc {
  static const String listFunction = 'list_user_advance_requests';
  static const String monthsFunction = 'list_user_advance_request_months';

  /// All in-scope ids, for the Settlement Review "send all" action — which can
  /// no longer read them off the current page.
  static const String idsFunction = 'list_user_advance_request_ids';

  /// Postgres DATE params want 'yyyy-MM-dd'. The RPC reads only the month, so
  /// any day in it works; the 1st keeps the wire value self-explanatory.
  static String monthParam(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-01';

  /// Builds the `params` map.
  ///
  /// `null` is the RPC's "no filter" signal for search, status and month —
  /// sending `'all'` or `''` through would be treated as a literal value to
  /// match against.
  static Map<String, dynamic> params(AdvanceRequestsQuery query, {required int offset, required int limit}) {
    final search = query.search.trim();
    return {
      'p_source': query.scope.wire,
      'p_offset': offset,
      'p_limit': limit,
      'p_search': search.isEmpty ? null : search,
      'p_status': query.status == 'all' ? null : query.status,
      'p_month': query.month == null ? null : monthParam(query.month!),
      'p_sort_key': query.sortKey.wire,
      'p_sort_asc': query.sortAscending,
      'p_locale': query.locale,
    };
  }

  /// Turns the RPC result into a page.
  ///
  /// The function is `RETURNS TABLE`, so PostgREST sends a one-element array;
  /// a bare object is accepted too in case that ever changes.
  ///
  /// Each payload already carries its `scheduled_payments` and
  /// `unscheduled_payments`, so there is no post-pass here — the model's
  /// `fromJson` has always read both keys, they simply used to arrive from two
  /// extra queries instead of with the row.
  static PagedResult<AdvanceOnSalaryRequestModel> parse(dynamic response) {
    final Map<String, dynamic> row;
    if (response is List) {
      if (response.isEmpty) return const PagedResult.empty();
      row = Map<String, dynamic>.from(response.first as Map);
    } else if (response is Map) {
      row = Map<String, dynamic>.from(response);
    } else {
      throw FormatException('$listFunction returned an unexpected shape: ${response.runtimeType}');
    }

    final items =
        (row['rows'] as List? ?? const [])
            .map<AdvanceOnSalaryRequestModel>(
              (entry) => AdvanceOnSalaryRequestModel.fromJson(Map<String, dynamic>.from(entry as Map)),
            )
            .toList();

    return PagedResult(
      items: items,
      // The total across ALL pages. Present even when `rows` is empty, which is
      // why it is a separate column rather than a per-row window function.
      totalCount: (row['total_count'] as num?)?.toInt() ?? 0,
      hasActionable: row['has_actionable'] as bool? ?? false,
    );
  }

  /// Parses the `list_user_advance_request_months` result into first-of-month
  /// dates. Unparseable rows are dropped rather than failing the whole picker.
  static List<DateTime> parseMonths(dynamic response) {
    return (response as List)
        .map((row) => DateTime.tryParse((row as Map)['month'].toString()))
        .whereType<DateTime>()
        .toList();
  }

  /// Parses the `list_user_advance_request_ids` result.
  static List<int> parseIds(dynamic response) {
    return (response as List).map((row) => (row as Map)['id']).whereType<num>().map((id) => id.toInt()).toList();
  }
}
