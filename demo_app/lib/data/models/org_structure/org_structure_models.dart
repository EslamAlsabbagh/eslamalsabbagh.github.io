// Immutable DTOs for the Org Structure Builder. Each maps 1:1 onto a row of the
// four tables created by the 20260718120000_org_structure.sql migration
// (locations, departments, department_locations, positions). Kept thin — no
// integrity logic (the DB enforces cycles / delete-restrict / unique-sibling),
// just typed transport plus copyWith for optimistic edits and toInsert/toUpdate
// maps for PostgREST writes.

int _toInt(dynamic v) => v is int ? v : (v as num).toInt();
int? _toIntN(dynamic v) => v == null ? null : (v is int ? v : (v as num).toInt());
bool _toBool(dynamic v) => v == null ? true : v as bool;
String? _trimN(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();

/// A physical site (HQ, a store, a warehouse). `locations` table.
class Location {
  final int id;
  final String name;
  final String? nameAr;
  final String code;
  final bool isActive;

  const Location({
    required this.id,
    required this.name,
    this.nameAr,
    required this.code,
    this.isActive = true,
  });

  factory Location.fromJson(Map<String, dynamic> j) => Location(
        id: _toInt(j['id']),
        name: (j['name'] as String?)?.trim() ?? '',
        nameAr: _trimN(j['name_ar'] as String?),
        code: (j['code'] as String?)?.trim() ?? '',
        isActive: _toBool(j['is_active']),
      );

  Location copyWith({String? name, String? nameAr, String? code, bool? isActive}) => Location(
        id: id,
        name: name ?? this.name,
        nameAr: nameAr ?? this.nameAr,
        code: code ?? this.code,
        isActive: isActive ?? this.isActive,
      );

  /// Insert payload (no id — the DB assigns the identity PK).
  Map<String, dynamic> toInsert() => {
        'name': name,
        'name_ar': nameAr,
        'code': code,
        'is_active': isActive,
      };
}

/// A node in the location-independent department hierarchy. `departments` table.
class Department {
  final int id;
  final String name;
  final String? nameAr;
  final String? code;
  final int? parentId; // null = top-level
  final bool isActive;

  const Department({
    required this.id,
    required this.name,
    this.nameAr,
    this.code,
    this.parentId,
    this.isActive = true,
  });

  factory Department.fromJson(Map<String, dynamic> j) => Department(
        id: _toInt(j['id']),
        name: (j['name'] as String?)?.trim() ?? '',
        nameAr: _trimN(j['name_ar'] as String?),
        code: _trimN(j['code'] as String?),
        parentId: _toIntN(j['parent_id']),
        isActive: _toBool(j['is_active']),
      );

  Department copyWith({
    String? name,
    String? nameAr,
    String? code,
    int? parentId,
    bool? isActive,
    bool clearParent = false,
    bool clearCode = false,
  }) =>
      Department(
        id: id,
        name: name ?? this.name,
        nameAr: nameAr ?? this.nameAr,
        code: clearCode ? null : (code ?? this.code),
        parentId: clearParent ? null : (parentId ?? this.parentId),
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toInsert() => {
        'name': name,
        'name_ar': nameAr,
        'code': code,
        'parent_id': parentId,
        'is_active': isActive,
      };
}

/// A department's instance at a location (a "link"). `department_locations` table.
class DepartmentLocation {
  final int id;
  final int departmentId;
  final int locationId;
  final int? managerPositionId; // the position that manages this dept-at-location
  final bool isActive;

  const DepartmentLocation({
    required this.id,
    required this.departmentId,
    required this.locationId,
    this.managerPositionId,
    this.isActive = true,
  });

  factory DepartmentLocation.fromJson(Map<String, dynamic> j) => DepartmentLocation(
        id: _toInt(j['id']),
        departmentId: _toInt(j['department_id']),
        locationId: _toInt(j['location_id']),
        managerPositionId: _toIntN(j['manager_position_id']),
        isActive: _toBool(j['is_active']),
      );

  DepartmentLocation copyWith({int? managerPositionId, bool? isActive, bool clearManager = false}) =>
      DepartmentLocation(
        id: id,
        departmentId: departmentId,
        locationId: locationId,
        managerPositionId: clearManager ? null : (managerPositionId ?? this.managerPositionId),
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toInsert() => {
        'department_id': departmentId,
        'location_id': locationId,
        'is_active': isActive,
      };
}

/// A position within a link's reporting chart. `positions` table. Belongs to a
/// dept-location pair (deptLocId), not directly to a department. `reportsToId`
/// is a self-reference to another position within the SAME link (null = top).
class Position {
  final int id;
  final int deptLocId;
  final String title;
  final String? titleAr;
  final String? grade;
  final int? reportsToId;
  final bool isActive;

  const Position({
    required this.id,
    required this.deptLocId,
    required this.title,
    this.titleAr,
    this.grade,
    this.reportsToId,
    this.isActive = true,
  });

  factory Position.fromJson(Map<String, dynamic> j) => Position(
        id: _toInt(j['id']),
        deptLocId: _toInt(j['department_location_id']),
        title: (j['title'] as String?)?.trim() ?? '',
        titleAr: _trimN(j['title_ar'] as String?),
        grade: _trimN(j['grade'] as String?),
        reportsToId: _toIntN(j['reports_to_position_id']),
        isActive: _toBool(j['is_active']),
      );

  Position copyWith({
    String? title,
    String? titleAr,
    String? grade,
    int? reportsToId,
    bool? isActive,
    bool clearReportsTo = false,
    bool clearGrade = false,
  }) =>
      Position(
        id: id,
        deptLocId: deptLocId,
        title: title ?? this.title,
        titleAr: titleAr ?? this.titleAr,
        grade: clearGrade ? null : (grade ?? this.grade),
        reportsToId: clearReportsTo ? null : (reportsToId ?? this.reportsToId),
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toInsert() => {
        'department_location_id': deptLocId,
        'title': title,
        'title_ar': titleAr,
        'grade': grade,
        'reports_to_position_id': reportsToId,
        'is_active': isActive,
      };
}

/// One immutable snapshot of the whole org structure, as loaded on open.
class OrgSnapshot {
  final List<Location> locations;
  final List<Department> departments;
  final List<DepartmentLocation> links;
  final List<Position> positions;

  const OrgSnapshot({
    this.locations = const [],
    this.departments = const [],
    this.links = const [],
    this.positions = const [],
  });

  static const empty = OrgSnapshot();
}
