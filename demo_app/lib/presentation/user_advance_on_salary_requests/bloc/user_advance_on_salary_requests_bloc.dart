import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/advance_on_salary_request_model.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_requests_query.dart';
import 'package:hrms_demo/services/advance_request/advance_request_workflow_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'user_advance_on_salary_requests_event.dart';
import 'user_advance_on_salary_requests_state.dart';

class UserAdvanceOnSalaryRequestsBloc extends Bloc<UserAdvanceOnSalaryRequestsEvent, UserAdvanceOnSalaryRequestsState> {
  final AdvanceOnSalaryRequestsRepo _advanceOnSalaryRequestRepo;
  final AdvanceRequestWorkflowService? _workflowService;

  /// The scope the screen is currently on, remembered so a mutation refreshes
  /// the list the user is actually looking at.
  ///
  /// This replaces the hard-coded refetch targets every mutation used to carry:
  /// approve, decline and acknowledge all called `getRequestsToApprove`, settle
  /// called `getApprovedUnsettledRequests`, and confirm/cancel finance edit each
  /// called something different again. Acting on a row from the Processed tab
  /// therefore swapped the user to the Team list.
  AdvanceRequestScope _scope = AdvanceRequestScope.my;

  /// Guards against out-of-order page responses.
  int _pageSeq = 0;

  UserAdvanceOnSalaryRequestsBloc(this._advanceOnSalaryRequestRepo, {AdvanceRequestWorkflowService? workflowService})
    : _workflowService = workflowService,
      super(const UserAdvanceOnSalaryRequestsState()) {
    on<InitAdvanceRequests>(_onInitAdvanceRequests);
    on<AdvancePageChanged>(_onPageChanged);
    on<AdvancePageSizeChanged>(_onPageSizeChanged);
    on<AdvanceQueryChanged>(_onQueryChanged);
    on<RefreshAdvancePage>(_onRefreshPage);
    on<LoadUserAdvanceOnSalaryRequests>(_onLoadUserAdvanceOnSalaryRequests);
    on<ApproveAdvanceOnSalaryRequest>(_onApproveAdvanceOnSalaryRequest);
    on<DeclineAdvanceOnSalaryRequest>(_onDeclineAdvanceOnSalaryRequest);
    on<LoadUserAdvanceOnSalaryRequestsByMonth>(_onLoadUserAdvanceOnSalaryRequestsByMonth);
    on<ResetApproveStatus>(_onResetApproveStatus);
    on<ResetDeclineStatus>(_onResetDeclineStatus);
    on<LoadUnsettledAdvanceOnSalaryRequests>(_onLoadUnsettledAdvanceOnSalaryRequests);
    on<SettleAdvanceOnSalaryRequest>(_onSettleAdvanceOnSalaryRequest);
    on<ResetSettleStatus>(_onResetSettleStatus);
    on<UpdateRequestByFinance>(_onUpdateRequestByFinance);
    on<AddUnscheduledPayment>(_onAddUnscheduledPayment);
    on<ResetFinanceEditStatus>(_onResetFinanceEditStatus);
    on<CancelAdvanceOnSalaryRequest>(_onCancelAdvanceOnSalaryRequest);
    on<ResetCancelStatus>(_onResetCancelStatus);
    on<ConfirmFinanceEdit>(_onConfirmFinanceEdit);
    on<CancelFinanceEdit>(_onCancelFinanceEdit);
    on<AcknowledgeEmployeeDecision>(_onAcknowledgeEmployeeDecision);
    on<LoadEmployeeConfirmationRequests>(_onLoadEmployeeConfirmationRequests);
    on<LoadFinanceAcknowledgmentRequests>(_onLoadFinanceAcknowledgmentRequests);
    on<ResetEmployeeConfirmationStatus>(_onResetEmployeeConfirmationStatus);
    on<ResetFinanceAcknowledgmentStatus>(_onResetFinanceAcknowledgmentStatus);
  }

  // ── Server-paged path ──────────────────────────────────────────────────────

  Future<void> _onInitAdvanceRequests(InitAdvanceRequests event, Emitter<UserAdvanceOnSalaryRequestsState> emit) async {
    _scope = event.scope;

    // Deliberately NOT Status.loading: that branch blanks the whole screen, so
    // the tabs and filters vanish and come back, and the first page fetch would
    // be delayed behind these two scope-wide reads rather than running with them.
    emit(
      state.copyWith(
        clearHasAnyRequests: true,
        // Filters belong to the tab. The SORT does not: every tab starts on the
        // query's own default, `created_at DESC`.
        //
        // An earlier version of this seeded a per-tab sort from each repo
        // method's ORDER BY — getRequestsToApprove used `created_at ASC`,
        // getApprovedUnsettledRequests used `updated_payment_end_date ASC`, and
        // so on. That was wrong: those orders never reached the screen. The
        // widget re-sorted the whole list afterwards in
        // _filteredAndSortedRequests, defaulting to _sortBy = 'createdAt' with
        // _sortAscending = false, so what users have always seen on EVERY tab is
        // newest-first. Reproducing the repo's ORDER BY reversed the Actionable
        // tab.
        query: AdvanceRequestsQuery(scope: event.scope, locale: state.query.locale),
        // Drops the previous tab's rows — see PagedSection.resetForQuery. The
        // tab switch routes through here (the content widget's SegmentedButton
        // calls _refreshRequests, which dispatches InitAdvanceRequests).
        paged: state.paged.resetForQuery(),
      ),
    );

    await _loadScopeFacts(emit);
    await _loadPage(emit);
  }

  Future<void> _loadScopeFacts(Emitter<UserAdvanceOnSalaryRequestsState> emit) async {
    try {
      final results = await Future.wait([
        _advanceOnSalaryRequestRepo.hasAnyRequests(_scope),
        _advanceOnSalaryRequestRepo.getAdvanceRequestMonths(_scope),
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

  Future<void> _onPageChanged(AdvancePageChanged event, Emitter<UserAdvanceOnSalaryRequestsState> emit) async {
    // Idempotent, so a rebuild that re-dispatches the current page costs nothing.
    if (event.page == state.paged.page) return;
    emit(state.copyWith(paged: state.paged.copyWith(page: event.page)));
    await _loadPage(emit);
  }

  Future<void> _onPageSizeChanged(AdvancePageSizeChanged event, Emitter<UserAdvanceOnSalaryRequestsState> emit) async {
    if (event.pageSize == state.paged.pageSize) return;
    emit(state.copyWith(paged: state.paged.copyWith(pageSize: event.pageSize, page: 0)));
    await _loadPage(emit);
  }

  Future<void> _onQueryChanged(AdvanceQueryChanged event, Emitter<UserAdvanceOnSalaryRequestsState> emit) async {
    if (event.query == state.query) return;

    final scopeChanged = event.query.scope != state.query.scope;
    // The rows on screen answer the OLD query, so they go — whether the scope
    // changed or only the filters did.
    emit(state.copyWith(query: event.query, paged: state.paged.resetForQuery()));

    if (scopeChanged) {
      _scope = event.query.scope;
      // The month list and the empty-state answer both belong to the scope.
      // Clearing first stops the previous tab's answer showing against the new
      // tab's rows.
      emit(state.copyWith(clearHasAnyRequests: true));
      await _loadScopeFacts(emit);
    }

    await _loadPage(emit);
  }

  Future<void> _onRefreshPage(RefreshAdvancePage event, Emitter<UserAdvanceOnSalaryRequestsState> emit) =>
      _refreshCurrentPage(emit);

  /// The single page-fetch point.
  Future<void> _loadPage(Emitter<UserAdvanceOnSalaryRequestsState> emit) async {
    final seq = ++_pageSeq;

    // items are NOT cleared: the cards stay on screen under the spinner instead
    // of the list collapsing and the scroll position jumping to the top. It also
    // keeps the row a mutation is running against visible, so its per-row
    // spinner has something to spin on.
    emit(state.copyWith(paged: state.paged.copyWith(isPageLoading: true, clearPageFailure: true)));

    try {
      final result = await _advanceOnSalaryRequestRepo.getAdvanceRequestsPage(
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
  /// Never resets to page 1 and never names a scope.
  Future<void> _refreshCurrentPage(Emitter<UserAdvanceOnSalaryRequestsState> emit) async {
    try {
      // A mutation can empty a month, so the picker is re-read too.
      final months = await _advanceOnSalaryRequestRepo.getAdvanceRequestMonths(_scope);
      emit(state.copyWith(availableMonths: months));
    } catch (_) {
      // The picker is cosmetic; a failure here must not abort the page refresh.
    }

    await _loadPage(emit);

    // A settle, cancel or acknowledge can move the row out of the scope
    // entirely, shrinking the result set — so the page the user is on can stop
    // existing. Step back rather than showing an empty list under a live
    // paginator; the card-list equivalent of PageSyncApproach.goToLast.
    final paged = state.paged;
    if (paged.items.isEmpty && paged.page > 0 && paged.pageFailure == null) {
      emit(state.copyWith(paged: paged.copyWith(page: paged.lastPageIndex.clamp(0, paged.page))));
      await _loadPage(emit);
    }
  }

  /// Whichever refresh the active paging mode calls for.
  ///
  /// On the paged path [legacyFetch] is never called — which matters, because
  /// several of those fetches name a scope that has nothing to do with the tab
  /// the user is on.
  Future<void> _refreshAfterMutation(
    Emitter<UserAdvanceOnSalaryRequestsState> emit,
    Future<List<AdvanceOnSalaryRequestModel>> Function() legacyFetch,
  ) async {
    if (FeatureFlags.serverPagedAdvanceRequests) {
      await _refreshCurrentPage(emit);
    } else {
      emit(state.copyWith(requests: await legacyFetch()));
    }
  }

  // ── Legacy whole-list path ─────────────────────────────────────────────────

  Future<void> _onLoadUserAdvanceOnSalaryRequests(
    LoadUserAdvanceOnSalaryRequests event,
    Emitter<UserAdvanceOnSalaryRequestsState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final requests = switch (event.sourceType) {
        RequestSourceType.myRequests => await _advanceOnSalaryRequestRepo.getMyAdvanceOnSalaryRequests(event.userCode),
        RequestSourceType.teamRequests => await _advanceOnSalaryRequestRepo.getRequestsToApprove(event.userCode),
        RequestSourceType.processedRequests => await _advanceOnSalaryRequestRepo.getProcessedRequests(event.userCode),
        RequestSourceType.unsettledRequests => await _advanceOnSalaryRequestRepo.getApprovedUnsettledRequests(),
        RequestSourceType.settledRequests => await _advanceOnSalaryRequestRepo.getApprovedSettledRequests(),
        RequestSourceType.employeeConfirmationRequests => await _advanceOnSalaryRequestRepo
            .getRequestsNeedingEmployeeConfirmation(event.userCode),
        RequestSourceType.financeAcknowledgmentRequests => await _advanceOnSalaryRequestRepo
            .getRequestsNeedingFinanceAcknowledgment(event.userCode),
      };

      emit(state.copyWith(status: Status.success, requests: requests));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onApproveAdvanceOnSalaryRequest(
    ApproveAdvanceOnSalaryRequest event,
    Emitter<UserAdvanceOnSalaryRequestsState> emit,
  ) async {
    emit(
      state.copyWith(approveStatus: Status.loading, processingRequestId: event.requestId, clearOperationFailure: true),
    );

    try {
      // If finance approval and workflow service is available, use it to generate PDF
      if (event.currentApprover == 'finance' && _workflowService != null) {
        await _workflowService.financeApproveWithPDFWorkflow(
          event.requestId,
          event.userCode,
          'en', // locale
        );
      } else {
        // For n2 and hr approvals, use basic approval (no PDF generation)
        await _advanceOnSalaryRequestRepo.approveRequest(event.requestId, event.currentApprover, event.userCode);
      }

      await _refreshAfterMutation(emit, () => _advanceOnSalaryRequestRepo.getRequestsToApprove(event.userCode));
      emit(state.copyWith(approveStatus: Status.success, clearProcessingRequestId: true));
    } catch (e) {
      emit(
        state.copyWith(
          approveStatus: Status.failure,
          operationFailure: Failure(e.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  Future<void> _onDeclineAdvanceOnSalaryRequest(
    DeclineAdvanceOnSalaryRequest event,
    Emitter<UserAdvanceOnSalaryRequestsState> emit,
  ) async {
    emit(
      state.copyWith(declineStatus: Status.loading, processingRequestId: event.requestId, clearOperationFailure: true),
    );

    try {
      await _advanceOnSalaryRequestRepo.declineRequest(
        event.requestId,
        event.reason,
        event.currentApprover,
        event.userCode,
      );

      await _refreshAfterMutation(emit, () => _advanceOnSalaryRequestRepo.getRequestsToApprove(event.userCode));
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

  Future<void> _onLoadUserAdvanceOnSalaryRequestsByMonth(
    LoadUserAdvanceOnSalaryRequestsByMonth event,
    Emitter<UserAdvanceOnSalaryRequestsState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final requests =
          event.sourceType == RequestSourceType.myRequests
              ? await _advanceOnSalaryRequestRepo.getRequestsByMonth(event.userCode, event.month)
              : await _advanceOnSalaryRequestRepo.getRequestsToApprove(event.userCode);

      emit(state.copyWith(status: Status.success, requests: requests));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  void _onResetApproveStatus(ResetApproveStatus event, Emitter<UserAdvanceOnSalaryRequestsState> emit) {
    emit(state.copyWith(approveStatus: Status.initial, clearOperationFailure: true));
  }

  void _onResetDeclineStatus(ResetDeclineStatus event, Emitter<UserAdvanceOnSalaryRequestsState> emit) {
    emit(state.copyWith(declineStatus: Status.initial, clearOperationFailure: true));
  }

  Future<void> _onLoadUnsettledAdvanceOnSalaryRequests(
    LoadUnsettledAdvanceOnSalaryRequests event,
    Emitter<UserAdvanceOnSalaryRequestsState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final requests = await _advanceOnSalaryRequestRepo.getApprovedUnsettledRequests();
      emit(state.copyWith(status: Status.success, requests: requests));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onSettleAdvanceOnSalaryRequest(
    SettleAdvanceOnSalaryRequest event,
    Emitter<UserAdvanceOnSalaryRequestsState> emit,
  ) async {
    emit(
      state.copyWith(settleStatus: Status.loading, processingRequestId: event.requestId, clearOperationFailure: true),
    );

    try {
      // 1. Settle the request
      await _advanceOnSalaryRequestRepo.settleAdvanceRequest(
        event.requestId,
        event.settlerNameArabic,
        event.settlerNameEnglish,
        event.recordedBy,
      );

      // 2. Regenerate PDF with settlement data (BEFORE sending notification)
      await _regeneratePDF(event.requestId);

      // 3. Send settlement notification (email fetches updated PDF from storage)
      try {
        await _advanceOnSalaryRequestRepo.sendSettlementNotification(event.requestId);
      } catch (notificationError) {
        // Silently ignore notification errors - settlement should succeed even if notification fails
      }

      // 4. Refresh. Settling moves the row from Unsettled to Settled, so this
      //    genuinely changes which rows the current scope contains.
      await _refreshAfterMutation(emit, () => _advanceOnSalaryRequestRepo.getApprovedUnsettledRequests());
      emit(state.copyWith(settleStatus: Status.success, clearProcessingRequestId: true));
    } catch (e) {
      emit(
        state.copyWith(
          settleStatus: Status.failure,
          operationFailure: Failure(e.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  void _onResetSettleStatus(ResetSettleStatus event, Emitter<UserAdvanceOnSalaryRequestsState> emit) {
    emit(state.copyWith(settleStatus: Status.initial, clearOperationFailure: true));
  }

  Future<void> _onUpdateRequestByFinance(
    UpdateRequestByFinance event,
    Emitter<UserAdvanceOnSalaryRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        financeEditStatus: Status.loading,
        processingRequestId: event.request.id,
        clearOperationFailure: true,
      ),
    );

    try {
      await _advanceOnSalaryRequestRepo.updateRequestByFinance(event.request);

      // Paged path: re-read rather than patching the row with event.request.
      //
      // The row may not be in `items` at all, so the patch would silently do
      // nothing. And even where it is, `event.request` is stale on exactly the
      // fields the card renders: updateRequestByFinance recomputes
      // updated_monthly_payment, updated_payment_end_date and
      // requires_employee_confirmation server-side. The legacy patch below is
      // left as it was — its staleness is masked by the next tab switch, and
      // "fix it everywhere" is a separate change.
      if (FeatureFlags.serverPagedAdvanceRequests) {
        await _refreshCurrentPage(emit);
        emit(state.copyWith(financeEditStatus: Status.success, clearProcessingRequestId: true));
      } else {
        final updatedRequests =
            state.requests.map((request) {
              if (request.id == event.request.id) {
                return event.request;
              }
              return request;
            }).toList();

        emit(
          state.copyWith(financeEditStatus: Status.success, requests: updatedRequests, clearProcessingRequestId: true),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          financeEditStatus: Status.failure,
          operationFailure: Failure(e.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  Future<void> _onAddUnscheduledPayment(
    AddUnscheduledPayment event,
    Emitter<UserAdvanceOnSalaryRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        financeEditStatus: Status.loading,
        processingRequestId: event.requestId,
        clearOperationFailure: true,
      ),
    );

    try {
      // Add unscheduled payment
      await _advanceOnSalaryRequestRepo.addUnscheduledPayment(event.requestId, event.payment, event.recordedBy);

      // Regenerate PDF with updated payment data
      await _regeneratePDF(event.requestId);

      // Paged path: the payload already carries each row's payments, and adding
      // one changes the remaining amount — which decides whether the row still
      // belongs in the Unsettled scope at all. A patch cannot express "this row
      // has moved to another tab".
      if (FeatureFlags.serverPagedAdvanceRequests) {
        await _refreshCurrentPage(emit);
        emit(state.copyWith(financeEditStatus: Status.success, clearProcessingRequestId: true));
      } else {
        // Refresh the unscheduled payments for this request
        final unscheduledPayments = await _advanceOnSalaryRequestRepo.getUnscheduledPayments(event.requestId);

        // Update the request in the current list with the new unscheduled payments
        final updatedRequests =
            state.requests.map((request) {
              if (request.id == event.requestId) {
                return request.copyWith(unscheduledPayments: unscheduledPayments);
              }
              return request;
            }).toList();

        emit(
          state.copyWith(financeEditStatus: Status.success, requests: updatedRequests, clearProcessingRequestId: true),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          financeEditStatus: Status.failure,
          operationFailure: Failure(e.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  void _onResetFinanceEditStatus(ResetFinanceEditStatus event, Emitter<UserAdvanceOnSalaryRequestsState> emit) {
    emit(state.copyWith(financeEditStatus: Status.initial, clearOperationFailure: true));
  }

  Future<void> _onCancelAdvanceOnSalaryRequest(
    CancelAdvanceOnSalaryRequest event,
    Emitter<UserAdvanceOnSalaryRequestsState> emit,
  ) async {
    emit(state.copyWith(cancelStatus: Status.loading, processingRequestId: event.requestId));

    try {
      await _advanceOnSalaryRequestRepo.cancelRequest(event.requestId);

      // Paged path: a cancel can move the row out of the current scope entirely
      // (out of Team, into Processed), which an in-place `cancelled: true`
      // cannot express — and on the paged path `state.requests` is empty, so the
      // map below would do nothing at all.
      if (FeatureFlags.serverPagedAdvanceRequests) {
        await _refreshCurrentPage(emit);
        emit(state.copyWith(cancelStatus: Status.success, clearProcessingRequestId: true));
      } else {
        // Update the request in the current list to mark it as cancelled
        final updatedRequests =
            state.requests.map((request) {
              if (request.id == event.requestId) {
                return request.copyWith(cancelled: true);
              }
              return request;
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

  void _onResetCancelStatus(ResetCancelStatus event, Emitter<UserAdvanceOnSalaryRequestsState> emit) {
    emit(state.copyWith(cancelStatus: Status.initial, clearOperationFailure: true));
  }

  Future<void> _onConfirmFinanceEdit(ConfirmFinanceEdit event, Emitter<UserAdvanceOnSalaryRequestsState> emit) async {
    emit(
      state.copyWith(
        employeeConfirmationStatus: Status.loading,
        processingRequestId: event.requestId,
        clearOperationFailure: true,
      ),
    );

    try {
      await _advanceOnSalaryRequestRepo.confirmFinanceEdit(event.requestId, event.employeeCode);

      await _refreshAfterMutation(
        emit,
        () => _advanceOnSalaryRequestRepo.getMyAdvanceOnSalaryRequests(event.employeeCode),
      );
      emit(state.copyWith(employeeConfirmationStatus: Status.success, clearProcessingRequestId: true));
    } catch (e) {
      emit(
        state.copyWith(
          employeeConfirmationStatus: Status.failure,
          operationFailure: Failure(e.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  Future<void> _onCancelFinanceEdit(CancelFinanceEdit event, Emitter<UserAdvanceOnSalaryRequestsState> emit) async {
    emit(
      state.copyWith(
        employeeConfirmationStatus: Status.loading,
        processingRequestId: event.requestId,
        clearOperationFailure: true,
      ),
    );

    try {
      await _advanceOnSalaryRequestRepo.cancelFinanceEdit(event.requestId, event.employeeCode);

      await _refreshAfterMutation(
        emit,
        () => _advanceOnSalaryRequestRepo.getRequestsNeedingEmployeeConfirmation(event.employeeCode),
      );
      emit(state.copyWith(employeeConfirmationStatus: Status.success, clearProcessingRequestId: true));
    } catch (e) {
      emit(
        state.copyWith(
          employeeConfirmationStatus: Status.failure,
          operationFailure: Failure(e.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  Future<void> _onAcknowledgeEmployeeDecision(
    AcknowledgeEmployeeDecision event,
    Emitter<UserAdvanceOnSalaryRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        financeAcknowledgmentStatus: Status.loading,
        processingRequestId: event.requestId,
        clearOperationFailure: true,
      ),
    );

    try {
      await _advanceOnSalaryRequestRepo.acknowledgeEmployeeDecision(event.requestId, event.financeCode);

      await _refreshAfterMutation(emit, () => _advanceOnSalaryRequestRepo.getRequestsToApprove(event.financeCode));
      emit(state.copyWith(financeAcknowledgmentStatus: Status.success, clearProcessingRequestId: true));
    } catch (e) {
      emit(
        state.copyWith(
          financeAcknowledgmentStatus: Status.failure,
          operationFailure: Failure(e.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  Future<void> _onLoadEmployeeConfirmationRequests(
    LoadEmployeeConfirmationRequests event,
    Emitter<UserAdvanceOnSalaryRequestsState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final requests = await _advanceOnSalaryRequestRepo.getRequestsNeedingEmployeeConfirmation(event.employeeCode);
      emit(state.copyWith(status: Status.success, requests: requests));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onLoadFinanceAcknowledgmentRequests(
    LoadFinanceAcknowledgmentRequests event,
    Emitter<UserAdvanceOnSalaryRequestsState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final requests = await _advanceOnSalaryRequestRepo.getRequestsNeedingFinanceAcknowledgment(event.financeCode);
      emit(state.copyWith(status: Status.success, requests: requests));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  void _onResetEmployeeConfirmationStatus(
    ResetEmployeeConfirmationStatus event,
    Emitter<UserAdvanceOnSalaryRequestsState> emit,
  ) {
    emit(state.copyWith(employeeConfirmationStatus: Status.initial, clearOperationFailure: true));
  }

  void _onResetFinanceAcknowledgmentStatus(
    ResetFinanceAcknowledgmentStatus event,
    Emitter<UserAdvanceOnSalaryRequestsState> emit,
  ) {
    emit(state.copyWith(financeAcknowledgmentStatus: Status.initial, clearOperationFailure: true));
  }

  /// Helper method to regenerate PDF after payment changes
  /// Errors are silently caught since payment data is already persisted
  /// OPTIMIZED: Only regenerates final PDF (not current state PDF)
  Future<void> _regeneratePDF(int requestId) async {
    if (_workflowService == null) return;

    try {
      // Use optimized method that only regenerates final PDF
      await _workflowService.regenerateFinalPDFOnly(requestId, 'en');
    } catch (e) {
      // Silently log - payment data already persisted, PDF is secondary
      // In production, you might want to log this to a monitoring service
    }
  }
}
