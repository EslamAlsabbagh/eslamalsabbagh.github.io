import 'package:equatable/equatable.dart';
import 'package:hrms_demo/core/constants/employee_type_selection.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/models/advance_on_salary_request_model.dart';

abstract class AdvanceOnSalaryEvent extends Equatable {
  const AdvanceOnSalaryEvent();

  @override
  List<Object?> get props => [];
}

class InitializeAdvanceOnSalaryForm extends AdvanceOnSalaryEvent {}

class SearchEmployees extends AdvanceOnSalaryEvent {
  final String searchTerm;

  const SearchEmployees(this.searchTerm);

  @override
  List<Object> get props => [searchTerm];
}

class SelectEmployee extends AdvanceOnSalaryEvent {
  final UserModel employee;

  const SelectEmployee(this.employee);

  @override
  List<Object> get props => [employee];
}

class UpdateAmountRequested extends AdvanceOnSalaryEvent {
  final double amount;

  const UpdateAmountRequested(this.amount);

  @override
  List<Object> get props => [amount];
}

class UpdatePeriodInMonths extends AdvanceOnSalaryEvent {
  final int months;

  const UpdatePeriodInMonths(this.months);

  @override
  List<Object> get props => [months];
}

class UpdatePaymentStartDate extends AdvanceOnSalaryEvent {
  final DateTime startDate;

  const UpdatePaymentStartDate(this.startDate);

  @override
  List<Object> get props => [startDate];
}

class CalculateFields extends AdvanceOnSalaryEvent {}

class ClearSearchResults extends AdvanceOnSalaryEvent {}

class ResetForm extends AdvanceOnSalaryEvent {}

class ValidateForm extends AdvanceOnSalaryEvent {}

class FetchServerDate extends AdvanceOnSalaryEvent {}

class FetchAllManagedEmployees extends AdvanceOnSalaryEvent {}

class FetchAllIndirectEmployees extends AdvanceOnSalaryEvent {}

class FetchAllDeepSubordinates extends AdvanceOnSalaryEvent {}

class ToggleEmployeeType extends AdvanceOnSalaryEvent {
  final EmployeeTypeSelection employeeType;

  const ToggleEmployeeType(this.employeeType);

  @override
  List<Object> get props => [employeeType];
}

class SubmitAdvanceOnSalaryRequest extends AdvanceOnSalaryEvent {
  final AdvanceOnSalaryRequestModel request;

  const SubmitAdvanceOnSalaryRequest(this.request);

  @override
  List<Object> get props => [request];
}

class CheckPendingRequest extends AdvanceOnSalaryEvent {
  final int userCode;

  const CheckPendingRequest(this.userCode);

  @override
  List<Object> get props => [userCode];
}
