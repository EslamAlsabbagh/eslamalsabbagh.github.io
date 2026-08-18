// GENERATED SCAFFOLD - in-memory stand-in for DisciplinaryActionRequestRepo.
//
// The demo build has no backend. Every member below returns a type-correct
// empty value unless it has been hand-written to read from DemoStore, so a
// screen that touches an unmodelled corner renders empty instead of crashing.

import 'dart:typed_data';
import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'package:hrms_demo/data/models/request_item_wrapper.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_action_request_repo.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_requests_query.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeDisciplinaryActionRequestRepo implements DisciplinaryActionRequestRepo {
  FakeDisciplinaryActionRequestRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  @override
  Future<int> submitDisciplinaryActionRequest(DisciplinaryActionRequestModel request) async => 0;

  @override
  Future<PagedResult<RequestItem>> getDisciplinaryRequestsPage( DisciplinaryRequestsQuery query, { required int offset, required int limit, }) async => throw UnimplementedError('DisciplinaryActionRequestRepo.getDisciplinaryRequestsPage is not part of the demo dataset.');

  @override
  Future<List<DateTime>> getDisciplinaryRequestMonths(DisciplinaryRequestScope scope) async => <DateTime>[];

  @override
  Future<bool> hasAnyRequests(DisciplinaryRequestScope scope) async => false;

  @override
  Future<List<DisciplinaryActionRequestModel>> getMyDisciplinaryActionRequests(int userCode) async => <DisciplinaryActionRequestModel>[];

  @override
  Future<List<DisciplinaryActionRequestModel>> getDisciplinaryActionRequestsAsParty(int userCode) async => <DisciplinaryActionRequestModel>[];

  @override
  Future<List<DisciplinaryActionRequestModel>> getRequestsToApprove(int approverCode) async => <DisciplinaryActionRequestModel>[];

  @override
  Future<void> approveRequest( int requestId, String currentApprover, int approverCode, String reason, { Uint8List? pdfBytes, String? pdfFileName, }) async {}

  @override
  Future<void> declineRequest( int requestId, String reason, String currentApprover, int approverCode, { Uint8List? pdfBytes, String? pdfFileName, }) async {}

  @override
  Future<void> putOnHoldRequest(int requestId, String currentApprover, int approverCode, String reason) async {}

  @override
  Future<void> sendToHrInvestigation(int requestId, int n2Code, String reason) async {}

  @override
  Future<List<DisciplinaryActionRequestModel>> getRequestsByMonth(int userCode, DateTime month) async => <DisciplinaryActionRequestModel>[];

  @override
  Future<List<DisciplinaryActionRequestModel>> getProcessedRequests(int approverCode) async => <DisciplinaryActionRequestModel>[];

  @override
  Future<List<DisciplinaryActionRequestModel>> getEmployeeDisciplinaryHistory(int employeeCode) async => <DisciplinaryActionRequestModel>[];

  @override
  Future<List<DisciplinaryActionRequestModel>> getWrittenWarningsInPeriod( int employeeCode, DateTime startDate, DateTime endDate, ) async => <DisciplinaryActionRequestModel>[];

  @override
  Future<int> getWrittenWarningsCount(int employeeCode, DateTime startDate, DateTime endDate) async => 0;

  @override
  Future<bool> shouldEmployeeBeTerminated(int employeeCode) async => false;

  @override
  Future<void> generateAndStorePDF(DisciplinaryActionRequestModel request, String locale) async {}

  @override
  Future<String?> getPDFUrl(int requestId) async => null;

  @override
  Future<bool> hasPendingRequest(int employeeCode) async => false;

  @override
  Future<void> cancelRequest(int requestId) async {}

  @override
  Future<void> editWrittenWarningOptions(int requestId, WrittenWarningOptions options, String? comments) async {}

  @override
  Future<void> acknowledgeRequest(int requestId, int employeeCode, String acknowledgmentType, String? remark) async {}

  @override
  Future<List<DisciplinaryActionRequestModel>> getRequestsNeedingEmployeeAcknowledgment(int employeeCode) async => <DisciplinaryActionRequestModel>[];

  @override
  Future<bool> hasRequestsMadeForUser(int userCode) async => false;

  @override
  Future<bool> hasMyRequests(int userCode) async => false;

  @override
  Future<bool> hasTeamRequests(int approverCode) async => false;

  @override
  Future<bool> hasProcessedRequests(int approverCode) async => false;

  @override
  Future<void> escalateToLegal(int requestId, int hrApproverCode, String reason) async {}

  @override
  Future<void> legalUploadInvestigation(int requestId, int legalApproverCode, Uint8List pdfBytes, String pdfFileName) async {}

  @override
  Future<void> legalAcknowledge(int requestId, int legalApproverCode) async {}

  @override
  Future<void> hrFinalDecision(int requestId, int hrApproverCode, String action, String reason, int? suspensionDays) async {}

  @override
  Future<List<DisciplinaryActionRequestModel>> getLegalPendingRequests() async => <DisciplinaryActionRequestModel>[];

  @override
  Future<List<DisciplinaryActionRequestModel>> getLegalProcessedRequests(int legalUserCode) async => <DisciplinaryActionRequestModel>[];

  @override
  Future<void> uploadAttachments(List<Uint8List> files, List<String>? fileNames, int requestId) async {}

  @override
  Future<List<String>> getAttachmentSignedUrls(List<String> filePaths) async => <String>[];

  @override
  Future<int> convertDisciplinaryActionToInvestigation(int disciplinaryActionId, int convertedBy, String reason) async => 0;

  @override
  Future<DisciplinaryActionRequestModel?> fetchDisciplinaryActionById(int id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
