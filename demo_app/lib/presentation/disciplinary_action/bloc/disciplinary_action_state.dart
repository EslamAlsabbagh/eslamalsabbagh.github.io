import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:hrms_demo/core/constants/employee_type_selection.dart';
import 'package:hrms_demo/core/constants/violation_category.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';

const _undefined = Object();

enum DisciplinaryFormMode { disciplinaryAction, investigation }

abstract class DisciplinaryActionState extends Equatable {
  const DisciplinaryActionState();

  @override
  List<Object?> get props => [];
}

class DisciplinaryActionInitial extends DisciplinaryActionState {}

class DisciplinaryActionLoading extends DisciplinaryActionState {}

class DisciplinaryActionFormState extends DisciplinaryActionState {
  final DisciplinaryFormMode formMode;
  final UserModel? selectedEmployee;
  final List<UserModel> selectedEmployees;
  final ViolationCategory? violationCategory;
  final String? selectedViolation;
  final DisciplinaryActionType? actionType;
  final String? incidentDescription;
  final DateTime? violationDate;
  final double? deductDays;
  final List<UserModel> employeeSearchResults;
  final List<UserModel> allManagedEmployees;
  final List<UserModel> allIndirectEmployees;
  final List<UserModel> allDeepSubordinates;
  final EmployeeTypeSelection employeeType;
  final bool isSearching;
  final bool isLoadingAllEmployees;
  final String searchQuery;
  final int? userCode;
  final Map<String, String> validationErrors;
  final bool isFormValid;
  final Set<String> touchedFields;
  final DateTime? serverDate;
  final bool isLoadingServerDate;
  final bool isSubmitting;
  final bool isSubmissionSuccessful;
  final String? submissionError;
  final bool hasPendingRequest;
  final bool isCheckingPendingRequest;
  final List<DisciplinaryActionRequestModel> employeeWarningsHistory;
  final bool isLoadingWarningsHistory;
  final int currentWarningsCount;
  final bool shouldShowTerminationWarning;
  final List<Uint8List> attachmentFiles;
  final List<String> attachmentFileNames;
  final bool isUploadingAttachments;

  const DisciplinaryActionFormState({
    this.formMode = DisciplinaryFormMode.disciplinaryAction,
    this.selectedEmployee,
    this.selectedEmployees = const [],
    this.violationCategory,
    this.selectedViolation,
    this.actionType,
    this.incidentDescription,
    this.violationDate,
    this.deductDays,
    this.employeeSearchResults = const [],
    this.allManagedEmployees = const [],
    this.allIndirectEmployees = const [],
    this.allDeepSubordinates = const [],
    this.employeeType = EmployeeTypeSelection.direct,
    this.isSearching = false,
    this.isLoadingAllEmployees = false,
    this.searchQuery = '',
    this.userCode,
    this.validationErrors = const {},
    this.isFormValid = false,
    this.touchedFields = const {},
    this.serverDate,
    this.isLoadingServerDate = false,
    this.isSubmitting = false,
    this.isSubmissionSuccessful = false,
    this.submissionError,
    this.hasPendingRequest = false,
    this.isCheckingPendingRequest = false,
    this.employeeWarningsHistory = const [],
    this.isLoadingWarningsHistory = false,
    this.currentWarningsCount = 0,
    this.shouldShowTerminationWarning = false,
    this.attachmentFiles = const [],
    this.attachmentFileNames = const [],
    this.isUploadingAttachments = false,
  });

  DisciplinaryActionFormState copyWith({
    DisciplinaryFormMode? formMode,
    UserModel? selectedEmployee,
    List<UserModel>? selectedEmployees,
    Object? violationCategory = _undefined,
    Object? selectedViolation = _undefined,
    DisciplinaryActionType? actionType,
    String? incidentDescription,
    DateTime? violationDate,
    Object? deductDays = _undefined,
    List<UserModel>? employeeSearchResults,
    List<UserModel>? allManagedEmployees,
    List<UserModel>? allIndirectEmployees,
    List<UserModel>? allDeepSubordinates,
    EmployeeTypeSelection? employeeType,
    bool? isSearching,
    bool? isLoadingAllEmployees,
    String? searchQuery,
    int? userCode,
    Map<String, String>? validationErrors,
    bool? isFormValid,
    Set<String>? touchedFields,
    DateTime? serverDate,
    bool? isLoadingServerDate,
    bool? isSubmitting,
    bool? isSubmissionSuccessful,
    String? submissionError,
    bool? hasPendingRequest,
    bool? isCheckingPendingRequest,
    List<DisciplinaryActionRequestModel>? employeeWarningsHistory,
    bool? isLoadingWarningsHistory,
    int? currentWarningsCount,
    bool? shouldShowTerminationWarning,
    List<Uint8List>? attachmentFiles,
    List<String>? attachmentFileNames,
    bool? isUploadingAttachments,
  }) {
    return DisciplinaryActionFormState(
      formMode: formMode ?? this.formMode,
      selectedEmployee: selectedEmployee ?? this.selectedEmployee,
      selectedEmployees: selectedEmployees ?? this.selectedEmployees,
      violationCategory:
          violationCategory == _undefined ? this.violationCategory : violationCategory as ViolationCategory?,
      selectedViolation: selectedViolation == _undefined ? this.selectedViolation : selectedViolation as String?,
      actionType: actionType ?? this.actionType,
      incidentDescription: incidentDescription ?? this.incidentDescription,
      violationDate: violationDate ?? this.violationDate,
      deductDays: deductDays == _undefined ? this.deductDays : deductDays as double?,
      employeeSearchResults: employeeSearchResults ?? this.employeeSearchResults,
      allManagedEmployees: allManagedEmployees ?? this.allManagedEmployees,
      allIndirectEmployees: allIndirectEmployees ?? this.allIndirectEmployees,
      allDeepSubordinates: allDeepSubordinates ?? this.allDeepSubordinates,
      employeeType: employeeType ?? this.employeeType,
      isSearching: isSearching ?? this.isSearching,
      isLoadingAllEmployees: isLoadingAllEmployees ?? this.isLoadingAllEmployees,
      searchQuery: searchQuery ?? this.searchQuery,
      userCode: userCode ?? this.userCode,
      validationErrors: validationErrors ?? this.validationErrors,
      isFormValid: isFormValid ?? this.isFormValid,
      touchedFields: touchedFields ?? this.touchedFields,
      serverDate: serverDate ?? this.serverDate,
      isLoadingServerDate: isLoadingServerDate ?? this.isLoadingServerDate,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmissionSuccessful: isSubmissionSuccessful ?? this.isSubmissionSuccessful,
      submissionError: submissionError ?? this.submissionError,
      hasPendingRequest: hasPendingRequest ?? this.hasPendingRequest,
      isCheckingPendingRequest: isCheckingPendingRequest ?? this.isCheckingPendingRequest,
      employeeWarningsHistory: employeeWarningsHistory ?? this.employeeWarningsHistory,
      isLoadingWarningsHistory: isLoadingWarningsHistory ?? this.isLoadingWarningsHistory,
      currentWarningsCount: currentWarningsCount ?? this.currentWarningsCount,
      shouldShowTerminationWarning: shouldShowTerminationWarning ?? this.shouldShowTerminationWarning,
      attachmentFiles: attachmentFiles ?? this.attachmentFiles,
      attachmentFileNames: attachmentFileNames ?? this.attachmentFileNames,
      isUploadingAttachments: isUploadingAttachments ?? this.isUploadingAttachments,
    );
  }

  @override
  List<Object?> get props => [
    formMode,
    selectedEmployee,
    selectedEmployees,
    violationCategory,
    selectedViolation,
    actionType,
    incidentDescription,
    violationDate,
    deductDays,
    employeeSearchResults,
    allManagedEmployees,
    allIndirectEmployees,
    allDeepSubordinates,
    employeeType,
    isSearching,
    isLoadingAllEmployees,
    searchQuery,
    userCode,
    validationErrors,
    isFormValid,
    touchedFields,
    serverDate,
    isLoadingServerDate,
    isSubmitting,
    isSubmissionSuccessful,
    submissionError,
    hasPendingRequest,
    isCheckingPendingRequest,
    employeeWarningsHistory,
    isLoadingWarningsHistory,
    currentWarningsCount,
    shouldShowTerminationWarning,
    attachmentFiles,
    attachmentFileNames,
    isUploadingAttachments,
  ];
}

class DisciplinaryActionError extends DisciplinaryActionState {
  final String message;

  const DisciplinaryActionError(this.message);

  @override
  List<Object> get props => [message];
}
