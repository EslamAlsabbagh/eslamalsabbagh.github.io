import 'package:flutter/material.dart';

import '../../../../core/format/due_label.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/task_list_item.dart';
import 'due_color.dart';
import 'status_pill.dart';
import 'stored_text.dart';
import 'task_flag.dart';

/// An open task inside a person card (spec §4 View 3), on two lines: the
/// flag (when urgent) and the title, then «ملف / موضوع» at the start with the
/// status and due label at the end. Colored like [CompactTaskRow]. The whole
/// row is one button that opens the drawer.
class PersonTaskRow extends StatelessWidget {
  const PersonTaskRow({super.key, required this.task, this.onTap});

  final TaskListItem task;

  /// Opens the task drawer.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final (Color bg, Color border) = task.isUrgentNow
        ? (tokens.urgentRowBg, tokens.urgentRowBorder)
        : (tokens.miniBg, tokens.miniBorder);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.button),
      side: BorderSide(color: border),
    );

    // A button, as in the canvas; InkWell alone only adds the tap action.
    return Semantics(
      container: true,
      button: true,
      child: Material(
        color: bg,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
            child: Padding(
              // 10 × 12 plus the 1px border, which the Material shape doesn't lay out.
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 13, vertical: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 4,
                children: [
                  FlaggedTitle(
                    title: task.title,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: tokens.ink,
                    ),
                    flag: task.isUrgentNow ? TaskFlag(overdue: task.isOverdue, verticalPadding: 0) : null,
                  ),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${task.fileName} / ${task.topicName}',
                        style: AppTextStyles.badge.copyWith(fontWeight: FontWeight.w400, color: tokens.textMuted),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 8,
                        children: [
                          StatusPill(task.status, dense: true),
                          Text(
                            DueLabel.format(l10n, daysUntilDue: task.daysUntilDue, dueDate: task.dueDate),
                            style: AppTextStyles.badge.copyWith(color: dueColorFor(tokens, task)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
