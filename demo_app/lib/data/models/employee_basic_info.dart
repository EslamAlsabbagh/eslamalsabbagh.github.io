/// Employee basic information model for name enrichment in investigations
///
/// This lightweight model fetches and displays employee names in investigation dialogs
/// without storing full employee data in investigation records.
class EmployeeBasicInfo {
  final int code;
  final String? englishName;
  final String? arabicName;
  final String? departmentName;
  final String? arabicDepartmentName;
  final String? hireDate;

  const EmployeeBasicInfo({
    required this.code,
    this.englishName,
    this.arabicName,
    this.departmentName,
    this.arabicDepartmentName,
    this.hireDate,
  });

  /// Factory constructor from Supabase users table JSON
  factory EmployeeBasicInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeBasicInfo(
      code: json['Code'] as int,
      englishName: json['English Name'] as String?,
      arabicName: json['Arabic Name'] as String?,
      departmentName: json['english_department'] as String?,
      arabicDepartmentName: json['Department'] as String?,
      hireDate: json['Hire Date'] as String?,
    );
  }

  /// Get display name based on locale
  String getDisplayName(bool isArabic) {
    if (isArabic && arabicName != null) {
      return arabicName!;
    } else if (englishName != null) {
      return englishName!;
    } else {
      return 'Unknown';
    }
  }

  /// Get full display with code: "John Doe (1234)"
  String getFullDisplay(bool isArabic) {
    final name = getDisplayName(isArabic);
    return '$name ($code)';
  }
}
