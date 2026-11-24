import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// «عرض / إخفاء …»: the outline button, 40 high, that opens and closes a
/// section («المكتملة», the drawer's «سجل التغييرات»). Screen readers hear its
/// expanded state.
class ExpandToggle extends StatelessWidget {
  const ExpandToggle({
    super.key,
    required this.buttonKey,
    required this.expanded,
    required this.label,
    required this.onPressed,
  });

  /// On the button itself, for tests.
  final Key buttonKey;
  final bool expanded;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    // Merged, so «expanded» lands on the button's own node; a plain Semantics
    // would hand it up to the parent instead.
    return MergeSemantics(
      child: Semantics(
        expanded: expanded,
        child: OutlinedButton(
          key: buttonKey,
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: tokens.ink,
            textStyle: AppTextStyles.body.copyWith(fontSize: 14),
            minimumSize: const Size(0, AppSpacing.chipHeight),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 14),
            side: BorderSide(color: tokens.borderStrong),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
