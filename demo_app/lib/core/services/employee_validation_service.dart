import 'package:hrms_demo/core/constants/department.dart';
import 'package:hrms_demo/data/models/bulk_employee_row.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';

/// Service for validating bulk employee data
class EmployeeValidationService {
  final UsersRepo _usersRepo;

  EmployeeValidationService(this._usersRepo);

  /// Valid location values
  static const List<String> validLocations = ['RIVERSIDE', 'HARBOUR', 'HQ'];

  /// Valid cost center values
  static const List<String> validCostCenters = ['RIVERSIDE', 'HARBOUR', 'GATEWAY', 'Company', 'MARINA'];

  /// Valid shift hours values
  static const List<String> validShiftHours = ['8', '9', '12'];

  /// Valid working days values
  static const List<String> validWorkingDays = ['5', '6'];

  /// Valid leaves eligibility values
  static const List<String> validLeavesEligibility = ['15', '21', '30'];

  /// Validate a single employee row
  Future<BulkEmployeeRow> validateRow(
    BulkEmployeeRow row, {
    Map<int, int>? codeCountsInFile,
    Set<int>? existingCodesInDb,
    Set<int>? validCodesInFile,
    Map<int, bool>? n1ExistenceCache,
  }) async {
    final errors = <String, String>{};

    // Validate employee code
    final codeError = _validateEmployeeCode(row.employeeCode, codeCountsInFile, existingCodesInDb);
    if (codeError != null) {
      errors['employeeCode'] = codeError;
    }

    // Validate required fields
    if (row.englishName == null || row.englishName!.trim().isEmpty) {
      errors['englishName'] = 'English name is required';
    }

    if (row.arabicName == null || row.arabicName!.trim().isEmpty) {
      errors['arabicName'] = 'Arabic name is required';
    }

    if (row.arabicTitle == null || row.arabicTitle!.trim().isEmpty) {
      errors['arabicTitle'] = 'Arabic title is required';
    }

    if (row.englishTitle == null || row.englishTitle!.trim().isEmpty) {
      errors['englishTitle'] = 'English title is required';
    }

    // Auto-fill departmentEnglish from Arabic when English is absent/invalid.
    // This prevents an invisible validation error for rows from CSVs that only
    // provide an Arabic department column.
    final resolvedEnglish =
        isValidDepartment(row.departmentEnglish, false)
            ? row.departmentEnglish
            : getEnglishDepartment(row.departmentArabic);

    // Validate department
    final deptErrors = _validateDepartment(row.departmentArabic, resolvedEnglish);
    errors.addAll(deptErrors);

    // Validate hire date
    if (row.hireDate == null || row.hireDate!.trim().isEmpty) {
      errors['hireDate'] = 'Hire date is required';
    }

    // Validate N+1
    final n1Error = await _validateN1(row.n1Code, n1ExistenceCache, validCodesInFile);
    if (n1Error != null) {
      errors['n1Code'] = n1Error;
    }

    // Validate dropdown fields
    if (!isValidLocation(row.location)) {
      errors['location'] = 'Invalid location. Valid values: ${validLocations.join(', ')}';
    }

    if (!isValidCostCenter(row.costCenter)) {
      errors['costCenter'] = 'Invalid cost center. Valid values: ${validCostCenters.join(', ')}';
    }

    if (!isValidShiftHours(row.shiftHours)) {
      errors['shiftHours'] = 'Invalid shift hours. Valid values: ${validShiftHours.join(', ')}';
    }

    if (!isValidWorkingDays(row.workingDays)) {
      errors['workingDays'] = 'Invalid working days. Valid values: ${validWorkingDays.join(', ')}';
    }

    if (!isValidLeavesEligibility(row.leavesEligibility)) {
      errors['leavesEligibility'] = 'Invalid leaves eligibility. Valid values: ${validLeavesEligibility.join(', ')}';
    }

    // Validate email format if provided
    if (row.email != null && row.email!.isNotEmpty) {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(row.email!)) {
        errors['email'] = 'Invalid email format';
      }
    }

    // Persist the auto-filled English department so toUserModel() has a value.
    return row.copyWith(
      departmentEnglish: resolvedEnglish ?? row.departmentEnglish,
      validationErrors: errors,
    );
  }

  /// Validate all rows in a batch
  Future<List<BulkEmployeeRow>> validateAllRows(List<BulkEmployeeRow> rows) async {
    // Count employee codes in the file to detect duplicates
    final codeCounts = <int, int>{};
    for (final row in rows) {
      final code = int.tryParse(row.employeeCode ?? '');
      if (code != null) {
        codeCounts[code] = (codeCounts[code] ?? 0) + 1;
      }
    }

    // Get unique codes for database check
    final codesInFile = codeCounts.keys.toSet();

    // Check which codes already exist in database
    final existingCodesInDb = await _checkExistingCodes(codesInFile);

    // Build set of valid employee codes in the file (non-duplicate, correct format, not in DB)
    final validCodesInFile = <int>{};
    for (final code in codesInFile) {
      if (_validateEmployeeCode(code.toString(), codeCounts, existingCodesInDb) == null) {
        validCodesInFile.add(code);
      }
    }

    // Cache for N+1 existence checks
    final n1ExistenceCache = <int, bool>{};

    // Validate each row
    final validatedRows = <BulkEmployeeRow>[];
    for (final row in rows) {
      final validatedRow = await validateRow(
        row,
        codeCountsInFile: codeCounts,
        existingCodesInDb: existingCodesInDb,
        validCodesInFile: validCodesInFile,
        n1ExistenceCache: n1ExistenceCache,
      );
      validatedRows.add(validatedRow);
    }

    return validatedRows;
  }

  /// Validate employee code
  String? _validateEmployeeCode(String? code, Map<int, int>? codeCountsInFile, Set<int>? existingCodesInDb) {
    if (code == null || code.trim().isEmpty) {
      return 'Employee code is required';
    }

    if (code.length != 6 && code.length != 8) {
      return 'Employee code must be exactly 6 or 8 digits';
    }

    final codeInt = int.tryParse(code);
    if (codeInt == null) {
      return 'Employee code must be a valid number';
    }

    // Check for duplicates within the file
    if (codeCountsInFile != null) {
      final count = codeCountsInFile[codeInt] ?? 0;
      if (count > 1) {
        return 'Duplicate employee code in file (appears $count times)';
      }
    }

    // Check if code already exists in database
    if (existingCodesInDb != null && existingCodesInDb.contains(codeInt)) {
      return 'Employee code already exists in database';
    }

    return null;
  }

  /// Validate department fields
  Map<String, String> _validateDepartment(String? arabic, String? english) {
    final errors = <String, String>{};

    // Check if Arabic department is valid
    bool arabicValid = isValidDepartment(arabic, true);
    bool englishValid = isValidDepartment(english, false);

    if (!arabicValid && (arabic == null || arabic.isEmpty)) {
      errors['departmentArabic'] = 'Department (Arabic) is required';
    } else if (!arabicValid) {
      errors['departmentArabic'] = 'Invalid department. Please select from the dropdown';
    }

    if (!englishValid && (english == null || english.isEmpty)) {
      errors['departmentEnglish'] = 'Department (English) is required';
    } else if (!englishValid) {
      errors['departmentEnglish'] = 'Invalid department. Please select from the dropdown';
    }

    return errors;
  }

  /// Validate N+1 code
  Future<String?> _validateN1(String? n1Code, Map<int, bool>? cache, Set<int>? validCodesInFile) async {
    if (n1Code == null || n1Code.trim().isEmpty) {
      return 'N+1 manager code is required';
    }

    if (n1Code.length != 6 && n1Code.length != 8) {
      return 'N+1 code must be exactly 6 or 8 digits';
    }

    final n1Int = int.tryParse(n1Code);
    if (n1Int == null) {
      return 'N+1 code must be a valid number';
    }

    // Accept N+1 if it's a valid employee code in the same uploaded file
    if (validCodesInFile != null && validCodesInFile.contains(n1Int)) {
      return null;
    }

    // Check cache first
    if (cache != null && cache.containsKey(n1Int)) {
      if (!cache[n1Int]!) {
        return 'N+1 manager not found';
      }
      return null;
    }

    // Check if N+1 exists in database
    try {
      final exists = await _checkEmployeeExists(n1Int);
      if (cache != null) {
        cache[n1Int] = exists;
      }
      if (!exists) {
        return 'N+1 manager not found';
      }
    } catch (e) {
      return 'Error validating N+1 manager';
    }

    return null;
  }

  /// Check if an employee exists in the database
  Future<bool> _checkEmployeeExists(int code) async {
    try {
      await _usersRepo.getEmployeeById(code);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check which codes already exist in the database
  Future<Set<int>> _checkExistingCodes(Set<int> codes) async {
    final existingCodes = <int>{};
    for (final code in codes) {
      if (await _checkEmployeeExists(code)) {
        existingCodes.add(code);
      }
    }
    return existingCodes;
  }

  /// Check if a department value is valid
  static bool isValidDepartment(String? value, bool isArabic) {
    if (value == null || value.isEmpty) return false;

    if (isArabic) {
      return Department.getAllArabicTextLabels().contains(value);
    } else {
      return Department.getAllEnglishTextLabels().contains(value);
    }
  }

  /// Check if a location value is valid
  static bool isValidLocation(String? value) {
    if (value == null || value.isEmpty) return false;
    return validLocations.contains(value.toUpperCase());
  }

  /// Check if a cost center value is valid
  static bool isValidCostCenter(String? value) {
    if (value == null || value.isEmpty) return false;
    return validCostCenters.contains(value);
  }

  /// Check if a shift hours value is valid
  static bool isValidShiftHours(String? value) {
    if (value == null || value.isEmpty) return false;
    return validShiftHours.contains(value);
  }

  /// Check if a working days value is valid
  static bool isValidWorkingDays(String? value) {
    if (value == null || value.isEmpty) return false;
    return validWorkingDays.contains(value);
  }

  /// Check if a leaves eligibility value is valid
  static bool isValidLeavesEligibility(String? value) {
    if (value == null || value.isEmpty) return false;
    return validLeavesEligibility.contains(value);
  }

  /// Get the corresponding English department for an Arabic department
  static String? getEnglishDepartment(String? arabicDept) {
    if (arabicDept == null) return null;
    return Department.getEnglishFromArabic(arabicDept);
  }

  /// Get the corresponding Arabic department for an English department
  static String? getArabicDepartment(String? englishDept) {
    if (englishDept == null) return null;
    return Department.getArabicFromEnglish(englishDept);
  }

  /// Get all valid Arabic departments
  static List<String> getAllArabicDepartments() {
    return Department.getAllArabicTextLabels();
  }

  /// Get all valid English departments
  static List<String> getAllEnglishDepartments() {
    return Department.getAllEnglishTextLabels();
  }
}
