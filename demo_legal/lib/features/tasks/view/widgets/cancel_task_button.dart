import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import 'confirm_dialog.dart';

/// «إلغاء المهمة» at the bottom of the drawer (not in the canvas; ADR-0003).
/// A quiet outline button that asks before cancelling.
class CancelTaskButton extends StatelessWidget {
  const CancelTaskButton({super.key, required this.onConfirmed});

  /// Null makes the button inert (a save in flight).
  final VoidCallback? onConfirmed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onConfirmed = this.onConfirmed;
    return OutlinedButton(
      key: const Key('cancel-task'),
      onPressed: onConfirmed == null
          ? null
          : () async {
              final confirmed = await showConfirmDialog(
                context,
                title: l10n.cancelTaskTitle,
                body: l10n.cancelTaskBody,
                backLabel: l10n.cancelTaskBack,
                confirmLabel: l10n.cancelTask,
                keyPrefix: 'cancel-task',
              );
              if (confirmed) onConfirmed();
            },
      style: quietOutlineButtonStyle(context),
      child: Text(l10n.cancelTask),
    );
  }
}
