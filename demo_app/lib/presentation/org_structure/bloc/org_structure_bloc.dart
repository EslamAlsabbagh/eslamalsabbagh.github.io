import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/org_structure/org_structure_models.dart';
import 'package:hrms_demo/data/repos/org_structure/org_structure_repo.dart';
import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_event.dart';
import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_state.dart';
import 'package:hrms_demo/presentation/org_structure/org_selectors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Semantic warning tokens the UI translates to localized text. Repo failures
/// fall back to [saveFailed]. Keeping these as tokens (not English prose) lets
/// the inline warnings honour the app locale like the rest of the chrome.
class OrgWarn {
  static const deptHasChildren = 'dept_has_children';
  static const deptCycle = 'dept_cycle';
  static const linkHasPositions = 'link_has_positions';
  static const positionCycle = 'position_cycle';
  static const saveFailed = 'save_failed';
}

/// Owns the whole builder's state. Mutations follow one discipline: run the
/// client-side guard first (so an obviously-invalid action never hits the wire),
/// then call the repo, then apply the returned row to the in-memory lists. On a
/// repo throw (RLS denial, DB trigger, FK restrict) we surface a warning and
/// leave the lists untouched — nothing was optimistically changed.
class OrgStructureBloc extends Bloc<OrgStructureEvent, OrgStructureState> {
  final OrgStructureRepo repo;

  OrgStructureBloc(this.repo) : super(const OrgStructureState()) {
    on<OrgLoaded>(_onLoaded);
    on<OrgLangChanged>((e, emit) => emit(state.copyWith(lang: e.lang)));
    on<OrgDeptSelected>(
      (e, emit) => emit(state.copyWith(selectedDeptId: e.id, clearSelection: e.id == null, clearEditing: true)),
    );
    on<OrgDeptExpandToggled>(_onExpandToggled);
    on<OrgPositionsCollapseToggled>(_onCollapseToggled);
    on<OrgEditStarted>((e, emit) => emit(state.copyWith(editing: e.target, clearWarning: true)));
    on<OrgEditCancelled>((e, emit) => emit(state.copyWith(clearEditing: true)));
    on<OrgWarningCleared>((e, emit) => emit(state.copyWith(clearWarning: true)));

    on<OrgDepartmentAdded>(_onDepartmentAdded);
    on<OrgDepartmentRenamed>(_onDepartmentRenamed);
    on<OrgDepartmentActiveToggled>(_onDepartmentActiveToggled);
    on<OrgDepartmentReparented>(_onDepartmentReparented);
    on<OrgDepartmentDeleted>(_onDepartmentDeleted);

    on<OrgLocationAdded>(_onLocationAdded);
    on<OrgLocationEdited>(_onLocationEdited);
    on<OrgLocationActiveToggled>(_onLocationActiveToggled);
    on<OrgLocationDeleted>(_onLocationDeleted);

    on<OrgLocationConnected>(_onLocationConnected);
    on<OrgLocationDisconnected>(_onLocationDisconnected);
    on<OrgManagerToggled>(_onManagerToggled);

    on<OrgPositionAdded>(_onPositionAdded);
    on<OrgPositionEdited>(_onPositionEdited);
    on<OrgPositionReportsToChanged>(_onPositionReportsToChanged);
    on<OrgPositionDeleted>(_onPositionDeleted);
    on<OrgPositionDuplicated>(_onPositionDuplicated);
    on<OrgPositionsCopied>(_onPositionsCopied);
  }

  // ── Load ───────────────────────────────────────────────────────────────────
  Future<void> _onLoaded(OrgLoaded e, Emitter<OrgStructureState> emit) async {
    emit(state.copyWith(status: Status.loading, clearWarning: true));
    try {
      final snap = await repo.loadAll();
      emit(
        state.copyWith(
          status: Status.success,
          locations: snap.locations,
          departments: snap.departments,
          links: snap.links,
          positions: snap.positions,
        ),
      );
    } catch (_) {
      emit(state.copyWith(status: Status.failure, warning: OrgWarn.saveFailed));
    }
  }

  void _onExpandToggled(OrgDeptExpandToggled e, Emitter<OrgStructureState> emit) {
    final next = Set<int>.from(state.expanded);
    next.contains(e.id) ? next.remove(e.id) : next.add(e.id);
    emit(state.copyWith(expanded: next));
  }

  /// Charts start collapsed, so the set tracks the links the user has expanded.
  void _onCollapseToggled(OrgPositionsCollapseToggled e, Emitter<OrgStructureState> emit) {
    final next = Set<int>.from(state.expandedLinks);
    next.contains(e.linkId) ? next.remove(e.linkId) : next.add(e.linkId);
    emit(state.copyWith(expandedLinks: next));
  }

  // ── Departments ────────────────────────────────────────────────────────────
  Future<void> _onDepartmentAdded(OrgDepartmentAdded e, Emitter<OrgStructureState> emit) async {
    await _guarded(emit, () async {
      final created = await repo.createDepartment(name: 'New Department', parentId: e.parentId);
      final expanded = Set<int>.from(state.expanded);
      if (e.parentId != null) expanded.add(e.parentId!); // reveal the new child
      emit(
        state.copyWith(
          departments: [...state.departments, created],
          expanded: expanded,
          selectedDeptId: created.id,
          editing: OrgEditTarget(EditKind.department, created.id),
          clearWarning: true,
        ),
      );
    });
  }

  Future<void> _onDepartmentRenamed(OrgDepartmentRenamed e, Emitter<OrgStructureState> emit) async {
    if (e.name.trim().isEmpty) {
      emit(state.copyWith(clearEditing: true));
      return;
    }
    await _guarded(emit, () async {
      final updated = await repo.updateDepartment(e.id, name: e.name.trim(), nameAr: e.nameAr);
      emit(state.copyWith(departments: _replace(state.departments, updated), clearEditing: true, clearWarning: true));
    });
  }

  Future<void> _onDepartmentActiveToggled(OrgDepartmentActiveToggled e, Emitter<OrgStructureState> emit) async {
    final dept = _byId(state.departments, e.id);
    if (dept == null) return;
    await _guarded(emit, () async {
      final updated = await repo.updateDepartment(e.id, isActive: !dept.isActive);
      emit(state.copyWith(departments: _replace(state.departments, updated), clearWarning: true));
    });
  }

  Future<void> _onDepartmentReparented(OrgDepartmentReparented e, Emitter<OrgStructureState> emit) async {
    // Reject self-drop or a drop onto one of the dragged node's descendants —
    // the DB trigger would also reject it, but catching it here is instant and
    // avoids a needless round trip.
    if (e.newParentId == e.id ||
        (e.newParentId != null && OrgSelectors.descendantIds(state.departments, e.id).contains(e.newParentId))) {
      emit(state.copyWith(warning: OrgWarn.deptCycle));
      return;
    }
    await _guarded(emit, () async {
      final updated = await repo.reparentDepartment(e.id, e.newParentId);
      final expanded = Set<int>.from(state.expanded);
      if (e.newParentId != null) expanded.add(e.newParentId!); // auto-expand new parent
      emit(state.copyWith(departments: _replace(state.departments, updated), expanded: expanded, clearWarning: true));
    }, cycleWarning: OrgWarn.deptCycle);
  }

  Future<void> _onDepartmentDeleted(OrgDepartmentDeleted e, Emitter<OrgStructureState> emit) async {
    if (OrgSelectors.hasChildren(state.departments, e.id)) {
      emit(state.copyWith(warning: OrgWarn.deptHasChildren));
      return;
    }
    await _guarded(emit, () async {
      // FKs are `on delete restrict`, so cascade by hand: positions -> links -> dept.
      final deptLinks = OrgSelectors.linksForDept(state.links, e.id);
      final linkIds = deptLinks.map((l) => l.id).toSet();
      for (final l in deptLinks) {
        for (final p in OrgSelectors.positionsInLink(state.positions, l.id)) {
          await repo.deletePosition(p.id);
        }
        await repo.disconnect(l.id);
      }
      await repo.deleteDepartment(e.id);

      emit(
        state.copyWith(
          departments: state.departments.where((d) => d.id != e.id).toList(),
          links: state.links.where((l) => !linkIds.contains(l.id)).toList(),
          positions: state.positions.where((p) => !linkIds.contains(p.deptLocId)).toList(),
          clearSelection: state.selectedDeptId == e.id,
          clearWarning: true,
        ),
      );
    });
  }

  // ── Locations ──────────────────────────────────────────────────────────────
  Future<void> _onLocationAdded(OrgLocationAdded e, Emitter<OrgStructureState> emit) async {
    await _guarded(emit, () async {
      final created = await repo.createLocation(name: 'New Location', code: _uniqueLocationCode());
      emit(
        state.copyWith(
          locations: [...state.locations, created],
          editing: OrgEditTarget(EditKind.location, created.id),
          clearWarning: true,
        ),
      );
    });
  }

  Future<void> _onLocationEdited(OrgLocationEdited e, Emitter<OrgStructureState> emit) async {
    if (e.name.trim().isEmpty || e.code.trim().isEmpty) {
      emit(state.copyWith(clearEditing: true));
      return;
    }
    await _guarded(emit, () async {
      final updated = await repo.updateLocation(
        e.id,
        name: e.name.trim(),
        nameAr: e.nameAr,
        code: e.code.trim().toUpperCase(),
      );
      emit(state.copyWith(locations: _replaceLoc(state.locations, updated), clearEditing: true, clearWarning: true));
    });
  }

  Future<void> _onLocationActiveToggled(OrgLocationActiveToggled e, Emitter<OrgStructureState> emit) async {
    final loc = _byId(state.locations, e.id);
    if (loc == null) return;
    await _guarded(emit, () async {
      final updated = await repo.updateLocation(e.id, isActive: !loc.isActive);
      emit(state.copyWith(locations: _replaceLoc(state.locations, updated), clearWarning: true));
    });
  }

  Future<void> _onLocationDeleted(OrgLocationDeleted e, Emitter<OrgStructureState> emit) async {
    await _guarded(emit, () async {
      // Cascade: for every link at this location, delete its positions then the
      // link, then the location itself (FKs are restrict).
      final locLinks = state.links.where((l) => l.locationId == e.id).toList();
      final linkIds = locLinks.map((l) => l.id).toSet();
      for (final l in locLinks) {
        for (final p in OrgSelectors.positionsInLink(state.positions, l.id)) {
          await repo.deletePosition(p.id);
        }
        await repo.disconnect(l.id);
      }
      await repo.deleteLocation(e.id);

      emit(
        state.copyWith(
          locations: state.locations.where((loc) => loc.id != e.id).toList(),
          links: state.links.where((l) => !linkIds.contains(l.id)).toList(),
          positions: state.positions.where((p) => !linkIds.contains(p.deptLocId)).toList(),
          clearWarning: true,
        ),
      );
    });
  }

  // ── Links ────────────────────────────────────────────────────────────────────
  Future<void> _onLocationConnected(OrgLocationConnected e, Emitter<OrgStructureState> emit) async {
    if (OrgSelectors.linkFor(state.links, e.departmentId, e.locationId) != null) return; // already linked
    await _guarded(emit, () async {
      final created = await repo.connect(e.departmentId, e.locationId);
      emit(state.copyWith(links: [...state.links, created], clearWarning: true));
    });
  }

  Future<void> _onLocationDisconnected(OrgLocationDisconnected e, Emitter<OrgStructureState> emit) async {
    if (OrgSelectors.positionsInLink(state.positions, e.linkId).isNotEmpty) {
      emit(state.copyWith(warning: OrgWarn.linkHasPositions));
      return;
    }
    await _guarded(emit, () async {
      await repo.disconnect(e.linkId);
      emit(state.copyWith(links: state.links.where((l) => l.id != e.linkId).toList(), clearWarning: true));
    });
  }

  Future<void> _onManagerToggled(OrgManagerToggled e, Emitter<OrgStructureState> emit) async {
    final link = _byId(state.links, e.linkId);
    if (link == null) return;
    final next = link.managerPositionId == e.positionId ? null : e.positionId; // toggle off if same
    await _guarded(emit, () async {
      final updated = await repo.setManager(e.linkId, next);
      emit(state.copyWith(links: _replaceLink(state.links, updated), clearWarning: true));
    });
  }

  // ── Positions ────────────────────────────────────────────────────────────────
  Future<void> _onPositionAdded(OrgPositionAdded e, Emitter<OrgStructureState> emit) async {
    await _guarded(emit, () async {
      final created = await repo.createPosition(
        deptLocId: e.deptLocId,
        title: 'New Position',
        reportsToId: e.reportsToId,
      );
      emit(
        state.copyWith(
          positions: [...state.positions, created],
          editing: OrgEditTarget(EditKind.position, created.id),
          clearWarning: true,
        ),
      );
    });
  }

  /// Applies to every id in the event: a collapsed "×N" row edits all of its
  /// members in one go, keeping them identical (and therefore still grouped).
  Future<void> _onPositionEdited(OrgPositionEdited e, Emitter<OrgStructureState> emit) async {
    if (e.title.trim().isEmpty || e.ids.isEmpty) {
      emit(state.copyWith(clearEditing: true));
      return;
    }
    await _guarded(emit, () async {
      var positions = state.positions;
      for (final id in e.ids) {
        final updated = await repo.updatePosition(id, title: e.title.trim(), titleAr: e.titleAr, grade: e.grade);
        positions = _replacePos(positions, updated);
      }
      emit(state.copyWith(positions: positions, clearEditing: true, clearWarning: true));
    });
  }

  Future<void> _onPositionReportsToChanged(OrgPositionReportsToChanged e, Emitter<OrgStructureState> emit) async {
    final pos = _byId(state.positions, e.id);
    if (pos == null) return;
    // A position may only report to another position in the SAME link, and never
    // to one of its own (transitive) subordinates.
    if (e.reportsToId != null) {
      final target = _byId(state.positions, e.reportsToId!);
      if (target == null || target.deptLocId != pos.deptLocId) return;
      if (OrgSelectors.positionSubtreeIds(state.positions, pos.deptLocId, pos.id).contains(e.reportsToId)) {
        emit(state.copyWith(warning: OrgWarn.positionCycle));
        return;
      }
    }
    await _guarded(emit, () async {
      final updated = await repo.setReportsTo(e.id, e.reportsToId);
      emit(state.copyWith(positions: _replacePos(state.positions, updated), clearWarning: true));
    });
  }

  /// Deletes one position, or every member of a collapsed repeat group.
  Future<void> _onPositionDeleted(OrgPositionDeleted e, Emitter<OrgStructureState> emit) async {
    final doomed = e.ids.where((id) => _byId(state.positions, id) != null).toSet();
    if (doomed.isEmpty) return;
    await _guarded(emit, () async {
      // Re-parent EVERY direct report to null (top of chart) so the
      // delete-restrict self-FK doesn't block — including reports that are
      // themselves doomed, which frees us from having to delete children first.
      final directReports = state.positions.where((p) => doomed.contains(p.reportsToId)).toList();
      for (final child in directReports) {
        await repo.setReportsTo(child.id, null);
      }
      final managingLinks = state.links.where((l) => doomed.contains(l.managerPositionId)).toList();
      for (final l in managingLinks) {
        await repo.setManager(l.id, null);
      }
      for (final id in doomed) {
        await repo.deletePosition(id);
      }

      final positions =
          state.positions
              .where((p) => !doomed.contains(p.id))
              .map((p) => doomed.contains(p.reportsToId) ? p.copyWith(clearReportsTo: true) : p)
              .toList();
      final links =
          state.links.map((l) => doomed.contains(l.managerPositionId) ? l.copyWith(clearManager: true) : l).toList();
      emit(state.copyWith(positions: positions, links: links, clearWarning: true));
    });
  }

  /// Make an exact sibling copy of a single position: same parent
  /// ([reportsToId]), title, grade and active state. The manager star is not
  /// carried over (one manager per link), and sub-reports are not cloned.
  Future<void> _onPositionDuplicated(OrgPositionDuplicated e, Emitter<OrgStructureState> emit) async {
    final src = _byId(state.positions, e.id);
    if (src == null) return;
    await _guarded(emit, () async {
      final created = await repo.createPosition(
        deptLocId: src.deptLocId,
        title: src.title,
        titleAr: src.titleAr,
        grade: src.grade,
        reportsToId: src.reportsToId,
        isActive: src.isActive,
      );
      emit(state.copyWith(positions: [...state.positions, created], clearWarning: true));
    });
  }

  /// Clone every position from [sourceLinkId] into [targetLinkId] (same
  /// department, different location). Preserves the reporting tree and the
  /// designated manager by remapping source ids to the freshly-created ones.
  Future<void> _onPositionsCopied(OrgPositionsCopied e, Emitter<OrgStructureState> emit) async {
    final targetLink = _byId(state.links, e.targetLinkId);
    final sourceLink = _byId(state.links, e.sourceLinkId);
    if (targetLink == null || sourceLink == null) return;

    await _guarded(emit, () async {
      // flattenPositions yields parents before children, so a child's parent
      // is always in [idMap] by the time we create the child — one pass.
      final rows = OrgSelectors.flattenPositions(state.positions, e.sourceLinkId);
      final idMap = <int, int>{};
      final newPositions = <Position>[];
      for (final row in rows) {
        final src = row.position;
        final created = await repo.createPosition(
          deptLocId: e.targetLinkId,
          title: src.title,
          titleAr: src.titleAr,
          grade: src.grade,
          reportsToId: src.reportsToId == null ? null : idMap[src.reportsToId],
          isActive: src.isActive,
        );
        idMap[src.id] = created.id;
        newPositions.add(created);
      }

      // Carry over the designated manager (remapped to its new position id).
      var links = state.links;
      final srcManagerId = sourceLink.managerPositionId;
      if (srcManagerId != null && idMap[srcManagerId] != null) {
        final updated = await repo.setManager(e.targetLinkId, idMap[srcManagerId]);
        links = _replaceLink(links, updated);
      }

      emit(state.copyWith(positions: [...state.positions, ...newPositions], links: links, clearWarning: true));
    });
  }

  // ── Infra ──────────────────────────────────────────────────────────────────

  /// Run a mutation, translating any thrown repo error into an inline warning.
  /// [cycleWarning] lets a caller surface a friendlier token for the specific
  /// error the DB trigger raises (otherwise it's the generic save-failed token).
  Future<void> _guarded(Emitter<OrgStructureState> emit, Future<void> Function() action, {String? cycleWarning}) async {
    try {
      await action();
    } catch (err) {
      final token =
          (cycleWarning != null && err.toString().toLowerCase().contains('cycle')) ? cycleWarning : OrgWarn.saveFailed;
      emit(state.copyWith(warning: token));
    }
  }

  /// A location code that doesn't collide with an existing one (the column is
  /// NOT NULL UNIQUE). New locations start with this placeholder, then the user
  /// edits it inline.
  String _uniqueLocationCode() {
    final used = state.locations.map((l) => l.code.toUpperCase()).toSet();
    var n = state.locations.length + 1;
    while (used.contains('LOC-$n')) {
      n++;
    }
    return 'LOC-$n';
  }

  static T? _byId<T>(List<T> items, int id) {
    for (final item in items) {
      if ((item as dynamic).id == id) return item;
    }
    return null;
  }

  List<Department> _replace(List<Department> list, Department updated) =>
      list.map((d) => d.id == updated.id ? updated : d).toList();
  List<Location> _replaceLoc(List<Location> list, Location updated) =>
      list.map((l) => l.id == updated.id ? updated : l).toList();
  List<DepartmentLocation> _replaceLink(List<DepartmentLocation> list, DepartmentLocation updated) =>
      list.map((l) => l.id == updated.id ? updated : l).toList();
  List<Position> _replacePos(List<Position> list, Position updated) =>
      list.map((p) => p.id == updated.id ? updated : p).toList();
}
