import 'package:flutter/material.dart';

import '../../../../core/format/app_formats.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../bloc/tasks_bloc.dart';
import '../../data/task_list_item.dart';
import 'compact_task_row.dart';
import 'task_flag.dart';

/// A topic (brand) card in the «المواضيع» view (spec §4 View 2): name and
/// urgent badge, progress (done of all but cancelled), then the open tasks.
class TopicCard extends StatelessWidget {
  const TopicCard({super.key, required this.summary, required this.onOpen, this.onRename});

  final TopicSummary summary;
  final ValueChanged<TaskListItem> onOpen;

  /// Managers and admins: shows the pencil at the end of the heading row.
  final VoidCallback? onRename;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final urgent = summary.urgentCount;
    final total = summary.progressTotal;
    final muted = AppTextStyles.badge.copyWith(fontWeight: FontWeight.w400, color: tokens.textMuted);

    // A container, so a screen reader finishes one card before the next
    // instead of reading across the cards of a grid row. Its parts keep
    // their own nodes (the heading, the progress, each row's button).
    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.border),
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Expanded(
                  // One heading node, «عقد براند» then the name, read before the badge.
                  child: Semantics(
                    container: true,
                    header: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Text(l10n.topicBrandLabel, style: muted),
                        Text(
                          summary.topic.name,
                          style: AppTextStyles.cardTitle.copyWith(color: tokens.ink),
                        ),
                      ],
                    ),
                  ),
                ),
                if (urgent > 0)
                  TaskFlag(
                    key: const Key('topic-urgent-badge'),
                    overdue: false,
                    verticalPadding: 2,
                    label: l10n.urgentCountLabel(AppFormats.number(urgent)),
                  ),
                if (onRename case final onRename?)
                  _RenameButton(topicName: summary.topic.name, onPressed: onRename),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                _ProgressBar(value: total == 0 ? 0 : summary.doneCount / total),
                Text(
                  total == 0
                      ? l10n.topicNoTasks
                      : l10n.topicProgress(AppFormats.number(summary.doneCount), AppFormats.number(total)),
                  key: const Key('topic-progress'),
                  style: muted,
                ),
              ],
            ),
            if (summary.openTasks.isEmpty)
              Text(l10n.topicNoOpenTasks, style: AppTextStyles.meta.copyWith(color: tokens.textMuted))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 6,
                children: [
                  for (final task in summary.openTasks)
                    CompactTaskRow(key: ValueKey(task.id), task: task, onTap: () => onOpen(task)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// 6px track in `progressTrack`, filled with `accent` from the start side.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  /// 0 to 1.
  final double value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(3);
    // The text under it says the same; the bar itself is decoration.
    return ExcludeSemantics(
      child: Container(
        height: 6,
        decoration: BoxDecoration(color: tokens.progressTrack, borderRadius: radius),
        alignment: AlignmentDirectional.centerStart,
        child: FractionallySizedBox(
          widthFactor: value,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(color: tokens.accent, borderRadius: radius),
          ),
        ),
      ),
    );
  }
}

/// The pencil at the end of the heading row: a 44px target with an 18px
/// `textMuted` glyph. The tooltip is for the mouse only; screen readers get
/// one label with the topic's name.
class _RenameButton extends StatelessWidget {
  const _RenameButton({required this.topicName, required this.onPressed});

  final String topicName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.editTopicTooltip,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: l10n.editTopicSemantics(topicName),
        excludeSemantics: true,
        onTap: onPressed,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: const Key('rename-topic'),
            borderRadius: BorderRadius.circular(AppRadii.button),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: AppSpacing.touchTarget,
              child: Icon(Icons.edit_outlined, size: 18, color: tokens.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
