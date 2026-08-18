import 'package:hrms_demo/core/bases/base_state.dart';
import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/overtime_request_model.dart';

final class UserOvertimeRequestsState extends BaseState {
  const UserOvertimeRequestsState({
    super.status = Status.initial,
    super.failure,
    this.requests = const [],
    this.hasAnyRequests,
    this.availableMonths = const [],
    this.refreshToken = 0,
    this.cancelStatus = Status.initial,
    this.operationFailure,
    this.processingRequestId,
  });

  /// Whole-list rows. Populated only on the legacy, client-paged path
  /// (`FeatureFlags.serverPagedOvertimeRequests == false`); empty otherwise,
  /// because the paged table holds its rows in its own `AsyncDataTableSource`.
  final List<OvertimeRequestModel> requests;

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
  final Failure? operationFailure;

  /// Id of the request currently being mutated, so its row can show a spinner on
  /// the button that was tapped instead of the screen blanking.
  final int? processingRequestId;

  UserOvertimeRequestsState copyWith({
    Status? status,
    Failure? failure,
    List<OvertimeRequestModel>? requests,
    bool? hasAnyRequests,
    bool clearHasAnyRequests = false,
    List<DateTime>? availableMonths,
    int? refreshToken,
    Status? cancelStatus,
    Failure? operationFailure,
    int? processingRequestId,
    bool clearProcessingRequestId = false,
  }) {
    return UserOvertimeRequestsState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      requests: requests ?? this.requests,
      // Needs an explicit clear flag: under the `??` idiom a null argument means
      // "keep", so there would otherwise be no way to put the probe back into
      // its unanswered state on a scope change.
      hasAnyRequests: clearHasAnyRequests ? null : (hasAnyRequests ?? this.hasAnyRequests),
      availableMonths: availableMonths ?? this.availableMonths,
      refreshToken: refreshToken ?? this.refreshToken,
      cancelStatus: cancelStatus ?? this.cancelStatus,
      operationFailure: operationFailure ?? this.operationFailure,
      processingRequestId: clearProcessingRequestId ? null : (processingRequestId ?? this.processingRequestId),
    );
  }

  @override
  List<Object?> get props =>
      super.props..addAll([
        requests,
        hasAnyRequests,
        availableMonths,
        refreshToken,
        cancelStatus,
        operationFailure,
        processingRequestId,
      ]);
}
