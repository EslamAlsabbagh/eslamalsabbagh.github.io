import 'package:hrms_demo/core/bases/base_state.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/disabled_date_info.dart';

final class RequestMissingpunchingState extends BaseState {
  final bool isSubmitting;
  final bool isFormValid;
  final int requestId;
  final String missingPunchType;
  final List<DisabledDateInfo> disabledDates;
  final bool disabledDatesLoaded;

  const RequestMissingpunchingState({
    super.status = Status.initial,
    super.failure,
    this.isSubmitting = false,
    this.isFormValid = false,
    this.requestId = 0,
    this.missingPunchType = "In",
    this.disabledDates = const [],
    this.disabledDatesLoaded = false,
  });
  RequestMissingpunchingState copyWith({
    Status? status,
    dynamic failure,
    bool? isSubmitting,
    bool? isFormValid,
    int? requestId,
    String? missingPunchType,
    List<DisabledDateInfo>? disabledDates,
    bool? disabledDatesLoaded,
  }) {
    return RequestMissingpunchingState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isFormValid: isFormValid ?? this.isFormValid,
      requestId: requestId ?? this.requestId,
      missingPunchType: missingPunchType ?? this.missingPunchType,
      disabledDates: disabledDates ?? this.disabledDates,
      disabledDatesLoaded: disabledDatesLoaded ?? this.disabledDatesLoaded,
    );
  }

  @override
  List<Object?> get props =>
      super.props..addAll([isSubmitting, isFormValid, requestId, missingPunchType, disabledDates, disabledDatesLoaded]);
}
