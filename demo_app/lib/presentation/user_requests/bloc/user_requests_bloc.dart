import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/leave_cancellation_request_model.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_requests_query.dart';
import 'package:hrms_demo/data/repos/leave_cancellation_request/leave_cancellation_request_repo.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/presentation/user_requests/bloc/user_requests_event.dart';
import 'package:hrms_demo/presentation/user_requests/bloc/user_requests_state.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserRequestsBloc extends Bloc<UserRequestsEvent, UserRequestsState> {
  final LeaveRequestsRepo repo;
  final LeaveCancellationRequestsRepo cancellationRepo;
  final UsersRepo usersRepo;
  final UserBloc userBloc;

  /// Scope of the list currently on screen, remembered so a mutation can
  /// refresh [UserRequestsState.availableMonths] for the right list without the
  /// caller having to pass it back in.
  LeaveRequestScope _scope = LeaveRequestScope.my;

  UserRequestsBloc(this.repo, this.cancellationRepo, this.usersRepo, this.userBloc) : super(UserRequestsState()) {
    on<InitUserRequests>(_onInitUserRequests);
    on<LoadUserRequests>(_onLoadUserRequests);
    on<ApproveRequest>(_onApproveRequest);
    on<DeclineRequest>(_onDeclineRequest);
    on<LoadUserRequestsByMonth>(_onLoadUserRequestsByMonth);
    on<CancelRequest>(_onCancelRequest);
    on<RemoveRequest>(_onRemoveRequest);
    on<RemoveRequestForN1>(_onRemoveRequestForN1);
    on<ResetCancelStatus>(_onResetCancelStatus);
    on<RequestCancellation>(_onRequestCancellation);
    on<ApproveCancellationRequest>(_onApproveCancellationRequest);
    on<DeclineCancellationRequest>(_onDeclineCancellationRequest);
  }

  /// Loads the two things that describe the whole scope rather than one page:
  /// whether it has any rows at all, and which months it spans. The rows
  /// themselves are fetched by the table's `AsyncDataTableSource`.
  ///
  /// Page data deliberately does NOT flow through the bloc. `getRows` has to
  /// return a value to its caller, and awaiting a state emission for that is
  /// racy the moment two page turns overlap.
  Future<void> _onInitUserRequests(InitUserRequests event, Emitter<UserRequestsState> emit) async {
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
        repo.hasAnyRequests(_scope, event.userCode),
        repo.getLeaveRequestMonths(_scope),
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
  /// This replaces the old "refetch the entire list" and the optimistic
  /// in-place list edits, neither of which can work when only one page is in
  /// memory. Months are re-read because a removal can empty a month.
  /// Only ever reached after a mutation succeeded, so it also clears a stale
  /// [Status.failure] left by an earlier attempt.
  Future<void> _refreshAfterMutation(Emitter<UserRequestsState> emit) async {
    final months = await repo.getLeaveRequestMonths(_scope);
    emit(state.copyWith(status: Status.success, availableMonths: months, refreshToken: state.refreshToken + 1));
  }

  Future<void> _onLoadUserRequests(LoadUserRequests event, Emitter<UserRequestsState> emit) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final requests = switch (event.sourceType) {
        RequestSourceType.myRequests => await repo.getMyLeaveRequests(event.userCode),
        RequestSourceType.teamRequests => await repo.getRequestsToApprove(event.userCode),
        RequestSourceType.processedRequests => await repo.getProcessedRequests(event.userCode),
      };

      // Load cancellation requests based on source type
      final cancellationRequests = switch (event.sourceType) {
        RequestSourceType.myRequests => await cancellationRepo.getMyCancellationRequests(event.userCode),
        RequestSourceType.teamRequests => await cancellationRepo.getCancellationRequestsToApprove(event.userCode),
        RequestSourceType.processedRequests => await cancellationRepo.getProcessedCancellationRequests(event.userCode),
      };

      emit(state.copyWith(status: Status.success, requests: requests, cancellationRequests: cancellationRequests));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onApproveRequest(ApproveRequest event, Emitter<UserRequestsState> emit) async {
    // Paged path marks the ONE row being mutated, so its Approve button can spin
    // in place. Status.loading would blank the whole screen and, on the way back,
    // remount the table — re-fetching the page on top of _refreshAfterMutation.
    emit(
      FeatureFlags.serverPagedLeaveRequests
          ? state.copyWith(processingRequestId: event.requestId)
          : state.copyWith(status: Status.loading),
    );
    try {
      await repo.approveRequest(event.requestId, event.currentApprover, event.userCode);
      if (FeatureFlags.serverPagedLeaveRequests) {
        await _refreshAfterMutation(emit);
        emit(state.copyWith(clearProcessingRequestId: true));
      } else {
        final updatedList = await repo.getRequestsToApprove(event.userCode); // or getMyRequests if applicable
        emit(state.copyWith(requests: updatedList, status: Status.success));
      }
    } catch (e) {
      emit(state.copyWith(failure: Failure(e.toString()), status: Status.failure, clearProcessingRequestId: true));
    }
  }

  Future<void> _onDeclineRequest(DeclineRequest event, Emitter<UserRequestsState> emit) async {
    emit(
      FeatureFlags.serverPagedLeaveRequests
          ? state.copyWith(processingRequestId: event.requestId)
          : state.copyWith(status: Status.loading),
    );
    try {
      await repo.declineRequest(event.requestId, event.reason, event.currentApprover, event.userCode);
      if (FeatureFlags.serverPagedLeaveRequests) {
        await _refreshAfterMutation(emit);
        emit(state.copyWith(clearProcessingRequestId: true));
      } else {
        final updatedList = await repo.getRequestsToApprove(event.userCode); // or getMyRequests if applicable
        emit(state.copyWith(requests: updatedList, status: Status.success));
      }
    } catch (e) {
      emit(state.copyWith(failure: Failure(e.toString()), status: Status.failure, clearProcessingRequestId: true));
    }
  }

  Future<void> _onLoadUserRequestsByMonth(LoadUserRequestsByMonth event, Emitter<UserRequestsState> emit) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final requests = await repo.getRequestsByMonth(event.userCode, event.month);

      // Load cancellation requests by month for both team and user requests
      final cancellationRequests = await cancellationRepo.getCancellationRequestsByMonth(event.userCode, event.month);

      emit(state.copyWith(status: Status.success, requests: requests, cancellationRequests: cancellationRequests));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onCancelRequest(CancelRequest event, Emitter<UserRequestsState> emit) async {
    emit(state.copyWith(cancelStatus: Status.loading, processingRequestId: event.requestId));
    try {
      await repo.cancelRequest(event.requestId);

      if (FeatureFlags.serverPagedLeaveRequests) {
        emit(state.copyWith(cancelStatus: Status.success, clearProcessingRequestId: true));
        await _refreshAfterMutation(emit);
      } else {
        final updatedRequests =
            state.requests.map((request) {
              if (request.id == event.requestId) {
                return request.copyWith(cancelled: true);
              }
              return request;
            }).toList();

        emit(state.copyWith(cancelStatus: Status.success, requests: updatedRequests, clearProcessingRequestId: true));
      }

      // Fetch fresh user profile after a reasonable delay to get updated balance
      Future.delayed(const Duration(seconds: 2), () {
        final currentUser = userBloc.state.user;
        if (currentUser != null) {
          userBloc.add(LoadUserProfile(currentUser.id!.toString()));
        }
      });
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

  Future<void> _onRemoveRequest(RemoveRequest event, Emitter<UserRequestsState> emit) async {
    try {
      await repo.removeRequest(event.requestId);

      if (FeatureFlags.serverPagedLeaveRequests) {
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

  Future<void> _onRemoveRequestForN1(RemoveRequestForN1 event, Emitter<UserRequestsState> emit) async {
    try {
      await repo.removeRequestForN1(event.requestId);

      if (FeatureFlags.serverPagedLeaveRequests) {
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

  void _onResetCancelStatus(ResetCancelStatus event, Emitter<UserRequestsState> emit) {
    emit(state.copyWith(cancelStatus: Status.initial, operationFailure: null));
  }

  Future<void> _onRequestCancellation(RequestCancellation event, Emitter<UserRequestsState> emit) async {
    emit(state.copyWith(cancellationRequestStatus: Status.loading, processingRequestId: event.originalLeaveRequestId));
    try {
      // Get user details for the cancellation request
      final currentUser = userBloc.state.user;
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }

      // Get N+1 code from users repository
      final userDetails = await usersRepo.getEmployeeById(currentUser.id!);

      final cancellationRequest = LeaveCancellationRequestModel(
        originalLeaveRequestId: event.originalLeaveRequestId,
        userId: currentUser.id!,
        reason: event.reason,
        status: 'pending',
        currentApprover: 'n1',
        n1Code: userDetails.n1,
        n2Code: userDetails.n2,
        createdAt: DateTime.now(),
      );

      await cancellationRepo.submitCancellationRequest(cancellationRequest);

      if (FeatureFlags.serverPagedLeaveRequests) {
        emit(state.copyWith(cancellationRequestStatus: Status.success, clearProcessingRequestId: true));
        await _refreshAfterMutation(emit);
      } else {
        final updatedRequests = await repo.getMyLeaveRequests(currentUser.id!);
        final updatedCancellationRequests = await cancellationRepo.getMyCancellationRequests(currentUser.id!);
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

  Future<void> _onApproveCancellationRequest(ApproveCancellationRequest event, Emitter<UserRequestsState> emit) async {
    // event.requestId is a CANCELLATION id, hence the separate field — see
    // UserRequestsState.processingCancellationRequestId.
    emit(
      FeatureFlags.serverPagedLeaveRequests
          ? state.copyWith(processingCancellationRequestId: event.requestId)
          : state.copyWith(status: Status.loading),
    );
    try {
      await cancellationRepo.approveCancellationRequest(event.requestId, event.currentApprover, event.userCode);

      if (FeatureFlags.serverPagedLeaveRequests) {
        await _refreshAfterMutation(emit);
        emit(state.copyWith(clearProcessingCancellationRequestId: true));
      } else {
        // Reload requests for team view
        final requests = await repo.getRequestsToApprove(event.userCode);
        final cancellationRequests = await cancellationRepo.getCancellationRequestsToApprove(event.userCode);

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

  Future<void> _onDeclineCancellationRequest(DeclineCancellationRequest event, Emitter<UserRequestsState> emit) async {
    emit(
      FeatureFlags.serverPagedLeaveRequests
          ? state.copyWith(processingCancellationRequestId: event.requestId)
          : state.copyWith(status: Status.loading),
    );
    try {
      await cancellationRepo.declineCancellationRequest(
        event.requestId,
        event.reason,
        event.currentApprover,
        event.userCode,
      );

      if (FeatureFlags.serverPagedLeaveRequests) {
        await _refreshAfterMutation(emit);
        emit(state.copyWith(clearProcessingCancellationRequestId: true));
      } else {
        // Reload the unified requests for team view
        final requests = await repo.getRequestsToApprove(event.userCode);
        final cancellationRequests = await cancellationRepo.getCancellationRequestsToApprove(event.userCode);

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
