import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunch_requests_query.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunching_request_repo.dart';
import 'package:hrms_demo/data/services/same_day_conflict_service.dart';
import 'package:hrms_demo/presentation/user_missingpunch-requests/bloc/user_missingpunch_requests_event.dart';
import 'package:hrms_demo/presentation/user_missingpunch-requests/bloc/user_missingpunch_requests_state.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserMissingpunchRequestsBloc extends Bloc<UserMissingpunchRequestsEvent, UserMissingpunchRequestsState> {
  UserMissingpunchRequestsBloc(this._missingpunchRequestRepo, this._userBloc, this._conflictService)
    : super(const UserMissingpunchRequestsState()) {
    on<InitMissingpunchRequests>(_onInitMissingpunchRequests);
    on<LoadUserMissingpunchRequests>(_onLoadUserMissingpunchRequests);
    on<ApproveMissingpunchRequest>(_onApproveMissingpunchRequest);
    on<DeclineMissingpunchRequest>(_onDeclineMissingpunchRequest);
    on<LoadUserMissingPunchRequestsByMonth>(_onLoadUserMissingPunchRequestsByMonth);
    on<CancelMissingpunchRequest>(_onCancelMissingpunchRequest);
    on<RemoveMissingpunchRequest>(_onRemoveRequest);
    on<RemoveMissingpunchRequestForN1>(_onRemoveRequestForN1);
    on<ResetCancelStatus>(_onResetCancelStatus);
  }

  final MissingpunchingRequestsRepo _missingpunchRequestRepo;
  final UserBloc _userBloc;

  /// Injected rather than self-constructed from `Supabase.instance.client`,
  /// which used to make this bloc untestable without a live Supabase.
  ///
  /// LEGACY path only — on the paged path the overlap is a per-row flag from the
  /// RPC. See [InitMissingpunchRequests].
  final SameDayConflictService _conflictService;

  /// The scope the screen is currently showing. Set by
  /// [InitMissingpunchRequests] and read by every mutation, so a refresh after
  /// an approve re-reads the tab the user is actually on rather than always the
  /// team queue.
  MissingpunchRequestScope _scope = MissingpunchRequestScope.my;

  /// Loads the two things that describe the whole scope rather than one page:
  /// whether it has any rows at all, and which months it spans. The rows
  /// themselves are fetched by the table's `AsyncDataTableSource`.
  ///
  /// Page data deliberately does NOT flow through the bloc. `getRows` has to
  /// return a value to its caller, and awaiting a state emission for that is
  /// racy the moment two page turns overlap.
  Future<void> _onInitMissingpunchRequests(
    InitMissingpunchRequests event,
    Emitter<UserMissingpunchRequestsState> emit,
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
        _missingpunchRequestRepo.hasAnyRequests(_scope, event.userCode),
        _missingpunchRequestRepo.getMissingpunchRequestMonths(_scope),
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
  /// when only one page is in memory. Months are re-read because a removal can
  /// empty a month. Only ever reached after a mutation succeeded, so it also
  /// clears a stale [Status.failure] left by an earlier attempt.
  Future<void> _refreshAfterMutation(Emitter<UserMissingpunchRequestsState> emit) async {
    final months = await _missingpunchRequestRepo.getMissingpunchRequestMonths(_scope);
    emit(state.copyWith(status: Status.success, availableMonths: months, refreshToken: state.refreshToken + 1));
  }

  Future<void> _onLoadUserMissingpunchRequests(
    LoadUserMissingpunchRequests event,
    Emitter<UserMissingpunchRequestsState> emit,
  ) async {
    _scope = event.sourceType.scope;
    emit(state.copyWith(status: Status.loading));
    try {
      final requests = switch (event.sourceType) {
        RequestSourceType.myRequests => await _missingpunchRequestRepo.getMyMissingpunchingRequests(event.userCode),
        RequestSourceType.teamRequests => await _missingpunchRequestRepo.getRequestsToApprove(event.userCode),
        RequestSourceType.processedRequests => await _missingpunchRequestRepo.getProcessedRequests(event.userCode),
      };
      // Only the team/approval view surfaces same-day business-trip overlaps.
      final conflictingRequestIds =
          event.sourceType == RequestSourceType.teamRequests
              ? await _conflictService.missingPunchConflicts(requests)
              : <int>{};
      emit(state.copyWith(status: Status.success, requests: requests, conflictingRequestIds: conflictingRequestIds));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onApproveMissingpunchRequest(
    ApproveMissingpunchRequest event,
    Emitter<UserMissingpunchRequestsState> emit,
  ) async {
    // Paged path marks the ONE row being mutated, so its Approve button can spin
    // in place. Status.loading would blank the whole screen and, on the way back,
    // remount the table — re-fetching the page on top of _refreshAfterMutation.
    emit(
      FeatureFlags.serverPagedMissingpunchRequests
          ? state.copyWith(processingRequestId: event.requestId)
          : state.copyWith(status: Status.loading),
    );
    try {
      await _missingpunchRequestRepo.approveRequest(event.requestId, event.currentApprover, event.userCode);
      if (FeatureFlags.serverPagedMissingpunchRequests) {
        await _refreshAfterMutation(emit);
        emit(state.copyWith(clearProcessingRequestId: true));
      } else {
        final updatedList = await _missingpunchRequestRepo.getRequestsToApprove(event.userCode);
        emit(state.copyWith(requests: updatedList, status: Status.success));
        add(LoadUserMissingpunchRequests(event.userCode, RequestSourceType.teamRequests));
      }
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString()), clearProcessingRequestId: true));
    }
  }

  Future<void> _onDeclineMissingpunchRequest(
    DeclineMissingpunchRequest event,
    Emitter<UserMissingpunchRequestsState> emit,
  ) async {
    emit(
      FeatureFlags.serverPagedMissingpunchRequests
          ? state.copyWith(processingRequestId: event.requestId)
          : state.copyWith(status: Status.loading),
    );
    try {
      await _missingpunchRequestRepo.declineRequest(
        event.requestId,
        event.reason,
        event.currentApprover,
        event.userCode,
      );
      if (FeatureFlags.serverPagedMissingpunchRequests) {
        await _refreshAfterMutation(emit);
        emit(state.copyWith(clearProcessingRequestId: true));
      } else {
        final updatedList = await _missingpunchRequestRepo.getRequestsToApprove(event.userCode);
        emit(state.copyWith(requests: updatedList, status: Status.success));
        add(LoadUserMissingpunchRequests(event.userCode, RequestSourceType.teamRequests));
      }
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString()), clearProcessingRequestId: true));
    }
  }

  Future<void> _onLoadUserMissingPunchRequestsByMonth(
    LoadUserMissingPunchRequestsByMonth event,
    Emitter<UserMissingpunchRequestsState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final requests = await _missingpunchRequestRepo.getRequestsByMonth(event.userCode, event.month);
      emit(state.copyWith(status: Status.success, requests: requests));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onCancelMissingpunchRequest(
    CancelMissingpunchRequest event,
    Emitter<UserMissingpunchRequestsState> emit,
  ) async {
    emit(state.copyWith(cancelStatus: Status.loading, processingRequestId: event.requestId));
    try {
      await _missingpunchRequestRepo.cancelRequest(event.requestId);

      if (FeatureFlags.serverPagedMissingpunchRequests) {
        // The optimistic in-place edit below cannot work here: state.requests is
        // empty on the paged path, so it would silently do nothing and the row
        // would keep showing its old status until the user changed page.
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

      // Fetch fresh user profile after a reasonable delay to get updated missing
      // punch balance. Unrelated to paging: cancelRequest restores the balance
      // server-side and the sidebar reads it from the user profile.
      Future.delayed(const Duration(seconds: 2), () {
        final currentUser = _userBloc.state.user;
        if (currentUser != null) {
          _userBloc.add(LoadUserProfile(currentUser.id!.toString()));
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

  Future<void> _onRemoveRequest(RemoveMissingpunchRequest event, Emitter<UserMissingpunchRequestsState> emit) async {
    try {
      await _missingpunchRequestRepo.removeRequest(event.requestId);

      if (FeatureFlags.serverPagedMissingpunchRequests) {
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

  Future<void> _onRemoveRequestForN1(
    RemoveMissingpunchRequestForN1 event,
    Emitter<UserMissingpunchRequestsState> emit,
  ) async {
    try {
      await _missingpunchRequestRepo.removeRequestForN1(event.requestId);

      if (FeatureFlags.serverPagedMissingpunchRequests) {
        await _refreshAfterMutation(emit);
      } else {
        final updatedRequests = state.requests.where((request) => request.id != event.requestId).toList();
        emit(state.copyWith(requests: updatedRequests));
      }
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  void _onResetCancelStatus(ResetCancelStatus event, Emitter<UserMissingpunchRequestsState> emit) {
    emit(state.copyWith(cancelStatus: Status.initial, operationFailure: null));
  }
}
