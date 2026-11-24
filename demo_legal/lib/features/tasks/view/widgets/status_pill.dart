import 'package:flutter/material.dart';

import '../../../../core/domain/task_status.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../l10n/task_status_l10n.dart';

/// Status label in its enum colors (spec §1 "Status colors"), 13 / 600.
/// [dense] is the «الموظفون» rows' smaller pill: 12 / 600, no vertical padding.
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key, this.dense = false});

  final TaskStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.tokens.status(status);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: dense
            ? const EdgeInsetsDirectional.symmetric(horizontal: 8)
            : const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 2),
        child: Text(
          status.label(AppLocalizations.of(context)),
          style: (dense ? AppTextStyles.badge : AppTextStyles.fieldLabel).copyWith(color: colors.fg),
        ),
      ),
    );
  }
}
