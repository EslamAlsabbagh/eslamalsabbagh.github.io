import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @action.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @approver.
  ///
  /// In en, this message translates to:
  /// **'Approver'**
  String get approver;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @editManagerTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Manager'**
  String get editManagerTitle;

  /// No description provided for @currentManager.
  ///
  /// In en, this message translates to:
  /// **'Current Manager'**
  String get currentManager;

  /// No description provided for @newManager.
  ///
  /// In en, this message translates to:
  /// **'New Manager (N+1)'**
  String get newManager;

  /// No description provided for @pleaseSelectManager.
  ///
  /// In en, this message translates to:
  /// **'Please select a manager'**
  String get pleaseSelectManager;

  /// No description provided for @circularReportingLine.
  ///
  /// In en, this message translates to:
  /// **'That would create a circular reporting line'**
  String get circularReportingLine;

  /// No description provided for @failedToUpdateManager.
  ///
  /// In en, this message translates to:
  /// **'Failed to update manager'**
  String get failedToUpdateManager;

  /// No description provided for @noPermissionToChangeManager.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to change managers'**
  String get noPermissionToChangeManager;

  /// No description provided for @managerUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Manager updated successfully'**
  String get managerUpdatedSuccessfully;

  /// No description provided for @employeeDetailsUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Employee details updated successfully'**
  String get employeeDetailsUpdatedSuccessfully;

  /// No description provided for @failedToUpdateEmployeeDetails.
  ///
  /// In en, this message translates to:
  /// **'Failed to update employee details'**
  String get failedToUpdateEmployeeDetails;

  /// No description provided for @noPermissionToEditEmployeeDetails.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to edit employee details'**
  String get noPermissionToEditEmployeeDetails;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @dateFrom.
  ///
  /// In en, this message translates to:
  /// **'Date From'**
  String get dateFrom;

  /// No description provided for @dateTo.
  ///
  /// In en, this message translates to:
  /// **'Date To'**
  String get dateTo;

  /// No description provided for @day.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get day;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get days;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @putOnHold.
  ///
  /// In en, this message translates to:
  /// **'Put on Hold'**
  String get putOnHold;

  /// No description provided for @declineReason.
  ///
  /// In en, this message translates to:
  /// **'Decline Reason'**
  String get declineReason;

  /// No description provided for @department.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get department;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @hoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hoursLabel;

  /// No description provided for @hourLabel.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hourLabel;

  /// No description provided for @numberOfHours.
  ///
  /// In en, this message translates to:
  /// **'Num of Hours'**
  String get numberOfHours;

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// No description provided for @morning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get morning;

  /// No description provided for @evening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get evening;

  /// No description provided for @id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @leaveBalance.
  ///
  /// In en, this message translates to:
  /// **'Leave Balance'**
  String get leaveBalance;

  /// No description provided for @availableNow.
  ///
  /// In en, this message translates to:
  /// **'Available Till Date'**
  String get availableNow;

  /// No description provided for @annualAllowanceRemaining.
  ///
  /// In en, this message translates to:
  /// **'Annual allowance remaining'**
  String get annualAllowanceRemaining;

  /// No description provided for @carryForward.
  ///
  /// In en, this message translates to:
  /// **'Carry-forward'**
  String get carryForward;

  /// No description provided for @expiresApr1.
  ///
  /// In en, this message translates to:
  /// **'expires Mar 31'**
  String get expiresApr1;

  /// No description provided for @catchingUp.
  ///
  /// In en, this message translates to:
  /// **'catching up'**
  String get catchingUp;

  /// No description provided for @maxPerMonth.
  ///
  /// In en, this message translates to:
  /// **'max {days}/month'**
  String maxPerMonth(Object days);

  /// No description provided for @negativeBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Your balance is currently negative — the system will check whether it covers your selected dates once you submit a new request'**
  String get negativeBalanceHint;

  /// No description provided for @useCompensationFirst.
  ///
  /// In en, this message translates to:
  /// **'Use compensation leave first'**
  String get useCompensationFirst;

  /// No description provided for @annualCapReached.
  ///
  /// In en, this message translates to:
  /// **'Annual cap reached'**
  String get annualCapReached;

  /// No description provided for @leaveType.
  ///
  /// In en, this message translates to:
  /// **'Leave Type'**
  String get leaveType;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @enterLocation.
  ///
  /// In en, this message translates to:
  /// **'Enter location'**
  String get enterLocation;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @lRSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Leave request submitted successfully'**
  String get lRSubmittedSuccessfully;

  /// No description provided for @errUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find your employee record.'**
  String get errUserNotFound;

  /// No description provided for @errLeaveOutsideYear.
  ///
  /// In en, this message translates to:
  /// **'Leave dates must fall within the current year.'**
  String get errLeaveOutsideYear;

  /// No description provided for @errAnnualCapExceeded.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your annual leave allowance for this year.'**
  String get errAnnualCapExceeded;

  /// No description provided for @errInsufficientProjectedBalance.
  ///
  /// In en, this message translates to:
  /// **'Your balance won\'t cover these dates, even with upcoming monthly credits.'**
  String get errInsufficientProjectedBalance;

  /// No description provided for @errDatesRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select both a start and end date.'**
  String get errDatesRequired;

  /// No description provided for @errLeaveRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t submit your leave request. Please try again.'**
  String get errLeaveRequestFailed;

  /// No description provided for @oRSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Overtime request submitted successfully'**
  String get oRSubmittedSuccessfully;

  /// No description provided for @myRequests.
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @noLeaveRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No leave requests found'**
  String get noLeaveRequestsFound;

  /// No description provided for @noOvertimeRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No overtime requests found'**
  String get noOvertimeRequestsFound;

  /// No description provided for @noSickAvail.
  ///
  /// In en, this message translates to:
  /// **'No sick note available'**
  String get noSickAvail;

  /// No description provided for @numberOfDays.
  ///
  /// In en, this message translates to:
  /// **'Number of days'**
  String get numberOfDays;

  /// No description provided for @oldPassword.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// No description provided for @overtime.
  ///
  /// In en, this message translates to:
  /// **'Overtime'**
  String get overtime;

  /// No description provided for @overTimeBalance.
  ///
  /// In en, this message translates to:
  /// **'Overtime Balance'**
  String get overTimeBalance;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords Do Not Match'**
  String get passwordsDoNotMatch;

  /// No description provided for @passwordUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password Updated Successfully'**
  String get passwordUpdatedSuccessfully;

  /// No description provided for @plsNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please Enter New Password'**
  String get plsNewPassword;

  /// No description provided for @plsOldPassword.
  ///
  /// In en, this message translates to:
  /// **'Please Enter Old Password'**
  String get plsOldPassword;

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// No description provided for @resetPasswordConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordConfirmTitle;

  /// No description provided for @resetPasswordConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset this employee\'s password to \"123456\"?'**
  String get resetPasswordConfirmMessage;

  /// No description provided for @resetPasswordSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully to \"123456\"'**
  String get resetPasswordSuccess;

  /// No description provided for @resetPasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset password'**
  String get resetPasswordFailed;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @quickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick Access'**
  String get quickAccess;

  /// No description provided for @showMore.
  ///
  /// In en, this message translates to:
  /// **'Show More'**
  String get showMore;

  /// No description provided for @showLess.
  ///
  /// In en, this message translates to:
  /// **'Show Less'**
  String get showLess;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @requestID.
  ///
  /// In en, this message translates to:
  /// **'Request ID'**
  String get requestID;

  /// No description provided for @requestLeave.
  ///
  /// In en, this message translates to:
  /// **'Request Leave'**
  String get requestLeave;

  /// No description provided for @requestOvertime.
  ///
  /// In en, this message translates to:
  /// **'Request Overtime'**
  String get requestOvertime;

  /// No description provided for @sickNote.
  ///
  /// In en, this message translates to:
  /// **'Medical Report'**
  String get sickNote;

  /// No description provided for @sickNotes.
  ///
  /// In en, this message translates to:
  /// **'Medical Reports'**
  String get sickNotes;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @teamRequests.
  ///
  /// In en, this message translates to:
  /// **'Team Requests'**
  String get teamRequests;

  /// No description provided for @forgotPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Forgot password? Contact HR to reset password'**
  String get forgotPasswordHint;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @timeFrom.
  ///
  /// In en, this message translates to:
  /// **'Time From'**
  String get timeFrom;

  /// No description provided for @timeTo.
  ///
  /// In en, this message translates to:
  /// **'Time To'**
  String get timeTo;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @upSicknote.
  ///
  /// In en, this message translates to:
  /// **'Upload Medical Report'**
  String get upSicknote;

  /// No description provided for @youWillOff.
  ///
  /// In en, this message translates to:
  /// **'You Will Be Off For: '**
  String get youWillOff;

  /// No description provided for @newRequest.
  ///
  /// In en, this message translates to:
  /// **'New Request'**
  String get newRequest;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @declined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declined;

  /// No description provided for @onHold.
  ///
  /// In en, this message translates to:
  /// **'On Hold'**
  String get onHold;

  /// No description provided for @underInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Under Investigation'**
  String get underInvestigation;

  /// No description provided for @viewRequests.
  ///
  /// In en, this message translates to:
  /// **'View Requests'**
  String get viewRequests;

  /// No description provided for @actionable.
  ///
  /// In en, this message translates to:
  /// **'Actionable'**
  String get actionable;

  /// No description provided for @processed.
  ///
  /// In en, this message translates to:
  /// **'Processed'**
  String get processed;

  /// No description provided for @processedDisciplinary.
  ///
  /// In en, this message translates to:
  /// **'Processed Disciplinary'**
  String get processedDisciplinary;

  /// No description provided for @processedInvestigations.
  ///
  /// In en, this message translates to:
  /// **'Processed Investigations'**
  String get processedInvestigations;

  /// No description provided for @annual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annual;

  /// No description provided for @sick.
  ///
  /// In en, this message translates to:
  /// **'Sick'**
  String get sick;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @compensation.
  ///
  /// In en, this message translates to:
  /// **'Compensation'**
  String get compensation;

  /// No description provided for @compensationNotEnoughBalance.
  ///
  /// In en, this message translates to:
  /// **'Compensation (not enough balance)'**
  String get compensationNotEnoughBalance;

  /// No description provided for @annualNotEnoughBalance.
  ///
  /// In en, this message translates to:
  /// **'Annual (not enough balance)'**
  String get annualNotEnoughBalance;

  /// No description provided for @annualHasOvertime.
  ///
  /// In en, this message translates to:
  /// **'Annual (you have overtime balance)'**
  String get annualHasOvertime;

  /// No description provided for @numOfHours.
  ///
  /// In en, this message translates to:
  /// **'Number of Hours'**
  String get numOfHours;

  /// No description provided for @emergencyMaxOneDay.
  ///
  /// In en, this message translates to:
  /// **'Emergency leave cannot exceed 1 day.'**
  String get emergencyMaxOneDay;

  /// No description provided for @emergencyNotEnoughBalance.
  ///
  /// In en, this message translates to:
  /// **'You do not have enough emergency leave balance.'**
  String get emergencyNotEnoughBalance;

  /// No description provided for @emergencyRequiresAnnual.
  ///
  /// In en, this message translates to:
  /// **'You must have annual leave balance to request emergency leave.'**
  String get emergencyRequiresAnnual;

  /// No description provided for @requestMissingPunching.
  ///
  /// In en, this message translates to:
  /// **'Request Missing Punching'**
  String get requestMissingPunching;

  /// No description provided for @requestMissingPunchingSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Missing punching request submitted successfully'**
  String get requestMissingPunchingSubmittedSuccessfully;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @missingPunching.
  ///
  /// In en, this message translates to:
  /// **'Missing Punch'**
  String get missingPunching;

  /// No description provided for @noMissingPunchingRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No missing punching requests found'**
  String get noMissingPunchingRequestsFound;

  /// No description provided for @missingPunchingRequests.
  ///
  /// In en, this message translates to:
  /// **'Missing Punching Requests'**
  String get missingPunchingRequests;

  /// No description provided for @missingPunchingRequestDetails.
  ///
  /// In en, this message translates to:
  /// **'Missing Punching Request Details'**
  String get missingPunchingRequestDetails;

  /// No description provided for @requestBusinesstrip.
  ///
  /// In en, this message translates to:
  /// **'Request Business Trip'**
  String get requestBusinesstrip;

  /// No description provided for @businessTrip.
  ///
  /// In en, this message translates to:
  /// **'Business Trip'**
  String get businessTrip;

  /// No description provided for @noBusinessTripRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No business trip requests found'**
  String get noBusinessTripRequestsFound;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @businessTripSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Business trip request submitted successfully'**
  String get businessTripSubmittedSuccessfully;

  /// No description provided for @riverside.
  ///
  /// In en, this message translates to:
  /// **'RIVERSIDE'**
  String get riverside;

  /// No description provided for @riversidePark.
  ///
  /// In en, this message translates to:
  /// **'RIVERSIDE PARK'**
  String get riversidePark;

  /// No description provided for @northSquare.
  ///
  /// In en, this message translates to:
  /// **'NORTH SQUARE'**
  String get northSquare;

  /// No description provided for @transportationFeesEligible.
  ///
  /// In en, this message translates to:
  /// **'This location is eligible for transportation fees.'**
  String get transportationFeesEligible;

  /// No description provided for @requestTransportationFees.
  ///
  /// In en, this message translates to:
  /// **'Request transportation fees'**
  String get requestTransportationFees;

  /// No description provided for @transportationFeeAmount.
  ///
  /// In en, this message translates to:
  /// **'Transportation fee amount'**
  String get transportationFeeAmount;

  /// No description provided for @transportationFeeAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount.'**
  String get transportationFeeAmountRequired;

  /// No description provided for @editTransportationFeeAmount.
  ///
  /// In en, this message translates to:
  /// **'Edit transportation fee amount'**
  String get editTransportationFeeAmount;

  /// No description provided for @egp.
  ///
  /// In en, this message translates to:
  /// **'EGP'**
  String get egp;

  /// No description provided for @sameDayMissingPunchWarning.
  ///
  /// In en, this message translates to:
  /// **'A missing punch request exists on the same day.'**
  String get sameDayMissingPunchWarning;

  /// No description provided for @sameDayBusinessTripWarning.
  ///
  /// In en, this message translates to:
  /// **'A business trip request exists on the same day.'**
  String get sameDayBusinessTripWarning;

  /// No description provided for @holidays.
  ///
  /// In en, this message translates to:
  /// **'Holidays'**
  String get holidays;

  /// No description provided for @compensatedHours.
  ///
  /// In en, this message translates to:
  /// **'Compensated Hours'**
  String get compensatedHours;

  /// No description provided for @reasonDetails.
  ///
  /// In en, this message translates to:
  /// **'Reason Description'**
  String get reasonDetails;

  /// No description provided for @missingPunchBalance.
  ///
  /// In en, this message translates to:
  /// **'Missing Punch Balance'**
  String get missingPunchBalance;

  /// No description provided for @employeeBalances.
  ///
  /// In en, this message translates to:
  /// **'Employee Balances'**
  String get employeeBalances;

  /// No description provided for @annualLeave.
  ///
  /// In en, this message translates to:
  /// **'Annual Leave'**
  String get annualLeave;

  /// No description provided for @dayAbbr.
  ///
  /// In en, this message translates to:
  /// **'d'**
  String get dayAbbr;

  /// No description provided for @hourAbbr.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hourAbbr;

  /// No description provided for @filterByMonth.
  ///
  /// In en, this message translates to:
  /// **'Filter by Month'**
  String get filterByMonth;

  /// No description provided for @chooseMonth.
  ///
  /// In en, this message translates to:
  /// **'Choose Month'**
  String get chooseMonth;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// No description provided for @requestsReport.
  ///
  /// In en, this message translates to:
  /// **'Requests Report'**
  String get requestsReport;

  /// No description provided for @employeeRequestsReport.
  ///
  /// In en, this message translates to:
  /// **'Employee Requests Report'**
  String get employeeRequestsReport;

  /// No description provided for @overallSummary.
  ///
  /// In en, this message translates to:
  /// **'Overall Summary'**
  String get overallSummary;

  /// No description provided for @totalRequests.
  ///
  /// In en, this message translates to:
  /// **'Total Requests'**
  String get totalRequests;

  /// No description provided for @pendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get pendingRequests;

  /// No description provided for @myInProcessRequests.
  ///
  /// In en, this message translates to:
  /// **'In-Process Requests'**
  String get myInProcessRequests;

  /// No description provided for @myRecentlyProcessedRequests.
  ///
  /// In en, this message translates to:
  /// **'Recently Processed Requests'**
  String get myRecentlyProcessedRequests;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @leaveRequests.
  ///
  /// In en, this message translates to:
  /// **'Leave Requests'**
  String get leaveRequests;

  /// No description provided for @overtimeRequests.
  ///
  /// In en, this message translates to:
  /// **'Overtime Requests'**
  String get overtimeRequests;

  /// No description provided for @businessTripRequests.
  ///
  /// In en, this message translates to:
  /// **'Business Trip Requests'**
  String get businessTripRequests;

  /// No description provided for @missingPunchRequests.
  ///
  /// In en, this message translates to:
  /// **'Missing Punch Requests'**
  String get missingPunchRequests;

  /// No description provided for @noRequestsMessage.
  ///
  /// In en, this message translates to:
  /// **'This employee has not submitted any requests yet.'**
  String get noRequestsMessage;

  /// No description provided for @andMoreRequests.
  ///
  /// In en, this message translates to:
  /// **'{count} more requests'**
  String andMoreRequests(int count);

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @detailsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Details not available'**
  String get detailsNotAvailable;

  /// No description provided for @leaveRequest.
  ///
  /// In en, this message translates to:
  /// **'Leave Request'**
  String get leaveRequest;

  /// No description provided for @overtimeRequest.
  ///
  /// In en, this message translates to:
  /// **'Overtime Request'**
  String get overtimeRequest;

  /// No description provided for @businessTripRequest.
  ///
  /// In en, this message translates to:
  /// **'Business Trip Request'**
  String get businessTripRequest;

  /// No description provided for @missingPunchRequest.
  ///
  /// In en, this message translates to:
  /// **'Missing Punch Request'**
  String get missingPunchRequest;

  /// No description provided for @request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// No description provided for @searchByName.
  ///
  /// In en, this message translates to:
  /// **'Search by name or code'**
  String get searchByName;

  /// No description provided for @searchByNameOrCode.
  ///
  /// In en, this message translates to:
  /// **'Search by name or code...'**
  String get searchByNameOrCode;

  /// No description provided for @addEmployee.
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get addEmployee;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @employeesList.
  ///
  /// In en, this message translates to:
  /// **'Employees List'**
  String get employeesList;

  /// No description provided for @editEmployee.
  ///
  /// In en, this message translates to:
  /// **'Edit Employee'**
  String get editEmployee;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editPeriod.
  ///
  /// In en, this message translates to:
  /// **'Edit Payment Period'**
  String get editPeriod;

  /// No description provided for @updatedPeriod.
  ///
  /// In en, this message translates to:
  /// **'Updated Payment Period'**
  String get updatedPeriod;

  /// No description provided for @originalPeriod.
  ///
  /// In en, this message translates to:
  /// **'Original Payment Period'**
  String get originalPeriod;

  /// No description provided for @unscheduledPayment.
  ///
  /// In en, this message translates to:
  /// **'Unscheduled Payment'**
  String get unscheduledPayment;

  /// No description provided for @noEmployeesFoundMatching.
  ///
  /// In en, this message translates to:
  /// **'No No employees found matching'**
  String get noEmployeesFoundMatching;

  /// No description provided for @noEmployeesYet.
  ///
  /// In en, this message translates to:
  /// **'No employees yet'**
  String get noEmployeesYet;

  /// No description provided for @saveEmployee.
  ///
  /// In en, this message translates to:
  /// **'Save employee'**
  String get saveEmployee;

  /// No description provided for @employeeAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Employee added successfully'**
  String get employeeAddedSuccessfully;

  /// No description provided for @employeeUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Employee updated successfully'**
  String get employeeUpdatedSuccessfully;

  /// No description provided for @suspendEmployee.
  ///
  /// In en, this message translates to:
  /// **'Suspend Employee'**
  String get suspendEmployee;

  /// No description provided for @unsuspendEmployee.
  ///
  /// In en, this message translates to:
  /// **'Unsuspend Employee'**
  String get unsuspendEmployee;

  /// No description provided for @workingDays.
  ///
  /// In en, this message translates to:
  /// **'Working Days'**
  String get workingDays;

  /// No description provided for @leavesEligibility.
  ///
  /// In en, this message translates to:
  /// **'Leaves Eligibility'**
  String get leavesEligibility;

  /// No description provided for @shiftHours.
  ///
  /// In en, this message translates to:
  /// **'Shift Hours'**
  String get shiftHours;

  /// No description provided for @inType.
  ///
  /// In en, this message translates to:
  /// **'In'**
  String get inType;

  /// No description provided for @outType.
  ///
  /// In en, this message translates to:
  /// **'Out'**
  String get outType;

  /// No description provided for @filterRequests.
  ///
  /// In en, this message translates to:
  /// **'Filter Requests'**
  String get filterRequests;

  /// No description provided for @filterByRequestType.
  ///
  /// In en, this message translates to:
  /// **'Filter by Request Type'**
  String get filterByRequestType;

  /// No description provided for @allTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get allTypes;

  /// No description provided for @leaveRequestsFilter.
  ///
  /// In en, this message translates to:
  /// **'Leave Requests'**
  String get leaveRequestsFilter;

  /// No description provided for @overtimeRequestsFilter.
  ///
  /// In en, this message translates to:
  /// **'Overtime Requests'**
  String get overtimeRequestsFilter;

  /// No description provided for @businessTripRequestsFilter.
  ///
  /// In en, this message translates to:
  /// **'Business Trip Requests'**
  String get businessTripRequestsFilter;

  /// No description provided for @missingPunchRequestsFilter.
  ///
  /// In en, this message translates to:
  /// **'Missing Punch Requests'**
  String get missingPunchRequestsFilter;

  /// No description provided for @clearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear Filters'**
  String get clearFilters;

  /// No description provided for @exportToCSV.
  ///
  /// In en, this message translates to:
  /// **'Export to CSV'**
  String get exportToCSV;

  /// No description provided for @exportToXlsx.
  ///
  /// In en, this message translates to:
  /// **'Export to Xlsx'**
  String get exportToXlsx;

  /// No description provided for @exportByRequestType.
  ///
  /// In en, this message translates to:
  /// **'By Request Type'**
  String get exportByRequestType;

  /// No description provided for @exportByEmployee.
  ///
  /// In en, this message translates to:
  /// **'By Employee'**
  String get exportByEmployee;

  /// No description provided for @downloadingFiles.
  ///
  /// In en, this message translates to:
  /// **'Downloading {count} file(s)...'**
  String downloadingFiles(int count);

  /// No description provided for @csvExport.
  ///
  /// In en, this message translates to:
  /// **'CSV Export'**
  String get csvExport;

  /// No description provided for @csvContentGenerated.
  ///
  /// In en, this message translates to:
  /// **'CSV content generated successfully!'**
  String get csvContentGenerated;

  /// No description provided for @csvMobileInstructions.
  ///
  /// In en, this message translates to:
  /// **'On mobile platforms, you can copy this content and save it as a .csv file.'**
  String get csvMobileInstructions;

  /// No description provided for @showingRequests.
  ///
  /// In en, this message translates to:
  /// **'Showing {filteredCount} of {totalCount} requests'**
  String showingRequests(int filteredCount, int totalCount);

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get selectMonth;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @arabicName.
  ///
  /// In en, this message translates to:
  /// **'Arabic Name'**
  String get arabicName;

  /// No description provided for @nationalId.
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalId;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @contactInfoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Contact info updated successfully'**
  String get contactInfoUpdated;

  /// No description provided for @contactInfoUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update contact info'**
  String get contactInfoUpdateFailed;

  /// No description provided for @arabicNickname.
  ///
  /// In en, this message translates to:
  /// **'Arabic Nickname'**
  String get arabicNickname;

  /// No description provided for @englishNickname.
  ///
  /// In en, this message translates to:
  /// **'English Nickname'**
  String get englishNickname;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @jobTitleInArabic.
  ///
  /// In en, this message translates to:
  /// **'Job Title in Arabic'**
  String get jobTitleInArabic;

  /// No description provided for @jobTitleInEnglish.
  ///
  /// In en, this message translates to:
  /// **'Job Title in English'**
  String get jobTitleInEnglish;

  /// No description provided for @employeeCode.
  ///
  /// In en, this message translates to:
  /// **'Employee Code'**
  String get employeeCode;

  /// No description provided for @loginCode.
  ///
  /// In en, this message translates to:
  /// **'Login Code'**
  String get loginCode;

  /// No description provided for @directManager.
  ///
  /// In en, this message translates to:
  /// **'Direct Manager'**
  String get directManager;

  /// No description provided for @managersManager.
  ///
  /// In en, this message translates to:
  /// **'Manager\'s Manager'**
  String get managersManager;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @loadingEmployeeRequests.
  ///
  /// In en, this message translates to:
  /// **'Loading requests...'**
  String get loadingEmployeeRequests;

  /// No description provided for @addingEmployees.
  ///
  /// In en, this message translates to:
  /// **'Adding...'**
  String get addingEmployees;

  /// No description provided for @employeeId.
  ///
  /// In en, this message translates to:
  /// **'Employee ID'**
  String get employeeId;

  /// No description provided for @pleaseEnterEmployeeName.
  ///
  /// In en, this message translates to:
  /// **'Please enter employee name'**
  String get pleaseEnterEmployeeName;

  /// No description provided for @pleaseEnterArabicName.
  ///
  /// In en, this message translates to:
  /// **'Please enter Arabic name'**
  String get pleaseEnterArabicName;

  /// No description provided for @pleaseEnterJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter job title'**
  String get pleaseEnterJobTitle;

  /// No description provided for @pleaseEnterEmployeeCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter employee code'**
  String get pleaseEnterEmployeeCode;

  /// No description provided for @pleaseEnterLoginCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter login code'**
  String get pleaseEnterLoginCode;

  /// No description provided for @pleaseEnterHireDate.
  ///
  /// In en, this message translates to:
  /// **'Please enter Hire Date'**
  String get pleaseEnterHireDate;

  /// No description provided for @pleaseEnterN1Manager.
  ///
  /// In en, this message translates to:
  /// **'Please enter N+1 manager'**
  String get pleaseEnterN1Manager;

  /// No description provided for @pleaseEnterN2Manager.
  ///
  /// In en, this message translates to:
  /// **'Please enter N+2 manager'**
  String get pleaseEnterN2Manager;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get operationFailed;

  /// No description provided for @noEmployeeFound.
  ///
  /// In en, this message translates to:
  /// **'No employee found with this code'**
  String get noEmployeeFound;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Are you sure you want to leave?'**
  String get unsavedChangesMessage;

  /// No description provided for @stay.
  ///
  /// In en, this message translates to:
  /// **'Stay'**
  String get stay;

  /// No description provided for @leave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// No description provided for @departmentInArabic.
  ///
  /// In en, this message translates to:
  /// **'Department in Arabic'**
  String get departmentInArabic;

  /// No description provided for @departmentInEnglish.
  ///
  /// In en, this message translates to:
  /// **'Department in English'**
  String get departmentInEnglish;

  /// No description provided for @pleaseSelectDepartment.
  ///
  /// In en, this message translates to:
  /// **'Please select a department'**
  String get pleaseSelectDepartment;

  /// No description provided for @pleaseSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Please select a location'**
  String get pleaseSelectLocation;

  /// No description provided for @pleaseSelectCostCenter.
  ///
  /// In en, this message translates to:
  /// **'Please select cost center'**
  String get pleaseSelectCostCenter;

  /// No description provided for @costCenter.
  ///
  /// In en, this message translates to:
  /// **'Cost Center'**
  String get costCenter;

  /// No description provided for @topManagement.
  ///
  /// In en, this message translates to:
  /// **'Top Management'**
  String get topManagement;

  /// No description provided for @financialDepartment.
  ///
  /// In en, this message translates to:
  /// **'Financial Department'**
  String get financialDepartment;

  /// No description provided for @receptionDepartment.
  ///
  /// In en, this message translates to:
  /// **'Reception Department'**
  String get receptionDepartment;

  /// No description provided for @administrativeAffairs.
  ///
  /// In en, this message translates to:
  /// **'Administrative Affairs'**
  String get administrativeAffairs;

  /// No description provided for @eventsDepartment.
  ///
  /// In en, this message translates to:
  /// **'Events Department'**
  String get eventsDepartment;

  /// No description provided for @marketingDepartment.
  ///
  /// In en, this message translates to:
  /// **'Marketing Department'**
  String get marketingDepartment;

  /// No description provided for @leasingDepartment.
  ///
  /// In en, this message translates to:
  /// **'Leasing Department'**
  String get leasingDepartment;

  /// No description provided for @licenseDepartment.
  ///
  /// In en, this message translates to:
  /// **'Regulatory affairs & Licensing solutions'**
  String get licenseDepartment;

  /// No description provided for @maintenanceDepartment.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Department'**
  String get maintenanceDepartment;

  /// No description provided for @projectsDepartment.
  ///
  /// In en, this message translates to:
  /// **'Projects Department'**
  String get projectsDepartment;

  /// No description provided for @legalDepartment.
  ///
  /// In en, this message translates to:
  /// **'Legal Department'**
  String get legalDepartment;

  /// No description provided for @operationsDepartment.
  ///
  /// In en, this message translates to:
  /// **'Operations Department'**
  String get operationsDepartment;

  /// No description provided for @safetyDepartment.
  ///
  /// In en, this message translates to:
  /// **'Safety Department'**
  String get safetyDepartment;

  /// No description provided for @prDepartment.
  ///
  /// In en, this message translates to:
  /// **'PR Department'**
  String get prDepartment;

  /// No description provided for @purchasingDepartment.
  ///
  /// In en, this message translates to:
  /// **'Purchasing Department'**
  String get purchasingDepartment;

  /// No description provided for @cashierDepartment.
  ///
  /// In en, this message translates to:
  /// **'Cashier Department'**
  String get cashierDepartment;

  /// No description provided for @humanResourcesDepartment.
  ///
  /// In en, this message translates to:
  /// **'Human Resources Department'**
  String get humanResourcesDepartment;

  /// No description provided for @itDepartment.
  ///
  /// In en, this message translates to:
  /// **'IT Department'**
  String get itDepartment;

  /// No description provided for @warehousesDepartment.
  ///
  /// In en, this message translates to:
  /// **'Warehouses Department'**
  String get warehousesDepartment;

  /// No description provided for @collectionDepartment.
  ///
  /// In en, this message translates to:
  /// **'Collection Department'**
  String get collectionDepartment;

  /// No description provided for @pleaseEnterValidNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid number'**
  String get pleaseEnterValidNumber;

  /// No description provided for @pleaseEnterValidEmployeeCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid employee code'**
  String get pleaseEnterValidEmployeeCode;

  /// No description provided for @pleaseEnterValidN1ManagerCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid N+1 manager code'**
  String get pleaseEnterValidN1ManagerCode;

  /// No description provided for @pleaseEnterValidN2ManagerCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid N+2 manager code'**
  String get pleaseEnterValidN2ManagerCode;

  /// No description provided for @pleaseSelectShiftHours.
  ///
  /// In en, this message translates to:
  /// **'Please select shift hours'**
  String get pleaseSelectShiftHours;

  /// No description provided for @pleaseSelectWorkingDays.
  ///
  /// In en, this message translates to:
  /// **'Please select working days'**
  String get pleaseSelectWorkingDays;

  /// No description provided for @pleaseSelectLeavesEligibility.
  ///
  /// In en, this message translates to:
  /// **'Please select leaves eligibility'**
  String get pleaseSelectLeavesEligibility;

  /// No description provided for @n1DirectManagerCode.
  ///
  /// In en, this message translates to:
  /// **'N+1 (Direct Manager) Code'**
  String get n1DirectManagerCode;

  /// No description provided for @n2ManagersManagerCode.
  ///
  /// In en, this message translates to:
  /// **'N+2 (Manager\'s Manager) Code'**
  String get n2ManagersManagerCode;

  /// No description provided for @licensingDepartment.
  ///
  /// In en, this message translates to:
  /// **'Regulatory affairs & Licensing solutions'**
  String get licensingDepartment;

  /// No description provided for @internalSecurity.
  ///
  /// In en, this message translates to:
  /// **'Internal Security'**
  String get internalSecurity;

  /// No description provided for @filterByDateRange.
  ///
  /// In en, this message translates to:
  /// **'Filter by Date Range'**
  String get filterByDateRange;

  /// No description provided for @dateFilterEffective.
  ///
  /// In en, this message translates to:
  /// **'Effective Date'**
  String get dateFilterEffective;

  /// No description provided for @dateFilterCreated.
  ///
  /// In en, this message translates to:
  /// **'Created Date'**
  String get dateFilterCreated;

  /// No description provided for @filterByRequestStatus.
  ///
  /// In en, this message translates to:
  /// **'Filter by Request Status'**
  String get filterByRequestStatus;

  /// No description provided for @filterByUser.
  ///
  /// In en, this message translates to:
  /// **'Filter By User'**
  String get filterByUser;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All Statuses'**
  String get allStatuses;

  /// No description provided for @pendingStatus.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingStatus;

  /// No description provided for @approvedStatus.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approvedStatus;

  /// No description provided for @declinedStatus.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get declinedStatus;

  /// No description provided for @waitingStatus.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waitingStatus;

  /// No description provided for @submittedStatus.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submittedStatus;

  /// No description provided for @acceptedStatus.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get acceptedStatus;

  /// No description provided for @rejectedStatus.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejectedStatus;

  /// No description provided for @cancelledStatus.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledStatus;

  /// No description provided for @completedStatus.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedStatus;

  /// No description provided for @requestType.
  ///
  /// In en, this message translates to:
  /// **'Request Type'**
  String get requestType;

  /// No description provided for @overtimeType.
  ///
  /// In en, this message translates to:
  /// **'Overtime Type'**
  String get overtimeType;

  /// No description provided for @missingpunchType.
  ///
  /// In en, this message translates to:
  /// **'Missing Punch Type'**
  String get missingpunchType;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @selectDepartments.
  ///
  /// In en, this message translates to:
  /// **'Select Departments'**
  String get selectDepartments;

  /// No description provided for @departmentsSelected.
  ///
  /// In en, this message translates to:
  /// **'departments selected'**
  String get departmentsSelected;

  /// No description provided for @addEmployees.
  ///
  /// In en, this message translates to:
  /// **'Add Employees'**
  String get addEmployees;

  /// No description provided for @filteredBy.
  ///
  /// In en, this message translates to:
  /// **'Filtered By'**
  String get filteredBy;

  /// No description provided for @employee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employee;

  /// No description provided for @employeewithAl.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employeewithAl;

  /// No description provided for @employeesWithoutAl.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employeesWithoutAl;

  /// No description provided for @investigation.
  ///
  /// In en, this message translates to:
  /// **'Investigation'**
  String get investigation;

  /// No description provided for @investigations.
  ///
  /// In en, this message translates to:
  /// **'Investigations'**
  String get investigations;

  /// No description provided for @investigationDetails.
  ///
  /// In en, this message translates to:
  /// **'Investigation Details'**
  String get investigationDetails;

  /// No description provided for @employeeCount.
  ///
  /// In en, this message translates to:
  /// **'Employee Count'**
  String get employeeCount;

  /// No description provided for @numOfDays.
  ///
  /// In en, this message translates to:
  /// **'Num Of Days'**
  String get numOfDays;

  /// No description provided for @advanceOnSalary.
  ///
  /// In en, this message translates to:
  /// **'Advance on Salary'**
  String get advanceOnSalary;

  /// No description provided for @advanceOnSalaryRequests.
  ///
  /// In en, this message translates to:
  /// **'Advance on Salary Requests'**
  String get advanceOnSalaryRequests;

  /// No description provided for @advanceOnSalaryRequest.
  ///
  /// In en, this message translates to:
  /// **'Advance on Salary Request'**
  String get advanceOnSalaryRequest;

  /// No description provided for @advanceOnSalarySubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Advance on salary request submitted successfully'**
  String get advanceOnSalarySubmittedSuccessfully;

  /// No description provided for @advanceOnSalaryRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Advance on Salary Request'**
  String get advanceOnSalaryRequestTitle;

  /// No description provided for @browseAllManagedEmployees.
  ///
  /// In en, this message translates to:
  /// **'Browse All Managed Employees ({count})'**
  String browseAllManagedEmployees(int count);

  /// No description provided for @directEmployees.
  ///
  /// In en, this message translates to:
  /// **'Direct Employees'**
  String get directEmployees;

  /// No description provided for @indirectEmployees.
  ///
  /// In en, this message translates to:
  /// **'First Level Indirect'**
  String get indirectEmployees;

  /// No description provided for @allSubordinates.
  ///
  /// In en, this message translates to:
  /// **'Downline Employees'**
  String get allSubordinates;

  /// No description provided for @browseAllIndirectEmployees.
  ///
  /// In en, this message translates to:
  /// **'Browse First Level Indirect Employees ({count})'**
  String browseAllIndirectEmployees(int count);

  /// No description provided for @browseAllSubordinates.
  ///
  /// In en, this message translates to:
  /// **'Browse Downline Employees ({count})'**
  String browseAllSubordinates(int count);

  /// No description provided for @mandatoryPasswordChange.
  ///
  /// In en, this message translates to:
  /// **'Mandatory Password Change'**
  String get mandatoryPasswordChange;

  /// No description provided for @weakPasswordMessage.
  ///
  /// In en, this message translates to:
  /// **'Your current password is weak and must be changed for security reasons. You cannot access the system until you update your password.'**
  String get weakPasswordMessage;

  /// No description provided for @weakPasswordError.
  ///
  /// In en, this message translates to:
  /// **'Password can\'t be 123456. Please choose a stronger password.'**
  String get weakPasswordError;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long.'**
  String get passwordTooShort;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password requirements:\n• Must be at least 8 characters long\n• Must contain at least one uppercase letter (A-Z)\n• Must contain at least one lowercase letter (a-z)\n• Must contain at least one digit (0-9)\n• Must contain at least one special character (!@#\$%^&*)\n• Can\'t be 123456\n• Different from your current password'**
  String get passwordRequirements;

  /// No description provided for @passwordTooShortNew.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long'**
  String get passwordTooShortNew;

  /// No description provided for @passwordMissingUppercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one uppercase letter'**
  String get passwordMissingUppercase;

  /// No description provided for @passwordMissingLowercase.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one lowercase letter'**
  String get passwordMissingLowercase;

  /// No description provided for @passwordMissingDigit.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one digit'**
  String get passwordMissingDigit;

  /// No description provided for @passwordMissingSpecialChar.
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least one special character (!@#\$%^&*)'**
  String get passwordMissingSpecialChar;

  /// No description provided for @passwordComplexityError.
  ///
  /// In en, this message translates to:
  /// **'Password does not meet complexity requirements'**
  String get passwordComplexityError;

  /// No description provided for @unableToVerifyCurrentDate.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify current date'**
  String get unableToVerifyCurrentDate;

  /// No description provided for @checkInternetConnectionAndRetry.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection and try again'**
  String get checkInternetConnectionAndRetry;

  /// No description provided for @hireDate.
  ///
  /// In en, this message translates to:
  /// **'Hire Date'**
  String get hireDate;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @amountInLetters.
  ///
  /// In en, this message translates to:
  /// **'Amount in Letters'**
  String get amountInLetters;

  /// No description provided for @willBeCalculated.
  ///
  /// In en, this message translates to:
  /// **'Will be calculated'**
  String get willBeCalculated;

  /// No description provided for @paymentEndDate.
  ///
  /// In en, this message translates to:
  /// **'Payment End Date'**
  String get paymentEndDate;

  /// No description provided for @monthlyPayment.
  ///
  /// In en, this message translates to:
  /// **'Monthly Payment'**
  String get monthlyPayment;

  /// No description provided for @newMonthlyPayment.
  ///
  /// In en, this message translates to:
  /// **'New Monthly Payment'**
  String get newMonthlyPayment;

  /// No description provided for @searchByNameOrCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Search By Name Or Code'**
  String get searchByNameOrCodeHint;

  /// No description provided for @amountRequestedEgp.
  ///
  /// In en, this message translates to:
  /// **'Amount Requested (EGP) *'**
  String get amountRequestedEgp;

  /// No description provided for @enterAmountBetween.
  ///
  /// In en, this message translates to:
  /// **'Enter amount between 500 and 20,000 EGP'**
  String get enterAmountBetween;

  /// No description provided for @periodInMonths.
  ///
  /// In en, this message translates to:
  /// **'Period in Months *'**
  String get periodInMonths;

  /// No description provided for @enterPeriodBetween.
  ///
  /// In en, this message translates to:
  /// **'Enter period between 1 and 12 months'**
  String get enterPeriodBetween;

  /// No description provided for @paymentStartDate.
  ///
  /// In en, this message translates to:
  /// **'Payment Start Date'**
  String get paymentStartDate;

  /// No description provided for @mustBeOnFirstDay.
  ///
  /// In en, this message translates to:
  /// **'Must be on the 1st day, 1 or 2 months from now'**
  String get mustBeOnFirstDay;

  /// No description provided for @requestsCantBeSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Requests can\'t be submitted at this time'**
  String get requestsCantBeSubmitted;

  /// No description provided for @submissionWindowMessage.
  ///
  /// In en, this message translates to:
  /// **'The submission window is open only from the 15th to the 25th of each month'**
  String get submissionWindowMessage;

  /// No description provided for @notEligibleForAdvance.
  ///
  /// In en, this message translates to:
  /// **'Not Eligible for Advance on Salary'**
  String get notEligibleForAdvance;

  /// No description provided for @tenureLessThanSixMonths.
  ///
  /// In en, this message translates to:
  /// **'Since tenure is less than six months'**
  String get tenureLessThanSixMonths;

  /// No description provided for @currentAdvanceOnSalaryRequest.
  ///
  /// In en, this message translates to:
  /// **'Since Employee has a current advance on salary'**
  String get currentAdvanceOnSalaryRequest;

  /// No description provided for @newEmployeePeriodRestriction.
  ///
  /// In en, this message translates to:
  /// **'For employees with less than 1 year tenure, the period is automatically set to 1 month only'**
  String get newEmployeePeriodRestriction;

  /// No description provided for @newEmployeePaymentStartRestriction.
  ///
  /// In en, this message translates to:
  /// **'For employees with less than 1 year tenure, the payment start date is automatically set to next month'**
  String get newEmployeePaymentStartRestriction;

  /// No description provided for @advanceEligibilityDateRestriction.
  ///
  /// In en, this message translates to:
  /// **'This employee will be eligible for advance on salary starting from {eligibilityDate}'**
  String advanceEligibilityDateRestriction(String eligibilityDate);

  /// No description provided for @pendingRequestExists.
  ///
  /// In en, this message translates to:
  /// **'Pending Request Exists'**
  String get pendingRequestExists;

  /// No description provided for @pendingRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'This employee already has a pending advance on salary request. Please wait for the current request to be processed before submitting a new one.'**
  String get pendingRequestMessage;

  /// No description provided for @checkingPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Checking for pending requests...'**
  String get checkingPendingRequests;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelRequest;

  /// No description provided for @confirmCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Confirm Cancel Request'**
  String get confirmCancelRequest;

  /// No description provided for @cancelRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this request? This action cannot be undone.'**
  String get cancelRequestMessage;

  /// No description provided for @requestCancelledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request cancelled successfully'**
  String get requestCancelledSuccessfully;

  /// No description provided for @cancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling...'**
  String get cancelling;

  /// No description provided for @errorCancellingRequest.
  ///
  /// In en, this message translates to:
  /// **'Error cancelling request'**
  String get errorCancellingRequest;

  /// No description provided for @requestCancellation.
  ///
  /// In en, this message translates to:
  /// **'Cancellation Request'**
  String get requestCancellation;

  /// No description provided for @leaveCancellationRequests.
  ///
  /// In en, this message translates to:
  /// **'Leave Cancellation Requests'**
  String get leaveCancellationRequests;

  /// No description provided for @leaveCancellationRequest.
  ///
  /// In en, this message translates to:
  /// **'Leave Cancellation Request'**
  String get leaveCancellationRequest;

  /// No description provided for @cancellationRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'This will create a cancellation request that requires approval from your manager and HR. Please provide a reason:'**
  String get cancellationRequestMessage;

  /// No description provided for @cancellationRequestSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Cancellation request submitted successfully'**
  String get cancellationRequestSubmittedSuccessfully;

  /// No description provided for @errorSubmittingCancellationRequest.
  ///
  /// In en, this message translates to:
  /// **'Error submitting cancellation request'**
  String get errorSubmittingCancellationRequest;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @confirmRemoveRequest.
  ///
  /// In en, this message translates to:
  /// **'Confirm Remove Request'**
  String get confirmRemoveRequest;

  /// No description provided for @removeRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this request from the list?'**
  String get removeRequestMessage;

  /// No description provided for @requestRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request removed successfully'**
  String get requestRemovedSuccessfully;

  /// No description provided for @removing.
  ///
  /// In en, this message translates to:
  /// **'Removing...'**
  String get removing;

  /// No description provided for @errorRemovingRequest.
  ///
  /// In en, this message translates to:
  /// **'Error removing request'**
  String get errorRemovingRequest;

  /// No description provided for @selectPaymentStartDate.
  ///
  /// In en, this message translates to:
  /// **'Select Payment Start Date'**
  String get selectPaymentStartDate;

  /// No description provided for @pleaseFillAllRequiredFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all required fields'**
  String get pleaseFillAllRequiredFields;

  /// No description provided for @myAdvanceOnSalaryRequests.
  ///
  /// In en, this message translates to:
  /// **'My Advance on Salary Requests'**
  String get myAdvanceOnSalaryRequests;

  /// No description provided for @teamAdvanceOnSalaryRequests.
  ///
  /// In en, this message translates to:
  /// **'Team Advance on Salary Requests'**
  String get teamAdvanceOnSalaryRequests;

  /// No description provided for @searchByNameCodeOrAmount.
  ///
  /// In en, this message translates to:
  /// **'Search by name, code or amount'**
  String get searchByNameCodeOrAmount;

  /// No description provided for @allStatus.
  ///
  /// In en, this message translates to:
  /// **'All Status'**
  String get allStatus;

  /// No description provided for @allMonths.
  ///
  /// In en, this message translates to:
  /// **'All Months'**
  String get allMonths;

  /// No description provided for @groupHr.
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get groupHr;

  /// No description provided for @groupFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get groupFinance;

  /// No description provided for @groupLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get groupLegal;

  /// No description provided for @groupTopManagement.
  ///
  /// In en, this message translates to:
  /// **'Top Management'**
  String get groupTopManagement;

  /// No description provided for @groupIt.
  ///
  /// In en, this message translates to:
  /// **'IT'**
  String get groupIt;

  /// No description provided for @groupDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get groupDashboard;

  /// No description provided for @perPage.
  ///
  /// In en, this message translates to:
  /// **'Per Page'**
  String get perPage;

  /// No description provided for @sortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by:'**
  String get sortBy;

  /// No description provided for @dateCreated.
  ///
  /// In en, this message translates to:
  /// **'Date Created'**
  String get dateCreated;

  /// No description provided for @period.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get period;

  /// No description provided for @ascending.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get descending;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No requests found'**
  String get noRequestsFound;

  /// No description provided for @noNewUpdates.
  ///
  /// In en, this message translates to:
  /// **'No new updates'**
  String get noNewUpdates;

  /// No description provided for @tryAdjustingSearchFilters.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filters'**
  String get tryAdjustingSearchFilters;

  /// No description provided for @showingRequestsOfTotal.
  ///
  /// In en, this message translates to:
  /// **'Showing {showing} of {total} requests'**
  String showingRequestsOfTotal(int showing, int total);

  /// No description provided for @requestor.
  ///
  /// In en, this message translates to:
  /// **'Requestor'**
  String get requestor;

  /// No description provided for @borrower.
  ///
  /// In en, this message translates to:
  /// **'Borrower'**
  String get borrower;

  /// No description provided for @amountRequested.
  ///
  /// In en, this message translates to:
  /// **'Amount Requested'**
  String get amountRequested;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @currentApprover.
  ///
  /// In en, this message translates to:
  /// **'Current Approver'**
  String get currentApprover;

  /// No description provided for @n2Manager.
  ///
  /// In en, this message translates to:
  /// **'N+2'**
  String get n2Manager;

  /// No description provided for @hrDepartment.
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get hrDepartment;

  /// No description provided for @financeDepartment.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get financeDepartment;

  /// No description provided for @paymentStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment Start Date'**
  String get paymentStartDateLabel;

  /// No description provided for @paymentEndDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment End Date'**
  String get paymentEndDateLabel;

  /// No description provided for @monthlyPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Monthly Payment'**
  String get monthlyPaymentLabel;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @months.
  ///
  /// In en, this message translates to:
  /// **'months'**
  String get months;

  /// No description provided for @declining.
  ///
  /// In en, this message translates to:
  /// **'Declining...'**
  String get declining;

  /// No description provided for @approving.
  ///
  /// In en, this message translates to:
  /// **'Approving...'**
  String get approving;

  /// No description provided for @pageOfPages.
  ///
  /// In en, this message translates to:
  /// **'Page {current} of {total}'**
  String pageOfPages(int current, int total);

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous Page'**
  String get previousPage;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next Page'**
  String get nextPage;

  /// No description provided for @requestApprovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request approved successfully'**
  String get requestApprovedSuccessfully;

  /// No description provided for @failedToApproveRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to approve request: {error}'**
  String failedToApproveRequest(String error);

  /// No description provided for @requestDeclinedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request declined successfully'**
  String get requestDeclinedSuccessfully;

  /// No description provided for @requestPutOnHoldSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request put on hold successfully'**
  String get requestPutOnHoldSuccessfully;

  /// No description provided for @failedToDeclineRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to decline request: {error}'**
  String failedToDeclineRequest(String error);

  /// No description provided for @failedToPutOnHoldRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to put request on hold: {error}'**
  String failedToPutOnHoldRequest(String error);

  /// No description provided for @errorLoadingRequests.
  ///
  /// In en, this message translates to:
  /// **'Error loading requests: {error}'**
  String errorLoadingRequests(String error);

  /// No description provided for @approvalConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Approval Confirmation'**
  String get approvalConfirmation;

  /// No description provided for @requestDetails.
  ///
  /// In en, this message translates to:
  /// **'Request Details'**
  String get requestDetails;

  /// No description provided for @requestId.
  ///
  /// In en, this message translates to:
  /// **'Request ID'**
  String get requestId;

  /// No description provided for @declineRequest.
  ///
  /// In en, this message translates to:
  /// **'Decline Request'**
  String get declineRequest;

  /// No description provided for @provideDeclinereason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for declining this request:'**
  String get provideDeclinereason;

  /// No description provided for @enterDeclineReason.
  ///
  /// In en, this message translates to:
  /// **'Enter decline reason...'**
  String get enterDeclineReason;

  /// No description provided for @pleaseEnterDeclineReason.
  ///
  /// In en, this message translates to:
  /// **'Please enter a decline reason'**
  String get pleaseEnterDeclineReason;

  /// No description provided for @confirmApproval.
  ///
  /// In en, this message translates to:
  /// **'Confirm Approval'**
  String get confirmApproval;

  /// No description provided for @confirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming...'**
  String get confirming;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @previewPdf.
  ///
  /// In en, this message translates to:
  /// **'Preview PDF'**
  String get previewPdf;

  /// No description provided for @printPdf.
  ///
  /// In en, this message translates to:
  /// **'Print PDF'**
  String get printPdf;

  /// No description provided for @printing.
  ///
  /// In en, this message translates to:
  /// **'Printing...'**
  String get printing;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// No description provided for @generatePdf.
  ///
  /// In en, this message translates to:
  /// **'Generate PDF'**
  String get generatePdf;

  /// No description provided for @pdfActions.
  ///
  /// In en, this message translates to:
  /// **'PDF Actions'**
  String get pdfActions;

  /// No description provided for @pdfNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'PDF not available yet'**
  String get pdfNotAvailable;

  /// No description provided for @pdfGeneratedWhenApproved.
  ///
  /// In en, this message translates to:
  /// **'PDF will be generated when the request is fully approved by Finance'**
  String get pdfGeneratedWhenApproved;

  /// No description provided for @downloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Download PDF'**
  String get downloadPdf;

  /// No description provided for @pdfDownloadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PDF downloaded successfully to {filePath}'**
  String pdfDownloadedSuccessfully(String filePath);

  /// No description provided for @failedToDownloadPdf.
  ///
  /// In en, this message translates to:
  /// **'Failed to download PDF: {error}'**
  String failedToDownloadPdf(String error);

  /// No description provided for @unsettled.
  ///
  /// In en, this message translates to:
  /// **'Unsettled'**
  String get unsettled;

  /// No description provided for @settled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get settled;

  /// No description provided for @settle.
  ///
  /// In en, this message translates to:
  /// **'Settle'**
  String get settle;

  /// No description provided for @settling.
  ///
  /// In en, this message translates to:
  /// **'Settling...'**
  String get settling;

  /// No description provided for @manuallySettled.
  ///
  /// In en, this message translates to:
  /// **'Manually Settled'**
  String get manuallySettled;

  /// No description provided for @settledBy.
  ///
  /// In en, this message translates to:
  /// **'Settled By'**
  String get settledBy;

  /// No description provided for @settlementDate.
  ///
  /// In en, this message translates to:
  /// **'Settlement Date'**
  String get settlementDate;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @confirmSettlement.
  ///
  /// In en, this message translates to:
  /// **'Confirm Settlement'**
  String get confirmSettlement;

  /// No description provided for @confirmSettlementMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to settle this advance on salary request? This action cannot be undone.'**
  String get confirmSettlementMessage;

  /// No description provided for @settlementWarning.
  ///
  /// In en, this message translates to:
  /// **'This will mark the request as manually settled and update the borrower\'s eligibility date to today.'**
  String get settlementWarning;

  /// No description provided for @confirmSettle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Settle'**
  String get confirmSettle;

  /// No description provided for @confirmSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Confirm Submit Request'**
  String get confirmSubmitRequest;

  /// No description provided for @areYouSureToSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to submit this advance on salary request?'**
  String get areYouSureToSubmitRequest;

  /// No description provided for @areYouSureToSubmitDisciplinaryRequest.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to submit this disciplinary action request?'**
  String get areYouSureToSubmitDisciplinaryRequest;

  /// No description provided for @requestSettledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request settled successfully'**
  String get requestSettledSuccessfully;

  /// No description provided for @failedToSettleRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to settle request: {error}'**
  String failedToSettleRequest(String error);

  /// No description provided for @confirmPasswordDoesNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Confirm password does not match new password'**
  String get confirmPasswordDoesNotMatch;

  /// No description provided for @oldPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Old password is incorrect'**
  String get oldPasswordIncorrect;

  /// No description provided for @updatePasswordFailed.
  ///
  /// In en, this message translates to:
  /// **'Update password failed'**
  String get updatePasswordFailed;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid employee code or password. Please try again.'**
  String get invalidCredentials;

  /// No description provided for @emailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Email not confirmed. Please check your email.'**
  String get emailNotConfirmed;

  /// No description provided for @tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many login attempts. Please try again later.'**
  String get tooManyRequests;

  /// No description provided for @signupFailed.
  ///
  /// In en, this message translates to:
  /// **'Signup failed'**
  String get signupFailed;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password can\'t be 123456. Please choose a stronger password.'**
  String get weakPassword;

  /// No description provided for @samePassword.
  ///
  /// In en, this message translates to:
  /// **'New password must be different from old password'**
  String get samePassword;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @accountSuspended.
  ///
  /// In en, this message translates to:
  /// **'Your account is suspended.'**
  String get accountSuspended;

  /// No description provided for @employeeCodeOnlyNumbers.
  ///
  /// In en, this message translates to:
  /// **'Employee code must contain only numbers'**
  String get employeeCodeOnlyNumbers;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get fieldRequired;

  /// No description provided for @reasonMinLength.
  ///
  /// In en, this message translates to:
  /// **'Reason must be at least {min} characters'**
  String reasonMinLength(Object min);

  /// No description provided for @advanceOnSalaryRequestsFilter.
  ///
  /// In en, this message translates to:
  /// **'Advance on Salary Requests'**
  String get advanceOnSalaryRequestsFilter;

  /// No description provided for @groupManagement.
  ///
  /// In en, this message translates to:
  /// **'Group Management'**
  String get groupManagement;

  /// No description provided for @addToGroup.
  ///
  /// In en, this message translates to:
  /// **'Add to Group'**
  String get addToGroup;

  /// No description provided for @addGroup.
  ///
  /// In en, this message translates to:
  /// **'Add Group'**
  String get addGroup;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @userAlreadyInGroup.
  ///
  /// In en, this message translates to:
  /// **'User is already in {group} group'**
  String userAlreadyInGroup(String group);

  /// No description provided for @successfullyAddedUserToGroup.
  ///
  /// In en, this message translates to:
  /// **'Successfully added user to {group} group'**
  String successfullyAddedUserToGroup(String group);

  /// No description provided for @failedToAddUserToGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to add user to group: {error}'**
  String failedToAddUserToGroup(String error);

  /// No description provided for @removeFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove from Group'**
  String get removeFromGroup;

  /// No description provided for @successfullyRemovedUserFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Successfully removed user from {group} group'**
  String successfullyRemovedUserFromGroup(String group);

  /// No description provided for @failedToRemoveUserFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove user from group: {error}'**
  String failedToRemoveUserFromGroup(String error);

  /// No description provided for @userNotInGroup.
  ///
  /// In en, this message translates to:
  /// **'User is not in {group} group'**
  String userNotInGroup(String group);

  /// No description provided for @currentGroups.
  ///
  /// In en, this message translates to:
  /// **'Current Groups'**
  String get currentGroups;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @selectEmployee.
  ///
  /// In en, this message translates to:
  /// **'Select Employee'**
  String get selectEmployee;

  /// No description provided for @selectedEmployee.
  ///
  /// In en, this message translates to:
  /// **'Selected Employee'**
  String get selectedEmployee;

  /// No description provided for @clearSelection.
  ///
  /// In en, this message translates to:
  /// **'Clear Selection'**
  String get clearSelection;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// No description provided for @disciplinaryAction.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary Action'**
  String get disciplinaryAction;

  /// No description provided for @disciplinaryActionRequest.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary Action Request'**
  String get disciplinaryActionRequest;

  /// No description provided for @disciplinaryActionRequests.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary Action Requests'**
  String get disciplinaryActionRequests;

  /// No description provided for @myDisciplinaryActionRequests.
  ///
  /// In en, this message translates to:
  /// **'My Disciplinary Action Requests'**
  String get myDisciplinaryActionRequests;

  /// No description provided for @teamDisciplinaryActionRequests.
  ///
  /// In en, this message translates to:
  /// **'Team Disciplinary Action Requests'**
  String get teamDisciplinaryActionRequests;

  /// No description provided for @processedDisciplinaryActionRequests.
  ///
  /// In en, this message translates to:
  /// **'Processed Disciplinary Action Requests'**
  String get processedDisciplinaryActionRequests;

  /// No description provided for @disciplinaryActionType.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary Action Type'**
  String get disciplinaryActionType;

  /// No description provided for @actionType.
  ///
  /// In en, this message translates to:
  /// **'Action Type'**
  String get actionType;

  /// No description provided for @selectActionType.
  ///
  /// In en, this message translates to:
  /// **'Select Action Type'**
  String get selectActionType;

  /// No description provided for @verbalRemark.
  ///
  /// In en, this message translates to:
  /// **'Verbal Remark'**
  String get verbalRemark;

  /// No description provided for @writtenRemark.
  ///
  /// In en, this message translates to:
  /// **'Written Remark'**
  String get writtenRemark;

  /// No description provided for @writtenWarning.
  ///
  /// In en, this message translates to:
  /// **'Written Warning'**
  String get writtenWarning;

  /// No description provided for @selectEmployees.
  ///
  /// In en, this message translates to:
  /// **'Select Employees'**
  String get selectEmployees;

  /// No description provided for @selectedEmployees.
  ///
  /// In en, this message translates to:
  /// **'Selected Employees'**
  String get selectedEmployees;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @removeEmployee.
  ///
  /// In en, this message translates to:
  /// **'Remove Employee'**
  String get removeEmployee;

  /// No description provided for @browseAllEmployees.
  ///
  /// In en, this message translates to:
  /// **'Browse All Employees'**
  String get browseAllEmployees;

  /// No description provided for @pleaseSelectAtLeastOneEmployee.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one employee'**
  String get pleaseSelectAtLeastOneEmployee;

  /// No description provided for @incidentDescription.
  ///
  /// In en, this message translates to:
  /// **'Incident Description'**
  String get incidentDescription;

  /// No description provided for @describeIncident.
  ///
  /// In en, this message translates to:
  /// **'Please describe the incident in detail'**
  String get describeIncident;

  /// No description provided for @violationDate.
  ///
  /// In en, this message translates to:
  /// **'Violation Date'**
  String get violationDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// No description provided for @writtenWarningOptions.
  ///
  /// In en, this message translates to:
  /// **'Written Warning Options'**
  String get writtenWarningOptions;

  /// No description provided for @deductDays.
  ///
  /// In en, this message translates to:
  /// **'Deduct Days'**
  String get deductDays;

  /// No description provided for @quarterDay.
  ///
  /// In en, this message translates to:
  /// **'1/4 Day'**
  String get quarterDay;

  /// No description provided for @halfDay.
  ///
  /// In en, this message translates to:
  /// **'1/2 Day'**
  String get halfDay;

  /// No description provided for @selectDeductDays.
  ///
  /// In en, this message translates to:
  /// **'Select deduct days'**
  String get selectDeductDays;

  /// No description provided for @additionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additionalInformation;

  /// No description provided for @witnessStatements.
  ///
  /// In en, this message translates to:
  /// **'Witness Statements'**
  String get witnessStatements;

  /// No description provided for @recommendedAction.
  ///
  /// In en, this message translates to:
  /// **'Recommended Action'**
  String get recommendedAction;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'(Optional)'**
  String get optional;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @requestSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request submitted successfully'**
  String get requestSubmittedSuccessfully;

  /// No description provided for @searchEmployee.
  ///
  /// In en, this message translates to:
  /// **'Search Employee'**
  String get searchEmployee;

  /// No description provided for @orSelectFromList.
  ///
  /// In en, this message translates to:
  /// **'Or select from list'**
  String get orSelectFromList;

  /// No description provided for @terminationWarning.
  ///
  /// In en, this message translates to:
  /// **'Termination Warning'**
  String get terminationWarning;

  /// No description provided for @searchRequests.
  ///
  /// In en, this message translates to:
  /// **'Search requests...'**
  String get searchRequests;

  /// No description provided for @sortAscending.
  ///
  /// In en, this message translates to:
  /// **'Sort Ascending'**
  String get sortAscending;

  /// No description provided for @sortDescending.
  ///
  /// In en, this message translates to:
  /// **'Sort Descending'**
  String get sortDescending;

  /// No description provided for @enterReason.
  ///
  /// In en, this message translates to:
  /// **'Enter reason...'**
  String get enterReason;

  /// No description provided for @pleaseEnterReason.
  ///
  /// In en, this message translates to:
  /// **'Please enter a reason'**
  String get pleaseEnterReason;

  /// No description provided for @pleaseEnterApprovalReason.
  ///
  /// In en, this message translates to:
  /// **'Please enter approval reason'**
  String get pleaseEnterApprovalReason;

  /// No description provided for @pleaseEnterHoldReason.
  ///
  /// In en, this message translates to:
  /// **'Please enter hold reason'**
  String get pleaseEnterHoldReason;

  /// No description provided for @pleaseEnterInvestigationReason.
  ///
  /// In en, this message translates to:
  /// **'Please enter investigation reason'**
  String get pleaseEnterInvestigationReason;

  /// No description provided for @approvalReason.
  ///
  /// In en, this message translates to:
  /// **'Approval Reason'**
  String get approvalReason;

  /// No description provided for @holdReason.
  ///
  /// In en, this message translates to:
  /// **'Hold Reason'**
  String get holdReason;

  /// No description provided for @investigationReason.
  ///
  /// In en, this message translates to:
  /// **'Investigation Reason'**
  String get investigationReason;

  /// No description provided for @sendToHrInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Send to HR for Investigation'**
  String get sendToHrInvestigation;

  /// No description provided for @sendingToHrInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Sending to HR for Investigation...'**
  String get sendingToHrInvestigation;

  /// No description provided for @sentToHrInvestigationSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request sent to HR for investigation successfully'**
  String get sentToHrInvestigationSuccessfully;

  /// No description provided for @failedToSendToHrInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Failed to send to HR for investigation: {error}'**
  String failedToSendToHrInvestigation(String error);

  /// No description provided for @editWrittenWarning.
  ///
  /// In en, this message translates to:
  /// **'Edit Written Warning'**
  String get editWrittenWarning;

  /// No description provided for @editDeductDays.
  ///
  /// In en, this message translates to:
  /// **'Edit Deduct Days'**
  String get editDeductDays;

  /// No description provided for @editSuspensionDays.
  ///
  /// In en, this message translates to:
  /// **'Edit Suspension Days'**
  String get editSuspensionDays;

  /// No description provided for @writtenWarningUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Written warning options updated successfully'**
  String get writtenWarningUpdatedSuccessfully;

  /// No description provided for @failedToUpdateWrittenWarning.
  ///
  /// In en, this message translates to:
  /// **'Failed to update written warning: {error}'**
  String failedToUpdateWrittenWarning(String error);

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @employeeTerminationWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'This employee has {warningCount} written warnings in the last 6 months.'**
  String employeeTerminationWarningMessage(int warningCount);

  /// No description provided for @deductDaysHint.
  ///
  /// In en, this message translates to:
  /// **'1-5'**
  String get deductDaysHint;

  /// No description provided for @suspensionDaysHint.
  ///
  /// In en, this message translates to:
  /// **'1-7'**
  String get suspensionDaysHint;

  /// No description provided for @suspensionDays.
  ///
  /// In en, this message translates to:
  /// **'Suspension Days'**
  String get suspensionDays;

  /// No description provided for @pleaseSelectEmployee.
  ///
  /// In en, this message translates to:
  /// **'Please select an employee'**
  String get pleaseSelectEmployee;

  /// No description provided for @pleaseSelectActionType.
  ///
  /// In en, this message translates to:
  /// **'Please select a disciplinary action type'**
  String get pleaseSelectActionType;

  /// No description provided for @pleaseProvideIncidentDetails.
  ///
  /// In en, this message translates to:
  /// **'Please provide incident details'**
  String get pleaseProvideIncidentDetails;

  /// No description provided for @incidentDescriptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Incident description must be at least 10 words'**
  String get incidentDescriptionTooShort;

  /// No description provided for @pleaseSelectViolationDate.
  ///
  /// In en, this message translates to:
  /// **'Please select the violation date'**
  String get pleaseSelectViolationDate;

  /// No description provided for @violationDateFuture.
  ///
  /// In en, this message translates to:
  /// **'Violation date cannot be in the future'**
  String get violationDateFuture;

  /// No description provided for @violationDateTooOld.
  ///
  /// In en, this message translates to:
  /// **'Violation date cannot be more than 30 days ago'**
  String get violationDateTooOld;

  /// No description provided for @deductDaysRange.
  ///
  /// In en, this message translates to:
  /// **'Deduction days must be between 1 and 5'**
  String get deductDaysRange;

  /// No description provided for @suspensionDaysRange.
  ///
  /// In en, this message translates to:
  /// **'Suspension days must be between 1 and 7'**
  String get suspensionDaysRange;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @enterDaysBetween1And5.
  ///
  /// In en, this message translates to:
  /// **'Enter days between 1-5'**
  String get enterDaysBetween1And5;

  /// No description provided for @enterSuspensionDaysBetween1And7.
  ///
  /// In en, this message translates to:
  /// **'Enter suspension days between 1-7'**
  String get enterSuspensionDaysBetween1And7;

  /// No description provided for @employeeConfirmationRequired.
  ///
  /// In en, this message translates to:
  /// **'Employee Confirmation Required'**
  String get employeeConfirmationRequired;

  /// No description provided for @financeHasEditedPaymentPeriod.
  ///
  /// In en, this message translates to:
  /// **'Finance has edited the payment period for your advance on salary request. Please review and confirm or cancel the request.'**
  String get financeHasEditedPaymentPeriod;

  /// No description provided for @confirmFinanceEdit.
  ///
  /// In en, this message translates to:
  /// **'Confirm Changes'**
  String get confirmFinanceEdit;

  /// No description provided for @cancelFinanceEdit.
  ///
  /// In en, this message translates to:
  /// **'Cancel Request'**
  String get cancelFinanceEdit;

  /// No description provided for @confirmingChanges.
  ///
  /// In en, this message translates to:
  /// **'Confirming Changes...'**
  String get confirmingChanges;

  /// No description provided for @cancellingRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancelling Request...'**
  String get cancellingRequest;

  /// No description provided for @changesConfirmedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Changes confirmed successfully'**
  String get changesConfirmedSuccessfully;

  /// No description provided for @failedToConfirmChanges.
  ///
  /// In en, this message translates to:
  /// **'Failed to confirm changes: {error}'**
  String failedToConfirmChanges(String error);

  /// No description provided for @failedToCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel request: {error}'**
  String failedToCancelRequest(String error);

  /// No description provided for @financeAcknowledgmentRequired.
  ///
  /// In en, this message translates to:
  /// **'Finance Acknowledgment Required'**
  String get financeAcknowledgmentRequired;

  /// No description provided for @employeeHasRespondedToFinanceEdit.
  ///
  /// In en, this message translates to:
  /// **'Employee has responded to the finance edit. Please acknowledge their decision.'**
  String get employeeHasRespondedToFinanceEdit;

  /// No description provided for @acknowledgeEmployeeDecision.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge Decision'**
  String get acknowledgeEmployeeDecision;

  /// No description provided for @acknowledgingDecision.
  ///
  /// In en, this message translates to:
  /// **'Acknowledging Decision...'**
  String get acknowledgingDecision;

  /// No description provided for @decisionAcknowledgedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Decision acknowledged successfully'**
  String get decisionAcknowledgedSuccessfully;

  /// No description provided for @failedToAcknowledgeDecision.
  ///
  /// In en, this message translates to:
  /// **'Failed to acknowledge decision: {error}'**
  String failedToAcknowledgeDecision(String error);

  /// No description provided for @employeeConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Employee Confirmed'**
  String get employeeConfirmed;

  /// No description provided for @employeeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Employee Cancelled'**
  String get employeeCancelled;

  /// No description provided for @pendingEmployeeConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Pending Employee Confirmation'**
  String get pendingEmployeeConfirmation;

  /// No description provided for @pendingFinanceAcknowledgment.
  ///
  /// In en, this message translates to:
  /// **'Pending Finance Acknowledgment'**
  String get pendingFinanceAcknowledgment;

  /// No description provided for @employeeConfirmationRequests.
  ///
  /// In en, this message translates to:
  /// **'My Advance on Salary Requests'**
  String get employeeConfirmationRequests;

  /// No description provided for @orgChart.
  ///
  /// In en, this message translates to:
  /// **'Org Chart'**
  String get orgChart;

  /// No description provided for @businessTripCancellationRequest.
  ///
  /// In en, this message translates to:
  /// **'Business Trip Cancellation Request'**
  String get businessTripCancellationRequest;

  /// No description provided for @businessTripCancellationRequests.
  ///
  /// In en, this message translates to:
  /// **'Business Trip Cancellation Requests'**
  String get businessTripCancellationRequests;

  /// No description provided for @firstLineManager.
  ///
  /// In en, this message translates to:
  /// **'First Line Manager'**
  String get firstLineManager;

  /// No description provided for @secondLineManager.
  ///
  /// In en, this message translates to:
  /// **'Second Line Manager'**
  String get secondLineManager;

  /// No description provided for @approvedByN1.
  ///
  /// In en, this message translates to:
  /// **'Approved by N+1'**
  String get approvedByN1;

  /// No description provided for @approvedByN2.
  ///
  /// In en, this message translates to:
  /// **'Approved by N+2'**
  String get approvedByN2;

  /// No description provided for @approvedByHR.
  ///
  /// In en, this message translates to:
  /// **'Approved by HR'**
  String get approvedByHR;

  /// No description provided for @approvedByFinance.
  ///
  /// In en, this message translates to:
  /// **'Approved by Finance'**
  String get approvedByFinance;

  /// No description provided for @approvedBy.
  ///
  /// In en, this message translates to:
  /// **'Approved by'**
  String get approvedBy;

  /// No description provided for @acknowledgedBy.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged by'**
  String get acknowledgedBy;

  /// No description provided for @completedBy.
  ///
  /// In en, this message translates to:
  /// **'Completed by'**
  String get completedBy;

  /// No description provided for @declinedBy.
  ///
  /// In en, this message translates to:
  /// **'Declined by'**
  String get declinedBy;

  /// No description provided for @declinedByN1.
  ///
  /// In en, this message translates to:
  /// **'Declined by N+1'**
  String get declinedByN1;

  /// No description provided for @declinedByN2.
  ///
  /// In en, this message translates to:
  /// **'Declined by N+2'**
  String get declinedByN2;

  /// No description provided for @declinedByHR.
  ///
  /// In en, this message translates to:
  /// **'Declined by HR'**
  String get declinedByHR;

  /// No description provided for @declinedByFinance.
  ///
  /// In en, this message translates to:
  /// **'Declined by Finance'**
  String get declinedByFinance;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get on;

  /// No description provided for @autoFillNicknameFromFullName.
  ///
  /// In en, this message translates to:
  /// **'Auto-fill from full name'**
  String get autoFillNicknameFromFullName;

  /// No description provided for @unavailableLeaveRequest.
  ///
  /// In en, this message translates to:
  /// **'Unavailable: Leave Request'**
  String get unavailableLeaveRequest;

  /// No description provided for @unavailableBusinessTrip.
  ///
  /// In en, this message translates to:
  /// **'Unavailable: Business Trip'**
  String get unavailableBusinessTrip;

  /// No description provided for @unavailableMissingPunch.
  ///
  /// In en, this message translates to:
  /// **'Unavailable: Missing Punch Request'**
  String get unavailableMissingPunch;

  /// No description provided for @hoursRequiredDueToMissingPunch.
  ///
  /// In en, this message translates to:
  /// **'Hours selection is required because a missing punch request exists on this date'**
  String get hoursRequiredDueToMissingPunch;

  /// No description provided for @leaveTypeAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get leaveTypeAnnual;

  /// No description provided for @leaveTypeEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get leaveTypeEmergency;

  /// No description provided for @leaveTypeSick.
  ///
  /// In en, this message translates to:
  /// **'Sick'**
  String get leaveTypeSick;

  /// No description provided for @leaveTypeCompensation.
  ///
  /// In en, this message translates to:
  /// **'Compensation'**
  String get leaveTypeCompensation;

  /// No description provided for @leaveTypeUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get leaveTypeUnpaid;

  /// No description provided for @moreActions.
  ///
  /// In en, this message translates to:
  /// **'More Actions'**
  String get moreActions;

  /// No description provided for @puttingOnHold.
  ///
  /// In en, this message translates to:
  /// **'Putting on Hold...'**
  String get puttingOnHold;

  /// No description provided for @investigating.
  ///
  /// In en, this message translates to:
  /// **'Sending to Investigation...'**
  String get investigating;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @acknowledgeWithRemark.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge with Remark'**
  String get acknowledgeWithRemark;

  /// No description provided for @confirmAcknowledgment.
  ///
  /// In en, this message translates to:
  /// **'Confirm Acknowledgment'**
  String get confirmAcknowledgment;

  /// No description provided for @pleaseProvideYourRemarkOnThisAction.
  ///
  /// In en, this message translates to:
  /// **'Please provide your remark on this action:'**
  String get pleaseProvideYourRemarkOnThisAction;

  /// No description provided for @areYouSureYouWantToAcknowledgeThisRequest.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to acknowledge this disciplinary action request?'**
  String get areYouSureYouWantToAcknowledgeThisRequest;

  /// No description provided for @yourRemark.
  ///
  /// In en, this message translates to:
  /// **'Your Remark'**
  String get yourRemark;

  /// No description provided for @enterYourRemark.
  ///
  /// In en, this message translates to:
  /// **'Enter your remark here...'**
  String get enterYourRemark;

  /// No description provided for @pleaseProvideARemark.
  ///
  /// In en, this message translates to:
  /// **'Please provide a remark'**
  String get pleaseProvideARemark;

  /// No description provided for @acknowledgmentWillMoveRequestToApprovalWorkflow.
  ///
  /// In en, this message translates to:
  /// **'By acknowledging, this request will proceed to the approval workflow.'**
  String get acknowledgmentWillMoveRequestToApprovalWorkflow;

  /// No description provided for @acknowledge.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge'**
  String get acknowledge;

  /// No description provided for @employeeAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Employee Acknowledged'**
  String get employeeAcknowledged;

  /// No description provided for @autoEscalated.
  ///
  /// In en, this message translates to:
  /// **'Auto-Escalated (No Response from Employee)'**
  String get autoEscalated;

  /// No description provided for @escalationDate.
  ///
  /// In en, this message translates to:
  /// **'Escalation Date'**
  String get escalationDate;

  /// No description provided for @acknowledgmentDate.
  ///
  /// In en, this message translates to:
  /// **'Acknowledgment Date'**
  String get acknowledgmentDate;

  /// No description provided for @acknowledgmentType.
  ///
  /// In en, this message translates to:
  /// **'Acknowledgment Type'**
  String get acknowledgmentType;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @acknowledgedWithRemark.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged with Remark'**
  String get acknowledgedWithRemark;

  /// No description provided for @employeeRemark.
  ///
  /// In en, this message translates to:
  /// **'Employee Remark'**
  String get employeeRemark;

  /// No description provided for @acknowledging.
  ///
  /// In en, this message translates to:
  /// **'Acknowledging...'**
  String get acknowledging;

  /// No description provided for @requestAcknowledgedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request acknowledged successfully'**
  String get requestAcknowledgedSuccessfully;

  /// No description provided for @confirmAcknowledgmentMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to acknowledge this disciplinary action request without providing a remark?'**
  String get confirmAcknowledgmentMessage;

  /// No description provided for @requiresYourAcknowledgment.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary action requires your acknowledgment'**
  String get requiresYourAcknowledgment;

  /// No description provided for @escalateToLegal.
  ///
  /// In en, this message translates to:
  /// **'Escalate to Legal'**
  String get escalateToLegal;

  /// No description provided for @legalInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Legal Investigation'**
  String get legalInvestigation;

  /// No description provided for @legalEscalationReason.
  ///
  /// In en, this message translates to:
  /// **'Legal Escalation Reason'**
  String get legalEscalationReason;

  /// No description provided for @provideEscalationReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide reason for legal escalation'**
  String get provideEscalationReason;

  /// No description provided for @uploadInvestigationPDF.
  ///
  /// In en, this message translates to:
  /// **'Upload Investigation PDF'**
  String get uploadInvestigationPDF;

  /// No description provided for @acknowledgeLegalRequest.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge Request'**
  String get acknowledgeLegalRequest;

  /// No description provided for @acknowledgeLegalRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'By acknowledging this request, you confirm that you have received it and will begin the legal investigation. This will stop reminder notifications.'**
  String get acknowledgeLegalRequestMessage;

  /// No description provided for @legalAcknowledgedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request acknowledged successfully'**
  String get legalAcknowledgedSuccessfully;

  /// No description provided for @investigationPdfRequired.
  ///
  /// In en, this message translates to:
  /// **'Investigation PDF is required'**
  String get investigationPdfRequired;

  /// No description provided for @hrFinalDecision.
  ///
  /// In en, this message translates to:
  /// **'HR Final Decision'**
  String get hrFinalDecision;

  /// No description provided for @terminateEmployee.
  ///
  /// In en, this message translates to:
  /// **'Terminate Employee'**
  String get terminateEmployee;

  /// No description provided for @enterSuspensionDays.
  ///
  /// In en, this message translates to:
  /// **'Enter number of suspension days'**
  String get enterSuspensionDays;

  /// No description provided for @closedAtHR.
  ///
  /// In en, this message translates to:
  /// **'Closed at HR'**
  String get closedAtHR;

  /// No description provided for @escalatedToLegalSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request escalated to Legal successfully'**
  String get escalatedToLegalSuccessfully;

  /// No description provided for @investigationUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Investigation uploaded successfully'**
  String get investigationUploadedSuccessfully;

  /// No description provided for @hrFinalDecisionSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'HR final decision submitted successfully'**
  String get hrFinalDecisionSubmittedSuccessfully;

  /// No description provided for @pendingLegalInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Pending Legal Investigation'**
  String get pendingLegalInvestigation;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @legalApprover.
  ///
  /// In en, this message translates to:
  /// **'Legal Approver'**
  String get legalApprover;

  /// No description provided for @investigationReport.
  ///
  /// In en, this message translates to:
  /// **'Investigation Report'**
  String get investigationReport;

  /// No description provided for @viewInvestigationReport.
  ///
  /// In en, this message translates to:
  /// **'View Investigation Report'**
  String get viewInvestigationReport;

  /// No description provided for @suspendedFor.
  ///
  /// In en, this message translates to:
  /// **'Suspended for'**
  String get suspendedFor;

  /// No description provided for @terminationRecommended.
  ///
  /// In en, this message translates to:
  /// **'Termination Recommended'**
  String get terminationRecommended;

  /// No description provided for @suspensionPeriod.
  ///
  /// In en, this message translates to:
  /// **'Suspension Period'**
  String get suspensionPeriod;

  /// No description provided for @suspensionStartDate.
  ///
  /// In en, this message translates to:
  /// **'Suspension Start Date'**
  String get suspensionStartDate;

  /// No description provided for @suspensionEndDate.
  ///
  /// In en, this message translates to:
  /// **'Suspension End Date'**
  String get suspensionEndDate;

  /// No description provided for @escalatingToLegal.
  ///
  /// In en, this message translates to:
  /// **'Escalating to Legal...'**
  String get escalatingToLegal;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @approveFinal.
  ///
  /// In en, this message translates to:
  /// **'Approve Final'**
  String get approveFinal;

  /// No description provided for @declineFinal.
  ///
  /// In en, this message translates to:
  /// **'Decline Final'**
  String get declineFinal;

  /// No description provided for @pleaseSelectPdfFile.
  ///
  /// In en, this message translates to:
  /// **'Please select a PDF file to upload'**
  String get pleaseSelectPdfFile;

  /// No description provided for @investigationPdfUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Investigation PDF uploaded successfully'**
  String get investigationPdfUploadedSuccessfully;

  /// No description provided for @suspensionDaysRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter suspension days'**
  String get suspensionDaysRequired;

  /// No description provided for @suspensionDaysMustBePositive.
  ///
  /// In en, this message translates to:
  /// **'Suspension days must be greater than 0'**
  String get suspensionDaysMustBePositive;

  /// No description provided for @confirmTermination.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to terminate this employee? This action is irreversible.'**
  String get confirmTermination;

  /// No description provided for @submittingFinalDecision.
  ///
  /// In en, this message translates to:
  /// **'Submitting final decision...'**
  String get submittingFinalDecision;

  /// No description provided for @legalInvestigationComplete.
  ///
  /// In en, this message translates to:
  /// **'Legal Investigation Complete'**
  String get legalInvestigationComplete;

  /// No description provided for @makeHRFinalDecision.
  ///
  /// In en, this message translates to:
  /// **'Make HR Final Decision'**
  String get makeHRFinalDecision;

  /// No description provided for @n2SendingForInvestigationReason.
  ///
  /// In en, this message translates to:
  /// **'(N+2) has sent request for HR investigation for the following reason'**
  String get n2SendingForInvestigationReason;

  /// No description provided for @attachDocuments.
  ///
  /// In en, this message translates to:
  /// **'Attach Documents'**
  String get attachDocuments;

  /// No description provided for @uploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Upload Documents'**
  String get uploadDocuments;

  /// No description provided for @removeDocument.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeDocument;

  /// No description provided for @supportedFormats.
  ///
  /// In en, this message translates to:
  /// **'Supported formats: PDF, JPG, PNG, DOC, DOCX'**
  String get supportedFormats;

  /// No description provided for @maxFilesReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum 5 files allowed'**
  String get maxFilesReached;

  /// No description provided for @fileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'File size exceeds 10MB limit'**
  String get fileTooLarge;

  /// No description provided for @documentsAttached.
  ///
  /// In en, this message translates to:
  /// **'{count} document(s) attached'**
  String documentsAttached(int count);

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @viewAttachment.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewAttachment;

  /// No description provided for @loadingAttachments.
  ///
  /// In en, this message translates to:
  /// **'Loading attachments...'**
  String get loadingAttachments;

  /// No description provided for @noAttachments.
  ///
  /// In en, this message translates to:
  /// **'No attachments'**
  String get noAttachments;

  /// No description provided for @openAttachmentFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to open attachment'**
  String get openAttachmentFailed;

  /// No description provided for @violationCategory.
  ///
  /// In en, this message translates to:
  /// **'Violation Category'**
  String get violationCategory;

  /// No description provided for @selectViolationCategory.
  ///
  /// In en, this message translates to:
  /// **'Select violation category'**
  String get selectViolationCategory;

  /// No description provided for @violation.
  ///
  /// In en, this message translates to:
  /// **'Violation'**
  String get violation;

  /// No description provided for @selectViolation.
  ///
  /// In en, this message translates to:
  /// **'Select violation'**
  String get selectViolation;

  /// No description provided for @violationDescription.
  ///
  /// In en, this message translates to:
  /// **'Violation Description'**
  String get violationDescription;

  /// No description provided for @describeViolation.
  ///
  /// In en, this message translates to:
  /// **'Describe the violation in detail'**
  String get describeViolation;

  /// No description provided for @selectCategoryFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select a category first'**
  String get selectCategoryFirst;

  /// No description provided for @categoryAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get categoryAttendance;

  /// No description provided for @categoryConduct.
  ///
  /// In en, this message translates to:
  /// **'Conduct'**
  String get categoryConduct;

  /// No description provided for @categoryPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get categoryPerformance;

  /// No description provided for @categorySafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get categorySafety;

  /// No description provided for @categoryPolicy.
  ///
  /// In en, this message translates to:
  /// **'Policy'**
  String get categoryPolicy;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @pleaseSelectViolationCategory.
  ///
  /// In en, this message translates to:
  /// **'Please select a violation category'**
  String get pleaseSelectViolationCategory;

  /// No description provided for @pleaseSelectViolation.
  ///
  /// In en, this message translates to:
  /// **'Please select a violation'**
  String get pleaseSelectViolation;

  /// No description provided for @pleaseDescribeViolation.
  ///
  /// In en, this message translates to:
  /// **'Please describe the violation'**
  String get pleaseDescribeViolation;

  /// No description provided for @violationDescriptionTooShort.
  ///
  /// In en, this message translates to:
  /// **'Violation description must be at least 10 characters'**
  String get violationDescriptionTooShort;

  /// No description provided for @settlementReview.
  ///
  /// In en, this message translates to:
  /// **'Settlement Review'**
  String get settlementReview;

  /// No description provided for @settlementReviewRequests.
  ///
  /// In en, this message translates to:
  /// **'Settlement Notifications'**
  String get settlementReviewRequests;

  /// No description provided for @sendNotification.
  ///
  /// In en, this message translates to:
  /// **'Send Notification'**
  String get sendNotification;

  /// No description provided for @sendAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Send All'**
  String get sendAllNotifications;

  /// No description provided for @noSettlementReviewRequests.
  ///
  /// In en, this message translates to:
  /// **'No settlement notifications pending'**
  String get noSettlementReviewRequests;

  /// No description provided for @settlementNotificationSent.
  ///
  /// In en, this message translates to:
  /// **'Settlement notification sent successfully'**
  String get settlementNotificationSent;

  /// No description provided for @allNotificationsSent.
  ///
  /// In en, this message translates to:
  /// **'All settlement notifications sent successfully'**
  String get allNotificationsSent;

  /// No description provided for @skipNotification.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipNotification;

  /// No description provided for @notificationSkipped.
  ///
  /// In en, this message translates to:
  /// **'Notification skipped'**
  String get notificationSkipped;

  /// No description provided for @reviewPdf.
  ///
  /// In en, this message translates to:
  /// **'Review PDF'**
  String get reviewPdf;

  /// No description provided for @confirmSendAll.
  ///
  /// In en, this message translates to:
  /// **'Confirm Send All'**
  String get confirmSendAll;

  /// No description provided for @confirmSendAllNotifications.
  ///
  /// In en, this message translates to:
  /// **'Send {count} settlement notifications?'**
  String confirmSendAllNotifications(Object count);

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @readyForReview.
  ///
  /// In en, this message translates to:
  /// **'Ready for Review'**
  String get readyForReview;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @recordDecision.
  ///
  /// In en, this message translates to:
  /// **'Record Decision'**
  String get recordDecision;

  /// No description provided for @hrDecision.
  ///
  /// In en, this message translates to:
  /// **'HR Decision'**
  String get hrDecision;

  /// No description provided for @legalReview.
  ///
  /// In en, this message translates to:
  /// **'Legal Review'**
  String get legalReview;

  /// No description provided for @topManagementDecision.
  ///
  /// In en, this message translates to:
  /// **'Top Management Decision'**
  String get topManagementDecision;

  /// No description provided for @decisionHistory.
  ///
  /// In en, this message translates to:
  /// **'Decision History'**
  String get decisionHistory;

  /// No description provided for @linkedActions.
  ///
  /// In en, this message translates to:
  /// **'Linked Disciplinary Actions'**
  String get linkedActions;

  /// No description provided for @takeAction.
  ///
  /// In en, this message translates to:
  /// **'Take Disciplinary Action'**
  String get takeAction;

  /// No description provided for @noAction.
  ///
  /// In en, this message translates to:
  /// **'No Action'**
  String get noAction;

  /// No description provided for @suspend.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get suspend;

  /// No description provided for @terminate.
  ///
  /// In en, this message translates to:
  /// **'Terminate'**
  String get terminate;

  /// No description provided for @confirmDecision.
  ///
  /// In en, this message translates to:
  /// **'Confirm Decision'**
  String get confirmDecision;

  /// No description provided for @convertToDisciplinary.
  ///
  /// In en, this message translates to:
  /// **'Convert to Disciplinary Action'**
  String get convertToDisciplinary;

  /// No description provided for @decisionSummary.
  ///
  /// In en, this message translates to:
  /// **'Decision Summary'**
  String get decisionSummary;

  /// No description provided for @decidedBy.
  ///
  /// In en, this message translates to:
  /// **'Decided By'**
  String get decidedBy;

  /// No description provided for @decidedAt.
  ///
  /// In en, this message translates to:
  /// **'Decided At'**
  String get decidedAt;

  /// No description provided for @reviewedBy.
  ///
  /// In en, this message translates to:
  /// **'Reviewed By'**
  String get reviewedBy;

  /// No description provided for @employeeDecisions.
  ///
  /// In en, this message translates to:
  /// **'Employee Decisions'**
  String get employeeDecisions;

  /// No description provided for @legalOpinion.
  ///
  /// In en, this message translates to:
  /// **'Legal Opinion'**
  String get legalOpinion;

  /// No description provided for @createActions.
  ///
  /// In en, this message translates to:
  /// **'Create Disciplinary Actions'**
  String get createActions;

  /// No description provided for @bulkCreation.
  ///
  /// In en, this message translates to:
  /// **'Bulk Creation'**
  String get bulkCreation;

  /// No description provided for @createdFromInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Created from Investigation'**
  String get createdFromInvestigation;

  /// No description provided for @convertedFromDisciplinary.
  ///
  /// In en, this message translates to:
  /// **'Converted from Disciplinary Action'**
  String get convertedFromDisciplinary;

  /// No description provided for @viewInvestigation.
  ///
  /// In en, this message translates to:
  /// **'View Investigation'**
  String get viewInvestigation;

  /// No description provided for @loadingEmployeeDetails.
  ///
  /// In en, this message translates to:
  /// **'Loading employee details...'**
  String get loadingEmployeeDetails;

  /// No description provided for @unknownEmployee.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownEmployee;

  /// No description provided for @finalDecision.
  ///
  /// In en, this message translates to:
  /// **'Final Decision'**
  String get finalDecision;

  /// No description provided for @uploadDecisionPdf.
  ///
  /// In en, this message translates to:
  /// **'Upload Decision PDF'**
  String get uploadDecisionPdf;

  /// No description provided for @legalPdfRequired.
  ///
  /// In en, this message translates to:
  /// **'Legal PDF is required to submit review'**
  String get legalPdfRequired;

  /// No description provided for @fromInvestigation.
  ///
  /// In en, this message translates to:
  /// **'From Investigation'**
  String get fromInvestigation;

  /// No description provided for @convertToInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Convert to Investigation'**
  String get convertToInvestigation;

  /// No description provided for @hrFinalDecisionAfterLegal.
  ///
  /// In en, this message translates to:
  /// **'HR Final Decision (After Legal Review)'**
  String get hrFinalDecisionAfterLegal;

  /// No description provided for @invalidApproverType.
  ///
  /// In en, this message translates to:
  /// **'Invalid approver type'**
  String get invalidApproverType;

  /// No description provided for @basicInformation.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInformation;

  /// No description provided for @hrDecisions.
  ///
  /// In en, this message translates to:
  /// **'HR Decisions'**
  String get hrDecisions;

  /// No description provided for @topManagementDecisions.
  ///
  /// In en, this message translates to:
  /// **'Top Management Decisions'**
  String get topManagementDecisions;

  /// No description provided for @linkedDisciplinaryActions.
  ///
  /// In en, this message translates to:
  /// **'Linked Disciplinary Actions'**
  String get linkedDisciplinaryActions;

  /// No description provided for @employeeName.
  ///
  /// In en, this message translates to:
  /// **'Employee Name'**
  String get employeeName;

  /// No description provided for @uploaded.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get uploaded;

  /// No description provided for @escalatedFromDisciplinaryAction.
  ///
  /// In en, this message translates to:
  /// **'Escalated from Disciplinary Action #{id}'**
  String escalatedFromDisciplinaryAction(Object id);

  /// No description provided for @createDisciplinaryActions.
  ///
  /// In en, this message translates to:
  /// **'Create Disciplinary Actions'**
  String get createDisciplinaryActions;

  /// No description provided for @backToDetails.
  ///
  /// In en, this message translates to:
  /// **'Back to Details'**
  String get backToDetails;

  /// No description provided for @continueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// No description provided for @submitAll.
  ///
  /// In en, this message translates to:
  /// **'Submit All ({count} actions)'**
  String submitAll(Object count);

  /// No description provided for @acknowledgeInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge Investigation'**
  String get acknowledgeInvestigation;

  /// No description provided for @uploadLegalPdf.
  ///
  /// In en, this message translates to:
  /// **'Upload Legal PDF'**
  String get uploadLegalPdf;

  /// No description provided for @cleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get cleared;

  /// No description provided for @verbalWarning.
  ///
  /// In en, this message translates to:
  /// **'Verbal Warning'**
  String get verbalWarning;

  /// No description provided for @suspension.
  ///
  /// In en, this message translates to:
  /// **'Suspension'**
  String get suspension;

  /// No description provided for @termination.
  ///
  /// In en, this message translates to:
  /// **'Termination'**
  String get termination;

  /// No description provided for @disciplinaryActionRequired.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary Action Required'**
  String get disciplinaryActionRequired;

  /// No description provided for @pleaseSelectDecisionForAll.
  ///
  /// In en, this message translates to:
  /// **'Please make a decision for all employees'**
  String get pleaseSelectDecisionForAll;

  /// No description provided for @escalateToLegalDepartment.
  ///
  /// In en, this message translates to:
  /// **'Escalate to Legal Department'**
  String get escalateToLegalDepartment;

  /// No description provided for @escalationReason.
  ///
  /// In en, this message translates to:
  /// **'Escalation Reason'**
  String get escalationReason;

  /// No description provided for @provideReasonForEscalation.
  ///
  /// In en, this message translates to:
  /// **'Provide reason for legal escalation...'**
  String get provideReasonForEscalation;

  /// No description provided for @pleaseProvideEscalationReason.
  ///
  /// In en, this message translates to:
  /// **'Please provide a reason for escalation'**
  String get pleaseProvideEscalationReason;

  /// No description provided for @investigationEscalatedToLegal.
  ///
  /// In en, this message translates to:
  /// **'Investigation #{id} escalated to Legal Department'**
  String investigationEscalatedToLegal(Object id);

  /// No description provided for @acknowledgeInvestigationMessage.
  ///
  /// In en, this message translates to:
  /// **'This will stop email reminders for this investigation. The investigation will remain assigned to Legal until you upload the investigation PDF.'**
  String get acknowledgeInvestigationMessage;

  /// No description provided for @acknowledgeInvestigationNote.
  ///
  /// In en, this message translates to:
  /// **'Note: You must upload the investigation PDF to return this case to HR.'**
  String get acknowledgeInvestigationNote;

  /// No description provided for @investigationAcknowledged.
  ///
  /// In en, this message translates to:
  /// **'Investigation #{id} acknowledged. Email reminders stopped.'**
  String investigationAcknowledged(Object id);

  /// No description provided for @uploadLegalPdfTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload Legal PDF'**
  String get uploadLegalPdfTitle;

  /// No description provided for @uploadPdfConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Upload this PDF for Investigation #{id}?'**
  String uploadPdfConfirmation(Object id);

  /// No description provided for @afterUploadingReturnToHr.
  ///
  /// In en, this message translates to:
  /// **'After uploading, this investigation will be returned to HR.'**
  String get afterUploadingReturnToHr;

  /// No description provided for @pdfUploadedReturnedToHr.
  ///
  /// In en, this message translates to:
  /// **'PDF uploaded. Investigation #{id} returned to HR.'**
  String pdfUploadedReturnedToHr(Object id);

  /// No description provided for @errorCouldNotReadFile.
  ///
  /// In en, this message translates to:
  /// **'Error: Could not read file'**
  String get errorCouldNotReadFile;

  /// No description provided for @escalatedOn.
  ///
  /// In en, this message translates to:
  /// **'Escalated on: {date}'**
  String escalatedOn(Object date);

  /// No description provided for @acknowledgedByLegal.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged by Legal'**
  String get acknowledgedByLegal;

  /// No description provided for @pendingAcknowledgment.
  ///
  /// In en, this message translates to:
  /// **'Pending acknowledgment'**
  String get pendingAcknowledgment;

  /// No description provided for @viewInvestigationReportPdf.
  ///
  /// In en, this message translates to:
  /// **'View Investigation Report (PDF)'**
  String get viewInvestigationReportPdf;

  /// No description provided for @viewLegalInvestigationReportPdf.
  ///
  /// In en, this message translates to:
  /// **'View Legal Investigation Report (PDF)'**
  String get viewLegalInvestigationReportPdf;

  /// No description provided for @pdfOpeningNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'PDF opening functionality will be implemented soon'**
  String get pdfOpeningNotImplemented;

  /// No description provided for @daNumber.
  ///
  /// In en, this message translates to:
  /// **'DA #{id}'**
  String daNumber(Object id);

  /// No description provided for @decision.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get decision;

  /// No description provided for @autoEscalateWarning.
  ///
  /// In en, this message translates to:
  /// **'Suspend or Terminate decisions will automatically escalate to Top Management for review'**
  String get autoEscalateWarning;

  /// No description provided for @investigationNumber.
  ///
  /// In en, this message translates to:
  /// **'Investigation #{id}'**
  String investigationNumber(Object id);

  /// No description provided for @legalReviewCompleted.
  ///
  /// In en, this message translates to:
  /// **'Legal Review Completed'**
  String get legalReviewCompleted;

  /// No description provided for @legalReviewCompletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Legal has reviewed this investigation. You can now make final decisions.'**
  String get legalReviewCompletedMessage;

  /// No description provided for @viewLegalPdf.
  ///
  /// In en, this message translates to:
  /// **'View Legal PDF'**
  String get viewLegalPdf;

  /// No description provided for @bulkCreationInstruction.
  ///
  /// In en, this message translates to:
  /// **'Select the disciplinary action type for each employee. Violation details will be copied from the investigation.'**
  String get bulkCreationInstruction;

  /// No description provided for @employeeActionTypes.
  ///
  /// In en, this message translates to:
  /// **'Employee Action Types'**
  String get employeeActionTypes;

  /// No description provided for @attachmentsOptional.
  ///
  /// In en, this message translates to:
  /// **'Attachments (Optional)'**
  String get attachmentsOptional;

  /// No description provided for @attachmentsWillBeAddedToAll.
  ///
  /// In en, this message translates to:
  /// **'These attachments will be added to all created disciplinary actions'**
  String get attachmentsWillBeAddedToAll;

  /// No description provided for @creatingActionsFromInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Creating {count} disciplinary {actions} from Investigation #{id}'**
  String creatingActionsFromInvestigation(
    Object actions,
    Object count,
    Object id,
  );

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'actions'**
  String get actions;

  /// No description provided for @enterLegalOpinion.
  ///
  /// In en, this message translates to:
  /// **'Enter your legal opinion and recommendations...'**
  String get enterLegalOpinion;

  /// No description provided for @legalOpinionRequired.
  ///
  /// In en, this message translates to:
  /// **'Legal opinion is required'**
  String get legalOpinionRequired;

  /// No description provided for @legalDocument.
  ///
  /// In en, this message translates to:
  /// **'Legal Document'**
  String get legalDocument;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'REQUIRED'**
  String get required;

  /// No description provided for @legalPdfMandatory.
  ///
  /// In en, this message translates to:
  /// **'* Legal PDF is mandatory to complete review'**
  String get legalPdfMandatory;

  /// No description provided for @reviewHrDecisions.
  ///
  /// In en, this message translates to:
  /// **'Review the decisions made by HR for each employee'**
  String get reviewHrDecisions;

  /// No description provided for @afterSubmittingReturnedToHr.
  ///
  /// In en, this message translates to:
  /// **'After Legal Review, this investigation will be returned to HR for final decisions'**
  String get afterSubmittingReturnedToHr;

  /// No description provided for @submitLegalReview.
  ///
  /// In en, this message translates to:
  /// **'Submit Legal Review'**
  String get submitLegalReview;

  /// No description provided for @hrDecisionsReadOnly.
  ///
  /// In en, this message translates to:
  /// **'HR Decisions'**
  String get hrDecisionsReadOnly;

  /// No description provided for @legalReviewSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Legal review submitted successfully'**
  String get legalReviewSubmittedSuccess;

  /// No description provided for @errorSubmittingReview.
  ///
  /// In en, this message translates to:
  /// **'Error submitting legal review'**
  String get errorSubmittingReview;

  /// No description provided for @reviewSuspendTerminateDecisions.
  ///
  /// In en, this message translates to:
  /// **'Review employees with Suspend or Terminate decisions'**
  String get reviewSuspendTerminateDecisions;

  /// No description provided for @employeesRequireReview.
  ///
  /// In en, this message translates to:
  /// **'{count} employees require review'**
  String employeesRequireReview(Object count);

  /// No description provided for @noEmployeesRequireTmReview.
  ///
  /// In en, this message translates to:
  /// **'No employees require Top Management review'**
  String get noEmployeesRequireTmReview;

  /// No description provided for @tmDecision.
  ///
  /// In en, this message translates to:
  /// **'TM Decision'**
  String get tmDecision;

  /// No description provided for @convertToDisciplinaryAction.
  ///
  /// In en, this message translates to:
  /// **'Convert to Disciplinary Action'**
  String get convertToDisciplinaryAction;

  /// No description provided for @originalHrDecision.
  ///
  /// In en, this message translates to:
  /// **'Original HR Decision'**
  String get originalHrDecision;

  /// No description provided for @tmDecisionOptional.
  ///
  /// In en, this message translates to:
  /// **'Top Management Decision (Optional PDF)'**
  String get tmDecisionOptional;

  /// No description provided for @uploadTmPdf.
  ///
  /// In en, this message translates to:
  /// **'Upload TM Decision PDF'**
  String get uploadTmPdf;

  /// No description provided for @uploadPdfOptional.
  ///
  /// In en, this message translates to:
  /// **'Upload PDF (Optional)'**
  String get uploadPdfOptional;

  /// No description provided for @selectPdf.
  ///
  /// In en, this message translates to:
  /// **'Select PDF'**
  String get selectPdf;

  /// No description provided for @noFileSelected.
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get noFileSelected;

  /// No description provided for @submitTmDecision.
  ///
  /// In en, this message translates to:
  /// **'Submit TM Decision'**
  String get submitTmDecision;

  /// No description provided for @tmDecisionSubmittedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Top Management decision submitted successfully'**
  String get tmDecisionSubmittedSuccess;

  /// No description provided for @hrDecisionWillBeExecuted.
  ///
  /// In en, this message translates to:
  /// **'HR decision will be executed as proposed'**
  String get hrDecisionWillBeExecuted;

  /// No description provided for @reasonMinimum25.
  ///
  /// In en, this message translates to:
  /// **'Reason must be at least 25 characters'**
  String get reasonMinimum25;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @uploadDecisionPdfOptional.
  ///
  /// In en, this message translates to:
  /// **'Upload Decision PDF (Optional)'**
  String get uploadDecisionPdfOptional;

  /// No description provided for @choosePdfFiles.
  ///
  /// In en, this message translates to:
  /// **'Choose PDF Files'**
  String get choosePdfFiles;

  /// No description provided for @filesSelected.
  ///
  /// In en, this message translates to:
  /// **'file(s) selected'**
  String get filesSelected;

  /// No description provided for @addAttachments.
  ///
  /// In en, this message translates to:
  /// **'Add Attachments'**
  String get addAttachments;

  /// No description provided for @chooseLegalPdfRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose Legal PDF'**
  String get chooseLegalPdfRequired;

  /// No description provided for @legalReviewRecordedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Legal review recorded successfully. Case returned to HR.'**
  String get legalReviewRecordedSuccess;

  /// No description provided for @submitFinalDecision.
  ///
  /// In en, this message translates to:
  /// **'Submit Final Decision'**
  String get submitFinalDecision;

  /// No description provided for @legalHasReviewedInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Legal has reviewed this investigation and provided documentation'**
  String get legalHasReviewedInvestigation;

  /// No description provided for @converted.
  ///
  /// In en, this message translates to:
  /// **'Converted'**
  String get converted;

  /// No description provided for @finalDecisionWarning.
  ///
  /// In en, this message translates to:
  /// **'This is the final decision. Investigation will be closed after submission.'**
  String get finalDecisionWarning;

  /// No description provided for @duplicateFileSkipped.
  ///
  /// In en, this message translates to:
  /// **'{fileName} was skipped (duplicate)'**
  String duplicateFileSkipped(Object fileName);

  /// No description provided for @daConvertedToInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary Action Request converted to Investigation'**
  String get daConvertedToInvestigation;

  /// No description provided for @convertedToInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Converted to Investigation'**
  String get convertedToInvestigation;

  /// No description provided for @convertToInvestigationDescription.
  ///
  /// In en, this message translates to:
  /// **'This will convert the disciplinary action into a formal investigation request.'**
  String get convertToInvestigationDescription;

  /// No description provided for @whatHappensNext.
  ///
  /// In en, this message translates to:
  /// **'What happens next:'**
  String get whatHappensNext;

  /// No description provided for @investigationRequestWillBeCreated.
  ///
  /// In en, this message translates to:
  /// **'Investigation request will be created'**
  String get investigationRequestWillBeCreated;

  /// No description provided for @originalDaWillBeLinked.
  ///
  /// In en, this message translates to:
  /// **'Original disciplinary action will be linked'**
  String get originalDaWillBeLinked;

  /// No description provided for @investigationFollowsFormalProcess.
  ///
  /// In en, this message translates to:
  /// **'Investigation follows formal review process'**
  String get investigationFollowsFormalProcess;

  /// No description provided for @hrLegalTopManagement.
  ///
  /// In en, this message translates to:
  /// **'HR → Legal (if needed) → Top Management'**
  String get hrLegalTopManagement;

  /// No description provided for @convertToInvestigationConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to convert this to an investigation?'**
  String get convertToInvestigationConfirmation;

  /// No description provided for @uploadInvestigationPdfOptional.
  ///
  /// In en, this message translates to:
  /// **'Upload Investigation PDF (Optional)'**
  String get uploadInvestigationPdfOptional;

  /// No description provided for @fileSelected.
  ///
  /// In en, this message translates to:
  /// **'File Selected'**
  String get fileSelected;

  /// No description provided for @choosePdfFile.
  ///
  /// In en, this message translates to:
  /// **'Choose PDF File'**
  String get choosePdfFile;

  /// No description provided for @pdfFilesOnlyMax10mb.
  ///
  /// In en, this message translates to:
  /// **'PDF files only, max 10MB'**
  String get pdfFilesOnlyMax10mb;

  /// No description provided for @invalidFilePdfUnder10mb.
  ///
  /// In en, this message translates to:
  /// **'Invalid file. Please upload a valid PDF file under 10MB.'**
  String get invalidFilePdfUnder10mb;

  /// No description provided for @errorSelectingFile.
  ///
  /// In en, this message translates to:
  /// **'Error selecting file: {error}'**
  String errorSelectingFile(String error);

  /// No description provided for @viewButton.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewButton;

  /// No description provided for @failedToLoadInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Failed to load investigation: {error}'**
  String failedToLoadInvestigation(String error);

  /// No description provided for @legalEscalation.
  ///
  /// In en, this message translates to:
  /// **'Legal Escalation'**
  String get legalEscalation;

  /// No description provided for @completionDate.
  ///
  /// In en, this message translates to:
  /// **'Completion Date'**
  String get completionDate;

  /// No description provided for @changeLog.
  ///
  /// In en, this message translates to:
  /// **'Change Log'**
  String get changeLog;

  /// No description provided for @hrInvestigationPdf.
  ///
  /// In en, this message translates to:
  /// **'HR Investigation PDF'**
  String get hrInvestigationPdf;

  /// No description provided for @investigationPdfDocument.
  ///
  /// In en, this message translates to:
  /// **'Investigation PDF Document'**
  String get investigationPdfDocument;

  /// No description provided for @uploadedDate.
  ///
  /// In en, this message translates to:
  /// **'Uploaded: {date}'**
  String uploadedDate(String date);

  /// No description provided for @legalInvestigationPdf.
  ///
  /// In en, this message translates to:
  /// **'Legal Investigation PDF'**
  String get legalInvestigationPdf;

  /// No description provided for @legalInvestigationPdfDocument.
  ///
  /// In en, this message translates to:
  /// **'Legal Investigation PDF Document'**
  String get legalInvestigationPdfDocument;

  /// No description provided for @finalApproval.
  ///
  /// In en, this message translates to:
  /// **'Final Approval'**
  String get finalApproval;

  /// No description provided for @finalDecline.
  ///
  /// In en, this message translates to:
  /// **'Final Decline'**
  String get finalDecline;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get endDate;

  /// No description provided for @terminationRecommendedDate.
  ///
  /// In en, this message translates to:
  /// **'Termination Recommended Date'**
  String get terminationRecommendedDate;

  /// No description provided for @bulkEmployeeUpload.
  ///
  /// In en, this message translates to:
  /// **'Bulk Employee Upload'**
  String get bulkEmployeeUpload;

  /// No description provided for @instructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructions;

  /// No description provided for @downloadTemplateInstruction.
  ///
  /// In en, this message translates to:
  /// **'Download the CSV or Excel template'**
  String get downloadTemplateInstruction;

  /// No description provided for @fillEmployeeDataInstruction.
  ///
  /// In en, this message translates to:
  /// **'Fill in employee data'**
  String get fillEmployeeDataInstruction;

  /// No description provided for @uploadFileInstruction.
  ///
  /// In en, this message translates to:
  /// **'Upload the completed file'**
  String get uploadFileInstruction;

  /// No description provided for @reviewAndFixErrorsInstruction.
  ///
  /// In en, this message translates to:
  /// **'Review and fix any validation errors'**
  String get reviewAndFixErrorsInstruction;

  /// No description provided for @submitToAddEmployeesInstruction.
  ///
  /// In en, this message translates to:
  /// **'Click Submit to add employees'**
  String get submitToAddEmployeesInstruction;

  /// No description provided for @downloadCsvTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download CSV Template'**
  String get downloadCsvTemplate;

  /// No description provided for @downloadExcelTemplate.
  ///
  /// In en, this message translates to:
  /// **'Download Excel Template'**
  String get downloadExcelTemplate;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get uploadFile;

  /// No description provided for @parsingFile.
  ///
  /// In en, this message translates to:
  /// **'Parsing file...'**
  String get parsingFile;

  /// No description provided for @validatingData.
  ///
  /// In en, this message translates to:
  /// **'Validating data...'**
  String get validatingData;

  /// No description provided for @totalEmployees.
  ///
  /// In en, this message translates to:
  /// **'Total Employees'**
  String get totalEmployees;

  /// No description provided for @valid.
  ///
  /// In en, this message translates to:
  /// **'Valid'**
  String get valid;

  /// No description provided for @withErrors.
  ///
  /// In en, this message translates to:
  /// **'With Errors'**
  String get withErrors;

  /// No description provided for @invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalid;

  /// No description provided for @reviewData.
  ///
  /// In en, this message translates to:
  /// **'Review Data'**
  String get reviewData;

  /// No description provided for @revalidate.
  ///
  /// In en, this message translates to:
  /// **'Revalidate'**
  String get revalidate;

  /// No description provided for @clickOnRedCellsToFix.
  ///
  /// In en, this message translates to:
  /// **'Click on red cells to fix errors'**
  String get clickOnRedCellsToFix;

  /// No description provided for @n1Code.
  ///
  /// In en, this message translates to:
  /// **'N+1 Code'**
  String get n1Code;

  /// No description provided for @uploadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading: {current}/{total} employees'**
  String uploadingProgress(int current, int total);

  /// No description provided for @submitEmployees.
  ///
  /// In en, this message translates to:
  /// **'Submit ({count} employees)'**
  String submitEmployees(int count);

  /// No description provided for @fixErrorsToSubmit.
  ///
  /// In en, this message translates to:
  /// **'Fix all errors to enable submit'**
  String get fixErrorsToSubmit;

  /// No description provided for @uploadComplete.
  ///
  /// In en, this message translates to:
  /// **'Upload Complete'**
  String get uploadComplete;

  /// No description provided for @partialUploadComplete.
  ///
  /// In en, this message translates to:
  /// **'Partial Upload Complete'**
  String get partialUploadComplete;

  /// No description provided for @succeeded.
  ///
  /// In en, this message translates to:
  /// **'Succeeded'**
  String get succeeded;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @failedEmployeesList.
  ///
  /// In en, this message translates to:
  /// **'Failed Employees:'**
  String get failedEmployeesList;

  /// No description provided for @retryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry Failed'**
  String get retryFailed;

  /// No description provided for @confirmUpload.
  ///
  /// In en, this message translates to:
  /// **'Confirm Upload'**
  String get confirmUpload;

  /// No description provided for @confirmUploadMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to add {count} employees?'**
  String confirmUploadMessage(int count);

  /// No description provided for @templateSavedTo.
  ///
  /// In en, this message translates to:
  /// **'Template saved to: {path}'**
  String templateSavedTo(String path);

  /// No description provided for @employeesAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{count} employees added successfully'**
  String employeesAddedSuccessfully(int count);

  /// No description provided for @employeeGroups.
  ///
  /// In en, this message translates to:
  /// **'Employee Groups'**
  String get employeeGroups;

  /// No description provided for @manageGroups.
  ///
  /// In en, this message translates to:
  /// **'Manage Groups'**
  String get manageGroups;

  /// No description provided for @addMember.
  ///
  /// In en, this message translates to:
  /// **'Add Member'**
  String get addMember;

  /// No description provided for @noMembersInGroup.
  ///
  /// In en, this message translates to:
  /// **'No members in this group yet.'**
  String get noMembersInGroup;

  /// No description provided for @searchEmployeesToAdd.
  ///
  /// In en, this message translates to:
  /// **'Search employees to add...'**
  String get searchEmployeesToAdd;

  /// No description provided for @confirmRemoveMemberTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get confirmRemoveMemberTitle;

  /// No description provided for @confirmRemoveMemberMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove {name} from the {group} group?'**
  String confirmRemoveMemberMessage(String name, String group);

  /// No description provided for @reassignDirectReports.
  ///
  /// In en, this message translates to:
  /// **'Reassign Direct Reports'**
  String get reassignDirectReports;

  /// No description provided for @suspendingEmployee.
  ///
  /// In en, this message translates to:
  /// **'Suspending: {name}'**
  String suspendingEmployee(String name);

  /// No description provided for @directReportsAssignmentWarning.
  ///
  /// In en, this message translates to:
  /// **'All direct reports must be assigned a new N+1 manager before suspending.'**
  String get directReportsAssignmentWarning;

  /// No description provided for @employeesAssignedProgress.
  ///
  /// In en, this message translates to:
  /// **'{assigned} of {total} employees assigned'**
  String employeesAssignedProgress(int assigned, int total);

  /// No description provided for @assignN1ToEmployee.
  ///
  /// In en, this message translates to:
  /// **'Assign N+1 to 1 selected employee'**
  String get assignN1ToEmployee;

  /// No description provided for @assignN1ToEmployees.
  ///
  /// In en, this message translates to:
  /// **'Assign N+1 to {count} selected employees'**
  String assignN1ToEmployees(int count);

  /// No description provided for @bulkAssignN1SelectFirst.
  ///
  /// In en, this message translates to:
  /// **'Bulk Assign N+1 — select rows below first'**
  String get bulkAssignN1SelectFirst;

  /// No description provided for @selectRowsFirstToSearch.
  ///
  /// In en, this message translates to:
  /// **'Select rows first to enable search'**
  String get selectRowsFirstToSearch;

  /// No description provided for @directReportsCount.
  ///
  /// In en, this message translates to:
  /// **'Direct Reports ({count})'**
  String directReportsCount(int count);

  /// No description provided for @newN1.
  ///
  /// In en, this message translates to:
  /// **'New N+1'**
  String get newN1;

  /// No description provided for @notAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get notAssigned;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing...'**
  String get processing;

  /// No description provided for @confirmAndSuspend.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Suspend'**
  String get confirmAndSuspend;

  /// No description provided for @couldNotLoadDirectReports.
  ///
  /// In en, this message translates to:
  /// **'Could not load direct reports: {error}'**
  String couldNotLoadDirectReports(String error);

  /// No description provided for @suspensionReason.
  ///
  /// In en, this message translates to:
  /// **'Suspension Reason'**
  String get suspensionReason;

  /// No description provided for @selectSuspensionReason.
  ///
  /// In en, this message translates to:
  /// **'Select a reason'**
  String get selectSuspensionReason;

  /// No description provided for @reasonResignation.
  ///
  /// In en, this message translates to:
  /// **'Resignation'**
  String get reasonResignation;

  /// No description provided for @reasonTermination.
  ///
  /// In en, this message translates to:
  /// **'Termination'**
  String get reasonTermination;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonOther;

  /// No description provided for @lastWorkingDate.
  ///
  /// In en, this message translates to:
  /// **'Last Working Date'**
  String get lastWorkingDate;

  /// No description provided for @selectLastWorkingDate.
  ///
  /// In en, this message translates to:
  /// **'Select last working date'**
  String get selectLastWorkingDate;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @acknowledged.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged'**
  String get acknowledged;

  /// No description provided for @hrLetter.
  ///
  /// In en, this message translates to:
  /// **'HR Letter'**
  String get hrLetter;

  /// No description provided for @hrLetterRequest.
  ///
  /// In en, this message translates to:
  /// **'HR Letter Request'**
  String get hrLetterRequest;

  /// No description provided for @hrLetterRequests.
  ///
  /// In en, this message translates to:
  /// **'HR Letter Requests'**
  String get hrLetterRequests;

  /// No description provided for @myHrLetterRequests.
  ///
  /// In en, this message translates to:
  /// **'My HR Letter Requests'**
  String get myHrLetterRequests;

  /// No description provided for @teamHrLetterRequests.
  ///
  /// In en, this message translates to:
  /// **'HR Letter Requests'**
  String get teamHrLetterRequests;

  /// No description provided for @hrLetterSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'HR letter request submitted successfully'**
  String get hrLetterSubmittedSuccessfully;

  /// No description provided for @letterPurpose.
  ///
  /// In en, this message translates to:
  /// **'Letter Purpose'**
  String get letterPurpose;

  /// No description provided for @letterPurposeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get letterPurposeBank;

  /// No description provided for @letterPurposeEmbassy.
  ///
  /// In en, this message translates to:
  /// **'Embassy'**
  String get letterPurposeEmbassy;

  /// No description provided for @letterPurposeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get letterPurposeOther;

  /// No description provided for @travelFromDate.
  ///
  /// In en, this message translates to:
  /// **'Travel From Date'**
  String get travelFromDate;

  /// No description provided for @travelToDate.
  ///
  /// In en, this message translates to:
  /// **'Travel To Date'**
  String get travelToDate;

  /// No description provided for @hrLetterDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get hrLetterDetails;

  /// No description provided for @hrLetterDetailsHint.
  ///
  /// In en, this message translates to:
  /// **'Enter any additional details...'**
  String get hrLetterDetailsHint;

  /// No description provided for @hrLetterDetailsRequired.
  ///
  /// In en, this message translates to:
  /// **'Details are required when purpose is Other'**
  String get hrLetterDetailsRequired;

  /// No description provided for @hrLetterNationalIdRequired.
  ///
  /// In en, this message translates to:
  /// **'National ID is required'**
  String get hrLetterNationalIdRequired;

  /// No description provided for @hrLetterPurposeRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a letter purpose'**
  String get hrLetterPurposeRequired;

  /// No description provided for @hrLetterTravelFromRequired.
  ///
  /// In en, this message translates to:
  /// **'Travel from date is required'**
  String get hrLetterTravelFromRequired;

  /// No description provided for @hrLetterTravelToRequired.
  ///
  /// In en, this message translates to:
  /// **'Travel to date is required'**
  String get hrLetterTravelToRequired;

  /// No description provided for @hrLetterTravelToAfterFrom.
  ///
  /// In en, this message translates to:
  /// **'Travel to date must be after travel from date'**
  String get hrLetterTravelToAfterFrom;

  /// No description provided for @notEligibleForHrLetter.
  ///
  /// In en, this message translates to:
  /// **'Not Eligible for HR Letter'**
  String get notEligibleForHrLetter;

  /// No description provided for @tenureLessThanThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'You are not eligible because your tenure is less than 3 months'**
  String get tenureLessThanThreeMonths;

  /// No description provided for @acknowledgeHrLetterRequest.
  ///
  /// In en, this message translates to:
  /// **'Acknowledge Request'**
  String get acknowledgeHrLetterRequest;

  /// No description provided for @confirmAcknowledgeHrLetter.
  ///
  /// In en, this message translates to:
  /// **'Confirm Acknowledge'**
  String get confirmAcknowledgeHrLetter;

  /// No description provided for @confirmAcknowledgeHrLetterMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to acknowledge this HR letter request?'**
  String get confirmAcknowledgeHrLetterMessage;

  /// No description provided for @completeRequest.
  ///
  /// In en, this message translates to:
  /// **'Complete Request'**
  String get completeRequest;

  /// No description provided for @confirmCompleteHrLetter.
  ///
  /// In en, this message translates to:
  /// **'Confirm Complete'**
  String get confirmCompleteHrLetter;

  /// No description provided for @confirmCompleteHrLetterMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to mark this HR letter as completed and ready for collection?'**
  String get confirmCompleteHrLetterMessage;

  /// No description provided for @completing.
  ///
  /// In en, this message translates to:
  /// **'Completing...'**
  String get completing;

  /// No description provided for @requestCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Request completed successfully'**
  String get requestCompletedSuccessfully;

  /// No description provided for @hrLetterReadyForCollection.
  ///
  /// In en, this message translates to:
  /// **'HR Letter is ready for collection'**
  String get hrLetterReadyForCollection;

  /// No description provided for @searchByNameOrNationalId.
  ///
  /// In en, this message translates to:
  /// **'Search by name, code or national ID'**
  String get searchByNameOrNationalId;

  /// No description provided for @noHrLetterRequestsFound.
  ///
  /// In en, this message translates to:
  /// **'No HR letter requests found'**
  String get noHrLetterRequestsFound;

  /// No description provided for @failedToCompleteRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to complete request: {error}'**
  String failedToCompleteRequest(String error);

  /// No description provided for @failedToAcknowledgeHrLetterRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to acknowledge request: {error}'**
  String failedToAcknowledgeHrLetterRequest(String error);

  /// No description provided for @failedToCancelHrLetterRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel request: {error}'**
  String failedToCancelHrLetterRequest(String error);

  /// No description provided for @failedToDeclineHrLetterRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to decline request: {error}'**
  String failedToDeclineHrLetterRequest(String error);

  /// No description provided for @lastActionAt.
  ///
  /// In en, this message translates to:
  /// **'Last Updated'**
  String get lastActionAt;

  /// No description provided for @acknowledgedAt.
  ///
  /// In en, this message translates to:
  /// **'Acknowledged At'**
  String get acknowledgedAt;

  /// No description provided for @completedAt.
  ///
  /// In en, this message translates to:
  /// **'Completed At'**
  String get completedAt;

  /// No description provided for @declinedAt.
  ///
  /// In en, this message translates to:
  /// **'Declined At'**
  String get declinedAt;

  /// No description provided for @cancelledAt.
  ///
  /// In en, this message translates to:
  /// **'Cancelled At'**
  String get cancelledAt;

  /// No description provided for @hrHandler.
  ///
  /// In en, this message translates to:
  /// **'HR Handler'**
  String get hrHandler;

  /// No description provided for @n2ApprovalDate.
  ///
  /// In en, this message translates to:
  /// **'N+2 Approval Date'**
  String get n2ApprovalDate;

  /// No description provided for @n2ApprovalReason.
  ///
  /// In en, this message translates to:
  /// **'N+2 Approval Reason'**
  String get n2ApprovalReason;

  /// No description provided for @hrApprovalDate.
  ///
  /// In en, this message translates to:
  /// **'HR Approval Date'**
  String get hrApprovalDate;

  /// No description provided for @hrApprovalReason.
  ///
  /// In en, this message translates to:
  /// **'HR Approval Reason'**
  String get hrApprovalReason;

  /// No description provided for @legalEscalationDate.
  ///
  /// In en, this message translates to:
  /// **'Legal Escalation Date'**
  String get legalEscalationDate;

  /// No description provided for @legalCompletionDate.
  ///
  /// In en, this message translates to:
  /// **'Legal Completion Date'**
  String get legalCompletionDate;

  /// No description provided for @employeeAcknowledgmentDate.
  ///
  /// In en, this message translates to:
  /// **'Employee Acknowledgment Date'**
  String get employeeAcknowledgmentDate;

  /// No description provided for @employeeAcknowledgmentRemark.
  ///
  /// In en, this message translates to:
  /// **'Employee Acknowledgment Remark'**
  String get employeeAcknowledgmentRemark;

  /// No description provided for @employeeAcknowledgmentType.
  ///
  /// In en, this message translates to:
  /// **'Employee Acknowledgment Type'**
  String get employeeAcknowledgmentType;

  /// No description provided for @linkedInvestigation.
  ///
  /// In en, this message translates to:
  /// **'Linked Investigation'**
  String get linkedInvestigation;

  /// No description provided for @linkedDisciplinaryAction.
  ///
  /// In en, this message translates to:
  /// **'Linked Disciplinary Action'**
  String get linkedDisciplinaryAction;

  /// No description provided for @requestorDepartment.
  ///
  /// In en, this message translates to:
  /// **'Requestor Department'**
  String get requestorDepartment;

  /// No description provided for @requestorTitle.
  ///
  /// In en, this message translates to:
  /// **'Requestor Title'**
  String get requestorTitle;

  /// No description provided for @scheduleOnShift.
  ///
  /// In en, this message translates to:
  /// **'On shift'**
  String get scheduleOnShift;

  /// No description provided for @scheduleLateNoPunch.
  ///
  /// In en, this message translates to:
  /// **'Late / no punch'**
  String get scheduleLateNoPunch;

  /// No description provided for @scheduleOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get scheduleOff;

  /// No description provided for @scheduleLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading schedule...'**
  String get scheduleLoading;

  /// No description provided for @scheduleUnableToLoad.
  ///
  /// In en, this message translates to:
  /// **'Unable to load schedule'**
  String get scheduleUnableToLoad;

  /// No description provided for @scheduleCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your connection and try again'**
  String get scheduleCheckConnection;

  /// No description provided for @scheduleRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get scheduleRetry;

  /// No description provided for @schedulePageTitle.
  ///
  /// In en, this message translates to:
  /// **'Employee Schedule'**
  String get schedulePageTitle;

  /// No description provided for @scheduleStatusPublished.
  ///
  /// In en, this message translates to:
  /// **'Published'**
  String get scheduleStatusPublished;

  /// No description provided for @scheduleStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get scheduleStatusDraft;

  /// No description provided for @scheduleTabWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get scheduleTabWeekly;

  /// No description provided for @scheduleTabDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get scheduleTabDaily;

  /// No description provided for @scheduleTabMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get scheduleTabMonthly;

  /// No description provided for @scheduleTabOnShiftNow.
  ///
  /// In en, this message translates to:
  /// **'On Shift Now'**
  String get scheduleTabOnShiftNow;

  /// No description provided for @scheduleTabMySchedule.
  ///
  /// In en, this message translates to:
  /// **'My Schedule'**
  String get scheduleTabMySchedule;

  /// No description provided for @scheduleTabSwaps.
  ///
  /// In en, this message translates to:
  /// **'Swaps'**
  String get scheduleTabSwaps;

  /// No description provided for @mobileBulkAssignTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign shifts'**
  String get mobileBulkAssignTitle;

  /// No description provided for @mobileBulkStep1Shift.
  ///
  /// In en, this message translates to:
  /// **'1 · Shift'**
  String get mobileBulkStep1Shift;

  /// No description provided for @mobileBulkStep2Days.
  ///
  /// In en, this message translates to:
  /// **'2 · Days'**
  String get mobileBulkStep2Days;

  /// No description provided for @mobileBulkStep3Employees.
  ///
  /// In en, this message translates to:
  /// **'3 · Employees'**
  String get mobileBulkStep3Employees;

  /// No description provided for @mobileBulkWholeWeek.
  ///
  /// In en, this message translates to:
  /// **'Whole week'**
  String get mobileBulkWholeWeek;

  /// No description provided for @mobileBulkClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get mobileBulkClear;

  /// No description provided for @mobileBulkAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get mobileBulkAll;

  /// No description provided for @mobileBulkAssignN.
  ///
  /// In en, this message translates to:
  /// **'Assign {count} {count, plural, =1{shift} other{shifts}}'**
  String mobileBulkAssignN(int count);

  /// No description provided for @mobileBulkSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name or department…'**
  String get mobileBulkSearchHint;

  /// No description provided for @mobileBulkFillDay.
  ///
  /// In en, this message translates to:
  /// **'Fill this day'**
  String get mobileBulkFillDay;

  /// No description provided for @mobileBulkAssignDay.
  ///
  /// In en, this message translates to:
  /// **'Assign this day…'**
  String get mobileBulkAssignDay;

  /// No description provided for @mobileBulkAssignShifts.
  ///
  /// In en, this message translates to:
  /// **'Assign shifts…'**
  String get mobileBulkAssignShifts;

  /// No description provided for @mobileBulkOneShift.
  ///
  /// In en, this message translates to:
  /// **'One'**
  String get mobileBulkOneShift;

  /// No description provided for @mobileWeekHoursScheduled.
  ///
  /// In en, this message translates to:
  /// **'{hours}h scheduled'**
  String mobileWeekHoursScheduled(int hours);

  /// No description provided for @mobileThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get mobileThisWeek;

  /// No description provided for @mobileUpcoming14Days.
  ///
  /// In en, this message translates to:
  /// **'Upcoming · next 14 days'**
  String get mobileUpcoming14Days;

  /// No description provided for @mobileSwapActivity.
  ///
  /// In en, this message translates to:
  /// **'Swap activity'**
  String get mobileSwapActivity;

  /// No description provided for @mobileSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get mobileSeeAll;

  /// No description provided for @mobileDayOff.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get mobileDayOff;

  /// No description provided for @mobileOnLeave.
  ///
  /// In en, this message translates to:
  /// **'On leave'**
  String get mobileOnLeave;

  /// No description provided for @mobileApprovedTimeOff.
  ///
  /// In en, this message translates to:
  /// **'Approved time off'**
  String get mobileApprovedTimeOff;

  /// No description provided for @mobileNoShiftScheduled.
  ///
  /// In en, this message translates to:
  /// **'No shift scheduled'**
  String get mobileNoShiftScheduled;

  /// No description provided for @mobileOnShiftNow.
  ///
  /// In en, this message translates to:
  /// **'On shift'**
  String get mobileOnShiftNow;

  /// No description provided for @mobileLateNoPunch.
  ///
  /// In en, this message translates to:
  /// **'Late / no punch'**
  String get mobileLateNoPunch;

  /// No description provided for @mobileOffShift.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get mobileOffShift;

  /// No description provided for @mobileMoreTab.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get mobileMoreTab;

  /// No description provided for @mobilePublishWeek.
  ///
  /// In en, this message translates to:
  /// **'Publish week'**
  String get mobilePublishWeek;

  /// No description provided for @mobileCopyLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Copy last week'**
  String get mobileCopyLastWeek;

  /// No description provided for @mobileFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get mobileFilters;

  /// No description provided for @mobileAllTeams.
  ///
  /// In en, this message translates to:
  /// **'All teams'**
  String get mobileAllTeams;

  /// No description provided for @mobileFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get mobileFiltersTitle;

  /// No description provided for @mobileDepartment.
  ///
  /// In en, this message translates to:
  /// **'Department'**
  String get mobileDepartment;

  /// No description provided for @mobileLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get mobileLocation;

  /// No description provided for @mobileTeamScope.
  ///
  /// In en, this message translates to:
  /// **'Team scope'**
  String get mobileTeamScope;

  /// No description provided for @mobileTeamScopeAll.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get mobileTeamScopeAll;

  /// No description provided for @mobileTeamScopeDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct reports'**
  String get mobileTeamScopeDirect;

  /// No description provided for @mobileTeamScopeIndirect.
  ///
  /// In en, this message translates to:
  /// **'Indirect'**
  String get mobileTeamScopeIndirect;

  /// No description provided for @mobileFiltersReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get mobileFiltersReset;

  /// No description provided for @mobileFiltersApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get mobileFiltersApply;

  /// No description provided for @mobileShiftRequests.
  ///
  /// In en, this message translates to:
  /// **'Swap Requests'**
  String get mobileShiftRequests;

  /// No description provided for @mobilePendingAction.
  ///
  /// In en, this message translates to:
  /// **'Pending action'**
  String get mobilePendingAction;

  /// No description provided for @mobileSentByMe.
  ///
  /// In en, this message translates to:
  /// **'Sent by me'**
  String get mobileSentByMe;

  /// No description provided for @mobileSwapHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get mobileSwapHistory;

  /// No description provided for @mobileOpenRequests.
  ///
  /// In en, this message translates to:
  /// **'Open requests'**
  String get mobileOpenRequests;

  /// No description provided for @mobilePastRequests.
  ///
  /// In en, this message translates to:
  /// **'Past requests'**
  String get mobilePastRequests;

  /// No description provided for @mobileConflictWarning.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{conflict} other{conflicts}} will be created'**
  String mobileConflictWarning(int count);

  /// No description provided for @mobileStatPeople.
  ///
  /// In en, this message translates to:
  /// **'People scheduled'**
  String get mobileStatPeople;

  /// No description provided for @mobileStatShifts.
  ///
  /// In en, this message translates to:
  /// **'Shifts this week'**
  String get mobileStatShifts;

  /// No description provided for @mobileStatConflicts.
  ///
  /// In en, this message translates to:
  /// **'Conflicts'**
  String get mobileStatConflicts;

  /// No description provided for @mobileStatUnpublished.
  ///
  /// In en, this message translates to:
  /// **'Unpublished'**
  String get mobileStatUnpublished;

  /// No description provided for @mobileStatAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get mobileStatAllClear;

  /// No description provided for @mobileStatAllPublished.
  ///
  /// In en, this message translates to:
  /// **'All published'**
  String get mobileStatAllPublished;

  /// No description provided for @mobileStatOfTotal.
  ///
  /// In en, this message translates to:
  /// **'of {total} in view'**
  String mobileStatOfTotal(int total);

  /// No description provided for @mobileStatHoursTotal.
  ///
  /// In en, this message translates to:
  /// **'{hours}h total'**
  String mobileStatHoursTotal(int hours);

  /// No description provided for @mobileShiftDetailWorking.
  ///
  /// In en, this message translates to:
  /// **'Working this shift'**
  String get mobileShiftDetailWorking;

  /// No description provided for @mobileRequestSwap.
  ///
  /// In en, this message translates to:
  /// **'Request shift swap'**
  String get mobileRequestSwap;

  /// No description provided for @mobileCurrentlyOnShift.
  ///
  /// In en, this message translates to:
  /// **'Currently on shift'**
  String get mobileCurrentlyOnShift;

  /// No description provided for @mobileLateTitle.
  ///
  /// In en, this message translates to:
  /// **'Late / no punch'**
  String get mobileLateTitle;

  /// No description provided for @mobileOffTitle.
  ///
  /// In en, this message translates to:
  /// **'Off shift'**
  String get mobileOffTitle;

  /// No description provided for @scheduleCopyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy last week\'s schedule?'**
  String get scheduleCopyDialogTitle;

  /// No description provided for @scheduleCopyFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get scheduleCopyFrom;

  /// No description provided for @scheduleCopyTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get scheduleCopyTo;

  /// No description provided for @scheduleCopyShiftsToCopy.
  ///
  /// In en, this message translates to:
  /// **'Shifts to copy'**
  String get scheduleCopyShiftsToCopy;

  /// No description provided for @scheduleCopyTeamSize.
  ///
  /// In en, this message translates to:
  /// **'Team size'**
  String get scheduleCopyTeamSize;

  /// No description provided for @scheduleCopyEmployeesToCopy.
  ///
  /// In en, this message translates to:
  /// **'Employees to copy'**
  String get scheduleCopyEmployeesToCopy;

  /// No description provided for @scheduleCopyEmployees.
  ///
  /// In en, this message translates to:
  /// **'{count} employees'**
  String scheduleCopyEmployees(int count);

  /// No description provided for @scheduleCopyNote.
  ///
  /// In en, this message translates to:
  /// **'Existing shifts for this week will be kept. Only missing days will be filled in.'**
  String get scheduleCopyNote;

  /// No description provided for @scheduleCopyButton.
  ///
  /// In en, this message translates to:
  /// **'Copy schedule'**
  String get scheduleCopyButton;

  /// No description provided for @schedulePublishDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish this week\'s schedule?'**
  String get schedulePublishDialogTitle;

  /// No description provided for @schedulePublishTotalShifts.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get schedulePublishTotalShifts;

  /// No description provided for @schedulePublishToBePublished.
  ///
  /// In en, this message translates to:
  /// **'To be published'**
  String get schedulePublishToBePublished;

  /// No description provided for @schedulePublishEmployeesNotified.
  ///
  /// In en, this message translates to:
  /// **'Employees notified'**
  String get schedulePublishEmployeesNotified;

  /// No description provided for @schedulePublishWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get schedulePublishWeekLabel;

  /// No description provided for @schedulePublishNote.
  ///
  /// In en, this message translates to:
  /// **'Employees will receive a notification once the schedule is published.'**
  String get schedulePublishNote;

  /// No description provided for @schedulePublishButton.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get schedulePublishButton;

  /// No description provided for @scheduleToolbarToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get scheduleToolbarToday;

  /// No description provided for @scheduleToolbarWeek.
  ///
  /// In en, this message translates to:
  /// **'Wk {number}'**
  String scheduleToolbarWeek(int number);

  /// No description provided for @scheduleAllDepartments.
  ///
  /// In en, this message translates to:
  /// **'All departments'**
  String get scheduleAllDepartments;

  /// No description provided for @scheduleAllLocations.
  ///
  /// In en, this message translates to:
  /// **'All locations'**
  String get scheduleAllLocations;

  /// No description provided for @scheduleDirectPlusIndirect.
  ///
  /// In en, this message translates to:
  /// **'Direct + indirect'**
  String get scheduleDirectPlusIndirect;

  /// No description provided for @scheduleDirectReportsOnly.
  ///
  /// In en, this message translates to:
  /// **'Direct reports only'**
  String get scheduleDirectReportsOnly;

  /// No description provided for @scheduleIndirectOnly.
  ///
  /// In en, this message translates to:
  /// **'Indirect only'**
  String get scheduleIndirectOnly;

  /// No description provided for @scheduleCopyLastWeek.
  ///
  /// In en, this message translates to:
  /// **'Copy last week'**
  String get scheduleCopyLastWeek;

  /// No description provided for @scheduleCopyLastWeekNoShifts.
  ///
  /// In en, this message translates to:
  /// **'Last week has no shifts to copy'**
  String get scheduleCopyLastWeekNoShifts;

  /// No description provided for @scheduleCopyNoRoom.
  ///
  /// In en, this message translates to:
  /// **'No empty days to copy into this week'**
  String get scheduleCopyNoRoom;

  /// No description provided for @schedulePublishing.
  ///
  /// In en, this message translates to:
  /// **'Publishing…'**
  String get schedulePublishing;

  /// No description provided for @schedulePublishingPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Publishing in progress, please wait'**
  String get schedulePublishingPleaseWait;

  /// No description provided for @schedulePublishWeek.
  ///
  /// In en, this message translates to:
  /// **'Publish week'**
  String get schedulePublishWeek;

  /// No description provided for @schedulePanelSwapRequests.
  ///
  /// In en, this message translates to:
  /// **'Swap Requests'**
  String get schedulePanelSwapRequests;

  /// No description provided for @scheduleNoPendingSwaps.
  ///
  /// In en, this message translates to:
  /// **'No pending swap requests'**
  String get scheduleNoPendingSwaps;

  /// No description provided for @schedulePanelConflicts.
  ///
  /// In en, this message translates to:
  /// **'Conflicts'**
  String get schedulePanelConflicts;

  /// No description provided for @scheduleNoConflicts.
  ///
  /// In en, this message translates to:
  /// **'No conflicts detected'**
  String get scheduleNoConflicts;

  /// No description provided for @schedulePanelTimeOff.
  ///
  /// In en, this message translates to:
  /// **'Time Off'**
  String get schedulePanelTimeOff;

  /// No description provided for @scheduleNoApprovedLeaves.
  ///
  /// In en, this message translates to:
  /// **'No approved leaves this week'**
  String get scheduleNoApprovedLeaves;

  /// No description provided for @scheduleSidePanelCollapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse panel'**
  String get scheduleSidePanelCollapse;

  /// No description provided for @scheduleSidePanelExpand.
  ///
  /// In en, this message translates to:
  /// **'Expand panel'**
  String get scheduleSidePanelExpand;

  /// No description provided for @scheduleShiftNewShift.
  ///
  /// In en, this message translates to:
  /// **'New shift'**
  String get scheduleShiftNewShift;

  /// No description provided for @scheduleShiftEditShift.
  ///
  /// In en, this message translates to:
  /// **'Edit shift'**
  String get scheduleShiftEditShift;

  /// No description provided for @scheduleShiftBulkAssign.
  ///
  /// In en, this message translates to:
  /// **'Bulk assign'**
  String get scheduleShiftBulkAssign;

  /// No description provided for @scheduleShiftAssignCells.
  ///
  /// In en, this message translates to:
  /// **'Assign shift to {count} cells'**
  String scheduleShiftAssignCells(int count);

  /// No description provided for @scheduleConflictDetected.
  ///
  /// In en, this message translates to:
  /// **'Conflict detected'**
  String get scheduleConflictDetected;

  /// No description provided for @scheduleQuickTypes.
  ///
  /// In en, this message translates to:
  /// **'Quick types'**
  String get scheduleQuickTypes;

  /// No description provided for @scheduleOffTypeDayOff.
  ///
  /// In en, this message translates to:
  /// **'Day Off'**
  String get scheduleOffTypeDayOff;

  /// No description provided for @scheduleOffTypePlannedLeave.
  ///
  /// In en, this message translates to:
  /// **'Planned Leave'**
  String get scheduleOffTypePlannedLeave;

  /// No description provided for @scheduleOffTypeUnplannedLeave.
  ///
  /// In en, this message translates to:
  /// **'Unplanned Leave'**
  String get scheduleOffTypeUnplannedLeave;

  /// No description provided for @scheduleOffTypeHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get scheduleOffTypeHoliday;

  /// No description provided for @scheduleSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get scheduleSummary;

  /// No description provided for @scheduleSummaryShifts.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get scheduleSummaryShifts;

  /// No description provided for @scheduleSummaryConflicts.
  ///
  /// In en, this message translates to:
  /// **'Conflicts'**
  String get scheduleSummaryConflicts;

  /// No description provided for @scheduleSummaryLeaveOnShift.
  ///
  /// In en, this message translates to:
  /// **'{type} (on shift)'**
  String scheduleSummaryLeaveOnShift(String type);

  /// No description provided for @scheduleEmptyCellsRemaining.
  ///
  /// In en, this message translates to:
  /// **'{count} cells still unfilled'**
  String scheduleEmptyCellsRemaining(int count);

  /// No description provided for @scheduleQuickTemplates.
  ///
  /// In en, this message translates to:
  /// **'Quick templates'**
  String get scheduleQuickTemplates;

  /// No description provided for @scheduleNoTemplatesYet.
  ///
  /// In en, this message translates to:
  /// **'No templates yet — enter times below to create one'**
  String get scheduleNoTemplatesYet;

  /// No description provided for @scheduleStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get scheduleStartTime;

  /// No description provided for @scheduleEndTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get scheduleEndTime;

  /// No description provided for @scheduleHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get scheduleHours;

  /// No description provided for @scheduleSaveAsTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save as template'**
  String get scheduleSaveAsTemplate;

  /// No description provided for @scheduleTemplateName.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get scheduleTemplateName;

  /// No description provided for @scheduleTemplateNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Morning shift'**
  String get scheduleTemplateNameHint;

  /// No description provided for @scheduleTemplateNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Template name is required'**
  String get scheduleTemplateNameRequired;

  /// No description provided for @scheduleNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get scheduleNoteOptional;

  /// No description provided for @scheduleNotifyEmployees.
  ///
  /// In en, this message translates to:
  /// **'Notify employees when schedule is published'**
  String get scheduleNotifyEmployees;

  /// No description provided for @scheduleRemoveShift.
  ///
  /// In en, this message translates to:
  /// **'Remove shift'**
  String get scheduleRemoveShift;

  /// No description provided for @scheduleSaveAsDraft.
  ///
  /// In en, this message translates to:
  /// **'Save as draft'**
  String get scheduleSaveAsDraft;

  /// No description provided for @scheduleTapCellFirst.
  ///
  /// In en, this message translates to:
  /// **'Tap a cell in the grid first to select which employee and day to assign.'**
  String get scheduleTapCellFirst;

  /// No description provided for @scheduleConflictApprovedLeave.
  ///
  /// In en, this message translates to:
  /// **'Employee is on approved leave that day'**
  String get scheduleConflictApprovedLeave;

  /// No description provided for @scheduleConflictExceedsMaxHours.
  ///
  /// In en, this message translates to:
  /// **'Shift exceeds 16 hours'**
  String get scheduleConflictExceedsMaxHours;

  /// No description provided for @scheduleConflictInsufficientRestAfter.
  ///
  /// In en, this message translates to:
  /// **'Less than 8h rest after previous shift'**
  String get scheduleConflictInsufficientRestAfter;

  /// No description provided for @scheduleConflictInsufficientRestBefore.
  ///
  /// In en, this message translates to:
  /// **'Less than 8h rest before next shift'**
  String get scheduleConflictInsufficientRestBefore;

  /// No description provided for @scheduleRequestSwapTitle.
  ///
  /// In en, this message translates to:
  /// **'Request shift swap'**
  String get scheduleRequestSwapTitle;

  /// No description provided for @scheduleSwapWith.
  ///
  /// In en, this message translates to:
  /// **'Swap with'**
  String get scheduleSwapWith;

  /// No description provided for @scheduleSearchColleague.
  ///
  /// In en, this message translates to:
  /// **'Search colleague…'**
  String get scheduleSearchColleague;

  /// No description provided for @scheduleSameShift.
  ///
  /// In en, this message translates to:
  /// **'Same shift'**
  String get scheduleSameShift;

  /// No description provided for @scheduleDayOff.
  ///
  /// In en, this message translates to:
  /// **'Day off'**
  String get scheduleDayOff;

  /// No description provided for @schedulePleaseSelectColleague.
  ///
  /// In en, this message translates to:
  /// **'Please select a colleague'**
  String get schedulePleaseSelectColleague;

  /// No description provided for @scheduleReasonOptional.
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get scheduleReasonOptional;

  /// No description provided for @scheduleWhySwapHint.
  ///
  /// In en, this message translates to:
  /// **'Why do you need to swap this shift?'**
  String get scheduleWhySwapHint;

  /// No description provided for @scheduleSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get scheduleSendRequest;

  /// No description provided for @scheduleNoUpcomingShifts.
  ///
  /// In en, this message translates to:
  /// **'No upcoming published shifts to swap.'**
  String get scheduleNoUpcomingShifts;

  /// No description provided for @scheduleSelectShift.
  ///
  /// In en, this message translates to:
  /// **'Select a shift to swap'**
  String get scheduleSelectShift;

  /// No description provided for @scheduleNoData.
  ///
  /// In en, this message translates to:
  /// **'No schedule data available.'**
  String get scheduleNoData;

  /// No description provided for @scheduleUpcomingShifts.
  ///
  /// In en, this message translates to:
  /// **'Upcoming shifts · next 14 days'**
  String get scheduleUpcomingShifts;

  /// No description provided for @scheduleNotAssigned.
  ///
  /// In en, this message translates to:
  /// **'Not assigned'**
  String get scheduleNotAssigned;

  /// No description provided for @scheduleRequestSwap.
  ///
  /// In en, this message translates to:
  /// **'Request swap'**
  String get scheduleRequestSwap;

  /// No description provided for @scheduleTeamView.
  ///
  /// In en, this message translates to:
  /// **'Team'**
  String get scheduleTeamView;

  /// No description provided for @scheduleColleaguesView.
  ///
  /// In en, this message translates to:
  /// **'Colleagues'**
  String get scheduleColleaguesView;

  /// No description provided for @scheduleNotAvailableInColleaguesMode.
  ///
  /// In en, this message translates to:
  /// **'Not available in colleagues mode'**
  String get scheduleNotAvailableInColleaguesMode;

  /// No description provided for @scheduleSelectOtherShiftsToSwap.
  ///
  /// In en, this message translates to:
  /// **'Select other shifts to swap with'**
  String get scheduleSelectOtherShiftsToSwap;

  /// No description provided for @scheduleSwapSameShift.
  ///
  /// In en, this message translates to:
  /// **'Same shift — nothing to swap'**
  String get scheduleSwapSameShift;

  /// No description provided for @scheduleSwapAlreadyPending.
  ///
  /// In en, this message translates to:
  /// **'You already have an open swap request for this day'**
  String get scheduleSwapAlreadyPending;

  /// No description provided for @scheduleSwapPastDay.
  ///
  /// In en, this message translates to:
  /// **'Swaps can only be requested for future shifts'**
  String get scheduleSwapPastDay;

  /// No description provided for @scheduleSwapOnLeave.
  ///
  /// In en, this message translates to:
  /// **'Cannot swap a shift on a leave day'**
  String get scheduleSwapOnLeave;

  /// No description provided for @scheduleSwapColleagueOnLeave.
  ///
  /// In en, this message translates to:
  /// **'Colleague is on leave — cannot swap this shift'**
  String get scheduleSwapColleagueOnLeave;

  /// No description provided for @scheduleSwapWantsToSwap.
  ///
  /// In en, this message translates to:
  /// **'Wants to swap shifts with you'**
  String get scheduleSwapWantsToSwap;

  /// No description provided for @scheduleSwapAwaitingManagerApproval.
  ///
  /// In en, this message translates to:
  /// **'Swap is awaiting manager approval'**
  String get scheduleSwapAwaitingManagerApproval;

  /// No description provided for @scheduleSwapCompleted.
  ///
  /// In en, this message translates to:
  /// **'Swap completed'**
  String get scheduleSwapCompleted;

  /// No description provided for @scheduleSwapDeclined.
  ///
  /// In en, this message translates to:
  /// **'Swap request was declined'**
  String get scheduleSwapDeclined;

  /// No description provided for @scheduleSwapCancelledByRequester.
  ///
  /// In en, this message translates to:
  /// **'Request was cancelled by requester'**
  String get scheduleSwapCancelledByRequester;

  /// No description provided for @scheduleSwapAwaitingColleague.
  ///
  /// In en, this message translates to:
  /// **'Awaiting their response'**
  String get scheduleSwapAwaitingColleague;

  /// No description provided for @scheduleSwapAwaitingManager.
  ///
  /// In en, this message translates to:
  /// **'Awaiting manager approval'**
  String get scheduleSwapAwaitingManager;

  /// No description provided for @scheduleSwapRequestDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request was declined'**
  String get scheduleSwapRequestDeclined;

  /// No description provided for @scheduleSwapYouCancelled.
  ///
  /// In en, this message translates to:
  /// **'You cancelled this request'**
  String get scheduleSwapYouCancelled;

  /// No description provided for @scheduleStatusApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get scheduleStatusApproved;

  /// No description provided for @scheduleStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get scheduleStatusCancelled;

  /// No description provided for @scheduleStatusDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get scheduleStatusDeclined;

  /// No description provided for @scheduleAwaitingColleagueBadge.
  ///
  /// In en, this message translates to:
  /// **'Awaiting colleague'**
  String get scheduleAwaitingColleagueBadge;

  /// No description provided for @scheduleAwaitingManagerBadge.
  ///
  /// In en, this message translates to:
  /// **'Awaiting manager'**
  String get scheduleAwaitingManagerBadge;

  /// No description provided for @scheduleGridCellSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} cell selected'**
  String scheduleGridCellSelected(int count);

  /// No description provided for @scheduleGridCellsSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} cells selected'**
  String scheduleGridCellsSelected(int count);

  /// No description provided for @scheduleAssignShift.
  ///
  /// In en, this message translates to:
  /// **'Assign Shift'**
  String get scheduleAssignShift;

  /// No description provided for @scheduleCoverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage'**
  String get scheduleCoverage;

  /// No description provided for @scheduleScrollTooltip.
  ///
  /// In en, this message translates to:
  /// **'Scroll (Shift + mouse wheel)'**
  String get scheduleScrollTooltip;

  /// No description provided for @scheduleEmployeeColumn.
  ///
  /// In en, this message translates to:
  /// **'Employee · {count}'**
  String scheduleEmployeeColumn(int count);

  /// No description provided for @scheduleKpiPeopleScheduled.
  ///
  /// In en, this message translates to:
  /// **'People scheduled'**
  String get scheduleKpiPeopleScheduled;

  /// No description provided for @scheduleKpiOfInView.
  ///
  /// In en, this message translates to:
  /// **'of {total} in view'**
  String scheduleKpiOfInView(int total);

  /// No description provided for @scheduleKpiShiftsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Shifts this week'**
  String get scheduleKpiShiftsThisWeek;

  /// No description provided for @scheduleKpiTotalHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h total'**
  String scheduleKpiTotalHours(int hours);

  /// No description provided for @scheduleKpiConflicts.
  ///
  /// In en, this message translates to:
  /// **'Conflicts'**
  String get scheduleKpiConflicts;

  /// No description provided for @scheduleKpiAllClear.
  ///
  /// In en, this message translates to:
  /// **'All clear'**
  String get scheduleKpiAllClear;

  /// No description provided for @scheduleKpiNeedReview.
  ///
  /// In en, this message translates to:
  /// **'Need review'**
  String get scheduleKpiNeedReview;

  /// No description provided for @scheduleKpiUnpublishedDrafts.
  ///
  /// In en, this message translates to:
  /// **'Unpublished drafts'**
  String get scheduleKpiUnpublishedDrafts;

  /// No description provided for @scheduleKpiAllPublished.
  ///
  /// In en, this message translates to:
  /// **'All published'**
  String get scheduleKpiAllPublished;

  /// No description provided for @scheduleKpiPendingPublish.
  ///
  /// In en, this message translates to:
  /// **'Pending publish'**
  String get scheduleKpiPendingPublish;

  /// No description provided for @scheduleKpiOnApprovedLeave.
  ///
  /// In en, this message translates to:
  /// **'On approved leave'**
  String get scheduleKpiOnApprovedLeave;

  /// No description provided for @scheduleKpiThisWeek.
  ///
  /// In en, this message translates to:
  /// **'this week'**
  String get scheduleKpiThisWeek;

  /// No description provided for @scheduleLegendMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get scheduleLegendMorning;

  /// No description provided for @scheduleLegendAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get scheduleLegendAfternoon;

  /// No description provided for @scheduleLegendOvernight.
  ///
  /// In en, this message translates to:
  /// **'Overnight'**
  String get scheduleLegendOvernight;

  /// No description provided for @scheduleLegendNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get scheduleLegendNight;

  /// No description provided for @scheduleLegendLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get scheduleLegendLeave;

  /// No description provided for @scheduleLegendDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get scheduleLegendDraft;

  /// No description provided for @scheduleLegendConflict.
  ///
  /// In en, this message translates to:
  /// **'Conflict'**
  String get scheduleLegendConflict;

  /// No description provided for @schedulePinnedSelfBadge.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get schedulePinnedSelfBadge;

  /// No description provided for @schedulePinnedManagerBadge.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get schedulePinnedManagerBadge;

  /// No description provided for @scheduleProposedBadge.
  ///
  /// In en, this message translates to:
  /// **'Proposed'**
  String get scheduleProposedBadge;

  /// No description provided for @scheduleReservedByManager.
  ///
  /// In en, this message translates to:
  /// **'Reserved by your manager'**
  String get scheduleReservedByManager;

  /// No description provided for @scheduleDraftHint.
  ///
  /// In en, this message translates to:
  /// **'Draft — your manager publishes'**
  String get scheduleDraftHint;

  /// No description provided for @scheduleLegendPublished.
  ///
  /// In en, this message translates to:
  /// **'{count} published'**
  String scheduleLegendPublished(int count);

  /// No description provided for @daySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// No description provided for @daySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// No description provided for @dayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// No description provided for @dayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// No description provided for @dayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// No description provided for @dayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// No description provided for @dayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @scheduleOpenSlot.
  ///
  /// In en, this message translates to:
  /// **'Open slot'**
  String get scheduleOpenSlot;

  /// No description provided for @scheduleAnErrorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get scheduleAnErrorOccurred;

  /// No description provided for @scheduleCarryOverEnds.
  ///
  /// In en, this message translates to:
  /// **'↵ ends {time}'**
  String scheduleCarryOverEnds(String time);

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @requestsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Error loading requests'**
  String get requestsLoadFailed;

  /// No description provided for @errorLoadingPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Error loading pending requests'**
  String get errorLoadingPendingRequests;

  /// No description provided for @teamShiftSwapRequests.
  ///
  /// In en, this message translates to:
  /// **'Team Shift Swap Requests'**
  String get teamShiftSwapRequests;

  /// No description provided for @colleaguesSwapRequests.
  ///
  /// In en, this message translates to:
  /// **'Colleagues Swap Requests'**
  String get colleaguesSwapRequests;

  /// No description provided for @shiftSwapRequests.
  ///
  /// In en, this message translates to:
  /// **'Shift Swap Requests'**
  String get shiftSwapRequests;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @shiftMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning'**
  String get shiftMorning;

  /// No description provided for @shiftEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening'**
  String get shiftEvening;

  /// No description provided for @shiftAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Afternoon'**
  String get shiftAfternoon;

  /// No description provided for @shiftOvernight.
  ///
  /// In en, this message translates to:
  /// **'Overnight'**
  String get shiftOvernight;

  /// No description provided for @shiftNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get shiftNight;

  /// No description provided for @shiftFullDay.
  ///
  /// In en, this message translates to:
  /// **'Full day'**
  String get shiftFullDay;

  /// No description provided for @hrTools.
  ///
  /// In en, this message translates to:
  /// **'HR Tools'**
  String get hrTools;

  /// No description provided for @bulkLeaves.
  ///
  /// In en, this message translates to:
  /// **'Bulk Leaves'**
  String get bulkLeaves;

  /// No description provided for @bulkOvertimeIncrement.
  ///
  /// In en, this message translates to:
  /// **'Bulk Overtime Increment'**
  String get bulkOvertimeIncrement;

  /// No description provided for @selectEmployeesFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select at least one employee'**
  String get selectEmployeesFirst;

  /// No description provided for @bulkLeavesSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Bulk leaves added successfully'**
  String get bulkLeavesSubmittedSuccessfully;

  /// No description provided for @bulkOvertimeSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Overtime balances updated successfully'**
  String get bulkOvertimeSubmittedSuccessfully;

  /// No description provided for @daysToAdd.
  ///
  /// In en, this message translates to:
  /// **'Days to Add'**
  String get daysToAdd;

  /// No description provided for @daysToAddHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1.5'**
  String get daysToAddHint;

  /// No description provided for @invalidDaysToAdd.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number greater than 0'**
  String get invalidDaysToAdd;

  /// No description provided for @bulkLeaveNote.
  ///
  /// In en, this message translates to:
  /// **'Leaves will be auto-approved for all selected employees'**
  String get bulkLeaveNote;

  /// No description provided for @approvalMode.
  ///
  /// In en, this message translates to:
  /// **'Approval Mode'**
  String get approvalMode;

  /// No description provided for @autoApproveMode.
  ///
  /// In en, this message translates to:
  /// **'Auto-approve'**
  String get autoApproveMode;

  /// No description provided for @normalApprovalCycleMode.
  ///
  /// In en, this message translates to:
  /// **'Normal cycle'**
  String get normalApprovalCycleMode;

  /// No description provided for @bulkLeaveApprovalCycleNote.
  ///
  /// In en, this message translates to:
  /// **'Requests will be sent to each employee\'s direct manager (N+1) for approval'**
  String get bulkLeaveApprovalCycleNote;

  /// No description provided for @bulkSickNoteSingleEmployeeOnly.
  ///
  /// In en, this message translates to:
  /// **'A medical report can only be attached when a single employee is selected'**
  String get bulkSickNoteSingleEmployeeOnly;

  /// No description provided for @bulkLeaveNoteUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'The leave was created, but the medical report could not be uploaded'**
  String get bulkLeaveNoteUploadFailed;

  /// No description provided for @bulkLeavesPartialTitle.
  ///
  /// In en, this message translates to:
  /// **'Some requests were not created'**
  String get bulkLeavesPartialTitle;

  /// No description provided for @bulkLeavesPartialSummary.
  ///
  /// In en, this message translates to:
  /// **'Created {created} of {total} requests'**
  String bulkLeavesPartialSummary(int created, int total);

  /// No description provided for @tutTopBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Top Bar'**
  String get tutTopBarTitle;

  /// No description provided for @tutTopBarBody.
  ///
  /// In en, this message translates to:
  /// **'Shows the current page name, logged-in user, and sign-out button on the left.'**
  String get tutTopBarBody;

  /// No description provided for @tutSidebarTitle.
  ///
  /// In en, this message translates to:
  /// **'Side Navigation'**
  String get tutSidebarTitle;

  /// No description provided for @tutSidebarBody.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts to all system sections: Home, Leaves, Attendance, Advances, Letters and more.'**
  String get tutSidebarBody;

  /// No description provided for @tutPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Requests'**
  String get tutPendingTitle;

  /// No description provided for @tutPendingBody.
  ///
  /// In en, this message translates to:
  /// **'Requests waiting for your action, grouped by type: leaves, missions, attendance, advances, admin actions.'**
  String get tutPendingBody;

  /// No description provided for @tutProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'In-Process Requests'**
  String get tutProcessingTitle;

  /// No description provided for @tutProcessingBody.
  ///
  /// In en, this message translates to:
  /// **'Requests you have sent that are still under review by management or HR.'**
  String get tutProcessingBody;

  /// No description provided for @tutRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recently Processed'**
  String get tutRecentTitle;

  /// No description provided for @tutRecentBody.
  ///
  /// In en, this message translates to:
  /// **'A log of the latest processed requests for easy reference.'**
  String get tutRecentBody;

  /// No description provided for @tutQuickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get tutQuickActionsTitle;

  /// No description provided for @tutQuickActionsBody.
  ///
  /// In en, this message translates to:
  /// **'Start any new request in one tap: mission, leave, advance, attendance proof, HR letter, or admin action.'**
  String get tutQuickActionsBody;

  /// No description provided for @tutLeaveButtonTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit a Leave Request'**
  String get tutLeaveButtonTitle;

  /// No description provided for @tutLeaveButtonBody.
  ///
  /// In en, this message translates to:
  /// **'This is the Leave Request button. Tap it to open the leave submission form.'**
  String get tutLeaveButtonBody;

  /// No description provided for @tutLeaveBalancesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Balances'**
  String get tutLeaveBalancesTitle;

  /// No description provided for @tutLeaveBalancesBody.
  ///
  /// In en, this message translates to:
  /// **'Your leave balances at a glance. \'Available Now\' is what you can use today (it can go negative if you\'re in deficit). Carry-forward days are last year\'s remainder and expire on Mar 31; overtime/compensation balance is shown separately and is used before annual leave.'**
  String get tutLeaveBalancesBody;

  /// No description provided for @tutLeaveFromDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get tutLeaveFromDateTitle;

  /// No description provided for @tutLeaveFromDateBody.
  ///
  /// In en, this message translates to:
  /// **'Pick the first day of your leave. In the calendar, days struck through in red are unavailable — they already have a leave, business-trip, or missing-punch request. Tap a red day to see the reason.'**
  String get tutLeaveFromDateBody;

  /// No description provided for @tutLeaveToDateTitle.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get tutLeaveToDateTitle;

  /// No description provided for @tutLeaveToDateBody.
  ///
  /// In en, this message translates to:
  /// **'Pick the last day of your leave. The range can\'t cross an unavailable (red) day, so the selectable days adjust automatically based on your start date.'**
  String get tutLeaveToDateBody;

  /// No description provided for @tutLeaveHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Partial Hours'**
  String get tutLeaveHoursTitle;

  /// No description provided for @tutLeaveHoursBody.
  ///
  /// In en, this message translates to:
  /// **'Only shown for a single-day request. Choose how many hours you need instead of a full day — leave it empty to take the whole day. Selecting hours limits which leave types you can pick.'**
  String get tutLeaveHoursBody;

  /// No description provided for @tutLeaveDayCountTitle.
  ///
  /// In en, this message translates to:
  /// **'Days Off'**
  String get tutLeaveDayCountTitle;

  /// No description provided for @tutLeaveDayCountBody.
  ///
  /// In en, this message translates to:
  /// **'A live count of how long you\'ll be off for the dates you chose. It shows hours instead of days when you request partial hours.'**
  String get tutLeaveDayCountBody;

  /// No description provided for @tutLeaveTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Type'**
  String get tutLeaveTypeTitle;

  /// No description provided for @tutLeaveTypeBody.
  ///
  /// In en, this message translates to:
  /// **'Choose the type that fits your situation. A greyed-out option means its rule isn\'t met for your current dates, hours, or balance.\n\n• Annual — planned time off. Needs available or carry-forward balance, is subject to your yearly allowance. If you have overtime balance, use Compensation first.\n\n• Emergency — sudden, same-day needs. Limited to one day and requires available annual/carry-forward balance.\n\n• Compensation — spends your overtime balance. Available only when that balance covers the requested days.\n\n• Sick — for illness. Requires uploading a sick note.\n\n• Unpaid — time off without pay. Available only when you have little or no paid balance left.'**
  String get tutLeaveTypeBody;

  /// No description provided for @tutLeaveSubmitTitle.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get tutLeaveSubmitTitle;

  /// No description provided for @tutLeaveSubmitBody.
  ///
  /// In en, this message translates to:
  /// **'Sends your request for approval. It stays grey and disabled until every field is valid, then turns blue. Any blocking issue (like an emergency request that\'s too long) is shown just above this button.'**
  String get tutLeaveSubmitBody;

  /// No description provided for @tutHelpTooltip.
  ///
  /// In en, this message translates to:
  /// **'Help tour'**
  String get tutHelpTooltip;

  /// No description provided for @tutNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tutNext;

  /// No description provided for @tutSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip tour'**
  String get tutSkip;

  /// No description provided for @tutWatchHow.
  ///
  /// In en, this message translates to:
  /// **'Watch how'**
  String get tutWatchHow;

  /// No description provided for @tutHelpCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Help'**
  String get tutHelpCenterTitle;

  /// No description provided for @tutStartTour.
  ///
  /// In en, this message translates to:
  /// **'Start guided tour'**
  String get tutStartTour;

  /// No description provided for @tutBrowseClips.
  ///
  /// In en, this message translates to:
  /// **'WATCH HOW-TO CLIPS'**
  String get tutBrowseClips;

  /// No description provided for @tutClipComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This recording is coming soon.'**
  String get tutClipComingSoon;

  /// No description provided for @tutSchViewModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Team vs Colleagues'**
  String get tutSchViewModeTitle;

  /// No description provided for @tutSchViewModeBody.
  ///
  /// In en, this message translates to:
  /// **'Switch between Team view — the schedule of everyone who reports to you — and Colleagues view, where you draft your own shifts alongside your peers.'**
  String get tutSchViewModeBody;

  /// No description provided for @tutSchTabsTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Views'**
  String get tutSchTabsTitle;

  /// No description provided for @tutSchTabsBody.
  ///
  /// In en, this message translates to:
  /// **'Look at the same week four ways: Weekly grid, a Daily timeline, a Monthly calendar, and My Schedule for your own shifts.'**
  String get tutSchTabsBody;

  /// No description provided for @tutSchFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigate & Filter'**
  String get tutSchFiltersTitle;

  /// No description provided for @tutSchFiltersBody.
  ///
  /// In en, this message translates to:
  /// **'Use Today and the arrows to move between weeks, then narrow the team by department, location, or reporting scope (direct, indirect, or both).'**
  String get tutSchFiltersBody;

  /// No description provided for @tutSchCopyTitle.
  ///
  /// In en, this message translates to:
  /// **'Copy Last Week'**
  String get tutSchCopyTitle;

  /// No description provided for @tutSchCopyBody.
  ///
  /// In en, this message translates to:
  /// **'Reuse last week\'s plan in one step — it copies shifts into any empty days for the current week, skipping days that are already filled.'**
  String get tutSchCopyBody;

  /// No description provided for @tutSchPublishTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish the Week'**
  String get tutSchPublishTitle;

  /// No description provided for @tutSchPublishBody.
  ///
  /// In en, this message translates to:
  /// **'Turn your drafts into the official schedule. Once every cell is filled the button turns blue; publishing notifies the affected employees. It stays disabled while empty cells remain.'**
  String get tutSchPublishBody;

  /// No description provided for @tutSchKpiTitle.
  ///
  /// In en, this message translates to:
  /// **'Week at a Glance'**
  String get tutSchKpiTitle;

  /// No description provided for @tutSchKpiBody.
  ///
  /// In en, this message translates to:
  /// **'Live totals for the visible team: people scheduled, shifts this week, conflicts, unpublished drafts, and how many are on approved leave.'**
  String get tutSchKpiBody;

  /// No description provided for @tutSchLegendTitle.
  ///
  /// In en, this message translates to:
  /// **'Colour Legend'**
  String get tutSchLegendTitle;

  /// No description provided for @tutSchLegendBody.
  ///
  /// In en, this message translates to:
  /// **'What the cell colours mean — Morning, Afternoon, Night and Overnight shifts, plus Leave and Day-off, and the markers for drafts and conflicts.'**
  String get tutSchLegendBody;

  /// No description provided for @tutSchAssignTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign a Shift'**
  String get tutSchAssignTitle;

  /// No description provided for @tutSchAssignBody.
  ///
  /// In en, this message translates to:
  /// **'Tap any empty cell to open the shift editor and set the times, or tap an existing shift to edit it. Conflicts (rest gaps, leave overlaps) are flagged automatically.'**
  String get tutSchAssignBody;

  /// No description provided for @tutSchMultiSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Multiple Cells'**
  String get tutSchMultiSelectTitle;

  /// No description provided for @tutSchMultiSelectBody.
  ///
  /// In en, this message translates to:
  /// **'Need the same shift across several people or days? Drag across the grid — or long-press then tap — to select many cells, then assign them all at once from the bar that appears.'**
  String get tutSchMultiSelectBody;

  /// No description provided for @tutSchTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Reusable Templates'**
  String get tutSchTemplateTitle;

  /// No description provided for @tutSchTemplateBody.
  ///
  /// In en, this message translates to:
  /// **'In the shift editor, tick \'Save as template\' and give it a name to store a shift you use often. Next time it appears as a chip you can apply in one tap.'**
  String get tutSchTemplateBody;

  /// No description provided for @tutSchSwapTitle.
  ///
  /// In en, this message translates to:
  /// **'Swaps, Conflicts & Time Off'**
  String get tutSchSwapTitle;

  /// No description provided for @tutSchSwapBody.
  ///
  /// In en, this message translates to:
  /// **'The side panel collects swap requests to approve or decline, scheduling conflicts to resolve, and your team\'s approved time off — all in one place.'**
  String get tutSchSwapBody;

  /// No description provided for @tutTeamTour.
  ///
  /// In en, this message translates to:
  /// **'Team view tour'**
  String get tutTeamTour;

  /// No description provided for @tutColleaguesTour.
  ///
  /// In en, this message translates to:
  /// **'Colleagues view tour'**
  String get tutColleaguesTour;

  /// No description provided for @tutSchWeekNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Navigate Weeks'**
  String get tutSchWeekNavTitle;

  /// No description provided for @tutSchWeekNavBody.
  ///
  /// In en, this message translates to:
  /// **'Use Today and the arrows to move between weeks. The week label shows which week you\'re viewing.'**
  String get tutSchWeekNavBody;

  /// No description provided for @tutSchSelfActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Draft Actions'**
  String get tutSchSelfActionsTitle;

  /// No description provided for @tutSchSelfActionsBody.
  ///
  /// In en, this message translates to:
  /// **'In Colleagues view you draft your own row. \'Copy last week\' fills your empty days from last week, and the amber hint reminds you that your manager publishes your final schedule.'**
  String get tutSchSelfActionsBody;

  /// No description provided for @tutSchSelfDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Draft Your Own Shifts'**
  String get tutSchSelfDraftTitle;

  /// No description provided for @tutSchSelfDraftBody.
  ///
  /// In en, this message translates to:
  /// **'Tap an empty day on your row to propose a shift, or tap your own draft to edit it. Days your manager has reserved show a lock and can\'t be edited. Your drafts stay pending until your manager publishes them.'**
  String get tutSchSelfDraftBody;

  /// No description provided for @tutSchRequestSwapTitle.
  ///
  /// In en, this message translates to:
  /// **'Request a Swap'**
  String get tutSchRequestSwapTitle;

  /// No description provided for @tutSchRequestSwapBody.
  ///
  /// In en, this message translates to:
  /// **'Tap a colleague\'s shift to request a swap with them. You can only swap future shifts, and not when either of you is on leave or already has an open request for that day.'**
  String get tutSchRequestSwapBody;

  /// No description provided for @tutSchPinnedRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Manager Comparison Row'**
  String get tutSchPinnedRowTitle;

  /// No description provided for @tutSchPinnedRowBody.
  ///
  /// In en, this message translates to:
  /// **'This pinned row shows your manager\'s schedule for reference (read-only, marked with a \'Manager\' badge) so you can line your own shifts up against theirs.'**
  String get tutSchPinnedRowBody;

  /// No description provided for @tutSchMobileWeekNavTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a Week'**
  String get tutSchMobileWeekNavTitle;

  /// No description provided for @tutSchMobileWeekNavBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the arrows to move between weeks; the label in the middle shows the week you\'re viewing.'**
  String get tutSchMobileWeekNavBody;

  /// No description provided for @tutSchMobileStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Week at a Glance'**
  String get tutSchMobileStatsTitle;

  /// No description provided for @tutSchMobileStatsBody.
  ///
  /// In en, this message translates to:
  /// **'Quick totals for the week: people scheduled and shifts always show; in Team view you also see conflicts and unpublished drafts.'**
  String get tutSchMobileStatsBody;

  /// No description provided for @tutSchMobileDayPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a Day'**
  String get tutSchMobileDayPickerTitle;

  /// No description provided for @tutSchMobileDayPickerBody.
  ///
  /// In en, this message translates to:
  /// **'Tap a day to focus the list below on that day\'s shifts. Swipe the strip sideways to reach the whole week.'**
  String get tutSchMobileDayPickerBody;

  /// No description provided for @tutSchMobileBulkTitle.
  ///
  /// In en, this message translates to:
  /// **'Bulk Assign Shifts'**
  String get tutSchMobileBulkTitle;

  /// No description provided for @tutSchMobileBulkBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \'Assign shifts…\' to open the bulk sheet and give the same shift to several people across several days at once — it walks you through the shift (template or custom times), the days, then who it applies to. The \'Fill this day\' link above the list does the same for just the day you\'re viewing.'**
  String get tutSchMobileBulkBody;

  /// No description provided for @tutSchMobileTabsTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Views'**
  String get tutSchMobileTabsTitle;

  /// No description provided for @tutSchMobileTabsBody.
  ///
  /// In en, this message translates to:
  /// **'Swipe the tab strip to move between views: Weekly (the day-by-day list below), Monthly for a whole-month overview, On Shift Now for who\'s working right now, My Schedule for your own shifts, and Swaps — its badge counts requests waiting on you. Managers also get a More tab for publishing and copying.'**
  String get tutSchMobileTabsBody;

  /// No description provided for @tutSchMobileFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter the Team'**
  String get tutSchMobileFiltersTitle;

  /// No description provided for @tutSchMobileFiltersBody.
  ///
  /// In en, this message translates to:
  /// **'Tap this chip to open the filters sheet, then narrow the list by department, location, or reporting scope. Nothing changes until you tap Apply, and Reset clears everything. The chip itself shows what\'s currently applied.'**
  String get tutSchMobileFiltersBody;

  /// No description provided for @tutSchMobileSelfBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Shift Actions'**
  String get tutSchMobileSelfBarTitle;

  /// No description provided for @tutSchMobileSelfBarBody.
  ///
  /// In en, this message translates to:
  /// **'\'Copy last week\' fills your empty days from last week, and \'Assign shifts…\' opens a sheet locked to your own row so you can draft several days at once. Your drafts stay pending until your manager publishes them.'**
  String get tutSchMobileSelfBarBody;

  /// No description provided for @tutSchMobileSwapsTitle.
  ///
  /// In en, this message translates to:
  /// **'Approve Swap Requests'**
  String get tutSchMobileSwapsTitle;

  /// No description provided for @tutSchMobileSwapsBody.
  ///
  /// In en, this message translates to:
  /// **'Swap requests from your team land here under \'Pending action\'. Each card shows both shifts side by side so you can compare them, then Approve or Decline. The tab badge tells you how many are waiting.'**
  String get tutSchMobileSwapsBody;

  /// No description provided for @tutSchMobileSwapsPeerTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Swaps'**
  String get tutSchMobileSwapsPeerTitle;

  /// No description provided for @tutSchMobileSwapsPeerBody.
  ///
  /// In en, this message translates to:
  /// **'Everything about your swaps in one tab: requests colleagues sent you (accept or decline), the ones you\'ve sent (which you can cancel), and your past swap history. To start a new one, tap a colleague\'s shift in Weekly or use \'Swap with\' in My Schedule.'**
  String get tutSchMobileSwapsPeerBody;

  /// No description provided for @tutSchMobileMoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Publish & Copy'**
  String get tutSchMobileMoreTitle;

  /// No description provided for @tutSchMobileMoreBody.
  ///
  /// In en, this message translates to:
  /// **'The manager actions live here. \'Publish week\' turns your drafts into the official schedule and notifies everyone affected — it stays disabled until every cell is filled. \'Copy last week\' reuses last week\'s plan for any empty days.'**
  String get tutSchMobileMoreBody;

  /// No description provided for @tutSchKpiColleaguesBody.
  ///
  /// In en, this message translates to:
  /// **'Totals for the week you\'re viewing: how many people are scheduled and how many shifts there are in total.'**
  String get tutSchKpiColleaguesBody;

  /// No description provided for @tutSchLegendColleaguesBody.
  ///
  /// In en, this message translates to:
  /// **'What the colours mean — Morning, Afternoon, Night and Overnight shifts, plus Leave and Day-off.'**
  String get tutSchLegendColleaguesBody;

  /// No description provided for @tutTopicsTeam.
  ///
  /// In en, this message translates to:
  /// **'MANAGING YOUR TEAM'**
  String get tutTopicsTeam;

  /// No description provided for @tutTopicsColleagues.
  ///
  /// In en, this message translates to:
  /// **'YOUR OWN SCHEDULE'**
  String get tutTopicsColleagues;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @statsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get statsOverview;

  /// No description provided for @statsApprovalFunnel.
  ///
  /// In en, this message translates to:
  /// **'Approval Funnel'**
  String get statsApprovalFunnel;

  /// No description provided for @statsLeaveAttendance.
  ///
  /// In en, this message translates to:
  /// **'Leave & Attendance'**
  String get statsLeaveAttendance;

  /// No description provided for @statsFinancial.
  ///
  /// In en, this message translates to:
  /// **'Financial'**
  String get statsFinancial;

  /// No description provided for @statsDisciplinary.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary'**
  String get statsDisciplinary;

  /// No description provided for @statsWorkforce.
  ///
  /// In en, this message translates to:
  /// **'Workforce'**
  String get statsWorkforce;

  /// No description provided for @statsTotalRequests.
  ///
  /// In en, this message translates to:
  /// **'Total Requests'**
  String get statsTotalRequests;

  /// No description provided for @statsPendingApproval.
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get statsPendingApproval;

  /// No description provided for @statsAvgApprovalTime.
  ///
  /// In en, this message translates to:
  /// **'Avg Approval Time'**
  String get statsAvgApprovalTime;

  /// No description provided for @statsApprovalRate.
  ///
  /// In en, this message translates to:
  /// **'Approval Rate'**
  String get statsApprovalRate;

  /// No description provided for @statsVolumeByType.
  ///
  /// In en, this message translates to:
  /// **'Request Volume by Type'**
  String get statsVolumeByType;

  /// No description provided for @statsStatusDistribution.
  ///
  /// In en, this message translates to:
  /// **'Status Distribution'**
  String get statsStatusDistribution;

  /// No description provided for @statsRequestsByDepartment.
  ///
  /// In en, this message translates to:
  /// **'Requests by Department'**
  String get statsRequestsByDepartment;

  /// No description provided for @statsAvgTimePerStage.
  ///
  /// In en, this message translates to:
  /// **'Avg Time per Stage'**
  String get statsAvgTimePerStage;

  /// No description provided for @statsPendingByApprover.
  ///
  /// In en, this message translates to:
  /// **'Pending by Approver × Type'**
  String get statsPendingByApprover;

  /// No description provided for @statsOldestPending.
  ///
  /// In en, this message translates to:
  /// **'Oldest Pending'**
  String get statsOldestPending;

  /// No description provided for @statsLeaveTypeMix.
  ///
  /// In en, this message translates to:
  /// **'Leave Type Mix'**
  String get statsLeaveTypeMix;

  /// No description provided for @statsLeaveSeasonality.
  ///
  /// In en, this message translates to:
  /// **'Leave Days (Seasonality)'**
  String get statsLeaveSeasonality;

  /// No description provided for @statsLeaveBalanceByDept.
  ///
  /// In en, this message translates to:
  /// **'Leave Balance by Department'**
  String get statsLeaveBalanceByDept;

  /// No description provided for @statsAdvancesDisbursed.
  ///
  /// In en, this message translates to:
  /// **'Advances Disbursed'**
  String get statsAdvancesDisbursed;

  /// No description provided for @statsTotalAdvances.
  ///
  /// In en, this message translates to:
  /// **'Total Advances'**
  String get statsTotalAdvances;

  /// No description provided for @statsSettlementRate.
  ///
  /// In en, this message translates to:
  /// **'Settlement Rate'**
  String get statsSettlementRate;

  /// No description provided for @statsAvgAdvance.
  ///
  /// In en, this message translates to:
  /// **'Avg Advance'**
  String get statsAvgAdvance;

  /// No description provided for @statsApprovedAmount.
  ///
  /// In en, this message translates to:
  /// **'Approved Amount'**
  String get statsApprovedAmount;

  /// No description provided for @statsViolationCategories.
  ///
  /// In en, this message translates to:
  /// **'Violation Categories'**
  String get statsViolationCategories;

  /// No description provided for @statsActionTypes.
  ///
  /// In en, this message translates to:
  /// **'Action Types'**
  String get statsActionTypes;

  /// No description provided for @statsOutcomes.
  ///
  /// In en, this message translates to:
  /// **'Outcomes'**
  String get statsOutcomes;

  /// No description provided for @statsEscalatedToLegal.
  ///
  /// In en, this message translates to:
  /// **'Escalated to Legal'**
  String get statsEscalatedToLegal;

  /// No description provided for @statsSuspensions.
  ///
  /// In en, this message translates to:
  /// **'Suspensions'**
  String get statsSuspensions;

  /// No description provided for @statsTerminations.
  ///
  /// In en, this message translates to:
  /// **'Terminations'**
  String get statsTerminations;

  /// No description provided for @statsTotalCases.
  ///
  /// In en, this message translates to:
  /// **'Total Cases'**
  String get statsTotalCases;

  /// No description provided for @statsHeadcountByDepartment.
  ///
  /// In en, this message translates to:
  /// **'Headcount by Department'**
  String get statsHeadcountByDepartment;

  /// No description provided for @statsHeadcountByLocation.
  ///
  /// In en, this message translates to:
  /// **'Headcount by Location'**
  String get statsHeadcountByLocation;

  /// No description provided for @statsTenureDistribution.
  ///
  /// In en, this message translates to:
  /// **'Tenure Distribution'**
  String get statsTenureDistribution;

  /// No description provided for @statsAllDepartments.
  ///
  /// In en, this message translates to:
  /// **'All Departments'**
  String get statsAllDepartments;

  /// No description provided for @statsAllLocations.
  ///
  /// In en, this message translates to:
  /// **'All Locations'**
  String get statsAllLocations;

  /// No description provided for @statsAllTypes.
  ///
  /// In en, this message translates to:
  /// **'All Types'**
  String get statsAllTypes;

  /// No description provided for @statsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get statsThisMonth;

  /// No description provided for @statsLast3Months.
  ///
  /// In en, this message translates to:
  /// **'Last 3 months'**
  String get statsLast3Months;

  /// No description provided for @statsThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get statsThisYear;

  /// No description provided for @statsLast12Months.
  ///
  /// In en, this message translates to:
  /// **'Last 12 months'**
  String get statsLast12Months;

  /// No description provided for @statsNoData.
  ///
  /// In en, this message translates to:
  /// **'No data for this period'**
  String get statsNoData;

  /// No description provided for @statsNothingPending.
  ///
  /// In en, this message translates to:
  /// **'Nothing pending'**
  String get statsNothingPending;

  /// No description provided for @statsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get statsRetry;

  /// No description provided for @statsApproverN1.
  ///
  /// In en, this message translates to:
  /// **'N+1'**
  String get statsApproverN1;

  /// No description provided for @statsApproverN2.
  ///
  /// In en, this message translates to:
  /// **'N+2'**
  String get statsApproverN2;

  /// No description provided for @statsApproverHr.
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get statsApproverHr;

  /// No description provided for @statsApproverFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get statsApproverFinance;

  /// No description provided for @statsApproverLegal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get statsApproverLegal;

  /// No description provided for @statsApproverEmployee.
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get statsApproverEmployee;

  /// No description provided for @statsApproverNone.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get statsApproverNone;

  /// No description provided for @statsStageSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get statsStageSubmitted;

  /// No description provided for @statsStageFinalized.
  ///
  /// In en, this message translates to:
  /// **'Finalized'**
  String get statsStageFinalized;

  /// No description provided for @statsTenureUnder1.
  ///
  /// In en, this message translates to:
  /// **'< 1 yr'**
  String get statsTenureUnder1;

  /// No description provided for @statsTenure1to2.
  ///
  /// In en, this message translates to:
  /// **'1-2 yr'**
  String get statsTenure1to2;

  /// No description provided for @statsTenure2to4.
  ///
  /// In en, this message translates to:
  /// **'2-4 yr'**
  String get statsTenure2to4;

  /// No description provided for @statsTenure4plus.
  ///
  /// In en, this message translates to:
  /// **'4+ yr'**
  String get statsTenure4plus;

  /// No description provided for @statsUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get statsUnknown;

  /// No description provided for @statsPendingAt.
  ///
  /// In en, this message translates to:
  /// **'At'**
  String get statsPendingAt;

  /// No description provided for @statsAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get statsAge;

  /// No description provided for @statsLeaveCancellation.
  ///
  /// In en, this message translates to:
  /// **'Leave Cancellation'**
  String get statsLeaveCancellation;

  /// No description provided for @statsBusinesstripCancellation.
  ///
  /// In en, this message translates to:
  /// **'Business Trip Cancellation'**
  String get statsBusinesstripCancellation;

  /// No description provided for @statsTakenVsBalanceByDept.
  ///
  /// In en, this message translates to:
  /// **'Leave Taken vs Available Balance by Department (avg. days/employee)'**
  String get statsTakenVsBalanceByDept;

  /// No description provided for @statsTakenThisYear.
  ///
  /// In en, this message translates to:
  /// **'Taken this year'**
  String get statsTakenThisYear;

  /// No description provided for @statsAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available balance'**
  String get statsAvailableBalance;

  /// No description provided for @statsHeadcount.
  ///
  /// In en, this message translates to:
  /// **'Headcount'**
  String get statsHeadcount;

  /// No description provided for @statsAccessDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have access to statistics.'**
  String get statsAccessDenied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
