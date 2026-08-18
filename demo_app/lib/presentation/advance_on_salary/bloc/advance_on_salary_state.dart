import 'package:equatable/equatable.dart';
import 'package:hrms_demo/core/constants/employee_type_selection.dart';
import 'package:hrms_demo/data/models/user_model.dart';

abstract class AdvanceOnSalaryState extends Equatable {
  const AdvanceOnSalaryState();

  @override
  List<Object?> get props => [];
}

class AdvanceOnSalaryInitial extends AdvanceOnSalaryState {}

class AdvanceOnSalaryLoading extends AdvanceOnSalaryState {}

class AdvanceOnSalaryFormState extends AdvanceOnSalaryState {
  final UserModel? selectedEmployee;
  final String? hireDate;
  final double? amountRequested;
  final String amountInLettersArabic;
  final String amountInLettersEnglish;
  final int? periodInMonths;
  final DateTime? paymentStartDate;
  final DateTime? paymentEndDate;
  final double? monthlyPayment;
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

  const AdvanceOnSalaryFormState({
    this.selectedEmployee,
    this.hireDate,
    this.amountRequested,
    this.amountInLettersArabic = '',
    this.amountInLettersEnglish = '',
    this.periodInMonths,
    this.paymentStartDate,
    this.paymentEndDate,
    this.monthlyPayment,
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
  });

  AdvanceOnSalaryFormState copyWith({
    UserModel? selectedEmployee,
    String? hireDate,
    double? amountRequested,
    String? amountInLettersArabic,
    String? amountInLettersEnglish,
    int? periodInMonths,
    DateTime? paymentStartDate,
    DateTime? paymentEndDate,
    double? monthlyPayment,
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
  }) {
    return AdvanceOnSalaryFormState(
      selectedEmployee: selectedEmployee ?? this.selectedEmployee,
      hireDate: hireDate ?? this.hireDate,
      amountRequested: amountRequested ?? this.amountRequested,
      amountInLettersArabic: amountInLettersArabic ?? this.amountInLettersArabic,
      amountInLettersEnglish: amountInLettersEnglish ?? this.amountInLettersEnglish,
      periodInMonths: periodInMonths ?? this.periodInMonths,
      paymentStartDate: paymentStartDate ?? this.paymentStartDate,
      paymentEndDate: paymentEndDate ?? this.paymentEndDate,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
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
    );
  }

  @override
  List<Object?> get props => [
    selectedEmployee,
    hireDate,
    amountRequested,
    amountInLettersArabic,
    amountInLettersEnglish,
    periodInMonths,
    paymentStartDate,
    paymentEndDate,
    monthlyPayment,
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
  ];
}

class AdvanceOnSalaryError extends AdvanceOnSalaryState {
  final String message;

  const AdvanceOnSalaryError(this.message);

  @override
  List<Object> get props => [message];
}
