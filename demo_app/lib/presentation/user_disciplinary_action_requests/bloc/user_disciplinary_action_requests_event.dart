import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_requests_query.dart';
import 'package:flutter/foundation.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'dart:typed_data';

@immutable
sealed class UserDisciplinaryActionRequestsEvent {
  const UserDisciplinaryActionRequestsEvent();
}

/// Which entry page the user opened. Routing only — the three in-screen tabs
/// map to four [DisciplinaryRequestScope]s, because the two processed tabs are
/// separate server queries rather than one query filtered twice.
enum RequestSourceType { myRequests, teamRequests, processedRequests }

extension RequestSourceTypeScope on RequestSourceType {
  /// The scope a screen starts on. The team page then switches between
  /// [DisciplinaryRequestScope.team] and the two processed scopes via its tabs,
  /// which dispatch a [DisciplinaryQueryChanged].
  DisciplinaryRequestScope get defaultScope => switch (this) {
    RequestSourceType.myRequests => DisciplinaryRequestScope.my,
    RequestSourceType.teamRequests => DisciplinaryRequestScope.team,
    RequestSourceType.processedRequests => DisciplinaryRequestScope.processedDisciplinary,
  };
}

/// LEGACY whole-list load, which merged two repos' results in Dart. Used only
/// when `FeatureFlags.serverPagedDisciplinaryRequests` is false.
class LoadUserDisciplinaryActionRequests extends UserDisciplinaryActionRequestsEvent {
  const LoadUserDisciplinaryActionRequests(this.userCode, this.sourceType);
  final int userCode;
  final RequestSourceType sourceType;
}

/// Loads what outlives a single page — whether the scope has any rows and which
/// months it spans — then fetches the first page.
class InitDisciplinaryRequests extends UserDisciplinaryActionRequestsEvent {
  const InitDisciplinaryRequests(this.userCode, this.scope);
  final int userCode;
  final DisciplinaryRequestScope scope;
}

/// Moves the window. [page] is 0-based.
class DisciplinaryPageChanged extends UserDisciplinaryActionRequestsEvent {
  const DisciplinaryPageChanged(this.page);
  final int page;
}

/// Resizes the window and returns to the first page.
class DisciplinaryPageSizeChanged extends UserDisciplinaryActionRequestsEvent {
  const DisciplinaryPageSizeChanged(this.pageSize);
  final int pageSize;
}

/// Replaces scope / filters / sort and returns to the first page. A query equal
/// to the current one is dropped, so a rebuild cannot re-issue a fetch.
class DisciplinaryQueryChanged extends UserDisciplinaryActionRequestsEvent {
  const DisciplinaryQueryChanged(this.query);
  final DisciplinaryRequestsQuery query;
}

/// Re-fetches the current page without moving the window.
class RefreshDisciplinaryPage extends UserDisciplinaryActionRequestsEvent {
  const RefreshDisciplinaryPage();
}

/// The event that populates a screen, whichever paging mode is active.
UserDisciplinaryActionRequestsEvent loadDisciplinaryRequestsEvent(int userCode, RequestSourceType sourceType) =>
    FeatureFlags.serverPagedDisciplinaryRequests
        ? InitDisciplinaryRequests(userCode, sourceType.defaultScope)
        : LoadUserDisciplinaryActionRequests(userCode, sourceType);

class ApproveDisciplinaryActionRequest extends UserDisciplinaryActionRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  final String reason;
  final Uint8List? pdfBytes;
  final String? pdfFileName;

  const ApproveDisciplinaryActionRequest(
    this.requestId,
    this.currentApprover,
    this.userCode,
    this.reason, {
    this.pdfBytes,
    this.pdfFileName,
  });
}

class DeclineDisciplinaryActionRequest extends UserDisciplinaryActionRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  final String reason;
  final Uint8List? pdfBytes;
  final String? pdfFileName;

  const DeclineDisciplinaryActionRequest(
    this.requestId,
    this.currentApprover,
    this.userCode,
    this.reason, {
    this.pdfBytes,
    this.pdfFileName,
  });
}

class PutOnHoldDisciplinaryActionRequest extends UserDisciplinaryActionRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  final String reason;

  const PutOnHoldDisciplinaryActionRequest(this.requestId, this.currentApprover, this.userCode, this.reason);
}

class LoadUserDisciplinaryActionRequestsByMonth extends UserDisciplinaryActionRequestsEvent {
  final int userCode;
  final RequestSourceType sourceType;
  final DateTime month;

  const LoadUserDisciplinaryActionRequestsByMonth({
    required this.userCode,
    required this.sourceType,
    required this.month,
  });
}

class LoadEmployeeDisciplinaryHistory extends UserDisciplinaryActionRequestsEvent {
  final int employeeCode;

  const LoadEmployeeDisciplinaryHistory(this.employeeCode);
}

class ResetApproveStatus extends UserDisciplinaryActionRequestsEvent {
  const ResetApproveStatus();
}

class ResetDeclineStatus extends UserDisciplinaryActionRequestsEvent {
  const ResetDeclineStatus();
}

class ResetOnHoldStatus extends UserDisciplinaryActionRequestsEvent {
  const ResetOnHoldStatus();
}

class CancelDisciplinaryActionRequest extends UserDisciplinaryActionRequestsEvent {
  final int requestId;

  const CancelDisciplinaryActionRequest(this.requestId);
}

class ResetCancelStatus extends UserDisciplinaryActionRequestsEvent {
  const ResetCancelStatus();
}

class SendToHrInvestigationDisciplinaryActionRequest extends UserDisciplinaryActionRequestsEvent {
  final int requestId;
  final int n2Code;
  final String reason;

  const SendToHrInvestigationDisciplinaryActionRequest(this.requestId, this.n2Code, this.reason);
}

class ResetInvestigationStatus extends UserDisciplinaryActionRequestsEvent {
  const ResetInvestigationStatus();
}

class EditWrittenWarningOptionsDisciplinaryActionRequest extends UserDisciplinaryActionRequestsEvent {
  final int requestId;
  final WrittenWarningOptions options;
  final WrittenWarningOptions previousOptions;
  final String userEnglishName;
  final String userArabicName;

  const EditWrittenWarningOptionsDisciplinaryActionRequest(
    this.requestId,
    this.options,
    this.previousOptions,
    this.userEnglishName,
    this.userArabicName,
  );
}

class ResetEditStatus extends UserDisciplinaryActionRequestsEvent {
  const ResetEditStatus();
}

class ResetAcknowledgmentStatus extends UserDisciplinaryActionRequestsEvent {
  const ResetAcknowledgmentStatus();
}

class AcknowledgeRequest extends UserDisciplinaryActionRequestsEvent {
  final int requestId;
  final int employeeCode;
  final String acknowledgmentType;
  final String? remark;

  const AcknowledgeRequest({
    required this.requestId,
    required this.employeeCode,
    required this.acknowledgmentType,
    this.remark,
  });
}

class EscalateToLegalDisciplinaryActionRequest extends UserDisciplinaryActionRequestsEvent {
  final int requestId;
  final int hrApproverCode;
  final String reason;

  const EscalateToLegalDisciplinaryActionRequest(this.requestId, this.hrApproverCode, this.reason);
}

class ResetEscalateToLegalStatus extends UserDisciplinaryActionRequestsEvent {
  const ResetEscalateToLegalStatus();
}

class LegalUploadInvestigationDisciplinaryActionRequest extends UserDisciplinaryActionRequestsEvent {
  final int requestId;
  final int legalApproverCode;
  final Uint8List pdfBytes;
  final String pdfFileName;

  const LegalUploadInvestigationDisciplinaryActionRequest(
    this.requestId,
    this.legalApproverCode,
    this.pdfBytes,
    this.pdfFileName,
  );
}

class ResetLegalUploadStatus extends UserDisciplinaryActionRequestsEvent {
  const ResetLegalUploadStatus();
}

class LegalAcknowledgeDisciplinaryActionRequest extends UserDisciplinaryActionRequestsEvent {
  final int requestId;
  final int legalApproverCode;

  const LegalAcknowledgeDisciplinaryActionRequest(this.requestId, this.legalApproverCode);
}

class ResetLegalAcknowledgeStatus extends UserDisciplinaryActionRequestsEvent {
  const ResetLegalAcknowledgeStatus();
}

class HRFinalDecisionDisciplinaryActionRequest extends UserDisciplinaryActionRequestsEvent {
  final int requestId;
  final int hrApproverCode;
  final String action; // 'approve', 'decline', 'suspend', 'terminate'
  final String reason;
  final int? suspensionDays; // Required if action = 'suspend'

  const HRFinalDecisionDisciplinaryActionRequest(
    this.requestId,
    this.hrApproverCode,
    this.action,
    this.reason, {
    this.suspensionDays,
  });
}

class ResetHRFinalDecisionStatus extends UserDisciplinaryActionRequestsEvent {
  const ResetHRFinalDecisionStatus();
}

class FetchAttachmentSignedUrls extends UserDisciplinaryActionRequestsEvent {
  final List<String> attachmentPaths;

  const FetchAttachmentSignedUrls(this.attachmentPaths);
}

class ResetAttachmentUrls extends UserDisciplinaryActionRequestsEvent {
  const ResetAttachmentUrls();
}

// ========== Investigation Events ==========

class RecordHrInvestigationDecision extends UserDisciplinaryActionRequestsEvent {
  final int investigationId;
  final int decidedBy;
  final Map<int, String> employeeDecisions; // employeeCode -> decision
  final Map<int, String>? employeeComments; // employeeCode -> comment
  final bool escalateToLegal;
  final List<String>? pdfUrls;
  final List<Uint8List>? attachmentFiles; // Raw file bytes for upload
  final List<String>? attachmentFileNames; // File names for upload
  final Map<int, String>? employeeDaTypes; // employeeCode -> DA action type (for take_action decisions)
  final Map<int, double>? employeeDeductDays; // employeeCode -> deduct days (for written_warning DA)

  const RecordHrInvestigationDecision({
    required this.investigationId,
    required this.decidedBy,
    required this.employeeDecisions,
    this.employeeComments,
    required this.escalateToLegal,
    this.pdfUrls,
    this.attachmentFiles,
    this.attachmentFileNames,
    this.employeeDaTypes,
    this.employeeDeductDays,
  });
}

class RecordLegalInvestigationReview extends UserDisciplinaryActionRequestsEvent {
  final int investigationId;
  final int reviewedBy;
  final Map<int, String>? employeeComments; // employeeCode -> per-employee note
  final List<String> pdfUrls; // Mandatory
  final List<Uint8List>? pdfBytes;
  final List<String>? pdfFileNames;

  const RecordLegalInvestigationReview({
    required this.investigationId,
    required this.reviewedBy,
    this.employeeComments,
    required this.pdfUrls,
    this.pdfBytes,
    this.pdfFileNames,
  });
}

class RecordTopManagementInvestigationDecision extends UserDisciplinaryActionRequestsEvent {
  final int investigationId;
  final int decidedBy;
  final Map<int, String> employeeDecisions; // employeeCode -> decision ('confirm' or 'convert_to_disciplinary')
  final Map<int, String>? employeeComments; // employeeCode -> comment
  final List<String>? pdfUrls;
  final List<Uint8List>? pdfBytes;
  final List<String>? pdfFileNames;

  const RecordTopManagementInvestigationDecision({
    required this.investigationId,
    required this.decidedBy,
    required this.employeeDecisions,
    this.employeeComments,
    this.pdfUrls,
    this.pdfBytes,
    this.pdfFileNames,
  });
}

class SendTopManagementDecisionNotification extends UserDisciplinaryActionRequestsEvent {
  final int investigationId;
  const SendTopManagementDecisionNotification({required this.investigationId});
}

class EscalateInvestigationToLegal extends UserDisciplinaryActionRequestsEvent {
  final int investigationId;
  final int hrCode;
  final String reason;

  const EscalateInvestigationToLegal({required this.investigationId, required this.hrCode, required this.reason});
}

/// Legal acknowledges investigation (stops email reminders, investigation stays at legal)
class AcknowledgeInvestigation extends UserDisciplinaryActionRequestsEvent {
  final int investigationId;
  final int legalCode;

  const AcknowledgeInvestigation({required this.investigationId, required this.legalCode});
}

/// Legal uploads PDF for investigation (returns investigation to HR)
class UploadLegalInvestigationPdf extends UserDisciplinaryActionRequestsEvent {
  final int investigationId;
  final int legalCode;
  final Uint8List pdfBytes;
  final String pdfFileName;

  const UploadLegalInvestigationPdf({
    required this.investigationId,
    required this.legalCode,
    required this.pdfBytes,
    required this.pdfFileName,
  });
}

class CreateBulkDisciplinaryActionsFromInvestigation extends UserDisciplinaryActionRequestsEvent {
  final int investigationId;
  final int requestorCode;
  final List<int> employeeCodes;
  final DisciplinaryActionType actionType;
  final String? violationCategory;
  final String? violation;
  final DateTime violationDate;
  final String? incidentDescription;
  final WrittenWarningOptions? writtenWarningOptions;
  final List<String>? attachmentUrls;
  final List<Uint8List>? attachmentFiles; // Raw file bytes for upload
  final List<String>? attachmentFileNames; // File names for upload

  const CreateBulkDisciplinaryActionsFromInvestigation({
    required this.investigationId,
    required this.requestorCode,
    required this.employeeCodes,
    required this.actionType,
    this.violationCategory,
    this.violation,
    required this.violationDate,
    this.incidentDescription,
    this.writtenWarningOptions,
    this.attachmentUrls,
    this.attachmentFiles,
    this.attachmentFileNames,
  });
}

class ConvertDisciplinaryActionToInvestigation extends UserDisciplinaryActionRequestsEvent {
  final int disciplinaryActionId;
  final int convertedBy;
  final String reason;

  const ConvertDisciplinaryActionToInvestigation({
    required this.disciplinaryActionId,
    required this.convertedBy,
    required this.reason,
  });
}

class ResetInvestigationDecisionStatus extends UserDisciplinaryActionRequestsEvent {
  const ResetInvestigationDecisionStatus();
}

/// Opens an investigation PDF by converting its storage path to a signed URL
class OpenInvestigationPdf extends UserDisciplinaryActionRequestsEvent {
  final String storagePath;
  const OpenInvestigationPdf(this.storagePath);
}

class ResetPdfOpenStatus extends UserDisciplinaryActionRequestsEvent {
  const ResetPdfOpenStatus();
}

/// @deprecated This event is deprecated and will be removed in a future release.
/// Employee names are now pre-populated in investigation models via repository enrichment.
/// This event is no longer needed as names are available directly from the model using:
/// - `investigation.getEmployeeName(code, isArabic)`
/// - `investigation.getRequestorName(isArabic)`
///
/// Only kept for backward compatibility during migration period.
@Deprecated('Use investigation model helper methods instead')
class FetchEmployeeBasicInfo extends UserDisciplinaryActionRequestsEvent {
  final List<int> employeeCodes;

  const FetchEmployeeBasicInfo(this.employeeCodes);
}

class FetchLinkedDisciplinaryActions extends UserDisciplinaryActionRequestsEvent {
  final int investigationId;

  const FetchLinkedDisciplinaryActions(this.investigationId);
}

/// Fetches a single investigation by ID for viewing from disciplinary action details
class FetchInvestigationById extends UserDisciplinaryActionRequestsEvent {
  final int investigationId;
  final int? approverCode; // used to stamp viewerIsPassiveObserver in the repo

  const FetchInvestigationById(this.investigationId, {this.approverCode});
}

/// Resets the fetched investigation state
class ResetFetchedInvestigation extends UserDisciplinaryActionRequestsEvent {
  const ResetFetchedInvestigation();
}

/// Fetches a single disciplinary action by ID for viewing from investigation details
class FetchDisciplinaryActionById extends UserDisciplinaryActionRequestsEvent {
  final int disciplinaryActionId;

  const FetchDisciplinaryActionById(this.disciplinaryActionId);
}

/// Resets the fetched disciplinary action state
class ResetFetchedDisciplinaryAction extends UserDisciplinaryActionRequestsEvent {
  const ResetFetchedDisciplinaryAction();
}

/// Fetches the investigation linked to a disciplinary action by the DA's own ID.
/// Used when status == 'converted_to_investigation' and investigationId is null on the DA.
class FetchInvestigationByDisciplinaryActionId extends UserDisciplinaryActionRequestsEvent {
  final int disciplinaryActionId;
  const FetchInvestigationByDisciplinaryActionId(this.disciplinaryActionId);
}

/// Resets the linked investigation ID state
class ResetLinkedInvestigationId extends UserDisciplinaryActionRequestsEvent {
  const ResetLinkedInvestigationId();
}
