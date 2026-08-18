part of 'settlement_review_bloc.dart';

// Note: BaseState and Status are imported in the main bloc file

final class SettlementReviewState extends BaseState {
  /// LEGACY whole-list rows. Populated only when
  /// `FeatureFlags.serverPagedAdvanceRequests` is false; empty on the paged
  /// path, where [paged] holds the current page instead.
  final List<AdvanceOnSalaryRequestModel> requests;

  /// The current page window and the rows in it. This screen has no filters, so
  /// there is no query field to go with it — the scope is always
  /// `AdvanceRequestScope.settlementReview`.
  final PagedSection<AdvanceOnSalaryRequestModel> paged;

  final Status sendStatus;
  final Status sendAllStatus;
  final Status skipStatus;
  final int? processingRequestId;

  const SettlementReviewState({
    super.status = Status.initial,
    super.failure,
    this.requests = const [],
    this.paged = const PagedSection<AdvanceOnSalaryRequestModel>(),
    this.sendStatus = Status.initial,
    this.sendAllStatus = Status.initial,
    this.skipStatus = Status.initial,
    this.processingRequestId,
  });

  SettlementReviewState copyWith({
    Status? status,
    Failure? failure,
    List<AdvanceOnSalaryRequestModel>? requests,
    PagedSection<AdvanceOnSalaryRequestModel>? paged,
    Status? sendStatus,
    Status? sendAllStatus,
    Status? skipStatus,
    int? processingRequestId,
    bool clearProcessingRequestId = false,
  }) {
    return SettlementReviewState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      requests: requests ?? this.requests,
      paged: paged ?? this.paged,
      sendStatus: sendStatus ?? this.sendStatus,
      sendAllStatus: sendAllStatus ?? this.sendAllStatus,
      skipStatus: skipStatus ?? this.skipStatus,
      processingRequestId: clearProcessingRequestId ? null : (processingRequestId ?? this.processingRequestId),
    );
  }

  @override
  List<Object?> get props =>
      super.props..addAll([requests, paged, sendStatus, sendAllStatus, skipStatus, processingRequestId]);
}
