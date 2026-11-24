import 'package:flutter/material.dart';

import '../../../../core/domain/contract_list_status.dart';
import '../../../../core/domain/task_status.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/contract_l10n.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// A contract's list status, 12 / 600 in the task status pill's shape. The
/// colors reuse the task statuses' (DESIGN_SPEC §4 View 4 "List status
/// pills"); red stays for what is overdue, so only «منتهية» has it.
class ContractStatusPill extends StatelessWidget {
  const ContractStatusPill(this.status, {super.key});

  final ContractListStatus status;

  static ColorPair colorsFor(AppTokens tokens, ContractListStatus status) => switch (status) {
        ContractListStatus.active => tokens.status(TaskStatus.done),
        ContractListStatus.ending => tokens.status(TaskStatus.waiting),
        ContractListStatus.expired => ColorPair(tokens.overdueRowBg, tokens.overdue),
        ContractListStatus.terminated => tokens.status(TaskStatus.cancelled),
      };

  @override
  Widget build(BuildContext context) {
    final colors = colorsFor(context.tokens, status);
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 2),
        child: Text(
          status.label(AppLocalizations.of(context)),
          style: AppTextStyles.badge.copyWith(color: colors.fg),
        ),
      ),
    );
  }
}
