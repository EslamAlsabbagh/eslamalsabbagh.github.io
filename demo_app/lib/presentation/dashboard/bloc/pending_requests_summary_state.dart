import 'package:hrms_demo/core/bases/base_state.dart';
import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';

class PendingRequestsSummary {
  final int leaveRequests;
  final int leaveCancellationRequests;
  final int overtimeRequests;
  final int businessTripRequests;
  final int businesstripCancellationRequests;
  final int missingPunchRequests;
  final int advanceOnSalaryRequests;
  final int disciplinaryActionRequests;
  final int employeeConfirmationRequests;
  final int employeeDisciplinaryAcknowledgmentRequests;
  final int settlementReviewRequests;
  final int hrLetterRequests;
  final int swapRequests;
  final int incomingSwapRequests;

  const PendingRequestsSummary({
    this.leaveRequests = 0,
    this.leaveCancellationRequests = 0,
    this.overtimeRequests = 0,
    this.businessTripRequests = 0,
    this.businesstripCancellationRequests = 0,
    this.missingPunchRequests = 0,
    this.advanceOnSalaryRequests = 0,
    this.disciplinaryActionRequests = 0,
    this.employeeConfirmationRequests = 0,
    this.employeeDisciplinaryAcknowledgmentRequests = 0,
    this.settlementReviewRequests = 0,
    this.hrLetterRequests = 0,
    this.swapRequests = 0,
    this.incomingSwapRequests = 0,
  });

  int get totalRequests =>
      leaveRequests +
      leaveCancellationRequests +
      overtimeRequests +
      businessTripRequests +
      businesstripCancellationRequests +
      missingPunchRequests +
      advanceOnSalaryRequests +
      disciplinaryActionRequests +
      employeeConfirmationRequests +
      employeeDisciplinaryAcknowledgmentRequests +
      settlementReviewRequests +
      hrLetterRequests +
      swapRequests +
      incomingSwapRequests;

  bool get hasAnyRequests => totalRequests > 0;

  int get activeRequestTypesCount {
    int count = 0;
    if (leaveRequests > 0) count++;
    if (leaveCancellationRequests > 0) count++;
    if (overtimeRequests > 0) count++;
    if (businessTripRequests > 0) count++;
    if (businesstripCancellationRequests > 0) count++;
    if (missingPunchRequests > 0) count++;
    if (advanceOnSalaryRequests > 0) count++;
    if (disciplinaryActionRequests > 0) count++;
    if (employeeConfirmationRequests > 0) count++;
    if (employeeDisciplinaryAcknowledgmentRequests > 0) count++;
    if (settlementReviewRequests > 0) count++;
    if (hrLetterRequests > 0) count++;
    if (swapRequests > 0) count++;
    if (incomingSwapRequests > 0) count++;
    return count;
  }

  PendingRequestsSummary copyWith({
    int? leaveRequests,
    int? leaveCancellationRequests,
    int? overtimeRequests,
    int? businessTripRequests,
    int? businesstripCancellationRequests,
    int? missingPunchRequests,
    int? advanceOnSalaryRequests,
    int? disciplinaryActionRequests,
    int? employeeConfirmationRequests,
    int? employeeDisciplinaryAcknowledgmentRequests,
    int? settlementReviewRequests,
    int? hrLetterRequests,
    int? swapRequests,
    int? incomingSwapRequests,
  }) {
    return PendingRequestsSummary(
      leaveRequests: leaveRequests ?? this.leaveRequests,
      leaveCancellationRequests: leaveCancellationRequests ?? this.leaveCancellationRequests,
      overtimeRequests: overtimeRequests ?? this.overtimeRequests,
      businessTripRequests: businessTripRequests ?? this.businessTripRequests,
      businesstripCancellationRequests: businesstripCancellationRequests ?? this.businesstripCancellationRequests,
      missingPunchRequests: missingPunchRequests ?? this.missingPunchRequests,
      advanceOnSalaryRequests: advanceOnSalaryRequests ?? this.advanceOnSalaryRequests,
      disciplinaryActionRequests: disciplinaryActionRequests ?? this.disciplinaryActionRequests,
      employeeConfirmationRequests: employeeConfirmationRequests ?? this.employeeConfirmationRequests,
      employeeDisciplinaryAcknowledgmentRequests:
          employeeDisciplinaryAcknowledgmentRequests ?? this.employeeDisciplinaryAcknowledgmentRequests,
      settlementReviewRequests: settlementReviewRequests ?? this.settlementReviewRequests,
      hrLetterRequests: hrLetterRequests ?? this.hrLetterRequests,
      swapRequests: swapRequests ?? this.swapRequests,
      incomingSwapRequests: incomingSwapRequests ?? this.incomingSwapRequests,
    );
  }
}

final class PendingRequestsSummaryState extends BaseState {
  const PendingRequestsSummaryState({
    super.status = Status.initial,
    super.failure,
    this.summary = const PendingRequestsSummary(),
  });

  final PendingRequestsSummary summary;

  PendingRequestsSummaryState copyWith({Status? status, Failure? failure, PendingRequestsSummary? summary}) {
    return PendingRequestsSummaryState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => super.props..addAll([summary]);
}
