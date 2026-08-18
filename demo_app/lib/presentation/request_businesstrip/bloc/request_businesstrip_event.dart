import 'package:hrms_demo/data/models/businesstrip_request_model.dart';

abstract class RequestBusinesstripEvent {}

class SubmitBusinesstripRequest extends RequestBusinesstripEvent {
  final BusinesstripRequestModel request;
  SubmitBusinesstripRequest(this.request);
}

final class ValidateForm extends RequestBusinesstripEvent {
  final String dateFrom;
  final String dateTo;
  final String location;
  final int numberOfDays;
  ValidateForm({required this.dateFrom, required this.dateTo, required this.location, required this.numberOfDays});
}

class SetOtherLocation extends RequestBusinesstripEvent {
  final bool other;
  SetOtherLocation(this.other);
}

class SetLocationTransportationFee extends RequestBusinesstripEvent {
  final bool deservesFee;
  SetLocationTransportationFee(this.deservesFee);
}

class SetRequestTransportationFee extends RequestBusinesstripEvent {
  final bool requested;
  SetRequestTransportationFee(this.requested);
}

class SetTransportationFeeAmount extends RequestBusinesstripEvent {
  final double? amount;
  SetTransportationFeeAmount(this.amount);
}

class LoadExistingBusinesstripRequests extends RequestBusinesstripEvent {
  final int userCode;

  LoadExistingBusinesstripRequests(this.userCode);
}

class SetNumberOfHours extends RequestBusinesstripEvent {
  final int? numberOfHours;
  SetNumberOfHours(this.numberOfHours);
}

class SetAmPm extends RequestBusinesstripEvent {
  final String? amPm;
  SetAmPm(this.amPm);
}
