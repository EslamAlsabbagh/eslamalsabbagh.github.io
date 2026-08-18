import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_requests_query.dart';
import 'package:flutter/foundation.dart';

/// Which entry page the user opened. Routing only — the Actionable/Processed
/// split inside the team page is a [HrLetterRequestScope], not a source type.
enum HrLetterRequestSourceType { myRequests, teamRequests }

extension HrLetterRequestSourceTypeScope on HrLetterRequestSourceType {
  /// The scope a screen starts on. The team page then switches between
  /// [HrLetterRequestScope.team] and [HrLetterRequestScope.processed] via its
  /// tab, which dispatches a [HrLetterQueryChanged].
  HrLetterRequestScope get defaultScope => switch (this) {
    HrLetterRequestSourceType.myRequests => HrLetterRequestScope.my,
    HrLetterRequestSourceType.teamRequests => HrLetterRequestScope.team,
  };
}

@immutable
sealed class UserHrLetterRequestsEvent {
  const UserHrLetterRequestsEvent();
}

/// LEGACY whole-list load. Used only when
/// `FeatureFlags.serverPagedHrLetterRequests` is false.
class LoadHrLetterRequests extends UserHrLetterRequestsEvent {
  final int userCode;
  final HrLetterRequestSourceType sourceType;
  const LoadHrLetterRequests(this.userCode, this.sourceType);
}

/// Loads what outlives a single page — whether the scope has any rows and which
/// months it spans — then fetches the first page.
class InitHrLetterRequests extends UserHrLetterRequestsEvent {
  final int userCode;
  final HrLetterRequestScope scope;
  const InitHrLetterRequests(this.userCode, this.scope);
}

/// Moves the window. [page] is 0-based.
class HrLetterPageChanged extends UserHrLetterRequestsEvent {
  final int page;
  const HrLetterPageChanged(this.page);
}

/// Resizes the window and returns to the first page.
class HrLetterPageSizeChanged extends UserHrLetterRequestsEvent {
  final int pageSize;
  const HrLetterPageSizeChanged(this.pageSize);
}

/// Replaces scope / filters / sort and returns to the first page. A query equal
/// to the current one is dropped, so a rebuild cannot re-issue a fetch.
class HrLetterQueryChanged extends UserHrLetterRequestsEvent {
  final HrLetterRequestsQuery query;
  const HrLetterQueryChanged(this.query);
}

/// Re-fetches the current page without moving the window.
class RefreshHrLetterPage extends UserHrLetterRequestsEvent {
  const RefreshHrLetterPage();
}

/// The event that populates a screen, whichever paging mode is active.
///
/// Call this rather than picking an event directly, so the two entry pages and
/// the in-screen tab switch cannot drift apart.
UserHrLetterRequestsEvent loadHrLetterRequestsEvent(int userCode, HrLetterRequestSourceType sourceType) =>
    FeatureFlags.serverPagedHrLetterRequests
        ? InitHrLetterRequests(userCode, sourceType.defaultScope)
        : LoadHrLetterRequests(userCode, sourceType);

class AcknowledgeHrLetterRequest extends UserHrLetterRequestsEvent {
  final int requestId;
  final int hrCode;
  const AcknowledgeHrLetterRequest(this.requestId, this.hrCode);
}

class CompleteHrLetterRequest extends UserHrLetterRequestsEvent {
  final int requestId;
  final int hrCode;
  const CompleteHrLetterRequest(this.requestId, this.hrCode);
}

class DeclineHrLetterRequest extends UserHrLetterRequestsEvent {
  final int requestId;
  final int hrCode;
  final String reason;
  const DeclineHrLetterRequest(this.requestId, this.hrCode, this.reason);
}

class CancelHrLetterRequest extends UserHrLetterRequestsEvent {
  final int requestId;
  const CancelHrLetterRequest(this.requestId);
}

class ResetAcknowledgeHrLetterStatus extends UserHrLetterRequestsEvent {
  const ResetAcknowledgeHrLetterStatus();
}

class ResetCompleteHrLetterStatus extends UserHrLetterRequestsEvent {
  const ResetCompleteHrLetterStatus();
}

class ResetDeclineHrLetterStatus extends UserHrLetterRequestsEvent {
  const ResetDeclineHrLetterStatus();
}

class ResetCancelHrLetterStatus extends UserHrLetterRequestsEvent {
  const ResetCancelHrLetterStatus();
}
