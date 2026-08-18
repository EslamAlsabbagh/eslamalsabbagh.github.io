import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_requests_query.dart';

abstract class UserRequestsEvent {}

enum RequestSourceType { myRequests, teamRequests, processedRequests }

extension RequestSourceTypeScope on RequestSourceType {
  /// The server-side scope this UI source type maps to.
  LeaveRequestScope get scope => switch (this) {
    RequestSourceType.myRequests => LeaveRequestScope.my,
    RequestSourceType.teamRequests => LeaveRequestScope.team,
    RequestSourceType.processedRequests => LeaveRequestScope.processed,
  };
}

/// Loads only what outlives a single page: whether the scope has any rows, and
/// which months it spans. The table fetches its own rows through the repo.
///
/// Used on the server-paged path; the legacy path uses [LoadUserRequests].
class InitUserRequests extends UserRequestsEvent {
  final int userCode;
  final RequestSourceType sourceType;
  InitUserRequests(this.userCode, this.sourceType);
}

/// The event that populates a leave-requests screen, whichever paging mode is
/// active. Call this rather than picking an event directly, so the two entry
/// pages and the in-screen tab switch cannot drift apart.
UserRequestsEvent loadRequestsEvent(int userCode, RequestSourceType sourceType) =>
    FeatureFlags.serverPagedLeaveRequests
        ? InitUserRequests(userCode, sourceType)
        : LoadUserRequests(userCode, sourceType);

class LoadUserRequests extends UserRequestsEvent {
  final RequestSourceType sourceType;
  LoadUserRequests(this.userCode, this.sourceType);
  final int userCode;
}

class ApproveRequest extends UserRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  ApproveRequest(this.requestId, this.currentApprover, this.userCode);
}

class DeclineRequest extends UserRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  final String reason;

  DeclineRequest(this.requestId, this.currentApprover, this.userCode, this.reason);
}

class LoadUserRequestsByMonth extends UserRequestsEvent {
  final int userCode;
  final RequestSourceType sourceType;
  final DateTime month;
  LoadUserRequestsByMonth({required this.userCode, required this.sourceType, required this.month});
}

class CancelRequest extends UserRequestsEvent {
  final int requestId;
  CancelRequest(this.requestId);
}

class RemoveRequest extends UserRequestsEvent {
  final int requestId;
  RemoveRequest(this.requestId);
}

class RemoveRequestForN1 extends UserRequestsEvent {
  final int requestId;
  RemoveRequestForN1(this.requestId);
}

class ResetCancelStatus extends UserRequestsEvent {}

class RequestCancellation extends UserRequestsEvent {
  final int originalLeaveRequestId;
  final String reason;
  RequestCancellation(this.originalLeaveRequestId, this.reason);
}

class ApproveCancellationRequest extends UserRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  ApproveCancellationRequest(this.requestId, this.currentApprover, this.userCode);
}

class DeclineCancellationRequest extends UserRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  final String reason;
  DeclineCancellationRequest(this.requestId, this.currentApprover, this.userCode, this.reason);
}
