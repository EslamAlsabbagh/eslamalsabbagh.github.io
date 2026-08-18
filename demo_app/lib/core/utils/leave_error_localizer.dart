import 'package:hrms_demo/l10n/app_localizations.dart';

/// Maps a raw leave-submission error string (as produced by the server RPCs in
/// `supabase/migrations/leave_rpcs.sql` or the client-side guards in
/// [RequestLeaveBloc]) to a friendly, localized message.
///
/// The error set is closed and known, so we match on case-insensitive
/// substrings — this stays robust to the `PostgrestException(...)` wrapper and
/// to the interpolated dynamic "annual cap exceeded for user X — ..." variant.
/// Anything unrecognized falls back to a generic localized message rather than
/// leaking raw technical text to the user.
String localizeLeaveError(AppLocalizations l10n, String? raw) {
  final msg = (raw ?? '').toLowerCase();

  if (msg.contains('user not found')) {
    return l10n.errUserNotFound;
  }
  if (msg.contains('within the current year')) {
    return l10n.errLeaveOutsideYear;
  }
  if (msg.contains('use compensation leave first')) {
    return l10n.useCompensationFirst;
  }
  if (msg.contains('annual leave cap exceeded')) {
    return l10n.errAnnualCapExceeded;
  }
  if (msg.contains('insufficient projected balance')) {
    return l10n.errInsufficientProjectedBalance;
  }
  if (msg.contains('insufficient emergency leave balance')) {
    return l10n.emergencyNotEnoughBalance;
  }
  if (msg.contains('dates are required')) {
    return l10n.errDatesRequired;
  }

  return l10n.errLeaveRequestFailed;
}
