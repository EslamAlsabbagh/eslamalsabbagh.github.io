import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/businesstrip_request_model.dart';
import 'package:hrms_demo/data/models/businesstrip_cancellation_request_model.dart';
import 'package:flutter/foundation.dart';

@immutable
class UserBusinesstripRequestsState {
  const UserBusinesstripRequestsState({
    this.status = Status.initial,
    this.failure,
    this.requests = const [],
    this.cancellationRequests = const [],
    this.cancelStatus = Status.initial,
    this.cancellationRequestStatus = Status.initial,
    this.operationFailure,
    this.processingRequestId,
    this.processingCancellationRequestId,
    this.conflictingRequestIds = const {},
    this.hasAnyRequests,
    this.availableMonths = const [],
    this.refreshToken = 0,
  });

  final Status status;
  final Failure? failure;

  /// Legacy whole-list rows. Empty on the server-paged path — the table owns
  /// its page, the bloc owns only the scope-wide facts below.
  final List<BusinesstripRequestModel> requests;
  final List<BusinesstripCancellationRequestModel> cancellationRequests;

  final Status cancelStatus;
  final Status cancellationRequestStatus;
  final Failure? operationFailure;

  /// Id of the TRIP request currently being mutated, so only that row's buttons
  /// spin. `null` means no trip mutation is in flight.
  final int? processingRequestId;

  /// Id of the CANCELLATION request currently being mutated. A separate field
  /// because the two tables have independent id spaces — trip 5 and
  /// cancellation 5 both exist, and one spinner must not answer for the other.
  final int? processingCancellationRequestId;

  /// Ids of business-trip requests that overlap a same-user missing-punch day.
  /// Populated only for the team/approval view on the LEGACY path; surfaced as
  /// a red row + a warning note in the details dialog. On the paged path the
  /// server sets `BusinesstripRequestModel.hasMissingPunchConflict` per row
  /// instead, because a whole-list scan cannot see rows that are not in memory.
  final Set<int> conflictingRequestIds;

  /// Whether the current scope has any rows at all, ignoring filters.
  ///
  /// Three-valued on purpose: `null` means "not answered yet", which the screen
  /// reads as "assume yes" so it paints the shell on frame 1 rather than
  /// flashing an empty state that a moment later turns out to be wrong.
  final bool? hasAnyRequests;

  /// First-of-month dates the scope spans, for the month picker. Comes from the
  /// server so it can offer months that are not on the current page.
  final List<DateTime> availableMonths;

  /// Bumped after every successful mutation. The screen watches it and asks the
  /// table to re-fetch the page the user is looking at — the paged replacement
  /// for the old "refetch the whole list" and the optimistic in-place edits.
  final int refreshToken;

  UserBusinesstripRequestsState copyWith({
    Status? status,
    Failure? failure,
    List<BusinesstripRequestModel>? requests,
    List<BusinesstripCancellationRequestModel>? cancellationRequests,
    Status? cancelStatus,
    Status? cancellationRequestStatus,
    Failure? operationFailure,
    int? processingRequestId,
    bool clearProcessingRequestId = false,
    int? processingCancellationRequestId,
    bool clearProcessingCancellationRequestId = false,
    Set<int>? conflictingRequestIds,
    bool? hasAnyRequests,
    bool clearHasAnyRequests = false,
    List<DateTime>? availableMonths,
    int? refreshToken,
  }) {
    return UserBusinesstripRequestsState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      requests: requests ?? this.requests,
      cancellationRequests: cancellationRequests ?? this.cancellationRequests,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      cancellationRequestStatus: cancellationRequestStatus ?? this.cancellationRequestStatus,
      operationFailure: operationFailure ?? this.operationFailure,
      // The three nullable fields below need an explicit clear flag: under the
      // `??` idiom a null argument means "keep", so there is otherwise no way to
      // set them back to null.
      processingRequestId: clearProcessingRequestId ? null : (processingRequestId ?? this.processingRequestId),
      processingCancellationRequestId:
          clearProcessingCancellationRequestId
              ? null
              : (processingCancellationRequestId ?? this.processingCancellationRequestId),
      conflictingRequestIds: conflictingRequestIds ?? this.conflictingRequestIds,
      hasAnyRequests: clearHasAnyRequests ? null : (hasAnyRequests ?? this.hasAnyRequests),
      availableMonths: availableMonths ?? this.availableMonths,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}
