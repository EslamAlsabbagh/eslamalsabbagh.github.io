import 'package:hrms_demo/core/bases/base_state.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/disabled_date_info.dart';

final class RequestBusinesstripState extends BaseState {
  final bool isSubmitting;
  final bool isFormValid;
  final int requestId;
  final bool other;
  final int numberOfDays;
  final int? numberOfHours;
  final String? amPm;
  final bool showHourFields;
  final List<DisabledDateInfo> disabledDates;
  final bool disabledDatesLoaded;
  final bool locationDeservesFee;
  final bool feeRequested;
  final double? feeAmount;
  const RequestBusinesstripState({
    super.status = Status.initial,
    super.failure,
    this.isSubmitting = false,
    this.isFormValid = false,
    this.requestId = 0,
    this.other = false,
    this.numberOfDays = 0,
    this.numberOfHours,
    this.amPm,
    this.showHourFields = false,
    this.disabledDates = const [],
    this.disabledDatesLoaded = false,
    this.locationDeservesFee = false,
    this.feeRequested = false,
    this.feeAmount,
  });
  RequestBusinesstripState copyWith({
    Status? status,
    dynamic failure,
    bool? isSubmitting,
    bool? isFormValid,
    int? requestId,
    bool? other,
    int? numberOfDays,
    Object? numberOfHours = const _Unset(),
    Object? amPm = const _Unset(),
    bool? showHourFields,
    List<DisabledDateInfo>? disabledDates,
    bool? disabledDatesLoaded,
    bool? locationDeservesFee,
    bool? feeRequested,
    Object? feeAmount = const _Unset(),
  }) {
    return RequestBusinesstripState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isFormValid: isFormValid ?? this.isFormValid,
      requestId: requestId ?? this.requestId,
      other: other ?? this.other,
      numberOfDays: numberOfDays ?? this.numberOfDays,
      numberOfHours: numberOfHours is _Unset ? this.numberOfHours : numberOfHours as int?,
      amPm: amPm is _Unset ? this.amPm : amPm as String?,
      showHourFields: showHourFields ?? this.showHourFields,
      disabledDates: disabledDates ?? this.disabledDates,
      disabledDatesLoaded: disabledDatesLoaded ?? this.disabledDatesLoaded,
      locationDeservesFee: locationDeservesFee ?? this.locationDeservesFee,
      feeRequested: feeRequested ?? this.feeRequested,
      feeAmount: feeAmount is _Unset ? this.feeAmount : feeAmount as double?,
    );
  }

  @override
  List<Object?> get props =>
      super.props..addAll([
        isSubmitting,
        isFormValid,
        requestId,
        other,
        numberOfDays,
        numberOfHours,
        amPm,
        showHourFields,
        disabledDates,
        disabledDatesLoaded,
        locationDeservesFee,
        feeRequested,
        feeAmount,
      ]);
}

// Sentinel class to differentiate between null and unset
class _Unset {
  const _Unset();
}
