import 'package:equatable/equatable.dart';
import 'package:hrms_demo/data/models/user_model.dart';

abstract class EmployeesEvent extends Equatable {
  const EmployeesEvent();

  @override
  List<Object?> get props => [];
}

class LoadEmployees extends EmployeesEvent {
  final String? locale;

  const LoadEmployees({this.locale});
}

class LoadMoreEmployees extends EmployeesEvent {
  // New event
  final String? locale;

  const LoadMoreEmployees({this.locale});
}

class SearchEmployees extends EmployeesEvent {
  final String searchTerm;
  final String? locale;

  const SearchEmployees(this.searchTerm, {this.locale});

  @override
  List<Object?> get props => [searchTerm, locale];
}

class AddEmployee extends EmployeesEvent {
  final UserModel employee;

  const AddEmployee(this.employee);

  @override
  List<Object?> get props => [employee];
}

class UpdateEmployee extends EmployeesEvent {
  final UserModel employee;

  /// Code of the HR user performing the edit — recorded in the
  /// leave_balance_ledger audit rows for any balance that changes.
  final int? actorCode;

  const UpdateEmployee(this.employee, {this.actorCode});

  @override
  List<Object?> get props => [employee, actorCode];
}

class DeleteEmployee extends EmployeesEvent {
  final String employeeId;

  const DeleteEmployee(this.employeeId);

  @override
  List<Object?> get props => [employeeId];
}

class RefreshEmployees extends EmployeesEvent {
  final String? locale;

  const RefreshEmployees({this.locale});
}

class RefreshEditedEmployee extends EmployeesEvent {
  final int employeeId;

  const RefreshEditedEmployee(this.employeeId);

  @override
  List<Object?> get props => [employeeId];
}

class ClearSearch extends EmployeesEvent {
  const ClearSearch();
}

class LoadEmployeeRequests extends EmployeesEvent {
  final String employeeId;

  const LoadEmployeeRequests(this.employeeId);

  @override
  List<Object?> get props => [employeeId];
}

class SuspendEmployee extends EmployeesEvent {
  final int employeeId;

  /// Why the employee is being suspended: 'resignation' | 'termination' | 'other'.
  final String suspensionReason;

  /// Last working day — provided for resignation/termination, null for 'other'.
  final DateTime? lastWorkingDate;

  const SuspendEmployee(this.employeeId, {required this.suspensionReason, this.lastWorkingDate});

  @override
  List<Object?> get props => [employeeId, suspensionReason, lastWorkingDate];
}

class UnsuspendEmployee extends EmployeesEvent {
  final int employeeId;

  const UnsuspendEmployee(this.employeeId);

  @override
  List<Object?> get props => [employeeId];
}

class isEmployeeSuspended extends EmployeesEvent {
  final int employeeId;

  const isEmployeeSuspended(this.employeeId);

  @override
  List<Object?> get props => [employeeId];
}

class AddUserToGroup extends EmployeesEvent {
  final int employeeId;
  final String group;

  const AddUserToGroup({required this.employeeId, required this.group});

  @override
  List<Object?> get props => [employeeId, group];
}

class RemoveUserFromGroup extends EmployeesEvent {
  final int employeeId;
  final String group;

  const RemoveUserFromGroup({required this.employeeId, required this.group});

  @override
  List<Object?> get props => [employeeId, group];
}

class RefreshEmployeesPreservingSearch extends EmployeesEvent {
  final String? locale;

  const RefreshEmployeesPreservingSearch({this.locale});

  @override
  List<Object?> get props => [locale];
}

class ResetEmployeePassword extends EmployeesEvent {
  final String employeeCode;

  const ResetEmployeePassword(this.employeeCode);

  @override
  List<Object?> get props => [employeeCode];
}

class SearchActiveEmployeesForReassignment extends EmployeesEvent {
  final String searchTerm;

  const SearchActiveEmployeesForReassignment(this.searchTerm);

  @override
  List<Object?> get props => [searchTerm];
}

class SuspendWithReassignment extends EmployeesEvent {
  final int employeeId;

  /// Map of managedEmployee.id (Code) -> new N+1 Code
  final Map<int, int> n1Assignments;

  /// Why the employee is being suspended: 'resignation' | 'termination' | 'other'.
  final String suspensionReason;

  /// Last working day — provided for resignation/termination, null for 'other'.
  final DateTime? lastWorkingDate;

  const SuspendWithReassignment({
    required this.employeeId,
    required this.n1Assignments,
    required this.suspensionReason,
    this.lastWorkingDate,
  });

  @override
  List<Object?> get props => [employeeId, n1Assignments, suspensionReason, lastWorkingDate];
}
