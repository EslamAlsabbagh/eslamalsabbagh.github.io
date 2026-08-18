import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'package:hrms_demo/data/models/investigation_request_model.dart';
import 'package:hrms_demo/data/models/request_item_wrapper.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_requests_query.dart';

/// The wire contract for `list_user_disciplinary_requests`.
///
/// Kept out of the repo so it can be tested without a Supabase client. Every
/// rule that has to agree with
/// `supabase/migrations/20260804160000_disciplinary_requests_pagination.sql`
/// lives in this one place.
abstract final class DisciplinaryRequestsRpc {
  static const String listFunction = 'list_user_disciplinary_requests';
  static const String monthsFunction = 'list_user_disciplinary_request_months';

  /// Postgres DATE params want 'yyyy-MM-dd'. The RPC reads only the month, so
  /// any day in it works; the 1st keeps the wire value self-explanatory.
  static String monthParam(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-01';

  /// Builds the `params` map.
  ///
  /// `null` is the RPC's "no filter" signal for search, status and month.
  static Map<String, dynamic> params(DisciplinaryRequestsQuery query, {required int offset, required int limit}) {
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

  /// Turns the RPC result into a page of [RequestItem]s.
  ///
  /// Like leave and business trip, and unlike the single-table features, each
  /// element of `rows` is a `{'row_kind': ..., 'payload': {...}}` wrapper —
  /// this list interleaves two tables, so the payload alone cannot say which
  /// model to build.
  ///
  /// `RequestItem` is reused rather than replaced by a new sealed type: it
  /// already IS the union wrapper this screen is built on, and every branch of
  /// the 4000-line content widget switches on it.
  static PagedResult<RequestItem> parse(dynamic response) {
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
        (row['rows'] as List? ?? const []).map<RequestItem>((entry) {
          final wrapper = Map<String, dynamic>.from(entry as Map);
          final payload = Map<String, dynamic>.from(wrapper['payload'] as Map);
          return wrapper['row_kind'] == 'investigation'
              ? RequestItem.fromInvestigation(InvestigationRequestModel.fromJson(payload))
              : RequestItem.fromDisciplinary(DisciplinaryActionRequestModel.fromJson(payload));
        }).toList();

    return PagedResult(
      items: items,
      // The total across ALL pages, present even when `rows` is empty.
      totalCount: (row['total_count'] as num?)?.toInt() ?? 0,
      hasActionable: row['has_actionable'] as bool? ?? false,
    );
  }

  /// Parses the `list_user_disciplinary_request_months` result into
  /// first-of-month dates. Unparseable rows are dropped rather than failing the
  /// whole picker.
  static List<DateTime> parseMonths(dynamic response) {
    return (response as List)
        .map((row) => DateTime.tryParse((row as Map)['month'].toString()))
        .whereType<DateTime>()
        .toList();
  }
}
