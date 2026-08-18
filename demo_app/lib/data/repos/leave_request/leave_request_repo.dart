import 'dart:typed_data';

import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/leave_request_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/models/user_request_row.dart';
import 'package:hrms_demo/data/repos/leave_request/bulk_leave_result.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_requests_query.dart';

abstract class LeaveRequestsRepo {
  Future<int> submitLeaveRequest(LeaveRequestModel request);

  /// One page of the merged leave + leave-cancellation list.
  ///
  /// Filtering, sorting, counting and the leave/cancellation merge all happen
  /// server-side, so this is a single round trip regardless of page size.
  ///
  /// There is deliberately no `userCode` parameter: the server derives the
  /// caller from the auth session. The old methods take one and trust it, which
  /// let a client request another user's approval queue.
  Future<PagedResult<UserRequestRow>> getLeaveRequestsPage(
    LeaveRequestsQuery query, {
    required int offset,
    required int limit,
  });

  /// First-of-month dates that have at least one row in [scope], for the month
  /// picker. Unfiltered by search/status/month, matching how the picker's
  /// `availableMonths` is derived today.
  Future<List<DateTime>> getLeaveRequestMonths(LeaveRequestScope scope);

  /// Whether [scope] contains any row at all, ignoring filters.
  ///
  /// Drives the empty-state gate. It must stay unfiltered: gating on a filtered
  /// count would make the whole table (and its filter bar) vanish as soon as a
  /// user filtered down to zero results, stranding them.
  Future<bool> hasAnyRequests(LeaveRequestScope scope, int userCode);

  // ── LEGACY: unpaginated, whole-list reads ──────────────────────────────────
  // Prefer [getLeaveRequestsPage]. These three fetch every matching row and are
  // therefore subject to PostgREST's max_rows cap, which truncates SILENTLY —
  // past that limit they return an incomplete list with no error.
  //
  // Not annotated @Deprecated on purpose: the feature-flagged legacy branch in
  // UserRequestsBloc still calls them, and so do three dashboard call sites
  // (my_requests_summary_bloc.dart:54, pending_requests_summary_bloc.dart:68,
  // employees_bloc.dart:385) which only want integer counts. Annotating now
  // would mean scattering `// ignore:` comments that have to be removed again.
  // Delete these once those callers move to a count RPC.

  /// Legacy whole-list read. See the LEGACY note above.
  Future<List<LeaveRequestModel>> getMyLeaveRequests(int userCode);

  /// Legacy whole-list read. See the LEGACY note above.
  Future<List<LeaveRequestModel>> getRequestsToApprove(int approverCode);

  /// Legacy whole-list read. See the LEGACY note above.
  Future<List<LeaveRequestModel>> getProcessedRequests(int approverCode);
  Future<void> approveRequest(int requestId, String approverTitle, int approverCode);
  Future<void> declineRequest(int requestId, String reason, String currentApprover, int approverCode);
  Future<void> uploadSickNote(List<Uint8List> sickNotes, List<String>? sickNoteFileNames, int requestId);
  Future<List<LeaveRequestModel>> getRequestsByMonth(int userCode, DateTime month);
  Future<bool> hasMyRequests(int userCode);
  Future<bool> hasTeamRequests(int approverCode);
  Future<bool> hasProcessedRequests(int approverCode);
  Future<void> cancelRequest(int requestId);
  Future<void> removeRequest(int requestId);
  Future<void> removeRequestForN1(int requestId);

  /// Bulk submission that AUTO-APPROVES: writes rows straight to
  /// `leave_requests` already stamped `approved` / `is_auto_approved`, skipping
  /// both the approval chain and `validate_leave_request`.
  ///
  /// Returns the created `leave_requests.id`s in [employees] order.
  Future<List<int>> submitBulkLeaveRequests({
    required List<UserModel> employees,
    required DateTime dateFrom,
    required DateTime dateTo,
    required String leaveType,
    required double numberOfDays,
    required int hrApproverCode,
  });

  /// Bulk submission that goes through the NORMAL approval cycle: one
  /// `submit_leave_request` RPC per employee, so each request lands as
  /// `pending` with `current_approver = 'n1'` and the N+1 gets notified —
  /// exactly as if the employee had filed it themselves.
  ///
  /// Best-effort: a per-employee rejection is RETURNED as a [BulkLeaveFailure]
  /// rather than thrown, so one employee failing validation does not abort the
  /// rest of the batch. Empty `failures` means every employee succeeded.
  Future<BulkLeaveSubmissionResult> submitBulkLeaveRequestsForApproval({
    required List<UserModel> employees,
    required DateTime dateFrom,
    required DateTime dateTo,
    required String leaveType,
    required double numberOfDays,
  });
}
