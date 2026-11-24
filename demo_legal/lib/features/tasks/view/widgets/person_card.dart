import 'package:flutter/material.dart';

import '../../../../core/format/app_formats.dart';
import '../../../../core/format/arabic_count.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../bloc/tasks_bloc.dart';
import '../../data/task_list_item.dart';
import 'person_avatar.dart';
import 'person_task_row.dart';
import 'task_flag.dart';

/// A person card in the «الموظفون» view (spec §4 View 3): avatar, name,
/// open-task count and urgent badge, then their open tasks.
class PersonCard extends StatelessWidget {
  const PersonCard({super.key, required this.summary, required this.onOpen});

  final PersonSummary summary;
  final ValueChanged<TaskListItem> onOpen;

  static const double _avatarSize = 44;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final urgent = summary.urgentCount;
    final open = summary.openTasks.length;

    // A container, so a screen reader finishes one card before the next
    // instead of reading across the cards of a grid row. Its parts keep
    // their own nodes (the heading, the summary, each row's button).
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
          spacing: 14,
          children: [
            Row(
              spacing: 12,
              children: [
                PersonAvatar(userId: summary.id, name: summary.name, size: _avatarSize, letterSize: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          summary.name ?? l10n.formerEmployee,
                          style: AppTextStyles.cardTitle.copyWith(color: tokens.ink),
                        ),
                      ),
                      Text(
                        open == 0
                            ? l10n.openTaskCountZero
                            : arabicCount(
                                open,
                                one: l10n.openTaskCountOne,
                                two: l10n.openTaskCountTwo,
                                few: l10n.openTaskCountFew,
                                many: l10n.openTaskCountMany,
                              ),
                        key: const Key('person-summary'),
                        style: AppTextStyles.meta.copyWith(color: tokens.textMuted),
                      ),
                    ],
                  ),
                ),
                if (urgent > 0)
                  TaskFlag(
                    key: const Key('person-urgent-badge'),
                    overdue: false,
                    verticalPadding: 2,
                    label: l10n.urgentCountLabel(AppFormats.number(urgent)),
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
                    PersonTaskRow(key: ValueKey(task.id), task: task, onTap: () => onOpen(task)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
