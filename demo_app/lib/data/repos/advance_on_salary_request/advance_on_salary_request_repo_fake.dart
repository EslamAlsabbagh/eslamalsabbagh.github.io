// GENERATED SCAFFOLD - in-memory stand-in for AdvanceOnSalaryRequestsRepo.
//
// The demo build has no backend. Every member below returns a type-correct
// empty value unless it has been hand-written to read from DemoStore, so a
// screen that touches an unmodelled corner renders empty instead of crashing.

import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/advance_on_salary_request_model.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_requests_query.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeAdvanceOnSalaryRequestsRepo implements AdvanceOnSalaryRequestsRepo {
  FakeAdvanceOnSalaryRequestsRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  @override
  Future<int> submitAdvanceOnSalaryRequest(AdvanceOnSalaryRequestModel request) async => 0;

  @override
  Future<PagedResult<AdvanceOnSalaryRequestModel>> getAdvanceRequestsPage( AdvanceRequestsQuery query, { required int offset, required int limit, }) async => throw UnimplementedError('AdvanceOnSalaryRequestsRepo.getAdvanceRequestsPage is not part of the demo dataset.');

  @override
  Future<List<DateTime>> getAdvanceRequestMonths(AdvanceRequestScope scope) async => <DateTime>[];

  @override
  Future<bool> hasAnyRequests(AdvanceRequestScope scope) async => false;

  @override
  Future<List<int>> getAdvanceRequestIds(AdvanceRequestScope scope) async => <int>[];

  @override
  Future<List<AdvanceOnSalaryRequestModel>> getMyAdvanceOnSalaryRequests(int userCode) async => <AdvanceOnSalaryRequestModel>[];

  @override
  Future<List<AdvanceOnSalaryRequestModel>> getRequestsToApprove(int approverCode) async => <AdvanceOnSalaryRequestModel>[];

  @override
  Future<void> approveRequest(int requestId, String currentApprover, int approverCode) async {}

  @override
  Future<void> declineRequest(int requestId, String reason, String currentApprover, int approverCode) async {}

  @override
  Future<List<AdvanceOnSalaryRequestModel>> getRequestsByMonth(int userCode, DateTime month) async => <AdvanceOnSalaryRequestModel>[];

  @override
  Future<List<AdvanceOnSalaryRequestModel>> getProcessedRequests(int approverCode) async => <AdvanceOnSalaryRequestModel>[];

  @override
  Future<List<AdvanceOnSalaryRequestModel>> getApprovedUnsettledRequests() async => <AdvanceOnSalaryRequestModel>[];

  @override
  Future<List<AdvanceOnSalaryRequestModel>> getApprovedSettledRequests() async => <AdvanceOnSalaryRequestModel>[];

  @override
  Future<void> settleAdvanceRequest(int requestId, String settlerNameArabic, String settlerNameEnglish, int recordedBy) async {}

  @override
  Future<void> sendSettlementNotification(int requestId) async {}

  @override
  Future<void> updateRequestByFinance(AdvanceOnSalaryRequestModel request) async {}

  @override
  Future<void> addUnscheduledPayment(int requestId, UnscheduledPayment payment, int recordedBy) async {}

  @override
  Future<List<UnscheduledPayment>> getUnscheduledPayments(int requestId) async => <UnscheduledPayment>[];

  @override
  Future<void> deleteUnscheduledPayment(int paymentId) async {}

  @override
  Future<void> generateAndStorePDF(AdvanceOnSalaryRequestModel request, String locale) async {}

  @override
  Future<String?> getPDFUrl(int requestId) async => null;

  @override
  Future<bool> hasPendingRequest(int userCode) async => false;

  @override
  Future<void> cancelRequest(int requestId) async {}

  @override
  Future<bool> hasRequestsMadeForUser(int userCode) async => false;

  @override
  Future<bool> hasMyRequests(int userCode) async => false;

  @override
  Future<bool> hasTeamRequests(int approverCode) async => false;

  @override
  Future<bool> hasProcessedRequests(int approverCode) async => false;

  @override
  Future<void> confirmFinanceEdit(int requestId, int employeeCode) async {}

  @override
  Future<void> cancelFinanceEdit(int requestId, int employeeCode) async {}

  @override
  Future<void> acknowledgeEmployeeDecision(int requestId, int financeCode) async {}

  @override
  Future<List<AdvanceOnSalaryRequestModel>> getRequestsNeedingEmployeeConfirmation(int employeeCode) async => <AdvanceOnSalaryRequestModel>[];

  @override
  Future<List<AdvanceOnSalaryRequestModel>> getRequestsNeedingFinanceAcknowledgment(int financeCode) async => <AdvanceOnSalaryRequestModel>[];

  @override
  Future<List<AdvanceOnSalaryRequestModel>> getSettlementReviewRequests() async => <AdvanceOnSalaryRequestModel>[];

  @override
  Future<int> getSettlementReviewCount() async => 0;

  @override
  Future<void> sendSettlementNotificationConfirmed(int requestId, int financeUserCode) async {}

  @override
  Future<void> sendAllSettlementNotifications(List<int> requestIds, int financeUserCode) async {}

  @override
  Future<void> skipSettlementNotification(int requestId, int financeUserCode) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
