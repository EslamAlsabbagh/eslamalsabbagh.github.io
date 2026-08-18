import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunch_requests_query.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class UserMissingpunchRequestsEvent {
  const UserMissingpunchRequestsEvent();
}

enum RequestSourceType { myRequests, teamRequests, processedRequests }

extension RequestSourceTypeScope on RequestSourceType {
  /// The server-side scope this UI source type maps to.
  MissingpunchRequestScope get scope => switch (this) {
    RequestSourceType.myRequests => MissingpunchRequestScope.my,
    RequestSourceType.teamRequests => MissingpunchRequestScope.team,
    RequestSourceType.processedRequests => MissingpunchRequestScope.processed,
  };
}

/// Loads only what outlives a single page: whether the scope has any rows, and
/// which months it spans. The table fetches its own rows through the repo.
///
/// Used on the server-paged path; the legacy path uses
/// [LoadUserMissingpunchRequests].
class InitMissingpunchRequests extends UserMissingpunchRequestsEvent {
  const InitMissingpunchRequests(this.userCode, this.sourceType);
  final int userCode;
  final RequestSourceType sourceType;
}

/// The event that populates a missing-punch screen, whichever paging mode is
/// active. Call this rather than picking an event directly, so the two entry
/// pages and the in-screen tab switch cannot drift apart.
UserMissingpunchRequestsEvent loadMissingpunchRequestsEvent(int userCode, RequestSourceType sourceType) =>
    FeatureFlags.serverPagedMissingpunchRequests
        ? InitMissingpunchRequests(userCode, sourceType)
        : LoadUserMissingpunchRequests(userCode, sourceType);

class LoadUserMissingpunchRequests extends UserMissingpunchRequestsEvent {
  const LoadUserMissingpunchRequests(this.userCode, this.sourceType);
  final int userCode;
  final RequestSourceType sourceType;
}

class ApproveMissingpunchRequest extends UserMissingpunchRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  const ApproveMissingpunchRequest(this.requestId, this.currentApprover, this.userCode);
}

class DeclineMissingpunchRequest extends UserMissingpunchRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  final String reason;

  const DeclineMissingpunchRequest(this.requestId, this.currentApprover, this.userCode, this.reason);
}

class LoadUserMissingPunchRequestsByMonth extends UserMissingpunchRequestsEvent {
  final int userCode;
  final RequestSourceType sourceType;
  final DateTime month;
  const LoadUserMissingPunchRequestsByMonth({required this.userCode, required this.sourceType, required this.month});
}

class CancelMissingpunchRequest extends UserMissingpunchRequestsEvent {
  final int requestId;
  const CancelMissingpunchRequest(this.requestId);
}

class RemoveMissingpunchRequest extends UserMissingpunchRequestsEvent {
  final int requestId;
  RemoveMissingpunchRequest(this.requestId);
}

class RemoveMissingpunchRequestForN1 extends UserMissingpunchRequestsEvent {
  final int requestId;
  RemoveMissingpunchRequestForN1(this.requestId);
}

class ResetCancelStatus extends UserMissingpunchRequestsEvent {
  const ResetCancelStatus();
}
