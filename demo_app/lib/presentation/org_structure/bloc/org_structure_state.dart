import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/org_structure/org_structure_models.dart';
import 'package:hrms_demo/presentation/org_structure/org_labels.dart';
import 'package:equatable/equatable.dart';

/// Which entity is currently in inline-edit mode (only one at a time).
enum EditKind { department, location, position }

class OrgEditTarget extends Equatable {
  final EditKind kind;
  final int id;
  const OrgEditTarget(this.kind, this.id);

  @override
  List<Object?> get props => [kind, id];
}

/// Single source of truth for the Org Structure Builder: the four entity lists
/// plus UI state (display language, selection, expansion, current edit target,
/// and a transient inline warning). All mutations flow through OrgStructureBloc
/// and produce a new immutable copy.
class OrgStructureState extends Equatable {
  final Status status;
  final List<Location> locations;
  final List<Department> departments;
  final List<DepartmentLocation> links;
  final List<Position> positions;

  final OrgLang lang;
  final int? selectedDeptId;
  final Set<int> expanded;
  final OrgEditTarget? editing;

  /// Link ids whose position chart is expanded to one row per position.
  ///
  /// Charts COLLAPSE repeated positions into "Title ×N" rows by default, so
  /// this holds the exceptions — hence an empty set meaning "all collapsed".
  /// Purely a display preference; toggling never touches the positions.
  final Set<int> expandedLinks;

  /// Transient inline warning (guard rejections, repo failures). Cleared on the
  /// next successful action or explicitly.
  final String? warning;

  const OrgStructureState({
    this.status = Status.initial,
    this.locations = const [],
    this.departments = const [],
    this.links = const [],
    this.positions = const [],
    this.lang = OrgLang.en,
    this.selectedDeptId,
    this.expanded = const {},
    this.editing,
    this.expandedLinks = const {},
    this.warning,
  });

  OrgStructureState copyWith({
    Status? status,
    List<Location>? locations,
    List<Department>? departments,
    List<DepartmentLocation>? links,
    List<Position>? positions,
    OrgLang? lang,
    int? selectedDeptId,
    Set<int>? expanded,
    OrgEditTarget? editing,
    Set<int>? expandedLinks,
    String? warning,
    bool clearSelection = false,
    bool clearEditing = false,
    bool clearWarning = false,
  }) {
    return OrgStructureState(
      status: status ?? this.status,
      locations: locations ?? this.locations,
      departments: departments ?? this.departments,
      links: links ?? this.links,
      positions: positions ?? this.positions,
      lang: lang ?? this.lang,
      selectedDeptId: clearSelection ? null : (selectedDeptId ?? this.selectedDeptId),
      expanded: expanded ?? this.expanded,
      editing: clearEditing ? null : (editing ?? this.editing),
      expandedLinks: expandedLinks ?? this.expandedLinks,
      warning: clearWarning ? null : (warning ?? this.warning),
    );
  }

  @override
  List<Object?> get props => [
    status,
    locations,
    departments,
    links,
    positions,
    lang,
    selectedDeptId,
    expanded,
    editing,
    expandedLinks,
    warning,
  ];
}
