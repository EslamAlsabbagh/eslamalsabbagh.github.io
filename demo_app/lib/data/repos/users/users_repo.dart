import 'package:hrms_demo/data/models/user_model.dart';

abstract interface class UsersRepo {
  Future<List<UserModel>> getUsers({String? locale});
  Future<UserModel?> fetchUserProfile(String code, {String? locale});
  Future<List<UserModel>> searchEmployees(String searchTerm, {String? locale});
  Future<List<UserModel>> searchManagedEmployees(
    String searchTerm,
    int managerCode,
  );
  Future<List<UserModel>> getAllManagedEmployees(int managerCode);
  Future<List<UserModel>> getAllIndirectEmployees(int managerCode);
  Future<List<UserModel>> searchIndirectEmployees(
    String searchTerm,
    int managerCode,
  );
  Future<List<UserModel>> searchEmployeesByDepartment(
    String department, {
    String? locale,
  });
  Future<UserModel> addEmployee(UserModel employee);

  /// Updates an employee. Balance columns are routed through the audited
  /// `apply_manual_balance_edit` RPC; [actorCode] is the editing HR user's
  /// code, recorded in the resulting leave_balance_ledger rows.
  Future<UserModel> updateEmployee(UserModel employee, {int? actorCode});

  /// Reassigns an employee's direct manager (N+1) and second-level manager
  /// (N+2) with a *targeted* two-column update, leaving every other column
  /// untouched. Used by the org-chart manager picker, where only those four
  /// columns are loaded for each node — routing through [updateEmployee] would
  /// null out the unloaded columns. [actorCode] is the HR/Top-Management user
  /// performing the change (reserved for future hierarchy-change auditing).
  Future<void> updateEmployeeManager(
    int employeeId, {
    required int n1,
    int? n2,
    int? actorCode,
  });

  /// Updates an employee's English display name and title with a *targeted*
  /// two-column update (`English Name`, `english_title`), leaving every other
  /// column untouched. Used by the org-chart side panel's inline name/position
  /// edit, where only a few columns are loaded per node — routing through
  /// [updateEmployee] would null out the unloaded columns. [actorCode] is the
  /// HR/Top-Management user performing the change (reserved for future auditing).
  Future<void> updateEmployeeNameTitle(
    int employeeId, {
    required String englishName,
    required String englishTitle,
    int? actorCode,
  });

  /// Updates an employee's self-provided contact info (`Phone Number`,
  /// `Address`) with a *targeted* two-column update, leaving every other column
  /// untouched. Used by the employee self-service profile page, where the
  /// current `UserModel` may not have every column hydrated — routing through
  /// [updateEmployee] would null out the unloaded columns.
  Future<void> updateEmployeeContactInfo(
    int employeeId, {
    String? phoneNumber,
    String? address,
  });
  Future<List<UserModel>> getPaginatedEmployees({
    int offset = 0,
    int limit = 10,
    String? locale,
  });
  Future<UserModel> getEmployeeById(int employeeId);
  Future<void> suspendEmployee(int employeeId);
  Future<void> unsuspendEmployee(int employeeId);
  Future<bool> isEmployeeSuspended(int employeeId);
  Future<DateTime> getCurrentServerDate();
  Future<int> getManagedEmployeesCount(int managerCode);

  /// Gets all subordinates at level 3+ (N+3, N+4, etc.)
  /// Excludes N+1 (direct) and N+2 (indirect) as they have separate methods
  Future<List<UserModel>> getAllDeepSubordinates(int managerCode);

  /// Search within level 3+ subordinates
  Future<List<UserModel>> searchDeepSubordinates(
    String searchTerm,
    int managerCode,
  );

  /// Search all active (non-suspended) employees by name or code.
  /// Used for N+1 reassignment picker in the suspension dialog.
  Future<List<UserModel>> searchAllActiveEmployees(String searchTerm);

  /// Adds [delta] days to each employee's overtime_balance via the audited
  /// `bulk_increment_overtime_balance` RPC. [actorCode] is the HR user
  /// performing the bulk grant, recorded in each ledger row.
  Future<void> incrementOvertimeBalances({
    required List<int> userIds,
    required double delta,
    int? actorCode,
  });
}
