import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_requests_query.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class UserBusinesstripRequestsEvent {
  const UserBusinesstripRequestsEvent();
}

enum RequestSourceType { myRequests, teamRequests, processedRequests }

extension RequestSourceTypeScope on RequestSourceType {
  /// The server-side scope this UI source type maps to.
  BusinesstripRequestScope get scope => switch (this) {
    RequestSourceType.myRequests => BusinesstripRequestScope.my,
    RequestSourceType.teamRequests => BusinesstripRequestScope.team,
    RequestSourceType.processedRequests => BusinesstripRequestScope.processed,
  };
}

/// Loads only what outlives a single page: whether the scope has any rows, and
/// which months it spans. The table fetches its own rows through the repo.
///
/// Used on the server-paged path; the legacy path uses
/// [LoadUserBusinesstripRequests].
class InitBusinesstripRequests extends UserBusinesstripRequestsEvent {
  const InitBusinesstripRequests(this.userCode, this.sourceType);
  final int userCode;
  final RequestSourceType sourceType;
}

/// The event that populates a business-trip screen, whichever paging mode is
/// active. Call this rather than picking an event directly, so the two entry
/// pages and the in-screen tab switch cannot drift apart.
UserBusinesstripRequestsEvent loadBusinesstripRequestsEvent(int userCode, RequestSourceType sourceType) =>
    FeatureFlags.serverPagedBusinesstripRequests
        ? InitBusinesstripRequests(userCode, sourceType)
        : LoadUserBusinesstripRequests(userCode, sourceType);

class LoadUserBusinesstripRequests extends UserBusinesstripRequestsEvent {
  const LoadUserBusinesstripRequests(this.userCode, this.sourceType);
  final int userCode;
  final RequestSourceType sourceType;
}

class ApproveBusinesstripRequest extends UserBusinesstripRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  final String locale;
  final double? transportationFeeAmount;
  const ApproveBusinesstripRequest(
    this.requestId,
    this.currentApprover,
    this.userCode, {
    this.locale = 'en',
    this.transportationFeeAmount,
  });
}

class DeclineBusinesstripRequest extends UserBusinesstripRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  final String reason;

  const DeclineBusinesstripRequest(this.requestId, this.currentApprover, this.userCode, this.reason);
}

class CancelBusinesstripRequest extends UserBusinesstripRequestsEvent {
  final int requestId;
  const CancelBusinesstripRequest(this.requestId);
}

class RemoveBusinesstripRequest extends UserBusinesstripRequestsEvent {
  final int requestId;
  RemoveBusinesstripRequest(this.requestId);
}

class RemoveBusinesstripRequestForN1 extends UserBusinesstripRequestsEvent {
  final int requestId;
  RemoveBusinesstripRequestForN1(this.requestId);
}

class ResetCancelStatus extends UserBusinesstripRequestsEvent {
  const ResetCancelStatus();
}

class RequestBusinesstripCancellation extends UserBusinesstripRequestsEvent {
  final int originalBusinesstripRequestId;
  final String reason;
  const RequestBusinesstripCancellation(this.originalBusinesstripRequestId, this.reason);
}

class ApproveBusinesstripCancellationRequest extends UserBusinesstripRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  const ApproveBusinesstripCancellationRequest(this.requestId, this.currentApprover, this.userCode);
}

class DeclineBusinesstripCancellationRequest extends UserBusinesstripRequestsEvent {
  final int requestId;
  final String currentApprover;
  final int userCode;
  final String reason;
  const DeclineBusinesstripCancellationRequest(this.requestId, this.currentApprover, this.userCode, this.reason);
}
