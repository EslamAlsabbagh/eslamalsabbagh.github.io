import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/hr_letter_request_model.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_requests_query.dart';

abstract class HrLetterRequestRepo {
  Future<int> submitHrLetterRequest(HrLetterRequestModel request);

  /// One page of the HR-letter list.
  ///
  /// There is deliberately no `userCode` parameter: the server derives the
  /// caller from the auth session, so a client cannot ask for someone else's
  /// list.
  Future<PagedResult<HrLetterRequestModel>> getHrLetterRequestsPage(
    HrLetterRequestsQuery query, {
    required int offset,
    required int limit,
  });

  /// First-of-month dates that have at least one row in [scope], for the month
  /// picker. Derived from the same projection as the list, so the dropdown
  /// cannot offer a month the list has no rows for.
  Future<List<DateTime>> getHrLetterRequestMonths(HrLetterRequestScope scope);

  /// Whether [scope] contains any row at all, ignoring filters. Drives the
  /// empty-state gate.
  Future<bool> hasAnyRequests(HrLetterRequestScope scope);

  /// LEGACY whole-list reads, kept for the `SERVER_PAGED_HR_LETTER_REQUESTS=false`
  /// fallback path only. Both are subject to PostgREST's max_rows cap, which
  /// truncates silently, and [getAllHrLetterRequests] applies no predicate at
  /// all — see the migration header.
  Future<List<HrLetterRequestModel>> getMyHrLetterRequests(int employeeCode);
  Future<List<HrLetterRequestModel>> getAllHrLetterRequests();

  /// LEGACY existence probes. The paged screens use [hasAnyRequests] instead,
  /// because these three disagree with what the list actually returns: none of
  /// them applies the `employee_code <> caller` rule the team list applies, and
  /// none is gated on the `hr` group. Still used by the sidebar availability
  /// checks (user_bloc.dart).
  Future<bool> hasMyRequests(int employeeCode);
  Future<bool> hasTeamRequests();
  Future<bool> hasProcessedRequests();

  Future<void> acknowledgeRequest(int requestId, int hrCode);
  Future<void> completeRequest(int requestId, int hrCode);
  Future<void> declineRequest(int requestId, int hrCode, String reason);
  Future<void> cancelRequest(int requestId);

  Future<void> sendSubmissionNotification(int requestId);
  Future<void> sendCompletionNotification(int requestId);
  Future<void> sendDeclineNotification(int requestId);
}
