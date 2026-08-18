import 'package:hrms_demo/data/models/org_structure/org_structure_models.dart';

/// A department paired with its depth in a flattened tree walk.
class DeptRow {
  final Department dept;
  final int depth;
  final bool hasChildren;
  const DeptRow(this.dept, this.depth, this.hasChildren);
}

/// A position paired with its depth within a single link's reporting chart.
class PosRow {
  final Position position;
  final int depth;
  const PosRow(this.position, this.depth);
}

/// The attributes that must all match for two sibling positions to be treated
/// as the same "repeat". A record, so equality is structural and free.
typedef RepeatKey = ({String title, String? titleAr, String? grade, bool isActive});

/// One rendered row of a link's chart: either a single position, or a run of
/// identical sibling positions collapsed into one "Title ×N" row. In expanded
/// mode every group holds exactly one member, so the row widget needs no branch.
class PosGroup {
  /// Growable — [OrgSelectors.flattenPositionGroups] appends repeats as it walks.
  /// The first entry is the "lead": the member acted on by edit/duplicate.
  final List<Position> members;
  final int depth;
  PosGroup(this.members, this.depth);

  Position get lead => members.first;
  int get count => members.length;
  List<int> get ids => members.map((p) => p.id).toList();
}

/// Pure, side-effect-free derivations over the entity lists. Shared by the Bloc
/// (for guard checks) and the widgets (for rendering trees, breadcrumbs, chips).
/// Kept as static methods so there is exactly one implementation of each walk.
class OrgSelectors {
  const OrgSelectors._();

  // ── Departments ──────────────────────────────────────────────────────────────
  static List<Department> childrenOf(List<Department> depts, int? parentId) =>
      depts.where((d) => d.parentId == parentId).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  static bool hasChildren(List<Department> depts, int id) => depts.any((d) => d.parentId == id);

  /// All descendant ids of [id] (excluding [id] itself).
  static Set<int> descendantIds(List<Department> depts, int id) {
    final out = <int>{};
    final stack = <int>[id];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      for (final d in depts) {
        if (d.parentId == current && !out.contains(d.id)) {
          out.add(d.id);
          stack.add(d.id);
        }
      }
    }
    return out;
  }

  /// Flatten the hierarchy depth-first, emitting only rows whose ancestors are
  /// all in [expanded]. Root departments (parentId == null) are always shown.
  static List<DeptRow> flattenTree(List<Department> depts, Set<int> expanded) {
    final rows = <DeptRow>[];
    void walk(int? parentId, int depth) {
      for (final d in childrenOf(depts, parentId)) {
        final kids = hasChildren(depts, d.id);
        rows.add(DeptRow(d, depth, kids));
        if (kids && expanded.contains(d.id)) walk(d.id, depth + 1);
      }
    }

    walk(null, 0);
    return rows;
  }

  /// Root → [id] chain (inclusive), for the detail-pane breadcrumb.
  static List<Department> ancestryChain(List<Department> depts, int id) {
    final byId = {for (final d in depts) d.id: d};
    final chain = <Department>[];
    Department? current = byId[id];
    final guard = <int>{};
    while (current != null && guard.add(current.id)) {
      chain.insert(0, current);
      final pid = current.parentId;
      current = pid == null ? null : byId[pid];
    }
    return chain;
  }

  // ── Links ────────────────────────────────────────────────────────────────────
  static DepartmentLocation? linkFor(List<DepartmentLocation> links, int deptId, int locId) {
    for (final l in links) {
      if (l.departmentId == deptId && l.locationId == locId) return l;
    }
    return null;
  }

  static List<DepartmentLocation> linksForDept(List<DepartmentLocation> links, int deptId) =>
      links.where((l) => l.departmentId == deptId).toList();

  /// How many locations a department is linked to (for the tree row's pin count).
  static int linkCount(List<DepartmentLocation> links, int deptId) =>
      links.where((l) => l.departmentId == deptId).length;

  // ── Positions ────────────────────────────────────────────────────────────────
  static List<Position> positionsInLink(List<Position> positions, int deptLocId) =>
      positions.where((p) => p.deptLocId == deptLocId).toList();

  static List<Position> childPositions(List<Position> positions, int deptLocId, int? reportsToId) =>
      positions.where((p) => p.deptLocId == deptLocId && p.reportsToId == reportsToId).toList()
        ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

  /// All position ids that report (transitively) to [id] within the same link,
  /// including [id] itself — used to reject a reporting line that forms a cycle.
  static Set<int> positionSubtreeIds(List<Position> positions, int deptLocId, int id) {
    final out = <int>{id};
    final stack = <int>[id];
    while (stack.isNotEmpty) {
      final current = stack.removeLast();
      for (final p in positions) {
        if (p.deptLocId == deptLocId && p.reportsToId == current && out.add(p.id)) {
          stack.add(p.id);
        }
      }
    }
    return out;
  }

  /// Whether [id] has any direct reports within the same link.
  static bool hasReports(List<Position> positions, int deptLocId, int id) =>
      positions.any((p) => p.deptLocId == deptLocId && p.reportsToId == id);

  /// Flatten one link's reporting chart depth-first (roots = reportsToId null).
  static List<PosRow> flattenPositions(List<Position> positions, int deptLocId) {
    final rows = <PosRow>[];
    void walk(int? reportsToId, int depth) {
      for (final p in childPositions(positions, deptLocId, reportsToId)) {
        rows.add(PosRow(p, depth));
        walk(p.id, depth + 1);
      }
    }

    walk(null, 0);
    return rows;
  }

  /// Same depth-first walk as [flattenPositions], but with runs of identical
  /// sibling positions collapsed into one row when [collapseRepeats] is on.
  ///
  /// A position only joins a group when it is a LEAF (no direct reports) and is
  /// not the link's manager — so a count never hides a subtree or the manager
  /// star. Everything else renders as a one-member group, keeping the caller on
  /// a single code path in both modes.
  static List<PosGroup> flattenPositionGroups(
    List<Position> positions,
    int deptLocId, {
    required bool collapseRepeats,
    int? managerPositionId,
  }) {
    final rows = <PosGroup>[];

    void walk(int? reportsToId, int depth) {
      // Keyed per sibling level, so identical titles under DIFFERENT parents
      // never merge. Siblings are sorted by title only, so equal-key positions
      // are not necessarily adjacent (a same-title/different-grade row can sit
      // between them) — hence a map rather than an adjacent-run scan.
      final openGroups = <RepeatKey, PosGroup>{};

      for (final p in childPositions(positions, deptLocId, reportsToId)) {
        final groupable = collapseRepeats && p.id != managerPositionId && !hasReports(positions, deptLocId, p.id);
        if (groupable) {
          final key = _repeatKey(p);
          final existing = openGroups[key];
          if (existing != null) {
            existing.members.add(p);
            continue;
          }
          final group = PosGroup([p], depth);
          openGroups[key] = group;
          rows.add(group);
          continue; // a leaf has no subtree to walk
        }
        rows.add(PosGroup([p], depth));
        walk(p.id, depth + 1);
      }
    }

    walk(null, 0);
    return rows;
  }

  /// Identity of a "repeat": two positions collapse together only when every
  /// displayed attribute matches, so a collapsed row can never misrepresent one
  /// of its members. A record (structural equality) rather than a joined string,
  /// so no title containing the separator can forge a false match.
  static RepeatKey _repeatKey(Position p) => (title: p.title, titleAr: p.titleAr, grade: p.grade, isActive: p.isActive);

  /// Whether [deptLocId]'s chart contains at least one collapsible repeat —
  /// drives whether the card even shows its collapse toggle.
  static bool hasRepeats(List<Position> positions, int deptLocId, {int? managerPositionId}) => flattenPositionGroups(
    positions,
    deptLocId,
    collapseRepeats: true,
    managerPositionId: managerPositionId,
  ).any((g) => g.count > 1);
}
