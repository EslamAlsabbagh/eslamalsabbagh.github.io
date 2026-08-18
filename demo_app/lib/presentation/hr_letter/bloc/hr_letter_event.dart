import 'package:equatable/equatable.dart';

abstract class HrLetterEvent extends Equatable {
  const HrLetterEvent();

  @override
  List<Object?> get props => [];
}

class InitializeHrLetterForm extends HrLetterEvent {}

class UpdateLetterPurpose extends HrLetterEvent {
  final String purpose;

  const UpdateLetterPurpose(this.purpose);

  @override
  List<Object?> get props => [purpose];
}

class UpdateTravelFromDate extends HrLetterEvent {
  final DateTime date;

  const UpdateTravelFromDate(this.date);

  @override
  List<Object?> get props => [date];
}

class UpdateTravelToDate extends HrLetterEvent {
  final DateTime date;

  const UpdateTravelToDate(this.date);

  @override
  List<Object?> get props => [date];
}

class UpdateDetails extends HrLetterEvent {
  final String details;

  const UpdateDetails(this.details);

  @override
  List<Object?> get props => [details];
}

class UpdateNationalId extends HrLetterEvent {
  final String nationalId;

  const UpdateNationalId(this.nationalId);

  @override
  List<Object?> get props => [nationalId];
}

class ValidateHrLetterForm extends HrLetterEvent {}

class ResetHrLetterForm extends HrLetterEvent {}

class SubmitHrLetterRequest extends HrLetterEvent {}
