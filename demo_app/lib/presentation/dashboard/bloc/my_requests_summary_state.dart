import 'package:hrms_demo/core/bases/base_state.dart';
import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';

class MyRequestsSummary {
  // In-Process counts (status == 'pending' && cancelled != true)
  final int inProcessLeaveRequests;
  final int inProcessOvertimeRequests;
  final int inProcessBusinessTripRequests;
  final int inProcessMissingPunchRequests;
  final int inProcessAdvanceOnSalaryRequests;
  final int inProcessDisciplinaryActionRequests; // includes investigations
  final int inProcessHrLetterRequests;
  final int inProcessSwapRequests;

  // Recently Processed counts (status in ['approved', 'declined'/'closed'], within 7 days)
  final int recentlyProcessedLeaveRequests;
  final int recentlyProcessedOvertimeRequests;
  final int recentlyProcessedBusinessTripRequests;
  final int recentlyProcessedMissingPunchRequests;
  final int recentlyProcessedAdvanceOnSalaryRequests;
  final int recentlyProcessedDisciplinaryActionRequests; // includes investigations
  final int recentlyProcessedHrLetterRequests;
  final int recentlyProcessedSwapRequests;

  const MyRequestsSummary({
    this.inProcessLeaveRequests = 0,
    this.inProcessOvertimeRequests = 0,
    this.inProcessBusinessTripRequests = 0,
    this.inProcessMissingPunchRequests = 0,
    this.inProcessAdvanceOnSalaryRequests = 0,
    this.inProcessDisciplinaryActionRequests = 0,
    this.inProcessHrLetterRequests = 0,
    this.inProcessSwapRequests = 0,
    this.recentlyProcessedLeaveRequests = 0,
    this.recentlyProcessedOvertimeRequests = 0,
    this.recentlyProcessedBusinessTripRequests = 0,
    this.recentlyProcessedMissingPunchRequests = 0,
    this.recentlyProcessedAdvanceOnSalaryRequests = 0,
    this.recentlyProcessedDisciplinaryActionRequests = 0,
    this.recentlyProcessedHrLetterRequests = 0,
    this.recentlyProcessedSwapRequests = 0,
  });

  int get totalInProcess =>
      inProcessLeaveRequests +
      inProcessOvertimeRequests +
      inProcessBusinessTripRequests +
      inProcessMissingPunchRequests +
      inProcessAdvanceOnSalaryRequests +
      inProcessDisciplinaryActionRequests +
      inProcessHrLetterRequests +
      inProcessSwapRequests;

  int get totalRecentlyProcessed =>
      recentlyProcessedLeaveRequests +
      recentlyProcessedOvertimeRequests +
      recentlyProcessedBusinessTripRequests +
      recentlyProcessedMissingPunchRequests +
      recentlyProcessedAdvanceOnSalaryRequests +
      recentlyProcessedDisciplinaryActionRequests +
      recentlyProcessedHrLetterRequests +
      recentlyProcessedSwapRequests;

  bool get hasInProcessRequests => totalInProcess > 0;
  bool get hasRecentlyProcessedRequests => totalRecentlyProcessed > 0;

  int get activeInProcessTypesCount {
    int count = 0;
    if (inProcessLeaveRequests > 0) count++;
    // if (inProcessOvertimeRequests > 0) count++;
    if (inProcessBusinessTripRequests > 0) count++;
    if (inProcessMissingPunchRequests > 0) count++;
    if (inProcessAdvanceOnSalaryRequests > 0) count++;
    if (inProcessDisciplinaryActionRequests > 0) count++;
    if (inProcessHrLetterRequests > 0) count++;
    if (inProcessSwapRequests > 0) count++;
    return count;
  }

  int get activeRecentlyProcessedTypesCount {
    int count = 0;
    if (recentlyProcessedLeaveRequests > 0) count++;
    if (recentlyProcessedOvertimeRequests > 0) count++;
    if (recentlyProcessedBusinessTripRequests > 0) count++;
    if (recentlyProcessedMissingPunchRequests > 0) count++;
    if (recentlyProcessedAdvanceOnSalaryRequests > 0) count++;
    if (recentlyProcessedDisciplinaryActionRequests > 0) count++;
    if (recentlyProcessedHrLetterRequests > 0) count++;
    if (recentlyProcessedSwapRequests > 0) count++;
    return count;
  }

  MyRequestsSummary copyWith({
    int? inProcessLeaveRequests,
    int? inProcessOvertimeRequests,
    int? inProcessBusinessTripRequests,
    int? inProcessMissingPunchRequests,
    int? inProcessAdvanceOnSalaryRequests,
    int? inProcessDisciplinaryActionRequests,
    int? inProcessHrLetterRequests,
    int? inProcessSwapRequests,
    int? recentlyProcessedLeaveRequests,
    int? recentlyProcessedOvertimeRequests,
    int? recentlyProcessedBusinessTripRequests,
    int? recentlyProcessedMissingPunchRequests,
    int? recentlyProcessedAdvanceOnSalaryRequests,
    int? recentlyProcessedDisciplinaryActionRequests,
    int? recentlyProcessedHrLetterRequests,
    int? recentlyProcessedSwapRequests,
  }) {
    return MyRequestsSummary(
      inProcessLeaveRequests: inProcessLeaveRequests ?? this.inProcessLeaveRequests,
      inProcessOvertimeRequests: inProcessOvertimeRequests ?? this.inProcessOvertimeRequests,
      inProcessBusinessTripRequests: inProcessBusinessTripRequests ?? this.inProcessBusinessTripRequests,
      inProcessMissingPunchRequests: inProcessMissingPunchRequests ?? this.inProcessMissingPunchRequests,
      inProcessAdvanceOnSalaryRequests: inProcessAdvanceOnSalaryRequests ?? this.inProcessAdvanceOnSalaryRequests,
      inProcessDisciplinaryActionRequests:
          inProcessDisciplinaryActionRequests ?? this.inProcessDisciplinaryActionRequests,
      inProcessHrLetterRequests: inProcessHrLetterRequests ?? this.inProcessHrLetterRequests,
      inProcessSwapRequests: inProcessSwapRequests ?? this.inProcessSwapRequests,
      recentlyProcessedLeaveRequests: recentlyProcessedLeaveRequests ?? this.recentlyProcessedLeaveRequests,
      recentlyProcessedOvertimeRequests: recentlyProcessedOvertimeRequests ?? this.recentlyProcessedOvertimeRequests,
      recentlyProcessedBusinessTripRequests:
          recentlyProcessedBusinessTripRequests ?? this.recentlyProcessedBusinessTripRequests,
      recentlyProcessedMissingPunchRequests:
          recentlyProcessedMissingPunchRequests ?? this.recentlyProcessedMissingPunchRequests,
      recentlyProcessedAdvanceOnSalaryRequests:
          recentlyProcessedAdvanceOnSalaryRequests ?? this.recentlyProcessedAdvanceOnSalaryRequests,
      recentlyProcessedDisciplinaryActionRequests:
          recentlyProcessedDisciplinaryActionRequests ?? this.recentlyProcessedDisciplinaryActionRequests,
      recentlyProcessedHrLetterRequests: recentlyProcessedHrLetterRequests ?? this.recentlyProcessedHrLetterRequests,
      recentlyProcessedSwapRequests: recentlyProcessedSwapRequests ?? this.recentlyProcessedSwapRequests,
    );
  }
}

final class MyRequestsSummaryState extends BaseState {
  const MyRequestsSummaryState({
    super.status = Status.initial,
    super.failure,
    this.summary = const MyRequestsSummary(),
  });

  final MyRequestsSummary summary;

  MyRequestsSummaryState copyWith({Status? status, Failure? failure, MyRequestsSummary? summary}) {
    return MyRequestsSummaryState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => super.props..addAll([summary]);
}
