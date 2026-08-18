import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/leave_request_model.dart';
import 'package:hrms_demo/data/models/overtime_request_model.dart';
import 'package:hrms_demo/data/models/businesstrip_request_model.dart';
import 'package:hrms_demo/data/models/missingpunching_request_model.dart';
import 'package:hrms_demo/data/models/advance_on_salary_request_model.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'package:hrms_demo/data/models/investigation_request_model.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_request_repo.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunching_request_repo.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_action_request_repo.dart';
import 'package:hrms_demo/data/repos/investigation_request/investigation_request_repo.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_request_repo.dart';
import 'package:hrms_demo/data/models/hr_letter_request_model.dart';
import 'package:hrms_demo/data/repos/schedule/schedule_repo.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/my_requests_summary_event.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/my_requests_summary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MyRequestsSummaryBloc extends Bloc<MyRequestsSummaryEvent, MyRequestsSummaryState> {
  final LeaveRequestsRepo leaveRequestsRepo;
  final OvertimeRequestRepo overtimeRequestsRepo;
  final BusinesstripRequestsRepo businessTripRequestsRepo;
  final MissingpunchingRequestsRepo missingPunchRequestsRepo;
  final AdvanceOnSalaryRequestsRepo advanceOnSalaryRequestsRepo;
  final DisciplinaryActionRequestRepo disciplinaryActionRequestsRepo;
  final InvestigationRequestRepo investigationRequestsRepo;
  final HrLetterRequestRepo hrLetterRequestsRepo;
  final ScheduleRepo scheduleRepo;

  MyRequestsSummaryBloc({
    required this.leaveRequestsRepo,
    required this.overtimeRequestsRepo,
    required this.businessTripRequestsRepo,
    required this.missingPunchRequestsRepo,
    required this.advanceOnSalaryRequestsRepo,
    required this.disciplinaryActionRequestsRepo,
    required this.investigationRequestsRepo,
    required this.hrLetterRequestsRepo,
    required this.scheduleRepo,
  }) : super(const MyRequestsSummaryState()) {
    on<LoadMyRequestsSummary>(_onLoadMyRequestsSummary);
  }

  Future<void> _onLoadMyRequestsSummary(LoadMyRequestsSummary event, Emitter<MyRequestsSummaryState> emit) async {
    emit(state.copyWith(status: Status.loading));

    try {
      final results = await Future.wait([
        leaveRequestsRepo.getMyLeaveRequests(event.userCode),
        overtimeRequestsRepo.getMyOvertimeRequests(event.userCode),
        businessTripRequestsRepo.getMybusinesstripRequests(event.userCode),
        missingPunchRequestsRepo.getMyMissingpunchingRequests(event.userCode),
        advanceOnSalaryRequestsRepo.getMyAdvanceOnSalaryRequests(event.userCode),
        disciplinaryActionRequestsRepo.getMyDisciplinaryActionRequests(event.userCode),
        investigationRequestsRepo.getMyInvestigationRequests(event.userCode),
        hrLetterRequestsRepo.getMyHrLetterRequests(event.userCode),
      ]);

      final leaveRequests = results[0] as List<LeaveRequestModel>;
      final overtimeRequests = results[1] as List<OvertimeRequestModel>;
      final businessTripRequests = results[2] as List<BusinesstripRequestModel>;
      final missingPunchRequests = results[3] as List<MissingpunchingRequestModel>;
      final advanceOnSalaryRequests = results[4] as List<AdvanceOnSalaryRequestModel>;
      final disciplinaryActionRequests = results[5] as List<DisciplinaryActionRequestModel>;
      final investigationRequests = results[6] as List<InvestigationRequestModel>;
      final hrLetterRequests = results[7] as List<HrLetterRequestModel>;

      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      // Count in-process requests (pending and not cancelled)
      final inProcessLeave = leaveRequests.where((r) => _isInProcess(r.status, r.cancelled)).length;
      final inProcessOvertime = overtimeRequests.where((r) => _isInProcess(r.status, r.isCancelled)).length;
      final inProcessBusinessTrip = businessTripRequests.where((r) => _isInProcess(r.status, r.isCancelled)).length;
      final inProcessMissingPunch = missingPunchRequests.where((r) => _isInProcess(r.status, r.isCancelled)).length;
      final inProcessAdvance = advanceOnSalaryRequests.where((r) => _isInProcess(r.status, r.isCancelled)).length;
      final inProcessDisciplinaryOnly =
          disciplinaryActionRequests.where((r) => _isInProcess(r.status, r.isCancelled)).length;
      // Investigations use status 'pending' — combine with disciplinary action count
      final inProcessInvestigation =
          investigationRequests.where((r) => r.status?.toLowerCase() == 'pending' && !r.isCancelled).length;
      final inProcessDisciplinary = inProcessDisciplinaryOnly + inProcessInvestigation;

      // Count recently processed requests (approved/declined within last 7 days)
      final recentlyProcessedLeave =
          leaveRequests
              .where(
                (r) => _isRecentlyProcessed(
                  r.status,
                  r.cancelled,
                  _getProcessedDate(r.hrApprovalDate, r.n2ApprovalDate, r.n1ApprovalDate),
                  sevenDaysAgo,
                ),
              )
              .length;

      final recentlyProcessedOvertime =
          overtimeRequests
              .where(
                (r) => _isRecentlyProcessed(
                  r.status,
                  r.isCancelled,
                  _getProcessedDate(r.hrApprovalDate, r.n2ApprovalDate, r.n1ApprovalDate),
                  sevenDaysAgo,
                ),
              )
              .length;

      final recentlyProcessedBusinessTrip =
          businessTripRequests
              .where(
                (r) => _isRecentlyProcessed(
                  r.status,
                  r.isCancelled,
                  _getProcessedDate(r.hrApprovalDate, r.n2ApprovalDate, r.n1ApprovalDate),
                  sevenDaysAgo,
                ),
              )
              .length;

      final recentlyProcessedMissingPunch =
          missingPunchRequests
              .where(
                (r) => _isRecentlyProcessed(
                  r.status,
                  r.isCancelled,
                  _getProcessedDate(r.hrApprovalDate, r.n2ApprovalDate, r.n1ApprovalDate),
                  sevenDaysAgo,
                ),
              )
              .length;

      final recentlyProcessedAdvance =
          advanceOnSalaryRequests
              .where(
                (r) => _isRecentlyProcessed(
                  r.status,
                  r.isCancelled,
                  _getProcessedDate(r.hrApprovalDate, r.n2ApprovalDate, null),
                  sevenDaysAgo,
                ),
              )
              .length;

      final recentlyProcessedDisciplinaryOnly =
          disciplinaryActionRequests
              .where(
                (r) => _isRecentlyProcessed(
                  r.status,
                  r.isCancelled,
                  _getProcessedDate(r.hrApprovalDate, r.n2ApprovalDate, null),
                  sevenDaysAgo,
                ),
              )
              .length;
      // Investigations use status 'closed' and lastActionAt as the processed date
      final recentlyProcessedInvestigation =
          investigationRequests.where((r) {
            if (r.isCancelled) return false;
            if (r.status?.toLowerCase() != 'closed') return false;
            if (r.lastActionAt == null) return false;
            return r.lastActionAt!.isAfter(sevenDaysAgo);
          }).length;
      final recentlyProcessedDisciplinary = recentlyProcessedDisciplinaryOnly + recentlyProcessedInvestigation;

      final inProcessHrLetter =
          hrLetterRequests.where((r) => (r.isPending || r.isAcknowledged) && !r.isCancelled).length;
      final recentlyProcessedHrLetter =
          hrLetterRequests.where((r) {
            if (r.isCancelled) return false;
            if (!r.isCompleted && !r.isDeclined) return false;
            if (r.lastActionAt == null) return false;
            return r.lastActionAt!.isAfter(sevenDaysAgo);
          }).length;

      int inProcessSwap = 0;
      try {
        inProcessSwap = await scheduleRepo.countMyInProcessSwapRequests(event.userCode);
      } catch (_) {}
      try {
        inProcessSwap += await scheduleRepo.countAcceptedSwapRequestsAsTarget(event.userCode);
      } catch (_) {}

      int processedSwap = 0;
      try {
        processedSwap = await scheduleRepo.countMyRecentlyProcessedSwapRequests(event.userCode);
      } catch (_) {}

      final summary = MyRequestsSummary(
        inProcessLeaveRequests: inProcessLeave,
        inProcessOvertimeRequests: inProcessOvertime,
        inProcessBusinessTripRequests: inProcessBusinessTrip,
        inProcessMissingPunchRequests: inProcessMissingPunch,
        inProcessAdvanceOnSalaryRequests: inProcessAdvance,
        inProcessDisciplinaryActionRequests: inProcessDisciplinary,
        inProcessHrLetterRequests: inProcessHrLetter,
        inProcessSwapRequests: inProcessSwap,
        recentlyProcessedLeaveRequests: recentlyProcessedLeave,
        recentlyProcessedOvertimeRequests: recentlyProcessedOvertime,
        recentlyProcessedBusinessTripRequests: recentlyProcessedBusinessTrip,
        recentlyProcessedMissingPunchRequests: recentlyProcessedMissingPunch,
        recentlyProcessedAdvanceOnSalaryRequests: recentlyProcessedAdvance,
        recentlyProcessedDisciplinaryActionRequests: recentlyProcessedDisciplinary,
        recentlyProcessedHrLetterRequests: recentlyProcessedHrLetter,
        recentlyProcessedSwapRequests: processedSwap,
      );

      emit(state.copyWith(status: Status.success, summary: summary));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  bool _isInProcess(String? status, bool? cancelled) {
    return (status?.toLowerCase() == 'pending' || status?.toLowerCase() == 'on_hold') && cancelled != true;
  }

  bool _isRecentlyProcessed(String? status, bool? cancelled, DateTime? processedDate, DateTime sevenDaysAgo) {
    if (cancelled == true) return false;
    final statusLower = status?.toLowerCase();
    if (statusLower != 'approved' && statusLower != 'declined') return false;
    if (processedDate == null) return false;
    return processedDate.isAfter(sevenDaysAgo);
  }

  DateTime? _getProcessedDate(DateTime? hrApprovalDate, DateTime? n2ApprovalDate, DateTime? n1ApprovalDate) {
    // Priority: hrApprovalDate > n2ApprovalDate > n1ApprovalDate
    // For approved requests, hrApprovalDate is typically set
    // For declined requests, the date is set at the level where declined
    if (hrApprovalDate != null) return hrApprovalDate;
    if (n2ApprovalDate != null) return n2ApprovalDate;
    if (n1ApprovalDate != null) return n1ApprovalDate;
    return null;
  }
}
