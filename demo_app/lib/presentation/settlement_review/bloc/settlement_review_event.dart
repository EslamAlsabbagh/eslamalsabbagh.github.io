part of 'settlement_review_bloc.dart';

abstract class SettlementReviewEvent {}

class LoadSettlementReviewRequests extends SettlementReviewEvent {}

/// Moves the window. [page] is 0-based.
class SettlementReviewPageChanged extends SettlementReviewEvent {
  final int page;

  SettlementReviewPageChanged(this.page);
}

class SendSettlementNotification extends SettlementReviewEvent {
  final int requestId;
  final int financeUserCode;

  SendSettlementNotification(this.requestId, this.financeUserCode);
}

class SendAllSettlementNotifications extends SettlementReviewEvent {
  final int financeUserCode;

  SendAllSettlementNotifications(this.financeUserCode);
}

class SkipSettlementNotification extends SettlementReviewEvent {
  final int requestId;
  final int financeUserCode;

  SkipSettlementNotification(this.requestId, this.financeUserCode);
}
