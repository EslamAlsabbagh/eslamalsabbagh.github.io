import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_request_repo.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_requests_query.dart';
import 'package:hrms_demo/presentation/user_hr_letter_requests/bloc/user_hr_letter_requests_event.dart';
import 'package:hrms_demo/presentation/user_hr_letter_requests/bloc/user_hr_letter_requests_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserHrLetterRequestsBloc extends Bloc<UserHrLetterRequestsEvent, UserHrLetterRequestsState> {
  final HrLetterRequestRepo hrLetterRepo;

  // Track current source type for re-fetching after actions (legacy path).
  HrLetterRequestSourceType? _sourceType;
  int? _userCode;

  /// The scope the screen is currently on, remembered so a mutation refreshes
  /// the list the user is actually looking at. The old code re-derived it from
  /// whichever event happened to fire, which is how the other request blocs
  /// ended up hard-coding `teamRequests` into every refetch.
  HrLetterRequestScope _scope = HrLetterRequestScope.my;

  /// Guards against out-of-order page responses. A fast page-3 → page-4 tap
  /// issues two fetches, and nothing else guarantees they resolve in order —
  /// the table screens got this for free from `AsyncDataTableSource`.
  int _pageSeq = 0;

  UserHrLetterRequestsBloc(this.hrLetterRepo) : super(const UserHrLetterRequestsState()) {
    on<LoadHrLetterRequests>(_onLoadRequests);
    on<InitHrLetterRequests>(_onInit);
    on<HrLetterPageChanged>(_onPageChanged);
    on<HrLetterPageSizeChanged>(_onPageSizeChanged);
    on<HrLetterQueryChanged>(_onQueryChanged);
    on<RefreshHrLetterPage>(_onRefreshPage);
    on<AcknowledgeHrLetterRequest>(_onAcknowledge);
    on<CompleteHrLetterRequest>(_onComplete);
    on<DeclineHrLetterRequest>(_onDecline);
    on<CancelHrLetterRequest>(_onCancel);
    on<ResetAcknowledgeHrLetterStatus>(_onResetAcknowledge);
    on<ResetCompleteHrLetterStatus>(_onResetComplete);
    on<ResetDeclineHrLetterStatus>(_onResetDecline);
    on<ResetCancelHrLetterStatus>(_onResetCancel);
  }

  // ── Server-paged path ──────────────────────────────────────────────────────

  Future<void> _onInit(InitHrLetterRequests event, Emitter<UserHrLetterRequestsState> emit) async {
    _scope = event.scope;
    _userCode = event.userCode;

    // Deliberately NOT Status.loading. That branch blanks the whole screen
    // (user_hr_letter_requests_content.dart), so the filters and tabs vanish
    // and come back, and the first page fetch would be delayed behind these two
    // scope-wide reads rather than running alongside them.
    emit(
      state.copyWith(
        clearHasAnyRequests: true,
        // Filters belong to the tab, not to the screen: switching scope resets
        // them, exactly as the old widget's tab handler did.
        query: HrLetterRequestsQuery(scope: event.scope, locale: state.query.locale),
        // Drops the previous scope's rows — see PagedSection.resetForQuery.
        paged: state.paged.resetForQuery(),
      ),
    );

    try {
      final results = await Future.wait([
        hrLetterRepo.hasAnyRequests(_scope),
        hrLetterRepo.getHrLetterRequestMonths(_scope),
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

    await _loadPage(emit);
  }

  Future<void> _onPageChanged(HrLetterPageChanged event, Emitter<UserHrLetterRequestsState> emit) async {
    // Idempotent, so a rebuild that re-dispatches the current page costs
    // nothing.
    if (event.page == state.paged.page) return;
    emit(state.copyWith(paged: state.paged.copyWith(page: event.page)));
    await _loadPage(emit);
  }

  Future<void> _onPageSizeChanged(HrLetterPageSizeChanged event, Emitter<UserHrLetterRequestsState> emit) async {
    if (event.pageSize == state.paged.pageSize) return;
    // Back to page 0: keeping the index would jump the user an arbitrary
    // distance through the list.
    emit(state.copyWith(paged: state.paged.copyWith(pageSize: event.pageSize, page: 0)));
    await _loadPage(emit);
  }

  Future<void> _onQueryChanged(HrLetterQueryChanged event, Emitter<UserHrLetterRequestsState> emit) async {
    if (event.query == state.query) return;

    final scopeChanged = event.query.scope != state.query.scope;
    // The rows on screen answer the OLD query, so they go — whether the scope
    // changed (tab switch) or only the filters did.
    emit(state.copyWith(query: event.query, paged: state.paged.resetForQuery()));

    if (scopeChanged) {
      _scope = event.query.scope;
      // The month list and the empty-state answer both belong to the scope, so
      // a tab switch has to re-read them. Clearing first stops the previous
      // tab's answer from being shown against the new tab's rows.
      emit(state.copyWith(clearHasAnyRequests: true));
      try {
        final results = await Future.wait([
          hrLetterRepo.hasAnyRequests(_scope),
          hrLetterRepo.getHrLetterRequestMonths(_scope),
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

    await _loadPage(emit);
  }

  Future<void> _onRefreshPage(RefreshHrLetterPage event, Emitter<UserHrLetterRequestsState> emit) =>
      _refreshCurrentPage(emit);

  /// The single page-fetch point.
  Future<void> _loadPage(Emitter<UserHrLetterRequestsState> emit) async {
    final seq = ++_pageSeq;

    // items are NOT cleared here: the cards stay on screen under the spinner
    // instead of the list collapsing and the scroll position jumping to the
    // top. It also keeps the row a mutation is running against visible, so its
    // per-row spinner has something to spin on.
    emit(state.copyWith(paged: state.paged.copyWith(isPageLoading: true, clearPageFailure: true)));

    try {
      final result = await hrLetterRepo.getHrLetterRequestsPage(
        state.query,
        offset: state.paged.offset,
        limit: state.paged.pageSize,
      );
      if (seq != _pageSeq) return; // a newer page won; drop this response
      emit(state.copyWith(paged: state.paged.withResult(result)));
    } catch (e) {
      if (seq != _pageSeq) return;
      emit(state.copyWith(paged: state.paged.copyWith(isPageLoading: false, pageFailure: Failure(e.toString()))));
    }
  }

  /// Re-reads the page the user is looking at after a mutation.
  ///
  /// Never resets to page 1 and never names a scope: both are what made
  /// "approve a request from the Processed tab" silently swap the user to the
  /// Team list in the sibling request blocs.
  Future<void> _refreshCurrentPage(Emitter<UserHrLetterRequestsState> emit) async {
    try {
      // A mutation can empty a month — a cancel is the last row of its month
      // often enough to matter — so the picker is re-read too.
      final months = await hrLetterRepo.getHrLetterRequestMonths(_scope);
      emit(state.copyWith(availableMonths: months));
    } catch (_) {
      // The picker is cosmetic; a failure here must not abort the page refresh.
    }

    await _loadPage(emit);

    // Completing or cancelling the last row of the last page shrinks the result
    // set, so the page the user is on can stop existing. Step back rather than
    // showing an empty list under a live paginator — the card-list equivalent
    // of the tables' PageSyncApproach.goToLast.
    final paged = state.paged;
    if (paged.items.isEmpty && paged.page > 0 && paged.pageFailure == null) {
      emit(state.copyWith(paged: paged.copyWith(page: paged.lastPageIndex.clamp(0, paged.page))));
      await _loadPage(emit);
    }
  }

  // ── Legacy whole-list path ─────────────────────────────────────────────────

  Future<void> _onLoadRequests(LoadHrLetterRequests event, Emitter<UserHrLetterRequestsState> emit) async {
    _sourceType = event.sourceType;
    _userCode = event.userCode;

    emit(state.copyWith(status: Status.loading));
    try {
      final requests =
          event.sourceType == HrLetterRequestSourceType.myRequests
              ? await hrLetterRepo.getMyHrLetterRequests(event.userCode)
              : await hrLetterRepo.getAllHrLetterRequests();

      emit(state.copyWith(status: Status.success, requests: requests));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  /// Re-fetches the whole list using the stored source type and user code.
  Future<void> _reload(Emitter<UserHrLetterRequestsState> emit) async {
    if (_sourceType == null || _userCode == null) return;
    final requests =
        _sourceType == HrLetterRequestSourceType.myRequests
            ? await hrLetterRepo.getMyHrLetterRequests(_userCode!)
            : await hrLetterRepo.getAllHrLetterRequests();
    emit(state.copyWith(status: Status.success, requests: requests));
  }

  /// Whichever refresh the active paging mode calls for.
  Future<void> _refreshAfterMutation(Emitter<UserHrLetterRequestsState> emit) =>
      FeatureFlags.serverPagedHrLetterRequests ? _refreshCurrentPage(emit) : _reload(emit);

  // ── Mutations ──────────────────────────────────────────────────────────────
  //
  // Each marks the ONE row it is working on via processingRequestId, so that
  // card can spin in place. There is no Status.loading here on either path:
  // blanking the screen would remount the list and, on the way back, re-fetch
  // the page on top of the refresh below.

  Future<void> _onAcknowledge(AcknowledgeHrLetterRequest event, Emitter<UserHrLetterRequestsState> emit) async {
    emit(state.copyWith(acknowledgeStatus: Status.loading, processingRequestId: event.requestId));
    try {
      await hrLetterRepo.acknowledgeRequest(event.requestId, event.hrCode);
      await _refreshAfterMutation(emit);
      emit(state.copyWith(acknowledgeStatus: Status.success, clearProcessingRequestId: true));
    } catch (e) {
      emit(
        state.copyWith(
          acknowledgeStatus: Status.failure,
          operationFailure: Failure(e.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  Future<void> _onComplete(CompleteHrLetterRequest event, Emitter<UserHrLetterRequestsState> emit) async {
    emit(state.copyWith(completeStatus: Status.loading, processingRequestId: event.requestId));
    try {
      await hrLetterRepo.completeRequest(event.requestId, event.hrCode);
      await hrLetterRepo.sendCompletionNotification(event.requestId);
      await _refreshAfterMutation(emit);
      emit(state.copyWith(completeStatus: Status.success, clearProcessingRequestId: true));
    } catch (e) {
      emit(
        state.copyWith(
          completeStatus: Status.failure,
          operationFailure: Failure(e.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  Future<void> _onDecline(DeclineHrLetterRequest event, Emitter<UserHrLetterRequestsState> emit) async {
    emit(state.copyWith(declineStatus: Status.loading, processingRequestId: event.requestId));
    try {
      await hrLetterRepo.declineRequest(event.requestId, event.hrCode, event.reason);
      await hrLetterRepo.sendDeclineNotification(event.requestId);
      await _refreshAfterMutation(emit);
      emit(state.copyWith(declineStatus: Status.success, clearProcessingRequestId: true));
    } catch (e) {
      emit(
        state.copyWith(
          declineStatus: Status.failure,
          operationFailure: Failure(e.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  Future<void> _onCancel(CancelHrLetterRequest event, Emitter<UserHrLetterRequestsState> emit) async {
    emit(state.copyWith(cancelStatus: Status.loading, processingRequestId: event.requestId));
    try {
      await hrLetterRepo.cancelRequest(event.requestId);
      await _refreshAfterMutation(emit);
      emit(state.copyWith(cancelStatus: Status.success, clearProcessingRequestId: true));
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

  void _onResetAcknowledge(ResetAcknowledgeHrLetterStatus event, Emitter<UserHrLetterRequestsState> emit) {
    emit(state.copyWith(acknowledgeStatus: Status.initial, clearOperationFailure: true));
  }

  void _onResetComplete(ResetCompleteHrLetterStatus event, Emitter<UserHrLetterRequestsState> emit) {
    emit(state.copyWith(completeStatus: Status.initial, clearOperationFailure: true));
  }

  void _onResetDecline(ResetDeclineHrLetterStatus event, Emitter<UserHrLetterRequestsState> emit) {
    emit(state.copyWith(declineStatus: Status.initial, clearOperationFailure: true));
  }

  void _onResetCancel(ResetCancelHrLetterStatus event, Emitter<UserHrLetterRequestsState> emit) {
    emit(state.copyWith(cancelStatus: Status.initial, clearOperationFailure: true));
  }
}
