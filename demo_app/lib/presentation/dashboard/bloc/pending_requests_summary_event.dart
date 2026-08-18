abstract class PendingRequestsSummaryEvent {}

class LoadPendingRequestsSummary extends PendingRequestsSummaryEvent {
  final int userCode;
  final List<String>? userGroups;

  LoadPendingRequestsSummary(this.userCode, {this.userGroups});
}
