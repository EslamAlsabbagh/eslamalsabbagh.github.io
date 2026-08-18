import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/data/models/advance_on_salary_request_model.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_requests_query.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class UserAdvanceOnSalaryRequestsEvent {
  const UserAdvanceOnSalaryRequestsEvent();
}

enum RequestSourceType {
  myRequests,
  teamRequests,
  processedRequests,
  unsettledRequests,
  settledRequests,
  employeeConfirmationRequests,
  financeAcknowledgmentRequests,
}

extension RequestSourceTypeScope on RequestSourceType {
  AdvanceRequestScope get scope => switch (this) {
    RequestSourceType.myRequests => AdvanceRequestScope.my,
    RequestSourceType.teamRequests => AdvanceRequestScope.team,
    RequestSourceType.processedRequests => AdvanceRequestScope.processed,
    RequestSourceType.unsettledRequests => AdvanceRequestScope.unsettled,
    RequestSourceType.settledRequests => AdvanceRequestScope.settled,
    RequestSourceType.employeeConfirmationRequests => AdvanceRequestScope.employeeConfirmation,
    RequestSourceType.financeAcknowledgmentRequests => AdvanceRequestScope.financeAcknowledgment,
  };
}

/// LEGACY whole-list load. Used only when
/// `FeatureFlags.serverPagedAdvanceRequests` is false.
class LoadUserAdvanceOnSalaryRequests extends UserAdvanceOnSalaryRequestsEvent {
  const LoadUserAdvanceOnSalaryRequests(this.userCode, this.sourceType);
  final int userCode;
  final RequestSourceType sourceType;
}

/// Loads what outlives a single page — whether the scope has any rows and which
/// months it spans — then fetches the first page.
class InitAdvanceRequests extends UserAdvanceOnSalaryRequestsEvent {
  const InitAdvanceRequests(this.userCode, this.scope);
  final int userCode;
  final AdvanceRequestScope scope;
}

/// Moves the window. [page] is 0-based.
class AdvancePageChanged extends UserAdvanceOnSalaryRequestsEvent {
  const AdvancePageChanged(this.page);
  final int page;
}

/// Resizes the window and returns to the first page.
class AdvancePageSizeChanged extends UserAdvanceOnSalaryRequestsEvent {
  const AdvancePageSizeChanged(this.pageSize);
  final int pageSize;
}

/// Replaces scope / filters / sort and returns to the first page. A query equal
/// to the current one is dropped, so a rebuild cannot re-issue a fetch.
class AdvanceQueryChanged extends UserAdvanceOnSalaryRequestsEvent {
  const AdvanceQueryChanged(this.query);
  final AdvanceRequestsQuery query;
}

/// Re-fetches the current page without moving the window.
class RefreshAdvancePage extends UserAdvanceOnSalaryRequestsEvent {
  const RefreshAdvancePage();
}

/// The event that populates a screen, whichever paging mode is active.
///
/// Call this rather than picking an event directly, so the entry pages and the
/// in-screen tab switch cannot drift apart.
UserAdvanceOnSalaryRequestsEvent loadAdvanceRequestsEvent(int userCode, RequestSourceType sourceType) =>
    FeatureFlags.serverPagedAdvanceRequests
        ? InitAdvanceRequests(userCode, sourceType.scope)
        : LoadUserAdvanceOnSalaryRequests(userCode, sourceType);

class ApproveAdvanceOnSalaryRequest extends UserAdvanceOnSalaryRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  const ApproveAdvanceOnSalaryRequest(this.requestId, this.currentApprover, this.userCode);
}

class DeclineAdvanceOnSalaryRequest extends UserAdvanceOnSalaryRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  final String reason;

  const DeclineAdvanceOnSalaryRequest(this.requestId, this.currentApprover, this.userCode, this.reason);
}

class LoadUserAdvanceOnSalaryRequestsByMonth extends UserAdvanceOnSalaryRequestsEvent {
  final int userCode;
  final RequestSourceType sourceType;
  final DateTime month;
  const LoadUserAdvanceOnSalaryRequestsByMonth({required this.userCode, required this.sourceType, required this.month});
}

class ResetApproveStatus extends UserAdvanceOnSalaryRequestsEvent {
  const ResetApproveStatus();
}

class ResetDeclineStatus extends UserAdvanceOnSalaryRequestsEvent {
  const ResetDeclineStatus();
}

class LoadUnsettledAdvanceOnSalaryRequests extends UserAdvanceOnSalaryRequestsEvent {
  const LoadUnsettledAdvanceOnSalaryRequests();
}

class SettleAdvanceOnSalaryRequest extends UserAdvanceOnSalaryRequestsEvent {
  final int requestId;
  final String settlerNameArabic;
  final String settlerNameEnglish;
  final int recordedBy;
  const SettleAdvanceOnSalaryRequest(this.requestId, this.settlerNameArabic, this.settlerNameEnglish, this.recordedBy);
}

class ResetSettleStatus extends UserAdvanceOnSalaryRequestsEvent {
  const ResetSettleStatus();
}

class UpdateRequestByFinance extends UserAdvanceOnSalaryRequestsEvent {
  final AdvanceOnSalaryRequestModel request;
  const UpdateRequestByFinance(this.request);
}

class AddUnscheduledPayment extends UserAdvanceOnSalaryRequestsEvent {
  final int requestId;
  final UnscheduledPayment payment;
  final int recordedBy;
  const AddUnscheduledPayment(this.requestId, this.payment, this.recordedBy);
}

class ResetFinanceEditStatus extends UserAdvanceOnSalaryRequestsEvent {
  const ResetFinanceEditStatus();
}

class CancelAdvanceOnSalaryRequest extends UserAdvanceOnSalaryRequestsEvent {
  final int requestId;
  const CancelAdvanceOnSalaryRequest(this.requestId);
}

class ResetCancelStatus extends UserAdvanceOnSalaryRequestsEvent {
  const ResetCancelStatus();
}

class ConfirmFinanceEdit extends UserAdvanceOnSalaryRequestsEvent {
  final int requestId;
  final int employeeCode;
  const ConfirmFinanceEdit(this.requestId, this.employeeCode);
}

class CancelFinanceEdit extends UserAdvanceOnSalaryRequestsEvent {
  final int requestId;
  final int employeeCode;
  const CancelFinanceEdit(this.requestId, this.employeeCode);
}

class AcknowledgeEmployeeDecision extends UserAdvanceOnSalaryRequestsEvent {
  final int requestId;
  final int financeCode;
  const AcknowledgeEmployeeDecision(this.requestId, this.financeCode);
}

class LoadEmployeeConfirmationRequests extends UserAdvanceOnSalaryRequestsEvent {
  final int employeeCode;
  const LoadEmployeeConfirmationRequests(this.employeeCode);
}

class LoadFinanceAcknowledgmentRequests extends UserAdvanceOnSalaryRequestsEvent {
  final int financeCode;
  const LoadFinanceAcknowledgmentRequests(this.financeCode);
}

class ResetEmployeeConfirmationStatus extends UserAdvanceOnSalaryRequestsEvent {
  const ResetEmployeeConfirmationStatus();
}

class ResetFinanceAcknowledgmentStatus extends UserAdvanceOnSalaryRequestsEvent {
  const ResetFinanceAcknowledgmentStatus();
}
