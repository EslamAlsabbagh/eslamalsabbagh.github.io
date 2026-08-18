import 'dart:typed_data';

import 'package:hrms_demo/core/bases/base_state.dart';
import 'package:hrms_demo/core/constants/leave_type.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/disabled_date_info.dart';

final class RequestLeaveState extends BaseState {
  final bool isSubmitting;
  final double dayCount;
  final bool isFormValid;
  final LeaveType? leaveType;
  final List<Uint8List> sickNoteFiles;
  final List<String>? sickNoteFileNames;
  final int requestId;
  final List<DisabledDateInfo> disabledDates;
  final bool disabledDatesLoaded;

  const RequestLeaveState({
    super.status = Status.initial,
    super.failure,
    this.isSubmitting = false,
    this.dayCount = 0,
    this.isFormValid = false,
    this.leaveType,
    this.sickNoteFiles = const [],
    this.sickNoteFileNames = const [],
    this.requestId = 0,
    this.disabledDates = const [],
    this.disabledDatesLoaded = false,
  });
  RequestLeaveState copyWith({
    Status? status,
    dynamic failure,
    bool? isSubmitting,
    double? dayCount,
    bool? isFormValid,
    LeaveType? leaveType,
    List<Uint8List>? sickNoteFiles,
    List<String>? sickNoteFileNames,
    int? requestId,
    List<DisabledDateInfo>? disabledDates,
    bool? disabledDatesLoaded,
  }) {
    return RequestLeaveState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      dayCount: dayCount ?? this.dayCount,
      isFormValid: isFormValid ?? this.isFormValid,
      leaveType: leaveType ?? this.leaveType,
      sickNoteFiles: sickNoteFiles ?? this.sickNoteFiles,
      sickNoteFileNames: sickNoteFileNames ?? this.sickNoteFileNames,
      requestId: requestId ?? this.requestId,
      disabledDates: disabledDates ?? this.disabledDates,
      disabledDatesLoaded: disabledDatesLoaded ?? this.disabledDatesLoaded,
    );
  }

  @override
  List<Object?> get props =>
      super.props..addAll([
        isSubmitting,
        dayCount,
        isFormValid,
        leaveType,
        sickNoteFiles,
        sickNoteFileNames,
        requestId,
        disabledDates,
        disabledDatesLoaded,
      ]);
}
