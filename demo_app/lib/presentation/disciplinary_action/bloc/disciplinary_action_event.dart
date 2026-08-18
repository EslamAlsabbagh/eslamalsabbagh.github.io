import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:hrms_demo/core/constants/employee_type_selection.dart';
import 'package:hrms_demo/core/constants/violation_category.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'package:hrms_demo/data/models/investigation_request_model.dart';
import 'package:hrms_demo/presentation/disciplinary_action/bloc/disciplinary_action_state.dart';

abstract class DisciplinaryActionEvent extends Equatable {
  const DisciplinaryActionEvent();

  @override
  List<Object?> get props => [];
}

class InitializeDisciplinaryActionForm extends DisciplinaryActionEvent {}

class SearchEmployees extends DisciplinaryActionEvent {
  final String searchTerm;

  const SearchEmployees(this.searchTerm);

  @override
  List<Object> get props => [searchTerm];
}

class SelectEmployee extends DisciplinaryActionEvent {
  final UserModel employee;

  const SelectEmployee(this.employee);

  @override
  List<Object> get props => [employee];
}

class UpdateViolationCategory extends DisciplinaryActionEvent {
  final ViolationCategory? category;

  const UpdateViolationCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class UpdateSelectedViolation extends DisciplinaryActionEvent {
  final String? violation;

  const UpdateSelectedViolation(this.violation);

  @override
  List<Object?> get props => [violation];
}

class UpdateActionType extends DisciplinaryActionEvent {
  final DisciplinaryActionType actionType;

  const UpdateActionType(this.actionType);

  @override
  List<Object> get props => [actionType];
}

class UpdateIncidentDescription extends DisciplinaryActionEvent {
  final String description;

  const UpdateIncidentDescription(this.description);

  @override
  List<Object> get props => [description];
}

class UpdateViolationDate extends DisciplinaryActionEvent {
  final DateTime violationDate;

  const UpdateViolationDate(this.violationDate);

  @override
  List<Object> get props => [violationDate];
}

class UpdateDeductDays extends DisciplinaryActionEvent {
  final double? days;

  const UpdateDeductDays(this.days);

  @override
  List<Object?> get props => [days];
}

class ClearSearchResults extends DisciplinaryActionEvent {}

class ResetForm extends DisciplinaryActionEvent {}

class ValidateForm extends DisciplinaryActionEvent {
  final Map<String, String>? errorMessages;

  const ValidateForm([this.errorMessages]);

  @override
  List<Object?> get props => [errorMessages];
}

class FetchServerDate extends DisciplinaryActionEvent {}

class FetchAllManagedEmployees extends DisciplinaryActionEvent {}

class FetchAllIndirectEmployees extends DisciplinaryActionEvent {}

class FetchAllDeepSubordinates extends DisciplinaryActionEvent {}

class ToggleEmployeeType extends DisciplinaryActionEvent {
  final EmployeeTypeSelection employeeType;

  const ToggleEmployeeType(this.employeeType);

  @override
  List<Object> get props => [employeeType];
}

class CheckEmployeeWarningsHistory extends DisciplinaryActionEvent {
  final int employeeCode;

  const CheckEmployeeWarningsHistory(this.employeeCode);

  @override
  List<Object> get props => [employeeCode];
}

class SubmitDisciplinaryActionRequest extends DisciplinaryActionEvent {
  final DisciplinaryActionRequestModel request;

  const SubmitDisciplinaryActionRequest(this.request);

  @override
  List<Object> get props => [request];
}

class SubmitInvestigationRequest extends DisciplinaryActionEvent {
  final InvestigationRequestModel request;

  const SubmitInvestigationRequest(this.request);

  @override
  List<Object> get props => [request];
}

class CheckPendingRequest extends DisciplinaryActionEvent {
  final int employeeCode;

  const CheckPendingRequest(this.employeeCode);

  @override
  List<Object> get props => [employeeCode];
}

class UpdateAttachments extends DisciplinaryActionEvent {
  final List<Uint8List> files;
  final List<String> fileNames;

  const UpdateAttachments(this.files, this.fileNames);

  @override
  List<Object> get props => [files, fileNames];
}

class UploadAttachmentFiles extends DisciplinaryActionEvent {
  final List<Uint8List> files;
  final List<String> fileNames;
  final int requestId;

  const UploadAttachmentFiles(this.files, this.fileNames, this.requestId);

  @override
  List<Object> get props => [files, fileNames, requestId];
}

class RemoveAttachment extends DisciplinaryActionEvent {
  final int index;

  const RemoveAttachment(this.index);

  @override
  List<Object> get props => [index];
}

class SwitchFormMode extends DisciplinaryActionEvent {
  final DisciplinaryFormMode mode;

  const SwitchFormMode(this.mode);

  @override
  List<Object> get props => [mode];
}

class AddEmployeeToSelection extends DisciplinaryActionEvent {
  final UserModel employee;

  const AddEmployeeToSelection(this.employee);

  @override
  List<Object> get props => [employee];
}

class RemoveEmployeeFromSelection extends DisciplinaryActionEvent {
  final UserModel employee;

  const RemoveEmployeeFromSelection(this.employee);

  @override
  List<Object> get props => [employee];
}

class ClearSelectedEmployees extends DisciplinaryActionEvent {}
