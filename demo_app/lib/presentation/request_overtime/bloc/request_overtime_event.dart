import 'package:hrms_demo/core/constants/overtime_type.dart';
import 'package:hrms_demo/data/models/overtime_request_model.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class RequestOvertimeEvent {
  const RequestOvertimeEvent();
}

final class SubmitOvertimeRequest extends RequestOvertimeEvent {
  const SubmitOvertimeRequest(this.request);

  final OvertimeRequestModel request;
}

final class UpdateDateRange extends RequestOvertimeEvent {
  const UpdateDateRange({required this.fromDate, required this.toDate});

  final String fromDate;
  final String toDate;
}

final class ValidateForm extends RequestOvertimeEvent {
  const ValidateForm({required this.date, required this.fromTime, required this.toTime, required this.reason});

  final String date;
  final String fromTime;
  final String toTime;
  final String reason;
}

final class ChangeOvertimeType extends RequestOvertimeEvent {
  const ChangeOvertimeType(this.overtimeType);

  final OvertimeType overtimeType;
}
