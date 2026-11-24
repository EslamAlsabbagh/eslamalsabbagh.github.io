import 'package:flutter/material.dart';

import '../../../../core/domain/task_status.dart';
import '../../../../core/format/app_formats.dart';
import '../../../../core/format/arabic_count.dart';
import '../../../../core/format/text_direction.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/contract_list_item.dart';
import 'contract_status_pill.dart';

/// One main contract in «العقود» (DESIGN_SPEC §4 View 4 "List"), in the
/// «اليوم» row's box. The row is one button that opens the contract drawer.
///
/// - Line 1: the brand («بدون براند» when none) and the status pill.
/// - Line 2: «المستأجر · الوحدات · حتى ٣١ ديسمبر ٢٠٣٢».
/// - At the end: the annex, storage, follow-up and missing-item badges,
///   each only above 0.
///
/// On a narrow row the badges wrap under the lines.
class ContractRow extends StatelessWidget {
  const ContractRow({super.key, required this.contract, required this.brand, this.onTap});

  final ContractListItem contract;

  /// Opens the contract drawer.
  final VoidCallback? onTap;

  /// The brand (topic) name; null for a contract without one.
  final String? brand;

  /// Below this inner width the badges move under the lines.
  static const double _wideMinWidth = 640;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.row),
      side: BorderSide(color: tokens.border),
    );
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final lines = _Lines(contract: contract, brand: brand);
        final badges = _Badges.hasAny(contract) ? _Badges(contract: contract) : null;
        if (constraints.maxWidth < _wideMinWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [lines, ?badges],
          );
        }
        return Row(
          spacing: 18,
          children: [
            Expanded(child: lines),
            if (badges != null)
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.45),
                child: badges,
              ),
          ],
        );
      },
    );
    // A button, like the «اليوم» row; InkWell alone only adds the tap action.
    return Semantics(
      container: true,
      button: onTap != null,
      child: Material(
        color: tokens.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            // A Material shape's border takes no layout space; add its 1px so
            // the content sits where the row's border box puts it.
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.rowPaddingH + 1,
              vertical: AppSpacing.rowPaddingV + 1,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// The brand and pill, then the tenant, units and end date.
class _Lines extends StatelessWidget {
  const _Lines({required this.contract, required this.brand});

  final ContractListItem contract;
  final String? brand;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final brand = this.brand;
    final meta = AppTextStyles.meta.copyWith(color: tokens.textMuted);

    // Each part is its own Text, so an English tenant or a unit code reads
    // in its own direction without bidi marks (CLAUDE.md).
    final parts = <Widget>[
      if (contract.partyName case final party?) Text(party, textDirection: textDirectionOf(party), style: meta),
      if (contract.unitCodes.isNotEmpty) _Units(codes: contract.unitCodes, style: meta),
      if (contract.endsOn case final endsOn?)
        Text(l10n.contractEndsOn(AppFormats.fullDate(endsOn)), style: meta)
      else if (contract.dateNote case final note?)
        Text(note, textDirection: textDirectionOf(note), style: meta),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (brand != null)
              Text(brand, textDirection: textDirectionOf(brand), style: AppTextStyles.taskTitle.copyWith(color: tokens.ink))
            else
              Text(l10n.contractNoBrand, style: AppTextStyles.taskTitle.copyWith(color: tokens.textMuted)),
            ContractStatusPill(contract.listStatus),
          ],
        ),
        if (parts.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 2,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final (i, part) in parts.indexed) ...[
                if (i > 0) ExcludeSemantics(child: Text('·', style: meta)),
                part,
              ],
            ],
          ),
      ],
    );
  }
}

/// Up to two unit codes, or the first and «+ ٢» for the rest. Codes are
/// written left to right.
class _Units extends StatelessWidget {
  const _Units({required this.codes, required this.style});

  final List<String> codes;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    Widget code(String text) => Text(text, textDirection: TextDirection.ltr, style: style);
    final shown = codes.length > 2 ? codes.take(1) : codes;
    return Wrap(
      spacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, text) in shown.indexed) ...[
          if (i > 0) Text('،', style: style),
          code(text),
        ],
        if (codes.length > 2)
          Text(AppLocalizations.of(context).contractMoreUnits(AppFormats.number(codes.length - 1)), style: style),
      ],
    );
  }
}

/// «٣ ملاحق», «مخزن», «متابعة», «نقصان»: counts above 0, with the §1 plural
/// rule (chosen 2026-11-12). Missing items take the `waiting` colors.
class _Badges extends StatelessWidget {
  const _Badges({required this.contract});

  final ContractListItem contract;

  static bool hasAny(ContractListItem c) =>
      c.annexCount > 0 || c.storageCount > 0 || c.openTaskCount > 0 || c.openItemCount > 0;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final plain = ColorPair(tokens.mutedFill, tokens.ink);
    final c = contract;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (c.annexCount > 0)
          ContractBadge(
            key: const Key('badge-annexes'),
            text: arabicCount(
              c.annexCount,
              one: l10n.annexCountOne,
              two: l10n.annexCountTwo,
              few: l10n.annexCountFew,
              many: l10n.annexCountMany,
            ),
            colors: plain,
          ),
        if (c.storageCount > 0)
          ContractBadge(
            key: const Key('badge-storage'),
            text: arabicCount(
              c.storageCount,
              one: l10n.storageCountOne,
              two: l10n.storageCountTwo,
              few: l10n.storageCountFew,
              many: l10n.storageCountMany,
            ),
            colors: plain,
          ),
        if (c.openTaskCount > 0)
          ContractBadge(
            key: const Key('badge-follow-ups'),
            text: arabicCount(
              c.openTaskCount,
              one: l10n.followUpCountOne,
              two: l10n.followUpCountTwo,
              few: l10n.followUpCountFew,
              many: l10n.followUpCountMany,
            ),
            colors: plain,
          ),
        if (c.openItemCount > 0)
          ContractBadge(
            key: const Key('badge-missing'),
            text: arabicCount(
              c.openItemCount,
              one: l10n.missingCountOne,
              two: l10n.missingCountTwo,
              few: l10n.missingCountFew,
              many: l10n.missingCountMany,
            ),
            colors: tokens.status(TaskStatus.waiting),
          ),
      ],
    );
  }
}

class ContractBadge extends StatelessWidget {
  const ContractBadge({super.key, required this.text, required this.colors});

  final String text;
  final ColorPair colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.bg, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 2),
        child: Text(text, style: AppTextStyles.badge.copyWith(color: colors.fg)),
      ),
    );
  }
}
