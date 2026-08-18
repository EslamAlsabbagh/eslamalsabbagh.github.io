// user_event.dart

sealed class UserEvent {}

final class LoadUserProfile extends UserEvent {
  final String code;

  LoadUserProfile(this.code);
}

final class RefreshUserProfileForLocale extends UserEvent {
  final String code;
  final String locale;

  RefreshUserProfileForLocale(this.code, this.locale);
}

final class ResetUserState extends UserEvent {
  ResetUserState();
}

/// Persists the current employee's self-provided contact info (phone/address)
/// via a targeted partial update, then patches the in-memory user without the
/// heavy full profile refetch.
final class UpdateUserContactInfo extends UserEvent {
  final int code;
  final String? phoneNumber;
  final String? address;

  UpdateUserContactInfo({required this.code, this.phoneNumber, this.address});
}

final class MarkRequestsAvailable extends UserEvent {
  final bool? hasLeaveRequests;
  final bool? hasOvertimeRequests;
  final bool? hasMissingPunchRequests;
  final bool? hasBusinessTripRequests;
  final bool? hasAdvanceRequests;
  final bool? hasDisciplinaryRequests;
  final bool? hasHrLetterRequests;

  MarkRequestsAvailable({
    this.hasLeaveRequests,
    this.hasOvertimeRequests,
    this.hasMissingPunchRequests,
    this.hasBusinessTripRequests,
    this.hasAdvanceRequests,
    this.hasDisciplinaryRequests,
    this.hasHrLetterRequests,
  });
}
