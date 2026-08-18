// user_bloc.dart
import 'package:hrms_demo/core/constants/status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_action_request_repo.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_request_repo.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_request_repo.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunching_request_repo.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UsersRepo repo;
  final AdvanceOnSalaryRequestsRepo advanceRepo;
  final DisciplinaryActionRequestRepo disciplinaryRepo;
  final HrLetterRequestRepo hrLetterRepo;
  final LeaveRequestsRepo leaveRepo;
  final OvertimeRequestRepo overtimeRepo;
  final MissingpunchingRequestsRepo missingPunchRepo;
  final BusinesstripRequestsRepo businessTripRepo;

  UserBloc(
    this.repo,
    this.advanceRepo,
    this.disciplinaryRepo,
    this.hrLetterRepo,
    this.leaveRepo,
    this.overtimeRepo,
    this.missingPunchRepo,
    this.businessTripRepo,
  ) : super(const UserState()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<RefreshUserProfileForLocale>(_onRefreshUserProfileForLocale);
    on<ResetUserState>(_onResetUserState);
    on<MarkRequestsAvailable>(_onMarkRequestsAvailable);
    on<UpdateUserContactInfo>(_onUpdateUserContactInfo);
  }

  Future<void> _onUpdateUserContactInfo(UpdateUserContactInfo event, Emitter<UserState> emit) async {
    emit(state.copyWith(contactUpdateStatus: Status.loading));

    try {
      await repo.updateEmployeeContactInfo(event.code, phoneNumber: event.phoneNumber, address: event.address);

      // Patch the in-memory user directly rather than re-running
      // LoadUserProfile's 24 parallel availability queries — the two fields we
      // wrote are the only thing that changed.
      emit(
        state.copyWith(
          user: state.user?.copyWith(phoneNumber: event.phoneNumber, address: event.address),
          contactUpdateStatus: Status.success,
        ),
      );
    } catch (e) {
      emit(state.copyWith(contactUpdateStatus: Status.failure, error: e.toString()));
    }
  }

  Future<void> _onLoadUserProfile(LoadUserProfile event, Emitter<UserState> emit) async {
    emit(state.copyWith(status: Status.loading));

    try {
      final user = await repo.fetchUserProfile(event.code);
      if (user != null) {
        // Load all request availability data in parallel
        final results = await Future.wait([
          repo.getManagedEmployeesCount(user.id!),
          advanceRepo.hasRequestsMadeForUser(user.id!),
          disciplinaryRepo.hasRequestsMadeForUser(user.id!),
          leaveRepo.hasMyRequests(user.id!),
          leaveRepo.hasTeamRequests(user.id!),
          leaveRepo.hasProcessedRequests(user.id!),
          overtimeRepo.hasMyRequests(user.id!),
          overtimeRepo.hasTeamRequests(user.id!),
          overtimeRepo.hasProcessedRequests(user.id!),
          missingPunchRepo.hasMyRequests(user.id!),
          missingPunchRepo.hasTeamRequests(user.id!),
          missingPunchRepo.hasProcessedRequests(user.id!),
          businessTripRepo.hasMyRequests(user.id!),
          businessTripRepo.hasTeamRequests(user.id!),
          businessTripRepo.hasProcessedRequests(user.id!),
          advanceRepo.hasMyRequests(user.id!),
          advanceRepo.hasTeamRequests(user.id!),
          advanceRepo.hasProcessedRequests(user.id!),
          disciplinaryRepo.hasMyRequests(user.id!),
          disciplinaryRepo.hasTeamRequests(user.id!),
          disciplinaryRepo.hasProcessedRequests(user.id!),
          hrLetterRepo.hasMyRequests(user.id!),
          hrLetterRepo.hasTeamRequests(),
          hrLetterRepo.hasProcessedRequests(),
        ]);

        final requestAvailability = RequestAvailability(
          hasLeaveRequests: results[3] as bool,
          hasTeamLeaveRequests: results[4] as bool,
          hasProcessedLeaveRequests: results[5] as bool,
          hasOvertimeRequests: results[6] as bool,
          hasTeamOvertimeRequests: results[7] as bool,
          hasProcessedOvertimeRequests: results[8] as bool,
          hasMissingPunchRequests: results[9] as bool,
          hasTeamMissingPunchRequests: results[10] as bool,
          hasProcessedMissingPunchRequests: results[11] as bool,
          hasBusinessTripRequests: results[12] as bool,
          hasTeamBusinessTripRequests: results[13] as bool,
          hasProcessedBusinessTripRequests: results[14] as bool,
          hasAdvanceRequests: results[15] as bool,
          hasTeamAdvanceRequests: results[16] as bool,
          hasProcessedAdvanceRequests: results[17] as bool,
          hasDisciplinaryRequests: results[18] as bool,
          hasTeamDisciplinaryRequests: results[19] as bool,
          hasProcessedDisciplinaryRequests: results[20] as bool,
          hasHrLetterRequests: results[21] as bool,
          hasTeamHrLetterRequests: results[22] as bool,
          hasProcessedHrLetterRequests: results[23] as bool,
        );

        emit(
          state.copyWith(
            status: Status.success,
            user: user,
            managedEmployeesCount: results[0] as int,
            hasAdvanceRequestsMadeForUser: results[1] as bool,
            hasDisciplinaryRequestsMadeForUser: results[2] as bool,
            requestAvailability: requestAvailability,
          ),
        );
      } else {
        emit(state.copyWith(status: Status.failure, error: 'User not found.'));
      }
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  Future<void> _onRefreshUserProfileForLocale(RefreshUserProfileForLocale event, Emitter<UserState> emit) async {
    emit(state.copyWith(status: Status.loading));

    try {
      final user = await repo.fetchUserProfile(event.code, locale: event.locale);
      if (user != null) {
        // Load all request availability data in parallel
        final results = await Future.wait([
          repo.getManagedEmployeesCount(user.id!),
          advanceRepo.hasRequestsMadeForUser(user.id!),
          disciplinaryRepo.hasRequestsMadeForUser(user.id!),
          leaveRepo.hasMyRequests(user.id!),
          leaveRepo.hasTeamRequests(user.id!),
          leaveRepo.hasProcessedRequests(user.id!),
          overtimeRepo.hasMyRequests(user.id!),
          overtimeRepo.hasTeamRequests(user.id!),
          overtimeRepo.hasProcessedRequests(user.id!),
          missingPunchRepo.hasMyRequests(user.id!),
          missingPunchRepo.hasTeamRequests(user.id!),
          missingPunchRepo.hasProcessedRequests(user.id!),
          businessTripRepo.hasMyRequests(user.id!),
          businessTripRepo.hasTeamRequests(user.id!),
          businessTripRepo.hasProcessedRequests(user.id!),
          advanceRepo.hasMyRequests(user.id!),
          advanceRepo.hasTeamRequests(user.id!),
          advanceRepo.hasProcessedRequests(user.id!),
          disciplinaryRepo.hasMyRequests(user.id!),
          disciplinaryRepo.hasTeamRequests(user.id!),
          disciplinaryRepo.hasProcessedRequests(user.id!),
          hrLetterRepo.hasMyRequests(user.id!),
          hrLetterRepo.hasTeamRequests(),
          hrLetterRepo.hasProcessedRequests(),
        ]);

        final requestAvailability = RequestAvailability(
          hasLeaveRequests: results[3] as bool,
          hasTeamLeaveRequests: results[4] as bool,
          hasProcessedLeaveRequests: results[5] as bool,
          hasOvertimeRequests: results[6] as bool,
          hasTeamOvertimeRequests: results[7] as bool,
          hasProcessedOvertimeRequests: results[8] as bool,
          hasMissingPunchRequests: results[9] as bool,
          hasTeamMissingPunchRequests: results[10] as bool,
          hasProcessedMissingPunchRequests: results[11] as bool,
          hasBusinessTripRequests: results[12] as bool,
          hasTeamBusinessTripRequests: results[13] as bool,
          hasProcessedBusinessTripRequests: results[14] as bool,
          hasAdvanceRequests: results[15] as bool,
          hasTeamAdvanceRequests: results[16] as bool,
          hasProcessedAdvanceRequests: results[17] as bool,
          hasDisciplinaryRequests: results[18] as bool,
          hasTeamDisciplinaryRequests: results[19] as bool,
          hasProcessedDisciplinaryRequests: results[20] as bool,
          hasHrLetterRequests: results[21] as bool,
          hasTeamHrLetterRequests: results[22] as bool,
          hasProcessedHrLetterRequests: results[23] as bool,
        );

        emit(
          state.copyWith(
            status: Status.success,
            user: user,
            managedEmployeesCount: results[0] as int,
            hasAdvanceRequestsMadeForUser: results[1] as bool,
            hasDisciplinaryRequestsMadeForUser: results[2] as bool,
            requestAvailability: requestAvailability,
          ),
        );
      } else {
        emit(state.copyWith(status: Status.failure, error: 'User not found.'));
      }
    } catch (e) {
      emit(state.copyWith(status: Status.failure, error: e.toString()));
    }
  }

  void _onResetUserState(ResetUserState event, Emitter<UserState> emit) {
    emit(const UserState());
  }

  void _onMarkRequestsAvailable(MarkRequestsAvailable event, Emitter<UserState> emit) {
    final current = state.requestAvailability ?? const RequestAvailability();
    emit(
      state.copyWith(
        requestAvailability: current.copyWith(
          hasLeaveRequests: event.hasLeaveRequests,
          hasOvertimeRequests: event.hasOvertimeRequests,
          hasMissingPunchRequests: event.hasMissingPunchRequests,
          hasBusinessTripRequests: event.hasBusinessTripRequests,
          hasAdvanceRequests: event.hasAdvanceRequests,
          hasDisciplinaryRequests: event.hasDisciplinaryRequests,
          hasHrLetterRequests: event.hasHrLetterRequests,
        ),
      ),
    );
  }
}
