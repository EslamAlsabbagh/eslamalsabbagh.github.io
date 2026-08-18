import 'dart:typed_data';
import 'package:hrms_demo/data/models/investigation_request_model.dart';
import 'package:hrms_demo/data/models/investigation_decision.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'package:hrms_demo/data/models/employee_basic_info.dart';

/// Repository interface for investigation request operations.
///
/// Handles CRUD operations, workflow management, and decision recording
/// for multi-employee investigations.
abstract class InvestigationRequestRepo {
  // ============== Submission ==============
  /// Submits a new investigation request and returns the investigation ID
  Future<int> submitInvestigationRequest(InvestigationRequestModel request);

  // ============== Retrieval ==============
  /// Gets all investigation requests created by the specified user
  Future<List<InvestigationRequestModel>> getMyInvestigationRequests(int userCode);

  /// Gets all pending investigations that the specified approver needs to review
  /// @param approverCode The code of the approver (HR, Legal, or Top Management)
  /// @param approverRole The role of the approver ('hr', 'legal', 'top_management')
  Future<List<InvestigationRequestModel>> getInvestigationsToApprove(
    int approverCode,
    String approverRole,
  );

  /// Gets a specific investigation by ID
  /// [approverCode] — when provided, stamps [viewerIsPassiveObserver] on the result
  Future<InvestigationRequestModel?> getInvestigationById(int investigationId, {int? approverCode});

  /// Gets all investigations that the specified approver has processed (closed/completed)
  Future<List<InvestigationRequestModel>> getProcessedInvestigations(int approverCode);

  // ============== HR Decisions ==============
  /// Records HR decisions for investigated employees
  ///
  /// If any decisions require suspension/termination, this automatically
  /// escalates to top management. Otherwise, closes the investigation at HR level.
  ///
  /// [attachmentUrls] - Optional list of already-uploaded attachment paths to store with the decision
  Future<void> recordHrDecisions(
    int investigationId,
    int hrCode,
    List<InvestigationDecision> decisions, {
    Uint8List? pdfBytes,
    String? pdfFileName,
    List<String>? attachmentUrls,
  });

  /// Uploads HR decision attachments and returns the storage paths (without saving to DB)
  /// These paths can then be passed to recordHrDecisions
  Future<List<String>> uploadHrDecisionAttachments(
    int investigationId,
    List<Uint8List> files,
    List<String> fileNames,
  );

  /// Manually escalates an investigation to top management
  /// Used when HR needs top management review for serious cases
  Future<void> escalateToTopManagement(
    int investigationId,
    int hrCode,
    List<InvestigationDecision> suspensionTerminationDecisions,
  );

  /// Closes an investigation at the HR level
  /// Called after all decisions are made and disciplinary actions are created
  Future<void> closeInvestigationAtHr(int investigationId, int hrCode);

  // ============== Legal Decisions ==============
  /// Escalates an investigation to the Legal department for review
  Future<void> escalateInvestigationToLegal(
    int investigationId,
    int hrCode,
    String reason,
  );

  /// Records Legal department's decisions for investigated employees
  Future<void> recordLegalDecisions(
    int investigationId,
    int legalCode,
    List<InvestigationDecision> decisions, {
    Uint8List? pdfBytes,
    String? pdfFileName,
  });

  /// Marks that Legal has acknowledged the investigation
  /// Note: Acknowledge only stops email reminders, investigation stays at legal
  Future<void> legalAcknowledgeInvestigation(
    int investigationId,
    int legalCode, {
    List<InvestigationDecision>? legalDecisions,
  });

  /// Updates investigation with legal PDF URLs and returns to HR
  /// This is the completion action that returns investigation to HR
  Future<void> updateInvestigationLegalPdfUrls(
    int investigationId,
    int legalCode,
    List<String> pdfUrls,
  );

  /// Uploads legal PDF and returns investigation to HR
  /// This handles the actual file upload to storage
  Future<void> uploadAndUpdateLegalPdf(
    int investigationId,
    int legalCode,
    Uint8List pdfBytes,
    String pdfFileName,
  );

  // ============== Top Management Decisions ==============
  /// Uploads TM decision attachments and returns the storage paths (without saving to DB)
  /// These paths can then be passed to recordTopManagementDecisions
  Future<List<String>> uploadTmDecisionAttachments(
    int investigationId,
    List<Uint8List> files,
    List<String> fileNames,
  );

  /// Records Top Management's decisions for employees facing suspension/termination
  ///
  /// Top Management can either:
  /// - Confirm the suspension/termination
  /// - Convert to a lesser disciplinary action (verbal/written warning)
  ///
  /// [attachmentPaths] - Optional list of already-uploaded attachment paths to store with the decision
  Future<void> recordTopManagementDecisions(
    int investigationId,
    int topManagementCode,
    List<InvestigationDecision> decisions,
    List<String>? attachmentPaths,
  );

  /// Fires the TM decision notification email (call after bulk DA creation is complete)
  Future<void> sendTopManagementDecisionNotification(int investigationId);

  /// Closes an investigation at the Top Management level
  Future<void> closeInvestigationAtTopManagement(
    int investigationId,
    int topManagementCode,
  );

  // ============== Disciplinary Action Creation ==============
  /// Creates disciplinary actions for employees based on investigation decisions
  ///
  /// This is called after HR (or Top Management) makes final decisions.
  /// Creates multiple disciplinary actions and links them to the investigation.
  ///
  /// @returns List of created disciplinary action IDs
  Future<List<int>> createDisciplinaryActionsFromInvestigation(
    int investigationId,
    List<DisciplinaryActionRequestModel> actions,
  );

  /// Gets all disciplinary actions that were created from a specific investigation
  Future<List<DisciplinaryActionRequestModel>> getLinkedDisciplinaryActions(
    int investigationId,
  );

  /// Gets investigation that created from a disciplinary action
  Future<InvestigationRequestModel?> getInvestigationFromDisciplinaryAction(int disciplinaryId);

  // ============== Attachment Management ==============
  /// Uploads investigation-related attachments (evidence, documents, etc.)
  Future<void> uploadInvestigationAttachments(
    List<Uint8List> files,
    List<String>? fileNames,
    int investigationId,
  );

  /// Gets signed URLs for investigation attachments
  /// @param filePaths List of file paths from the database
  /// @returns List of temporary signed URLs for downloading
  Future<List<String>> getInvestigationAttachmentSignedUrls(
    List<String> filePaths,
  );

  // ============== Status Checks ==============
  /// Checks if a user has any investigation requests (for showing menu badge)
  Future<bool> hasMyInvestigations(int userCode);

  /// Checks if there are any pending investigations for the specified approver role
  Future<bool> hasPendingInvestigations(String approverRole);

  

  // ============== Employee Info ==============
  /// Fetches basic employee information (names, department) for the given employee codes
  ///
  /// @deprecated This method is deprecated and will be removed in a future release.
  /// Employee names are now enriched directly in investigation models via repository
  /// enrichment. Use the investigation model's helper methods instead:
  /// - `investigation.getEmployeeName(code, isArabic)`
  /// - `investigation.getRequestorName(isArabic)`
  ///
  /// Only kept for backward compatibility during migration period.
  @Deprecated('Use investigation model helper methods instead')
  Future<Map<int, EmployeeBasicInfo>> getEmployeeBasicInfo(List<int> employeeCodes);
}
