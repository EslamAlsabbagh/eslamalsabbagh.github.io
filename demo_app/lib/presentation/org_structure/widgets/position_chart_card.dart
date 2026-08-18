import 'package:hrms_demo/core/theme/app_colors.dart';
import 'package:hrms_demo/data/models/org_structure/org_structure_models.dart';
import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_bloc.dart';
import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_event.dart';
import 'package:hrms_demo/presentation/org_structure/bloc/org_structure_state.dart';
import 'package:hrms_demo/presentation/org_structure/org_labels.dart';
import 'package:hrms_demo/presentation/org_structure/org_selectors.dart';
import 'package:hrms_demo/presentation/org_structure/widgets/org_common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// One card = one link (a department AT a location). Renders that link's
/// position reporting chart as a flattened tree; reporting lines are set by
/// drag-and-drop scoped to THIS link only.
class PositionChartCard extends StatelessWidget {
  final OrgStructureState state;
  final DepartmentLocation link;
  final Location location;
  const PositionChartCard({super.key, required this.state, required this.link, required this.location});

  @override
  Widget build(BuildContext context) {
    final s = OrgStrings.of(context);
    final bloc = context.read<OrgStructureBloc>();
    // Repeats collapse by default; the state tracks the links opened back up.
    final collapsed = !state.expandedLinks.contains(link.id);
    final groups = OrgSelectors.flattenPositionGroups(
      state.positions,
      link.id,
      collapseRepeats: collapsed,
      managerPositionId: link.managerPositionId,
    );
    // Only offer the toggle when there is actually something to collapse —
    // the same discipline the "Copy from…" control follows.
    final hasRepeats = OrgSelectors.hasRepeats(state.positions, link.id, managerPositionId: link.managerPositionId);

    // Other locations on this SAME department that already have positions to
    // clone from. Empty → the "Copy from…" control is hidden.
    final copySources =
        OrgSelectors.linksForDept(
          state.links,
          link.departmentId,
        ).where((l) => l.id != link.id && OrgSelectors.positionsInLink(state.positions, l.id).isNotEmpty).toList();

    Position? manager;
    if (link.managerPositionId != null) {
      for (final p in state.positions) {
        if (p.id == link.managerPositionId) {
          manager = p;
          break;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: OrgGap.m),
      padding: const EdgeInsets.all(OrgGap.l),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gridline),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: location + manager label + add position
          Row(
            children: [
              const Icon(Icons.push_pin, size: 16, color: AppColors.cat2Aqua),
              const SizedBox(width: OrgGap.s),
              Text(
                state.lang.label(location.name, location.nameAr),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.inkPrimary),
              ),
              const SizedBox(width: OrgGap.m),
              _managerLabel(context, s, manager),
              const Spacer(),
              if (hasRepeats)
                IconButton(
                  onPressed: () => bloc.add(OrgPositionsCollapseToggled(link.id)),
                  icon: Icon(collapsed ? Icons.unfold_more : Icons.unfold_less, size: 16),
                  color: collapsed ? AppColors.primary : AppColors.inkSecondary,
                  tooltip: collapsed ? s.expandRepeats : s.collapseRepeats,
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                ),
              if (hasRepeats) const SizedBox(width: OrgGap.s),
              if (copySources.isNotEmpty)
                PopupMenuButton<int>(
                  tooltip: s.copyFromLocationTip,
                  position: PopupMenuPosition.under,
                  onSelected: (sourceLinkId) => bloc.add(OrgPositionsCopied(link.id, sourceLinkId)),
                  itemBuilder:
                      (_) => [
                        for (final src in copySources)
                          PopupMenuItem<int>(value: src.id, child: Text(_locLabel(src.locationId))),
                      ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: OrgGap.s, vertical: OrgGap.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_all, size: 16, color: AppColors.primary),
                        const SizedBox(width: OrgGap.xs),
                        Text(
                          s.copyFromLocation,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: () => bloc.add(OrgPositionAdded(link.id)),
                icon: const Icon(Icons.add, size: 16),
                label: Text(s.addPosition),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: OrgGap.s),
          _TopDropZone(link: link, hint: s.dropHereRemoveManager),
          const SizedBox(height: OrgGap.s),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: OrgGap.m),
              child: Text(s.noPositionsYet, style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
            )
          else
            for (final group in groups) _PositionRow(state: state, link: link, group: group),
        ],
      ),
    );
  }

  /// Display name of a location (respecting the builder's language mode),
  /// used to label each entry in the "Copy from…" menu.
  String _locLabel(int locationId) {
    for (final l in state.locations) {
      if (l.id == locationId) return state.lang.label(l.name, l.nameAr);
    }
    return '';
  }

  Widget _managerLabel(BuildContext context, OrgStrings s, Position? manager) {
    if (manager == null) {
      return Text(
        s.noManager,
        style: const TextStyle(fontSize: 12, color: AppColors.inkMuted, fontStyle: FontStyle.italic),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, size: 13, color: AppColors.cat3Yellow),
        const SizedBox(width: 3),
        Text(
          '${s.manager}: ${state.lang.label(manager.title, manager.titleAr)}',
          style: const TextStyle(fontSize: 12, color: AppColors.inkSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Dashed zone above the chart: dropping a position here clears its reportsTo
/// (makes it a top-level node in this link's chart). Scoped to this link.
class _TopDropZone extends StatelessWidget {
  final DepartmentLocation link;
  final String hint;
  const _TopDropZone({required this.link, required this.hint});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrgStructureBloc>();
    return DragTarget<_PosDrag>(
      onWillAcceptWithDetails: (d) => d.data.deptLocId == link.id,
      onAcceptWithDetails: (d) {
        for (final id in d.data.ids) {
          bloc.add(OrgPositionReportsToChanged(id, null));
        }
      },
      builder: (context, candidate, _) {
        final active = candidate.isNotEmpty;
        return Container(
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: active ? AppColors.primary : AppColors.baseline, width: 1),
          ),
          child: Text(hint, style: TextStyle(fontSize: 10.5, color: active ? AppColors.primary : AppColors.inkMuted)),
        );
      },
    );
  }
}

/// Drag payload for positions: carries the link id so drops can be scoped, and
/// every id in the dragged row — a collapsed "×N" row moves as one unit.
class _PosDrag {
  final List<int> ids;
  final int deptLocId;
  const _PosDrag(this.ids, this.deptLocId);
}

class _PositionRow extends StatefulWidget {
  final OrgStructureState state;
  final DepartmentLocation link;
  final PosGroup group;
  const _PositionRow({required this.state, required this.link, required this.group});

  @override
  State<_PositionRow> createState() => _PositionRowState();
}

class _PositionRowState extends State<_PositionRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = OrgStrings.of(context);
    final bloc = context.read<OrgStructureBloc>();
    // The group's "lead" stands in for the row: it is the position that edit and
    // duplicate act on, and the only one shown when the group is collapsed.
    final pos = widget.group.lead;
    final count = widget.group.count;
    final depth = widget.group.depth;
    final isManager = widget.link.managerPositionId == pos.id;
    final editing = widget.state.editing?.kind == EditKind.position && widget.state.editing?.id == pos.id;

    final content =
        editing
            ? Padding(
              padding: EdgeInsets.only(left: 24 + depth * 20, top: OrgGap.xs, bottom: OrgGap.xs),
              child: InlineEditRow(
                fields: [
                  OrgEditField(s.englishTitle, pos.title),
                  OrgEditField(s.arabicTitle, pos.titleAr ?? '', rtl: true),
                  OrgEditField(s.grade, pos.grade ?? ''),
                ],
                // Edits every member, so a collapsed group stays identical (and
                // therefore stays a group) after a retitle.
                onSave: (v) => bloc.add(OrgPositionEdited(widget.group.ids, v[0], v[1], v[2])),
                onCancel: () => bloc.add(const OrgEditCancelled()),
              ),
            )
            : _display(context, s, bloc, pos, depth, isManager, count);

    return DragTarget<_PosDrag>(
      // A collapsed run of N identical positions offers no single well-defined
      // parent, so it never accepts a drop — only a lone position does.
      onWillAcceptWithDetails: (d) => count == 1 && d.data.deptLocId == widget.link.id && !d.data.ids.contains(pos.id),
      onAcceptWithDetails: (d) {
        for (final id in d.data.ids) {
          bloc.add(OrgPositionReportsToChanged(id, pos.id));
        }
      },
      builder: (context, candidate, _) {
        final isDropTarget = candidate.isNotEmpty;
        return Draggable<_PosDrag>(
          data: _PosDrag(widget.group.ids, widget.link.id),
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: _feedback(context, pos),
          childWhenDragging: Opacity(opacity: 0.35, child: content),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: Container(
              decoration: BoxDecoration(
                color: isDropTarget ? AppColors.primary.withValues(alpha: 0.10) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: content,
            ),
          ),
        );
      },
    );
  }

  Widget _display(
    BuildContext context,
    OrgStrings s,
    OrgStructureBloc bloc,
    Position pos,
    int depth,
    bool isManager,
    int count,
  ) {
    final grouped = count > 1;
    return Padding(
      padding: EdgeInsets.only(left: depth * 20.0),
      child: SizedBox(
        height: 34,
        child: Row(
          children: [
            Icon(Icons.drag_indicator, size: 14, color: AppColors.inkMuted.withValues(alpha: 0.6)),
            // Branch glyph for non-root rows (mirrors under RTL automatically via the icon).
            SizedBox(
              width: 16,
              child:
                  depth > 0
                      ? const Icon(Icons.subdirectory_arrow_right, size: 13, color: AppColors.inkMuted)
                      : const SizedBox.shrink(),
            ),
            // Members of a collapsed group are never the manager, and "which of
            // the N is it" has no answer — so the star is hidden but keeps its
            // space, holding every row's title on the same line.
            Visibility(
              visible: !grouped,
              // Space and layout are kept; taps and semantics are not.
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: IconButton(
                onPressed: () => bloc.add(OrgManagerToggled(widget.link.id, pos.id)),
                icon: Icon(
                  isManager ? Icons.star : Icons.star_border,
                  size: 16,
                  color: isManager ? AppColors.cat3Yellow : AppColors.inkMuted,
                ),
                tooltip: s.manager,
                padding: const EdgeInsets.all(2),
                constraints: const BoxConstraints(),
              ),
            ),
            Flexible(
              child: GestureDetector(
                onDoubleTap: () => bloc.add(OrgEditStarted(OrgEditTarget(EditKind.position, pos.id))),
                child: Text(
                  widget.state.lang.label(pos.title, pos.titleAr),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isManager ? FontWeight.w700 : FontWeight.w500,
                    color: pos.isActive ? AppColors.inkPrimary : AppColors.inkMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: OrgGap.s),
            if (grouped) ...[
              OrgTag('×$count', color: AppColors.cat8Orange, background: AppColors.cat8Orange.withValues(alpha: 0.15)),
              const SizedBox(width: OrgGap.xs),
            ],
            if (isManager)
              OrgTag(s.manager, color: AppColors.cat3Yellow, background: AppColors.cat3Yellow.withValues(alpha: 0.15)),
            if (pos.grade != null) ...[const SizedBox(width: OrgGap.xs), OrgTag(pos.grade!)],
            if (_hover) ...[
              const SizedBox(width: OrgGap.xs),
              // On a collapsed row: −/+ step the count by one occurrence, and
              // the bin clears the whole run.
              if (grouped)
                _miniAction(
                  Icons.remove_circle_outline,
                  s.removeOne,
                  () => bloc.add(OrgPositionDeleted([widget.group.members.last.id])),
                ),
              _miniAction(
                grouped ? Icons.add_circle_outline : Icons.control_point_duplicate,
                grouped ? s.addOne : s.duplicate,
                () => bloc.add(OrgPositionDuplicated(pos.id)),
              ),
              _miniAction(
                Icons.delete_outline,
                grouped ? s.deleteAll(count) : s.delete,
                () => bloc.add(OrgPositionDeleted(widget.group.ids)),
                color: AppColors.statusDeclined,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Compact hover action, matching the department tree's row actions.
  Widget _miniAction(IconData icon, String tip, VoidCallback onTap, {Color? color}) => IconButton(
    onPressed: onTap,
    icon: Icon(icon, size: 14),
    color: color ?? AppColors.inkSecondary,
    tooltip: tip,
    padding: const EdgeInsets.all(2),
    constraints: const BoxConstraints(),
    visualDensity: VisualDensity.compact,
  );

  Widget _feedback(BuildContext context, Position pos) => Material(
    color: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: OrgGap.m, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Text(
        widget.group.count > 1
            ? '${widget.state.lang.label(pos.title, pos.titleAr)} ×${widget.group.count}'
            : widget.state.lang.label(pos.title, pos.titleAr),
        style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
