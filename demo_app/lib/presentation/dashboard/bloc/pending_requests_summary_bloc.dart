import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/leave_request_model.dart';
import 'package:hrms_demo/data/models/leave_cancellation_request_model.dart';
import 'package:hrms_demo/data/models/overtime_request_model.dart';
import 'package:hrms_demo/data/models/businesstrip_request_model.dart';
import 'package:hrms_demo/data/models/businesstrip_cancellation_request_model.dart';
import 'package:hrms_demo/data/models/missingpunching_request_model.dart';
import 'package:hrms_demo/data/models/advance_on_salary_request_model.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'package:hrms_demo/data/models/investigation_request_model.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/repos/leave_cancellation_request/leave_cancellation_request_repo.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_request_repo.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo.dart';
import 'package:hrms_demo/data/repos/businesstrip_cancellation_request/businesstrip_cancellation_request_repo.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunching_request_repo.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_action_request_repo.dart';
import 'package:hrms_demo/data/repos/investigation_request/investigation_request_repo.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_request_repo.dart';
import 'package:hrms_demo/data/models/hr_letter_request_model.dart';
import 'package:hrms_demo/data/repos/schedule/schedule_repo.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/pending_requests_summary_event.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/pending_requests_summary_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PendingRequestsSummaryBloc extends Bloc<PendingRequestsSummaryEvent, PendingRequestsSummaryState> {
  final LeaveRequestsRepo leaveRequestsRepo;
  final LeaveCancellationRequestsRepo leaveCancellationRequestsRepo;
  final OvertimeRequestRepo overtimeRequestsRepo;
  final BusinesstripRequestsRepo businessTripRequestsRepo;
  final BusinesstripCancellationRequestsRepo businesstripCancellationRequestsRepo;
  final MissingpunchingRequestsRepo missingPunchRequestsRepo;
  final AdvanceOnSalaryRequestsRepo advanceOnSalaryRequestsRepo;
  final DisciplinaryActionRequestRepo disciplinaryActionRequestsRepo;
  final InvestigationRequestRepo investigationRequestsRepo;
  final HrLetterRequestRepo hrLetterRequestsRepo;
  final ScheduleRepo scheduleRepo;

  PendingRequestsSummaryBloc({
    required this.leaveRequestsRepo,
    required this.leaveCancellationRequestsRepo,
    required this.overtimeRequestsRepo,
    required this.businessTripRequestsRepo,
    required this.businesstripCancellationRequestsRepo,
    required this.missingPunchRequestsRepo,
    required this.advanceOnSalaryRequestsRepo,
    required this.disciplinaryActionRequestsRepo,
    required this.investigationRequestsRepo,
    required this.hrLetterRequestsRepo,
    required this.scheduleRepo,
  }) : super(const PendingRequestsSummaryState()) {
    on<LoadPendingRequestsSummary>(_onLoadPendingRequestsSummary);
  }

  Future<void> _onLoadPendingRequestsSummary(
    LoadPendingRequestsSummary event,
    Emitter<PendingRequestsSummaryState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));

    try {
      final isFinanceUser = event.userGroups?.contains('finance') ?? false;
      final isHRUser = event.userGroups?.contains('hr') ?? false;

      final results = await Future.wait([
        leaveRequestsRepo.getRequestsToApprove(event.userCode),
        leaveCancellationRequestsRepo.getCancellationRequestsToApprove(event.userCode),
        overtimeRequestsRepo.getTeamRequests(event.userCode),
        businessTripRequestsRepo.getRequestsToApprove(event.userCode),
        businesstripCancellationRequestsRepo.getCancellationRequestsToApprove(event.userCode),
        missingPunchRequestsRepo.getRequestsToApprove(event.userCode),
        advanceOnSalaryRequestsRepo.getRequestsToApprove(event.userCode),
        disciplinaryActionRequestsRepo.getRequestsToApprove(event.userCode),
        advanceOnSalaryRequestsRepo.getRequestsNeedingEmployeeConfirmation(event.userCode),
        advanceOnSalaryRequestsRepo.getRequestsNeedingFinanceAcknowledgment(event.userCode),
        disciplinaryActionRequestsRepo.getRequestsNeedingEmployeeAcknowledgment(event.userCode),
        _getAllPendingInvestigations(event.userCode), // Load investigations
        if (isHRUser)
          hrLetterRequestsRepo.getAllHrLetterRequests().then(
            (requests) => requests.where((r) => r.employeeCode != event.userCode).toList(),
          ),
        if (isFinanceUser) advanceOnSalaryRequestsRepo.getSettlementReviewCount(),
      ]);

      final leaveRequests = results[0] as List<LeaveRequestModel>;
      final leaveCancellationRequests = results[1] as List<LeaveCancellationRequestModel>;
      final overtimeRequests = results[2] as List<OvertimeRequestModel>;
      final businessTripRequests = results[3] as List<BusinesstripRequestModel>;
      final businesstripCancellationRequests = results[4] as List<BusinesstripCancellationRequestModel>;
      final missingPunchRequests = results[5] as List<MissingpunchingRequestModel>;
      final advanceOnSalaryRequests = results[6] as List<AdvanceOnSalaryRequestModel>;
      final disciplinaryActionRequests = results[7] as List<DisciplinaryActionRequestModel>;
      final employeeConfirmationRequests = results[8] as List<AdvanceOnSalaryRequestModel>;
      final financeAcknowledgmentRequests = results[9] as List<AdvanceOnSalaryRequestModel>;
      final employeeDisciplinaryAcknowledgmentRequests = results[10] as List<DisciplinaryActionRequestModel>;
      final investigationRequests = results[11] as List<InvestigationRequestModel>;
      final hrLetterAllRequests = isHRUser ? results[12] as List<HrLetterRequestModel> : <HrLetterRequestModel>[];
      final settlementReviewCount = isFinanceUser ? results[isHRUser ? 13 : 12] as int : 0;

      final pendingHrLetterRequests = hrLetterAllRequests.where((r) => r.isPending || r.isAcknowledged).length;

      final pendingLeaveRequests =
          leaveRequests.where((request) => request.status?.toLowerCase() == 'pending' && !request.isCancelled).length;
      final pendingOvertimeRequests =
          overtimeRequests
              .where((request) => request.status?.toLowerCase() == 'pending' && !request.isCancelled)
              .length;
      final pendingBusinessTripRequests =
          businessTripRequests
              .where((request) => request.status?.toLowerCase() == 'pending' && !request.isCancelled)
              .length;
      final pendingMissingPunchRequests =
          missingPunchRequests
              .where((request) => request.status?.toLowerCase() == 'pending' && !request.isCancelled)
              .length;
      final pendingAdvanceOnSalaryRequests =
          advanceOnSalaryRequests
              .where((request) => request.status?.toLowerCase() == 'pending' && !request.isCancelled)
              .length +
          financeAcknowledgmentRequests.length;
      final employeeConfirmationCount = employeeConfirmationRequests.length;
      // Filter pending disciplinary actions
      final pendingDisciplinaryActions =
          disciplinaryActionRequests
              .where((request) => request.status?.toLowerCase() == 'pending' && !request.isCancelled)
              .length;

      // Filter pending investigations
      final pendingInvestigations = investigationRequests.where((inv) => inv.status?.toLowerCase() == 'pending').length;

      // COMBINE both counts (disciplinary actions + investigations)
      final pendingDisciplinaryActionRequests = pendingDisciplinaryActions + pendingInvestigations;

      final pendingLeaveCancellationRequests =
          leaveCancellationRequests.where((request) => request.status?.toLowerCase() == 'pending').length;

      final pendingBusinesstripCancellationRequests =
          businesstripCancellationRequests.where((request) => request.status?.toLowerCase() == 'pending').length;
      final pendingDisciplinaryAcknowledgmentRequests =
          employeeDisciplinaryAcknowledgmentRequests
              .where((request) => request.status?.toLowerCase() == 'pending' && !request.isCancelled)
              .length;

      int pendingSwapRequests = 0;
      int incomingSwapRequests = 0;
      try {
        pendingSwapRequests = await scheduleRepo.countPendingSwapRequests(event.userCode);
      } catch (_) {}
      try {
        incomingSwapRequests = await scheduleRepo.countIncomingSwapRequests(event.userCode);
      } catch (_) {}

      final summary = PendingRequestsSummary(
        leaveRequests: pendingLeaveRequests,
        leaveCancellationRequests: pendingLeaveCancellationRequests,
        overtimeRequests: pendingOvertimeRequests,
        businessTripRequests: pendingBusinessTripRequests,
        businesstripCancellationRequests: pendingBusinesstripCancellationRequests,
        missingPunchRequests: pendingMissingPunchRequests,
        advanceOnSalaryRequests: pendingAdvanceOnSalaryRequests,
        disciplinaryActionRequests: pendingDisciplinaryActionRequests,
        employeeConfirmationRequests: employeeConfirmationCount,
        employeeDisciplinaryAcknowledgmentRequests: pendingDisciplinaryAcknowledgmentRequests,
        settlementReviewRequests: settlementReviewCount,
        hrLetterRequests: pendingHrLetterRequests,
        swapRequests: pendingSwapRequests,
        incomingSwapRequests: incomingSwapRequests,
      );

      emit(state.copyWith(status: Status.success, summary: summary));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  /// Helper method to load pending investigations across all roles (HR, Legal, Top Management)
  /// Users can be in multiple groups, so we try each role and combine results
  Future<List<InvestigationRequestModel>> _getAllPendingInvestigations(int userCode) async {
    final List<InvestigationRequestModel> allInvestigations = [];

    // Try HR role
    try {
      final hrInvestigations = await investigationRequestsRepo.getInvestigationsToApprove(userCode, 'hr');
      allInvestigations.addAll(hrInvestigations);
    } catch (e) {
      // User not in HR group, skip
    }

    // Try Legal role
    try {
      final legalInvestigations = await investigationRequestsRepo.getInvestigationsToApprove(userCode, 'legal');
      allInvestigations.addAll(legalInvestigations);
    } catch (e) {
      // User not in Legal group, skip
    }

    // Try Top Management role
    try {
      final topMgmtInvestigations = await investigationRequestsRepo.getInvestigationsToApprove(
        userCode,
        'top_management',
      );
      allInvestigations.addAll(topMgmtInvestigations);
    } catch (e) {
      // User not in Top Management group, skip
    }

    // Remove duplicates by ID (in case user is in multiple groups)
    final uniqueInvestigations = <int, InvestigationRequestModel>{};
    for (final inv in allInvestigations) {
      if (inv.id != null) {
        uniqueInvestigations[inv.id!] = inv;
      }
    }

    return uniqueInvestigations.values.toList();
  }
}
