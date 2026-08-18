import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/bases/paged_section.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/advance_on_salary_request_model.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_requests_query.dart';
import 'package:flutter/foundation.dart';

@immutable
class UserAdvanceOnSalaryRequestsState {
  const UserAdvanceOnSalaryRequestsState({
    this.status = Status.initial,
    this.failure,
    this.requests = const [],
    this.paged = const PagedSection<AdvanceOnSalaryRequestModel>(),
    this.query = const AdvanceRequestsQuery(scope: AdvanceRequestScope.my),
    this.availableMonths = const [],
    this.hasAnyRequests,
    this.approveStatus = Status.initial,
    this.declineStatus = Status.initial,
    this.settleStatus = Status.initial,
    this.financeEditStatus = Status.initial,
    this.cancelStatus = Status.initial,
    this.employeeConfirmationStatus = Status.initial,
    this.financeAcknowledgmentStatus = Status.initial,
    this.processingRequestId,
    this.operationFailure,
  });

  /// Screen-level status. On the paged path this only ever reports the outcome
  /// of the scope-wide reads ([hasAnyRequests] and [availableMonths]); page
  /// fetches report through `paged.isPageLoading` / `paged.pageFailure`, because
  /// `Status.loading` here blanks the whole screen.
  final Status status;
  final Failure? failure;

  /// LEGACY whole-list rows. Populated only when
  /// `FeatureFlags.serverPagedAdvanceRequests` is false; empty on the paged
  /// path, where [paged] holds the current page instead.
  final List<AdvanceOnSalaryRequestModel> requests;

  /// The current page window and the rows in it.
  final PagedSection<AdvanceOnSalaryRequestModel> paged;

  /// Scope + filters + sort the current page was fetched for.
  final AdvanceRequestsQuery query;

  /// Months the current scope spans, for the month picker. Read from the server
  /// rather than derived from the rows in memory, which are now one page.
  final List<DateTime> availableMonths;

  /// Whether the scope has any row at all, ignoring filters.
  ///
  /// Nullable on purpose — `null` is a third state meaning "the probe has not
  /// answered yet", which the empty-state gate reads as "do not claim empty".
  final bool? hasAnyRequests;

  final Status approveStatus;
  final Status declineStatus;
  final Status settleStatus;
  final Status financeEditStatus;
  final Status cancelStatus;
  final Status employeeConfirmationStatus;
  final Status financeAcknowledgmentStatus;
  final int? processingRequestId;
  final Failure? operationFailure;

  UserAdvanceOnSalaryRequestsState copyWith({
    Status? status,
    Failure? failure,
    List<AdvanceOnSalaryRequestModel>? requests,
    PagedSection<AdvanceOnSalaryRequestModel>? paged,
    AdvanceRequestsQuery? query,
    List<DateTime>? availableMonths,
    bool? hasAnyRequests,
    bool clearHasAnyRequests = false,
    Status? approveStatus,
    Status? declineStatus,
    Status? settleStatus,
    Status? financeEditStatus,
    Status? cancelStatus,
    Status? employeeConfirmationStatus,
    Status? financeAcknowledgmentStatus,
    int? processingRequestId,
    Failure? operationFailure,
    bool clearProcessingRequestId = false,
    bool clearOperationFailure = false,
  }) {
    return UserAdvanceOnSalaryRequestsState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      requests: requests ?? this.requests,
      paged: paged ?? this.paged,
      query: query ?? this.query,
      availableMonths: availableMonths ?? this.availableMonths,
      // `??` cannot express "set back to null", and a tab switch needs exactly
      // that — see the doc comment on hasAnyRequests.
      hasAnyRequests: clearHasAnyRequests ? null : (hasAnyRequests ?? this.hasAnyRequests),
      approveStatus: approveStatus ?? this.approveStatus,
      declineStatus: declineStatus ?? this.declineStatus,
      settleStatus: settleStatus ?? this.settleStatus,
      financeEditStatus: financeEditStatus ?? this.financeEditStatus,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      employeeConfirmationStatus: employeeConfirmationStatus ?? this.employeeConfirmationStatus,
      financeAcknowledgmentStatus: financeAcknowledgmentStatus ?? this.financeAcknowledgmentStatus,
      processingRequestId: clearProcessingRequestId ? null : (processingRequestId ?? this.processingRequestId),
      operationFailure: clearOperationFailure ? null : (operationFailure ?? this.operationFailure),
    );
  }
}
