import 'package:hrms_demo/data/models/missingpunching_request_model.dart';

abstract class RequestMissingpunchingEvent {}

class SubmitMissingPunchingRequest extends RequestMissingpunchingEvent {
  final MissingpunchingRequestModel request;
  SubmitMissingPunchingRequest(this.request);
}

final class ValidateForm extends RequestMissingpunchingEvent {
  final String date;
  final String time;
  ValidateForm({required this.date, required this.time});
}

final class ChangeMissingPunchType extends RequestMissingpunchingEvent {
  final String missingPunchType;
  ChangeMissingPunchType(this.missingPunchType);
}

class LoadExistingMissingpunchingRequests extends RequestMissingpunchingEvent {
  final int userCode;
  LoadExistingMissingpunchingRequests(this.userCode);
}
