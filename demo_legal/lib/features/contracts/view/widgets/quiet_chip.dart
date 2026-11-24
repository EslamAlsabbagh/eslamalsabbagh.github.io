import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// A 40-high quiet chip: `surface`, a `chipBorder` border and ink text;
/// selected, `ink` with white text, like the file chips. The contracts
/// filter row and the contract form's kind and status chips. A null [onTap]
/// fades it to 45% and makes it inert.
class QuietChip extends StatelessWidget {
  const QuietChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      side: BorderSide(color: selected ? tokens.ink : tokens.chipBorder),
    );
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap == null ? false : null,
      child: Opacity(
        opacity: onTap == null ? 0.45 : 1,
        child: Material(
          color: selected ? tokens.ink : tokens.surface,
          shape: shape,
          child: InkWell(
            customBorder: shape,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.chipHeight),
              child: Padding(
                // 14 + the 1px border, which the Material shape doesn't lay out.
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 15),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    style: AppTextStyles.body.copyWith(fontSize: 14, color: selected ? tokens.surface : tokens.ink),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
