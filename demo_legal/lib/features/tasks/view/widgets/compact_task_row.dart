import 'package:flutter/material.dart';

import '../../../../core/format/due_label.dart';
import '../../../../core/format/text_direction.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/task_list_item.dart';
import 'due_color.dart';
import 'person_avatar.dart';

/// An open task inside a topic card (spec §4 View 2): avatar, title on one
/// line, due label. Urgent rows (overdue included) take the urgent colors,
/// as in the canvas. The whole row is one button that opens the drawer.
class CompactTaskRow extends StatelessWidget {
  const CompactTaskRow({super.key, required this.task, this.onTap});

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
              // 8 × 10 plus the 1px border, which the Material shape doesn't lay out.
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 11, vertical: 9),
              child: Row(
                spacing: 10,
                children: [
                  // The avatar is a letter; screen readers get the name instead.
                  Semantics(
                    label: task.assigneeName ?? l10n.formerEmployee,
                    child: PersonAvatar(userId: task.assigneeId, name: task.assigneeName, size: 26),
                  ),
                  Expanded(
                    child: Text(
                      task.title,
                      textDirection: textDirectionOf(task.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: tokens.ink,
                      ),
                    ),
                  ),
                  Text(
                    DueLabel.format(l10n, daysUntilDue: task.daysUntilDue, dueDate: task.dueDate),
                    style: AppTextStyles.badge.copyWith(color: dueColorFor(tokens, task)),
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
