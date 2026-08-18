import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/missingpunching_request_model.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunch_requests_query.dart';

abstract class MissingpunchingRequestsRepo {
  Future<int> submitMissingpunchingRequest(MissingpunchingRequestModel request);

  /// One page of the missing-punch list.
  ///
  /// Filtering, sorting and counting all happen server-side, so this is a single
  /// round trip regardless of page size — replacing the old path's up-to-six
  /// sequential queries.
  ///
  /// There is deliberately no `userCode` parameter: the server derives the
  /// caller from the auth session. The old methods take one and trust it, which
  /// let a client request another user's approval queue.
  Future<PagedResult<MissingpunchingRequestModel>> getMissingpunchRequestsPage(
    MissingpunchRequestsQuery query, {
    required int offset,
    required int limit,
  });

  /// First-of-month dates that have at least one row in [scope], for the month
  /// picker. Unfiltered by search/status/month, matching how the picker's
  /// `availableMonths` is derived today. Buckets on `date`, not `created_at`.
  Future<List<DateTime>> getMissingpunchRequestMonths(MissingpunchRequestScope scope);

  /// Whether [scope] contains any row at all, ignoring filters.
  ///
  /// Drives the empty-state gate. It must stay unfiltered: gating on a filtered
  /// count would make the whole table (and its filter bar) vanish as soon as a
  /// user filtered down to zero results, stranding them.
  Future<bool> hasAnyRequests(MissingpunchRequestScope scope, int userCode);

  // ── LEGACY: unpaginated, whole-list reads ──────────────────────────────────
  // Prefer [getMissingpunchRequestsPage]. These fetch every matching row and are
  // therefore subject to PostgREST's max_rows cap, which truncates SILENTLY —
  // past that limit they return an incomplete list with no error.
  //
  // Not annotated @Deprecated on purpose: the feature-flagged legacy branch in
  // UserMissingpunchRequestsBloc still calls them, and so do the dashboard
  // summaries (pending_requests_summary_bloc.dart:73,
  // my_requests_summary_bloc.dart:57) and the sidebar's menu gate
  // (user_bloc.dart:76-81), which only want integer counts.

  /// Legacy whole-list read. See the LEGACY note above.
  Future<List<MissingpunchingRequestModel>> getMyMissingpunchingRequests(int userCode);

  /// Legacy whole-list read. See the LEGACY note above.
  Future<List<MissingpunchingRequestModel>> getRequestsToApprove(int approverCode);

  /// Legacy whole-list read. See the LEGACY note above.
  Future<List<MissingpunchingRequestModel>> getProcessedRequests(int approverCode);

  Future<void> approveRequest(int requestId, String approverTitle, int approverCode);
  Future<void> declineRequest(int requestId, String reason, String currentApprover, int approverCode);
  Future<List<MissingpunchingRequestModel>> getRequestsByMonth(int userCode, DateTime month);
  Future<bool> hasMyRequests(int userCode);
  Future<bool> hasTeamRequests(int approverCode);
  Future<bool> hasProcessedRequests(int approverCode);
  Future<void> cancelRequest(int requestId);
  Future<void> removeRequest(int requestId);
  Future<void> removeRequestForN1(int requestId);
}
