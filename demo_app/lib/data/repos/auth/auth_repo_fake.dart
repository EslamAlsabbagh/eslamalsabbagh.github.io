// In-memory stand-in for AuthRepo.
//
// The demo has no identity provider. Any seeded employee code signs in, with
// any password — the sign-in screen exists to show the flow, not to guard
// anything. Unknown codes still fail, so the error path stays demonstrable.

import 'package:hrms_demo/data/repos/auth/auth_repo.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeAuthRepo implements AuthRepo {
  FakeAuthRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  @override
  Future<String?> login(String code, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final parsed = int.tryParse(code.trim());
    final user = store.userByCode(parsed);
    if (user == null) throw Exception('invalidCredentials');
    if (user.isSuspended) throw Exception('suspended');
    store.switchUser(user.id!);
    return user.id.toString();
  }

  @override
  Future<bool> signup(String password, String email) async => true;

  @override
  Future<bool> createEmployeeAuthAccount(String password, String email) async => true;

  @override
  Future<void> updatePassword(
    String code,
    String oldPassword,
    String newPassword,
    String confirmPassword,
  ) async {}

  @override
  Future<void> resetEmployeePassword(String employeeCode) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
