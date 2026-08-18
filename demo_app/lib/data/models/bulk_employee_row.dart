import 'package:hrms_demo/data/models/user_model.dart';

/// Represents a single row in the bulk employee upload with validation status
class BulkEmployeeRow {
  final int rowIndex;
  final String? englishName;
  final String? arabicName;
  final String? arabicTitle;
  final String? englishTitle;
  final String? departmentArabic;
  final String? departmentEnglish;
  final String? employeeCode;
  final String? hireDate;
  final String? n1Code;
  final String? n2Code;
  final String? location;
  final String? costCenter;
  final String? shiftHours;
  final String? workingDays;
  final String? leavesEligibility;
  final String? email;
  final String? nationalId;
  final String? englishNickname;
  final String? arabicNickname;

  // Validation status
  final Map<String, String> validationErrors;
  final bool isEdited;

  const BulkEmployeeRow({
    required this.rowIndex,
    this.englishName,
    this.arabicName,
    this.arabicTitle,
    this.englishTitle,
    this.departmentArabic,
    this.departmentEnglish,
    this.employeeCode,
    this.hireDate,
    this.n1Code,
    this.n2Code,
    this.location,
    this.costCenter,
    this.shiftHours,
    this.workingDays,
    this.leavesEligibility,
    this.email,
    this.nationalId,
    this.englishNickname,
    this.arabicNickname,
    this.validationErrors = const {},
    this.isEdited = false,
  });

  /// Check if the row has any validation errors
  bool get hasErrors => validationErrors.isNotEmpty;

  /// Check if the row is valid (no errors)
  bool get isValid => validationErrors.isEmpty;

  /// Get error message for a specific field
  String? getError(String field) => validationErrors[field];

  /// Check if a specific field has an error
  bool hasError(String field) => validationErrors.containsKey(field);

  /// Create a copy with updated values
  BulkEmployeeRow copyWith({
    int? rowIndex,
    String? englishName,
    String? arabicName,
    String? arabicTitle,
    String? englishTitle,
    String? departmentArabic,
    String? departmentEnglish,
    String? employeeCode,
    String? hireDate,
    String? n1Code,
    String? n2Code,
    String? location,
    String? costCenter,
    String? shiftHours,
    String? workingDays,
    String? leavesEligibility,
    String? email,
    String? nationalId,
    String? englishNickname,
    String? arabicNickname,
    Map<String, String>? validationErrors,
    bool? isEdited,
    bool clearField = false,
    String? clearFieldName,
  }) {
    // Handle field clearing
    Map<String, String> newErrors = Map<String, String>.from(validationErrors ?? this.validationErrors);
    if (clearField && clearFieldName != null) {
      newErrors.remove(clearFieldName);
    }

    return BulkEmployeeRow(
      rowIndex: rowIndex ?? this.rowIndex,
      englishName: englishName ?? this.englishName,
      arabicName: arabicName ?? this.arabicName,
      arabicTitle: arabicTitle ?? this.arabicTitle,
      englishTitle: englishTitle ?? this.englishTitle,
      departmentArabic: departmentArabic ?? this.departmentArabic,
      departmentEnglish: departmentEnglish ?? this.departmentEnglish,
      employeeCode: employeeCode ?? this.employeeCode,
      hireDate: hireDate ?? this.hireDate,
      n1Code: n1Code ?? this.n1Code,
      n2Code: n2Code ?? this.n2Code,
      location: location ?? this.location,
      costCenter: costCenter ?? this.costCenter,
      shiftHours: shiftHours ?? this.shiftHours,
      workingDays: workingDays ?? this.workingDays,
      leavesEligibility: leavesEligibility ?? this.leavesEligibility,
      email: email ?? this.email,
      nationalId: nationalId ?? this.nationalId,
      englishNickname: englishNickname ?? this.englishNickname,
      arabicNickname: arabicNickname ?? this.arabicNickname,
      validationErrors: newErrors,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  /// Convert to UserModel for database insertion
  UserModel toUserModel() {
    return UserModel(
      id: int.tryParse(employeeCode ?? ''),
      englishName: englishName,
      arabicName: arabicName,
      title: arabicTitle,
      englishTitle: englishTitle,
      department: departmentArabic,
      englishDepartment: departmentEnglish,
      hireDate: hireDate,
      n1: int.tryParse(n1Code ?? ''),
      n2: int.tryParse(n2Code ?? ''),
      location: location,
      costCenter: costCenter,
      shiftHours: int.tryParse(shiftHours ?? ''),
      workingDays: int.tryParse(workingDays ?? ''),
      leavesEligibility: int.tryParse(leavesEligibility ?? ''),
      email: email,
      nationalId: nationalId,
      englishNickname: englishNickname,
      arabicNickname: arabicNickname,
      // "Leave Balance" / annual_remaining_balance are projected from hire date +
      // eligibility by initialize_new_hire_leave_balance (called in
      // UsersRepoImpl.addEmployee), not seeded to the full eligibility here.
    );
  }

  /// Create from a map (CSV/Excel row)
  factory BulkEmployeeRow.fromMap(Map<String, dynamic> map, int rowIndex) {
    return BulkEmployeeRow(
      rowIndex: rowIndex,
      englishName:
          _parseString(map['english_name']) ?? _parseString(map['English Name']) ?? _parseString(map['englishName']),
      arabicName:
          _parseString(map['arabic_name']) ?? _parseString(map['Arabic Name']) ?? _parseString(map['arabicName']),
      arabicTitle:
          _parseString(map['arabic_title']) ??
          _parseString(map['Arabic Title']) ??
          _parseString(map['arabicTitle']) ??
          _parseString(map['title']) ??
          _parseString(map['Title']),
      englishTitle:
          _parseString(map['english_title']) ?? _parseString(map['English Title']) ?? _parseString(map['englishTitle']),
      departmentArabic:
          _parseString(map['department_arabic']) ??
          _parseString(map['Department Arabic']) ??
          _parseString(map['departmentArabic']) ??
          _parseString(map['department']) ??
          _parseString(map['Department']),
      departmentEnglish:
          _parseString(map['department_english']) ??
          _parseString(map['Department English']) ??
          _parseString(map['departmentEnglish']) ??
          _parseString(map['english_department']) ??
          _parseString(map['English Department']),
      employeeCode:
          _parseString(map['employee_code']) ??
          _parseString(map['Employee Code']) ??
          _parseString(map['employeeCode']) ??
          _parseString(map['code']) ??
          _parseString(map['Code']),
      hireDate: _parseString(map['hire_date']) ?? _parseString(map['Hire Date']) ?? _parseString(map['hireDate']),
      n1Code:
          _parseString(map['n1_code']) ??
          _parseString(map['N1 Code']) ??
          _parseString(map['n1Code']) ??
          _parseString(map['n+1']) ??
          _parseString(map['N+1']),
      n2Code:
          _parseString(map['n2_code']) ??
          _parseString(map['N2 Code']) ??
          _parseString(map['n2Code']) ??
          _parseString(map['n+2']) ??
          _parseString(map['N+2']),
      location:
          _parseString(map['location']) ??
          _parseString(map['Location']) ??
          _parseString(map['site']) ??
          _parseString(map['Site']),
      costCenter:
          _parseString(map['cost_center']) ?? _parseString(map['Cost Center']) ?? _parseString(map['costCenter']),
      shiftHours:
          _parseString(map['shift_hours']) ?? _parseString(map['Shift Hours']) ?? _parseString(map['shiftHours']),
      workingDays:
          _parseString(map['working_days']) ?? _parseString(map['Working Days']) ?? _parseString(map['workingDays']),
      leavesEligibility:
          _parseString(map['leaves_eligibility']) ??
          _parseString(map['Leaves Eligibility']) ??
          _parseString(map['leavesEligibility']),
      email:
          _parseString(map['email']) ??
          _parseString(map['Email']) ??
          _parseString(map['real_email']) ??
          _parseString(map['Real Email']),
      nationalId:
          _parseString(map['national_id']) ?? _parseString(map['National ID']) ?? _parseString(map['nationalId']),
      englishNickname:
          _parseString(map['english_nickname']) ??
          _parseString(map['English Nickname']) ??
          _parseString(map['englishNickname']),
      arabicNickname:
          _parseString(map['arabic_nickname']) ??
          _parseString(map['Arabic Nickname']) ??
          _parseString(map['arabicNickname']),
    );
  }

  /// Parse string value, handling null and empty strings
  static String? _parseString(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  @override
  String toString() {
    return 'BulkEmployeeRow(rowIndex: $rowIndex, employeeCode: $employeeCode, englishName: $englishName, hasErrors: $hasErrors)';
  }
}

/// Enum for bulk upload status
enum BulkUploadStatus { initial, parsing, validating, ready, uploading, success, partialSuccess, error }

/// Extension to get display name for status
extension BulkUploadStatusExtension on BulkUploadStatus {
  String get displayName {
    switch (this) {
      case BulkUploadStatus.initial:
        return 'Initial';
      case BulkUploadStatus.parsing:
        return 'Parsing File...';
      case BulkUploadStatus.validating:
        return 'Validating Data...';
      case BulkUploadStatus.ready:
        return 'Ready to Submit';
      case BulkUploadStatus.uploading:
        return 'Uploading...';
      case BulkUploadStatus.success:
        return 'Success';
      case BulkUploadStatus.partialSuccess:
        return 'Partial Success';
      case BulkUploadStatus.error:
        return 'Error';
    }
  }
}
