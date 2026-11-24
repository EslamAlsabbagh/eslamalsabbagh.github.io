import 'package:flutter/material.dart';

import '../../../../core/format/app_formats.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../tasks/data/task_list_item.dart';
import '../../../tasks/view/widgets/compact_task_row.dart';
import '../../../tasks/view/widgets/expand_toggle.dart';
import '../../../tasks/view/widgets/task_row.dart';
import 'contract_sections.dart';

/// The follow-up tasks of a contract: the loaded tasks linked to it or to a
/// row under it ([contractIds]), in the task list's order.
List<TaskListItem> followUpsOf(List<TaskListItem> tasks, Set<String> contractIds) => [
      for (final task in tasks)
        if (task.contractId case final id? when contractIds.contains(id)) task,
    ];

/// «المتابعات (n)» (DESIGN_SPEC §4 "Contract drawer" → Sections 4): the open
/// follow-ups as compact rows (avatar · title · due label, `urgentRow`
/// colors when urgent), as in «المواضيع», and the closed ones behind
/// «عرض المكتملة (n)». A row opens the task drawer over this one; «+ إضافة
/// متابعة» the new-task modal with the file, brand and contract fixed
/// ([onAdd] null hides it).
class ContractFollowUpsSection extends StatefulWidget {
  const ContractFollowUpsSection({super.key, required this.tasks, required this.onOpen, required this.onAdd});

  /// In the task list's order ([followUpsOf]).
  final List<TaskListItem> tasks;
  final ValueChanged<TaskListItem> onOpen;
  final VoidCallback? onAdd;

  @override
  State<ContractFollowUpsSection> createState() => _ContractFollowUpsSectionState();
}

class _ContractFollowUpsSectionState extends State<ContractFollowUpsSection> {
  bool _showClosed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final open = widget.tasks.where((t) => t.isOpen).toList();
    final closed = widget.tasks.where((t) => !t.isOpen).toList();
    final count = AppFormats.number(closed.length);
    return Column(
      key: const Key('contract-followups'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        DrawerSectionHeader(
          title: l10n.contractFollowUpsTitle(AppFormats.number(open.length)),
          addLabel: l10n.contractAddFollowUp,
          addKey: const Key('contract-add-followup'),
          onAdd: widget.onAdd,
        ),
        for (final task in open)
          CompactTaskRow(key: ValueKey('followup-${task.id}'), task: task, onTap: () => widget.onOpen(task)),
        if (closed.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ExpandToggle(
              buttonKey: const Key('followups-closed-toggle'),
              expanded: _showClosed,
              label: _showClosed ? l10n.hideClosed(count) : l10n.showClosed(count),
              onPressed: () => setState(() => _showClosed = !_showClosed),
            ),
          ),
        if (_showClosed)
          for (final task in closed)
            TaskRow(key: ValueKey('followup-${task.id}'), task: task, onTap: () => widget.onOpen(task)),
      ],
    );
  }
}
