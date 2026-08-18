import 'package:bloc/bloc.dart';
import 'package:hrms_demo/core/bases/base_state.dart';
import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/bases/paged_section.dart';
import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/advance_on_salary_request_model.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_requests_query.dart';

part 'settlement_review_event.dart';
part 'settlement_review_state.dart';

class SettlementReviewBloc extends Bloc<SettlementReviewEvent, SettlementReviewState> {
  final AdvanceOnSalaryRequestsRepo _repo;

  /// This screen only ever shows one scope, so unlike the advance-list bloc
  /// there is nothing to remember.
  static const _scope = AdvanceRequestScope.settlementReview;

  /// Guards against out-of-order page responses.
  int _pageSeq = 0;

  SettlementReviewBloc(this._repo) : super(const SettlementReviewState()) {
    on<LoadSettlementReviewRequests>(_onLoadSettlementReviewRequests);
    on<SettlementReviewPageChanged>(_onPageChanged);
    on<SendSettlementNotification>(_onSendSettlementNotification);
    on<SendAllSettlementNotifications>(_onSendAllSettlementNotifications);
    on<SkipSettlementNotification>(_onSkipSettlementNotification);
  }

  Future<void> _onLoadSettlementReviewRequests(
    LoadSettlementReviewRequests event,
    Emitter<SettlementReviewState> emit,
  ) async {
    if (FeatureFlags.serverPagedAdvanceRequests) {
      emit(state.copyWith(status: Status.success, paged: state.paged.copyWith(page: 0)));
      await _loadPage(emit);
      return;
    }

    emit(state.copyWith(status: Status.loading));
    try {
      final requests = await _repo.getSettlementReviewRequests();
      emit(state.copyWith(status: Status.success, requests: requests));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onPageChanged(SettlementReviewPageChanged event, Emitter<SettlementReviewState> emit) async {
    if (event.page == state.paged.page) return;
    emit(state.copyWith(paged: state.paged.copyWith(page: event.page)));
    await _loadPage(emit);
  }

  /// The single page-fetch point.
  Future<void> _loadPage(Emitter<SettlementReviewState> emit) async {
    final seq = ++_pageSeq;

    // items are NOT cleared: the cards stay on screen under the spinner, which
    // also keeps the row a send/skip is running against visible so its own
    // spinner has something to spin on.
    emit(state.copyWith(paged: state.paged.copyWith(isPageLoading: true, clearPageFailure: true)));

    try {
      final result = await _repo.getAdvanceRequestsPage(
        const AdvanceRequestsQuery(
          scope: _scope,
          sortKey: AdvanceRequestSortKey.settlementReadyDate,
          sortAscending: true,
        ),
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

  /// Re-reads the page the user is on, stepping back if it no longer exists.
  ///
  /// Sending or skipping a notification takes the row OUT of this scope, so the
  /// page can shrink under the user — and on the last page it can vanish.
  Future<void> _refreshCurrentPage(Emitter<SettlementReviewState> emit) async {
    await _loadPage(emit);

    final paged = state.paged;
    if (paged.items.isEmpty && paged.page > 0 && paged.pageFailure == null) {
      emit(state.copyWith(paged: paged.copyWith(page: paged.lastPageIndex.clamp(0, paged.page))));
      await _loadPage(emit);
    }
  }

  Future<void> _onSendSettlementNotification(
    SendSettlementNotification event,
    Emitter<SettlementReviewState> emit,
  ) async {
    emit(state.copyWith(sendStatus: Status.loading, processingRequestId: event.requestId));
    try {
      await _repo.sendSettlementNotificationConfirmed(event.requestId, event.financeUserCode);

      if (FeatureFlags.serverPagedAdvanceRequests) {
        // Dropping the row locally would leave the page one row short until the
        // next full reload, and would leave totalCount stale — so the paginator
        // would still offer a page that no longer exists.
        await _refreshCurrentPage(emit);
        emit(state.copyWith(sendStatus: Status.success, clearProcessingRequestId: true));
      } else {
        // Remove the request from the list
        final updatedRequests = state.requests.where((r) => r.id != event.requestId).toList();
        emit(state.copyWith(sendStatus: Status.success, requests: updatedRequests, clearProcessingRequestId: true));
      }
    } catch (e) {
      emit(state.copyWith(sendStatus: Status.failure, failure: Failure(e.toString()), clearProcessingRequestId: true));
    }
  }

  Future<void> _onSendAllSettlementNotifications(
    SendAllSettlementNotifications event,
    Emitter<SettlementReviewState> emit,
  ) async {
    emit(state.copyWith(sendAllStatus: Status.loading));
    try {
      // THE ONE PLACE PAGING CHANGES A WRITE.
      //
      // This used to read `state.requests.map((r) => r.id!)`, which under paging
      // is only the page on screen — so "Send all" would quietly become "send
      // these ten". The ids now come from the server, over the same scope the
      // list pages through.
      final requestIds =
          FeatureFlags.serverPagedAdvanceRequests
              ? await _repo.getAdvanceRequestIds(_scope)
              : state.requests.map((r) => r.id!).toList();

      await _repo.sendAllSettlementNotifications(requestIds, event.financeUserCode);

      if (FeatureFlags.serverPagedAdvanceRequests) {
        emit(state.copyWith(paged: state.paged.copyWith(page: 0)));
        await _loadPage(emit);
        emit(state.copyWith(sendAllStatus: Status.success));
      } else {
        emit(
          state.copyWith(
            sendAllStatus: Status.success,
            requests: [], // Clear all requests
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(sendAllStatus: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onSkipSettlementNotification(
    SkipSettlementNotification event,
    Emitter<SettlementReviewState> emit,
  ) async {
    emit(state.copyWith(skipStatus: Status.loading, processingRequestId: event.requestId));
    try {
      await _repo.skipSettlementNotification(event.requestId, event.financeUserCode);

      if (FeatureFlags.serverPagedAdvanceRequests) {
        await _refreshCurrentPage(emit);
        emit(state.copyWith(skipStatus: Status.success, clearProcessingRequestId: true));
      } else {
        // Remove the request from the list
        final updatedRequests = state.requests.where((r) => r.id != event.requestId).toList();
        emit(state.copyWith(skipStatus: Status.success, requests: updatedRequests, clearProcessingRequestId: true));
      }
    } catch (e) {
      emit(state.copyWith(skipStatus: Status.failure, failure: Failure(e.toString()), clearProcessingRequestId: true));
    }
  }
}
