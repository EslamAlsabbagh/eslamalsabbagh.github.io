import 'dart:typed_data';

import 'package:hrms_demo/core/constants/leave_type.dart';
import 'package:hrms_demo/data/models/leave_request_model.dart';

abstract class RequestLeaveEvent {}

class SubmitLeaveRequest extends RequestLeaveEvent {
  final LeaveRequestModel request;
  SubmitLeaveRequest(this.request);
}

class UpdateDateRange extends RequestLeaveEvent {
  final String? fromDate;
  final String? toDate;
  final int? leaveHours;
  final int? shiftHours;

  UpdateDateRange({this.fromDate, this.toDate, this.leaveHours, this.shiftHours});
}

class ValidateForm extends RequestLeaveEvent {
  final String fromDate;
  final String toDate;
  final String leaveType;
  final int? leaveHours;
  final int? shiftHours;

  ValidateForm({
    required this.fromDate,
    required this.toDate,
    required this.leaveType,
    required this.leaveHours,
    this.shiftHours,
  });
}

class ResetLeaveType extends RequestLeaveEvent {}

final class UploadSickNoteFiles extends RequestLeaveEvent {
  final List<Uint8List> files;
  final List<String>? fileNames;
  int requestId;

  UploadSickNoteFiles(this.files, this.fileNames, this.requestId);
}

class UpdateSickNotes extends RequestLeaveEvent {
  final List<Uint8List> sickNoteFiles;
  final List<String> sickNoteFileNames;

  UpdateSickNotes(this.sickNoteFiles, this.sickNoteFileNames);
}

class UpdateLeaveType extends RequestLeaveEvent {
  final LeaveType? leaveType;

  UpdateLeaveType(this.leaveType);
}

class LoadExistingLeaveRequests extends RequestLeaveEvent {
  final int userCode;

  LoadExistingLeaveRequests(this.userCode);
}
