// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get action => 'Action';

  @override
  String get approve => 'Approve';

  @override
  String get approver => 'Approver';

  @override
  String get cancel => 'Cancel';

  @override
  String get editManagerTitle => 'Edit Manager';

  @override
  String get currentManager => 'Current Manager';

  @override
  String get newManager => 'New Manager (N+1)';

  @override
  String get pleaseSelectManager => 'Please select a manager';

  @override
  String get circularReportingLine =>
      'That would create a circular reporting line';

  @override
  String get failedToUpdateManager => 'Failed to update manager';

  @override
  String get noPermissionToChangeManager =>
      'You don\'t have permission to change managers';

  @override
  String get managerUpdatedSuccessfully => 'Manager updated successfully';

  @override
  String get employeeDetailsUpdatedSuccessfully =>
      'Employee details updated successfully';

  @override
  String get failedToUpdateEmployeeDetails =>
      'Failed to update employee details';

  @override
  String get noPermissionToEditEmployeeDetails =>
      'You don\'t have permission to edit employee details';

  @override
  String get code => 'Code';

  @override
  String get close => 'Close';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get dateFrom => 'Date From';

  @override
  String get dateTo => 'Date To';

  @override
  String get day => 'Day';

  @override
  String get days => 'Days';

  @override
  String get decline => 'Decline';

  @override
  String get putOnHold => 'Put on Hold';

  @override
  String get declineReason => 'Decline Reason';

  @override
  String get department => 'Department';

  @override
  String get hours => 'Hours';

  @override
  String get hoursLabel => 'Hours';

  @override
  String get hourLabel => 'Hour';

  @override
  String get numberOfHours => 'Num of Hours';

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';

  @override
  String get morning => 'Morning';

  @override
  String get evening => 'Evening';

  @override
  String get id => 'ID';

  @override
  String get leaveBalance => 'Leave Balance';

  @override
  String get availableNow => 'Available Till Date';

  @override
  String get annualAllowanceRemaining => 'Annual allowance remaining';

  @override
  String get carryForward => 'Carry-forward';

  @override
  String get expiresApr1 => 'expires Mar 31';

  @override
  String get catchingUp => 'catching up';

  @override
  String maxPerMonth(Object days) {
    return 'max $days/month';
  }

  @override
  String get negativeBalanceHint =>
      'Your balance is currently negative — the system will check whether it covers your selected dates once you submit a new request';

  @override
  String get useCompensationFirst => 'Use compensation leave first';

  @override
  String get annualCapReached => 'Annual cap reached';

  @override
  String get leaveType => 'Leave Type';

  @override
  String get location => 'Location';

  @override
  String get enterLocation => 'Enter location';

  @override
  String get login => 'Login';

  @override
  String get lRSubmittedSuccessfully => 'Leave request submitted successfully';

  @override
  String get errUserNotFound => 'We couldn\'t find your employee record.';

  @override
  String get errLeaveOutsideYear =>
      'Leave dates must fall within the current year.';

  @override
  String get errAnnualCapExceeded =>
      'You\'ve reached your annual leave allowance for this year.';

  @override
  String get errInsufficientProjectedBalance =>
      'Your balance won\'t cover these dates, even with upcoming monthly credits.';

  @override
  String get errDatesRequired => 'Please select both a start and end date.';

  @override
  String get errLeaveRequestFailed =>
      'We couldn\'t submit your leave request. Please try again.';

  @override
  String get oRSubmittedSuccessfully =>
      'Overtime request submitted successfully';

  @override
  String get myRequests => 'My Requests';

  @override
  String get name => 'Name';

  @override
  String get newPassword => 'New Password';

  @override
  String get noLeaveRequestsFound => 'No leave requests found';

  @override
  String get noOvertimeRequestsFound => 'No overtime requests found';

  @override
  String get noSickAvail => 'No sick note available';

  @override
  String get numberOfDays => 'Number of days';

  @override
  String get oldPassword => 'Old Password';

  @override
  String get overtime => 'Overtime';

  @override
  String get overTimeBalance => 'Overtime Balance';

  @override
  String get password => 'Password';

  @override
  String get passwordsDoNotMatch => 'Passwords Do Not Match';

  @override
  String get passwordUpdatedSuccessfully => 'Password Updated Successfully';

  @override
  String get plsNewPassword => 'Please Enter New Password';

  @override
  String get plsOldPassword => 'Please Enter Old Password';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordConfirmTitle => 'Reset Password';

  @override
  String get resetPasswordConfirmMessage =>
      'Are you sure you want to reset this employee\'s password to \"123456\"?';

  @override
  String get resetPasswordSuccess =>
      'Password reset successfully to \"123456\"';

  @override
  String get resetPasswordFailed => 'Failed to reset password';

  @override
  String get profile => 'Profile';

  @override
  String get home => 'Home';

  @override
  String get quickAccess => 'Quick Access';

  @override
  String get showMore => 'Show More';

  @override
  String get showLess => 'Show Less';

  @override
  String get reason => 'Reason';

  @override
  String get requestID => 'Request ID';

  @override
  String get requestLeave => 'Request Leave';

  @override
  String get requestOvertime => 'Request Overtime';

  @override
  String get sickNote => 'Medical Report';

  @override
  String get sickNotes => 'Medical Reports';

  @override
  String get status => 'Status';

  @override
  String get submit => 'Submit';

  @override
  String get submitting => 'Submitting...';

  @override
  String get teamRequests => 'Team Requests';

  @override
  String get forgotPasswordHint =>
      'Forgot password? Contact HR to reset password';

  @override
  String get test => 'Test';

  @override
  String get timeFrom => 'Time From';

  @override
  String get timeTo => 'Time To';

  @override
  String get title => 'Title';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get upSicknote => 'Upload Medical Report';

  @override
  String get youWillOff => 'You Will Be Off For: ';

  @override
  String get newRequest => 'New Request';

  @override
  String get date => 'Date';

  @override
  String get pending => 'Pending';

  @override
  String get approved => 'Approved';

  @override
  String get declined => 'Declined';

  @override
  String get onHold => 'On Hold';

  @override
  String get underInvestigation => 'Under Investigation';

  @override
  String get viewRequests => 'View Requests';

  @override
  String get actionable => 'Actionable';

  @override
  String get processed => 'Processed';

  @override
  String get processedDisciplinary => 'Processed Disciplinary';

  @override
  String get processedInvestigations => 'Processed Investigations';

  @override
  String get annual => 'Annual';

  @override
  String get sick => 'Sick';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get emergency => 'Emergency';

  @override
  String get compensation => 'Compensation';

  @override
  String get compensationNotEnoughBalance =>
      'Compensation (not enough balance)';

  @override
  String get annualNotEnoughBalance => 'Annual (not enough balance)';

  @override
  String get annualHasOvertime => 'Annual (you have overtime balance)';

  @override
  String get numOfHours => 'Number of Hours';

  @override
  String get emergencyMaxOneDay => 'Emergency leave cannot exceed 1 day.';

  @override
  String get emergencyNotEnoughBalance =>
      'You do not have enough emergency leave balance.';

  @override
  String get emergencyRequiresAnnual =>
      'You must have annual leave balance to request emergency leave.';

  @override
  String get requestMissingPunching => 'Request Missing Punching';

  @override
  String get requestMissingPunchingSubmittedSuccessfully =>
      'Missing punching request submitted successfully';

  @override
  String get time => 'Time';

  @override
  String get missingPunching => 'Missing Punch';

  @override
  String get noMissingPunchingRequestsFound =>
      'No missing punching requests found';

  @override
  String get missingPunchingRequests => 'Missing Punching Requests';

  @override
  String get missingPunchingRequestDetails =>
      'Missing Punching Request Details';

  @override
  String get requestBusinesstrip => 'Request Business Trip';

  @override
  String get businessTrip => 'Business Trip';

  @override
  String get noBusinessTripRequestsFound => 'No business trip requests found';

  @override
  String get other => 'Other';

  @override
  String get businessTripSubmittedSuccessfully =>
      'Business trip request submitted successfully';

  @override
  String get riverside => 'RIVERSIDE';

  @override
  String get riversidePark => 'RIVERSIDE PARK';

  @override
  String get northSquare => 'NORTH SQUARE';

  @override
  String get transportationFeesEligible =>
      'This location is eligible for transportation fees.';

  @override
  String get requestTransportationFees => 'Request transportation fees';

  @override
  String get transportationFeeAmount => 'Transportation fee amount';

  @override
  String get transportationFeeAmountRequired => 'Please enter a valid amount.';

  @override
  String get editTransportationFeeAmount => 'Edit transportation fee amount';

  @override
  String get egp => 'EGP';

  @override
  String get sameDayMissingPunchWarning =>
      'A missing punch request exists on the same day.';

  @override
  String get sameDayBusinessTripWarning =>
      'A business trip request exists on the same day.';

  @override
  String get holidays => 'Holidays';

  @override
  String get compensatedHours => 'Compensated Hours';

  @override
  String get reasonDetails => 'Reason Description';

  @override
  String get missingPunchBalance => 'Missing Punch Balance';

  @override
  String get employeeBalances => 'Employee Balances';

  @override
  String get annualLeave => 'Annual Leave';

  @override
  String get dayAbbr => 'd';

  @override
  String get hourAbbr => 'h';

  @override
  String get filterByMonth => 'Filter by Month';

  @override
  String get chooseMonth => 'Choose Month';

  @override
  String get employees => 'Employees';

  @override
  String get requestsReport => 'Requests Report';

  @override
  String get employeeRequestsReport => 'Employee Requests Report';

  @override
  String get overallSummary => 'Overall Summary';

  @override
  String get totalRequests => 'Total Requests';

  @override
  String get pendingRequests => 'Pending Requests';

  @override
  String get myInProcessRequests => 'In-Process Requests';

  @override
  String get myRecentlyProcessedRequests => 'Recently Processed Requests';

  @override
  String get total => 'Total';

  @override
  String get leaveRequests => 'Leave Requests';

  @override
  String get overtimeRequests => 'Overtime Requests';

  @override
  String get businessTripRequests => 'Business Trip Requests';

  @override
  String get missingPunchRequests => 'Missing Punch Requests';

  @override
  String get noRequestsMessage =>
      'This employee has not submitted any requests yet.';

  @override
  String andMoreRequests(int count) {
    return '$count more requests';
  }

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get unknown => 'Unknown';

  @override
  String get detailsNotAvailable => 'Details not available';

  @override
  String get leaveRequest => 'Leave Request';

  @override
  String get overtimeRequest => 'Overtime Request';

  @override
  String get businessTripRequest => 'Business Trip Request';

  @override
  String get missingPunchRequest => 'Missing Punch Request';

  @override
  String get request => 'Request';

  @override
  String get searchByName => 'Search by name or code';

  @override
  String get searchByNameOrCode => 'Search by name or code...';

  @override
  String get addEmployee => 'Add Employee';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get employeesList => 'Employees List';

  @override
  String get editEmployee => 'Edit Employee';

  @override
  String get edit => 'Edit';

  @override
  String get editPeriod => 'Edit Payment Period';

  @override
  String get updatedPeriod => 'Updated Payment Period';

  @override
  String get originalPeriod => 'Original Payment Period';

  @override
  String get unscheduledPayment => 'Unscheduled Payment';

  @override
  String get noEmployeesFoundMatching => 'No No employees found matching';

  @override
  String get noEmployeesYet => 'No employees yet';

  @override
  String get saveEmployee => 'Save employee';

  @override
  String get employeeAddedSuccessfully => 'Employee added successfully';

  @override
  String get employeeUpdatedSuccessfully => 'Employee updated successfully';

  @override
  String get suspendEmployee => 'Suspend Employee';

  @override
  String get unsuspendEmployee => 'Unsuspend Employee';

  @override
  String get workingDays => 'Working Days';

  @override
  String get leavesEligibility => 'Leaves Eligibility';

  @override
  String get shiftHours => 'Shift Hours';

  @override
  String get inType => 'In';

  @override
  String get outType => 'Out';

  @override
  String get filterRequests => 'Filter Requests';

  @override
  String get filterByRequestType => 'Filter by Request Type';

  @override
  String get allTypes => 'All Types';

  @override
  String get leaveRequestsFilter => 'Leave Requests';

  @override
  String get overtimeRequestsFilter => 'Overtime Requests';

  @override
  String get businessTripRequestsFilter => 'Business Trip Requests';

  @override
  String get missingPunchRequestsFilter => 'Missing Punch Requests';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get exportToCSV => 'Export to CSV';

  @override
  String get exportToXlsx => 'Export to Xlsx';

  @override
  String get exportByRequestType => 'By Request Type';

  @override
  String get exportByEmployee => 'By Employee';

  @override
  String downloadingFiles(int count) {
    return 'Downloading $count file(s)...';
  }

  @override
  String get csvExport => 'CSV Export';

  @override
  String get csvContentGenerated => 'CSV content generated successfully!';

  @override
  String get csvMobileInstructions =>
      'On mobile platforms, you can copy this content and save it as a .csv file.';

  @override
  String showingRequests(int filteredCount, int totalCount) {
    return 'Showing $filteredCount of $totalCount requests';
  }

  @override
  String get select => 'Select';

  @override
  String get selectMonth => 'Select Month';

  @override
  String get type => 'Type';

  @override
  String get fullName => 'Full Name';

  @override
  String get arabicName => 'Arabic Name';

  @override
  String get nationalId => 'National ID';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get address => 'Address';

  @override
  String get contactInfoUpdated => 'Contact info updated successfully';

  @override
  String get contactInfoUpdateFailed => 'Failed to update contact info';

  @override
  String get arabicNickname => 'Arabic Nickname';

  @override
  String get englishNickname => 'English Nickname';

  @override
  String get email => 'Email';

  @override
  String get jobTitleInArabic => 'Job Title in Arabic';

  @override
  String get jobTitleInEnglish => 'Job Title in English';

  @override
  String get employeeCode => 'Employee Code';

  @override
  String get loginCode => 'Login Code';

  @override
  String get directManager => 'Direct Manager';

  @override
  String get managersManager => 'Manager\'s Manager';

  @override
  String get loading => 'Loading...';

  @override
  String get loadingEmployeeRequests => 'Loading requests...';

  @override
  String get addingEmployees => 'Adding...';

  @override
  String get employeeId => 'Employee ID';

  @override
  String get pleaseEnterEmployeeName => 'Please enter employee name';

  @override
  String get pleaseEnterArabicName => 'Please enter Arabic name';

  @override
  String get pleaseEnterJobTitle => 'Please enter job title';

  @override
  String get pleaseEnterEmployeeCode => 'Please enter employee code';

  @override
  String get pleaseEnterLoginCode => 'Please enter login code';

  @override
  String get pleaseEnterHireDate => 'Please enter Hire Date';

  @override
  String get pleaseEnterN1Manager => 'Please enter N+1 manager';

  @override
  String get pleaseEnterN2Manager => 'Please enter N+2 manager';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email address';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get noEmployeeFound => 'No employee found with this code';

  @override
  String get unsavedChanges => 'Unsaved Changes';

  @override
  String get unsavedChangesMessage =>
      'You have unsaved changes. Are you sure you want to leave?';

  @override
  String get stay => 'Stay';

  @override
  String get leave => 'Leave';

  @override
  String get departmentInArabic => 'Department in Arabic';

  @override
  String get departmentInEnglish => 'Department in English';

  @override
  String get pleaseSelectDepartment => 'Please select a department';

  @override
  String get pleaseSelectLocation => 'Please select a location';

  @override
  String get pleaseSelectCostCenter => 'Please select cost center';

  @override
  String get costCenter => 'Cost Center';

  @override
  String get topManagement => 'Top Management';

  @override
  String get financialDepartment => 'Financial Department';

  @override
  String get receptionDepartment => 'Reception Department';

  @override
  String get administrativeAffairs => 'Administrative Affairs';

  @override
  String get eventsDepartment => 'Events Department';

  @override
  String get marketingDepartment => 'Marketing Department';

  @override
  String get leasingDepartment => 'Leasing Department';

  @override
  String get licenseDepartment => 'Regulatory affairs & Licensing solutions';

  @override
  String get maintenanceDepartment => 'Maintenance Department';

  @override
  String get projectsDepartment => 'Projects Department';

  @override
  String get legalDepartment => 'Legal Department';

  @override
  String get operationsDepartment => 'Operations Department';

  @override
  String get safetyDepartment => 'Safety Department';

  @override
  String get prDepartment => 'PR Department';

  @override
  String get purchasingDepartment => 'Purchasing Department';

  @override
  String get cashierDepartment => 'Cashier Department';

  @override
  String get humanResourcesDepartment => 'Human Resources Department';

  @override
  String get itDepartment => 'IT Department';

  @override
  String get warehousesDepartment => 'Warehouses Department';

  @override
  String get collectionDepartment => 'Collection Department';

  @override
  String get pleaseEnterValidNumber => 'Please enter a valid number';

  @override
  String get pleaseEnterValidEmployeeCode =>
      'Please enter a valid employee code';

  @override
  String get pleaseEnterValidN1ManagerCode =>
      'Please enter a valid N+1 manager code';

  @override
  String get pleaseEnterValidN2ManagerCode =>
      'Please enter a valid N+2 manager code';

  @override
  String get pleaseSelectShiftHours => 'Please select shift hours';

  @override
  String get pleaseSelectWorkingDays => 'Please select working days';

  @override
  String get pleaseSelectLeavesEligibility =>
      'Please select leaves eligibility';

  @override
  String get n1DirectManagerCode => 'N+1 (Direct Manager) Code';

  @override
  String get n2ManagersManagerCode => 'N+2 (Manager\'s Manager) Code';

  @override
  String get licensingDepartment => 'Regulatory affairs & Licensing solutions';

  @override
  String get internalSecurity => 'Internal Security';

  @override
  String get filterByDateRange => 'Filter by Date Range';

  @override
  String get dateFilterEffective => 'Effective Date';

  @override
  String get dateFilterCreated => 'Created Date';

  @override
  String get filterByRequestStatus => 'Filter by Request Status';

  @override
  String get filterByUser => 'Filter By User';

  @override
  String get allStatuses => 'All Statuses';

  @override
  String get pendingStatus => 'Pending';

  @override
  String get approvedStatus => 'Approved';

  @override
  String get declinedStatus => 'Declined';

  @override
  String get waitingStatus => 'Waiting';

  @override
  String get submittedStatus => 'Submitted';

  @override
  String get acceptedStatus => 'Accepted';

  @override
  String get rejectedStatus => 'Rejected';

  @override
  String get cancelledStatus => 'Cancelled';

  @override
  String get completedStatus => 'Completed';

  @override
  String get requestType => 'Request Type';

  @override
  String get overtimeType => 'Overtime Type';

  @override
  String get missingpunchType => 'Missing Punch Type';

  @override
  String get clear => 'Clear';

  @override
  String get selectDepartments => 'Select Departments';

  @override
  String get departmentsSelected => 'departments selected';

  @override
  String get addEmployees => 'Add Employees';

  @override
  String get filteredBy => 'Filtered By';

  @override
  String get employee => 'Employee';

  @override
  String get employeewithAl => 'Employee';

  @override
  String get employeesWithoutAl => 'Employees';

  @override
  String get investigation => 'Investigation';

  @override
  String get investigations => 'Investigations';

  @override
  String get investigationDetails => 'Investigation Details';

  @override
  String get employeeCount => 'Employee Count';

  @override
  String get numOfDays => 'Num Of Days';

  @override
  String get advanceOnSalary => 'Advance on Salary';

  @override
  String get advanceOnSalaryRequests => 'Advance on Salary Requests';

  @override
  String get advanceOnSalaryRequest => 'Advance on Salary Request';

  @override
  String get advanceOnSalarySubmittedSuccessfully =>
      'Advance on salary request submitted successfully';

  @override
  String get advanceOnSalaryRequestTitle => 'Advance on Salary Request';

  @override
  String browseAllManagedEmployees(int count) {
    return 'Browse All Managed Employees ($count)';
  }

  @override
  String get directEmployees => 'Direct Employees';

  @override
  String get indirectEmployees => 'First Level Indirect';

  @override
  String get allSubordinates => 'Downline Employees';

  @override
  String browseAllIndirectEmployees(int count) {
    return 'Browse First Level Indirect Employees ($count)';
  }

  @override
  String browseAllSubordinates(int count) {
    return 'Browse Downline Employees ($count)';
  }

  @override
  String get mandatoryPasswordChange => 'Mandatory Password Change';

  @override
  String get weakPasswordMessage =>
      'Your current password is weak and must be changed for security reasons. You cannot access the system until you update your password.';

  @override
  String get weakPasswordError =>
      'Password can\'t be 123456. Please choose a stronger password.';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters long.';

  @override
  String get passwordRequirements =>
      'Password requirements:\n• Must be at least 8 characters long\n• Must contain at least one uppercase letter (A-Z)\n• Must contain at least one lowercase letter (a-z)\n• Must contain at least one digit (0-9)\n• Must contain at least one special character (!@#\$%^&*)\n• Can\'t be 123456\n• Different from your current password';

  @override
  String get passwordTooShortNew =>
      'Password must be at least 8 characters long';

  @override
  String get passwordMissingUppercase =>
      'Password must contain at least one uppercase letter';

  @override
  String get passwordMissingLowercase =>
      'Password must contain at least one lowercase letter';

  @override
  String get passwordMissingDigit => 'Password must contain at least one digit';

  @override
  String get passwordMissingSpecialChar =>
      'Password must contain at least one special character (!@#\$%^&*)';

  @override
  String get passwordComplexityError =>
      'Password does not meet complexity requirements';

  @override
  String get unableToVerifyCurrentDate => 'Unable to verify current date';

  @override
  String get checkInternetConnectionAndRetry =>
      'Please check your internet connection and try again';

  @override
  String get hireDate => 'Hire Date';

  @override
  String get notAvailable => 'Not available';

  @override
  String get amountInLetters => 'Amount in Letters';

  @override
  String get willBeCalculated => 'Will be calculated';

  @override
  String get paymentEndDate => 'Payment End Date';

  @override
  String get monthlyPayment => 'Monthly Payment';

  @override
  String get newMonthlyPayment => 'New Monthly Payment';

  @override
  String get searchByNameOrCodeHint => 'Search By Name Or Code';

  @override
  String get amountRequestedEgp => 'Amount Requested (EGP) *';

  @override
  String get enterAmountBetween => 'Enter amount between 500 and 20,000 EGP';

  @override
  String get periodInMonths => 'Period in Months *';

  @override
  String get enterPeriodBetween => 'Enter period between 1 and 12 months';

  @override
  String get paymentStartDate => 'Payment Start Date';

  @override
  String get mustBeOnFirstDay =>
      'Must be on the 1st day, 1 or 2 months from now';

  @override
  String get requestsCantBeSubmitted =>
      'Requests can\'t be submitted at this time';

  @override
  String get submissionWindowMessage =>
      'The submission window is open only from the 15th to the 25th of each month';

  @override
  String get notEligibleForAdvance => 'Not Eligible for Advance on Salary';

  @override
  String get tenureLessThanSixMonths => 'Since tenure is less than six months';

  @override
  String get currentAdvanceOnSalaryRequest =>
      'Since Employee has a current advance on salary';

  @override
  String get newEmployeePeriodRestriction =>
      'For employees with less than 1 year tenure, the period is automatically set to 1 month only';

  @override
  String get newEmployeePaymentStartRestriction =>
      'For employees with less than 1 year tenure, the payment start date is automatically set to next month';

  @override
  String advanceEligibilityDateRestriction(String eligibilityDate) {
    return 'This employee will be eligible for advance on salary starting from $eligibilityDate';
  }

  @override
  String get pendingRequestExists => 'Pending Request Exists';

  @override
  String get pendingRequestMessage =>
      'This employee already has a pending advance on salary request. Please wait for the current request to be processed before submitting a new one.';

  @override
  String get checkingPendingRequests => 'Checking for pending requests...';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get cancelRequest => 'Cancel Request';

  @override
  String get confirmCancelRequest => 'Confirm Cancel Request';

  @override
  String get cancelRequestMessage =>
      'Are you sure you want to cancel this request? This action cannot be undone.';

  @override
  String get requestCancelledSuccessfully => 'Request cancelled successfully';

  @override
  String get cancelling => 'Cancelling...';

  @override
  String get errorCancellingRequest => 'Error cancelling request';

  @override
  String get requestCancellation => 'Cancellation Request';

  @override
  String get leaveCancellationRequests => 'Leave Cancellation Requests';

  @override
  String get leaveCancellationRequest => 'Leave Cancellation Request';

  @override
  String get cancellationRequestMessage =>
      'This will create a cancellation request that requires approval from your manager and HR. Please provide a reason:';

  @override
  String get cancellationRequestSubmittedSuccessfully =>
      'Cancellation request submitted successfully';

  @override
  String get errorSubmittingCancellationRequest =>
      'Error submitting cancellation request';

  @override
  String get remove => 'Remove';

  @override
  String get confirmRemoveRequest => 'Confirm Remove Request';

  @override
  String get removeRequestMessage =>
      'Are you sure you want to remove this request from the list?';

  @override
  String get requestRemovedSuccessfully => 'Request removed successfully';

  @override
  String get removing => 'Removing...';

  @override
  String get errorRemovingRequest => 'Error removing request';

  @override
  String get selectPaymentStartDate => 'Select Payment Start Date';

  @override
  String get pleaseFillAllRequiredFields =>
      'Please fill in all required fields';

  @override
  String get myAdvanceOnSalaryRequests => 'My Advance on Salary Requests';

  @override
  String get teamAdvanceOnSalaryRequests => 'Team Advance on Salary Requests';

  @override
  String get searchByNameCodeOrAmount => 'Search by name, code or amount';

  @override
  String get allStatus => 'All Status';

  @override
  String get allMonths => 'All Months';

  @override
  String get groupHr => 'HR';

  @override
  String get groupFinance => 'Finance';

  @override
  String get groupLegal => 'Legal';

  @override
  String get groupTopManagement => 'Top Management';

  @override
  String get groupIt => 'IT';

  @override
  String get groupDashboard => 'Dashboard';

  @override
  String get perPage => 'Per Page';

  @override
  String get sortBy => 'Sort by:';

  @override
  String get dateCreated => 'Date Created';

  @override
  String get period => 'Period';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get refresh => 'Refresh';

  @override
  String get refreshing => 'Refreshing...';

  @override
  String get retry => 'Retry';

  @override
  String get noRequestsFound => 'No requests found';

  @override
  String get noNewUpdates => 'No new updates';

  @override
  String get tryAdjustingSearchFilters =>
      'Try adjusting your search or filters';

  @override
  String showingRequestsOfTotal(int showing, int total) {
    return 'Showing $showing of $total requests';
  }

  @override
  String get requestor => 'Requestor';

  @override
  String get borrower => 'Borrower';

  @override
  String get amountRequested => 'Amount Requested';

  @override
  String get createdAt => 'Created At';

  @override
  String get currentApprover => 'Current Approver';

  @override
  String get n2Manager => 'N+2';

  @override
  String get hrDepartment => 'HR';

  @override
  String get financeDepartment => 'Finance';

  @override
  String get paymentStartDateLabel => 'Payment Start Date';

  @override
  String get paymentEndDateLabel => 'Payment End Date';

  @override
  String get monthlyPaymentLabel => 'Monthly Payment';

  @override
  String get month => 'Month';

  @override
  String get months => 'months';

  @override
  String get declining => 'Declining...';

  @override
  String get approving => 'Approving...';

  @override
  String pageOfPages(int current, int total) {
    return 'Page $current of $total';
  }

  @override
  String get previousPage => 'Previous Page';

  @override
  String get nextPage => 'Next Page';

  @override
  String get requestApprovedSuccessfully => 'Request approved successfully';

  @override
  String failedToApproveRequest(String error) {
    return 'Failed to approve request: $error';
  }

  @override
  String get requestDeclinedSuccessfully => 'Request declined successfully';

  @override
  String get requestPutOnHoldSuccessfully => 'Request put on hold successfully';

  @override
  String failedToDeclineRequest(String error) {
    return 'Failed to decline request: $error';
  }

  @override
  String failedToPutOnHoldRequest(String error) {
    return 'Failed to put request on hold: $error';
  }

  @override
  String errorLoadingRequests(String error) {
    return 'Error loading requests: $error';
  }

  @override
  String get approvalConfirmation => 'Approval Confirmation';

  @override
  String get requestDetails => 'Request Details';

  @override
  String get requestId => 'Request ID';

  @override
  String get declineRequest => 'Decline Request';

  @override
  String get provideDeclinereason =>
      'Please provide a reason for declining this request:';

  @override
  String get enterDeclineReason => 'Enter decline reason...';

  @override
  String get pleaseEnterDeclineReason => 'Please enter a decline reason';

  @override
  String get confirmApproval => 'Confirm Approval';

  @override
  String get confirming => 'Confirming...';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get amount => 'Amount';

  @override
  String get previewPdf => 'Preview PDF';

  @override
  String get printPdf => 'Print PDF';

  @override
  String get printing => 'Printing...';

  @override
  String get downloading => 'Downloading...';

  @override
  String get generatePdf => 'Generate PDF';

  @override
  String get pdfActions => 'PDF Actions';

  @override
  String get pdfNotAvailable => 'PDF not available yet';

  @override
  String get pdfGeneratedWhenApproved =>
      'PDF will be generated when the request is fully approved by Finance';

  @override
  String get downloadPdf => 'Download PDF';

  @override
  String pdfDownloadedSuccessfully(String filePath) {
    return 'PDF downloaded successfully to $filePath';
  }

  @override
  String failedToDownloadPdf(String error) {
    return 'Failed to download PDF: $error';
  }

  @override
  String get unsettled => 'Unsettled';

  @override
  String get settled => 'Settled';

  @override
  String get settle => 'Settle';

  @override
  String get settling => 'Settling...';

  @override
  String get manuallySettled => 'Manually Settled';

  @override
  String get settledBy => 'Settled By';

  @override
  String get settlementDate => 'Settlement Date';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get confirmSettlement => 'Confirm Settlement';

  @override
  String get confirmSettlementMessage =>
      'Are you sure you want to settle this advance on salary request? This action cannot be undone.';

  @override
  String get settlementWarning =>
      'This will mark the request as manually settled and update the borrower\'s eligibility date to today.';

  @override
  String get confirmSettle => 'Confirm Settle';

  @override
  String get confirmSubmitRequest => 'Confirm Submit Request';

  @override
  String get areYouSureToSubmitRequest =>
      'Are you sure you want to submit this advance on salary request?';

  @override
  String get areYouSureToSubmitDisciplinaryRequest =>
      'Are you sure you want to submit this disciplinary action request?';

  @override
  String get requestSettledSuccessfully => 'Request settled successfully';

  @override
  String failedToSettleRequest(String error) {
    return 'Failed to settle request: $error';
  }

  @override
  String get confirmPasswordDoesNotMatch =>
      'Confirm password does not match new password';

  @override
  String get oldPasswordIncorrect => 'Old password is incorrect';

  @override
  String get updatePasswordFailed => 'Update password failed';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get invalidCredentials =>
      'Invalid employee code or password. Please try again.';

  @override
  String get emailNotConfirmed =>
      'Email not confirmed. Please check your email.';

  @override
  String get tooManyRequests =>
      'Too many login attempts. Please try again later.';

  @override
  String get signupFailed => 'Signup failed';

  @override
  String get weakPassword =>
      'Password can\'t be 123456. Please choose a stronger password.';

  @override
  String get samePassword => 'New password must be different from old password';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get accountSuspended => 'Your account is suspended.';

  @override
  String get employeeCodeOnlyNumbers =>
      'Employee code must contain only numbers';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String reasonMinLength(Object min) {
    return 'Reason must be at least $min characters';
  }

  @override
  String get advanceOnSalaryRequestsFilter => 'Advance on Salary Requests';

  @override
  String get groupManagement => 'Group Management';

  @override
  String get addToGroup => 'Add to Group';

  @override
  String get addGroup => 'Add Group';

  @override
  String get groups => 'Groups';

  @override
  String userAlreadyInGroup(String group) {
    return 'User is already in $group group';
  }

  @override
  String successfullyAddedUserToGroup(String group) {
    return 'Successfully added user to $group group';
  }

  @override
  String failedToAddUserToGroup(String error) {
    return 'Failed to add user to group: $error';
  }

  @override
  String get removeFromGroup => 'Remove from Group';

  @override
  String successfullyRemovedUserFromGroup(String group) {
    return 'Successfully removed user from $group group';
  }

  @override
  String failedToRemoveUserFromGroup(String error) {
    return 'Failed to remove user from group: $error';
  }

  @override
  String userNotInGroup(String group) {
    return 'User is not in $group group';
  }

  @override
  String get currentGroups => 'Current Groups';

  @override
  String get none => 'None';

  @override
  String get back => 'Back';

  @override
  String get selectEmployee => 'Select Employee';

  @override
  String get selectedEmployee => 'Selected Employee';

  @override
  String get clearSelection => 'Clear Selection';

  @override
  String get jobTitle => 'Job Title';

  @override
  String get disciplinaryAction => 'Disciplinary Action';

  @override
  String get disciplinaryActionRequest => 'Disciplinary Action Request';

  @override
  String get disciplinaryActionRequests => 'Disciplinary Action Requests';

  @override
  String get myDisciplinaryActionRequests => 'My Disciplinary Action Requests';

  @override
  String get teamDisciplinaryActionRequests =>
      'Team Disciplinary Action Requests';

  @override
  String get processedDisciplinaryActionRequests =>
      'Processed Disciplinary Action Requests';

  @override
  String get disciplinaryActionType => 'Disciplinary Action Type';

  @override
  String get actionType => 'Action Type';

  @override
  String get selectActionType => 'Select Action Type';

  @override
  String get verbalRemark => 'Verbal Remark';

  @override
  String get writtenRemark => 'Written Remark';

  @override
  String get writtenWarning => 'Written Warning';

  @override
  String get selectEmployees => 'Select Employees';

  @override
  String get selectedEmployees => 'Selected Employees';

  @override
  String get clearAll => 'Clear All';

  @override
  String get removeEmployee => 'Remove Employee';

  @override
  String get browseAllEmployees => 'Browse All Employees';

  @override
  String get pleaseSelectAtLeastOneEmployee =>
      'Please select at least one employee';

  @override
  String get incidentDescription => 'Incident Description';

  @override
  String get describeIncident => 'Please describe the incident in detail';

  @override
  String get violationDate => 'Violation Date';

  @override
  String get selectDate => 'Select Date';

  @override
  String get writtenWarningOptions => 'Written Warning Options';

  @override
  String get deductDays => 'Deduct Days';

  @override
  String get quarterDay => '1/4 Day';

  @override
  String get halfDay => '1/2 Day';

  @override
  String get selectDeductDays => 'Select deduct days';

  @override
  String get additionalInformation => 'Additional Information';

  @override
  String get witnessStatements => 'Witness Statements';

  @override
  String get recommendedAction => 'Recommended Action';

  @override
  String get optional => '(Optional)';

  @override
  String get reset => 'Reset';

  @override
  String get requestSubmittedSuccessfully => 'Request submitted successfully';

  @override
  String get searchEmployee => 'Search Employee';

  @override
  String get orSelectFromList => 'Or select from list';

  @override
  String get terminationWarning => 'Termination Warning';

  @override
  String get searchRequests => 'Search requests...';

  @override
  String get sortAscending => 'Sort Ascending';

  @override
  String get sortDescending => 'Sort Descending';

  @override
  String get enterReason => 'Enter reason...';

  @override
  String get pleaseEnterReason => 'Please enter a reason';

  @override
  String get pleaseEnterApprovalReason => 'Please enter approval reason';

  @override
  String get pleaseEnterHoldReason => 'Please enter hold reason';

  @override
  String get pleaseEnterInvestigationReason =>
      'Please enter investigation reason';

  @override
  String get approvalReason => 'Approval Reason';

  @override
  String get holdReason => 'Hold Reason';

  @override
  String get investigationReason => 'Investigation Reason';

  @override
  String get sendToHrInvestigation => 'Send to HR for Investigation';

  @override
  String get sendingToHrInvestigation => 'Sending to HR for Investigation...';

  @override
  String get sentToHrInvestigationSuccessfully =>
      'Request sent to HR for investigation successfully';

  @override
  String failedToSendToHrInvestigation(String error) {
    return 'Failed to send to HR for investigation: $error';
  }

  @override
  String get editWrittenWarning => 'Edit Written Warning';

  @override
  String get editDeductDays => 'Edit Deduct Days';

  @override
  String get editSuspensionDays => 'Edit Suspension Days';

  @override
  String get writtenWarningUpdatedSuccessfully =>
      'Written warning options updated successfully';

  @override
  String failedToUpdateWrittenWarning(String error) {
    return 'Failed to update written warning: $error';
  }

  @override
  String get errorPrefix => 'Error';

  @override
  String employeeTerminationWarningMessage(int warningCount) {
    return 'This employee has $warningCount written warnings in the last 6 months.';
  }

  @override
  String get deductDaysHint => '1-5';

  @override
  String get suspensionDaysHint => '1-7';

  @override
  String get suspensionDays => 'Suspension Days';

  @override
  String get pleaseSelectEmployee => 'Please select an employee';

  @override
  String get pleaseSelectActionType =>
      'Please select a disciplinary action type';

  @override
  String get pleaseProvideIncidentDetails => 'Please provide incident details';

  @override
  String get incidentDescriptionTooShort =>
      'Incident description must be at least 10 words';

  @override
  String get pleaseSelectViolationDate => 'Please select the violation date';

  @override
  String get violationDateFuture => 'Violation date cannot be in the future';

  @override
  String get violationDateTooOld =>
      'Violation date cannot be more than 30 days ago';

  @override
  String get deductDaysRange => 'Deduction days must be between 1 and 5';

  @override
  String get suspensionDaysRange => 'Suspension days must be between 1 and 7';

  @override
  String get save => 'Save';

  @override
  String get saving => 'Saving...';

  @override
  String get enterDaysBetween1And5 => 'Enter days between 1-5';

  @override
  String get enterSuspensionDaysBetween1And7 =>
      'Enter suspension days between 1-7';

  @override
  String get employeeConfirmationRequired => 'Employee Confirmation Required';

  @override
  String get financeHasEditedPaymentPeriod =>
      'Finance has edited the payment period for your advance on salary request. Please review and confirm or cancel the request.';

  @override
  String get confirmFinanceEdit => 'Confirm Changes';

  @override
  String get cancelFinanceEdit => 'Cancel Request';

  @override
  String get confirmingChanges => 'Confirming Changes...';

  @override
  String get cancellingRequest => 'Cancelling Request...';

  @override
  String get changesConfirmedSuccessfully => 'Changes confirmed successfully';

  @override
  String failedToConfirmChanges(String error) {
    return 'Failed to confirm changes: $error';
  }

  @override
  String failedToCancelRequest(String error) {
    return 'Failed to cancel request: $error';
  }

  @override
  String get financeAcknowledgmentRequired => 'Finance Acknowledgment Required';

  @override
  String get employeeHasRespondedToFinanceEdit =>
      'Employee has responded to the finance edit. Please acknowledge their decision.';

  @override
  String get acknowledgeEmployeeDecision => 'Acknowledge Decision';

  @override
  String get acknowledgingDecision => 'Acknowledging Decision...';

  @override
  String get decisionAcknowledgedSuccessfully =>
      'Decision acknowledged successfully';

  @override
  String failedToAcknowledgeDecision(String error) {
    return 'Failed to acknowledge decision: $error';
  }

  @override
  String get employeeConfirmed => 'Employee Confirmed';

  @override
  String get employeeCancelled => 'Employee Cancelled';

  @override
  String get pendingEmployeeConfirmation => 'Pending Employee Confirmation';

  @override
  String get pendingFinanceAcknowledgment => 'Pending Finance Acknowledgment';

  @override
  String get employeeConfirmationRequests => 'My Advance on Salary Requests';

  @override
  String get orgChart => 'Org Chart';

  @override
  String get businessTripCancellationRequest =>
      'Business Trip Cancellation Request';

  @override
  String get businessTripCancellationRequests =>
      'Business Trip Cancellation Requests';

  @override
  String get firstLineManager => 'First Line Manager';

  @override
  String get secondLineManager => 'Second Line Manager';

  @override
  String get approvedByN1 => 'Approved by N+1';

  @override
  String get approvedByN2 => 'Approved by N+2';

  @override
  String get approvedByHR => 'Approved by HR';

  @override
  String get approvedByFinance => 'Approved by Finance';

  @override
  String get approvedBy => 'Approved by';

  @override
  String get acknowledgedBy => 'Acknowledged by';

  @override
  String get completedBy => 'Completed by';

  @override
  String get declinedBy => 'Declined by';

  @override
  String get declinedByN1 => 'Declined by N+1';

  @override
  String get declinedByN2 => 'Declined by N+2';

  @override
  String get declinedByHR => 'Declined by HR';

  @override
  String get declinedByFinance => 'Declined by Finance';

  @override
  String get on => 'on';

  @override
  String get autoFillNicknameFromFullName => 'Auto-fill from full name';

  @override
  String get unavailableLeaveRequest => 'Unavailable: Leave Request';

  @override
  String get unavailableBusinessTrip => 'Unavailable: Business Trip';

  @override
  String get unavailableMissingPunch => 'Unavailable: Missing Punch Request';

  @override
  String get hoursRequiredDueToMissingPunch =>
      'Hours selection is required because a missing punch request exists on this date';

  @override
  String get leaveTypeAnnual => 'Annual';

  @override
  String get leaveTypeEmergency => 'Emergency';

  @override
  String get leaveTypeSick => 'Sick';

  @override
  String get leaveTypeCompensation => 'Compensation';

  @override
  String get leaveTypeUnpaid => 'Unpaid';

  @override
  String get moreActions => 'More Actions';

  @override
  String get puttingOnHold => 'Putting on Hold...';

  @override
  String get investigating => 'Sending to Investigation...';

  @override
  String get confirm => 'Confirm';

  @override
  String get acknowledgeWithRemark => 'Acknowledge with Remark';

  @override
  String get confirmAcknowledgment => 'Confirm Acknowledgment';

  @override
  String get pleaseProvideYourRemarkOnThisAction =>
      'Please provide your remark on this action:';

  @override
  String get areYouSureYouWantToAcknowledgeThisRequest =>
      'Are you sure you want to acknowledge this disciplinary action request?';

  @override
  String get yourRemark => 'Your Remark';

  @override
  String get enterYourRemark => 'Enter your remark here...';

  @override
  String get pleaseProvideARemark => 'Please provide a remark';

  @override
  String get acknowledgmentWillMoveRequestToApprovalWorkflow =>
      'By acknowledging, this request will proceed to the approval workflow.';

  @override
  String get acknowledge => 'Acknowledge';

  @override
  String get employeeAcknowledged => 'Employee Acknowledged';

  @override
  String get autoEscalated => 'Auto-Escalated (No Response from Employee)';

  @override
  String get escalationDate => 'Escalation Date';

  @override
  String get acknowledgmentDate => 'Acknowledgment Date';

  @override
  String get acknowledgmentType => 'Acknowledgment Type';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get acknowledgedWithRemark => 'Acknowledged with Remark';

  @override
  String get employeeRemark => 'Employee Remark';

  @override
  String get acknowledging => 'Acknowledging...';

  @override
  String get requestAcknowledgedSuccessfully =>
      'Request acknowledged successfully';

  @override
  String get confirmAcknowledgmentMessage =>
      'Are you sure you want to acknowledge this disciplinary action request without providing a remark?';

  @override
  String get requiresYourAcknowledgment =>
      'Disciplinary action requires your acknowledgment';

  @override
  String get escalateToLegal => 'Escalate to Legal';

  @override
  String get legalInvestigation => 'Legal Investigation';

  @override
  String get legalEscalationReason => 'Legal Escalation Reason';

  @override
  String get provideEscalationReason =>
      'Please provide reason for legal escalation';

  @override
  String get uploadInvestigationPDF => 'Upload Investigation PDF';

  @override
  String get acknowledgeLegalRequest => 'Acknowledge Request';

  @override
  String get acknowledgeLegalRequestMessage =>
      'By acknowledging this request, you confirm that you have received it and will begin the legal investigation. This will stop reminder notifications.';

  @override
  String get legalAcknowledgedSuccessfully =>
      'Request acknowledged successfully';

  @override
  String get investigationPdfRequired => 'Investigation PDF is required';

  @override
  String get hrFinalDecision => 'HR Final Decision';

  @override
  String get terminateEmployee => 'Terminate Employee';

  @override
  String get enterSuspensionDays => 'Enter number of suspension days';

  @override
  String get closedAtHR => 'Closed at HR';

  @override
  String get escalatedToLegalSuccessfully =>
      'Request escalated to Legal successfully';

  @override
  String get investigationUploadedSuccessfully =>
      'Investigation uploaded successfully';

  @override
  String get hrFinalDecisionSubmittedSuccessfully =>
      'HR final decision submitted successfully';

  @override
  String get pendingLegalInvestigation => 'Pending Legal Investigation';

  @override
  String get legal => 'Legal';

  @override
  String get legalApprover => 'Legal Approver';

  @override
  String get investigationReport => 'Investigation Report';

  @override
  String get viewInvestigationReport => 'View Investigation Report';

  @override
  String get suspendedFor => 'Suspended for';

  @override
  String get terminationRecommended => 'Termination Recommended';

  @override
  String get suspensionPeriod => 'Suspension Period';

  @override
  String get suspensionStartDate => 'Suspension Start Date';

  @override
  String get suspensionEndDate => 'Suspension End Date';

  @override
  String get escalatingToLegal => 'Escalating to Legal...';

  @override
  String get uploading => 'Uploading...';

  @override
  String get approveFinal => 'Approve Final';

  @override
  String get declineFinal => 'Decline Final';

  @override
  String get pleaseSelectPdfFile => 'Please select a PDF file to upload';

  @override
  String get investigationPdfUploadedSuccessfully =>
      'Investigation PDF uploaded successfully';

  @override
  String get suspensionDaysRequired => 'Please enter suspension days';

  @override
  String get suspensionDaysMustBePositive =>
      'Suspension days must be greater than 0';

  @override
  String get confirmTermination =>
      'Are you sure you want to terminate this employee? This action is irreversible.';

  @override
  String get submittingFinalDecision => 'Submitting final decision...';

  @override
  String get legalInvestigationComplete => 'Legal Investigation Complete';

  @override
  String get makeHRFinalDecision => 'Make HR Final Decision';

  @override
  String get n2SendingForInvestigationReason =>
      '(N+2) has sent request for HR investigation for the following reason';

  @override
  String get attachDocuments => 'Attach Documents';

  @override
  String get uploadDocuments => 'Upload Documents';

  @override
  String get removeDocument => 'Remove';

  @override
  String get supportedFormats => 'Supported formats: PDF, JPG, PNG, DOC, DOCX';

  @override
  String get maxFilesReached => 'Maximum 5 files allowed';

  @override
  String get fileTooLarge => 'File size exceeds 10MB limit';

  @override
  String documentsAttached(int count) {
    return '$count document(s) attached';
  }

  @override
  String get attachments => 'Attachments';

  @override
  String get viewAttachment => 'View';

  @override
  String get loadingAttachments => 'Loading attachments...';

  @override
  String get noAttachments => 'No attachments';

  @override
  String get openAttachmentFailed => 'Failed to open attachment';

  @override
  String get violationCategory => 'Violation Category';

  @override
  String get selectViolationCategory => 'Select violation category';

  @override
  String get violation => 'Violation';

  @override
  String get selectViolation => 'Select violation';

  @override
  String get violationDescription => 'Violation Description';

  @override
  String get describeViolation => 'Describe the violation in detail';

  @override
  String get selectCategoryFirst => 'Please select a category first';

  @override
  String get categoryAttendance => 'Attendance';

  @override
  String get categoryConduct => 'Conduct';

  @override
  String get categoryPerformance => 'Performance';

  @override
  String get categorySafety => 'Safety';

  @override
  String get categoryPolicy => 'Policy';

  @override
  String get categoryOther => 'Other';

  @override
  String get pleaseSelectViolationCategory =>
      'Please select a violation category';

  @override
  String get pleaseSelectViolation => 'Please select a violation';

  @override
  String get pleaseDescribeViolation => 'Please describe the violation';

  @override
  String get violationDescriptionTooShort =>
      'Violation description must be at least 10 characters';

  @override
  String get settlementReview => 'Settlement Review';

  @override
  String get settlementReviewRequests => 'Settlement Notifications';

  @override
  String get sendNotification => 'Send Notification';

  @override
  String get sendAllNotifications => 'Send All';

  @override
  String get noSettlementReviewRequests =>
      'No settlement notifications pending';

  @override
  String get settlementNotificationSent =>
      'Settlement notification sent successfully';

  @override
  String get allNotificationsSent =>
      'All settlement notifications sent successfully';

  @override
  String get skipNotification => 'Skip';

  @override
  String get notificationSkipped => 'Notification skipped';

  @override
  String get reviewPdf => 'Review PDF';

  @override
  String get confirmSendAll => 'Confirm Send All';

  @override
  String confirmSendAllNotifications(Object count) {
    return 'Send $count settlement notifications?';
  }

  @override
  String get send => 'Send';

  @override
  String get readyForReview => 'Ready for Review';

  @override
  String get closed => 'Closed';

  @override
  String get recordDecision => 'Record Decision';

  @override
  String get hrDecision => 'HR Decision';

  @override
  String get legalReview => 'Legal Review';

  @override
  String get topManagementDecision => 'Top Management Decision';

  @override
  String get decisionHistory => 'Decision History';

  @override
  String get linkedActions => 'Linked Disciplinary Actions';

  @override
  String get takeAction => 'Take Disciplinary Action';

  @override
  String get noAction => 'No Action';

  @override
  String get suspend => 'Suspend';

  @override
  String get terminate => 'Terminate';

  @override
  String get confirmDecision => 'Confirm Decision';

  @override
  String get convertToDisciplinary => 'Convert to Disciplinary Action';

  @override
  String get decisionSummary => 'Decision Summary';

  @override
  String get decidedBy => 'Decided By';

  @override
  String get decidedAt => 'Decided At';

  @override
  String get reviewedBy => 'Reviewed By';

  @override
  String get employeeDecisions => 'Employee Decisions';

  @override
  String get legalOpinion => 'Legal Opinion';

  @override
  String get createActions => 'Create Disciplinary Actions';

  @override
  String get bulkCreation => 'Bulk Creation';

  @override
  String get createdFromInvestigation => 'Created from Investigation';

  @override
  String get convertedFromDisciplinary => 'Converted from Disciplinary Action';

  @override
  String get viewInvestigation => 'View Investigation';

  @override
  String get loadingEmployeeDetails => 'Loading employee details...';

  @override
  String get unknownEmployee => 'Unknown';

  @override
  String get finalDecision => 'Final Decision';

  @override
  String get uploadDecisionPdf => 'Upload Decision PDF';

  @override
  String get legalPdfRequired => 'Legal PDF is required to submit review';

  @override
  String get fromInvestigation => 'From Investigation';

  @override
  String get convertToInvestigation => 'Convert to Investigation';

  @override
  String get hrFinalDecisionAfterLegal =>
      'HR Final Decision (After Legal Review)';

  @override
  String get invalidApproverType => 'Invalid approver type';

  @override
  String get basicInformation => 'Basic Information';

  @override
  String get hrDecisions => 'HR Decisions';

  @override
  String get topManagementDecisions => 'Top Management Decisions';

  @override
  String get linkedDisciplinaryActions => 'Linked Disciplinary Actions';

  @override
  String get employeeName => 'Employee Name';

  @override
  String get uploaded => 'Uploaded';

  @override
  String escalatedFromDisciplinaryAction(Object id) {
    return 'Escalated from Disciplinary Action #$id';
  }

  @override
  String get createDisciplinaryActions => 'Create Disciplinary Actions';

  @override
  String get backToDetails => 'Back to Details';

  @override
  String get continueButton => 'Continue';

  @override
  String submitAll(Object count) {
    return 'Submit All ($count actions)';
  }

  @override
  String get acknowledgeInvestigation => 'Acknowledge Investigation';

  @override
  String get uploadLegalPdf => 'Upload Legal PDF';

  @override
  String get cleared => 'Cleared';

  @override
  String get verbalWarning => 'Verbal Warning';

  @override
  String get suspension => 'Suspension';

  @override
  String get termination => 'Termination';

  @override
  String get disciplinaryActionRequired => 'Disciplinary Action Required';

  @override
  String get pleaseSelectDecisionForAll =>
      'Please make a decision for all employees';

  @override
  String get escalateToLegalDepartment => 'Escalate to Legal Department';

  @override
  String get escalationReason => 'Escalation Reason';

  @override
  String get provideReasonForEscalation =>
      'Provide reason for legal escalation...';

  @override
  String get pleaseProvideEscalationReason =>
      'Please provide a reason for escalation';

  @override
  String investigationEscalatedToLegal(Object id) {
    return 'Investigation #$id escalated to Legal Department';
  }

  @override
  String get acknowledgeInvestigationMessage =>
      'This will stop email reminders for this investigation. The investigation will remain assigned to Legal until you upload the investigation PDF.';

  @override
  String get acknowledgeInvestigationNote =>
      'Note: You must upload the investigation PDF to return this case to HR.';

  @override
  String investigationAcknowledged(Object id) {
    return 'Investigation #$id acknowledged. Email reminders stopped.';
  }

  @override
  String get uploadLegalPdfTitle => 'Upload Legal PDF';

  @override
  String uploadPdfConfirmation(Object id) {
    return 'Upload this PDF for Investigation #$id?';
  }

  @override
  String get afterUploadingReturnToHr =>
      'After uploading, this investigation will be returned to HR.';

  @override
  String pdfUploadedReturnedToHr(Object id) {
    return 'PDF uploaded. Investigation #$id returned to HR.';
  }

  @override
  String get errorCouldNotReadFile => 'Error: Could not read file';

  @override
  String escalatedOn(Object date) {
    return 'Escalated on: $date';
  }

  @override
  String get acknowledgedByLegal => 'Acknowledged by Legal';

  @override
  String get pendingAcknowledgment => 'Pending acknowledgment';

  @override
  String get viewInvestigationReportPdf => 'View Investigation Report (PDF)';

  @override
  String get viewLegalInvestigationReportPdf =>
      'View Legal Investigation Report (PDF)';

  @override
  String get pdfOpeningNotImplemented =>
      'PDF opening functionality will be implemented soon';

  @override
  String daNumber(Object id) {
    return 'DA #$id';
  }

  @override
  String get decision => 'Decision';

  @override
  String get autoEscalateWarning =>
      'Suspend or Terminate decisions will automatically escalate to Top Management for review';

  @override
  String investigationNumber(Object id) {
    return 'Investigation #$id';
  }

  @override
  String get legalReviewCompleted => 'Legal Review Completed';

  @override
  String get legalReviewCompletedMessage =>
      'Legal has reviewed this investigation. You can now make final decisions.';

  @override
  String get viewLegalPdf => 'View Legal PDF';

  @override
  String get bulkCreationInstruction =>
      'Select the disciplinary action type for each employee. Violation details will be copied from the investigation.';

  @override
  String get employeeActionTypes => 'Employee Action Types';

  @override
  String get attachmentsOptional => 'Attachments (Optional)';

  @override
  String get attachmentsWillBeAddedToAll =>
      'These attachments will be added to all created disciplinary actions';

  @override
  String creatingActionsFromInvestigation(
    Object actions,
    Object count,
    Object id,
  ) {
    return 'Creating $count disciplinary $actions from Investigation #$id';
  }

  @override
  String get actions => 'actions';

  @override
  String get enterLegalOpinion =>
      'Enter your legal opinion and recommendations...';

  @override
  String get legalOpinionRequired => 'Legal opinion is required';

  @override
  String get legalDocument => 'Legal Document';

  @override
  String get required => 'REQUIRED';

  @override
  String get legalPdfMandatory => '* Legal PDF is mandatory to complete review';

  @override
  String get reviewHrDecisions =>
      'Review the decisions made by HR for each employee';

  @override
  String get afterSubmittingReturnedToHr =>
      'After Legal Review, this investigation will be returned to HR for final decisions';

  @override
  String get submitLegalReview => 'Submit Legal Review';

  @override
  String get hrDecisionsReadOnly => 'HR Decisions';

  @override
  String get legalReviewSubmittedSuccess =>
      'Legal review submitted successfully';

  @override
  String get errorSubmittingReview => 'Error submitting legal review';

  @override
  String get reviewSuspendTerminateDecisions =>
      'Review employees with Suspend or Terminate decisions';

  @override
  String employeesRequireReview(Object count) {
    return '$count employees require review';
  }

  @override
  String get noEmployeesRequireTmReview =>
      'No employees require Top Management review';

  @override
  String get tmDecision => 'TM Decision';

  @override
  String get convertToDisciplinaryAction => 'Convert to Disciplinary Action';

  @override
  String get originalHrDecision => 'Original HR Decision';

  @override
  String get tmDecisionOptional => 'Top Management Decision (Optional PDF)';

  @override
  String get uploadTmPdf => 'Upload TM Decision PDF';

  @override
  String get uploadPdfOptional => 'Upload PDF (Optional)';

  @override
  String get selectPdf => 'Select PDF';

  @override
  String get noFileSelected => 'No file selected';

  @override
  String get submitTmDecision => 'Submit TM Decision';

  @override
  String get tmDecisionSubmittedSuccess =>
      'Top Management decision submitted successfully';

  @override
  String get hrDecisionWillBeExecuted =>
      'HR decision will be executed as proposed';

  @override
  String get reasonMinimum25 => 'Reason must be at least 25 characters';

  @override
  String get upload => 'Upload';

  @override
  String get uploadDecisionPdfOptional => 'Upload Decision PDF (Optional)';

  @override
  String get choosePdfFiles => 'Choose PDF Files';

  @override
  String get filesSelected => 'file(s) selected';

  @override
  String get addAttachments => 'Add Attachments';

  @override
  String get chooseLegalPdfRequired => 'Choose Legal PDF';

  @override
  String get legalReviewRecordedSuccess =>
      'Legal review recorded successfully. Case returned to HR.';

  @override
  String get submitFinalDecision => 'Submit Final Decision';

  @override
  String get legalHasReviewedInvestigation =>
      'Legal has reviewed this investigation and provided documentation';

  @override
  String get converted => 'Converted';

  @override
  String get finalDecisionWarning =>
      'This is the final decision. Investigation will be closed after submission.';

  @override
  String duplicateFileSkipped(Object fileName) {
    return '$fileName was skipped (duplicate)';
  }

  @override
  String get daConvertedToInvestigation =>
      'Disciplinary Action Request converted to Investigation';

  @override
  String get convertedToInvestigation => 'Converted to Investigation';

  @override
  String get convertToInvestigationDescription =>
      'This will convert the disciplinary action into a formal investigation request.';

  @override
  String get whatHappensNext => 'What happens next:';

  @override
  String get investigationRequestWillBeCreated =>
      'Investigation request will be created';

  @override
  String get originalDaWillBeLinked =>
      'Original disciplinary action will be linked';

  @override
  String get investigationFollowsFormalProcess =>
      'Investigation follows formal review process';

  @override
  String get hrLegalTopManagement => 'HR → Legal (if needed) → Top Management';

  @override
  String get convertToInvestigationConfirmation =>
      'Are you sure you want to convert this to an investigation?';

  @override
  String get uploadInvestigationPdfOptional =>
      'Upload Investigation PDF (Optional)';

  @override
  String get fileSelected => 'File Selected';

  @override
  String get choosePdfFile => 'Choose PDF File';

  @override
  String get pdfFilesOnlyMax10mb => 'PDF files only, max 10MB';

  @override
  String get invalidFilePdfUnder10mb =>
      'Invalid file. Please upload a valid PDF file under 10MB.';

  @override
  String errorSelectingFile(String error) {
    return 'Error selecting file: $error';
  }

  @override
  String get viewButton => 'View';

  @override
  String failedToLoadInvestigation(String error) {
    return 'Failed to load investigation: $error';
  }

  @override
  String get legalEscalation => 'Legal Escalation';

  @override
  String get completionDate => 'Completion Date';

  @override
  String get changeLog => 'Change Log';

  @override
  String get hrInvestigationPdf => 'HR Investigation PDF';

  @override
  String get investigationPdfDocument => 'Investigation PDF Document';

  @override
  String uploadedDate(String date) {
    return 'Uploaded: $date';
  }

  @override
  String get legalInvestigationPdf => 'Legal Investigation PDF';

  @override
  String get legalInvestigationPdfDocument =>
      'Legal Investigation PDF Document';

  @override
  String get finalApproval => 'Final Approval';

  @override
  String get finalDecline => 'Final Decline';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get terminationRecommendedDate => 'Termination Recommended Date';

  @override
  String get bulkEmployeeUpload => 'Bulk Employee Upload';

  @override
  String get instructions => 'Instructions';

  @override
  String get downloadTemplateInstruction =>
      'Download the CSV or Excel template';

  @override
  String get fillEmployeeDataInstruction => 'Fill in employee data';

  @override
  String get uploadFileInstruction => 'Upload the completed file';

  @override
  String get reviewAndFixErrorsInstruction =>
      'Review and fix any validation errors';

  @override
  String get submitToAddEmployeesInstruction => 'Click Submit to add employees';

  @override
  String get downloadCsvTemplate => 'Download CSV Template';

  @override
  String get downloadExcelTemplate => 'Download Excel Template';

  @override
  String get uploadFile => 'Upload File';

  @override
  String get parsingFile => 'Parsing file...';

  @override
  String get validatingData => 'Validating data...';

  @override
  String get totalEmployees => 'Total Employees';

  @override
  String get valid => 'Valid';

  @override
  String get withErrors => 'With Errors';

  @override
  String get invalid => 'Invalid';

  @override
  String get reviewData => 'Review Data';

  @override
  String get revalidate => 'Revalidate';

  @override
  String get clickOnRedCellsToFix => 'Click on red cells to fix errors';

  @override
  String get n1Code => 'N+1 Code';

  @override
  String uploadingProgress(int current, int total) {
    return 'Uploading: $current/$total employees';
  }

  @override
  String submitEmployees(int count) {
    return 'Submit ($count employees)';
  }

  @override
  String get fixErrorsToSubmit => 'Fix all errors to enable submit';

  @override
  String get uploadComplete => 'Upload Complete';

  @override
  String get partialUploadComplete => 'Partial Upload Complete';

  @override
  String get succeeded => 'Succeeded';

  @override
  String get failed => 'Failed';

  @override
  String get failedEmployeesList => 'Failed Employees:';

  @override
  String get retryFailed => 'Retry Failed';

  @override
  String get confirmUpload => 'Confirm Upload';

  @override
  String confirmUploadMessage(int count) {
    return 'Are you sure you want to add $count employees?';
  }

  @override
  String templateSavedTo(String path) {
    return 'Template saved to: $path';
  }

  @override
  String employeesAddedSuccessfully(int count) {
    return '$count employees added successfully';
  }

  @override
  String get employeeGroups => 'Employee Groups';

  @override
  String get manageGroups => 'Manage Groups';

  @override
  String get addMember => 'Add Member';

  @override
  String get noMembersInGroup => 'No members in this group yet.';

  @override
  String get searchEmployeesToAdd => 'Search employees to add...';

  @override
  String get confirmRemoveMemberTitle => 'Remove Member';

  @override
  String confirmRemoveMemberMessage(String name, String group) {
    return 'Are you sure you want to remove $name from the $group group?';
  }

  @override
  String get reassignDirectReports => 'Reassign Direct Reports';

  @override
  String suspendingEmployee(String name) {
    return 'Suspending: $name';
  }

  @override
  String get directReportsAssignmentWarning =>
      'All direct reports must be assigned a new N+1 manager before suspending.';

  @override
  String employeesAssignedProgress(int assigned, int total) {
    return '$assigned of $total employees assigned';
  }

  @override
  String get assignN1ToEmployee => 'Assign N+1 to 1 selected employee';

  @override
  String assignN1ToEmployees(int count) {
    return 'Assign N+1 to $count selected employees';
  }

  @override
  String get bulkAssignN1SelectFirst =>
      'Bulk Assign N+1 — select rows below first';

  @override
  String get selectRowsFirstToSearch => 'Select rows first to enable search';

  @override
  String directReportsCount(int count) {
    return 'Direct Reports ($count)';
  }

  @override
  String get newN1 => 'New N+1';

  @override
  String get notAssigned => 'Not assigned';

  @override
  String get processing => 'Processing...';

  @override
  String get confirmAndSuspend => 'Confirm & Suspend';

  @override
  String couldNotLoadDirectReports(String error) {
    return 'Could not load direct reports: $error';
  }

  @override
  String get suspensionReason => 'Suspension Reason';

  @override
  String get selectSuspensionReason => 'Select a reason';

  @override
  String get reasonResignation => 'Resignation';

  @override
  String get reasonTermination => 'Termination';

  @override
  String get reasonOther => 'Other';

  @override
  String get lastWorkingDate => 'Last Working Date';

  @override
  String get selectLastWorkingDate => 'Select last working date';

  @override
  String get completed => 'Completed';

  @override
  String get acknowledged => 'Acknowledged';

  @override
  String get hrLetter => 'HR Letter';

  @override
  String get hrLetterRequest => 'HR Letter Request';

  @override
  String get hrLetterRequests => 'HR Letter Requests';

  @override
  String get myHrLetterRequests => 'My HR Letter Requests';

  @override
  String get teamHrLetterRequests => 'HR Letter Requests';

  @override
  String get hrLetterSubmittedSuccessfully =>
      'HR letter request submitted successfully';

  @override
  String get letterPurpose => 'Letter Purpose';

  @override
  String get letterPurposeBank => 'Bank';

  @override
  String get letterPurposeEmbassy => 'Embassy';

  @override
  String get letterPurposeOther => 'Other';

  @override
  String get travelFromDate => 'Travel From Date';

  @override
  String get travelToDate => 'Travel To Date';

  @override
  String get hrLetterDetails => 'Details';

  @override
  String get hrLetterDetailsHint => 'Enter any additional details...';

  @override
  String get hrLetterDetailsRequired =>
      'Details are required when purpose is Other';

  @override
  String get hrLetterNationalIdRequired => 'National ID is required';

  @override
  String get hrLetterPurposeRequired => 'Please select a letter purpose';

  @override
  String get hrLetterTravelFromRequired => 'Travel from date is required';

  @override
  String get hrLetterTravelToRequired => 'Travel to date is required';

  @override
  String get hrLetterTravelToAfterFrom =>
      'Travel to date must be after travel from date';

  @override
  String get notEligibleForHrLetter => 'Not Eligible for HR Letter';

  @override
  String get tenureLessThanThreeMonths =>
      'You are not eligible because your tenure is less than 3 months';

  @override
  String get acknowledgeHrLetterRequest => 'Acknowledge Request';

  @override
  String get confirmAcknowledgeHrLetter => 'Confirm Acknowledge';

  @override
  String get confirmAcknowledgeHrLetterMessage =>
      'Are you sure you want to acknowledge this HR letter request?';

  @override
  String get completeRequest => 'Complete Request';

  @override
  String get confirmCompleteHrLetter => 'Confirm Complete';

  @override
  String get confirmCompleteHrLetterMessage =>
      'Are you sure you want to mark this HR letter as completed and ready for collection?';

  @override
  String get completing => 'Completing...';

  @override
  String get requestCompletedSuccessfully => 'Request completed successfully';

  @override
  String get hrLetterReadyForCollection => 'HR Letter is ready for collection';

  @override
  String get searchByNameOrNationalId => 'Search by name, code or national ID';

  @override
  String get noHrLetterRequestsFound => 'No HR letter requests found';

  @override
  String failedToCompleteRequest(String error) {
    return 'Failed to complete request: $error';
  }

  @override
  String failedToAcknowledgeHrLetterRequest(String error) {
    return 'Failed to acknowledge request: $error';
  }

  @override
  String failedToCancelHrLetterRequest(String error) {
    return 'Failed to cancel request: $error';
  }

  @override
  String failedToDeclineHrLetterRequest(String error) {
    return 'Failed to decline request: $error';
  }

  @override
  String get lastActionAt => 'Last Updated';

  @override
  String get acknowledgedAt => 'Acknowledged At';

  @override
  String get completedAt => 'Completed At';

  @override
  String get declinedAt => 'Declined At';

  @override
  String get cancelledAt => 'Cancelled At';

  @override
  String get hrHandler => 'HR Handler';

  @override
  String get n2ApprovalDate => 'N+2 Approval Date';

  @override
  String get n2ApprovalReason => 'N+2 Approval Reason';

  @override
  String get hrApprovalDate => 'HR Approval Date';

  @override
  String get hrApprovalReason => 'HR Approval Reason';

  @override
  String get legalEscalationDate => 'Legal Escalation Date';

  @override
  String get legalCompletionDate => 'Legal Completion Date';

  @override
  String get employeeAcknowledgmentDate => 'Employee Acknowledgment Date';

  @override
  String get employeeAcknowledgmentRemark => 'Employee Acknowledgment Remark';

  @override
  String get employeeAcknowledgmentType => 'Employee Acknowledgment Type';

  @override
  String get linkedInvestigation => 'Linked Investigation';

  @override
  String get linkedDisciplinaryAction => 'Linked Disciplinary Action';

  @override
  String get requestorDepartment => 'Requestor Department';

  @override
  String get requestorTitle => 'Requestor Title';

  @override
  String get scheduleOnShift => 'On shift';

  @override
  String get scheduleLateNoPunch => 'Late / no punch';

  @override
  String get scheduleOff => 'Off';

  @override
  String get scheduleLoading => 'Loading schedule...';

  @override
  String get scheduleUnableToLoad => 'Unable to load schedule';

  @override
  String get scheduleCheckConnection => 'Check your connection and try again';

  @override
  String get scheduleRetry => 'Retry';

  @override
  String get schedulePageTitle => 'Employee Schedule';

  @override
  String get scheduleStatusPublished => 'Published';

  @override
  String get scheduleStatusDraft => 'Draft';

  @override
  String get scheduleTabWeekly => 'Weekly';

  @override
  String get scheduleTabDaily => 'Daily';

  @override
  String get scheduleTabMonthly => 'Monthly';

  @override
  String get scheduleTabOnShiftNow => 'On Shift Now';

  @override
  String get scheduleTabMySchedule => 'My Schedule';

  @override
  String get scheduleTabSwaps => 'Swaps';

  @override
  String get mobileBulkAssignTitle => 'Assign shifts';

  @override
  String get mobileBulkStep1Shift => '1 · Shift';

  @override
  String get mobileBulkStep2Days => '2 · Days';

  @override
  String get mobileBulkStep3Employees => '3 · Employees';

  @override
  String get mobileBulkWholeWeek => 'Whole week';

  @override
  String get mobileBulkClear => 'Clear';

  @override
  String get mobileBulkAll => 'All';

  @override
  String mobileBulkAssignN(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'shifts',
      one: 'shift',
    );
    return 'Assign $count $_temp0';
  }

  @override
  String get mobileBulkSearchHint => 'Search name or department…';

  @override
  String get mobileBulkFillDay => 'Fill this day';

  @override
  String get mobileBulkAssignDay => 'Assign this day…';

  @override
  String get mobileBulkAssignShifts => 'Assign shifts…';

  @override
  String get mobileBulkOneShift => 'One';

  @override
  String mobileWeekHoursScheduled(int hours) {
    return '${hours}h scheduled';
  }

  @override
  String get mobileThisWeek => 'This week';

  @override
  String get mobileUpcoming14Days => 'Upcoming · next 14 days';

  @override
  String get mobileSwapActivity => 'Swap activity';

  @override
  String get mobileSeeAll => 'See all';

  @override
  String get mobileDayOff => 'Day off';

  @override
  String get mobileOnLeave => 'On leave';

  @override
  String get mobileApprovedTimeOff => 'Approved time off';

  @override
  String get mobileNoShiftScheduled => 'No shift scheduled';

  @override
  String get mobileOnShiftNow => 'On shift';

  @override
  String get mobileLateNoPunch => 'Late / no punch';

  @override
  String get mobileOffShift => 'Off';

  @override
  String get mobileMoreTab => 'More';

  @override
  String get mobilePublishWeek => 'Publish week';

  @override
  String get mobileCopyLastWeek => 'Copy last week';

  @override
  String get mobileFilters => 'Filters';

  @override
  String get mobileAllTeams => 'All teams';

  @override
  String get mobileFiltersTitle => 'Filters';

  @override
  String get mobileDepartment => 'Department';

  @override
  String get mobileLocation => 'Location';

  @override
  String get mobileTeamScope => 'Team scope';

  @override
  String get mobileTeamScopeAll => 'Everyone';

  @override
  String get mobileTeamScopeDirect => 'Direct reports';

  @override
  String get mobileTeamScopeIndirect => 'Indirect';

  @override
  String get mobileFiltersReset => 'Reset';

  @override
  String get mobileFiltersApply => 'Apply';

  @override
  String get mobileShiftRequests => 'Swap Requests';

  @override
  String get mobilePendingAction => 'Pending action';

  @override
  String get mobileSentByMe => 'Sent by me';

  @override
  String get mobileSwapHistory => 'History';

  @override
  String get mobileOpenRequests => 'Open requests';

  @override
  String get mobilePastRequests => 'Past requests';

  @override
  String mobileConflictWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'conflicts',
      one: 'conflict',
    );
    return '$count $_temp0 will be created';
  }

  @override
  String get mobileStatPeople => 'People scheduled';

  @override
  String get mobileStatShifts => 'Shifts this week';

  @override
  String get mobileStatConflicts => 'Conflicts';

  @override
  String get mobileStatUnpublished => 'Unpublished';

  @override
  String get mobileStatAllClear => 'All clear';

  @override
  String get mobileStatAllPublished => 'All published';

  @override
  String mobileStatOfTotal(int total) {
    return 'of $total in view';
  }

  @override
  String mobileStatHoursTotal(int hours) {
    return '${hours}h total';
  }

  @override
  String get mobileShiftDetailWorking => 'Working this shift';

  @override
  String get mobileRequestSwap => 'Request shift swap';

  @override
  String get mobileCurrentlyOnShift => 'Currently on shift';

  @override
  String get mobileLateTitle => 'Late / no punch';

  @override
  String get mobileOffTitle => 'Off shift';

  @override
  String get scheduleCopyDialogTitle => 'Copy last week\'s schedule?';

  @override
  String get scheduleCopyFrom => 'From';

  @override
  String get scheduleCopyTo => 'To';

  @override
  String get scheduleCopyShiftsToCopy => 'Shifts to copy';

  @override
  String get scheduleCopyTeamSize => 'Team size';

  @override
  String get scheduleCopyEmployeesToCopy => 'Employees to copy';

  @override
  String scheduleCopyEmployees(int count) {
    return '$count employees';
  }

  @override
  String get scheduleCopyNote =>
      'Existing shifts for this week will be kept. Only missing days will be filled in.';

  @override
  String get scheduleCopyButton => 'Copy schedule';

  @override
  String get schedulePublishDialogTitle => 'Publish this week\'s schedule?';

  @override
  String get schedulePublishTotalShifts => 'Shifts';

  @override
  String get schedulePublishToBePublished => 'To be published';

  @override
  String get schedulePublishEmployeesNotified => 'Employees notified';

  @override
  String get schedulePublishWeekLabel => 'Week';

  @override
  String get schedulePublishNote =>
      'Employees will receive a notification once the schedule is published.';

  @override
  String get schedulePublishButton => 'Publish';

  @override
  String get scheduleToolbarToday => 'Today';

  @override
  String scheduleToolbarWeek(int number) {
    return 'Wk $number';
  }

  @override
  String get scheduleAllDepartments => 'All departments';

  @override
  String get scheduleAllLocations => 'All locations';

  @override
  String get scheduleDirectPlusIndirect => 'Direct + indirect';

  @override
  String get scheduleDirectReportsOnly => 'Direct reports only';

  @override
  String get scheduleIndirectOnly => 'Indirect only';

  @override
  String get scheduleCopyLastWeek => 'Copy last week';

  @override
  String get scheduleCopyLastWeekNoShifts => 'Last week has no shifts to copy';

  @override
  String get scheduleCopyNoRoom => 'No empty days to copy into this week';

  @override
  String get schedulePublishing => 'Publishing…';

  @override
  String get schedulePublishingPleaseWait =>
      'Publishing in progress, please wait';

  @override
  String get schedulePublishWeek => 'Publish week';

  @override
  String get schedulePanelSwapRequests => 'Swap Requests';

  @override
  String get scheduleNoPendingSwaps => 'No pending swap requests';

  @override
  String get schedulePanelConflicts => 'Conflicts';

  @override
  String get scheduleNoConflicts => 'No conflicts detected';

  @override
  String get schedulePanelTimeOff => 'Time Off';

  @override
  String get scheduleNoApprovedLeaves => 'No approved leaves this week';

  @override
  String get scheduleSidePanelCollapse => 'Collapse panel';

  @override
  String get scheduleSidePanelExpand => 'Expand panel';

  @override
  String get scheduleShiftNewShift => 'New shift';

  @override
  String get scheduleShiftEditShift => 'Edit shift';

  @override
  String get scheduleShiftBulkAssign => 'Bulk assign';

  @override
  String scheduleShiftAssignCells(int count) {
    return 'Assign shift to $count cells';
  }

  @override
  String get scheduleConflictDetected => 'Conflict detected';

  @override
  String get scheduleQuickTypes => 'Quick types';

  @override
  String get scheduleOffTypeDayOff => 'Day Off';

  @override
  String get scheduleOffTypePlannedLeave => 'Planned Leave';

  @override
  String get scheduleOffTypeUnplannedLeave => 'Unplanned Leave';

  @override
  String get scheduleOffTypeHoliday => 'Holiday';

  @override
  String get scheduleSummary => 'Summary';

  @override
  String get scheduleSummaryShifts => 'Shifts';

  @override
  String get scheduleSummaryConflicts => 'Conflicts';

  @override
  String scheduleSummaryLeaveOnShift(String type) {
    return '$type (on shift)';
  }

  @override
  String scheduleEmptyCellsRemaining(int count) {
    return '$count cells still unfilled';
  }

  @override
  String get scheduleQuickTemplates => 'Quick templates';

  @override
  String get scheduleNoTemplatesYet =>
      'No templates yet — enter times below to create one';

  @override
  String get scheduleStartTime => 'Start time';

  @override
  String get scheduleEndTime => 'End time';

  @override
  String get scheduleHours => 'Hours';

  @override
  String get scheduleSaveAsTemplate => 'Save as template';

  @override
  String get scheduleTemplateName => 'Template name';

  @override
  String get scheduleTemplateNameHint => 'e.g. Morning shift';

  @override
  String get scheduleTemplateNameRequired => 'Template name is required';

  @override
  String get scheduleNoteOptional => 'Note (optional)';

  @override
  String get scheduleNotifyEmployees =>
      'Notify employees when schedule is published';

  @override
  String get scheduleRemoveShift => 'Remove shift';

  @override
  String get scheduleSaveAsDraft => 'Save as draft';

  @override
  String get scheduleTapCellFirst =>
      'Tap a cell in the grid first to select which employee and day to assign.';

  @override
  String get scheduleConflictApprovedLeave =>
      'Employee is on approved leave that day';

  @override
  String get scheduleConflictExceedsMaxHours => 'Shift exceeds 16 hours';

  @override
  String get scheduleConflictInsufficientRestAfter =>
      'Less than 8h rest after previous shift';

  @override
  String get scheduleConflictInsufficientRestBefore =>
      'Less than 8h rest before next shift';

  @override
  String get scheduleRequestSwapTitle => 'Request shift swap';

  @override
  String get scheduleSwapWith => 'Swap with';

  @override
  String get scheduleSearchColleague => 'Search colleague…';

  @override
  String get scheduleSameShift => 'Same shift';

  @override
  String get scheduleDayOff => 'Day off';

  @override
  String get schedulePleaseSelectColleague => 'Please select a colleague';

  @override
  String get scheduleReasonOptional => 'Reason (optional)';

  @override
  String get scheduleWhySwapHint => 'Why do you need to swap this shift?';

  @override
  String get scheduleSendRequest => 'Send request';

  @override
  String get scheduleNoUpcomingShifts =>
      'No upcoming published shifts to swap.';

  @override
  String get scheduleSelectShift => 'Select a shift to swap';

  @override
  String get scheduleNoData => 'No schedule data available.';

  @override
  String get scheduleUpcomingShifts => 'Upcoming shifts · next 14 days';

  @override
  String get scheduleNotAssigned => 'Not assigned';

  @override
  String get scheduleRequestSwap => 'Request swap';

  @override
  String get scheduleTeamView => 'Team';

  @override
  String get scheduleColleaguesView => 'Colleagues';

  @override
  String get scheduleNotAvailableInColleaguesMode =>
      'Not available in colleagues mode';

  @override
  String get scheduleSelectOtherShiftsToSwap =>
      'Select other shifts to swap with';

  @override
  String get scheduleSwapSameShift => 'Same shift — nothing to swap';

  @override
  String get scheduleSwapAlreadyPending =>
      'You already have an open swap request for this day';

  @override
  String get scheduleSwapPastDay =>
      'Swaps can only be requested for future shifts';

  @override
  String get scheduleSwapOnLeave => 'Cannot swap a shift on a leave day';

  @override
  String get scheduleSwapColleagueOnLeave =>
      'Colleague is on leave — cannot swap this shift';

  @override
  String get scheduleSwapWantsToSwap => 'Wants to swap shifts with you';

  @override
  String get scheduleSwapAwaitingManagerApproval =>
      'Swap is awaiting manager approval';

  @override
  String get scheduleSwapCompleted => 'Swap completed';

  @override
  String get scheduleSwapDeclined => 'Swap request was declined';

  @override
  String get scheduleSwapCancelledByRequester =>
      'Request was cancelled by requester';

  @override
  String get scheduleSwapAwaitingColleague => 'Awaiting their response';

  @override
  String get scheduleSwapAwaitingManager => 'Awaiting manager approval';

  @override
  String get scheduleSwapRequestDeclined => 'Request was declined';

  @override
  String get scheduleSwapYouCancelled => 'You cancelled this request';

  @override
  String get scheduleStatusApproved => 'Approved';

  @override
  String get scheduleStatusCancelled => 'Cancelled';

  @override
  String get scheduleStatusDeclined => 'Declined';

  @override
  String get scheduleAwaitingColleagueBadge => 'Awaiting colleague';

  @override
  String get scheduleAwaitingManagerBadge => 'Awaiting manager';

  @override
  String scheduleGridCellSelected(int count) {
    return '$count cell selected';
  }

  @override
  String scheduleGridCellsSelected(int count) {
    return '$count cells selected';
  }

  @override
  String get scheduleAssignShift => 'Assign Shift';

  @override
  String get scheduleCoverage => 'Coverage';

  @override
  String get scheduleScrollTooltip => 'Scroll (Shift + mouse wheel)';

  @override
  String scheduleEmployeeColumn(int count) {
    return 'Employee · $count';
  }

  @override
  String get scheduleKpiPeopleScheduled => 'People scheduled';

  @override
  String scheduleKpiOfInView(int total) {
    return 'of $total in view';
  }

  @override
  String get scheduleKpiShiftsThisWeek => 'Shifts this week';

  @override
  String scheduleKpiTotalHours(int hours) {
    return '${hours}h total';
  }

  @override
  String get scheduleKpiConflicts => 'Conflicts';

  @override
  String get scheduleKpiAllClear => 'All clear';

  @override
  String get scheduleKpiNeedReview => 'Need review';

  @override
  String get scheduleKpiUnpublishedDrafts => 'Unpublished drafts';

  @override
  String get scheduleKpiAllPublished => 'All published';

  @override
  String get scheduleKpiPendingPublish => 'Pending publish';

  @override
  String get scheduleKpiOnApprovedLeave => 'On approved leave';

  @override
  String get scheduleKpiThisWeek => 'this week';

  @override
  String get scheduleLegendMorning => 'Morning';

  @override
  String get scheduleLegendAfternoon => 'Afternoon';

  @override
  String get scheduleLegendOvernight => 'Overnight';

  @override
  String get scheduleLegendNight => 'Night';

  @override
  String get scheduleLegendLeave => 'Leave';

  @override
  String get scheduleLegendDraft => 'Draft';

  @override
  String get scheduleLegendConflict => 'Conflict';

  @override
  String get schedulePinnedSelfBadge => 'You';

  @override
  String get schedulePinnedManagerBadge => 'Manager';

  @override
  String get scheduleProposedBadge => 'Proposed';

  @override
  String get scheduleReservedByManager => 'Reserved by your manager';

  @override
  String get scheduleDraftHint => 'Draft — your manager publishes';

  @override
  String scheduleLegendPublished(int count) {
    return '$count published';
  }

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get scheduleOpenSlot => 'Open slot';

  @override
  String get scheduleAnErrorOccurred => 'An error occurred';

  @override
  String scheduleCarryOverEnds(String time) {
    return '↵ ends $time';
  }

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get requestsLoadFailed => 'Error loading requests';

  @override
  String get errorLoadingPendingRequests => 'Error loading pending requests';

  @override
  String get teamShiftSwapRequests => 'Team Shift Swap Requests';

  @override
  String get colleaguesSwapRequests => 'Colleagues Swap Requests';

  @override
  String get shiftSwapRequests => 'Shift Swap Requests';

  @override
  String get schedule => 'Schedule';

  @override
  String get shiftMorning => 'Morning';

  @override
  String get shiftEvening => 'Evening';

  @override
  String get shiftAfternoon => 'Afternoon';

  @override
  String get shiftOvernight => 'Overnight';

  @override
  String get shiftNight => 'Night';

  @override
  String get shiftFullDay => 'Full day';

  @override
  String get hrTools => 'HR Tools';

  @override
  String get bulkLeaves => 'Bulk Leaves';

  @override
  String get bulkOvertimeIncrement => 'Bulk Overtime Increment';

  @override
  String get selectEmployeesFirst => 'Please select at least one employee';

  @override
  String get bulkLeavesSubmittedSuccessfully =>
      'Bulk leaves added successfully';

  @override
  String get bulkOvertimeSubmittedSuccessfully =>
      'Overtime balances updated successfully';

  @override
  String get daysToAdd => 'Days to Add';

  @override
  String get daysToAddHint => 'e.g. 1.5';

  @override
  String get invalidDaysToAdd => 'Enter a valid number greater than 0';

  @override
  String get bulkLeaveNote =>
      'Leaves will be auto-approved for all selected employees';

  @override
  String get approvalMode => 'Approval Mode';

  @override
  String get autoApproveMode => 'Auto-approve';

  @override
  String get normalApprovalCycleMode => 'Normal cycle';

  @override
  String get bulkLeaveApprovalCycleNote =>
      'Requests will be sent to each employee\'s direct manager (N+1) for approval';

  @override
  String get bulkSickNoteSingleEmployeeOnly =>
      'A medical report can only be attached when a single employee is selected';

  @override
  String get bulkLeaveNoteUploadFailed =>
      'The leave was created, but the medical report could not be uploaded';

  @override
  String get bulkLeavesPartialTitle => 'Some requests were not created';

  @override
  String bulkLeavesPartialSummary(int created, int total) {
    return 'Created $created of $total requests';
  }

  @override
  String get tutTopBarTitle => 'Top Bar';

  @override
  String get tutTopBarBody =>
      'Shows the current page name, logged-in user, and sign-out button on the left.';

  @override
  String get tutSidebarTitle => 'Side Navigation';

  @override
  String get tutSidebarBody =>
      'Shortcuts to all system sections: Home, Leaves, Attendance, Advances, Letters and more.';

  @override
  String get tutPendingTitle => 'Pending Requests';

  @override
  String get tutPendingBody =>
      'Requests waiting for your action, grouped by type: leaves, missions, attendance, advances, admin actions.';

  @override
  String get tutProcessingTitle => 'In-Process Requests';

  @override
  String get tutProcessingBody =>
      'Requests you have sent that are still under review by management or HR.';

  @override
  String get tutRecentTitle => 'Recently Processed';

  @override
  String get tutRecentBody =>
      'A log of the latest processed requests for easy reference.';

  @override
  String get tutQuickActionsTitle => 'Quick Actions';

  @override
  String get tutQuickActionsBody =>
      'Start any new request in one tap: mission, leave, advance, attendance proof, HR letter, or admin action.';

  @override
  String get tutLeaveButtonTitle => 'Submit a Leave Request';

  @override
  String get tutLeaveButtonBody =>
      'This is the Leave Request button. Tap it to open the leave submission form.';

  @override
  String get tutLeaveBalancesTitle => 'Your Balances';

  @override
  String get tutLeaveBalancesBody =>
      'Your leave balances at a glance. \'Available Now\' is what you can use today (it can go negative if you\'re in deficit). Carry-forward days are last year\'s remainder and expire on Mar 31; overtime/compensation balance is shown separately and is used before annual leave.';

  @override
  String get tutLeaveFromDateTitle => 'Start Date';

  @override
  String get tutLeaveFromDateBody =>
      'Pick the first day of your leave. In the calendar, days struck through in red are unavailable — they already have a leave, business-trip, or missing-punch request. Tap a red day to see the reason.';

  @override
  String get tutLeaveToDateTitle => 'End Date';

  @override
  String get tutLeaveToDateBody =>
      'Pick the last day of your leave. The range can\'t cross an unavailable (red) day, so the selectable days adjust automatically based on your start date.';

  @override
  String get tutLeaveHoursTitle => 'Partial Hours';

  @override
  String get tutLeaveHoursBody =>
      'Only shown for a single-day request. Choose how many hours you need instead of a full day — leave it empty to take the whole day. Selecting hours limits which leave types you can pick.';

  @override
  String get tutLeaveDayCountTitle => 'Days Off';

  @override
  String get tutLeaveDayCountBody =>
      'A live count of how long you\'ll be off for the dates you chose. It shows hours instead of days when you request partial hours.';

  @override
  String get tutLeaveTypeTitle => 'Leave Type';

  @override
  String get tutLeaveTypeBody =>
      'Choose the type that fits your situation. A greyed-out option means its rule isn\'t met for your current dates, hours, or balance.\n\n• Annual — planned time off. Needs available or carry-forward balance, is subject to your yearly allowance. If you have overtime balance, use Compensation first.\n\n• Emergency — sudden, same-day needs. Limited to one day and requires available annual/carry-forward balance.\n\n• Compensation — spends your overtime balance. Available only when that balance covers the requested days.\n\n• Sick — for illness. Requires uploading a sick note.\n\n• Unpaid — time off without pay. Available only when you have little or no paid balance left.';

  @override
  String get tutLeaveSubmitTitle => 'Submit';

  @override
  String get tutLeaveSubmitBody =>
      'Sends your request for approval. It stays grey and disabled until every field is valid, then turns blue. Any blocking issue (like an emergency request that\'s too long) is shown just above this button.';

  @override
  String get tutHelpTooltip => 'Help tour';

  @override
  String get tutNext => 'Next';

  @override
  String get tutSkip => 'Skip tour';

  @override
  String get tutWatchHow => 'Watch how';

  @override
  String get tutHelpCenterTitle => 'Schedule Help';

  @override
  String get tutStartTour => 'Start guided tour';

  @override
  String get tutBrowseClips => 'WATCH HOW-TO CLIPS';

  @override
  String get tutClipComingSoon => 'This recording is coming soon.';

  @override
  String get tutSchViewModeTitle => 'Team vs Colleagues';

  @override
  String get tutSchViewModeBody =>
      'Switch between Team view — the schedule of everyone who reports to you — and Colleagues view, where you draft your own shifts alongside your peers.';

  @override
  String get tutSchTabsTitle => 'Schedule Views';

  @override
  String get tutSchTabsBody =>
      'Look at the same week four ways: Weekly grid, a Daily timeline, a Monthly calendar, and My Schedule for your own shifts.';

  @override
  String get tutSchFiltersTitle => 'Navigate & Filter';

  @override
  String get tutSchFiltersBody =>
      'Use Today and the arrows to move between weeks, then narrow the team by department, location, or reporting scope (direct, indirect, or both).';

  @override
  String get tutSchCopyTitle => 'Copy Last Week';

  @override
  String get tutSchCopyBody =>
      'Reuse last week\'s plan in one step — it copies shifts into any empty days for the current week, skipping days that are already filled.';

  @override
  String get tutSchPublishTitle => 'Publish the Week';

  @override
  String get tutSchPublishBody =>
      'Turn your drafts into the official schedule. Once every cell is filled the button turns blue; publishing notifies the affected employees. It stays disabled while empty cells remain.';

  @override
  String get tutSchKpiTitle => 'Week at a Glance';

  @override
  String get tutSchKpiBody =>
      'Live totals for the visible team: people scheduled, shifts this week, conflicts, unpublished drafts, and how many are on approved leave.';

  @override
  String get tutSchLegendTitle => 'Colour Legend';

  @override
  String get tutSchLegendBody =>
      'What the cell colours mean — Morning, Afternoon, Night and Overnight shifts, plus Leave and Day-off, and the markers for drafts and conflicts.';

  @override
  String get tutSchAssignTitle => 'Assign a Shift';

  @override
  String get tutSchAssignBody =>
      'Tap any empty cell to open the shift editor and set the times, or tap an existing shift to edit it. Conflicts (rest gaps, leave overlaps) are flagged automatically.';

  @override
  String get tutSchMultiSelectTitle => 'Select Multiple Cells';

  @override
  String get tutSchMultiSelectBody =>
      'Need the same shift across several people or days? Drag across the grid — or long-press then tap — to select many cells, then assign them all at once from the bar that appears.';

  @override
  String get tutSchTemplateTitle => 'Reusable Templates';

  @override
  String get tutSchTemplateBody =>
      'In the shift editor, tick \'Save as template\' and give it a name to store a shift you use often. Next time it appears as a chip you can apply in one tap.';

  @override
  String get tutSchSwapTitle => 'Swaps, Conflicts & Time Off';

  @override
  String get tutSchSwapBody =>
      'The side panel collects swap requests to approve or decline, scheduling conflicts to resolve, and your team\'s approved time off — all in one place.';

  @override
  String get tutTeamTour => 'Team view tour';

  @override
  String get tutColleaguesTour => 'Colleagues view tour';

  @override
  String get tutSchWeekNavTitle => 'Navigate Weeks';

  @override
  String get tutSchWeekNavBody =>
      'Use Today and the arrows to move between weeks. The week label shows which week you\'re viewing.';

  @override
  String get tutSchSelfActionsTitle => 'Your Draft Actions';

  @override
  String get tutSchSelfActionsBody =>
      'In Colleagues view you draft your own row. \'Copy last week\' fills your empty days from last week, and the amber hint reminds you that your manager publishes your final schedule.';

  @override
  String get tutSchSelfDraftTitle => 'Draft Your Own Shifts';

  @override
  String get tutSchSelfDraftBody =>
      'Tap an empty day on your row to propose a shift, or tap your own draft to edit it. Days your manager has reserved show a lock and can\'t be edited. Your drafts stay pending until your manager publishes them.';

  @override
  String get tutSchRequestSwapTitle => 'Request a Swap';

  @override
  String get tutSchRequestSwapBody =>
      'Tap a colleague\'s shift to request a swap with them. You can only swap future shifts, and not when either of you is on leave or already has an open request for that day.';

  @override
  String get tutSchPinnedRowTitle => 'Manager Comparison Row';

  @override
  String get tutSchPinnedRowBody =>
      'This pinned row shows your manager\'s schedule for reference (read-only, marked with a \'Manager\' badge) so you can line your own shifts up against theirs.';

  @override
  String get tutSchMobileWeekNavTitle => 'Pick a Week';

  @override
  String get tutSchMobileWeekNavBody =>
      'Tap the arrows to move between weeks; the label in the middle shows the week you\'re viewing.';

  @override
  String get tutSchMobileStatsTitle => 'Week at a Glance';

  @override
  String get tutSchMobileStatsBody =>
      'Quick totals for the week: people scheduled and shifts always show; in Team view you also see conflicts and unpublished drafts.';

  @override
  String get tutSchMobileDayPickerTitle => 'Choose a Day';

  @override
  String get tutSchMobileDayPickerBody =>
      'Tap a day to focus the list below on that day\'s shifts. Swipe the strip sideways to reach the whole week.';

  @override
  String get tutSchMobileBulkTitle => 'Bulk Assign Shifts';

  @override
  String get tutSchMobileBulkBody =>
      'Tap \'Assign shifts…\' to open the bulk sheet and give the same shift to several people across several days at once — it walks you through the shift (template or custom times), the days, then who it applies to. The \'Fill this day\' link above the list does the same for just the day you\'re viewing.';

  @override
  String get tutSchMobileTabsTitle => 'Schedule Views';

  @override
  String get tutSchMobileTabsBody =>
      'Swipe the tab strip to move between views: Weekly (the day-by-day list below), Monthly for a whole-month overview, On Shift Now for who\'s working right now, My Schedule for your own shifts, and Swaps — its badge counts requests waiting on you. Managers also get a More tab for publishing and copying.';

  @override
  String get tutSchMobileFiltersTitle => 'Filter the Team';

  @override
  String get tutSchMobileFiltersBody =>
      'Tap this chip to open the filters sheet, then narrow the list by department, location, or reporting scope. Nothing changes until you tap Apply, and Reset clears everything. The chip itself shows what\'s currently applied.';

  @override
  String get tutSchMobileSelfBarTitle => 'Your Shift Actions';

  @override
  String get tutSchMobileSelfBarBody =>
      '\'Copy last week\' fills your empty days from last week, and \'Assign shifts…\' opens a sheet locked to your own row so you can draft several days at once. Your drafts stay pending until your manager publishes them.';

  @override
  String get tutSchMobileSwapsTitle => 'Approve Swap Requests';

  @override
  String get tutSchMobileSwapsBody =>
      'Swap requests from your team land here under \'Pending action\'. Each card shows both shifts side by side so you can compare them, then Approve or Decline. The tab badge tells you how many are waiting.';

  @override
  String get tutSchMobileSwapsPeerTitle => 'Your Swaps';

  @override
  String get tutSchMobileSwapsPeerBody =>
      'Everything about your swaps in one tab: requests colleagues sent you (accept or decline), the ones you\'ve sent (which you can cancel), and your past swap history. To start a new one, tap a colleague\'s shift in Weekly or use \'Swap with\' in My Schedule.';

  @override
  String get tutSchMobileMoreTitle => 'Publish & Copy';

  @override
  String get tutSchMobileMoreBody =>
      'The manager actions live here. \'Publish week\' turns your drafts into the official schedule and notifies everyone affected — it stays disabled until every cell is filled. \'Copy last week\' reuses last week\'s plan for any empty days.';

  @override
  String get tutSchKpiColleaguesBody =>
      'Totals for the week you\'re viewing: how many people are scheduled and how many shifts there are in total.';

  @override
  String get tutSchLegendColleaguesBody =>
      'What the colours mean — Morning, Afternoon, Night and Overnight shifts, plus Leave and Day-off.';

  @override
  String get tutTopicsTeam => 'MANAGING YOUR TEAM';

  @override
  String get tutTopicsColleagues => 'YOUR OWN SCHEDULE';

  @override
  String get statistics => 'Statistics';

  @override
  String get statsOverview => 'Overview';

  @override
  String get statsApprovalFunnel => 'Approval Funnel';

  @override
  String get statsLeaveAttendance => 'Leave & Attendance';

  @override
  String get statsFinancial => 'Financial';

  @override
  String get statsDisciplinary => 'Disciplinary';

  @override
  String get statsWorkforce => 'Workforce';

  @override
  String get statsTotalRequests => 'Total Requests';

  @override
  String get statsPendingApproval => 'Pending Approval';

  @override
  String get statsAvgApprovalTime => 'Avg Approval Time';

  @override
  String get statsApprovalRate => 'Approval Rate';

  @override
  String get statsVolumeByType => 'Request Volume by Type';

  @override
  String get statsStatusDistribution => 'Status Distribution';

  @override
  String get statsRequestsByDepartment => 'Requests by Department';

  @override
  String get statsAvgTimePerStage => 'Avg Time per Stage';

  @override
  String get statsPendingByApprover => 'Pending by Approver × Type';

  @override
  String get statsOldestPending => 'Oldest Pending';

  @override
  String get statsLeaveTypeMix => 'Leave Type Mix';

  @override
  String get statsLeaveSeasonality => 'Leave Days (Seasonality)';

  @override
  String get statsLeaveBalanceByDept => 'Leave Balance by Department';

  @override
  String get statsAdvancesDisbursed => 'Advances Disbursed';

  @override
  String get statsTotalAdvances => 'Total Advances';

  @override
  String get statsSettlementRate => 'Settlement Rate';

  @override
  String get statsAvgAdvance => 'Avg Advance';

  @override
  String get statsApprovedAmount => 'Approved Amount';

  @override
  String get statsViolationCategories => 'Violation Categories';

  @override
  String get statsActionTypes => 'Action Types';

  @override
  String get statsOutcomes => 'Outcomes';

  @override
  String get statsEscalatedToLegal => 'Escalated to Legal';

  @override
  String get statsSuspensions => 'Suspensions';

  @override
  String get statsTerminations => 'Terminations';

  @override
  String get statsTotalCases => 'Total Cases';

  @override
  String get statsHeadcountByDepartment => 'Headcount by Department';

  @override
  String get statsHeadcountByLocation => 'Headcount by Location';

  @override
  String get statsTenureDistribution => 'Tenure Distribution';

  @override
  String get statsAllDepartments => 'All Departments';

  @override
  String get statsAllLocations => 'All Locations';

  @override
  String get statsAllTypes => 'All Types';

  @override
  String get statsThisMonth => 'This month';

  @override
  String get statsLast3Months => 'Last 3 months';

  @override
  String get statsThisYear => 'This year';

  @override
  String get statsLast12Months => 'Last 12 months';

  @override
  String get statsNoData => 'No data for this period';

  @override
  String get statsNothingPending => 'Nothing pending';

  @override
  String get statsRetry => 'Retry';

  @override
  String get statsApproverN1 => 'N+1';

  @override
  String get statsApproverN2 => 'N+2';

  @override
  String get statsApproverHr => 'HR';

  @override
  String get statsApproverFinance => 'Finance';

  @override
  String get statsApproverLegal => 'Legal';

  @override
  String get statsApproverEmployee => 'Employee';

  @override
  String get statsApproverNone => '—';

  @override
  String get statsStageSubmitted => 'Submitted';

  @override
  String get statsStageFinalized => 'Finalized';

  @override
  String get statsTenureUnder1 => '< 1 yr';

  @override
  String get statsTenure1to2 => '1-2 yr';

  @override
  String get statsTenure2to4 => '2-4 yr';

  @override
  String get statsTenure4plus => '4+ yr';

  @override
  String get statsUnknown => 'Unknown';

  @override
  String get statsPendingAt => 'At';

  @override
  String get statsAge => 'Age';

  @override
  String get statsLeaveCancellation => 'Leave Cancellation';

  @override
  String get statsBusinesstripCancellation => 'Business Trip Cancellation';

  @override
  String get statsTakenVsBalanceByDept =>
      'Leave Taken vs Available Balance by Department (avg. days/employee)';

  @override
  String get statsTakenThisYear => 'Taken this year';

  @override
  String get statsAvailableBalance => 'Available balance';

  @override
  String get statsHeadcount => 'Headcount';

  @override
  String get statsAccessDenied => 'You don\'t have access to statistics.';
}
