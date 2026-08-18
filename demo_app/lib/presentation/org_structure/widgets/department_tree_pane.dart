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

/// Left pane: the department hierarchy. Rows are a flattened walk of the tree
/// (respecting expand/collapse); reparenting is drag-and-drop, with a root
/// drop-zone at the top for "make top-level".
class DepartmentTreePane extends StatelessWidget {
  final OrgStructureState state;
  const DepartmentTreePane({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final s = OrgStrings.of(context);
    final bloc = context.read<OrgStructureBloc>();
    final rows = OrgSelectors.flattenTree(state.departments, state.expanded);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Text(
              s.departments,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.inkPrimary),
            ),
            const SizedBox(width: OrgGap.s),
            Icon(Icons.drag_indicator, size: 13, color: AppColors.inkMuted.withValues(alpha: 0.7)),
            Text(s.dragToReorganize, style: const TextStyle(fontSize: 11, color: AppColors.inkMuted)),
            const Spacer(),
            IconButton(
              onPressed: () => bloc.add(const OrgDepartmentAdded(null)),
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              style: IconButton.styleFrom(backgroundColor: AppColors.primary, visualDensity: VisualDensity.compact),
              tooltip: s.addTopLevel,
            ),
          ],
        ),
        const SizedBox(height: OrgGap.m),
        _RootDropZone(hint: s.dropHereTopLevel),
        const SizedBox(height: OrgGap.xs),
        Expanded(
          child: ListView.builder(itemCount: rows.length, itemBuilder: (_, i) => _DeptRow(state: state, row: rows[i])),
        ),
      ],
    );
  }
}

/// Dashed bar at the top of the tree: dropping a dragged department here makes
/// it top-level (parentId = null).
class _RootDropZone extends StatelessWidget {
  final String hint;
  const _RootDropZone({required this.hint});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<OrgStructureBloc>();
    return DragTarget<int>(
      onAcceptWithDetails: (d) => bloc.add(OrgDepartmentReparented(d.data, null)),
      builder: (context, candidate, _) {
        final active = candidate.isNotEmpty;
        return Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.baseline,
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
          child: Text(
            hint,
            style: TextStyle(
              fontSize: 11,
              color: active ? AppColors.primary : AppColors.inkMuted,
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        );
      },
    );
  }
}

class _DeptRow extends StatefulWidget {
  final OrgStructureState state;
  final DeptRow row;
  const _DeptRow({required this.state, required this.row});

  @override
  State<_DeptRow> createState() => _DeptRowState();
}

class _DeptRowState extends State<_DeptRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final s = OrgStrings.of(context);
    final bloc = context.read<OrgStructureBloc>();
    final dept = widget.row.dept;
    final depth = widget.row.depth;
    final selected = widget.state.selectedDeptId == dept.id;
    final editing = widget.state.editing?.kind == EditKind.department && widget.state.editing?.id == dept.id;
    final linkCount = OrgSelectors.linkCount(widget.state.links, dept.id);

    final content =
        editing
            ? Padding(
              padding: EdgeInsets.only(left: 20 + depth * 16, top: OrgGap.xs, bottom: OrgGap.xs, right: OrgGap.s),
              child: InlineEditRow(
                fields: [
                  OrgEditField(s.englishName, dept.name),
                  OrgEditField(s.arabicName, dept.nameAr ?? '', rtl: true),
                ],
                onSave: (v) => bloc.add(OrgDepartmentRenamed(dept.id, v[0], v[1])),
                onCancel: () => bloc.add(const OrgEditCancelled()),
              ),
            )
            : _display(context, s, bloc, dept, depth, selected, widget.row.hasChildren, linkCount);

    // DragTarget makes every row a "drop-into" zone; Draggable makes the whole
    // row draggable. A valid candidate (not self) tints the row.
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != dept.id,
      onAcceptWithDetails: (d) => bloc.add(OrgDepartmentReparented(d.data, dept.id)),
      builder: (context, candidate, _) {
        final isDropTarget = candidate.isNotEmpty;
        return Draggable<int>(
          data: dept.id,
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: _dragFeedback(context, dept),
          childWhenDragging: Opacity(opacity: 0.35, child: content),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: Container(
              decoration: BoxDecoration(
                color:
                    isDropTarget
                        ? AppColors.primary.withValues(alpha: 0.10)
                        : (selected ? AppColors.primary.withValues(alpha: 0.06) : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
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
    Department dept,
    int depth,
    bool selected,
    bool hasChildren,
    int linkCount,
  ) {
    final displayName = widget.state.lang.label(dept.name, dept.nameAr);
    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0),
      child: SizedBox(
        height: 36,
        child: Row(
          children: [
            Icon(Icons.drag_indicator, size: 15, color: AppColors.inkMuted.withValues(alpha: 0.6)),
            // Chevron (invisible placeholder keeps alignment when no children)
            SizedBox(
              width: 22,
              child:
                  hasChildren
                      ? IconButton(
                        onPressed: () => bloc.add(OrgDeptExpandToggled(dept.id)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: AnimatedRotation(
                          turns: widget.state.expanded.contains(dept.id) ? 0.25 : 0.0,
                          duration: const Duration(milliseconds: 150),
                          child: const Icon(Icons.chevron_right, size: 18, color: AppColors.inkSecondary),
                        ),
                      )
                      : const SizedBox.shrink(),
            ),
            Flexible(
              child: GestureDetector(
                onTap: () => bloc.add(OrgDeptSelected(dept.id)),
                onDoubleTap: () => bloc.add(OrgEditStarted(OrgEditTarget(EditKind.department, dept.id))),
                child: Text(
                  displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: dept.isActive ? (selected ? AppColors.primary : AppColors.inkPrimary) : AppColors.inkMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: OrgGap.s),
            if (dept.code != null) OrgTag(dept.code!),
            if (!dept.isActive) ...[
              const SizedBox(width: OrgGap.xs),
              OrgTag(s.inactive, color: AppColors.statusCancelled),
            ],
            if (linkCount > 0) ...[
              const SizedBox(width: OrgGap.xs),
              OrgTag('$linkCount', icon: Icons.push_pin, color: AppColors.cat2Aqua),
            ],
            // Hover actions
            if (_hover) ...[
              const SizedBox(width: OrgGap.xs),
              _miniAction(Icons.add, s.addSubDepartment, () => bloc.add(OrgDepartmentAdded(dept.id))),
              _miniAction(
                dept.isActive ? Icons.power_settings_new : Icons.power_off,
                dept.isActive ? s.deactivate : s.activate,
                () => bloc.add(OrgDepartmentActiveToggled(dept.id)),
              ),
              _miniAction(
                Icons.delete_outline,
                s.delete,
                () => bloc.add(OrgDepartmentDeleted(dept.id)),
                color: AppColors.statusDeclined,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _miniAction(IconData icon, String tip, VoidCallback onTap, {Color? color}) => IconButton(
    onPressed: onTap,
    icon: Icon(icon, size: 15),
    color: color ?? AppColors.inkSecondary,
    tooltip: tip,
    padding: const EdgeInsets.all(2),
    constraints: const BoxConstraints(),
    visualDensity: VisualDensity.compact,
  );

  Widget _dragFeedback(BuildContext context, Department dept) => Material(
    color: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: OrgGap.m, vertical: OrgGap.s),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Text(
        widget.state.lang.label(dept.name, dept.nameAr),
        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
