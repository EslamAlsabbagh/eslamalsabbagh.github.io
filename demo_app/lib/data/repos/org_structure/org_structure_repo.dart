import 'package:hrms_demo/data/models/org_structure/org_structure_models.dart';

/// Read/write gateway for the Org Structure Builder over the four org tables.
///
/// Every method talks to Supabase via the PostgREST query builder and RETURNS
/// THE PERSISTED ROW (or void for deletes). Methods THROW on failure — the DB
/// enforces the real integrity rules (the department cycle trigger, the
/// unique-sibling-name constraint, and `on delete restrict` FKs), so a rejected
/// write surfaces here as a thrown PostgrestException that the Bloc catches and
/// turns into an inline warning. RLS additionally rejects writes from callers
/// who are not HR / Top Management.
abstract class OrgStructureRepo {
  /// Load the entire structure in one shot (four parallel selects).
  Future<OrgSnapshot> loadAll();

  // ── Locations ──────────────────────────────────────────────────────────────
  Future<Location> createLocation({required String name, String? nameAr, required String code});
  Future<Location> updateLocation(int id, {String? name, String? nameAr, String? code, bool? isActive});
  Future<void> deleteLocation(int id);

  // ── Departments ──────────────────────────────────────────────────────────────
  Future<Department> createDepartment({required String name, String? nameAr, String? code, int? parentId});
  Future<Department> updateDepartment(int id, {String? name, String? nameAr, String? code, bool? isActive});

  /// Move a department under [newParentId] (null = top-level). The
  /// `trg_department_cycle` trigger rejects a move that would create a loop.
  Future<Department> reparentDepartment(int id, int? newParentId);
  Future<void> deleteDepartment(int id);

  // ── Department ↔ Location links ────────────────────────────────────────────
  Future<DepartmentLocation> connect(int departmentId, int locationId);
  Future<void> disconnect(int linkId);

  /// Set (or clear, when [positionId] is null) the link's manager position.
  Future<DepartmentLocation> setManager(int linkId, int? positionId);

  // ── Positions ────────────────────────────────────────────────────────────────
  Future<Position> createPosition({required int deptLocId, required String title, String? titleAr, String? grade, int? reportsToId, bool isActive});
  Future<Position> updatePosition(int id, {String? title, String? titleAr, String? grade, bool? isActive});

  /// Set (or clear, when [reportsToId] is null) a position's reporting line.
  Future<Position> setReportsTo(int id, int? reportsToId);
  Future<void> deletePosition(int id);
}
