import 'dart:async';
import 'package:hrms_demo/core/utils/search_filter_utils.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_action_request_repo.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_request_repo.dart';
import 'package:hrms_demo/data/repos/investigation_request/investigation_request_repo.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunching_request_repo.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_request_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_event.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_state.dart';
import 'package:hrms_demo/data/repos/auth/auth_repo.dart';

class EmployeesBloc extends Bloc<EmployeesEvent, EmployeesState> {
  final UsersRepo _employeeRepository;
  final MissingpunchingRequestsRepo _missingPunchingRequestRepository;
  final OvertimeRequestRepo _overtimeRequestRepository;
  final LeaveRequestsRepo _leaveRequestRepository;
  final BusinesstripRequestsRepo _businessTripRequestRepository;
  final AdvanceOnSalaryRequestsRepo _advanceOnSalaryRequestRepository;
  final HrLetterRequestRepo _hrLetterRequestRepository;
  final DisciplinaryActionRequestRepo _disciplinaryActionRequestRepository;
  final InvestigationRequestRepo _investigationRequestRepository;
  final AuthRepo _authRepo;
  EmployeesBloc({
    required UsersRepo employeeRepository,
    required MissingpunchingRequestsRepo missingPunchingRequestRepository,
    required OvertimeRequestRepo overtimeRequestRepository,
    required LeaveRequestsRepo leaveRequestRepository,
    required BusinesstripRequestsRepo businessTripRequestRepository,
    required AdvanceOnSalaryRequestsRepo advanceOnSalaryRequestRepository,
    required HrLetterRequestRepo hrLetterRequestRepository,
    required DisciplinaryActionRequestRepo disciplinaryActionRequestRepository,
    required InvestigationRequestRepo investigationRequestRepository,
    required AuthRepo authRepo,
  }) : _employeeRepository = employeeRepository,
       _missingPunchingRequestRepository = missingPunchingRequestRepository,
       _overtimeRequestRepository = overtimeRequestRepository,
       _leaveRequestRepository = leaveRequestRepository,
       _businessTripRequestRepository = businessTripRequestRepository,
       _advanceOnSalaryRequestRepository = advanceOnSalaryRequestRepository,
       _hrLetterRequestRepository = hrLetterRequestRepository,
       _disciplinaryActionRequestRepository = disciplinaryActionRequestRepository,
       _investigationRequestRepository = investigationRequestRepository,
       _authRepo = authRepo,
       super(const EmployeesState()) {
    on<LoadEmployees>(_onLoadEmployees);
    on<LoadMoreEmployees>(_onLoadMoreEmployees); // New event registration
    on<SearchEmployees>(_onSearchEmployees);
    on<AddEmployee>(_onAddEmployee);
    on<UpdateEmployee>(_onUpdateEmployee);
    on<RefreshEmployees>(_onRefreshEmployees);
    on<RefreshEditedEmployee>(_onRefreshEditedEmployee);
    on<ClearSearch>(_onClearSearch);
    on<LoadEmployeeRequests>(_onLoadEmployeeRequests);
    on<SuspendEmployee>(_onSuspendEmployee);
    on<UnsuspendEmployee>(_onUnsuspendEmployee);
    on<isEmployeeSuspended>(_onIsEmployeeSuspended);
    on<AddUserToGroup>(_onAddUserToGroup);
    on<RemoveUserFromGroup>(_onRemoveUserFromGroup);
    on<RefreshEmployeesPreservingSearch>(_onRefreshEmployeesPreservingSearch);
    on<ResetEmployeePassword>(_onResetEmployeePassword);
    on<SearchActiveEmployeesForReassignment>(_onSearchActiveEmployeesForReassignment);
    on<SuspendWithReassignment>(_onSuspendWithReassignment);
  }

  @override
  Future<void> close() {
    return super.close();
  }

  Future<void> _onLoadEmployees(LoadEmployees event, Emitter<EmployeesState> emit) async {
    emit(state.copyWith(status: EmployeesStatus.loading, page: 0, hasReachedMax: false)); // Reset pagination state

    try {
      final employees = await _employeeRepository.getUsers(locale: event.locale);
      final hasReachedMax = employees.length < state.pageSize;
      emit(
        state.copyWith(
          status: EmployeesStatus.loaded,
          employees: employees,
          filteredEmployees: employees,
          errorMessage: null,
          hasReachedMax: hasReachedMax,
          page: 1, // First page loaded
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: EmployeesStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> _onLoadMoreEmployees(LoadMoreEmployees event, Emitter<EmployeesState> emit) async {
    if (state.hasReachedMax) return;

    emit(state.copyWith(status: EmployeesStatus.loading));

    try {
      final newEmployees = await _employeeRepository.getPaginatedEmployees(
        offset: state.page * state.pageSize,
        limit: state.pageSize,
        locale: event.locale,
      );

      final hasReachedMax = newEmployees.length < state.pageSize;
      final updatedEmployees = List<UserModel>.from(state.employees)..addAll(newEmployees);

      emit(
        state.copyWith(
          status: EmployeesStatus.loaded,
          employees: updatedEmployees,
          filteredEmployees: updatedEmployees, // Assuming filtered also updates with new data
          hasReachedMax: hasReachedMax,
          page: state.page + 1,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: EmployeesStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> _onSearchEmployees(SearchEmployees event, Emitter<EmployeesState> emit) async {
    if (event.searchTerm.isEmpty) {
      emit(state.copyWith(filteredEmployees: state.employees, searchTerm: '', isSearching: false));
      return;
    }

    emit(state.copyWith(searchTerm: event.searchTerm, isSearching: true));

    try {
      final results = await _employeeRepository.searchEmployees(event.searchTerm, locale: event.locale);
      final filteredEmployees = _applySearchFilter(results, event.searchTerm);

      emit(
        state.copyWith(
          filteredEmployees: filteredEmployees,
          isSearching: true, // Keep searching state active
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isSearching: true, // Keep searching state active even on error
          errorMessage: 'Search failed: ${error.toString()}',
        ),
      );
    }
  }

  Future<void> _onAddEmployee(AddEmployee event, Emitter<EmployeesState> emit) async {
    emit(state.copyWith(status: EmployeesStatus.adding));

    try {
      final newEmployee = await _employeeRepository.addEmployee(event.employee);
      // Use admin API to create auth account WITHOUT creating a session
      await _authRepo.createEmployeeAuthAccount('123456', newEmployee.authEmail!);
      final updatedEmployees = List<UserModel>.from(state.employees)..add(newEmployee);

      // Apply current search if exists
      final filteredEmployees = _applySearchFilter(updatedEmployees, state.searchTerm);

      emit(
        state.copyWith(
          status: EmployeesStatus.loaded,
          employees: updatedEmployees,
          filteredEmployees: filteredEmployees,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: EmployeesStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> _onUpdateEmployee(UpdateEmployee event, Emitter<EmployeesState> emit) async {
    emit(state.copyWith(status: EmployeesStatus.updating));

    try {
      final updatedEmployee = await _employeeRepository.updateEmployee(event.employee, actorCode: event.actorCode);
      final updatedEmployees =
          state.employees.map((employee) {
            return employee.id == updatedEmployee.id ? updatedEmployee : employee;
          }).toList();

      // Apply current search if exists
      final filteredEmployees = _applySearchFilter(updatedEmployees, state.searchTerm);

      emit(
        state.copyWith(
          status: EmployeesStatus.loaded,
          employees: updatedEmployees,
          filteredEmployees: filteredEmployees,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: EmployeesStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> _onRefreshEmployees(RefreshEmployees event, Emitter<EmployeesState> emit) async {
    // If there's an active search, use the preserving search refresh
    if (state.isSearching && state.searchTerm.isNotEmpty) {
      add(RefreshEmployeesPreservingSearch(locale: event.locale));
    } else {
      add(LoadEmployees(locale: event.locale));
    }
  }

  Future<void> _onRefreshEditedEmployee(RefreshEditedEmployee event, Emitter<EmployeesState> emit) async {
    // Only emit a single loading state to avoid multiple state changes
    if (state.status != EmployeesStatus.loading) {
      emit(state.copyWith(status: EmployeesStatus.loading));
    }

    try {
      // Get the updated employee by ID
      final updatedEmployee = await _employeeRepository.getEmployeeById(event.employeeId);

      // Find the index of the employee in the current list
      final employeeIndex = state.employees.indexWhere((e) => e.id == event.employeeId);
      final filteredIndex = state.filteredEmployees.indexWhere((e) => e.id == event.employeeId);

      if (employeeIndex != -1) {
        // Create new lists with the updated employee
        final updatedEmployees = List<UserModel>.from(state.employees);
        updatedEmployees[employeeIndex] = updatedEmployee;

        final updatedFilteredEmployees = List<UserModel>.from(state.filteredEmployees);
        if (filteredIndex != -1) {
          updatedFilteredEmployees[filteredIndex] = updatedEmployee;
        }

        // Emit only one state update with the changes
        emit(
          state.copyWith(
            status: EmployeesStatus.loaded,
            employees: updatedEmployees,
            filteredEmployees: updatedFilteredEmployees,
            successMessage: null, // Clear any previous success messages
          ),
        );
      } else {
        // If employee not found in list, refresh the entire list
        add(const RefreshEmployees(locale: null));
      }
    } catch (error) {
      emit(
        state.copyWith(status: EmployeesStatus.error, errorMessage: 'Failed to refresh employee: ${error.toString()}'),
      );
    }
  }

  Future<void> _onClearSearch(ClearSearch event, Emitter<EmployeesState> emit) async {
    emit(state.copyWith(filteredEmployees: state.employees, searchTerm: '', isSearching: false));
  }

  Future<void> _onLoadEmployeeRequests(LoadEmployeeRequests event, Emitter<EmployeesState> emit) async {
    // Clear previous employee requests and set loading status
    emit(
      state.copyWith(
        status: EmployeesStatus.loading,
        employeeRequests: [], // Clear old requests
      ),
    );

    try {
      // Load all types of requests for the employee
      final List<dynamic> allRequests = [];

      // Load missing punching requests
      try {
        final missingPunchingRequests = await _missingPunchingRequestRepository.getMyMissingpunchingRequests(
          int.parse(event.employeeId),
        );
        allRequests.addAll(missingPunchingRequests);
      } catch (e) {
        // Continue with other request types even if one fails
      }

      // Load overtime requests
      try {
        final overtimeRequests = await _overtimeRequestRepository.getMyOvertimeRequests(int.parse(event.employeeId));
        allRequests.addAll(overtimeRequests);
      } catch (e) {
        // Continue with other request types even if one fails
      }

      // Load leave requests
      try {
        final leaveRequests = await _leaveRequestRepository.getMyLeaveRequests(int.parse(event.employeeId));
        allRequests.addAll(leaveRequests);
      } catch (e) {
        // Continue with other request types even if one fails
      }

      // Load business trip requests
      try {
        final businessTripRequests = await _businessTripRequestRepository.getMybusinesstripRequests(
          int.parse(event.employeeId),
        );
        allRequests.addAll(businessTripRequests);
      } catch (e) {
        // Continue with other request types even if one fails
      }

      // Load advance on salary requests
      try {
        final advanceOnSalaryRequests = await _advanceOnSalaryRequestRepository.getMyAdvanceOnSalaryRequests(
          int.parse(event.employeeId),
        );
        allRequests.addAll(advanceOnSalaryRequests);
      } catch (e) {
        // Continue with other request types even if one fails
      }

      // Load HR letter requests
      try {
        final hrLetterRequests = await _hrLetterRequestRepository.getMyHrLetterRequests(int.parse(event.employeeId));
        allRequests.addAll(hrLetterRequests);
      } catch (e) {
        // Continue with other request types even if one fails
      }

      // Load disciplinary action requests (both made by and made against the employee)
      try {
        final userCode = int.parse(event.employeeId);
        final dasByEmployee = await _disciplinaryActionRequestRepository.getDisciplinaryActionRequestsAsParty(userCode);
        final dasAgainstEmployee = await _disciplinaryActionRequestRepository.getEmployeeDisciplinaryHistory(userCode);
        // Merge and deduplicate by id
        final daMap = <int, dynamic>{};
        for (final da in [...dasByEmployee, ...dasAgainstEmployee]) {
          if (da.id != null) daMap[da.id!] = da;
        }
        allRequests.addAll(daMap.values);
      } catch (e) {
        // Continue with other request types even if one fails
      }

      // Load investigation requests (already returns both initiated by and targeting the employee)
      try {
        final investigations = await _investigationRequestRepository.getMyInvestigationRequests(
          int.parse(event.employeeId),
        );
        allRequests.addAll(investigations);
      } catch (e) {
        // Continue with other request types even if one fails
      }

      emit(
        state.copyWith(
          status: EmployeesStatus.requestsLoaded,
          employeeRequests: allRequests,
          userCode: int.parse(event.employeeId),
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: EmployeesStatus.error,
          userCode: int.parse(event.employeeId),
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSuspendEmployee(SuspendEmployee event, Emitter<EmployeesState> emit) async {
    try {
      // Clear groups and stamp the suspension reason/last-working-date before
      // suspending. These are plain `users` columns, so they ride the normal
      // updateEmployee path rather than the separate suspended_users insert.
      final employee = await _employeeRepository.getEmployeeById(event.employeeId);
      final updatedEmployee = employee.copyWith(
        groups: <String>[],
        suspensionReason: event.suspensionReason,
        lastWorkingDate: event.lastWorkingDate,
      );
      await _employeeRepository.updateEmployee(updatedEmployee);

      await _employeeRepository.suspendEmployee(event.employeeId);

      // Refresh the employee in-place so UI picks up cleared groups immediately
      final refreshedEmployee = await _employeeRepository.getEmployeeById(event.employeeId);
      final updatedEmployees = List<UserModel>.from(state.employees);
      final employeeIndex = updatedEmployees.indexWhere((e) => e.id == event.employeeId);
      if (employeeIndex != -1) {
        updatedEmployees[employeeIndex] = refreshedEmployee;
      }
      final updatedFiltered = List<UserModel>.from(state.filteredEmployees);
      final filteredIndex = updatedFiltered.indexWhere((e) => e.id == event.employeeId);
      if (filteredIndex != -1) {
        updatedFiltered[filteredIndex] = refreshedEmployee;
      }

      emit(
        state.copyWith(
          status: EmployeesStatus.loaded,
          employees: updatedEmployees,
          filteredEmployees: updatedFiltered,
          isSuspended: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(status: EmployeesStatus.error, errorMessage: 'Failed to suspend employee: ${error.toString()}'),
      );
    }
  }

  Future<void> _onUnsuspendEmployee(UnsuspendEmployee event, Emitter<EmployeesState> emit) async {
    try {
      await _employeeRepository.unsuspendEmployee(event.employeeId);
      // Optionally, you can refresh the employee list after unsuspension
      add(const LoadEmployees(locale: null));

      emit(state.copyWith(isSuspended: false));
    } catch (error) {
      emit(
        state.copyWith(
          status: EmployeesStatus.error,
          errorMessage: 'Failed to unsuspend employee: ${error.toString()}',
        ),
      );
    }
  }

  Future<void> _onIsEmployeeSuspended(isEmployeeSuspended event, Emitter<EmployeesState> emit) async {
    try {
      final isSuspended = await _employeeRepository.isEmployeeSuspended(event.employeeId);
      emit(state.copyWith(isSuspended: isSuspended));
    } catch (error) {
      emit(
        state.copyWith(
          status: EmployeesStatus.error,
          errorMessage: 'Failed to check employee suspension status: ${error.toString()}',
        ),
      );
    }
  }

  Future<void> _onAddUserToGroup(AddUserToGroup event, Emitter<EmployeesState> emit) async {
    emit(state.copyWith(status: EmployeesStatus.updating));

    try {
      // Get current employee
      final employee = await _employeeRepository.getEmployeeById(event.employeeId);

      // Safely convert groups to List<String>
      final currentGroups = <String>[];
      if (employee.groups != null) {
        for (final group in employee.groups!) {
          currentGroups.add(group);
        }
      }

      // Check if user is already in the group
      if (currentGroups.contains(event.group.toLowerCase())) {
        emit(state.copyWith(status: EmployeesStatus.error, errorMessage: 'USER_ALREADY_IN_GROUP:${event.group}'));
        return;
      }

      // Add the group
      currentGroups.add(event.group.toLowerCase());

      // Update the employee with new groups
      final updatedEmployee = employee.copyWith(groups: currentGroups);

      // Update via repository
      await _employeeRepository.updateEmployee(updatedEmployee);

      // Refresh the edited employee (this will emit the loaded state)
      add(RefreshEditedEmployee(event.employeeId));
    } catch (error) {
      emit(state.copyWith(status: EmployeesStatus.error, errorMessage: 'FAILED_ADD_TO_GROUP:${error.toString()}'));
    }
  }

  Future<void> _onRemoveUserFromGroup(RemoveUserFromGroup event, Emitter<EmployeesState> emit) async {
    emit(state.copyWith(status: EmployeesStatus.updating));

    try {
      // Get current employee
      final employee = await _employeeRepository.getEmployeeById(event.employeeId);

      // Safely convert groups to List<String>
      final currentGroups = <String>[];
      if (employee.groups != null) {
        for (final group in employee.groups!) {
          currentGroups.add(group);
        }
      }

      // Check if user is in the group
      if (!currentGroups.contains(event.group.toLowerCase())) {
        emit(state.copyWith(status: EmployeesStatus.error, errorMessage: 'USER_NOT_IN_GROUP:${event.group}'));
        return;
      }

      // Remove the group
      currentGroups.remove(event.group.toLowerCase());

      // Update the employee with new groups
      final updatedEmployee = employee.copyWith(groups: currentGroups);

      // Update via repository
      await _employeeRepository.updateEmployee(updatedEmployee);

      // Refresh the edited employee (this will emit the loaded state)
      add(RefreshEditedEmployee(event.employeeId));
    } catch (error) {
      emit(state.copyWith(status: EmployeesStatus.error, errorMessage: 'FAILED_REMOVE_FROM_GROUP:${error.toString()}'));
    }
  }

  Future<void> _onRefreshEmployeesPreservingSearch(
    RefreshEmployeesPreservingSearch event,
    Emitter<EmployeesState> emit,
  ) async {
    // Store current search state
    final currentSearchTerm = state.searchTerm;
    final isCurrentlySearching = state.isSearching;

    try {
      // Fetch fresh employees data
      final employees = await _employeeRepository.getUsers(locale: event.locale);

      // Re-run the same server-side search to preserve consistent ordering
      List<UserModel> filteredEmployees = employees;
      if (isCurrentlySearching && currentSearchTerm.isNotEmpty) {
        filteredEmployees = await _employeeRepository.searchEmployees(currentSearchTerm, locale: event.locale);
      }

      emit(
        state.copyWith(
          status: EmployeesStatus.loaded,
          employees: employees,
          filteredEmployees: filteredEmployees,
          searchTerm: currentSearchTerm, // Preserve search term
          isSearching: isCurrentlySearching, // Preserve search state
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: EmployeesStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> _onResetEmployeePassword(ResetEmployeePassword event, Emitter<EmployeesState> emit) async {
    emit(state.copyWith(status: EmployeesStatus.updating));

    try {
      await _authRepo.resetEmployeePassword(event.employeeCode);

      emit(state.copyWith(status: EmployeesStatus.loaded, errorMessage: null));
    } catch (error) {
      emit(state.copyWith(status: EmployeesStatus.error, errorMessage: error.toString()));
    }
  }

  Future<void> _onSearchActiveEmployeesForReassignment(
    SearchActiveEmployeesForReassignment event,
    Emitter<EmployeesState> emit,
  ) async {
    if (event.searchTerm.isEmpty) {
      emit(state.copyWith(n1SearchResults: [], isSearchingN1: false));
      return;
    }

    emit(state.copyWith(isSearchingN1: true));

    try {
      final results = await _employeeRepository.searchAllActiveEmployees(event.searchTerm);
      emit(state.copyWith(n1SearchResults: results.take(10).toList(), isSearchingN1: false));
    } catch (error) {
      emit(state.copyWith(isSearchingN1: false, errorMessage: 'Search failed: ${error.toString()}'));
    }
  }

  Future<void> _onSuspendWithReassignment(SuspendWithReassignment event, Emitter<EmployeesState> emit) async {
    emit(state.copyWith(status: EmployeesStatus.updating));

    try {
      // Step 1: Update N+1 for every managed employee.
      for (final entry in event.n1Assignments.entries) {
        final managedEmployee = await _employeeRepository.getEmployeeById(entry.key);
        final updated = managedEmployee.copyWith(n1: entry.value);
        await _employeeRepository.updateEmployee(updated);
      }

      // Step 2: Clear groups and stamp the suspension reason/last-working-date
      // before suspending (plain `users` columns via updateEmployee).
      final employee = await _employeeRepository.getEmployeeById(event.employeeId);
      final updatedEmployee = employee.copyWith(
        groups: <String>[],
        suspensionReason: event.suspensionReason,
        lastWorkingDate: event.lastWorkingDate,
      );
      await _employeeRepository.updateEmployee(updatedEmployee);

      // Step 3: Suspend the target employee.
      await _employeeRepository.suspendEmployee(event.employeeId);

      // Step 4: Refresh list and mark as suspended.
      add(const LoadEmployees(locale: null));
      add(RefreshEditedEmployee(event.employeeId));
      emit(state.copyWith(isSuspended: true));
    } catch (error) {
      emit(
        state.copyWith(
          status: EmployeesStatus.error,
          errorMessage: 'Failed to reassign and suspend: ${error.toString()}',
        ),
      );
    }
  }

  static List<UserModel> _applySearchFilter(List<UserModel> employees, String searchTerm) {
    if (searchTerm.isEmpty) return employees;
    final term = searchTerm.toLowerCase();
    final isNumeric = int.tryParse(searchTerm) != null;

    final filtered =
        employees.where((e) {
          final shortCode = ((e.id ?? 0) - 10000000).toString();
          return (e.englishName?.toLowerCase().contains(term) ?? false) ||
              (e.arabicName?.toLowerCase().contains(term) ?? false) ||
              (e.title?.toLowerCase().contains(term) ?? false) ||
              (e.englishTitle?.toLowerCase().contains(term) ?? false) ||
              (e.department?.toLowerCase().contains(term) ?? false) ||
              (e.englishDepartment?.toLowerCase().contains(term) ?? false) ||
              (isNumeric && shortCode.startsWith(searchTerm));
        }).toList();

    return SearchFilterUtils.sortByRelevance(filtered, searchTerm);
  }
}
