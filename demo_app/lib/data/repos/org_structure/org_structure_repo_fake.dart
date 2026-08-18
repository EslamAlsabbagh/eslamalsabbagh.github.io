// GENERATED SCAFFOLD - in-memory stand-in for OrgStructureRepo.
//
// The demo build has no backend. Every member below returns a type-correct
// empty value unless it has been hand-written to read from DemoStore, so a
// screen that touches an unmodelled corner renders empty instead of crashing.

import 'package:hrms_demo/data/models/org_structure/org_structure_models.dart';
import 'package:hrms_demo/data/repos/org_structure/org_structure_repo.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeOrgStructureRepo implements OrgStructureRepo {
  FakeOrgStructureRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  @override
  Future<OrgSnapshot> loadAll() async => throw UnimplementedError('OrgStructureRepo.loadAll is not part of the demo dataset.');

  @override
  Future<Location> createLocation({required String name, String? nameAr, required String code}) async => throw UnimplementedError('OrgStructureRepo.createLocation is not part of the demo dataset.');

  @override
  Future<Location> updateLocation(int id, {String? name, String? nameAr, String? code, bool? isActive}) async => throw UnimplementedError('OrgStructureRepo.updateLocation is not part of the demo dataset.');

  @override
  Future<void> deleteLocation(int id) async {}

  @override
  Future<Department> createDepartment({required String name, String? nameAr, String? code, int? parentId}) async => throw UnimplementedError('OrgStructureRepo.createDepartment is not part of the demo dataset.');

  @override
  Future<Department> updateDepartment(int id, {String? name, String? nameAr, String? code, bool? isActive}) async => throw UnimplementedError('OrgStructureRepo.updateDepartment is not part of the demo dataset.');

  @override
  Future<Department> reparentDepartment(int id, int? newParentId) async => throw UnimplementedError('OrgStructureRepo.reparentDepartment is not part of the demo dataset.');

  @override
  Future<void> deleteDepartment(int id) async {}

  @override
  Future<DepartmentLocation> connect(int departmentId, int locationId) async => throw UnimplementedError('OrgStructureRepo.connect is not part of the demo dataset.');

  @override
  Future<void> disconnect(int linkId) async {}

  @override
  Future<DepartmentLocation> setManager(int linkId, int? positionId) async => throw UnimplementedError('OrgStructureRepo.setManager is not part of the demo dataset.');

  @override
  Future<Position> createPosition({required int deptLocId, required String title, String? titleAr, String? grade, int? reportsToId, bool isActive = true}) async => throw UnimplementedError('OrgStructureRepo.createPosition is not part of the demo dataset.');

  @override
  Future<Position> updatePosition(int id, {String? title, String? titleAr, String? grade, bool? isActive}) async => throw UnimplementedError('OrgStructureRepo.updatePosition is not part of the demo dataset.');

  @override
  Future<Position> setReportsTo(int id, int? reportsToId) async => throw UnimplementedError('OrgStructureRepo.setReportsTo is not part of the demo dataset.');

  @override
  Future<void> deletePosition(int id) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
