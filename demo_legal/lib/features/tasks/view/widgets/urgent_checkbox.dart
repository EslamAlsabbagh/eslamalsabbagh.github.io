import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// The manual urgent flag: a 20px checkbox in `urgent` and its 600 label,
/// read as one checkbox and tappable as a whole. Used by the drawer's urgent
/// panel and the new-task modal.
class UrgentCheckbox extends StatelessWidget {
  const UrgentCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.minHeight = AppSpacing.touchTarget,
  });

  final String label;
  final bool value;

  /// Null makes it inert.
  final ValueChanged<bool>? onChanged;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final onChanged = this.onChanged;
    return MergeSemantics(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.flag),
        onTap: onChanged == null ? null : () => onChanged(!value),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              SizedBox.square(
                dimension: 20,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged == null ? null : (value) => onChanged(value ?? false),
                  activeColor: tokens.urgent,
                  checkColor: tokens.surface,
                  side: BorderSide(color: tokens.textMuted, width: 1.5),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Flexible(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600, color: tokens.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
