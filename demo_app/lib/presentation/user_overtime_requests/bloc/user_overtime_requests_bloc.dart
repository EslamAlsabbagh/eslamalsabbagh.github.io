import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_request_repo.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_requests_query.dart';
import 'package:hrms_demo/presentation/user_overtime_requests/bloc/user_overtime_requests_event.dart';
import 'package:hrms_demo/presentation/user_overtime_requests/bloc/user_overtime_requests_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserOvertimeRequestsBloc extends Bloc<UserOvertimeRequestsEvent, UserOvertimeRequestsState> {
  UserOvertimeRequestsBloc(this._overtimeRequestRepo) : super(const UserOvertimeRequestsState()) {
    on<InitOvertimeRequests>(_onInitOvertimeRequests);
    on<LoadUserOvertimeRequests>(_onLoadUserOvertimeRequests);
    on<ApproveOvertimeRequest>(_onApproveOvertimeRequest);
    on<DeclineOvertimeRequest>(_onDeclineOvertimeRequest);
    on<LoadUserRequestsByMonth>(_onLoadUserRequestsByMonth);
    on<CancelOvertimeRequest>(_onCancelOvertimeRequest);
    on<RemoveOvertimeRequest>(_onRemoveRequest);
    on<RemoveOvertimeRequestForN1>(_onRemoveRequestForN1);
    on<ResetCancelStatus>(_onResetCancelStatus);
  }

  final OvertimeRequestRepo _overtimeRequestRepo;

  /// The scope the screen is currently showing. Set by [InitOvertimeRequests]
  /// and read by every mutation, so a refresh after an approve re-reads the tab
  /// the user is actually on rather than always the team queue.
  OvertimeRequestScope _scope = OvertimeRequestScope.my;

  /// Loads the two things that describe the whole scope rather than one page:
  /// whether it has any rows at all, and which months it spans. The rows
  /// themselves are fetched by the table's `AsyncDataTableSource`.
  ///
  /// Page data deliberately does NOT flow through the bloc. `getRows` has to
  /// return a value to its caller, and awaiting a state emission for that is
  /// racy the moment two page turns overlap.
  Future<void> _onInitOvertimeRequests(
    InitOvertimeRequests event,
    Emitter<UserOvertimeRequestsState> emit,
  ) async {
    _scope = event.sourceType.scope;
    // Deliberately NOT Status.loading. Entry loading belongs to the table's
    // AsyncDataTableSource, which shows a spinner inside the table box while
    // keeping the AppBar, sidebar, tab switcher and filter bar on screen.
    //
    // hasAnyRequests goes back to "unknown" so a tab switch does not answer the
    // new tab's empty-state question with the previous tab's result.
    emit(state.copyWith(clearHasAnyRequests: true));
    try {
      final results = await Future.wait([
        _overtimeRequestRepo.hasAnyRequests(_scope, event.userCode),
        _overtimeRequestRepo.getOvertimeRequestMonths(_scope),
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
  /// This replaces the old "refetch the entire list, then dispatch a second full
  /// load" pair and the optimistic in-place list edits, none of which can work
  /// when only one page is in memory.
  Future<void> _refreshAfterMutation(Emitter<UserOvertimeRequestsState> emit) async {
    final months = await _overtimeRequestRepo.getOvertimeRequestMonths(_scope);
    emit(state.copyWith(status: Status.success, availableMonths: months, refreshToken: state.refreshToken + 1));
  }

  Future<void> _onLoadUserOvertimeRequests(
    LoadUserOvertimeRequests event,
    Emitter<UserOvertimeRequestsState> emit,
  ) async {
    _scope = event.sourceType.scope;
    emit(state.copyWith(status: Status.loading));
    try {
      final requests = switch (event.sourceType) {
        RequestSourceType.myRequests => await _overtimeRequestRepo.getMyOvertimeRequests(event.userCode),
        RequestSourceType.teamRequests => await _overtimeRequestRepo.getTeamRequests(event.userCode),
        RequestSourceType.processedRequests => await _overtimeRequestRepo.getProcessedRequests(event.userCode),
      };
      emit(state.copyWith(status: Status.success, requests: requests));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onApproveOvertimeRequest(ApproveOvertimeRequest event, Emitter<UserOvertimeRequestsState> emit) async {
    // Paged path marks the ONE row being mutated, so its Approve button can spin
    // in place. Status.loading would blank the whole screen and, on the way back,
    // remount the table — re-fetching the page on top of _refreshAfterMutation.
    emit(
      FeatureFlags.serverPagedOvertimeRequests
          ? state.copyWith(processingRequestId: event.requestId)
          : state.copyWith(status: Status.loading),
    );
    try {
      await _overtimeRequestRepo.approveRequest(event.requestId, event.currentApprover, event.userCode);
      if (FeatureFlags.serverPagedOvertimeRequests) {
        await _refreshAfterMutation(emit);
        emit(state.copyWith(clearProcessingRequestId: true));
      } else {
        final updatedList = await _overtimeRequestRepo.getTeamRequests(event.userCode);
        emit(state.copyWith(requests: updatedList, status: Status.success));
        add(LoadUserOvertimeRequests(event.userCode, RequestSourceType.teamRequests));
      }
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString()), clearProcessingRequestId: true));
    }
  }

  Future<void> _onDeclineOvertimeRequest(DeclineOvertimeRequest event, Emitter<UserOvertimeRequestsState> emit) async {
    emit(
      FeatureFlags.serverPagedOvertimeRequests
          ? state.copyWith(processingRequestId: event.requestId)
          : state.copyWith(status: Status.loading),
    );
    try {
      await _overtimeRequestRepo.declineRequest(
        event.requestId,
        event.reason,
        event.userCode,
        event.currentApprover,
        event.userCode,
      );
      if (FeatureFlags.serverPagedOvertimeRequests) {
        await _refreshAfterMutation(emit);
        emit(state.copyWith(clearProcessingRequestId: true));
      } else {
        final updatedList = await _overtimeRequestRepo.getTeamRequests(event.userCode);
        emit(state.copyWith(requests: updatedList, status: Status.success));
        add(LoadUserOvertimeRequests(event.userCode, RequestSourceType.teamRequests));
      }
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString()), clearProcessingRequestId: true));
    }
  }

  Future<void> _onLoadUserRequestsByMonth(
    LoadUserRequestsByMonth event,
    Emitter<UserOvertimeRequestsState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final requests = await _overtimeRequestRepo.getRequestsByMonth(event.userCode, event.month);
      emit(state.copyWith(status: Status.success, requests: requests));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onCancelOvertimeRequest(CancelOvertimeRequest event, Emitter<UserOvertimeRequestsState> emit) async {
    emit(state.copyWith(cancelStatus: Status.loading, processingRequestId: event.requestId));

    try {
      await _overtimeRequestRepo.cancelRequest(event.requestId);

      if (FeatureFlags.serverPagedOvertimeRequests) {
        // The optimistic in-place edit below cannot work here: state.requests is
        // empty on the paged path, so it would silently do nothing and the row
        // would keep showing its old status until the user changed page.
        emit(state.copyWith(cancelStatus: Status.success, clearProcessingRequestId: true));
        await _refreshAfterMutation(emit);
      } else {
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

  Future<void> _onRemoveRequest(RemoveOvertimeRequest event, Emitter<UserOvertimeRequestsState> emit) async {
    try {
      await _overtimeRequestRepo.removeRequest(event.requestId);

      if (FeatureFlags.serverPagedOvertimeRequests) {
        // Removing the last row of the last page is why the table uses
        // PageSyncApproach.goToLast — the refetch can return fewer pages than
        // the paginator currently believes exist.
        await _refreshAfterMutation(emit);
      } else {
        final updatedRequests = state.requests.where((request) => request.id != event.requestId).toList();
        emit(state.copyWith(requests: updatedRequests));
      }
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onRemoveRequestForN1(RemoveOvertimeRequestForN1 event, Emitter<UserOvertimeRequestsState> emit) async {
    try {
      await _overtimeRequestRepo.removeRequestForN1(event.requestId);

      if (FeatureFlags.serverPagedOvertimeRequests) {
        await _refreshAfterMutation(emit);
      } else {
        final updatedRequests = state.requests.where((request) => request.id != event.requestId).toList();
        emit(state.copyWith(requests: updatedRequests));
      }
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onResetCancelStatus(ResetCancelStatus event, Emitter<UserOvertimeRequestsState> emit) async {
    emit(state.copyWith(cancelStatus: Status.initial));
  }
}
