import 'package:flutter/material.dart';

import '../../../../core/domain/task_status.dart';
import '../../../../core/format/app_formats.dart';
import '../../../../core/format/due_label.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/task_list_item.dart';
import 'due_color.dart';
import 'person_avatar.dart';
import 'status_pill.dart';
import 'stored_text.dart';
import 'task_flag.dart';

/// One task in the tasks view (spec §4 "Task row").
///
/// Three looks, picked from the task itself:
/// - urgent now: overdue or urgent row colors, a flag before the title
/// - open otherwise: white row
/// - closed: muted row, struck-through title, assignee only (plus «ملغاة»)
///
/// On a wide row the title block sits at the start and the details at the
/// end; on a narrow one the details wrap under the title.
class TaskRow extends StatelessWidget {
  const TaskRow({super.key, required this.task, this.onTap});

  final TaskListItem task;

  /// Opens the task drawer.
  final VoidCallback? onTap;

  /// Below this inner width the details move under the title.
  static const double _wideMinWidth = 640;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final closed = !task.isOpen;
    final (Color bg, Color border) = closed
        ? (tokens.doneRowBg, tokens.doneRowBorder)
        : !task.isUrgentNow
            ? (tokens.surface, tokens.border)
            : task.isOverdue
                ? (tokens.overdueRowBg, tokens.overdueRowBorder)
                : (tokens.urgentRowBg, tokens.urgentRowBorder);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.row),
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
          child: Padding(
            // A Material shape's border takes no layout space; add its 1px so
            // the content sits where the canvas's CSS border box puts it.
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.rowPaddingH + 1,
              vertical: (closed ? 12 : AppSpacing.rowPaddingV) + 1,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final title = _TitleBlock(task: task);
                final details = _Details(task: task);
                if (constraints.maxWidth < _wideMinWidth) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 10,
                    children: [title, details],
                  );
                }
                return Row(
                  spacing: 18,
                  children: [
                    Expanded(child: title),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.55),
                      child: details,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Flag + title, then «ملف / موضوع».
class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.task});

  final TaskListItem task;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final closed = !task.isOpen;
    final titleStyle = closed
        ? AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
            color: tokens.textSoft,
            decoration: TextDecoration.lineThrough,
            decorationColor: tokens.textSoft,
          )
        : AppTextStyles.taskTitle.copyWith(color: tokens.ink);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: closed ? 2 : 4,
      children: [
        FlaggedTitle(
          title: task.title,
          style: titleStyle,
          flag: task.isUrgentNow ? TaskFlag(overdue: task.isOverdue) : null,
        ),
        Text(
          '${task.fileName} / ${task.topicName}',
          style: AppTextStyles.meta.copyWith(color: closed ? tokens.textSoft : tokens.textMuted),
        ),
      ],
    );
  }
}

/// Due label, status, update count and assignee; for a closed task only the
/// «ملغاة» pill (if cancelled) and the assignee.
class _Details extends StatelessWidget {
  const _Details({required this.task});

  final TaskListItem task;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final closed = !task.isOpen;

    final assignee = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        PersonAvatar(userId: task.assigneeId, name: task.assigneeName),
        Text(
          task.assigneeName ?? l10n.formerEmployee,
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: closed ? tokens.textSoft : tokens.ink,
          ),
        ),
      ],
    );

    final List<Widget> children;
    if (closed) {
      children = [
        if (task.status == TaskStatus.cancelled) StatusPill(task.status),
        assignee,
      ];
    } else {
      final dueColor = dueColorFor(tokens, task);
      children = [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          children: [
            Icon(Icons.calendar_today_outlined, size: 16, color: dueColor),
            Text(
              DueLabel.format(l10n, daysUntilDue: task.daysUntilDue, dueDate: task.dueDate),
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                fontWeight: task.isUrgentNow ? FontWeight.w600 : FontWeight.w400,
                color: dueColor,
              ),
            ),
          ],
        ),
        StatusPill(task.status),
        Semantics(
          label: l10n.updatesCount(AppFormats.number(task.updateCount)),
          excludeSemantics: true,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Icon(Icons.chat_bubble_outline, size: 16, color: tokens.textMuted),
              Text(
                AppFormats.number(task.updateCount),
                style: AppTextStyles.meta.copyWith(color: tokens.textMuted),
              ),
            ],
          ),
        ),
        assignee,
      ];
    }

    return Wrap(
      spacing: 14,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
  }
}
