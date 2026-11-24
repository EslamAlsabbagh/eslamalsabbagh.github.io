import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// The × of the drawer and the modals: 44px, radius 10, `subtleFill`, read
/// «إغلاق» once.
class CloseIconButton extends StatelessWidget {
  const CloseIconButton({super.key, required this.buttonKey, required this.onPressed});

  /// On the tap target, under the one semantics node, so a test that finds
  /// the button by key reads that node.
  final Key buttonKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final label = AppLocalizations.of(context).drawerClose;
    // The tooltip is for the mouse only: screen readers get the one label
    // below (with both, they read «إغلاق» twice).
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Semantics(
        button: true,
        label: label,
        // The label replaces the InkWell's node, so the tap is declared here
        // too, for screen readers.
        excludeSemantics: true,
        onTap: onPressed,
        child: Material(
          color: tokens.subtleFill,
          borderRadius: BorderRadius.circular(AppRadii.button),
          child: InkWell(
            key: buttonKey,
            borderRadius: BorderRadius.circular(AppRadii.button),
            onTap: onPressed,
            child: SizedBox.square(
              dimension: AppSpacing.touchTarget,
              child: Icon(Icons.close, size: 20, color: tokens.ink),
            ),
          ),
        ),
      ),
    );
  }
}
