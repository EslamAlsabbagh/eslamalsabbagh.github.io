import 'package:flutter/material.dart';

import '../../../../core/domain/task_status.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/task_list_item.dart';
import 'urgent_checkbox.dart';

/// The drawer's urgent panel: «تعليم كعاجلة يدويًا» and a note on why the
/// task is (or will become) urgent (spec §3 "Drawer urgent note texts").
class UrgentBox extends StatelessWidget {
  const UrgentBox({
    super.key,
    required this.task,
    required this.isManualUrgent,
    required this.onChanged,
    this.dimmed = false,
  });

  final TaskListItem task;
  final bool isManualUrgent;

  /// Null makes the checkbox inert.
  final ValueChanged<bool>? onChanged;
  final bool dimmed;

  /// From the database's fields, in the canvas's order.
  static String note(AppLocalizations l10n, TaskListItem task, {required bool isManualUrgent}) {
    if (task.status == TaskStatus.cancelled) return l10n.urgentNoteCancelled;
    if (task.status == TaskStatus.done) return l10n.urgentNoteDone;
    if (task.isOverdue) return l10n.urgentNoteOverdue;
    if (task.daysUntilDue == 0) return l10n.urgentNoteToday;
    if (isManualUrgent) return l10n.urgentNoteManual;
    return l10n.urgentNoteLater;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.urgentPanelBg,
        border: Border.all(color: tokens.urgentPanelBorder),
        borderRadius: BorderRadius.circular(AppRadii.row),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14 + 1, vertical: 12 + 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Opacity(
              opacity: dimmed ? 0.45 : 1,
              child: UrgentCheckbox(
                key: const Key('urgent-toggle'),
                label: l10n.drawerManualUrgent,
                value: isManualUrgent,
                onChanged: onChanged,
                minHeight: 32,
              ),
            ),
            Text(
              note(l10n, task, isManualUrgent: isManualUrgent),
              style: AppTextStyles.meta.copyWith(color: tokens.urgentPanelText),
            ),
          ],
        ),
      ),
    );
  }
}
