import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/businesstrip_cancellation_request_model.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_requests_query.dart';
import 'package:hrms_demo/data/repos/businesstrip_cancellation_request/businesstrip_cancellation_request_repo.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/data/services/same_day_conflict_service.dart';
import 'package:hrms_demo/presentation/user_businesstrip_requests/bloc/user_businesstrip_requests_event.dart';
import 'package:hrms_demo/presentation/user_businesstrip_requests/bloc/user_businesstrip_requests_state.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/services/businesstrip_request/businesstrip_approval_workflow_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserBusinesstripRequestsBloc extends Bloc<UserBusinesstripRequestsEvent, UserBusinesstripRequestsState> {
  UserBusinesstripRequestsBloc(
    this._businesstripRequestRepo,
    this._cancellationRepo,
    this._usersRepo,
    this._userBloc,
    this._approvalWorkflow,
    this._conflictService,
  ) : super(const UserBusinesstripRequestsState()) {
    on<InitBusinesstripRequests>(_onInitBusinesstripRequests);
    on<LoadUserBusinesstripRequests>(_onLoadUserBusinesstripRequests);
    on<ApproveBusinesstripRequest>(_onApproveBusinesstripRequest);
    on<DeclineBusinesstripRequest>(_onDeclineBusinesstripRequest);
    on<CancelBusinesstripRequest>(_onCancelBusinesstripRequest);
    on<RemoveBusinesstripRequest>(_onRemoveRequest);
    on<RemoveBusinesstripRequestForN1>(_onRemoveRequestForN1);
    on<ResetCancelStatus>(_onResetCancelStatus);
    on<RequestBusinesstripCancellation>(_onRequestCancellation);
    on<ApproveBusinesstripCancellationRequest>(_onApproveCancellationRequest);
    on<DeclineBusinesstripCancellationRequest>(_onDeclineCancellationRequest);
  }

  final BusinesstripRequestsRepo _businesstripRequestRepo;
  final BusinesstripCancellationRequestsRepo _cancellationRepo;
  final UsersRepo _usersRepo;
  final UserBloc _userBloc;

  /// Injected rather than self-constructed. Both used to be `late final` fields
  /// built from `Supabase.instance.client`, which made this bloc impossible to
  /// unit test — constructing it required a live `Supabase.initialize`.
  final BusinesstripApprovalWorkflowService _approvalWorkflow;
  final SameDayConflictService _conflictService;

  /// Scope of the list currently on screen, remembered so a mutation can
  /// refresh [UserBusinesstripRequestsState.availableMonths] for the right list
  /// without the caller having to pass it back in.
  BusinesstripRequestScope _scope = BusinesstripRequestScope.my;

  /// Loads the two things that describe the whole scope rather than one page:
  /// whether it has any rows at all, and which months it spans. The rows
  /// themselves are fetched by the table's `AsyncDataTableSource`.
  ///
  /// Page data deliberately does NOT flow through the bloc. `getRows` has to
  /// return a value to its caller, and awaiting a state emission for that is
  /// racy the moment two page turns overlap.
  Future<void> _onInitBusinesstripRequests(
    InitBusinesstripRequests event,
    Emitter<UserBusinesstripRequestsState> emit,
  ) async {
    _scope = event.sourceType.scope;
    // Deliberately NOT Status.loading. Entry loading belongs to the table's
    // AsyncDataTableSource, which shows a spinner inside the table box while
    // keeping the AppBar, sidebar, tab switcher and filter bar on screen. A
    // screen-level loading status here would have to be rendered by blanking
    // the whole page, and it would also delay the table's first fetch until
    // these two scope-wide reads resolve instead of running alongside them.
    //
    // hasAnyRequests goes back to "unknown" so a tab switch does not answer the
    // new tab's empty-state question with the previous tab's result.
    emit(state.copyWith(clearHasAnyRequests: true));
    try {
      final results = await Future.wait([
        _businesstripRequestRepo.hasAnyRequests(_scope, event.userCode),
        _businesstripRequestRepo.getBusinesstripRequestMonths(_scope),
      ]);

      emit(
        state.copyWith(
          status: Status.success,
          hasAnyRequests: results[0] as bool,
          availableMonths: results[1] as List<DateTime>,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  /// Re-reads the month list and tells the table to re-fetch the page the user
  /// is currently looking at.
  ///
  /// This replaces the old "refetch the entire list twice" (the previous
  /// approve/decline handlers both refetched and then dispatched a Load event
  /// that refetched again) and the optimistic in-place list edits, neither of
  /// which can work when only one page is in memory. Months are re-read because
  /// a removal can empty a month.
  Future<void> _refreshAfterMutation(Emitter<UserBusinesstripRequestsState> emit) async {
    final months = await _businesstripRequestRepo.getBusinesstripRequestMonths(_scope);
    emit(state.copyWith(status: Status.success, availableMonths: months, refreshToken: state.refreshToken + 1));
  }

  Future<void> _onLoadUserBusinesstripRequests(
    LoadUserBusinesstripRequests event,
    Emitter<UserBusinesstripRequestsState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final requests = switch (event.sourceType) {
        RequestSourceType.myRequests => await _businesstripRequestRepo.getMybusinesstripRequests(event.userCode),
        RequestSourceType.teamRequests => await _businesstripRequestRepo.getRequestsToApprove(event.userCode),
        RequestSourceType.processedRequests => await _businesstripRequestRepo.getProcessedRequests(event.userCode),
      };

      // Load cancellation requests based on source type
      final cancellationRequests = switch (event.sourceType) {
        RequestSourceType.myRequests => await _cancellationRepo.getMyCancellationRequests(event.userCode),
        RequestSourceType.teamRequests => await _cancellationRepo.getCancellationRequestsToApprove(event.userCode),
        RequestSourceType.processedRequests => await _cancellationRepo.getProcessedCancellationRequests(event.userCode),
      };

      // Only the team/approval view surfaces same-day missing-punch overlaps.
      final conflictingRequestIds =
          event.sourceType == RequestSourceType.teamRequests
              ? await _conflictService.businesstripConflicts(requests)
              : <int>{};

      emit(
        state.copyWith(
          status: Status.success,
          requests: requests,
          cancellationRequests: cancellationRequests,
          conflictingRequestIds: conflictingRequestIds,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onApproveBusinesstripRequest(
    ApproveBusinesstripRequest event,
    Emitter<UserBusinesstripRequestsState> emit,
  ) async {
    // Paged path marks the ONE row being mutated, so its Approve button can spin
    // in place. Status.loading would blank the whole screen and, on the way back,
    // remount the table — re-fetching the page on top of _refreshAfterMutation.
    emit(
      FeatureFlags.serverPagedBusinesstripRequests
          ? state.copyWith(processingRequestId: event.requestId)
          : state.copyWith(status: Status.loading),
    );
    try {
      if (event.currentApprover == 'hr') {
        // HR final approval: approve + notify (with PDF for fee-eligible trips).
        await _approvalWorkflow.hrApproveWithNotification(
          event.requestId,
          event.userCode,
          event.locale,
          transportationFeeAmount: event.transportationFeeAmount,
        );
      } else {
        // N+1 / N+2 escalation: repo handles the escalation notification.
        await _businesstripRequestRepo.approveRequest(
          event.requestId,
          event.currentApprover,
          event.userCode,
          transportationFeeAmount: event.transportationFeeAmount,
        );
      }
      if (FeatureFlags.serverPagedBusinesstripRequests) {
        await _refreshAfterMutation(emit);
        emit(state.copyWith(clearProcessingRequestId: true));
      } else {
        final updatedList = await _businesstripRequestRepo.getRequestsToApprove(
          event.userCode,
        ); // or getMyRequests if applicable
        emit(state.copyWith(requests: updatedList, status: Status.success));
        add(LoadUserBusinesstripRequests(event.userCode, RequestSourceType.teamRequests));
      }
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString()), clearProcessingRequestId: true));
    }
  }

  Future<void> _onDeclineBusinesstripRequest(
    DeclineBusinesstripRequest event,
    Emitter<UserBusinesstripRequestsState> emit,
  ) async {
    emit(
      FeatureFlags.serverPagedBusinesstripRequests
          ? state.copyWith(processingRequestId: event.requestId)
          : state.copyWith(status: Status.loading),
    );
    try {
      await _businesstripRequestRepo.declineRequest(
        event.requestId,
        event.reason,
        event.currentApprover,
        event.userCode,
      );
      if (FeatureFlags.serverPagedBusinesstripRequests) {
        await _refreshAfterMutation(emit);
        emit(state.copyWith(clearProcessingRequestId: true));
      } else {
        final updatedList = await _businesstripRequestRepo.getRequestsToApprove(
          event.userCode,
        ); // or getMyRequests if applicable
        emit(state.copyWith(requests: updatedList, status: Status.success));
        add(LoadUserBusinesstripRequests(event.userCode, RequestSourceType.teamRequests));
      }
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString()), clearProcessingRequestId: true));
    }
  }

  Future<void> _onCancelBusinesstripRequest(
    CancelBusinesstripRequest event,
    Emitter<UserBusinesstripRequestsState> emit,
  ) async {
    emit(state.copyWith(cancelStatus: Status.loading, processingRequestId: event.requestId));

    try {
      await _businesstripRequestRepo.cancelRequest(event.requestId);

      if (FeatureFlags.serverPagedBusinesstripRequests) {
        // The optimistic in-place edit below cannot work here: state.requests is
        // empty on the paged path, so it would silently do nothing and the row
        // would keep showing its old status until the user changed page.
        await _refreshAfterMutation(emit);
        emit(state.copyWith(cancelStatus: Status.success, clearProcessingRequestId: true));
      } else {
        // Update local state by marking request as cancelled
        final updatedRequests =
            state.requests.map((request) {
              return request.id == event.requestId ? request.copyWith(cancelled: true) : request;
            }).toList();

        emit(state.copyWith(cancelStatus: Status.success, requests: updatedRequests, clearProcessingRequestId: true));
      }
    } catch (e) {
      emit(
        state.copyWith(
          cancelStatus: Status.failure,
          operationFailure: Failure(e.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  Future<void> _onRemoveRequest(RemoveBusinesstripRequest event, Emitter<UserBusinesstripRequestsState> emit) async {
    try {
      await _businesstripRequestRepo.removeRequest(event.requestId);

      if (FeatureFlags.serverPagedBusinesstripRequests) {
        // Removing the last row of the last page is why the table is configured
        // with PageSyncApproach.goToLast — the refetch below can shrink the
        // total past the current offset.
        await _refreshAfterMutation(emit);
      } else {
        // Remove the request from local state
        final updatedRequests = state.requests.where((request) => request.id != event.requestId).toList();

        emit(state.copyWith(requests: updatedRequests));
      }
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onRemoveRequestForN1(
    RemoveBusinesstripRequestForN1 event,
    Emitter<UserBusinesstripRequestsState> emit,
  ) async {
    try {
      await _businesstripRequestRepo.removeRequestForN1(event.requestId);

      if (FeatureFlags.serverPagedBusinesstripRequests) {
        await _refreshAfterMutation(emit);
      } else {
        // Remove the request from local state
        final updatedRequests = state.requests.where((request) => request.id != event.requestId).toList();

        emit(state.copyWith(requests: updatedRequests));
      }
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onResetCancelStatus(ResetCancelStatus event, Emitter<UserBusinesstripRequestsState> emit) async {
    emit(state.copyWith(cancelStatus: Status.initial, cancellationRequestStatus: Status.initial));
  }

  Future<void> _onRequestCancellation(
    RequestBusinesstripCancellation event,
    Emitter<UserBusinesstripRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        cancellationRequestStatus: Status.loading,
        processingRequestId: event.originalBusinesstripRequestId,
      ),
    );
    try {
      // Get user details for the cancellation request
      final currentUser = _userBloc.state.user;
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Get N+1 code from users repository
      final userDetails = await _usersRepo.getEmployeeById(currentUser.id!);

      final cancellationRequest = BusinesstripCancellationRequestModel(
        originalBusinesstripRequestId: event.originalBusinesstripRequestId,
        userId: currentUser.id!,
        reason: event.reason,
        status: 'pending',
        currentApprover: 'n1',
        n1Code: userDetails.n1,
        n2Code: userDetails.n2,
        createdAt: DateTime.now(),
      );

      await _cancellationRepo.submitCancellationRequest(cancellationRequest);

      if (FeatureFlags.serverPagedBusinesstripRequests) {
        // A new cancellation row lands in the same merged stream the table pages
        // through, so refetching the current page is what makes it appear —
        // there is no local list to append to.
        await _refreshAfterMutation(emit);
        emit(state.copyWith(cancellationRequestStatus: Status.success, clearProcessingRequestId: true));
      } else {
        final updatedRequests = await _businesstripRequestRepo.getMybusinesstripRequests(currentUser.id!);
        final updatedCancellationRequests = await _cancellationRepo.getMyCancellationRequests(currentUser.id!);
        emit(
          state.copyWith(
            cancellationRequestStatus: Status.success,
            clearProcessingRequestId: true,
            requests: updatedRequests,
            cancellationRequests: updatedCancellationRequests,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          cancellationRequestStatus: Status.failure,
          operationFailure: Failure(e.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  Future<void> _onApproveCancellationRequest(
    ApproveBusinesstripCancellationRequest event,
    Emitter<UserBusinesstripRequestsState> emit,
  ) async {
    // Note the SEPARATE processing id: cancellation ids live in their own table,
    // so reusing processingRequestId would make a trip row with the same id spin
    // alongside (or instead of) the cancellation row actually being acted on.
    emit(
      FeatureFlags.serverPagedBusinesstripRequests
          ? state.copyWith(processingCancellationRequestId: event.requestId)
          : state.copyWith(status: Status.loading),
    );
    try {
      await _cancellationRepo.approveCancellationRequest(event.requestId, event.currentApprover, event.userCode);

      if (FeatureFlags.serverPagedBusinesstripRequests) {
        await _refreshAfterMutation(emit);
        emit(state.copyWith(clearProcessingCancellationRequestId: true));
      } else {
        // Reload requests for team view
        final requests = await _businesstripRequestRepo.getRequestsToApprove(event.userCode);
        final cancellationRequests = await _cancellationRepo.getCancellationRequestsToApprove(event.userCode);

        emit(state.copyWith(status: Status.success, requests: requests, cancellationRequests: cancellationRequests));
      }
    } catch (e) {
      emit(
        state.copyWith(
          failure: Failure(e.toString()),
          status: Status.failure,
          clearProcessingCancellationRequestId: true,
        ),
      );
    }
  }

  Future<void> _onDeclineCancellationRequest(
    DeclineBusinesstripCancellationRequest event,
    Emitter<UserBusinesstripRequestsState> emit,
  ) async {
    emit(
      FeatureFlags.serverPagedBusinesstripRequests
          ? state.copyWith(processingCancellationRequestId: event.requestId)
          : state.copyWith(status: Status.loading),
    );
    try {
      await _cancellationRepo.declineCancellationRequest(
        event.requestId,
        event.reason,
        event.currentApprover,
        event.userCode,
      );

      if (FeatureFlags.serverPagedBusinesstripRequests) {
        await _refreshAfterMutation(emit);
        emit(state.copyWith(clearProcessingCancellationRequestId: true));
      } else {
        // Reload the unified requests for team view
        final requests = await _businesstripRequestRepo.getRequestsToApprove(event.userCode);
        final cancellationRequests = await _cancellationRepo.getCancellationRequestsToApprove(event.userCode);

        emit(state.copyWith(status: Status.success, requests: requests, cancellationRequests: cancellationRequests));
      }
    } catch (e) {
      emit(
        state.copyWith(
          failure: Failure(e.toString()),
          status: Status.failure,
          clearProcessingCancellationRequestId: true,
        ),
      );
    }
  }
}
