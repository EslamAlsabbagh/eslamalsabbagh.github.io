import 'dart:typed_data';

import 'package:hrms_demo/data/models/user_model.dart';
import 'package:equatable/equatable.dart';

sealed class HrToolsEvent extends Equatable {
  const HrToolsEvent();

  @override
  List<Object?> get props => [];
}

class HrToolsInitialized extends HrToolsEvent {
  const HrToolsInitialized();
}

class HrToolsEmployeeSearchChanged extends HrToolsEvent {
  final String query;
  const HrToolsEmployeeSearchChanged(this.query);

  @override
  List<Object?> get props => [query];
}

class HrToolsSearchCleared extends HrToolsEvent {
  const HrToolsSearchCleared();
}

class HrToolsEmployeeAdded extends HrToolsEvent {
  final UserModel employee;
  const HrToolsEmployeeAdded(this.employee);

  @override
  List<Object?> get props => [employee];
}

class HrToolsEmployeeRemoved extends HrToolsEvent {
  final UserModel employee;
  const HrToolsEmployeeRemoved(this.employee);

  @override
  List<Object?> get props => [employee];
}

class HrToolsAllEmployeesCleared extends HrToolsEvent {
  const HrToolsAllEmployeesCleared();
}

class HrToolsTabChanged extends HrToolsEvent {
  final int index;
  const HrToolsTabChanged(this.index);

  @override
  List<Object?> get props => [index];
}

class HrToolsLeaveDateFromChanged extends HrToolsEvent {
  final DateTime date;
  const HrToolsLeaveDateFromChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class HrToolsLeaveDateToChanged extends HrToolsEvent {
  final DateTime date;
  const HrToolsLeaveDateToChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class HrToolsLeaveTypeChanged extends HrToolsEvent {
  final String leaveType;
  const HrToolsLeaveTypeChanged(this.leaveType);

  @override
  List<Object?> get props => [leaveType];
}

/// Switches bulk leaves between force-approval and the normal N+1 cycle.
class HrToolsApprovalModeChanged extends HrToolsEvent {
  final bool autoApprove;
  const HrToolsApprovalModeChanged(this.autoApprove);

  @override
  List<Object?> get props => [autoApprove];
}

/// Files chosen from the medical-report picker; replaces whatever was staged.
class HrToolsSickNotesPicked extends HrToolsEvent {
  final List<Uint8List> files;
  final List<String> fileNames;
  const HrToolsSickNotesPicked(this.files, this.fileNames);

  @override
  List<Object?> get props => [files, fileNames];
}

class HrToolsSickNoteRemoved extends HrToolsEvent {
  final int index;
  const HrToolsSickNoteRemoved(this.index);

  @override
  List<Object?> get props => [index];
}

class HrToolsBulkLeaveSubmitted extends HrToolsEvent {
  const HrToolsBulkLeaveSubmitted();
}

class HrToolsOvertimeDeltaChanged extends HrToolsEvent {
  final double delta;
  const HrToolsOvertimeDeltaChanged(this.delta);

  @override
  List<Object?> get props => [delta];
}

class HrToolsBulkOvertimeSubmitted extends HrToolsEvent {
  const HrToolsBulkOvertimeSubmitted();
}

class HrToolsFormReset extends HrToolsEvent {
  const HrToolsFormReset();
}

class HrToolsMessageCleared extends HrToolsEvent {
  const HrToolsMessageCleared();
}
