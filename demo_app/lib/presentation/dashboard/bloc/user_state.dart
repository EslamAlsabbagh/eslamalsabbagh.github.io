// user_state.dart
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/core/constants/status.dart';

class RequestAvailability {
  final bool hasLeaveRequests;
  final bool hasTeamLeaveRequests;
  final bool hasProcessedLeaveRequests;
  final bool hasOvertimeRequests;
  final bool hasTeamOvertimeRequests;
  final bool hasProcessedOvertimeRequests;
  final bool hasMissingPunchRequests;
  final bool hasTeamMissingPunchRequests;
  final bool hasProcessedMissingPunchRequests;
  final bool hasBusinessTripRequests;
  final bool hasTeamBusinessTripRequests;
  final bool hasProcessedBusinessTripRequests;
  final bool hasAdvanceRequests;
  final bool hasTeamAdvanceRequests;
  final bool hasProcessedAdvanceRequests;
  final bool hasDisciplinaryRequests;
  final bool hasTeamDisciplinaryRequests;
  final bool hasProcessedDisciplinaryRequests;
  final bool hasHrLetterRequests;
  final bool hasTeamHrLetterRequests;
  final bool hasProcessedHrLetterRequests;

  const RequestAvailability({
    this.hasLeaveRequests = false,
    this.hasTeamLeaveRequests = false,
    this.hasProcessedLeaveRequests = false,
    this.hasOvertimeRequests = false,
    this.hasTeamOvertimeRequests = false,
    this.hasProcessedOvertimeRequests = false,
    this.hasMissingPunchRequests = false,
    this.hasTeamMissingPunchRequests = false,
    this.hasProcessedMissingPunchRequests = false,
    this.hasBusinessTripRequests = false,
    this.hasTeamBusinessTripRequests = false,
    this.hasProcessedBusinessTripRequests = false,
    this.hasAdvanceRequests = false,
    this.hasTeamAdvanceRequests = false,
    this.hasProcessedAdvanceRequests = false,
    this.hasDisciplinaryRequests = false,
    this.hasTeamDisciplinaryRequests = false,
    this.hasProcessedDisciplinaryRequests = false,
    this.hasHrLetterRequests = false,
    this.hasTeamHrLetterRequests = false,
    this.hasProcessedHrLetterRequests = false,
  });

  RequestAvailability copyWith({
    bool? hasLeaveRequests,
    bool? hasTeamLeaveRequests,
    bool? hasProcessedLeaveRequests,
    bool? hasOvertimeRequests,
    bool? hasTeamOvertimeRequests,
    bool? hasProcessedOvertimeRequests,
    bool? hasMissingPunchRequests,
    bool? hasTeamMissingPunchRequests,
    bool? hasProcessedMissingPunchRequests,
    bool? hasBusinessTripRequests,
    bool? hasTeamBusinessTripRequests,
    bool? hasProcessedBusinessTripRequests,
    bool? hasAdvanceRequests,
    bool? hasTeamAdvanceRequests,
    bool? hasProcessedAdvanceRequests,
    bool? hasDisciplinaryRequests,
    bool? hasTeamDisciplinaryRequests,
    bool? hasProcessedDisciplinaryRequests,
    bool? hasHrLetterRequests,
    bool? hasTeamHrLetterRequests,
    bool? hasProcessedHrLetterRequests,
  }) {
    return RequestAvailability(
      hasLeaveRequests: hasLeaveRequests ?? this.hasLeaveRequests,
      hasTeamLeaveRequests: hasTeamLeaveRequests ?? this.hasTeamLeaveRequests,
      hasProcessedLeaveRequests: hasProcessedLeaveRequests ?? this.hasProcessedLeaveRequests,
      hasOvertimeRequests: hasOvertimeRequests ?? this.hasOvertimeRequests,
      hasTeamOvertimeRequests: hasTeamOvertimeRequests ?? this.hasTeamOvertimeRequests,
      hasProcessedOvertimeRequests: hasProcessedOvertimeRequests ?? this.hasProcessedOvertimeRequests,
      hasMissingPunchRequests: hasMissingPunchRequests ?? this.hasMissingPunchRequests,
      hasTeamMissingPunchRequests: hasTeamMissingPunchRequests ?? this.hasTeamMissingPunchRequests,
      hasProcessedMissingPunchRequests: hasProcessedMissingPunchRequests ?? this.hasProcessedMissingPunchRequests,
      hasBusinessTripRequests: hasBusinessTripRequests ?? this.hasBusinessTripRequests,
      hasTeamBusinessTripRequests: hasTeamBusinessTripRequests ?? this.hasTeamBusinessTripRequests,
      hasProcessedBusinessTripRequests: hasProcessedBusinessTripRequests ?? this.hasProcessedBusinessTripRequests,
      hasAdvanceRequests: hasAdvanceRequests ?? this.hasAdvanceRequests,
      hasTeamAdvanceRequests: hasTeamAdvanceRequests ?? this.hasTeamAdvanceRequests,
      hasProcessedAdvanceRequests: hasProcessedAdvanceRequests ?? this.hasProcessedAdvanceRequests,
      hasDisciplinaryRequests: hasDisciplinaryRequests ?? this.hasDisciplinaryRequests,
      hasTeamDisciplinaryRequests: hasTeamDisciplinaryRequests ?? this.hasTeamDisciplinaryRequests,
      hasProcessedDisciplinaryRequests: hasProcessedDisciplinaryRequests ?? this.hasProcessedDisciplinaryRequests,
      hasHrLetterRequests: hasHrLetterRequests ?? this.hasHrLetterRequests,
      hasTeamHrLetterRequests: hasTeamHrLetterRequests ?? this.hasTeamHrLetterRequests,
      hasProcessedHrLetterRequests: hasProcessedHrLetterRequests ?? this.hasProcessedHrLetterRequests,
    );
  }
}

class UserState {
  final Status status;
  final UserModel? user;
  final String? error;
  final int? managedEmployeesCount;
  final bool? hasAdvanceRequestsMadeForUser;
  final bool? hasDisciplinaryRequestsMadeForUser;
  final RequestAvailability? requestAvailability;

  /// Lifecycle of a self-service contact-info (phone/address) save. Kept
  /// separate from [status] so the profile page's inline editor can react to it
  /// without the whole page flipping to a spinner/error like [status] drives.
  final Status contactUpdateStatus;

  const UserState({
    this.status = Status.initial,
    this.user,
    this.error,
    this.managedEmployeesCount,
    this.hasAdvanceRequestsMadeForUser,
    this.hasDisciplinaryRequestsMadeForUser,
    this.requestAvailability,
    this.contactUpdateStatus = Status.initial,
  });

  UserState copyWith({
    Status? status,
    UserModel? user,
    String? error,
    int? managedEmployeesCount,
    bool? hasAdvanceRequestsMadeForUser,
    bool? hasDisciplinaryRequestsMadeForUser,
    RequestAvailability? requestAvailability,
    Status? contactUpdateStatus,
  }) {
    return UserState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      managedEmployeesCount: managedEmployeesCount ?? this.managedEmployeesCount,
      hasAdvanceRequestsMadeForUser: hasAdvanceRequestsMadeForUser ?? this.hasAdvanceRequestsMadeForUser,
      hasDisciplinaryRequestsMadeForUser: hasDisciplinaryRequestsMadeForUser ?? this.hasDisciplinaryRequestsMadeForUser,
      requestAvailability: requestAvailability ?? this.requestAvailability,
      contactUpdateStatus: contactUpdateStatus ?? this.contactUpdateStatus,
    );
  }
}
