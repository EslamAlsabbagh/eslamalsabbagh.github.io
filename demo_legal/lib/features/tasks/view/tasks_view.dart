import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/app_formats.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/tasks_bloc.dart';
import '../data/task_list_item.dart';
import 'task_drawer.dart';
import 'widgets/empty_section.dart';
import 'widgets/expand_toggle.dart';
import 'widgets/section_header.dart';
import 'widgets/task_row.dart';

/// View 1, «المهام والأولوية»: the urgent, upcoming and (collapsed) closed
/// sections, narrowed by the file chip and the search. A row opens the task
/// drawer. The chips and the search field sit above it in [TasksHome].
class TasksView extends StatelessWidget {
  const TasksView({super.key, this.clock = DateTime.now});

  /// "Now" for the drawer's update times; injectable for tests.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TasksBloc>().state;

    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final bloc = context.read<TasksBloc>();
    final closed = state.closed;
    void open(TaskListItem task) => showTaskDrawer(context, task, clock: clock);

    final noMatches = state.searchResultCount == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (noMatches)
          EmptySection(
            l10n.searchNoResults(state.searchedTerm),
            key: const Key('search-empty'),
          ),
        if (!noMatches) ...[
          _Section(
            key: const Key('section-urgent'),
            header: SectionHeader(
              title: l10n.sectionUrgentTitle,
              caption: l10n.sectionUrgentCaption,
              color: tokens.urgentText,
            ),
            tasks: state.urgent,
            emptyMessage: l10n.emptyUrgent,
            onOpen: open,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _Section(
            key: const Key('section-upcoming'),
            header: SectionHeader(
              title: l10n.sectionUpcomingTitle,
              caption: l10n.sectionUpcomingCaption,
            ),
            tasks: state.upcoming,
            emptyMessage: l10n.emptyUpcoming,
            onOpen: open,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          _Section(
            key: const Key('section-closed'),
            header: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                SectionHeader(title: l10n.sectionClosedTitle, color: tokens.textMuted),
                _ClosedToggle(
                  expanded: state.showClosed,
                  count: closed.length,
                  onPressed: () => bloc.add(const TasksClosedToggled()),
                ),
              ],
            ),
            tasks: state.showClosed ? closed : const [],
            onOpen: open,
          ),
        ],
      ],
    );
  }
}

/// Title, then the rows (or the empty box when [emptyMessage] is set).
class _Section extends StatelessWidget {
  const _Section({
    super.key,
    required this.header,
    required this.tasks,
    required this.onOpen,
    this.emptyMessage,
  });

  final Widget header;
  final List<TaskListItem> tasks;
  final ValueChanged<TaskListItem> onOpen;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final emptyMessage = this.emptyMessage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        header,
        if (tasks.isEmpty && emptyMessage != null) EmptySection(emptyMessage),
        if (tasks.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.rowGap,
            children: [
              for (final task in tasks)
                TaskRow(key: ValueKey(task.id), task: task, onTap: () => onOpen(task)),
            ],
          ),
      ],
    );
  }
}

/// «عرض / إخفاء المكتملة (n)».
class _ClosedToggle extends StatelessWidget {
  const _ClosedToggle({required this.expanded, required this.count, required this.onPressed});

  final bool expanded;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final countText = AppFormats.number(count);
    return ExpandToggle(
      buttonKey: const Key('closed-toggle'),
      expanded: expanded,
      label: expanded ? l10n.hideClosed(countText) : l10n.showClosed(countText),
      onPressed: onPressed,
    );
  }
}
