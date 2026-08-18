import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/advance_on_salary_request_model.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_requests_query.dart';

abstract class AdvanceOnSalaryRequestsRepo {
  Future<int> submitAdvanceOnSalaryRequest(AdvanceOnSalaryRequestModel request);

  /// One page of any of the eight advance lists.
  ///
  /// There is deliberately no `userCode` parameter: the server derives the
  /// caller from the auth session. The old `_isUserInHRGroup(code)` /
  /// `_isUserInFinanceGroup(code)` pair took the code from the client, so
  /// passing someone else's returned their approval queue.
  ///
  /// The page already carries each row's scheduled and unscheduled payments —
  /// no `_addUnscheduledPaymentsToRequests` post-pass is needed or wanted.
  Future<PagedResult<AdvanceOnSalaryRequestModel>> getAdvanceRequestsPage(
    AdvanceRequestsQuery query, {
    required int offset,
    required int limit,
  });

  /// First-of-month dates that have at least one row in [scope], for the month
  /// picker. Derived from the same projection as the list.
  Future<List<DateTime>> getAdvanceRequestMonths(AdvanceRequestScope scope);

  /// Whether [scope] contains any row at all, ignoring filters. Drives the
  /// empty-state gate.
  Future<bool> hasAnyRequests(AdvanceRequestScope scope);

  /// Every id the server considers in [scope], across all pages.
  ///
  /// Exists for the Settlement Review bulk action, which used to build its id
  /// list from the rows in memory. Under paging that would be one page, so
  /// "send all" would quietly become "send this page".
  Future<List<int>> getAdvanceRequestIds(AdvanceRequestScope scope);

  /// LEGACY whole-list reads, kept for the
  /// `SERVER_PAGED_ADVANCE_REQUESTS=false` fallback path and for the dashboard
  /// availability checks. All are subject to PostgREST's max_rows cap, which
  /// truncates silently.
  Future<List<AdvanceOnSalaryRequestModel>> getMyAdvanceOnSalaryRequests(int userCode);
  Future<List<AdvanceOnSalaryRequestModel>> getRequestsToApprove(int approverCode);
  Future<void> approveRequest(int requestId, String currentApprover, int approverCode);
  Future<void> declineRequest(int requestId, String reason, String currentApprover, int approverCode);
  Future<List<AdvanceOnSalaryRequestModel>> getRequestsByMonth(int userCode, DateTime month);
  Future<List<AdvanceOnSalaryRequestModel>> getProcessedRequests(int approverCode);
  Future<List<AdvanceOnSalaryRequestModel>> getApprovedUnsettledRequests();
  Future<List<AdvanceOnSalaryRequestModel>> getApprovedSettledRequests();
  Future<void> settleAdvanceRequest(int requestId, String settlerNameArabic, String settlerNameEnglish, int recordedBy);
  Future<void> sendSettlementNotification(int requestId);

  // Finance edit methods
  Future<void> updateRequestByFinance(AdvanceOnSalaryRequestModel request);
  Future<void> addUnscheduledPayment(int requestId, UnscheduledPayment payment, int recordedBy);
  Future<List<UnscheduledPayment>> getUnscheduledPayments(int requestId);
  Future<void> deleteUnscheduledPayment(int paymentId);

  // PDF workflow methods
  Future<void> generateAndStorePDF(AdvanceOnSalaryRequestModel request, String locale);
  Future<String?> getPDFUrl(int requestId);
  Future<bool> hasPendingRequest(int userCode);
  Future<void> cancelRequest(int requestId);
  Future<bool> hasRequestsMadeForUser(int userCode);
  Future<bool> hasMyRequests(int userCode);
  Future<bool> hasTeamRequests(int approverCode);
  Future<bool> hasProcessedRequests(int approverCode);

  // Employee confirmation workflow methods
  Future<void> confirmFinanceEdit(int requestId, int employeeCode);
  Future<void> cancelFinanceEdit(int requestId, int employeeCode);
  Future<void> acknowledgeEmployeeDecision(int requestId, int financeCode);
  Future<List<AdvanceOnSalaryRequestModel>> getRequestsNeedingEmployeeConfirmation(int employeeCode);
  Future<List<AdvanceOnSalaryRequestModel>> getRequestsNeedingFinanceAcknowledgment(int financeCode);

  // Settlement review methods
  Future<List<AdvanceOnSalaryRequestModel>> getSettlementReviewRequests();
  Future<int> getSettlementReviewCount();
  Future<void> sendSettlementNotificationConfirmed(int requestId, int financeUserCode);
  Future<void> sendAllSettlementNotifications(List<int> requestIds, int financeUserCode);
  Future<void> skipSettlementNotification(int requestId, int financeUserCode);
}
