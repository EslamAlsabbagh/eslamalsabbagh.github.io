import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/bases/paged_section.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/hr_letter_request_model.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_requests_query.dart';
import 'package:flutter/foundation.dart';

@immutable
class UserHrLetterRequestsState {
  const UserHrLetterRequestsState({
    this.status = Status.initial,
    this.failure,
    this.requests = const [],
    this.paged = const PagedSection<HrLetterRequestModel>(),
    this.query = const HrLetterRequestsQuery(scope: HrLetterRequestScope.my),
    this.availableMonths = const [],
    this.hasAnyRequests,
    this.acknowledgeStatus = Status.initial,
    this.completeStatus = Status.initial,
    this.declineStatus = Status.initial,
    this.cancelStatus = Status.initial,
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
  /// `FeatureFlags.serverPagedHrLetterRequests` is false; empty on the paged
  /// path, where [paged] holds the current page instead.
  final List<HrLetterRequestModel> requests;

  /// The current page window and the rows in it.
  final PagedSection<HrLetterRequestModel> paged;

  /// Scope + filters + sort the current page was fetched for.
  final HrLetterRequestsQuery query;

  /// Months the current scope spans, for the month picker. Read from the server
  /// rather than derived from the rows in memory, which are now one page.
  final List<DateTime> availableMonths;

  /// Whether the scope has any row at all, ignoring filters.
  ///
  /// Nullable on purpose — `null` is a third state meaning "the probe has not
  /// answered yet", which the empty-state gate reads as "do not claim empty".
  /// Without it, switching tabs flashes "no requests found" over the previous
  /// tab's answer.
  final bool? hasAnyRequests;

  final Status acknowledgeStatus;
  final Status completeStatus;
  final Status declineStatus;
  final Status cancelStatus;

  /// The one row a mutation is running against, so its card can spin in place
  /// instead of the screen blanking.
  final int? processingRequestId;
  final Failure? operationFailure;

  UserHrLetterRequestsState copyWith({
    Status? status,
    Failure? failure,
    List<HrLetterRequestModel>? requests,
    PagedSection<HrLetterRequestModel>? paged,
    HrLetterRequestsQuery? query,
    List<DateTime>? availableMonths,
    bool? hasAnyRequests,
    Status? acknowledgeStatus,
    Status? completeStatus,
    Status? declineStatus,
    Status? cancelStatus,
    int? processingRequestId,
    Failure? operationFailure,
    bool clearHasAnyRequests = false,
    bool clearProcessingRequestId = false,
    bool clearOperationFailure = false,
  }) {
    return UserHrLetterRequestsState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      requests: requests ?? this.requests,
      paged: paged ?? this.paged,
      query: query ?? this.query,
      availableMonths: availableMonths ?? this.availableMonths,
      // `??` cannot express "set back to null", and the tab switch needs
      // exactly that — see the doc comment on hasAnyRequests.
      hasAnyRequests: clearHasAnyRequests ? null : (hasAnyRequests ?? this.hasAnyRequests),
      acknowledgeStatus: acknowledgeStatus ?? this.acknowledgeStatus,
      completeStatus: completeStatus ?? this.completeStatus,
      declineStatus: declineStatus ?? this.declineStatus,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      processingRequestId: clearProcessingRequestId ? null : (processingRequestId ?? this.processingRequestId),
      operationFailure: clearOperationFailure ? null : (operationFailure ?? this.operationFailure),
    );
  }
}
