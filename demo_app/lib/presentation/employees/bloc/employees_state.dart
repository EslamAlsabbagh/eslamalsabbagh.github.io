import 'package:equatable/equatable.dart';
import 'package:hrms_demo/data/models/user_model.dart';

enum EmployeesStatus { initial, loading, loaded, requestsLoaded, error, adding, updating, deleting }

class EmployeesState extends Equatable {
  final EmployeesStatus status;
  final List<UserModel> employees;
  final List<UserModel> filteredEmployees;
  final String searchTerm;
  final String? errorMessage;
  final String? successMessage;
  final bool isSearching;
  final bool hasReachedMax; // New
  final int page; // New
  final int pageSize; // New
  final List<dynamic> employeeRequests; // New
  final bool isSuspended; // New

  final int userCode;
  final String requestType;
  final List<UserModel> n1SearchResults;
  final bool isSearchingN1;

  const EmployeesState({
    this.status = EmployeesStatus.initial,
    this.employees = const [],
    this.filteredEmployees = const [],
    this.searchTerm = '',
    this.errorMessage,
    this.successMessage,
    this.isSearching = false,
    this.hasReachedMax = false,
    this.page = 0,
    this.pageSize = 10,
    this.employeeRequests = const [],
    this.userCode = 0,
    this.requestType = '',
    this.isSuspended = false,
    this.n1SearchResults = const [],
    this.isSearchingN1 = false,
  });

  EmployeesState copyWith({
    EmployeesStatus? status,
    List<UserModel>? employees,
    List<UserModel>? filteredEmployees,
    String? searchTerm,
    String? errorMessage,
    String? successMessage,
    bool? isSearching,
    bool? hasReachedMax,
    int? page,
    int? pageSize,
    List<dynamic>? employeeRequests,
    int? userCode,
    String? requestType,
    bool? isSuspended,
    List<UserModel>? n1SearchResults,
    bool? isSearchingN1,
  }) {
    return EmployeesState(
      status: status ?? this.status,
      employees: employees ?? this.employees,
      filteredEmployees: filteredEmployees ?? this.filteredEmployees,
      searchTerm: searchTerm ?? this.searchTerm,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
      isSearching: isSearching ?? this.isSearching,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      employeeRequests: employeeRequests ?? this.employeeRequests,
      userCode: userCode ?? this.userCode,
      requestType: requestType ?? this.requestType,
      isSuspended: isSuspended ?? this.isSuspended,
      n1SearchResults: n1SearchResults ?? this.n1SearchResults,
      isSearchingN1: isSearchingN1 ?? this.isSearchingN1,
    );
  }

  @override
  List<Object?> get props => [
    status,
    employees,
    filteredEmployees,
    searchTerm,
    errorMessage,
    successMessage,
    isSearching,
    hasReachedMax,
    page,
    pageSize,
    employeeRequests,
    userCode,
    requestType,
    isSuspended,
    n1SearchResults,
    isSearchingN1,
  ];
}
