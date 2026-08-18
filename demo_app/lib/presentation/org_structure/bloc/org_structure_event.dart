import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_state.dart';
import 'package:hrms_demo/presentation/org_structure/org_labels.dart';
import 'package:equatable/equatable.dart';

abstract class OrgStructureEvent extends Equatable {
  const OrgStructureEvent();
  @override
  List<Object?> get props => [];
}

/// Initial (and manual-refresh) load of the whole structure.
class OrgLoaded extends OrgStructureEvent {
  const OrgLoaded();
}

// ── View state ────────────────────────────────────────────────────────────────
class OrgLangChanged extends OrgStructureEvent {
  final OrgLang lang;
  const OrgLangChanged(this.lang);
  @override
  List<Object?> get props => [lang];
}

class OrgDeptSelected extends OrgStructureEvent {
  final int? id; // null clears selection
  const OrgDeptSelected(this.id);
  @override
  List<Object?> get props => [id];
}

class OrgDeptExpandToggled extends OrgStructureEvent {
  final int id;
  const OrgDeptExpandToggled(this.id);
  @override
  List<Object?> get props => [id];
}

/// Flip whether one card's position chart collapses repeated positions into
/// "Title ×N" rows. Per link, so one location can be collapsed while another
/// stays expanded.
class OrgPositionsCollapseToggled extends OrgStructureEvent {
  final int linkId;
  const OrgPositionsCollapseToggled(this.linkId);
  @override
  List<Object?> get props => [linkId];
}

class OrgEditStarted extends OrgStructureEvent {
  final OrgEditTarget target;
  const OrgEditStarted(this.target);
  @override
  List<Object?> get props => [target];
}

class OrgEditCancelled extends OrgStructureEvent {
  const OrgEditCancelled();
}

class OrgWarningCleared extends OrgStructureEvent {
  const OrgWarningCleared();
}

// ── Departments ──────────────────────────────────────────────────────────────
class OrgDepartmentAdded extends OrgStructureEvent {
  final int? parentId; // null = top-level
  const OrgDepartmentAdded(this.parentId);
  @override
  List<Object?> get props => [parentId];
}

class OrgDepartmentRenamed extends OrgStructureEvent {
  final int id;
  final String name;
  final String? nameAr;
  const OrgDepartmentRenamed(this.id, this.name, this.nameAr);
  @override
  List<Object?> get props => [id, name, nameAr];
}

class OrgDepartmentActiveToggled extends OrgStructureEvent {
  final int id;
  const OrgDepartmentActiveToggled(this.id);
  @override
  List<Object?> get props => [id];
}

class OrgDepartmentReparented extends OrgStructureEvent {
  final int id;
  final int? newParentId; // null = to root
  const OrgDepartmentReparented(this.id, this.newParentId);
  @override
  List<Object?> get props => [id, newParentId];
}

class OrgDepartmentDeleted extends OrgStructureEvent {
  final int id;
  const OrgDepartmentDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

// ── Locations ────────────────────────────────────────────────────────────────
class OrgLocationAdded extends OrgStructureEvent {
  const OrgLocationAdded();
}

class OrgLocationEdited extends OrgStructureEvent {
  final int id;
  final String name;
  final String? nameAr;
  final String code;
  const OrgLocationEdited(this.id, this.name, this.nameAr, this.code);
  @override
  List<Object?> get props => [id, name, nameAr, code];
}

class OrgLocationActiveToggled extends OrgStructureEvent {
  final int id;
  const OrgLocationActiveToggled(this.id);
  @override
  List<Object?> get props => [id];
}

class OrgLocationDeleted extends OrgStructureEvent {
  final int id;
  const OrgLocationDeleted(this.id);
  @override
  List<Object?> get props => [id];
}

// ── Department ↔ Location links ──────────────────────────────────────────────
class OrgLocationConnected extends OrgStructureEvent {
  final int departmentId;
  final int locationId;
  const OrgLocationConnected(this.departmentId, this.locationId);
  @override
  List<Object?> get props => [departmentId, locationId];
}

class OrgLocationDisconnected extends OrgStructureEvent {
  final int linkId;
  const OrgLocationDisconnected(this.linkId);
  @override
  List<Object?> get props => [linkId];
}

class OrgManagerToggled extends OrgStructureEvent {
  final int linkId;
  final int positionId;
  const OrgManagerToggled(this.linkId, this.positionId);
  @override
  List<Object?> get props => [linkId, positionId];
}

// ── Positions ────────────────────────────────────────────────────────────────
class OrgPositionAdded extends OrgStructureEvent {
  final int deptLocId;
  final int? reportsToId;
  const OrgPositionAdded(this.deptLocId, {this.reportsToId});
  @override
  List<Object?> get props => [deptLocId, reportsToId];
}

/// Retitle/regrade one position, or every member of a collapsed repeat group at
/// once — the members are identical by definition, so an edit applies to all.
class OrgPositionEdited extends OrgStructureEvent {
  final List<int> ids;
  final String title;
  final String? titleAr;
  final String? grade;
  const OrgPositionEdited(this.ids, this.title, this.titleAr, this.grade);
  @override
  List<Object?> get props => [ids, title, titleAr, grade];
}

class OrgPositionReportsToChanged extends OrgStructureEvent {
  final int id;
  final int? reportsToId; // null = top of chart
  const OrgPositionReportsToChanged(this.id, this.reportsToId);
  @override
  List<Object?> get props => [id, reportsToId];
}

/// Delete one position, or a whole collapsed repeat group. Direct reports of a
/// deleted position are lifted to the top of the chart first.
class OrgPositionDeleted extends OrgStructureEvent {
  final List<int> ids;
  const OrgPositionDeleted(this.ids);
  @override
  List<Object?> get props => [ids];
}

/// Make an exact sibling copy of a single position (same parent, title, grade
/// and active state). Does not clone sub-reports or the manager designation.
class OrgPositionDuplicated extends OrgStructureEvent {
  final int id;
  const OrgPositionDuplicated(this.id);
  @override
  List<Object?> get props => [id];
}

/// Clone every position (reporting tree + designated manager) from one link
/// into another on the same department. Copied positions append to the target.
class OrgPositionsCopied extends OrgStructureEvent {
  final int targetLinkId; // where positions are copied INTO (current card's link)
  final int sourceLinkId; // where positions are copied FROM
  const OrgPositionsCopied(this.targetLinkId, this.sourceLinkId);
  @override
  List<Object?> get props => [targetLinkId, sourceLinkId];
}
