import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/core/constants/employee_type_selection.dart';
import 'package:hrms_demo/core/utils/search_filter_utils.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_action_request_repo.dart';
import 'package:hrms_demo/data/repos/investigation_request/investigation_request_repo.dart';
import 'package:hrms_demo/presentation/disciplinary_action/bloc/disciplinary_action_event.dart';
import 'package:hrms_demo/presentation/disciplinary_action/bloc/disciplinary_action_state.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';

class ValidationResult {
  final Map<String, String> errors;
  final bool isValid;

  ValidationResult({required this.errors, required this.isValid});
}

class DisciplinaryActionBloc extends Bloc<DisciplinaryActionEvent, DisciplinaryActionState> {
  final UsersRepo usersRepo;
  final UserBloc userBloc;
  final DisciplinaryActionRequestRepo disciplinaryActionRepo;
  final InvestigationRequestRepo investigationRepo;

  DisciplinaryActionBloc({
    required this.usersRepo,
    required this.userBloc,
    required this.disciplinaryActionRepo,
    required this.investigationRepo,
  }) : super(DisciplinaryActionInitial()) {
    on<InitializeDisciplinaryActionForm>(_onInitializeForm);
    on<SearchEmployees>(_onSearchEmployees);
    on<SelectEmployee>(_onSelectEmployee);
    on<UpdateViolationCategory>(_onUpdateViolationCategory);
    on<UpdateSelectedViolation>(_onUpdateSelectedViolation);
    on<UpdateActionType>(_onUpdateActionType);
    on<UpdateIncidentDescription>(_onUpdateIncidentDescription);
    on<UpdateViolationDate>(_onUpdateViolationDate);
    on<UpdateDeductDays>(_onUpdateDeductDays);
    on<ClearSearchResults>(_onClearSearchResults);
    on<ResetForm>(_onResetForm);
    on<ValidateForm>(_onValidateForm);
    on<FetchServerDate>(_onFetchServerDate);
    on<FetchAllManagedEmployees>(_onFetchAllManagedEmployees);
    on<FetchAllIndirectEmployees>(_onFetchAllIndirectEmployees);
    on<FetchAllDeepSubordinates>(_onFetchAllDeepSubordinates);
    on<ToggleEmployeeType>(_onToggleEmployeeType);
    on<CheckEmployeeWarningsHistory>(_onCheckEmployeeWarningsHistory);
    on<SubmitDisciplinaryActionRequest>(_onSubmitRequest);
    on<SubmitInvestigationRequest>(_onSubmitInvestigationRequest);
    on<CheckPendingRequest>(_onCheckPendingRequest);
    on<UpdateAttachments>(_onUpdateAttachments);
    on<UploadAttachmentFiles>(_onUploadAttachmentFiles);
    on<RemoveAttachment>(_onRemoveAttachment);
    on<SwitchFormMode>(_onSwitchFormMode);
    on<AddEmployeeToSelection>(_onAddEmployeeToSelection);
    on<RemoveEmployeeFromSelection>(_onRemoveEmployeeFromSelection);
    on<ClearSelectedEmployees>(_onClearSelectedEmployees);
  }

  void _onInitializeForm(InitializeDisciplinaryActionForm event, Emitter<DisciplinaryActionState> emit) {
    emit(DisciplinaryActionLoading());

    // Fetch managed employees first, which will then trigger server date fetch
    add(FetchAllManagedEmployees());
  }

  Future<void> _onSearchEmployees(SearchEmployees event, Emitter<DisciplinaryActionState> emit) async {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      emit(currentState.copyWith(isSearching: true, searchQuery: event.searchTerm));

      try {
        // Get the current user's code from UserBloc
        final currentUser = userBloc.state.user;
        if (currentUser?.id == null) {
          emit(currentState.copyWith(employeeSearchResults: [], isSearching: false));
          return;
        }

        // Use different repository method based on employee type
        final List<UserModel> employees;
        switch (currentState.employeeType) {
          case EmployeeTypeSelection.direct:
            employees = await usersRepo.searchManagedEmployees(event.searchTerm, currentUser!.id!);
          case EmployeeTypeSelection.indirect:
            employees = await usersRepo.searchIndirectEmployees(event.searchTerm, currentUser!.id!);
          case EmployeeTypeSelection.allSubordinates:
            employees = await usersRepo.searchDeepSubordinates(event.searchTerm, currentUser!.id!);
        }
        SearchFilterUtils.sortByRelevance(employees, event.searchTerm);
        emit(currentState.copyWith(employeeSearchResults: employees.take(5).toList(), isSearching: false));
      } catch (e) {
        emit(currentState.copyWith(employeeSearchResults: [], isSearching: false));
      }
    }
  }

  void _onSelectEmployee(SelectEmployee event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      emit(currentState.copyWith(selectedEmployee: event.employee, employeeSearchResults: [], searchQuery: ''));

      // Check employee's warnings history when selected
      add(CheckEmployeeWarningsHistory(event.employee.id!));
      add(CheckPendingRequest(event.employee.id!));
    }
  }

  void _onUpdateViolationCategory(UpdateViolationCategory event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      // Clear selected violation when category changes
      // Also remove 'selectedViolation' from touched fields so error doesn't show immediately
      final updatedTouchedFields = Set<String>.from(currentState.touchedFields)..remove('selectedViolation');
      final newState = currentState.copyWith(
        violationCategory: event.category,
        selectedViolation: null,
        touchedFields: updatedTouchedFields,
      );
      _emitWithValidation(newState, emit, {'violationCategory'});
    }
  }

  void _onUpdateSelectedViolation(UpdateSelectedViolation event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      final newState = currentState.copyWith(selectedViolation: event.violation);
      _emitWithValidation(newState, emit, {'selectedViolation'});
    }
  }

  void _onUpdateActionType(UpdateActionType event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      // Clear written warning options if not written warning
      final newState = currentState.copyWith(
        actionType: event.actionType,
        deductDays: event.actionType != DisciplinaryActionType.writtenWarning ? null : currentState.deductDays,
      );

      // Validate after update
      _emitWithValidation(newState, emit, {'actionType'});
    }
  }

  void _onUpdateIncidentDescription(UpdateIncidentDescription event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      final newState = currentState.copyWith(incidentDescription: event.description);
      _emitWithValidation(newState, emit, {'incidentDescription'});
    }
  }

  void _onUpdateViolationDate(UpdateViolationDate event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      final newState = currentState.copyWith(violationDate: event.violationDate);
      _emitWithValidation(newState, emit, {'violationDate'});
    }
  }

  void _onUpdateDeductDays(UpdateDeductDays event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      final newState = currentState.copyWith(deductDays: event.days);
      _emitWithValidation(newState, emit, {'deductDays'});
    }
  }

  void _onClearSearchResults(ClearSearchResults event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      emit(currentState.copyWith(employeeSearchResults: [], searchQuery: ''));
    }
  }

  void _onResetForm(ResetForm event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      emit(
        DisciplinaryActionFormState(
          formMode: currentState.formMode, // Preserve form mode
          serverDate: currentState.serverDate, // Preserve server date
          isLoadingServerDate: currentState.isLoadingServerDate,
          allManagedEmployees: currentState.allManagedEmployees, // Preserve managed employees
          allIndirectEmployees: currentState.allIndirectEmployees,
          allDeepSubordinates: currentState.allDeepSubordinates,
          employeeType: currentState.employeeType,
          isLoadingAllEmployees: currentState.isLoadingAllEmployees,
        ),
      );
    } else {
      emit(const DisciplinaryActionFormState());
    }
  }

  void _onValidateForm(ValidateForm event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      final validationResult = _validateForm(currentState);
      // When explicitly validating, mark all fields as touched and show all errors
      final allFields = {
        'employee',
        'employees',
        'violationCategory',
        'selectedViolation',
        'actionType',
        'incidentDescription',
        'violationDate',
        'deductDays',
      };
      emit(
        currentState.copyWith(
          validationErrors: validationResult.errors,
          isFormValid: validationResult.isValid,
          touchedFields: allFields,
        ),
      );
    }
  }

  Future<void> _onFetchServerDate(FetchServerDate event, Emitter<DisciplinaryActionState> emit) async {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      emit(currentState.copyWith(isLoadingServerDate: true));
      try {
        final serverDate = await usersRepo.getCurrentServerDate();
        emit(currentState.copyWith(serverDate: serverDate, isLoadingServerDate: false));
      } catch (e) {
        emit(currentState.copyWith(isLoadingServerDate: false));
      }
    }
    // If state is loading, we'll let the managed employees loading complete first
    // and the server date will be fetched after the form state is emitted
  }

  Future<void> _onFetchAllManagedEmployees(
    FetchAllManagedEmployees event,
    Emitter<DisciplinaryActionState> emit,
  ) async {
    final currentState = state;

    try {
      // Get the current user's code from UserBloc
      final currentUser = userBloc.state.user;
      if (currentUser?.id == null) {
        if (currentState is DisciplinaryActionFormState) {
          emit(currentState.copyWith(isLoadingAllEmployees: false));
        } else {
          emit(const DisciplinaryActionFormState(isLoadingAllEmployees: false));
        }
        return;
      }

      final employees = await usersRepo.getAllManagedEmployees(currentUser!.id!);

      // Emit form state with loaded employees
      if (currentState is DisciplinaryActionFormState) {
        // Preserve existing state including formMode
        emit(
          currentState.copyWith(
            allManagedEmployees: employees,
            isLoadingAllEmployees: false,
            isLoadingServerDate: true, // Still loading server date
          ),
        );
      } else {
        // First initialization - create new state
        emit(
          DisciplinaryActionFormState(
            allManagedEmployees: employees,
            isLoadingAllEmployees: false,
            isLoadingServerDate: true, // Still loading server date
          ),
        );
      }

      // Now fetch server date in the background
      add(FetchServerDate());
    } catch (e) {
      if (currentState is DisciplinaryActionFormState) {
        emit(currentState.copyWith(isLoadingAllEmployees: false));
      } else {
        emit(const DisciplinaryActionFormState(isLoadingAllEmployees: false));
      }
    }
  }

  Future<void> _onFetchAllIndirectEmployees(
    FetchAllIndirectEmployees event,
    Emitter<DisciplinaryActionState> emit,
  ) async {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      emit(currentState.copyWith(isLoadingAllEmployees: true));

      try {
        // Get the current user's code from UserBloc
        final currentUser = userBloc.state.user;
        if (currentUser?.id == null) {
          emit(currentState.copyWith(allIndirectEmployees: [], isLoadingAllEmployees: false));
          return;
        }

        final employees = await usersRepo.getAllIndirectEmployees(currentUser!.id!);

        if (state is DisciplinaryActionFormState) {
          final latestState = state as DisciplinaryActionFormState;
          emit(latestState.copyWith(allIndirectEmployees: employees, isLoadingAllEmployees: false));
        }
      } catch (e) {
        if (state is DisciplinaryActionFormState) {
          emit((state as DisciplinaryActionFormState).copyWith(allIndirectEmployees: [], isLoadingAllEmployees: false));
        }
      }
    }
  }

  Future<void> _onFetchAllDeepSubordinates(
    FetchAllDeepSubordinates event,
    Emitter<DisciplinaryActionState> emit,
  ) async {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      emit(currentState.copyWith(isLoadingAllEmployees: true));

      try {
        // Get the current user's code from UserBloc
        final currentUser = userBloc.state.user;
        if (currentUser?.id == null) {
          emit(currentState.copyWith(allDeepSubordinates: [], isLoadingAllEmployees: false));
          return;
        }

        final employees = await usersRepo.getAllDeepSubordinates(currentUser!.id!);

        if (state is DisciplinaryActionFormState) {
          final latestState = state as DisciplinaryActionFormState;
          emit(latestState.copyWith(allDeepSubordinates: employees, isLoadingAllEmployees: false));
        }
      } catch (e) {
        if (state is DisciplinaryActionFormState) {
          emit((state as DisciplinaryActionFormState).copyWith(allDeepSubordinates: [], isLoadingAllEmployees: false));
        }
      }
    }
  }

  void _onToggleEmployeeType(ToggleEmployeeType event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      // Clear selection and search results when toggling
      // Create a fresh state to reset all fields properly
      emit(
        DisciplinaryActionFormState(
          formMode: currentState.formMode, // Preserve form mode
          employeeType: event.employeeType,
          allManagedEmployees: currentState.allManagedEmployees,
          allIndirectEmployees: currentState.allIndirectEmployees,
          allDeepSubordinates: currentState.allDeepSubordinates,
          serverDate: currentState.serverDate,
          isLoadingServerDate: currentState.isLoadingServerDate,
        ),
      );

      // Fetch the appropriate employee list
      switch (event.employeeType) {
        case EmployeeTypeSelection.direct:
          add(FetchAllManagedEmployees());
        case EmployeeTypeSelection.indirect:
          add(FetchAllIndirectEmployees());
        case EmployeeTypeSelection.allSubordinates:
          add(FetchAllDeepSubordinates());
      }
    }
  }

  Future<void> _onCheckEmployeeWarningsHistory(
    CheckEmployeeWarningsHistory event,
    Emitter<DisciplinaryActionState> emit,
  ) async {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      emit(currentState.copyWith(isLoadingWarningsHistory: true));
      try {
        // Get warnings from last 6 months
        final sixMonthsAgo = DateTime.now().subtract(Duration(days: 180));
        final warningsCount = await disciplinaryActionRepo.getWrittenWarningsCount(
          event.employeeCode,
          sixMonthsAgo,
          DateTime.now(),
        );

        final history = await disciplinaryActionRepo.getEmployeeDisciplinaryHistory(event.employeeCode);

        final shouldTerminate = await disciplinaryActionRepo.shouldEmployeeBeTerminated(event.employeeCode);

        emit(
          currentState.copyWith(
            employeeWarningsHistory: history,
            currentWarningsCount: warningsCount,
            shouldShowTerminationWarning: shouldTerminate,
            isLoadingWarningsHistory: false,
          ),
        );
      } catch (e) {
        emit(currentState.copyWith(isLoadingWarningsHistory: false));
      }
    }
  }

  Future<void> _onSubmitRequest(SubmitDisciplinaryActionRequest event, Emitter<DisciplinaryActionState> emit) async {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      emit(currentState.copyWith(isSubmitting: true));
      try {
        final requestId = await disciplinaryActionRepo.submitDisciplinaryActionRequest(event.request);

        // Upload attachments if any
        if (currentState.attachmentFiles.isNotEmpty) {
          await disciplinaryActionRepo.uploadAttachments(
            currentState.attachmentFiles,
            currentState.attachmentFileNames,
            requestId,
          );
        }

        emit(currentState.copyWith(isSubmitting: false, isSubmissionSuccessful: true, submissionError: null));
      } catch (e) {
        emit(currentState.copyWith(isSubmitting: false, isSubmissionSuccessful: false, submissionError: e.toString()));
      }
    }
  }

  Future<void> _onSubmitInvestigationRequest(
    SubmitInvestigationRequest event,
    Emitter<DisciplinaryActionState> emit,
  ) async {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      emit(currentState.copyWith(isSubmitting: true));
      try {
        final investigationId = await investigationRepo.submitInvestigationRequest(event.request);

        // Upload attachments if any
        if (currentState.attachmentFiles.isNotEmpty) {
          await investigationRepo.uploadInvestigationAttachments(
            currentState.attachmentFiles,
            currentState.attachmentFileNames,
            investigationId,
          );
        }

        emit(currentState.copyWith(isSubmitting: false, isSubmissionSuccessful: true, submissionError: null));
      } catch (e) {
        emit(currentState.copyWith(isSubmitting: false, isSubmissionSuccessful: false, submissionError: e.toString()));
      }
    }
  }

  Future<void> _onCheckPendingRequest(CheckPendingRequest event, Emitter<DisciplinaryActionState> emit) async {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      emit(currentState.copyWith(isCheckingPendingRequest: true));
      try {
        final hasPending = await disciplinaryActionRepo.hasPendingRequest(event.employeeCode);
        emit(currentState.copyWith(hasPendingRequest: hasPending, isCheckingPendingRequest: false));
      } catch (e) {
        emit(currentState.copyWith(isCheckingPendingRequest: false));
      }
    }
  }

  void _onUpdateAttachments(UpdateAttachments event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      emit(currentState.copyWith(attachmentFiles: event.files, attachmentFileNames: event.fileNames));
    }
  }

  Future<void> _onUploadAttachmentFiles(UploadAttachmentFiles event, Emitter<DisciplinaryActionState> emit) async {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      emit(currentState.copyWith(isUploadingAttachments: true));
      try {
        await disciplinaryActionRepo.uploadAttachments(event.files, event.fileNames, event.requestId);
        emit(currentState.copyWith(isUploadingAttachments: false));
      } catch (e) {
        emit(currentState.copyWith(isUploadingAttachments: false));
      }
    }
  }

  void _onRemoveAttachment(RemoveAttachment event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      final updatedFiles = List<Uint8List>.from(currentState.attachmentFiles)..removeAt(event.index);
      final updatedNames = List<String>.from(currentState.attachmentFileNames)..removeAt(event.index);
      emit(currentState.copyWith(attachmentFiles: updatedFiles, attachmentFileNames: updatedNames));
    }
  }

  void _onSwitchFormMode(SwitchFormMode event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      // Clear form when switching modes, preserve employee lists and server date
      emit(
        DisciplinaryActionFormState(
          formMode: event.mode,
          serverDate: currentState.serverDate,
          isLoadingServerDate: currentState.isLoadingServerDate,
          allManagedEmployees: currentState.allManagedEmployees,
          allIndirectEmployees: currentState.allIndirectEmployees,
          allDeepSubordinates: currentState.allDeepSubordinates,
          employeeType: currentState.employeeType,
          isLoadingAllEmployees: currentState.isLoadingAllEmployees,
        ),
      );
    }
  }

  void _onAddEmployeeToSelection(AddEmployeeToSelection event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      // Check if employee is already selected
      if (currentState.selectedEmployees.any((e) => e.id == event.employee.id)) {
        return; // Already selected, do nothing
      }

      final updatedEmployees = [...currentState.selectedEmployees, event.employee];
      final newState = currentState.copyWith(
        selectedEmployees: updatedEmployees,
        employeeSearchResults: [],
        searchQuery: '',
      );
      _emitWithValidation(newState, emit, {'employees'});
    }
  }

  void _onRemoveEmployeeFromSelection(RemoveEmployeeFromSelection event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      final updatedEmployees = currentState.selectedEmployees.where((e) => e.id != event.employee.id).toList();
      final newState = currentState.copyWith(selectedEmployees: updatedEmployees);
      _emitWithValidation(newState, emit, {'employees'});
    }
  }

  void _onClearSelectedEmployees(ClearSelectedEmployees event, Emitter<DisciplinaryActionState> emit) {
    final currentState = state;
    if (currentState is DisciplinaryActionFormState) {
      final newState = currentState.copyWith(selectedEmployees: const []);
      _emitWithValidation(newState, emit, {'employees'});
    }
  }

  // Helper methods
  void _emitWithValidation(
    DisciplinaryActionFormState newState,
    Emitter<DisciplinaryActionState> emit,
    Set<String> updatedFields,
  ) {
    final validationResult = _validateForm(newState);
    final updatedTouchedFields = Set<String>.from(newState.touchedFields)..addAll(updatedFields);
    final filteredErrors = _filterErrorsByTouchedFields(validationResult.errors, updatedTouchedFields);

    emit(
      newState.copyWith(
        validationErrors: filteredErrors,
        isFormValid: validationResult.isValid,
        touchedFields: updatedTouchedFields,
      ),
    );
  }

  ValidationResult _validateForm(DisciplinaryActionFormState state) {
    final Map<String, String> errors = {};

    // Employee validation - different for each mode
    if (state.formMode == DisciplinaryFormMode.disciplinaryAction) {
      // Single employee validation
      if (state.selectedEmployee == null) {
        errors['employee'] = 'pleaseSelectEmployee';
      }
    } else {
      // Investigation mode - require at least one employee
      if (state.selectedEmployees.isEmpty) {
        errors['employees'] = 'pleaseSelectAtLeastOneEmployee';
      }
    }

    // Violation category validation
    if (state.violationCategory == null) {
      errors['violationCategory'] = 'pleaseSelectViolationCategory';
    }

    // Violation validation
    if (state.violationCategory != null) {
      if (state.violationCategory!.isOther) {
        // For "Other" category, require custom text with minimum length
        if (state.selectedViolation == null || state.selectedViolation!.trim().isEmpty) {
          errors['selectedViolation'] = 'pleaseDescribeViolation';
        } else if (state.selectedViolation!.trim().length < 10) {
          errors['selectedViolation'] = 'violationDescriptionTooShort';
        }
      } else {
        // For predefined categories, require selection from dropdown
        if (state.selectedViolation == null || state.selectedViolation!.isEmpty) {
          errors['selectedViolation'] = 'pleaseSelectViolation';
        }
      }
    }

    // Action type validation - ONLY for disciplinary action mode
    if (state.formMode == DisciplinaryFormMode.disciplinaryAction) {
      if (state.actionType == null) {
        errors['actionType'] = 'pleaseSelectActionType';
      }
    }

    // Incident description validation
    if (state.incidentDescription == null || state.incidentDescription!.trim().isEmpty) {
      errors['incidentDescription'] = 'pleaseProvideIncidentDetails';
    } else {
      final description = state.incidentDescription!.trim();
      // // Count letters only (excluding spaces, numbers, and special characters)
      // final letterCount = description.replaceAll(RegExp(r'[^a-zA-Z\u0600-\u06FF]'), '').length;
      // Count words (split by whitespace and filter empty strings)
      final wordCount = description.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;

      if (wordCount < 10) {
        errors['incidentDescription'] = 'incidentDescriptionTooShort';
      }
    }

    // Violation date validation
    if (state.violationDate == null) {
      errors['violationDate'] = 'pleaseSelectViolationDate';
    } else {
      final now = DateTime.now();
      if (state.violationDate!.isAfter(now)) {
        errors['violationDate'] = 'violationDateFuture';
      }
      // Check if violation date is more than 30 days ago
      final thirtyDaysAgo = now.subtract(Duration(days: 30));
      if (state.violationDate!.isBefore(thirtyDaysAgo)) {
        errors['violationDate'] = 'violationDateTooOld';
      }
    }

    // Written warning specific validations - ONLY for disciplinary action mode
    if (state.formMode == DisciplinaryFormMode.disciplinaryAction &&
        state.actionType == DisciplinaryActionType.writtenWarning) {
      // Validate deduct days if provided - allowed values: 0.25, 0.5, 1, 2, 3, 4, 5
      if (state.deductDays != null && state.deductDays! > 0) {
        const allowedDeductDays = [0.25, 0.5, 1.0, 2.0, 3.0, 4.0, 5.0];
        if (!allowedDeductDays.contains(state.deductDays)) {
          errors['deductDays'] = 'invalidDeductDays';
        }
      }
    }

    return ValidationResult(errors: errors, isValid: errors.isEmpty);
  }

  Map<String, String> _filterErrorsByTouchedFields(Map<String, String> allErrors, Set<String> touchedFields) {
    final filteredErrors = <String, String>{};
    for (final field in touchedFields) {
      if (allErrors.containsKey(field)) {
        filteredErrors[field] = allErrors[field]!;
      }
    }
    return filteredErrors;
  }
}
