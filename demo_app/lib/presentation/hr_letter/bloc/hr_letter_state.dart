import 'package:equatable/equatable.dart';

abstract class HrLetterState extends Equatable {
  const HrLetterState();

  @override
  List<Object?> get props => [];
}

class HrLetterInitial extends HrLetterState {}

class HrLetterLoading extends HrLetterState {}

class HrLetterFormState extends HrLetterState {
  final String? letterPurpose;
  final DateTime? travelFromDate;
  final DateTime? travelToDate;
  final String details;
  final String nationalId;
  final bool isNationalIdFromDb;
  final bool isEligible;
  final Map<String, String> validationErrors;
  final bool isFormValid;
  final bool isSubmitting;
  final bool isSubmissionSuccessful;
  final String? submissionError;

  const HrLetterFormState({
    this.letterPurpose,
    this.travelFromDate,
    this.travelToDate,
    this.details = '',
    this.nationalId = '',
    this.isNationalIdFromDb = false,
    this.isEligible = false,
    this.validationErrors = const {},
    this.isFormValid = false,
    this.isSubmitting = false,
    this.isSubmissionSuccessful = false,
    this.submissionError,
  });

  HrLetterFormState copyWith({
    String? letterPurpose,
    DateTime? travelFromDate,
    DateTime? travelToDate,
    String? details,
    String? nationalId,
    bool? isNationalIdFromDb,
    bool? isEligible,
    Map<String, String>? validationErrors,
    bool? isFormValid,
    bool? isSubmitting,
    bool? isSubmissionSuccessful,
    String? submissionError,
    bool clearLetterPurpose = false,
    bool clearTravelFromDate = false,
    bool clearTravelToDate = false,
    bool clearSubmissionError = false,
  }) {
    return HrLetterFormState(
      letterPurpose: clearLetterPurpose ? null : (letterPurpose ?? this.letterPurpose),
      travelFromDate: clearTravelFromDate ? null : (travelFromDate ?? this.travelFromDate),
      travelToDate: clearTravelToDate ? null : (travelToDate ?? this.travelToDate),
      details: details ?? this.details,
      nationalId: nationalId ?? this.nationalId,
      isNationalIdFromDb: isNationalIdFromDb ?? this.isNationalIdFromDb,
      isEligible: isEligible ?? this.isEligible,
      validationErrors: validationErrors ?? this.validationErrors,
      isFormValid: isFormValid ?? this.isFormValid,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmissionSuccessful: isSubmissionSuccessful ?? this.isSubmissionSuccessful,
      submissionError: clearSubmissionError ? null : (submissionError ?? this.submissionError),
    );
  }

  @override
  List<Object?> get props => [
    letterPurpose,
    travelFromDate,
    travelToDate,
    details,
    nationalId,
    isNationalIdFromDb,
    isEligible,
    validationErrors,
    isFormValid,
    isSubmitting,
    isSubmissionSuccessful,
    submissionError,
  ];
}

class HrLetterError extends HrLetterState {
  final String message;

  const HrLetterError(this.message);

  @override
  List<Object?> get props => [message];
}
