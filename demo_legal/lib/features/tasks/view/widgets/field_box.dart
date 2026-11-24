import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_theme.dart';

/// The canvas's `<select>` / `<input type="date">` box: min height 44,
/// 12px side padding, 1px `borderStrong`, radius 10, `surface`.
///
/// [dimmed] fades it to the 45% used for disabled controls.
class FieldBox extends StatelessWidget {
  const FieldBox({super.key, required this.child, this.onTap, this.dimmed = false});

  final Widget child;
  final VoidCallback? onTap;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.input),
      side: BorderSide(color: tokens.borderStrong),
    );
    return Opacity(
      opacity: dimmed ? 0.45 : 1,
      child: Material(
        color: tokens.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
            child: Padding(
              // Plus the 1px border, which a Material shape doesn't lay out.
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 12 + 1),
              child: Align(alignment: AlignmentDirectional.centerStart, heightFactor: 1, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
