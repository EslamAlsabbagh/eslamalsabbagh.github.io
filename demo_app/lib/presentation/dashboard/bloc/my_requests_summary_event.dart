abstract class MyRequestsSummaryEvent {}

class LoadMyRequestsSummary extends MyRequestsSummaryEvent {
  final int userCode;

  LoadMyRequestsSummary(this.userCode);
}
