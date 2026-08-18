import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/overtime_request_model.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_requests_query.dart';

/// The wire contract for `list_user_overtime_requests`.
///
/// Kept out of the repo so it can be tested without a Supabase client: the
/// repo's own job shrinks to "call `rpc`, hand the result here". Every rule
/// that has to agree with
/// `supabase/migrations/20260804130000_overtime_requests_pagination.sql` lives
/// in this one place.
abstract final class OvertimeRequestsRpc {
  static const String listFunction = 'list_user_overtime_requests';
  static const String monthsFunction = 'list_user_overtime_request_months';

  /// Postgres DATE params want 'yyyy-MM-dd'. The RPC reads only the month, so
  /// any day in it works; the 1st keeps the wire value self-explanatory.
  static String monthParam(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-01';

  /// Builds the `params` map.
  ///
  /// `null` is the RPC's "no filter" signal for search, status and month —
  /// sending `'all'` or `''` through would be treated as a literal value to
  /// match against.
  static Map<String, dynamic> params(
    OvertimeRequestsQuery query, {
    required int offset,
    required int limit,
  }) {
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
  /// Simpler than the leave and business-trip equivalents: overtime has no
  /// cancellation sibling table, so `rows` is a flat array of payloads with no
  /// `row_kind` wrapper to unwrap and no sealed row type to build.
  static PagedResult<OvertimeRequestModel> parse(dynamic response) {
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
            .map<OvertimeRequestModel>(
              (entry) => OvertimeRequestModel.fromJson(Map<String, dynamic>.from(entry as Map)),
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

  /// Parses the `list_user_overtime_request_months` result into first-of-month
  /// dates. Unparseable rows are dropped rather than failing the whole picker.
  static List<DateTime> parseMonths(dynamic response) {
    return (response as List)
        .map((row) => DateTime.tryParse((row as Map)['month'].toString()))
        .whereType<DateTime>()
        .toList();
  }
}
