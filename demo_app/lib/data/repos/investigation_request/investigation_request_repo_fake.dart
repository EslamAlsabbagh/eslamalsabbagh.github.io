// GENERATED SCAFFOLD - in-memory stand-in for InvestigationRequestRepo.
//
// The demo build has no backend. Every member below returns a type-correct
// empty value unless it has been hand-written to read from DemoStore, so a
// screen that touches an unmodelled corner renders empty instead of crashing.

import 'dart:typed_data';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'package:hrms_demo/data/models/employee_basic_info.dart';
import 'package:hrms_demo/data/models/investigation_decision.dart';
import 'package:hrms_demo/data/models/investigation_request_model.dart';
import 'package:hrms_demo/data/repos/investigation_request/investigation_request_repo.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeInvestigationRequestRepo implements InvestigationRequestRepo {
  FakeInvestigationRequestRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  @override
  Future<int> submitInvestigationRequest(InvestigationRequestModel request) async => 0;

  @override
  Future<List<InvestigationRequestModel>> getMyInvestigationRequests(int userCode) async => <InvestigationRequestModel>[];

  @override
  Future<List<InvestigationRequestModel>> getInvestigationsToApprove( int approverCode, String approverRole, ) async => <InvestigationRequestModel>[];

  @override
  Future<InvestigationRequestModel?> getInvestigationById(int investigationId, {int? approverCode}) async => null;

  @override
  Future<List<InvestigationRequestModel>> getProcessedInvestigations(int approverCode) async => <InvestigationRequestModel>[];

  @override
  Future<void> recordHrDecisions( int investigationId, int hrCode, List<InvestigationDecision> decisions, { Uint8List? pdfBytes, String? pdfFileName, List<String>? attachmentUrls, }) async {}

  @override
  Future<List<String>> uploadHrDecisionAttachments( int investigationId, List<Uint8List> files, List<String> fileNames, ) async => <String>[];

  @override
  Future<void> escalateToTopManagement( int investigationId, int hrCode, List<InvestigationDecision> suspensionTerminationDecisions, ) async {}

  @override
  Future<void> closeInvestigationAtHr(int investigationId, int hrCode) async {}

  @override
  Future<void> escalateInvestigationToLegal( int investigationId, int hrCode, String reason, ) async {}

  @override
  Future<void> recordLegalDecisions( int investigationId, int legalCode, List<InvestigationDecision> decisions, { Uint8List? pdfBytes, String? pdfFileName, }) async {}

  @override
  Future<void> legalAcknowledgeInvestigation( int investigationId, int legalCode, { List<InvestigationDecision>? legalDecisions, }) async {}

  @override
  Future<void> updateInvestigationLegalPdfUrls( int investigationId, int legalCode, List<String> pdfUrls, ) async {}

  @override
  Future<void> uploadAndUpdateLegalPdf( int investigationId, int legalCode, Uint8List pdfBytes, String pdfFileName, ) async {}

  @override
  Future<List<String>> uploadTmDecisionAttachments( int investigationId, List<Uint8List> files, List<String> fileNames, ) async => <String>[];

  @override
  Future<void> recordTopManagementDecisions( int investigationId, int topManagementCode, List<InvestigationDecision> decisions, List<String>? attachmentPaths, ) async {}

  @override
  Future<void> sendTopManagementDecisionNotification(int investigationId) async {}

  @override
  Future<void> closeInvestigationAtTopManagement( int investigationId, int topManagementCode, ) async {}

  @override
  Future<List<int>> createDisciplinaryActionsFromInvestigation( int investigationId, List<DisciplinaryActionRequestModel> actions, ) async => <int>[];

  @override
  Future<List<DisciplinaryActionRequestModel>> getLinkedDisciplinaryActions( int investigationId, ) async => <DisciplinaryActionRequestModel>[];

  @override
  Future<InvestigationRequestModel?> getInvestigationFromDisciplinaryAction(int disciplinaryId) async => null;

  @override
  Future<void> uploadInvestigationAttachments( List<Uint8List> files, List<String>? fileNames, int investigationId, ) async {}

  @override
  Future<List<String>> getInvestigationAttachmentSignedUrls( List<String> filePaths, ) async => <String>[];

  @override
  Future<bool> hasMyInvestigations(int userCode) async => false;

  @override
  Future<bool> hasPendingInvestigations(String approverRole) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
