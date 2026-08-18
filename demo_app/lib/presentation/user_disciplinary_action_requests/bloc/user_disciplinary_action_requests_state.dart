import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/bases/paged_section.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'package:hrms_demo/data/models/request_item_wrapper.dart';
import 'package:hrms_demo/data/models/employee_basic_info.dart';
import 'package:hrms_demo/data/models/investigation_request_model.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_requests_query.dart';
import 'package:flutter/foundation.dart';

@immutable
class UserDisciplinaryActionRequestsState {
  const UserDisciplinaryActionRequestsState({
    this.status = Status.initial,
    this.failure,
    this.requests = const <RequestItem>[],
    this.paged = const PagedSection<RequestItem>(),
    this.query = const DisciplinaryRequestsQuery(scope: DisciplinaryRequestScope.my),
    this.availableMonths = const [],
    this.hasAnyRequests,
    this.employeeHistory = const [],
    this.approveStatus = Status.initial,
    this.declineStatus = Status.initial,
    this.onHoldStatus = Status.initial,
    this.cancelStatus = Status.initial,
    this.investigationStatus = Status.initial,
    this.editStatus = Status.initial,
    this.acknowledgmentStatus = Status.initial,
    this.acknowledgmentActionType,
    this.escalateToLegalStatus = Status.initial,
    this.legalUploadStatus = Status.initial,
    this.legalAcknowledgeStatus = Status.initial,
    this.hrFinalDecisionStatus = Status.initial,
    this.hrFinalActionType,
    this.processingRequestId,
    this.operationFailure,
    this.attachmentSignedUrls,
    this.attachmentUrlsStatus = Status.initial,
    this.investigationDecisionStatus = Status.initial,
    this.bulkCreationStatus = Status.initial,
    this.convertToInvestigationStatus = Status.initial,
    this.employeeInfoMap = const {},
    this.employeeInfoStatus = Status.initial,
    this.linkedDisciplinaryActions = const [],
    this.linkedDisciplinaryActionsStatus = Status.initial,
    this.pdfOpenStatus = Status.initial,
    this.pdfSignedUrl,
    this.fetchedInvestigation,
    this.fetchedInvestigationStatus = Status.initial,
    this.fetchedDisciplinaryAction,
    this.fetchedDisciplinaryActionStatus = Status.initial,
    this.linkedInvestigationId,
    this.linkedInvestigationIdStatus = Status.initial,
  });

  /// Screen-level status. On the paged path this only ever reports the outcome
  /// of the scope-wide reads; page fetches report through
  /// `paged.isPageLoading` / `paged.pageFailure`.
  final Status status;
  final Failure? failure;

  /// LEGACY whole-list rows, merged in Dart from two repos. Populated only when
  /// `FeatureFlags.serverPagedDisciplinaryRequests` is false.
  final List<RequestItem> requests;

  /// The current page window and the rows in it — already interleaved and
  /// ordered by the server across both tables.
  final PagedSection<RequestItem> paged;

  /// Scope + filters + sort the current page was fetched for.
  final DisciplinaryRequestsQuery query;

  /// Months the current scope spans, across both tables.
  final List<DateTime> availableMonths;

  /// Whether the scope has any row at all, ignoring filters. `null` means the
  /// probe has not answered yet, which the empty-state gate reads as "do not
  /// claim empty".
  final bool? hasAnyRequests;

  final List<DisciplinaryActionRequestModel> employeeHistory;
  final Status approveStatus;
  final Status declineStatus;
  final Status onHoldStatus;
  final Status cancelStatus;
  final Status investigationStatus;
  final Status editStatus;
  final Status acknowledgmentStatus;
  final String? acknowledgmentActionType;
  final Status escalateToLegalStatus;
  final Status legalUploadStatus;
  final Status legalAcknowledgeStatus;
  final Status hrFinalDecisionStatus;
  final String? hrFinalActionType;
  final int? processingRequestId;
  final Failure? operationFailure;
  final List<String>? attachmentSignedUrls;
  final Status attachmentUrlsStatus;
  // Investigation operation statuses
  final Status investigationDecisionStatus; // For HR/Legal/TM decision recording
  final Status bulkCreationStatus; // For bulk disciplinary action creation
  final Status convertToInvestigationStatus; // For converting disciplinary action to investigation
  final Map<int, EmployeeBasicInfo> employeeInfoMap; // Employee code -> basic info (name, department)
  final Status employeeInfoStatus; // Loading status for employee info
  final List<DisciplinaryActionRequestModel>
  linkedDisciplinaryActions; // Disciplinary actions linked to an investigation
  final Status linkedDisciplinaryActionsStatus; // Loading status for linked actions
  final Status pdfOpenStatus; // For opening investigation PDFs (storage path → signed URL)
  final String? pdfSignedUrl; // Resolved signed URL for the PDF
  // Fetched investigation for viewing from disciplinary action details
  final InvestigationRequestModel? fetchedInvestigation;
  final Status fetchedInvestigationStatus; // Loading status for fetched investigation
  // Fetched disciplinary action for viewing from investigation details
  final DisciplinaryActionRequestModel? fetchedDisciplinaryAction;
  final Status fetchedDisciplinaryActionStatus;
  // Linked investigation ID resolved from DA ID (for 'converted_to_investigation' case)
  final int? linkedInvestigationId;
  final Status linkedInvestigationIdStatus;

  UserDisciplinaryActionRequestsState copyWith({
    Status? status,
    Failure? failure,
    List<RequestItem>? requests,
    PagedSection<RequestItem>? paged,
    DisciplinaryRequestsQuery? query,
    List<DateTime>? availableMonths,
    bool? hasAnyRequests,
    bool clearHasAnyRequests = false,
    List<DisciplinaryActionRequestModel>? employeeHistory,
    Status? approveStatus,
    Status? declineStatus,
    Status? onHoldStatus,
    Status? cancelStatus,
    Status? investigationStatus,
    Status? editStatus,
    Status? acknowledgmentStatus,
    String? acknowledgmentActionType,
    Status? escalateToLegalStatus,
    Status? legalUploadStatus,
    Status? legalAcknowledgeStatus,
    Status? hrFinalDecisionStatus,
    String? hrFinalActionType,
    int? processingRequestId,
    Failure? operationFailure,
    bool clearProcessingRequestId = false,
    bool clearOperationFailure = false,
    List<String>? attachmentSignedUrls,
    Status? attachmentUrlsStatus,
    bool clearAttachmentUrls = false,
    Status? investigationDecisionStatus,
    Status? bulkCreationStatus,
    Status? convertToInvestigationStatus,
    Map<int, EmployeeBasicInfo>? employeeInfoMap,
    Status? employeeInfoStatus,
    List<DisciplinaryActionRequestModel>? linkedDisciplinaryActions,
    Status? linkedDisciplinaryActionsStatus,
    Status? pdfOpenStatus,
    String? pdfSignedUrl,
    bool clearPdfSignedUrl = false,
    InvestigationRequestModel? fetchedInvestigation,
    Status? fetchedInvestigationStatus,
    bool clearFetchedInvestigation = false,
    DisciplinaryActionRequestModel? fetchedDisciplinaryAction,
    Status? fetchedDisciplinaryActionStatus,
    bool clearFetchedDisciplinaryAction = false,
    int? linkedInvestigationId,
    bool clearLinkedInvestigationId = false,
    Status? linkedInvestigationIdStatus,
  }) {
    return UserDisciplinaryActionRequestsState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      requests: requests ?? this.requests,
      paged: paged ?? this.paged,
      query: query ?? this.query,
      availableMonths: availableMonths ?? this.availableMonths,
      // `??` cannot express "set back to null", and a tab switch needs exactly
      // that — see the doc comment on hasAnyRequests.
      hasAnyRequests: clearHasAnyRequests ? null : (hasAnyRequests ?? this.hasAnyRequests),
      employeeHistory: employeeHistory ?? this.employeeHistory,
      approveStatus: approveStatus ?? this.approveStatus,
      declineStatus: declineStatus ?? this.declineStatus,
      onHoldStatus: onHoldStatus ?? this.onHoldStatus,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      investigationStatus: investigationStatus ?? this.investigationStatus,
      editStatus: editStatus ?? this.editStatus,
      acknowledgmentStatus: acknowledgmentStatus ?? this.acknowledgmentStatus,
      acknowledgmentActionType: acknowledgmentActionType,
      escalateToLegalStatus: escalateToLegalStatus ?? this.escalateToLegalStatus,
      legalUploadStatus: legalUploadStatus ?? this.legalUploadStatus,
      legalAcknowledgeStatus: legalAcknowledgeStatus ?? this.legalAcknowledgeStatus,
      hrFinalDecisionStatus: hrFinalDecisionStatus ?? this.hrFinalDecisionStatus,
      hrFinalActionType: hrFinalActionType,
      processingRequestId: clearProcessingRequestId ? null : (processingRequestId ?? this.processingRequestId),
      operationFailure: clearOperationFailure ? null : (operationFailure ?? this.operationFailure),
      attachmentSignedUrls: clearAttachmentUrls ? null : (attachmentSignedUrls ?? this.attachmentSignedUrls),
      attachmentUrlsStatus: attachmentUrlsStatus ?? this.attachmentUrlsStatus,
      investigationDecisionStatus: investigationDecisionStatus ?? this.investigationDecisionStatus,
      bulkCreationStatus: bulkCreationStatus ?? this.bulkCreationStatus,
      convertToInvestigationStatus: convertToInvestigationStatus ?? this.convertToInvestigationStatus,
      employeeInfoMap: employeeInfoMap ?? this.employeeInfoMap,
      employeeInfoStatus: employeeInfoStatus ?? this.employeeInfoStatus,
      linkedDisciplinaryActions: linkedDisciplinaryActions ?? this.linkedDisciplinaryActions,
      linkedDisciplinaryActionsStatus: linkedDisciplinaryActionsStatus ?? this.linkedDisciplinaryActionsStatus,
      pdfOpenStatus: pdfOpenStatus ?? this.pdfOpenStatus,
      pdfSignedUrl: clearPdfSignedUrl ? null : (pdfSignedUrl ?? this.pdfSignedUrl),
      fetchedInvestigation: clearFetchedInvestigation ? null : (fetchedInvestigation ?? this.fetchedInvestigation),
      fetchedInvestigationStatus: fetchedInvestigationStatus ?? this.fetchedInvestigationStatus,
      fetchedDisciplinaryAction:
          clearFetchedDisciplinaryAction ? null : (fetchedDisciplinaryAction ?? this.fetchedDisciplinaryAction),
      fetchedDisciplinaryActionStatus: fetchedDisciplinaryActionStatus ?? this.fetchedDisciplinaryActionStatus,
      linkedInvestigationId: clearLinkedInvestigationId ? null : (linkedInvestigationId ?? this.linkedInvestigationId),
      linkedInvestigationIdStatus: linkedInvestigationIdStatus ?? this.linkedInvestigationIdStatus,
    );
  }
}
