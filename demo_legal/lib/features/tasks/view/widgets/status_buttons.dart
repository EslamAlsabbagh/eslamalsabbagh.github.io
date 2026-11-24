import 'package:flutter/material.dart';

import '../../../../core/domain/task_status.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../l10n/task_status_l10n.dart';

/// «الحالة» in the drawer: one pill toggle per status, cancelled excluded
/// (it has its own action). A cancelled task has none pressed; picking one
/// reopens it.
///
/// Pressed: status `fg` fill, white text. Otherwise white, `fg` text,
/// `chipBorder` border (spec §1).
class StatusButtons extends StatelessWidget {
  const StatusButtons({super.key, required this.selected, required this.onPicked, this.dimmed = false});

  final TaskStatus selected;

  /// Null makes the buttons inert (read-only, or a save in flight).
  final ValueChanged<TaskStatus>? onPicked;
  final bool dimmed;

  static const _choices = [TaskStatus.todo, TaskStatus.doing, TaskStatus.waiting, TaskStatus.done];

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final onPicked = this.onPicked;

    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final status in _choices)
            Builder(builder: (context) {
              final colors = tokens.status(status);
              final pressed = status == selected;
              final onTap = onPicked == null ? null : () => onPicked(status);
              final shape = RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                side: BorderSide(color: pressed ? colors.fg : tokens.chipBorder),
              );
              return Semantics(
                button: true,
                selected: pressed,
                enabled: onPicked != null,
                // The label replaces the InkWell's node, so the tap is
                // declared here too, for screen readers.
                excludeSemantics: true,
                label: status.label(l10n),
                onTap: onTap,
                child: Material(
                  color: pressed ? colors.fg : tokens.surface,
                  shape: shape,
                  child: InkWell(
                    key: Key('status-${status.name}'),
                    customBorder: shape,
                    onTap: onTap,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: AppSpacing.chipHeight),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14 + 1),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            status.label(l10n),
                            style: AppTextStyles.button.copyWith(
                              color: pressed ? tokens.surface : colors.fg,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
