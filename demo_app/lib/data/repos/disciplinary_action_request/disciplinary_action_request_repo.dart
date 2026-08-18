import 'dart:typed_data';
import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'package:hrms_demo/data/models/request_item_wrapper.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_requests_query.dart';

abstract class DisciplinaryActionRequestRepo {
  Future<int> submitDisciplinaryActionRequest(DisciplinaryActionRequestModel request);

  /// One page of the MERGED disciplinary-action + investigation list.
  ///
  /// This repo owns the paged read for both tables even though investigations
  /// live behind their own repo, because the two only ever appear together —
  /// the bloc used to fetch them separately and merge in Dart, which is exactly
  /// what cannot be paged from the client. The server unions them with a
  /// `row_kind` discriminator, the same shape leave uses for requests +
  /// cancellations.
  ///
  /// There is deliberately no `userCode` parameter: the server derives the
  /// caller from the auth session, including the hr / legal / top_management
  /// group checks the old code took as arguments.
  Future<PagedResult<RequestItem>> getDisciplinaryRequestsPage(
    DisciplinaryRequestsQuery query, {
    required int offset,
    required int limit,
  });

  /// First-of-month dates that have at least one row in [scope], across BOTH
  /// tables, for the month picker.
  Future<List<DateTime>> getDisciplinaryRequestMonths(DisciplinaryRequestScope scope);

  /// Whether [scope] contains any row at all, ignoring filters. Drives the
  /// empty-state gate.
  Future<bool> hasAnyRequests(DisciplinaryRequestScope scope);

  /// LEGACY whole-list read, kept for the
  /// `SERVER_PAGED_DISCIPLINARY_REQUESTS=false` fallback path. Subject to
  /// PostgREST's max_rows cap, which truncates silently.
  Future<List<DisciplinaryActionRequestModel>> getMyDisciplinaryActionRequests(int userCode);

  Future<List<DisciplinaryActionRequestModel>> getDisciplinaryActionRequestsAsParty(int userCode);

  Future<List<DisciplinaryActionRequestModel>> getRequestsToApprove(int approverCode);

  Future<void> approveRequest(
    int requestId,
    String currentApprover,
    int approverCode,
    String reason, {
    Uint8List? pdfBytes,
    String? pdfFileName,
  });

  Future<void> declineRequest(
    int requestId,
    String reason,
    String currentApprover,
    int approverCode, {
    Uint8List? pdfBytes,
    String? pdfFileName,
  });

  Future<void> putOnHoldRequest(int requestId, String currentApprover, int approverCode, String reason);

  Future<void> sendToHrInvestigation(int requestId, int n2Code, String reason);

  Future<List<DisciplinaryActionRequestModel>> getRequestsByMonth(int userCode, DateTime month);

  Future<List<DisciplinaryActionRequestModel>> getProcessedRequests(int approverCode);

  Future<List<DisciplinaryActionRequestModel>> getEmployeeDisciplinaryHistory(int employeeCode);

  Future<List<DisciplinaryActionRequestModel>> getWrittenWarningsInPeriod(
    int employeeCode,
    DateTime startDate,
    DateTime endDate,
  );

  Future<int> getWrittenWarningsCount(int employeeCode, DateTime startDate, DateTime endDate);

  Future<bool> shouldEmployeeBeTerminated(int employeeCode);

  // PDF workflow methods
  Future<void> generateAndStorePDF(DisciplinaryActionRequestModel request, String locale);

  Future<String?> getPDFUrl(int requestId);

  Future<bool> hasPendingRequest(int employeeCode);

  Future<void> cancelRequest(int requestId);

  Future<void> editWrittenWarningOptions(int requestId, WrittenWarningOptions options, String? comments);

  Future<void> acknowledgeRequest(int requestId, int employeeCode, String acknowledgmentType, String? remark);

  Future<List<DisciplinaryActionRequestModel>> getRequestsNeedingEmployeeAcknowledgment(int employeeCode);

  Future<bool> hasRequestsMadeForUser(int userCode);
  Future<bool> hasMyRequests(int userCode);
  Future<bool> hasTeamRequests(int approverCode);
  Future<bool> hasProcessedRequests(int approverCode);

  // Legal escalation methods
  Future<void> escalateToLegal(int requestId, int hrApproverCode, String reason);

  Future<void> legalUploadInvestigation(int requestId, int legalApproverCode, Uint8List pdfBytes, String pdfFileName);

  Future<void> legalAcknowledge(int requestId, int legalApproverCode);

  Future<void> hrFinalDecision(int requestId, int hrApproverCode, String action, String reason, int? suspensionDays);

  Future<List<DisciplinaryActionRequestModel>> getLegalPendingRequests();

  Future<List<DisciplinaryActionRequestModel>> getLegalProcessedRequests(int legalUserCode);

  Future<void> uploadAttachments(List<Uint8List> files, List<String>? fileNames, int requestId);

  /// Generate signed URLs for viewing attachments (valid for 1 hour)
  Future<List<String>> getAttachmentSignedUrls(List<String> filePaths);

  /// Converts a disciplinary action into an investigation
  /// This is used when a single disciplinary action requires broader investigation
  /// Returns the newly created investigation ID
  Future<int> convertDisciplinaryActionToInvestigation(int disciplinaryActionId, int convertedBy, String reason);

  /// Fetches a single disciplinary action by ID for viewing from investigation details
  Future<DisciplinaryActionRequestModel?> fetchDisciplinaryActionById(int id);
}
