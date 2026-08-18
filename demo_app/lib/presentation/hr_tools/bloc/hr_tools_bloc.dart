import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/hr_tools/bloc/hr_tools_event.dart';
import 'package:hrms_demo/presentation/hr_tools/bloc/hr_tools_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HrToolsBloc extends Bloc<HrToolsEvent, HrToolsState> {
  final UsersRepo usersRepo;
  final LeaveRequestsRepo leaveRequestsRepo;
  final UserBloc userBloc;

  HrToolsBloc({required this.usersRepo, required this.leaveRequestsRepo, required this.userBloc})
    : super(const HrToolsState()) {
    on<HrToolsInitialized>(_onInitialized);
    on<HrToolsEmployeeSearchChanged>(_onSearchChanged);
    on<HrToolsSearchCleared>(_onSearchCleared);
    on<HrToolsEmployeeAdded>(_onEmployeeAdded);
    on<HrToolsEmployeeRemoved>(_onEmployeeRemoved);
    on<HrToolsAllEmployeesCleared>(_onAllEmployeesCleared);
    on<HrToolsTabChanged>(_onTabChanged);
    on<HrToolsLeaveDateFromChanged>(_onLeaveDateFromChanged);
    on<HrToolsLeaveDateToChanged>(_onLeaveDateToChanged);
    on<HrToolsLeaveTypeChanged>(_onLeaveTypeChanged);
    on<HrToolsApprovalModeChanged>(_onApprovalModeChanged);
    on<HrToolsSickNotesPicked>(_onSickNotesPicked);
    on<HrToolsSickNoteRemoved>(_onSickNoteRemoved);
    on<HrToolsBulkLeaveSubmitted>(_onBulkLeaveSubmitted);
    on<HrToolsOvertimeDeltaChanged>(_onOvertimeDeltaChanged);
    on<HrToolsBulkOvertimeSubmitted>(_onBulkOvertimeSubmitted);
    on<HrToolsFormReset>(_onFormReset);
    on<HrToolsMessageCleared>(_onMessageCleared);
  }

  void _onInitialized(HrToolsInitialized event, Emitter<HrToolsState> emit) {
    emit(const HrToolsState());
  }

  Future<void> _onSearchChanged(HrToolsEmployeeSearchChanged event, Emitter<HrToolsState> emit) async {
    if (event.query.trim().isEmpty) {
      emit(state.copyWith(searchResults: [], isSearching: false));
      return;
    }
    emit(state.copyWith(isSearching: true, searchResults: []));
    try {
      final results = await usersRepo.searchAllActiveEmployees(event.query.trim());
      emit(state.copyWith(searchResults: results.take(5).toList(), isSearching: false));
    } catch (_) {
      emit(state.copyWith(searchResults: [], isSearching: false));
    }
  }

  void _onSearchCleared(HrToolsSearchCleared event, Emitter<HrToolsState> emit) {
    emit(state.copyWith(searchResults: [], isSearching: false));
  }

  /// Blanks any staged medical report once [HrToolsState.canAttachSickNote] no
  /// longer holds for [next].
  ///
  /// Without this, HR could stage a file with one employee selected, add a
  /// second — which hides the upload control — and leave the bytes sitting
  /// invisibly in state, to be silently dropped at submit time or attached to
  /// the wrong row. Applied wherever the leave type or the selection changes.
  HrToolsState _dropStaleSickNotes(HrToolsState next) {
    if (next.canAttachSickNote || next.sickNoteFiles.isEmpty) return next;
    return next.copyWith(sickNoteFiles: [], sickNoteFileNames: []);
  }

  void _onEmployeeAdded(HrToolsEmployeeAdded event, Emitter<HrToolsState> emit) {
    final already = state.selectedEmployees.any((e) => e.id == event.employee.id);
    if (already) return;
    emit(
      _dropStaleSickNotes(
        state.copyWith(
          selectedEmployees: [...state.selectedEmployees, event.employee],
          searchResults: [],
          validationErrors: Map.from(state.validationErrors)..remove('employees'),
        ),
      ),
    );
  }

  void _onEmployeeRemoved(HrToolsEmployeeRemoved event, Emitter<HrToolsState> emit) {
    emit(
      _dropStaleSickNotes(
        state.copyWith(selectedEmployees: state.selectedEmployees.where((e) => e.id != event.employee.id).toList()),
      ),
    );
  }

  void _onAllEmployeesCleared(HrToolsAllEmployeesCleared event, Emitter<HrToolsState> emit) {
    emit(_dropStaleSickNotes(state.copyWith(selectedEmployees: [])));
  }

  void _onTabChanged(HrToolsTabChanged event, Emitter<HrToolsState> emit) {
    emit(state.copyWith(tabIndex: event.index, validationErrors: {}));
  }

  void _onLeaveDateFromChanged(HrToolsLeaveDateFromChanged event, Emitter<HrToolsState> emit) {
    final errors = Map<String, String>.from(state.validationErrors)..remove('dateFrom');
    // Clear dateTo if it's before the new dateFrom
    final clearTo = state.dateTo != null && !state.dateTo!.isAfter(event.date);
    emit(state.copyWith(dateFrom: event.date, clearDateTo: clearTo, validationErrors: errors));
  }

  void _onLeaveDateToChanged(HrToolsLeaveDateToChanged event, Emitter<HrToolsState> emit) {
    final errors = Map<String, String>.from(state.validationErrors)..remove('dateTo');
    emit(state.copyWith(dateTo: event.date, validationErrors: errors));
  }

  void _onLeaveTypeChanged(HrToolsLeaveTypeChanged event, Emitter<HrToolsState> emit) {
    emit(_dropStaleSickNotes(state.copyWith(leaveType: event.leaveType)));
  }

  void _onSickNotesPicked(HrToolsSickNotesPicked event, Emitter<HrToolsState> emit) {
    emit(state.copyWith(sickNoteFiles: event.files, sickNoteFileNames: event.fileNames));
  }

  void _onSickNoteRemoved(HrToolsSickNoteRemoved event, Emitter<HrToolsState> emit) {
    if (event.index < 0 || event.index >= state.sickNoteFiles.length) return;
    emit(
      state.copyWith(
        sickNoteFiles: [...state.sickNoteFiles]..removeAt(event.index),
        sickNoteFileNames: [...state.sickNoteFileNames]..removeAt(event.index),
      ),
    );
  }

  void _onApprovalModeChanged(HrToolsApprovalModeChanged event, Emitter<HrToolsState> emit) {
    // Drop any previous failure report — it describes a submission made under
    // the other mode and would be misleading if it survived the switch.
    emit(state.copyWith(autoApprove: event.autoApprove, submissionFailures: [], submissionSuccessCount: 0));
  }

  Future<void> _onBulkLeaveSubmitted(HrToolsBulkLeaveSubmitted event, Emitter<HrToolsState> emit) async {
    final errors = _validateLeaveForm();
    if (errors.isNotEmpty) {
      emit(state.copyWith(validationErrors: errors));
      return;
    }

    emit(
      state.copyWith(
        isSubmitting: true,
        clearErrorMessage: true,
        clearSuccessMessage: true,
        submissionFailures: [],
        submissionSuccessCount: 0,
      ),
    );

    try {
      final dateFrom = state.dateFrom!;
      final dateTo = state.dateTo!;
      final days = dateTo.difference(dateFrom).inDays + 1;
      final total = state.selectedEmployees.length;

      if (state.autoApprove) {
        // hrCode is only meaningful here — in the normal cycle HR is not the approver.
        final hrCode = userBloc.state.user?.id;
        if (hrCode == null) throw Exception('HR user not found');

        final createdIds = await leaveRequestsRepo.submitBulkLeaveRequests(
          employees: state.selectedEmployees,
          dateFrom: dateFrom,
          dateTo: dateTo,
          leaveType: state.leaveType,
          numberOfDays: days.toDouble(),
          hrApproverCode: hrCode,
        );

        final noteFailed = await _attachSickNotes(createdIds);

        emit(
          state.copyWith(
            isSubmitting: false,
            successMessage: noteFailed ? 'bulk_leaves_success_note_failed' : 'bulk_leaves_success',
            submissionSuccessCount: total,
            selectedEmployees: [],
            clearDateFrom: true,
            clearDateTo: true,
            validationErrors: {},
            sickNoteFiles: [],
            sickNoteFileNames: [],
          ),
        );
        return;
      }

      final result = await leaveRequestsRepo.submitBulkLeaveRequestsForApproval(
        employees: state.selectedEmployees,
        dateFrom: dateFrom,
        dateTo: dateTo,
        leaveType: state.leaveType,
        numberOfDays: days.toDouble(),
      );
      final failures = result.failures;
      final cleanRun = failures.isEmpty;

      final noteFailed = await _attachSickNotes(result.createdIds);

      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage:
              cleanRun
                  ? (noteFailed ? 'bulk_leaves_success_note_failed' : 'bulk_leaves_success')
                  : 'bulk_leaves_partial',
          submissionFailures: failures,
          submissionSuccessCount: total - failures.length,
          // Keep the rejected employees (and the dates) in the form so HR can
          // adjust and retry just those; only a clean run clears everything.
          selectedEmployees: cleanRun ? [] : failures.map((f) => f.employee).toList(),
          clearDateFrom: cleanRun,
          clearDateTo: cleanRun,
          validationErrors: {},
          // Nothing was created when every employee was rejected, so the staged
          // report was never uploaded — keep it for the retry.
          sickNoteFiles: result.createdIds.isEmpty ? null : const [],
          sickNoteFileNames: result.createdIds.isEmpty ? null : const [],
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }

  /// Uploads the staged medical report onto the one request that was created.
  /// Returns `true` if the upload was attempted and failed.
  ///
  /// Only ever fires for a single created request — see
  /// [HrToolsState.canAttachSickNote]. Awaited and caught deliberately: the
  /// employee-side equivalent (request_leave_bloc.dart) fires this without
  /// `await` or `try`, so a storage error there silently leaves `attachments`
  /// NULL after the user has already been told "success". The request row here
  /// is already committed and cannot be rolled back, so the honest thing is to
  /// report the partial outcome rather than hide it.
  Future<bool> _attachSickNotes(List<int> createdIds) async {
    if (state.sickNoteFiles.isEmpty || createdIds.length != 1) return false;
    try {
      await leaveRequestsRepo.uploadSickNote(state.sickNoteFiles, state.sickNoteFileNames, createdIds.single);
      return false;
    } catch (_) {
      return true;
    }
  }

  void _onOvertimeDeltaChanged(HrToolsOvertimeDeltaChanged event, Emitter<HrToolsState> emit) {
    final errors = Map<String, String>.from(state.validationErrors)..remove('overtimeDelta');
    emit(state.copyWith(overtimeDelta: event.delta, validationErrors: errors));
  }

  Future<void> _onBulkOvertimeSubmitted(HrToolsBulkOvertimeSubmitted event, Emitter<HrToolsState> emit) async {
    final errors = _validateOvertimeForm();
    if (errors.isNotEmpty) {
      emit(state.copyWith(validationErrors: errors));
      return;
    }

    emit(state.copyWith(isSubmitting: true, clearErrorMessage: true, clearSuccessMessage: true));

    try {
      await usersRepo.incrementOvertimeBalances(
        userIds: state.selectedEmployees.map((e) => e.id!).toList(),
        delta: state.overtimeDelta,
        actorCode: userBloc.state.user?.id,
      );

      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage: 'bulk_overtime_success',
          selectedEmployees: [],
          overtimeDelta: 0,
          validationErrors: {},
        ),
      );
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
    }
  }

  void _onFormReset(HrToolsFormReset event, Emitter<HrToolsState> emit) {
    emit(HrToolsState(tabIndex: state.tabIndex));
  }

  void _onMessageCleared(HrToolsMessageCleared event, Emitter<HrToolsState> emit) {
    emit(state.copyWith(clearSuccessMessage: true, clearErrorMessage: true));
  }

  Map<String, String> _validateLeaveForm() {
    final errors = <String, String>{};
    if (state.selectedEmployees.isEmpty) {
      errors['employees'] = 'selectEmployeesFirst';
    }
    if (state.dateFrom == null) {
      errors['dateFrom'] = 'pleaseSelectDate';
    }
    if (state.dateTo == null) {
      errors['dateTo'] = 'pleaseSelectDate';
    }
    if (state.dateFrom != null && state.dateTo != null && state.dateTo!.isBefore(state.dateFrom!)) {
      errors['dateTo'] = 'invalidDateRange';
    }
    return errors;
  }

  Map<String, String> _validateOvertimeForm() {
    final errors = <String, String>{};
    if (state.selectedEmployees.isEmpty) {
      errors['employees'] = 'selectEmployeesFirst';
    }
    if (state.overtimeDelta <= 0) {
      errors['overtimeDelta'] = 'invalidDaysToAdd';
    }
    return errors;
  }

  List<UserModel> get selectedEmployees => state.selectedEmployees;
}
