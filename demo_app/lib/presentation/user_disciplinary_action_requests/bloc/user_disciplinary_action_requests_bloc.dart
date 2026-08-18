import 'dart:async';
import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_action_request_repo.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_requests_query.dart';
import 'package:hrms_demo/data/repos/investigation_request/investigation_request_repo.dart';
import 'package:hrms_demo/data/models/request_item_wrapper.dart';
import 'package:hrms_demo/data/models/investigation_request_model.dart';
import 'package:hrms_demo/data/models/investigation_decision.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'user_disciplinary_action_requests_event.dart';
import 'user_disciplinary_action_requests_state.dart';

class UserDisciplinaryActionRequestsBloc
    extends Bloc<UserDisciplinaryActionRequestsEvent, UserDisciplinaryActionRequestsState> {
  final DisciplinaryActionRequestRepo _disciplinaryActionRequestRepo;
  final InvestigationRequestRepo _investigationRequestRepo;

  /// The scope the screen is currently on, remembered so a mutation refreshes
  /// the list the user is actually looking at.
  ///
  /// Every mutation handler used to end with
  /// `add(LoadUserDisciplinaryActionRequests(code, RequestSourceType.teamRequests))`
  /// — thirteen of them — so acting on a row from either Processed tab dropped
  /// the user back on the Team list.
  DisciplinaryRequestScope _scope = DisciplinaryRequestScope.my;

  /// Guards against out-of-order page responses.
  int _pageSeq = 0;

  UserDisciplinaryActionRequestsBloc(this._disciplinaryActionRequestRepo, this._investigationRequestRepo)
    : super(const UserDisciplinaryActionRequestsState()) {
    on<InitDisciplinaryRequests>(_onInitDisciplinaryRequests);
    on<DisciplinaryPageChanged>(_onPageChanged);
    on<DisciplinaryPageSizeChanged>(_onPageSizeChanged);
    on<DisciplinaryQueryChanged>(_onQueryChanged);
    on<RefreshDisciplinaryPage>(_onRefreshPage);
    on<LoadUserDisciplinaryActionRequests>(_onLoadUserDisciplinaryActionRequests);
    on<ApproveDisciplinaryActionRequest>(_onApproveDisciplinaryActionRequest);
    on<DeclineDisciplinaryActionRequest>(_onDeclineDisciplinaryActionRequest);
    on<PutOnHoldDisciplinaryActionRequest>(_onPutOnHoldDisciplinaryActionRequest);
    on<LoadUserDisciplinaryActionRequestsByMonth>(_onLoadUserDisciplinaryActionRequestsByMonth);
    on<LoadEmployeeDisciplinaryHistory>(_onLoadEmployeeDisciplinaryHistory);
    on<ResetApproveStatus>(_onResetApproveStatus);
    on<ResetDeclineStatus>(_onResetDeclineStatus);
    on<ResetOnHoldStatus>(_onResetOnHoldStatus);
    on<CancelDisciplinaryActionRequest>(_onCancelDisciplinaryActionRequest);
    on<ResetCancelStatus>(_onResetCancelStatus);
    on<SendToHrInvestigationDisciplinaryActionRequest>(_onSendToHrInvestigation);
    on<ResetInvestigationStatus>(_onResetInvestigationStatus);
    on<EditWrittenWarningOptionsDisciplinaryActionRequest>(_onEditWrittenWarningOptions);
    on<ResetEditStatus>(_onResetEditStatus);
    on<AcknowledgeRequest>(_onAcknowledgeRequest);
    on<ResetAcknowledgmentStatus>(_onResetAcknowledgmentStatus);
    on<EscalateToLegalDisciplinaryActionRequest>(_onEscalateToLegal);
    on<ResetEscalateToLegalStatus>(_onResetEscalateToLegalStatus);
    on<LegalUploadInvestigationDisciplinaryActionRequest>(_onLegalUploadInvestigation);
    on<ResetLegalUploadStatus>(_onResetLegalUploadStatus);
    on<LegalAcknowledgeDisciplinaryActionRequest>(_onLegalAcknowledge);
    on<ResetLegalAcknowledgeStatus>(_onResetLegalAcknowledgeStatus);
    on<HRFinalDecisionDisciplinaryActionRequest>(_onHRFinalDecision);
    on<ResetHRFinalDecisionStatus>(_onResetHRFinalDecisionStatus);
    on<FetchAttachmentSignedUrls>(_onFetchAttachmentSignedUrls);
    on<ResetAttachmentUrls>(_onResetAttachmentUrls);
    // Investigation event handlers
    on<RecordHrInvestigationDecision>(_onRecordHrInvestigationDecision);
    on<RecordLegalInvestigationReview>(_onRecordLegalInvestigationReview);
    on<RecordTopManagementInvestigationDecision>(_onRecordTopManagementInvestigationDecision);
    on<SendTopManagementDecisionNotification>(_onSendTopManagementDecisionNotification);
    on<EscalateInvestigationToLegal>(_onEscalateInvestigationToLegal);
    on<AcknowledgeInvestigation>(_onAcknowledgeInvestigation);
    on<UploadLegalInvestigationPdf>(_onUploadLegalInvestigationPdf);
    on<CreateBulkDisciplinaryActionsFromInvestigation>(_onCreateBulkDisciplinaryActionsFromInvestigation);
    on<ConvertDisciplinaryActionToInvestigation>(_onConvertDisciplinaryActionToInvestigation);
    on<ResetInvestigationDecisionStatus>(_onResetInvestigationDecisionStatus);
    on<OpenInvestigationPdf>(_onOpenInvestigationPdf);
    on<ResetPdfOpenStatus>(_onResetPdfOpenStatus);
    on<FetchEmployeeBasicInfo>(_onFetchEmployeeBasicInfo);
    on<FetchLinkedDisciplinaryActions>(_onFetchLinkedDisciplinaryActions);
    on<FetchInvestigationById>(_onFetchInvestigationById);
    on<ResetFetchedInvestigation>(_onResetFetchedInvestigation);
    on<FetchDisciplinaryActionById>(_onFetchDisciplinaryActionById);
    on<ResetFetchedDisciplinaryAction>(_onResetFetchedDisciplinaryAction);
    on<FetchInvestigationByDisciplinaryActionId>(_onFetchInvestigationByDisciplinaryActionId);
    on<ResetLinkedInvestigationId>(_onResetLinkedInvestigationId);
  }

  // ── Server-paged path ──────────────────────────────────────────────────────

  Future<void> _onInitDisciplinaryRequests(
    InitDisciplinaryRequests event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    _scope = event.scope;

    // Deliberately NOT Status.loading: that branch blanks the whole screen, and
    // the first page fetch would be delayed behind the two scope-wide reads
    // rather than running alongside them.
    emit(
      state.copyWith(
        clearHasAnyRequests: true,
        // Filters belong to the tab.
        query: DisciplinaryRequestsQuery(scope: event.scope, locale: state.query.locale),
        // Drops the previous tab's rows — see PagedSection.resetForQuery. It
        // matters most here: the three tabs hold different ENTITY kinds, so a
        // lingering row can be an investigation card under Processed
        // Disciplinary.
        paged: state.paged.resetForQuery(),
      ),
    );

    await _loadScopeFacts(emit);
    await _loadPage(emit);
  }

  Future<void> _loadScopeFacts(Emitter<UserDisciplinaryActionRequestsState> emit) async {
    try {
      final results = await Future.wait([
        _disciplinaryActionRequestRepo.hasAnyRequests(_scope),
        _disciplinaryActionRequestRepo.getDisciplinaryRequestMonths(_scope),
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

  Future<void> _onPageChanged(DisciplinaryPageChanged event, Emitter<UserDisciplinaryActionRequestsState> emit) async {
    // Idempotent, so a rebuild that re-dispatches the current page costs nothing.
    if (event.page == state.paged.page) return;
    emit(state.copyWith(paged: state.paged.copyWith(page: event.page)));
    await _loadPage(emit);
  }

  Future<void> _onPageSizeChanged(
    DisciplinaryPageSizeChanged event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    if (event.pageSize == state.paged.pageSize) return;
    emit(state.copyWith(paged: state.paged.copyWith(pageSize: event.pageSize, page: 0)));
    await _loadPage(emit);
  }

  Future<void> _onQueryChanged(
    DisciplinaryQueryChanged event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    if (event.query == state.query) return;

    final scopeChanged = event.query.scope != state.query.scope;
    // The rows on screen answer the OLD query, so they go — whether the scope
    // changed or only the filters did.
    emit(state.copyWith(query: event.query, paged: state.paged.resetForQuery()));

    if (scopeChanged) {
      _scope = event.query.scope;
      emit(state.copyWith(clearHasAnyRequests: true));
      await _loadScopeFacts(emit);
    }

    await _loadPage(emit);
  }

  Future<void> _onRefreshPage(RefreshDisciplinaryPage event, Emitter<UserDisciplinaryActionRequestsState> emit) =>
      _refreshCurrentPage(emit);

  /// The single page-fetch point.
  ///
  /// One call, not two: the server already interleaved the disciplinary and
  /// investigation branches and ordered them together, so there is nothing left
  /// to merge or re-sort in Dart.
  Future<void> _loadPage(Emitter<UserDisciplinaryActionRequestsState> emit) async {
    final seq = ++_pageSeq;

    // items are NOT cleared: the cards stay on screen under the spinner, which
    // also keeps the row a mutation is running against visible.
    emit(state.copyWith(paged: state.paged.copyWith(isPageLoading: true, clearPageFailure: true)));

    try {
      final result = await _disciplinaryActionRequestRepo.getDisciplinaryRequestsPage(
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
  Future<void> _refreshCurrentPage(Emitter<UserDisciplinaryActionRequestsState> emit) async {
    try {
      final months = await _disciplinaryActionRequestRepo.getDisciplinaryRequestMonths(_scope);
      emit(state.copyWith(availableMonths: months));
    } catch (_) {
      // The picker is cosmetic; a failure here must not abort the page refresh.
    }

    await _loadPage(emit);

    // Approving, cancelling or converting a row can move it out of the scope
    // entirely, so the page the user is on can stop existing.
    final paged = state.paged;
    if (paged.items.isEmpty && paged.page > 0 && paged.pageFailure == null) {
      emit(state.copyWith(paged: paged.copyWith(page: paged.lastPageIndex.clamp(0, paged.page))));
      await _loadPage(emit);
    }
  }

  /// Dispatched by every mutation handler once its write succeeds.
  ///
  /// [userCode] is only used by the legacy path, which has to name a source
  /// type; the paged path refreshes the memoized [_scope] instead.
  void _refreshAfterMutation(int userCode) {
    add(
      FeatureFlags.serverPagedDisciplinaryRequests
          ? const RefreshDisciplinaryPage()
          : LoadUserDisciplinaryActionRequests(userCode, RequestSourceType.teamRequests),
    );
  }

  // ── Legacy whole-list path ─────────────────────────────────────────────────

  Future<void> _onLoadUserDisciplinaryActionRequests(
    LoadUserDisciplinaryActionRequests event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: Status.loading,
        approveStatus: Status.initial,
        declineStatus: Status.initial,
        onHoldStatus: Status.initial,
        cancelStatus: Status.initial,
        investigationStatus: Status.initial,
        acknowledgmentStatus: Status.initial,
        escalateToLegalStatus: Status.initial,
        legalUploadStatus: Status.initial,
        legalAcknowledgeStatus: Status.initial,
        hrFinalDecisionStatus: Status.initial,
        convertToInvestigationStatus: Status.initial,
      ),
    );

    try {
      // Load disciplinary actions
      final disciplinaryFuture = switch (event.sourceType) {
        RequestSourceType.myRequests => _disciplinaryActionRequestRepo.getMyDisciplinaryActionRequests(event.userCode),
        RequestSourceType.teamRequests => _disciplinaryActionRequestRepo.getRequestsToApprove(event.userCode),
        RequestSourceType.processedRequests => _disciplinaryActionRequestRepo.getProcessedRequests(event.userCode),
      };

      // Load investigation requests
      final investigationFuture = switch (event.sourceType) {
        RequestSourceType.myRequests => _investigationRequestRepo.getMyInvestigationRequests(event.userCode),
        RequestSourceType.teamRequests => _getAllInvestigationsToApprove(event.userCode),
        RequestSourceType.processedRequests => _investigationRequestRepo.getProcessedInvestigations(event.userCode),
      };

      // Execute in parallel using Dart 3 record-based wait for type safety
      final (disciplinaryRequests, investigationRequests) = await (disciplinaryFuture, investigationFuture).wait;

      // Convert both to RequestItem wrappers
      final wrappedDisciplinary = disciplinaryRequests.map((d) => RequestItem.fromDisciplinary(d)).toList();
      final wrappedInvestigations = investigationRequests.map((i) => RequestItem.fromInvestigation(i)).toList();

      // Combine and sort by createdAt descending (most recent first)
      final allRequests = [...wrappedDisciplinary, ...wrappedInvestigations];
      allRequests.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));

      emit(state.copyWith(status: Status.success, requests: allRequests));
    } on Failure catch (failure) {
      emit(state.copyWith(status: Status.failure, failure: failure));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  /// Helper: Load investigations for all roles user has
  /// Users can be in multiple groups (HR, Legal, Top Management)
  Future<List<InvestigationRequestModel>> _getAllInvestigationsToApprove(int userCode) async {
    final List<InvestigationRequestModel> allInvestigations = [];

    // Try each role - repo checks user groups internally
    try {
      final hrInvestigations = await _investigationRequestRepo.getInvestigationsToApprove(userCode, 'hr');
      allInvestigations.addAll(hrInvestigations);
    } catch (e) {
      // User not in HR group, skip
    }

    try {
      final legalInvestigations = await _investigationRequestRepo.getInvestigationsToApprove(userCode, 'legal');
      allInvestigations.addAll(legalInvestigations);
    } catch (e) {
      // User not in Legal group, skip
    }

    try {
      final topMgmtInvestigations = await _investigationRequestRepo.getInvestigationsToApprove(
        userCode,
        'top_management',
      );
      allInvestigations.addAll(topMgmtInvestigations);
    } catch (e) {
      // User not in Top Management group, skip
    }

    // Remove duplicates by ID (in case user is in multiple groups)
    final uniqueInvestigations = <int, InvestigationRequestModel>{};
    for (final inv in allInvestigations) {
      if (inv.id != null) {
        uniqueInvestigations[inv.id!] = inv;
      }
    }

    return uniqueInvestigations.values.toList();
  }

  Future<void> _onApproveDisciplinaryActionRequest(
    ApproveDisciplinaryActionRequest event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(
      state.copyWith(approveStatus: Status.loading, processingRequestId: event.requestId, clearOperationFailure: true),
    );

    try {
      await _disciplinaryActionRequestRepo.approveRequest(
        event.requestId,
        event.currentApprover,
        event.userCode,
        event.reason,
        pdfBytes: event.pdfBytes,
        pdfFileName: event.pdfFileName,
      );

      emit(state.copyWith(approveStatus: Status.success, clearProcessingRequestId: true));
      _refreshAfterMutation(event.userCode);
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

  Future<void> _onDeclineDisciplinaryActionRequest(
    DeclineDisciplinaryActionRequest event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(
      state.copyWith(declineStatus: Status.loading, processingRequestId: event.requestId, clearOperationFailure: true),
    );

    try {
      await _disciplinaryActionRequestRepo.declineRequest(
        event.requestId,
        event.reason,
        event.currentApprover,
        event.userCode,
        pdfBytes: event.pdfBytes,
        pdfFileName: event.pdfFileName,
      );

      emit(state.copyWith(declineStatus: Status.success, clearProcessingRequestId: true));
      _refreshAfterMutation(event.userCode);
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

  Future<void> _onPutOnHoldDisciplinaryActionRequest(
    PutOnHoldDisciplinaryActionRequest event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(
      state.copyWith(onHoldStatus: Status.loading, processingRequestId: event.requestId, clearOperationFailure: true),
    );

    try {
      await _disciplinaryActionRequestRepo.putOnHoldRequest(
        event.requestId,
        event.currentApprover,
        event.userCode,
        event.reason,
      );

      emit(state.copyWith(onHoldStatus: Status.success, clearProcessingRequestId: true));
      _refreshAfterMutation(event.userCode);
    } catch (e) {
      emit(
        state.copyWith(
          onHoldStatus: Status.failure,
          operationFailure: Failure(e.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  Future<void> _onLoadUserDisciplinaryActionRequestsByMonth(
    LoadUserDisciplinaryActionRequestsByMonth event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    try {
      // Load disciplinary actions for the month
      final disciplinaryRequests = await _disciplinaryActionRequestRepo.getRequestsByMonth(event.userCode, event.month);

      // Load investigations for the month (if method exists)
      // For now, just load disciplinary actions since investigation repo may not have this method yet
      final wrappedDisciplinary = disciplinaryRequests.map((d) => RequestItem.fromDisciplinary(d)).toList();

      emit(state.copyWith(status: Status.success, requests: wrappedDisciplinary));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onLoadEmployeeDisciplinaryHistory(
    LoadEmployeeDisciplinaryHistory event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final history = await _disciplinaryActionRequestRepo.getEmployeeDisciplinaryHistory(event.employeeCode);

      emit(state.copyWith(status: Status.success, employeeHistory: history));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onCancelDisciplinaryActionRequest(
    CancelDisciplinaryActionRequest event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(
      state.copyWith(cancelStatus: Status.loading, processingRequestId: event.requestId, clearOperationFailure: true),
    );

    try {
      await _disciplinaryActionRequestRepo.cancelRequest(event.requestId);

      if (FeatureFlags.serverPagedDisciplinaryRequests) {
        // A cancel can move the row out of the current scope entirely, which an
        // in-place `cancelled: true` cannot express — and on the paged path
        // `state.requests` is empty, so the map below would do nothing at all.
        //
        // Note the id space: `requestItem.id == event.requestId` matches on id
        // ALONE, and disciplinary_action_requests.id and investigations.id
        // collide. On a page holding both kinds that patch could mark the wrong
        // card cancelled. Refreshing sidesteps it.
        await _refreshCurrentPage(emit);
        emit(state.copyWith(cancelStatus: Status.success, clearProcessingRequestId: true));
      } else {
        // Refresh the requests - assume this is called from "my requests" view
        // Update the request in the current list to mark it as cancelled
        final updatedRequests =
            state.requests.map((requestItem) {
              if (requestItem.id == event.requestId && requestItem.isDisciplinaryAction) {
                // Update the disciplinary action inside the wrapper
                final updatedAction = requestItem.disciplinaryAction!.copyWith(cancelled: true);
                return RequestItem.fromDisciplinary(updatedAction);
              }
              return requestItem;
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

  void _onResetApproveStatus(ResetApproveStatus event, Emitter<UserDisciplinaryActionRequestsState> emit) {
    emit(state.copyWith(approveStatus: Status.initial));
  }

  void _onResetDeclineStatus(ResetDeclineStatus event, Emitter<UserDisciplinaryActionRequestsState> emit) {
    emit(state.copyWith(declineStatus: Status.initial));
  }

  void _onResetOnHoldStatus(ResetOnHoldStatus event, Emitter<UserDisciplinaryActionRequestsState> emit) {
    emit(state.copyWith(onHoldStatus: Status.initial));
  }

  void _onResetCancelStatus(ResetCancelStatus event, Emitter<UserDisciplinaryActionRequestsState> emit) {
    emit(state.copyWith(cancelStatus: Status.initial));
  }

  Future<void> _onSendToHrInvestigation(
    SendToHrInvestigationDisciplinaryActionRequest event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        investigationStatus: Status.loading,
        processingRequestId: event.requestId,
        clearOperationFailure: true,
      ),
    );

    try {
      await _disciplinaryActionRequestRepo.sendToHrInvestigation(event.requestId, event.n2Code, event.reason);

      emit(state.copyWith(investigationStatus: Status.success, clearProcessingRequestId: true));
      _refreshAfterMutation(event.n2Code);
    } catch (e) {
      emit(
        state.copyWith(
          investigationStatus: Status.failure,
          operationFailure: Failure(e.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  void _onResetInvestigationStatus(ResetInvestigationStatus event, Emitter<UserDisciplinaryActionRequestsState> emit) {
    emit(state.copyWith(investigationStatus: Status.initial));
  }

  Future<void> _onEditWrittenWarningOptions(
    EditWrittenWarningOptionsDisciplinaryActionRequest event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(editStatus: Status.loading, processingRequestId: event.requestId, clearOperationFailure: true));

    try {
      // Read the row's existing comments by ID rather than scanning state.
      //
      // The old `state.requests.firstWhere(...)` throws StateError when the row
      // is not in the loaded list — a pre-existing crash that paging would make
      // routine, since `requests` holds one page at most (and nothing at all on
      // the paged path). It also matched on id alone, and disciplinary and
      // investigation ids collide.
      final currentAction = await _disciplinaryActionRequestRepo.fetchDisciplinaryActionById(event.requestId);

      // Generate change log entries
      final changes = <String>[];

      if (event.previousOptions.deductDays != event.options.deductDays) {
        final oldDays = event.previousOptions.deductDays ?? 0;
        final newDays = event.options.deductDays ?? 0;
        changes.add(
          'EN: ${event.userEnglishName}: Changed deduct days from $oldDays to $newDays | '
          'AR: ${event.userArabicName}: تم تغيير أيام الخصم من $oldDays إلى $newDays',
        );
      }

      if (event.previousOptions.suspensionDays != event.options.suspensionDays) {
        final oldDays = event.previousOptions.suspensionDays ?? 0;
        final newDays = event.options.suspensionDays ?? 0;
        changes.add(
          'EN: ${event.userEnglishName}: Changed suspension days from $oldDays to $newDays | '
          'AR: ${event.userArabicName}: تم تغيير أيام الإيقاف من $oldDays إلى $newDays',
        );
      }

      // Create the updated comments with change log
      String? updatedComments = currentAction?.comments;
      if (changes.isNotEmpty) {
        final timestamp = DateTime.now().toString().substring(0, 19);
        final newChangeEntries = changes.map((change) => '[$timestamp] $change').join('\n');
        updatedComments =
            updatedComments != null && updatedComments.isNotEmpty
                ? '$updatedComments\n$newChangeEntries'
                : newChangeEntries;
      }

      await _disciplinaryActionRequestRepo.editWrittenWarningOptions(event.requestId, event.options, updatedComments);

      if (FeatureFlags.serverPagedDisciplinaryRequests) {
        await _refreshCurrentPage(emit);
        emit(state.copyWith(editStatus: Status.success, clearProcessingRequestId: true));
      } else {
        // Update the specific request in the state with the new comments and options
        final updatedRequests =
            state.requests.map((requestItem) {
              if (requestItem.id == event.requestId && requestItem.isDisciplinaryAction) {
                final updatedAction = requestItem.disciplinaryAction!.copyWith(
                  writtenWarningOptions: event.options,
                  comments: updatedComments,
                );
                return RequestItem.fromDisciplinary(updatedAction);
              }
              return requestItem;
            }).toList();

        emit(state.copyWith(editStatus: Status.success, clearProcessingRequestId: true, requests: updatedRequests));
      }
    } catch (e) {
      emit(
        state.copyWith(
          editStatus: Status.failure,
          operationFailure: Failure(e.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  void _onResetEditStatus(ResetEditStatus event, Emitter<UserDisciplinaryActionRequestsState> emit) {
    emit(state.copyWith(editStatus: Status.initial));
  }

  Future<void> _onAcknowledgeRequest(
    AcknowledgeRequest event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    // Set loading with processingRequestId and action type for UI feedback
    emit(
      state.copyWith(
        acknowledgmentStatus: Status.loading,
        processingRequestId: event.requestId,
        acknowledgmentActionType: event.acknowledgmentType,
      ),
    );

    try {
      await _disciplinaryActionRequestRepo.acknowledgeRequest(
        event.requestId,
        event.employeeCode,
        event.acknowledgmentType,
        event.remark,
      );

      // Refresh requests list after acknowledgment
      final requests = await _disciplinaryActionRequestRepo.getMyDisciplinaryActionRequests(event.employeeCode);
      final wrappedRequests = requests.map((d) => RequestItem.fromDisciplinary(d)).toList();

      emit(
        state.copyWith(acknowledgmentStatus: Status.success, requests: wrappedRequests, clearProcessingRequestId: true),
      );
    } catch (error) {
      emit(
        state.copyWith(
          acknowledgmentStatus: Status.failure,
          failure: Failure(error.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  void _onResetAcknowledgmentStatus(
    ResetAcknowledgmentStatus event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) {
    emit(state.copyWith(acknowledgmentStatus: Status.initial));
  }

  Future<void> _onEscalateToLegal(
    EscalateToLegalDisciplinaryActionRequest event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        escalateToLegalStatus: Status.loading,
        processingRequestId: event.requestId,
        clearOperationFailure: true,
      ),
    );

    try {
      await _disciplinaryActionRequestRepo.escalateToLegal(event.requestId, event.hrApproverCode, event.reason);

      // Refresh the requests
      final requests = await _disciplinaryActionRequestRepo.getRequestsToApprove(event.hrApproverCode);
      final wrappedRequests = requests.map((d) => RequestItem.fromDisciplinary(d)).toList();
      emit(
        state.copyWith(
          escalateToLegalStatus: Status.success,
          requests: wrappedRequests,
          clearProcessingRequestId: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          escalateToLegalStatus: Status.failure,
          operationFailure: Failure(error.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  void _onResetEscalateToLegalStatus(
    ResetEscalateToLegalStatus event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) {
    emit(state.copyWith(escalateToLegalStatus: Status.initial));
  }

  Future<void> _onLegalUploadInvestigation(
    LegalUploadInvestigationDisciplinaryActionRequest event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        legalUploadStatus: Status.loading,
        processingRequestId: event.requestId,
        clearOperationFailure: true,
      ),
    );

    try {
      await _disciplinaryActionRequestRepo.legalUploadInvestigation(
        event.requestId,
        event.legalApproverCode,
        event.pdfBytes,
        event.pdfFileName,
      );

      // Refresh the requests
      final requests = await _disciplinaryActionRequestRepo.getRequestsToApprove(event.legalApproverCode);
      final wrappedRequests = requests.map((d) => RequestItem.fromDisciplinary(d)).toList();
      emit(
        state.copyWith(legalUploadStatus: Status.success, requests: wrappedRequests, clearProcessingRequestId: true),
      );
    } catch (error) {
      emit(
        state.copyWith(
          legalUploadStatus: Status.failure,
          operationFailure: Failure(error.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  void _onResetLegalUploadStatus(ResetLegalUploadStatus event, Emitter<UserDisciplinaryActionRequestsState> emit) {
    emit(state.copyWith(legalUploadStatus: Status.initial));
  }

  Future<void> _onLegalAcknowledge(
    LegalAcknowledgeDisciplinaryActionRequest event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        legalAcknowledgeStatus: Status.loading,
        processingRequestId: event.requestId,
        clearOperationFailure: true,
      ),
    );

    try {
      await _disciplinaryActionRequestRepo.legalAcknowledge(event.requestId, event.legalApproverCode);

      // Refresh the requests
      final requests = await _disciplinaryActionRequestRepo.getRequestsToApprove(event.legalApproverCode);
      final wrappedRequests = requests.map((d) => RequestItem.fromDisciplinary(d)).toList();
      emit(
        state.copyWith(
          legalAcknowledgeStatus: Status.success,
          requests: wrappedRequests,
          clearProcessingRequestId: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          legalAcknowledgeStatus: Status.failure,
          operationFailure: Failure(error.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  void _onResetLegalAcknowledgeStatus(
    ResetLegalAcknowledgeStatus event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) {
    emit(state.copyWith(legalAcknowledgeStatus: Status.initial));
  }

  Future<void> _onHRFinalDecision(
    HRFinalDecisionDisciplinaryActionRequest event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        hrFinalDecisionStatus: Status.loading,
        processingRequestId: event.requestId,
        hrFinalActionType: event.action,
        clearOperationFailure: true,
      ),
    );

    try {
      await _disciplinaryActionRequestRepo.hrFinalDecision(
        event.requestId,
        event.hrApproverCode,
        event.action,
        event.reason,
        event.suspensionDays,
      );

      // Refresh the requests
      final requests = await _disciplinaryActionRequestRepo.getRequestsToApprove(event.hrApproverCode);
      final wrappedRequests = requests.map((d) => RequestItem.fromDisciplinary(d)).toList();
      emit(
        state.copyWith(
          hrFinalDecisionStatus: Status.success,
          requests: wrappedRequests,
          hrFinalActionType: null,
          clearProcessingRequestId: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          hrFinalDecisionStatus: Status.failure,
          operationFailure: Failure(error.toString()),
          hrFinalActionType: null,
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  void _onResetHRFinalDecisionStatus(
    ResetHRFinalDecisionStatus event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) {
    emit(state.copyWith(hrFinalDecisionStatus: Status.initial, hrFinalActionType: null));
  }

  Future<void> _onFetchAttachmentSignedUrls(
    FetchAttachmentSignedUrls event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(attachmentUrlsStatus: Status.loading));

    try {
      final signedUrls = await _disciplinaryActionRequestRepo.getAttachmentSignedUrls(event.attachmentPaths);
      emit(state.copyWith(attachmentUrlsStatus: Status.success, attachmentSignedUrls: signedUrls));
    } catch (e) {
      emit(state.copyWith(attachmentUrlsStatus: Status.failure, operationFailure: Failure(e.toString())));
    }
  }

  void _onResetAttachmentUrls(ResetAttachmentUrls event, Emitter<UserDisciplinaryActionRequestsState> emit) {
    emit(state.copyWith(attachmentUrlsStatus: Status.initial, clearAttachmentUrls: true));
  }

  // ===== INVESTIGATION EVENT HANDLERS =====

  Future<void> _onRecordHrInvestigationDecision(
    RecordHrInvestigationDecision event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(investigationDecisionStatus: Status.loading));

    try {
      // Upload HR decision attachments if provided
      List<String>? attachmentUrls;
      if (event.attachmentFiles != null && event.attachmentFiles!.isNotEmpty && event.attachmentFileNames != null) {
        attachmentUrls = await _investigationRequestRepo.uploadHrDecisionAttachments(
          event.investigationId,
          event.attachmentFiles!,
          event.attachmentFileNames!,
        );
      }

      // Convert Map<int, String> to List<InvestigationDecision>
      final decisions =
          event.employeeDecisions.entries.map((entry) {
            final isTakeAction = entry.value == 'take_action';
            final daType = isTakeAction ? (event.employeeDaTypes?[entry.key]) : null;
            final deductDays = isTakeAction ? (event.employeeDeductDays?[entry.key]) : null;
            return InvestigationDecision(
              employeeCode: entry.key,
              decision: entry.value,
              comment: event.employeeComments?[entry.key],
              daType: daType,
              deductDays: deductDays,
            );
          }).toList();

      // Record HR decisions with attachments
      await _investigationRequestRepo.recordHrDecisions(
        event.investigationId,
        event.decidedBy,
        decisions,
        pdfBytes: null,
        pdfFileName: null,
        attachmentUrls: attachmentUrls,
      );

      emit(state.copyWith(investigationDecisionStatus: Status.success));

      // Refresh requests to show updated investigation status
      _refreshAfterMutation(event.decidedBy);
    } catch (error) {
      emit(state.copyWith(investigationDecisionStatus: Status.failure, operationFailure: Failure(error.toString())));
    }
  }

  Future<void> _onEscalateInvestigationToLegal(
    EscalateInvestigationToLegal event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(investigationDecisionStatus: Status.loading));

    try {
      await _investigationRequestRepo.escalateInvestigationToLegal(event.investigationId, event.hrCode, event.reason);

      emit(state.copyWith(investigationDecisionStatus: Status.success));

      // Refresh requests to show updated investigation status
      _refreshAfterMutation(event.hrCode);
    } catch (error) {
      emit(state.copyWith(investigationDecisionStatus: Status.failure, operationFailure: Failure(error.toString())));
    }
  }

  Future<void> _onRecordLegalInvestigationReview(
    RecordLegalInvestigationReview event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(investigationDecisionStatus: Status.loading));

    try {
      // Upload PDFs if provided
      if (event.pdfBytes != null && event.pdfBytes!.isNotEmpty && event.pdfFileNames != null) {
        // Upload the first PDF (primary legal investigation PDF)
        await _investigationRequestRepo.uploadAndUpdateLegalPdf(
          event.investigationId,
          event.reviewedBy,
          event.pdfBytes!.first,
          event.pdfFileNames!.first,
        );
      }

      // Build legal decisions from per-employee comments (decision: 'reviewed' as neutral placeholder)
      final legalDecisions =
          event.employeeComments?.entries
              .where((e) => e.value.trim().isNotEmpty)
              .map((e) => InvestigationDecision(employeeCode: e.key, decision: 'reviewed', comment: e.value.trim()))
              .toList();

      // Legal submits their decisions/review — triggers the correct "Legal Decisions Submitted" email
      await _investigationRequestRepo.recordLegalDecisions(
        event.investigationId,
        event.reviewedBy,
        legalDecisions ?? [],
      );

      emit(state.copyWith(investigationDecisionStatus: Status.success));

      // Refresh requests to show updated investigation status
      _refreshAfterMutation(event.reviewedBy);
    } catch (error) {
      emit(state.copyWith(investigationDecisionStatus: Status.failure, operationFailure: Failure(error.toString())));
    }
  }

  Future<void> _onAcknowledgeInvestigation(
    AcknowledgeInvestigation event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        legalAcknowledgeStatus: Status.loading,
        processingRequestId: event.investigationId,
        clearOperationFailure: true,
      ),
    );

    try {
      await _investigationRequestRepo.legalAcknowledgeInvestigation(event.investigationId, event.legalCode);

      emit(state.copyWith(legalAcknowledgeStatus: Status.success));

      // Refresh requests to show updated investigation status
      _refreshAfterMutation(event.legalCode);
    } catch (error) {
      emit(
        state.copyWith(
          legalAcknowledgeStatus: Status.failure,
          operationFailure: Failure(error.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  Future<void> _onUploadLegalInvestigationPdf(
    UploadLegalInvestigationPdf event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        legalUploadStatus: Status.loading,
        processingRequestId: event.investigationId,
        clearOperationFailure: true,
      ),
    );

    try {
      // Upload PDF to storage and update investigation record
      await _investigationRequestRepo.uploadAndUpdateLegalPdf(
        event.investigationId,
        event.legalCode,
        event.pdfBytes,
        event.pdfFileName,
      );

      emit(state.copyWith(legalUploadStatus: Status.success));

      // Refresh requests to show updated investigation status
      _refreshAfterMutation(event.legalCode);
    } catch (error) {
      emit(
        state.copyWith(
          legalUploadStatus: Status.failure,
          operationFailure: Failure(error.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  Future<void> _onRecordTopManagementInvestigationDecision(
    RecordTopManagementInvestigationDecision event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(investigationDecisionStatus: Status.loading));

    try {
      // Upload PDFs if provided and capture storage paths for DB persistence
      List<String>? attachmentPaths;
      if (event.pdfBytes != null && event.pdfBytes!.isNotEmpty && event.pdfFileNames != null) {
        attachmentPaths = await _investigationRequestRepo
            .uploadTmDecisionAttachments(event.investigationId, event.pdfBytes!, event.pdfFileNames!)
            .timeout(
              const Duration(seconds: 60),
              onTimeout:
                  () =>
                      throw TimeoutException(
                        'Attachment upload timed out. Please check your connection and try again.',
                      ),
            );
      }

      // Convert Map<int, String> to List<InvestigationDecision>
      final decisions =
          event.employeeDecisions.entries
              .map(
                (entry) => InvestigationDecision(
                  employeeCode: entry.key,
                  decision: entry.value,
                  comment: event.employeeComments?[entry.key],
                ),
              )
              .toList();

      // Record Top Management decisions, passing attachment paths so they are saved to DB
      await _investigationRequestRepo.recordTopManagementDecisions(
        event.investigationId,
        event.decidedBy,
        decisions,
        attachmentPaths,
      );

      emit(state.copyWith(investigationDecisionStatus: Status.success));

      // Refresh requests to show updated investigation status
      _refreshAfterMutation(event.decidedBy);
    } catch (error) {
      emit(state.copyWith(investigationDecisionStatus: Status.failure, operationFailure: Failure(error.toString())));
    }
  }

  Future<void> _onSendTopManagementDecisionNotification(
    SendTopManagementDecisionNotification event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    await _investigationRequestRepo.sendTopManagementDecisionNotification(event.investigationId);
  }

  Future<void> _onCreateBulkDisciplinaryActionsFromInvestigation(
    CreateBulkDisciplinaryActionsFromInvestigation event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(bulkCreationStatus: Status.loading));

    try {
      // Upload bulk action attachments if provided (shared across all actions)
      List<String>? attachmentUrls;
      if (event.attachmentFiles != null && event.attachmentFiles!.isNotEmpty && event.attachmentFileNames != null) {
        // Use investigation attachment upload - these are shared by all created actions
        attachmentUrls = await _investigationRequestRepo.uploadHrDecisionAttachments(
          event.investigationId,
          event.attachmentFiles!,
          event.attachmentFileNames!,
        );
      }

      // Build DisciplinaryActionRequestModel for each employee
      // Investigation-sourced actions are pre-approved (HR + Top Management review already done)
      final actions =
          event.employeeCodes.map((employeeCode) {
            return DisciplinaryActionRequestModel(
              requestorCode: event.requestorCode,
              employeeCode: employeeCode,
              actionType: event.actionType,
              violationCategory: event.violationCategory,
              violation: event.violation,
              violationDate: event.violationDate,
              incidentDescription: event.incidentDescription,
              writtenWarningOptions: event.writtenWarningOptions,
              attachments: attachmentUrls, // Shared attachments for all actions
              status: 'approved', // Pre-approved through investigation workflow
              currentApprover: '-', // No further approval needed
            );
          }).toList();

      // Create disciplinary actions from investigation
      await _investigationRequestRepo.createDisciplinaryActionsFromInvestigation(event.investigationId, actions);

      emit(state.copyWith(bulkCreationStatus: Status.success));

      // Refresh requests to show newly created disciplinary actions
      _refreshAfterMutation(event.requestorCode);
    } catch (error) {
      emit(state.copyWith(bulkCreationStatus: Status.failure, operationFailure: Failure(error.toString())));
    }
  }

  Future<void> _onConvertDisciplinaryActionToInvestigation(
    ConvertDisciplinaryActionToInvestigation event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(
      state.copyWith(
        convertToInvestigationStatus: Status.loading,
        processingRequestId: event.disciplinaryActionId,
        clearOperationFailure: true,
      ),
    );

    try {
      // Convert disciplinary action to investigation
      await _disciplinaryActionRequestRepo.convertDisciplinaryActionToInvestigation(
        event.disciplinaryActionId,
        event.convertedBy,
        event.reason,
      );

      emit(state.copyWith(convertToInvestigationStatus: Status.success, clearProcessingRequestId: true));

      // Refresh requests to show new investigation and updated disciplinary action
      _refreshAfterMutation(event.convertedBy);
    } catch (error) {
      emit(
        state.copyWith(
          convertToInvestigationStatus: Status.failure,
          operationFailure: Failure(error.toString()),
          clearProcessingRequestId: true,
        ),
      );
    }
  }

  void _onResetInvestigationDecisionStatus(
    ResetInvestigationDecisionStatus event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) {
    emit(
      state.copyWith(
        investigationDecisionStatus: Status.initial,
        bulkCreationStatus: Status.initial,
        convertToInvestigationStatus: Status.initial,
      ),
    );
  }

  Future<void> _onOpenInvestigationPdf(
    OpenInvestigationPdf event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(pdfOpenStatus: Status.loading));

    try {
      final String pdfUrl;
      if (event.storagePath.startsWith('http')) {
        // Already a public URL (DA old workflow — stored via DisciplinaryPDFStorageService.getPublicUrl)
        pdfUrl = event.storagePath;
      } else {
        // Relative storage path — needs a signed URL (investigation attachments)
        final signedUrls = await _investigationRequestRepo.getInvestigationAttachmentSignedUrls([event.storagePath]);
        pdfUrl = signedUrls.first;
      }
      emit(state.copyWith(pdfOpenStatus: Status.success, pdfSignedUrl: pdfUrl));
    } catch (e) {
      emit(state.copyWith(pdfOpenStatus: Status.failure, operationFailure: Failure(e.toString())));
    }
  }

  void _onResetPdfOpenStatus(ResetPdfOpenStatus event, Emitter<UserDisciplinaryActionRequestsState> emit) {
    emit(state.copyWith(pdfOpenStatus: Status.initial, clearPdfSignedUrl: true));
  }

  Future<void> _onFetchEmployeeBasicInfo(
    FetchEmployeeBasicInfo event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(employeeInfoStatus: Status.loading));

    try {
      final employeeInfoMap = await _investigationRequestRepo.getEmployeeBasicInfo(event.employeeCodes);
      emit(state.copyWith(employeeInfoMap: employeeInfoMap, employeeInfoStatus: Status.success));
    } catch (error) {
      emit(state.copyWith(employeeInfoStatus: Status.failure, operationFailure: Failure(error.toString())));
    }
  }

  Future<void> _onFetchLinkedDisciplinaryActions(
    FetchLinkedDisciplinaryActions event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(linkedDisciplinaryActionsStatus: Status.loading));

    try {
      final actions = await _investigationRequestRepo.getLinkedDisciplinaryActions(event.investigationId);

      emit(state.copyWith(linkedDisciplinaryActions: actions, linkedDisciplinaryActionsStatus: Status.success));
    } catch (error) {
      emit(
        state.copyWith(linkedDisciplinaryActionsStatus: Status.failure, operationFailure: Failure(error.toString())),
      );
    }
  }

  /// Fetches a single investigation by ID for viewing from disciplinary action details
  Future<void> _onFetchInvestigationById(
    FetchInvestigationById event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(fetchedInvestigationStatus: Status.loading, clearFetchedInvestigation: true));

    try {
      final investigation = await _investigationRequestRepo.getInvestigationById(
        event.investigationId,
        approverCode: event.approverCode,
      );

      if (investigation != null) {
        emit(state.copyWith(fetchedInvestigation: investigation, fetchedInvestigationStatus: Status.success));
      } else {
        emit(
          state.copyWith(
            fetchedInvestigationStatus: Status.failure,
            operationFailure: Failure('Investigation not found'),
          ),
        );
      }
    } catch (error) {
      emit(state.copyWith(fetchedInvestigationStatus: Status.failure, operationFailure: Failure(error.toString())));
    }
  }

  /// Resets the fetched investigation state
  Future<void> _onResetFetchedInvestigation(
    ResetFetchedInvestigation event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(clearFetchedInvestigation: true, fetchedInvestigationStatus: Status.initial));
  }

  /// Fetches a single disciplinary action by ID for viewing from investigation details
  Future<void> _onFetchDisciplinaryActionById(
    FetchDisciplinaryActionById event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(fetchedDisciplinaryActionStatus: Status.loading, clearFetchedDisciplinaryAction: true));

    try {
      final da = await _disciplinaryActionRequestRepo.fetchDisciplinaryActionById(event.disciplinaryActionId);

      if (da != null) {
        emit(state.copyWith(fetchedDisciplinaryAction: da, fetchedDisciplinaryActionStatus: Status.success));
      } else {
        emit(
          state.copyWith(
            fetchedDisciplinaryActionStatus: Status.failure,
            operationFailure: Failure('Disciplinary action not found'),
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(fetchedDisciplinaryActionStatus: Status.failure, operationFailure: Failure(error.toString())),
      );
    }
  }

  /// Resets the fetched disciplinary action state
  void _onResetFetchedDisciplinaryAction(
    ResetFetchedDisciplinaryAction event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) {
    emit(state.copyWith(clearFetchedDisciplinaryAction: true, fetchedDisciplinaryActionStatus: Status.initial));
  }

  Future<void> _onFetchInvestigationByDisciplinaryActionId(
    FetchInvestigationByDisciplinaryActionId event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) async {
    emit(state.copyWith(linkedInvestigationIdStatus: Status.loading, clearLinkedInvestigationId: true));
    try {
      final investigation = await _investigationRequestRepo.getInvestigationFromDisciplinaryAction(
        event.disciplinaryActionId,
      );
      if (investigation != null && investigation.id != null) {
        emit(state.copyWith(linkedInvestigationId: investigation.id, linkedInvestigationIdStatus: Status.success));
      } else {
        emit(
          state.copyWith(
            linkedInvestigationIdStatus: Status.failure,
            operationFailure: Failure('Linked investigation not found'),
          ),
        );
      }
    } catch (error) {
      emit(state.copyWith(linkedInvestigationIdStatus: Status.failure, operationFailure: Failure(error.toString())));
    }
  }

  void _onResetLinkedInvestigationId(
    ResetLinkedInvestigationId event,
    Emitter<UserDisciplinaryActionRequestsState> emit,
  ) {
    emit(state.copyWith(clearLinkedInvestigationId: true, linkedInvestigationIdStatus: Status.initial));
  }
}
