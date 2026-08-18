import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_requests_query.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class UserOvertimeRequestsEvent {
  const UserOvertimeRequestsEvent();
}

enum RequestSourceType { myRequests, teamRequests, processedRequests }

extension RequestSourceTypeScope on RequestSourceType {
  /// The server-side scope this UI source type maps to.
  OvertimeRequestScope get scope => switch (this) {
    RequestSourceType.myRequests => OvertimeRequestScope.my,
    RequestSourceType.teamRequests => OvertimeRequestScope.team,
    RequestSourceType.processedRequests => OvertimeRequestScope.processed,
  };
}

/// Loads only what outlives a single page: whether the scope has any rows, and
/// which months it spans. The table fetches its own rows through the repo.
///
/// Used on the server-paged path; the legacy path uses
/// [LoadUserOvertimeRequests].
class InitOvertimeRequests extends UserOvertimeRequestsEvent {
  const InitOvertimeRequests(this.userCode, this.sourceType);
  final int userCode;
  final RequestSourceType sourceType;
}

/// The event that populates an overtime screen, whichever paging mode is active.
/// Call this rather than picking an event directly, so the two entry pages and
/// the in-screen tab switch cannot drift apart.
UserOvertimeRequestsEvent loadOvertimeRequestsEvent(int userCode, RequestSourceType sourceType) =>
    FeatureFlags.serverPagedOvertimeRequests
        ? InitOvertimeRequests(userCode, sourceType)
        : LoadUserOvertimeRequests(userCode, sourceType);

class LoadUserOvertimeRequests extends UserOvertimeRequestsEvent {
  const LoadUserOvertimeRequests(this.userCode, this.sourceType);
  final int userCode;
  final RequestSourceType sourceType;
}

class ApproveOvertimeRequest extends UserOvertimeRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  const ApproveOvertimeRequest(this.requestId, this.currentApprover, this.userCode);
}

class DeclineOvertimeRequest extends UserOvertimeRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  final String reason;

  const DeclineOvertimeRequest(this.requestId, this.currentApprover, this.userCode, this.reason);
}

class LoadUserRequestsByMonth extends UserOvertimeRequestsEvent {
  final int userCode;
  final RequestSourceType sourceType;
  final DateTime month;
  LoadUserRequestsByMonth({required this.userCode, required this.sourceType, required this.month});
}

class CancelOvertimeRequest extends UserOvertimeRequestsEvent {
  final int requestId;
  const CancelOvertimeRequest(this.requestId);
}

class RemoveOvertimeRequest extends UserOvertimeRequestsEvent {
  final int requestId;
  RemoveOvertimeRequest(this.requestId);
}

class RemoveOvertimeRequestForN1 extends UserOvertimeRequestsEvent {
  final int requestId;
  RemoveOvertimeRequestForN1(this.requestId);
}

class ResetCancelStatus extends UserOvertimeRequestsEvent {
  const ResetCancelStatus();
}
