import 'package:flutter/material.dart';

import '../../../../core/format/due_label.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/task_list_item.dart';
import 'date_field_box.dart';

/// «موعد التسليم»: the date («١٣ أكتوبر ٢٠٢٦») in an input box that opens
/// the date picker, and the due label under it in the row's colors.
class DueDateField extends StatelessWidget {
  const DueDateField({super.key, required this.task, required this.onPicked, this.dimmed = false});

  final TaskListItem task;

  /// Null makes the field inert.
  final ValueChanged<DateTime>? onPicked;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    // Canvas: overdue red, due-today orange (open only), otherwise textSoft.
    final labelColor = task.isOverdue
        ? tokens.overdue
        : task.isOpen && task.daysUntilDue == 0
            ? tokens.urgentText
            : tokens.textSoft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 6,
      children: [
        DateFieldBox(date: task.dueDate, onPicked: onPicked, dimmed: dimmed),
        Text(
          DueLabel.format(l10n, daysUntilDue: task.daysUntilDue, dueDate: task.dueDate),
          style: AppTextStyles.fieldLabel.copyWith(color: labelColor),
        ),
      ],
    );
  }
}
