import 'package:flutter/material.dart';

import '../../../../core/domain/user_role.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../l10n/user_role_l10n.dart';

/// «الدور»: one pill toggle per role, styled like the drawer's status buttons
/// with `ink` as the pressed color. [onPicked] null makes them inert.
class RoleChoice extends StatelessWidget {
  const RoleChoice({super.key, required this.selected, required this.onPicked});

  final UserRole selected;
  final ValueChanged<UserRole>? onPicked;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final onPicked = this.onPicked;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final role in UserRole.values)
          Builder(
            builder: (context) {
              final pressed = role == selected;
              final onTap = onPicked == null ? null : () => onPicked(role);
              final shape = RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                side: BorderSide(color: pressed ? tokens.ink : tokens.chipBorder),
              );
              return Semantics(
                button: true,
                selected: pressed,
                inMutuallyExclusiveGroup: true,
                enabled: onPicked != null,
                // The label replaces the InkWell's node, so the tap is declared
                // here too, as on the status buttons.
                excludeSemantics: true,
                label: role.label(l10n),
                onTap: onTap,
                child: Material(
                  color: pressed ? tokens.ink : tokens.surface,
                  shape: shape,
                  child: InkWell(
                    key: Key('role-${role.name}'),
                    customBorder: shape,
                    onTap: onTap,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: AppSpacing.chipHeight),
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(horizontal: 14 + 1),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            role.label(l10n),
                            style: AppTextStyles.button.copyWith(color: pressed ? tokens.surface : tokens.ink),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
