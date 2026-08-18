import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/overtime_type.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:flutter/foundation.dart';

@immutable
class RequestOvertimeState {
  const RequestOvertimeState({
    this.status = Status.initial,
    this.failure,
    this.isFormValid = false,
    this.isSubmitting = false,
    this.numOfHours = 0,
    this.overtimeType = OvertimeType.holidays,
  });

  final Status status;
  final Failure? failure;
  final bool isFormValid;
  final bool isSubmitting;
  final num numOfHours;
  final OvertimeType overtimeType;

  RequestOvertimeState copyWith({
    Status? status,
    Failure? failure,
    bool? isFormValid,
    bool? isSubmitting,
    num? numOfHours,
    OvertimeType? overtimeType,
  }) {
    return RequestOvertimeState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      isFormValid: isFormValid ?? this.isFormValid,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      numOfHours: numOfHours ?? this.numOfHours,
      overtimeType: overtimeType ?? this.overtimeType,
    );
  }
}
