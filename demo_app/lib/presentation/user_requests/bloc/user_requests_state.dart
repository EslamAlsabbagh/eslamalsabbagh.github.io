import 'package:hrms_demo/core/bases/base_state.dart';
import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/leave_request_model.dart';
import 'package:hrms_demo/data/models/leave_cancellation_request_model.dart';

final class UserRequestsState extends BaseState {
  const UserRequestsState({
    super.status = Status.initial,
    super.failure,
    this.requests = const [],
    this.cancellationRequests = const [],
    this.hasAnyRequests,
    this.availableMonths = const [],
    this.refreshToken = 0,
    this.cancelStatus = Status.initial,
    this.cancellationRequestStatus = Status.initial,
    this.operationFailure,
    this.processingRequestId,
    this.processingCancellationRequestId,
  });

  /// Whole-list rows. Populated only on the legacy, client-paged path
  /// (`FeatureFlags.serverPagedLeaveRequests == false`); empty otherwise,
  /// because the paged table holds its rows in its own `AsyncDataTableSource`.
  final List<LeaveRequestModel> requests;
  final List<LeaveCancellationRequestModel> cancellationRequests;

  /// Whether the scope has any rows at all, ignoring filters.
  ///
  /// Gates the empty-state screen. Deliberately not derived from the page's
  /// total: that total is filtered, so filtering down to zero would hide the
  /// table *and* the filter bar, leaving the user with no way back.
  ///
  /// `null` means the probe has not answered yet — a THIRD state, not a
  /// defaulted `false`. The screen renders its table while this is null, so
  /// entering the page paints the shell immediately instead of flashing the
  /// "no requests" screen for the duration of the round trip.
  final bool? hasAnyRequests;

  /// First-of-month dates that have at least one row in this scope, for the
  /// month picker's greying-out. Server-computed, unfiltered.
  final List<DateTime> availableMonths;

  /// Bumped after every mutation. The table watches it and asks its data source
  /// to re-fetch the page currently on screen, which keeps the user where they
  /// were instead of resetting to page 1.
  final int refreshToken;

  final Status cancelStatus;
  final Status cancellationRequestStatus;
  final Failure? operationFailure;

  /// Id of the LEAVE request currently being mutated, so its row can show a
  /// spinner on the button that was tapped instead of the screen blanking.
  final int? processingRequestId;

  /// Id of the CANCELLATION request currently being mutated. Separate from
  /// [processingRequestId] because the two are different id spaces — one shared
  /// field would spin a leave row whose id happened to equal a cancellation's.
  final int? processingCancellationRequestId;

  UserRequestsState copyWith({
    Status? status,
    Failure? failure,
    List<LeaveRequestModel>? requests,
    List<LeaveCancellationRequestModel>? cancellationRequests,
    bool? hasAnyRequests,
    bool clearHasAnyRequests = false,
    List<DateTime>? availableMonths,
    int? refreshToken,
    Status? cancelStatus,
    Status? cancellationRequestStatus,
    Failure? operationFailure,
    int? processingRequestId,
    bool clearProcessingRequestId = false,
    int? processingCancellationRequestId,
    bool clearProcessingCancellationRequestId = false,
  }) {
    return UserRequestsState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      requests: requests ?? this.requests,
      cancellationRequests: cancellationRequests ?? this.cancellationRequests,
      hasAnyRequests: clearHasAnyRequests ? null : (hasAnyRequests ?? this.hasAnyRequests),
      availableMonths: availableMonths ?? this.availableMonths,
      refreshToken: refreshToken ?? this.refreshToken,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      cancellationRequestStatus: cancellationRequestStatus ?? this.cancellationRequestStatus,
      operationFailure: operationFailure ?? this.operationFailure,
      processingRequestId: clearProcessingRequestId ? null : (processingRequestId ?? this.processingRequestId),
      processingCancellationRequestId:
          clearProcessingCancellationRequestId
              ? null
              : (processingCancellationRequestId ?? this.processingCancellationRequestId),
    );
  }

  @override
  List<Object?> get props =>
      super.props..addAll([
        requests,
        cancellationRequests,
        hasAnyRequests,
        availableMonths,
        refreshToken,
        cancelStatus,
        cancellationRequestStatus,
        operationFailure,
        processingRequestId,
        processingCancellationRequestId,
      ]);
}
