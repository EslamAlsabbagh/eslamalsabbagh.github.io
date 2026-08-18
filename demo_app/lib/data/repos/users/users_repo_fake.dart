// In-memory stand-in for UsersRepo, backed by DemoStore.
//
// The demo build has no backend. Reads resolve against the seeded organisation
// in DemoStore; writes mutate it and are visible immediately. Nothing in this
// file touches the network.

import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeUsersRepo implements UsersRepo {
  FakeUsersRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  /// Hydrates the N+1 / N+2 display names the UI expects on a loaded row. The
  /// production query does this with two joins; here it is a map lookup.
  UserModel _withManagers(UserModel u) {
    final n1 = store.userByCode(u.n1);
    final n2 = store.userByCode(u.n2);
    return u.copyWith(
      n1EnglishName: n1?.englishName,
      n1ArabicName: n1?.arabicName,
      n2EnglishName: n2?.englishName,
      n2ArabicName: n2?.arabicName,
    );
  }

  List<UserModel> _all() => store.users.map(_withManagers).toList();

  bool _matches(UserModel u, String term) {
    final t = term.trim().toLowerCase();
    if (t.isEmpty) return true;
    return (u.englishName ?? '').toLowerCase().contains(t) ||
        (u.arabicName ?? '').contains(term.trim()) ||
        (u.id?.toString() ?? '').contains(t) ||
        (u.englishTitle ?? '').toLowerCase().contains(t) ||
        (u.englishDepartment ?? '').toLowerCase().contains(t);
  }

  @override
  Future<List<UserModel>> getUsers({String? locale}) async => _all();

  @override
  Future<UserModel?> fetchUserProfile(String code, {String? locale}) async {
    final u = store.userByCode(int.tryParse(code));
    return u == null ? null : _withManagers(u);
  }

  @override
  Future<List<UserModel>> searchEmployees(String searchTerm, {String? locale}) async =>
      _all().where((u) => _matches(u, searchTerm)).toList();

  @override
  Future<List<UserModel>> searchManagedEmployees(
    String searchTerm,
    int managerCode,
  ) async => store
      .directReports(managerCode)
      .map(_withManagers)
      .where((u) => _matches(u, searchTerm))
      .toList();

  @override
  Future<List<UserModel>> getAllManagedEmployees(int managerCode) async =>
      store.directReports(managerCode).map(_withManagers).toList();

  @override
  Future<List<UserModel>> getAllIndirectEmployees(int managerCode) async =>
      store.indirectReports(managerCode).map(_withManagers).toList();

  @override
  Future<List<UserModel>> searchIndirectEmployees(
    String searchTerm,
    int managerCode,
  ) async => store
      .indirectReports(managerCode)
      .map(_withManagers)
      .where((u) => _matches(u, searchTerm))
      .toList();

  @override
  Future<List<UserModel>> searchEmployeesByDepartment(
    String department, {
    String? locale,
  }) async => _all()
      .where((u) =>
          (u.englishDepartment ?? '').toLowerCase() == department.toLowerCase() ||
          (u.department ?? '') == department)
      .toList();

  @override
  Future<UserModel> addEmployee(UserModel employee) async {
    final nextId = store.users
            .map((u) => u.id ?? 0)
            .fold<int>(0, (a, b) => a > b ? a : b) +
        1;
    final created = employee.copyWith(
      id: employee.id ?? nextId,
      userState: employee.userState ?? 'active',
    );
    store.upsertUser(created);
    return _withManagers(created);
  }

  @override
  Future<UserModel> updateEmployee(UserModel employee, {int? actorCode}) async {
    store.upsertUser(employee);
    return _withManagers(employee);
  }

  @override
  Future<void> updateEmployeeManager(
    int employeeId, {
    required int n1,
    int? n2,
    int? actorCode,
  }) async {
    final u = store.userByCode(employeeId);
    if (u != null) store.upsertUser(u.copyWith(n1: n1, n2: n2));
  }

  @override
  Future<void> updateEmployeeNameTitle(
    int employeeId, {
    required String englishName,
    required String englishTitle,
    int? actorCode,
  }) async {
    final u = store.userByCode(employeeId);
    if (u != null) {
      store.upsertUser(
        u.copyWith(englishName: englishName, englishTitle: englishTitle),
      );
    }
  }

  @override
  Future<void> updateEmployeeContactInfo(
    int employeeId, {
    String? phoneNumber,
    String? address,
  }) async {
    final u = store.userByCode(employeeId);
    if (u != null) {
      store.upsertUser(u.copyWith(
        phoneNumber: phoneNumber ?? u.phoneNumber,
        address: address ?? u.address,
      ));
    }
  }

  @override
  Future<List<UserModel>> getPaginatedEmployees({
    int offset = 0,
    int limit = 10,
    String? locale,
  }) async {
    final all = _all();
    if (offset >= all.length) return const [];
    return all.skip(offset).take(limit).toList();
  }

  @override
  Future<UserModel> getEmployeeById(int employeeId) async {
    final u = store.userByCode(employeeId);
    if (u == null) {
      throw StateError('No employee with code $employeeId in the demo dataset.');
    }
    return _withManagers(u);
  }

  @override
  Future<void> suspendEmployee(int employeeId) async {
    final u = store.userByCode(employeeId);
    if (u != null) store.upsertUser(u.copyWith(userState: 'suspended'));
  }

  @override
  Future<void> unsuspendEmployee(int employeeId) async {
    final u = store.userByCode(employeeId);
    if (u != null) store.upsertUser(u.copyWith(userState: 'active'));
  }

  @override
  Future<bool> isEmployeeSuspended(int employeeId) async =>
      store.userByCode(employeeId)?.isSuspended ?? false;

  @override
  Future<DateTime> getCurrentServerDate() async => DateTime.now();

  @override
  Future<int> getManagedEmployeesCount(int managerCode) async =>
      store.directReports(managerCode).length;

  @override
  Future<List<UserModel>> getAllDeepSubordinates(int managerCode) async =>
      store.deepSubordinates(managerCode).map(_withManagers).toList();

  @override
  Future<List<UserModel>> searchDeepSubordinates(
    String searchTerm,
    int managerCode,
  ) async => store
      .deepSubordinates(managerCode)
      .map(_withManagers)
      .where((u) => _matches(u, searchTerm))
      .toList();

  @override
  Future<List<UserModel>> searchAllActiveEmployees(String searchTerm) async =>
      _all().where((u) => !u.isSuspended && _matches(u, searchTerm)).toList();

  @override
  Future<void> incrementOvertimeBalances({
    required List<int> userIds,
    required double delta,
    int? actorCode,
  }) async {
    for (final id in userIds) {
      final u = store.userByCode(id);
      if (u != null) {
        store.upsertUser(
          u.copyWith(overtimeBalance: (u.overtimeBalance ?? 0) + delta),
        );
      }
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
