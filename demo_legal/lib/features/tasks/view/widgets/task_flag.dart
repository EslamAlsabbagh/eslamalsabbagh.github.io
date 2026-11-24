import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// «متأخرة» (overdue color) or «عاجلة» (urgent color) before a task title.
/// With a [label], the same badge with other text (a topic's «١ عاجلة»).
class TaskFlag extends StatelessWidget {
  const TaskFlag({super.key, required this.overdue, this.verticalPadding = 1, this.label});

  final bool overdue;

  /// Replaces «متأخرة» / «عاجلة».
  final String? label;

  /// 1 in a row, 2 above the drawer title.
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: overdue ? tokens.overdue : tokens.urgent,
        borderRadius: BorderRadius.circular(AppRadii.flag),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: 8, vertical: verticalPadding),
        child: Text(
          label ?? (overdue ? l10n.flagOverdue : l10n.flagUrgent),
          style: AppTextStyles.badge.copyWith(color: tokens.surface),
        ),
      ),
    );
  }
}
