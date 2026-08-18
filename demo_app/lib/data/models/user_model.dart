class UserModel {
  final int? id;
  final String? arabicName;
  final String? englishName;
  final String? title;
  final String? department;
  final String? englishTitle;
  final String? englishDepartment;
  final String? location;
  final String? costCenter;
  final String? hireDate;
  final int? n1;
  final int? n2;
  final String? email;
  final int? leavesEligibility;
  final int? workingDays;
  final double? leaveBalance;
  final double? overtimeBalance;
  final double? emergencyBalance;
  final int? shiftHours;
  final String? n1EnglishName;
  final String? n1ArabicName;
  final String? n2EnglishName;
  final String? n2ArabicName;
  final int? missingPunchBalance;
  final String? authEmail;
  final DateTime? advanceOnSalaryEligibilityDate;
  final List<String>? groups;
  final String? nationalId;
  final String? arabicNickname;
  final String? englishNickname;
  final String? userState;
  final int? loginCode;
  /// Employee-provided contact info, self-editable from the profile page.
  /// Optional (nullable) — collected gradually, absent for most employees.
  final String? phoneNumber;
  final String? address;

  /// Why the employee was suspended: 'resignation' | 'termination' | 'other'.
  /// Captured at suspend time; null for employees that were never suspended.
  final String? suspensionReason;

  /// Last working day — only collected for resignation/termination
  /// suspensions; null for 'other' or never-suspended employees.
  final DateTime? lastWorkingDate;

  // ── Monthly-loading system fields (Leave Balance Monthly Loading System) ──
  // The first three map directly to columns on `users` (see
  // add_leave_loading_columns.sql); the remaining five are supplied only by
  // get_leave_balance_summary (fetched in parallel in user_bloc.dart) since
  // they require ledger aggregation the plain user row can't provide.
  /// annual_remaining_balance — "X days left this year" (the old Leave Balance
  /// meaning, preserved for familiar display). Always >= 0.
  final double? annualRemainingBalance;
  /// leave_carry_forward — Jan-1 snapshot of unused balance, usable through
  /// March 31 (Rule D). FIFO-depleted first on debit because it expires soonest.
  final double? carryForwardBalance;
  /// overtime_carry_forward — mirrors carryForwardBalance for compensation
  /// days (Rule E); unlike annual leave, overtimeBalance itself is never reset.
  final double? overtimeCarryForwardBalance;
  /// SUM of `debit` ledger entries this calendar year — from get_leave_balance_summary.
  final double? daysTakenThisYear;
  /// leavesEligibility / 12 — the regular monthly accrual rate (Rule C).
  final double? monthlyLeaveRate;

  bool get isSuspended => userState == 'suspended';

  const UserModel({
    this.id,
    this.arabicName,
    this.englishName,
    this.title,
    this.department,
    this.englishTitle,
    this.englishDepartment,
    this.location,
    this.costCenter,
    this.hireDate,
    this.n1,
    this.n2,
    this.email,
    this.leavesEligibility,
    this.workingDays,
    this.leaveBalance,
    this.overtimeBalance,
    this.emergencyBalance,
    this.shiftHours,
    this.n1EnglishName,
    this.n1ArabicName,
    this.n2EnglishName,
    this.n2ArabicName,
    this.missingPunchBalance,
    this.authEmail,
    this.advanceOnSalaryEligibilityDate,
    this.groups,
    this.nationalId,
    this.arabicNickname,
    this.englishNickname,
    this.userState,
    this.loginCode,
    this.phoneNumber,
    this.address,
    this.suspensionReason,
    this.lastWorkingDate,
    this.annualRemainingBalance,
    this.carryForwardBalance,
    this.overtimeCarryForwardBalance,
    this.daysTakenThisYear,
    this.monthlyLeaveRate,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    String? n1EnglishName,
    String? n2EnglishName,
    String? n1ArabicName,
    String? n2ArabicName,
    // Supplied by the parallel get_leave_balance_summary fetch in
    // user_bloc.dart — not present on the plain `users` row.
    double? daysTakenThisYear,
    double? monthlyLeaveRate,
  }) {
    return UserModel(
      id: json['Code'],
      arabicName: json['Arabic Name'],
      englishName: json['English Name'],
      title: json['Title'],
      department: json['Department'],
      englishTitle: json['english_title'],
      englishDepartment: json['english_department'],
      location: json['Location / Site'],
      costCenter: json['Cost Center'],
      hireDate: json['Hire Date'],
      n1: json['N+1'],
      n2: json['N+2'],
      email: json['Real Email Address'],
      leavesEligibility: json['Leaves Eligibility'],
      workingDays: json['Working Days'],
      leaveBalance: json['Leave Balance'],
      overtimeBalance: json['overtime_balance'],
      emergencyBalance: json['emergency_balance'],
      shiftHours: json['Shift Hours'],
      n1EnglishName: n1EnglishName,
      n1ArabicName: n1ArabicName,
      n2EnglishName: n2EnglishName,
      n2ArabicName: n2ArabicName,
      missingPunchBalance: json['missingpunch_balance'],
      authEmail: json['email'],
      advanceOnSalaryEligibilityDate:
          json['advance_on_salary_eligibility_date'] != null
              ? DateTime.tryParse(json['advance_on_salary_eligibility_date'])
              : null,
      groups: json['groups'] != null ? List<String>.from(json['groups']) : null,
      nationalId: json['National ID'],
      arabicNickname: json['Arabic Nickname'],
      englishNickname: json['English Nickname'],
      userState: json['user_state'] as String?,
      loginCode: json['login_code'],
      phoneNumber: json['Phone Number'],
      address: json['Address'],
      suspensionReason: json['Suspension Reason'],
      lastWorkingDate: json['Last Working Date'] != null
          ? DateTime.tryParse(json['Last Working Date'])
          : null,
      annualRemainingBalance: (json['annual_remaining_balance'] as num?)?.toDouble(),
      carryForwardBalance: (json['leave_carry_forward'] as num?)?.toDouble(),
      overtimeCarryForwardBalance: (json['overtime_carry_forward'] as num?)?.toDouble(),
      daysTakenThisYear: daysTakenThisYear,
      monthlyLeaveRate: monthlyLeaveRate,
    );
  }
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['Code'] = id;
    data['Arabic Name'] = arabicName;
    data['English Name'] = englishName;
    data['Title'] = title;
    data['Department'] = department;
    data['english_title'] = englishTitle;
    data['english_department'] = englishDepartment;
    data['Location / Site'] = location;
    data['Cost Center'] = costCenter;
    data['Hire Date'] = hireDate;
    data['N+1'] = n1;
    data['N+2'] = n2;
    data['Real Email Address'] = email;
    data['Leaves Eligibility'] = leavesEligibility;
    data['Working Days'] = workingDays;
    data['Leave Balance'] = leaveBalance;
    data['annual_remaining_balance'] = annualRemainingBalance;
    data['overtime_balance'] = overtimeBalance ?? 0;
    data['emergency_balance'] = emergencyBalance ?? 7;
    data['Shift Hours'] = shiftHours;
    data['missingpunch_balance'] = missingPunchBalance ?? 3;
    data['email'] = "${id.toString()}@demo.local";
    data['advance_on_salary_eligibility_date'] = advanceOnSalaryEligibilityDate?.toIso8601String();
    data['groups'] = groups;
    data['National ID'] = nationalId;
    data['Arabic Nickname'] = arabicNickname;
    data['English Nickname'] = englishNickname;
    data['login_code'] = loginCode;
    data['Phone Number'] = phoneNumber;
    data['Address'] = address;
    data['Suspension Reason'] = suspensionReason;
    // Date-only string so it fits the Postgres `date` column.
    data['Last Working Date'] = lastWorkingDate?.toIso8601String().split('T').first;
    return data;
  }

  UserModel copyWith({
    int? id,
    String? arabicName,
    String? englishName,
    String? title,
    String? englishTitle,
    String? department,
    String? englishDepartment,
    String? location,
    String? costCenter,
    String? hireDate,
    int? n1,
    int? n2,
    String? email,
    int? leavesEligibility,
    int? workingDays,
    double? leaveBalance,
    double? overtimeBalance,
    double? emergencyBalance,
    int? shiftHours,
    String? n1EnglishName,
    String? n1ArabicName,
    String? n2EnglishName,
    String? n2ArabicName,
    int? missingPunchBalance,
    String? authEmail,
    DateTime? advanceOnSalaryEligibilityDate,
    List<String>? groups,
    String? nationalId,
    String? arabicNickname,
    String? englishNickname,
    String? userState,
    int? loginCode,
    String? phoneNumber,
    String? address,
    String? suspensionReason,
    DateTime? lastWorkingDate,
    double? annualRemainingBalance,
    double? carryForwardBalance,
    double? overtimeCarryForwardBalance,
    double? daysTakenThisYear,
    double? monthlyLeaveRate,
  }) {
    return UserModel(
      id: id ?? this.id,
      arabicName: arabicName ?? this.arabicName,
      englishName: englishName ?? this.englishName,
      title: title ?? this.title,
      englishTitle: englishTitle ?? this.englishTitle,
      department: department ?? this.department,
      englishDepartment: englishDepartment ?? this.englishDepartment,
      location: location ?? this.location,
      costCenter: costCenter ?? this.costCenter,
      hireDate: hireDate ?? this.hireDate,
      n1: n1 ?? this.n1,
      n2: n2 ?? this.n2,
      email: email ?? this.email,
      leavesEligibility: leavesEligibility ?? this.leavesEligibility,
      workingDays: workingDays ?? this.workingDays,
      leaveBalance: leaveBalance ?? this.leaveBalance,
      overtimeBalance: overtimeBalance ?? this.overtimeBalance,
      emergencyBalance: emergencyBalance ?? this.emergencyBalance,
      shiftHours: shiftHours ?? this.shiftHours,
      n1EnglishName: n1EnglishName ?? this.n1EnglishName,
      n1ArabicName: n1ArabicName ?? this.n1ArabicName,
      n2EnglishName: n2EnglishName ?? this.n2EnglishName,
      n2ArabicName: n2ArabicName ?? this.n2ArabicName,
      missingPunchBalance: missingPunchBalance ?? this.missingPunchBalance,
      authEmail: authEmail ?? this.authEmail,
      advanceOnSalaryEligibilityDate: advanceOnSalaryEligibilityDate ?? this.advanceOnSalaryEligibilityDate,
      groups: groups ?? this.groups,
      nationalId: nationalId ?? this.nationalId,
      arabicNickname: arabicNickname ?? this.arabicNickname,
      englishNickname: englishNickname ?? this.englishNickname,
      userState: userState ?? this.userState,
      loginCode: loginCode ?? this.loginCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      lastWorkingDate: lastWorkingDate ?? this.lastWorkingDate,
      annualRemainingBalance: annualRemainingBalance ?? this.annualRemainingBalance,
      carryForwardBalance: carryForwardBalance ?? this.carryForwardBalance,
      overtimeCarryForwardBalance: overtimeCarryForwardBalance ?? this.overtimeCarryForwardBalance,
      daysTakenThisYear: daysTakenThisYear ?? this.daysTakenThisYear,
      monthlyLeaveRate: monthlyLeaveRate ?? this.monthlyLeaveRate,
    );
  }

  /// Get the localized nickname (falls back to name if nickname is absent)
  String? getLocalizedNickname(String locale) {
    if (locale == 'ar') return arabicNickname ?? arabicName ?? englishNickname ?? englishName;
    return englishNickname ?? englishName ?? arabicNickname ?? arabicName;
  }

  /// Get the localized name based on the current locale
  String getLocalizedName(String locale) {
    if (locale == 'ar' && arabicName != null && arabicName!.isNotEmpty) {
      return arabicName!;
    }
    return englishName ?? '';
  }

  /// Get the localized title based on the current locale
  String getLocalizedTitle(String locale) {
    if (locale == 'ar') {
      return title ?? '';
    }
    return englishTitle ?? title ?? '';
  }

  /// Get the localized department based on the current locale
  String getLocalizedDepartment(String locale) {
    if (locale == 'ar') {
      return department ?? '';
    }
    return englishDepartment ?? department ?? '';
  }
}
