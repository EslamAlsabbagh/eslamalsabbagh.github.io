import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/businesstrip_request_model.dart';
import 'package:hrms_demo/data/models/businesstrip_request_row.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_requests_query.dart';

abstract class BusinesstripRequestsRepo {
  Future<int> submitBusinesstripRequest(BusinesstripRequestModel request);

  // ── Server-side paging ─────────────────────────────────────────────────────

  /// One page of merged trip + cancellation rows for [query]'s scope.
  Future<PagedResult<BusinesstripRequestRow>> getBusinesstripRequestsPage(
    BusinesstripRequestsQuery query, {
    required int offset,
    required int limit,
  });

  /// First-of-month dates present in [scope], for the month picker. Unfiltered
  /// by design — the picker must offer months that are not on the current page.
  Future<List<DateTime>> getBusinesstripRequestMonths(BusinesstripRequestScope scope);

  /// Whether [scope] holds any rows at all, ignoring the user's filters.
  ///
  /// Gates the screen-level empty state. MUST be derived from the same query
  /// the table pages through — see the implementation for why the cheaper
  /// `has*Requests` probes below are the wrong answer.
  Future<bool> hasAnyRequests(BusinesstripRequestScope scope, int userCode);

  // ── Legacy whole-list reads ────────────────────────────────────────────────
  // Retained for two reasons: they are the fallback when
  // FeatureFlags.serverPagedBusinesstripRequests is off, and they are still the
  // only reads used by the dashboard summary widgets
  // (my_requests_summary_bloc.dart:56, pending_requests_summary_bloc.dart:71)
  // and the HR requests report (employees_bloc.dart:304). Do not delete them
  // when the flag is retired without migrating those call sites first.

  Future<List<BusinesstripRequestModel>> getMybusinesstripRequests(
    int userCode,
  );
  Future<List<BusinesstripRequestModel>> getRequestsToApprove(int approverCode);
  Future<List<BusinesstripRequestModel>> getProcessedRequests(int approverCode);
  Future<void> approveRequest(
    int requestId,
    String currentApprover,
    int approverCode, {
    double? transportationFeeAmount,
  });
  Future<void> declineRequest(int requestId, String reason, String currentApprover, int approverCode);

  /// Sidebar visibility probes (user_bloc.dart:82-84, :158-160). These count a
  /// DIFFERENT set of rows than the list scopes do, so they must not be used to
  /// answer "does this screen have rows" — use [hasAnyRequests] for that.
  Future<bool> hasMyRequests(int userCode);
  Future<bool> hasTeamRequests(int approverCode);
  Future<bool> hasProcessedRequests(int approverCode);

  Future<void> cancelRequest(int requestId);
  Future<void> removeRequest(int requestId);
  Future<void> removeRequestForN1(int requestId);
}
