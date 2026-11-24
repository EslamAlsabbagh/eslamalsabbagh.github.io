import 'package:flutter/material.dart';

import '../../../../core/format/app_formats.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/contract_l10n.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../bloc/contract_filters.dart';
import 'quiet_chip.dart';

/// The filter row under the chips (DESIGN_SPEC §4 View 4 "Filter row"):
/// «النوع», «الحالة», «بها نواقص» and «الموسم», each group one choice. The
/// groups are split by a 1px divider; they wrap on a wide screen and scroll
/// sideways on a phone. «+ عقد جديد» is in the header (chosen 2026-11-15).
/// [trailing] («تصدير», chosen 2026-11-16) stays at the row's `end`.
class ContractFilterRow extends StatelessWidget {
  const ContractFilterRow({
    super.key,
    required this.filters,
    required this.seasons,
    required this.onChanged,
    this.trailing,
  });

  final ContractFilters filters;

  /// The «الموسم» choices, newest first.
  final List<int> seasons;
  final ValueChanged<ContractFilters> onChanged;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = <Widget>[
      _Group(
        label: l10n.contractFilterKindLabel,
        children: [
          for (final kind in ContractKindFilter.values)
            QuietChip(
              key: Key('contract-kind-${kind.name}'),
              label: kind.label(l10n),
              selected: filters.kind == kind,
              onTap: () => onChanged(filters.copyWith(kind: kind)),
            ),
        ],
      ),
      const _Divider(),
      _Group(
        label: l10n.contractFilterStatusLabel,
        children: [
          for (final status in ContractStatusFilter.values)
            QuietChip(
              key: Key('contract-status-${status.name}'),
              label: status.label(l10n),
              selected: filters.status == status,
              onTap: () => onChanged(filters.copyWith(status: status)),
            ),
        ],
      ),
      const _Divider(),
      QuietChip(
        key: const Key('contract-missing'),
        label: l10n.contractMissingOnly,
        selected: filters.missingOnly,
        onTap: () => onChanged(filters.copyWith(missingOnly: !filters.missingOnly)),
      ),
      const _Divider(),
      _SeasonSelect(
        season: filters.season,
        seasons: seasons,
        onChanged: (season) => onChanged(filters.copyWith(season: () => season)),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final Widget filters = constraints.maxWidth < AppSpacing.mobileBreakpoint
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsetsDirectional.only(bottom: 4),
                child: Row(spacing: 16, children: items),
              )
            : Wrap(spacing: 16, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: items);
        final end = trailing;
        if (end == null) return filters;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [Expanded(child: filters), end],
        );
      },
    );
  }
}

/// One group's chips, read by screen readers under the group's name.
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      container: true,
      child: Wrap(spacing: 8, runSpacing: 8, children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 1, height: 24, child: ColoredBox(color: context.tokens.divider));
  }
}

/// «الموسم»: a 40-high select, «كل المواسم» or a signing year. Styled like
/// a chip, and like a selected one while a year is chosen.
class _SeasonSelect extends StatelessWidget {
  const _SeasonSelect({required this.season, required this.seasons, required this.onChanged});

  final int? season;
  final List<int> seasons;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final selected = season != null;
    final fg = selected ? tokens.surface : tokens.ink;
    String label(int? year) => year == null ? l10n.contractSeasonAll : AppFormats.year(year);
    final itemStyle = AppTextStyles.body.copyWith(fontSize: 14, color: tokens.ink);

    return Semantics(
      label: l10n.contractFilterSeasonLabel,
      container: true,
      child: Container(
        height: AppSpacing.chipHeight,
        padding: const EdgeInsetsDirectional.only(start: 15, end: 8),
        decoration: BoxDecoration(
          color: selected ? tokens.ink : tokens.surface,
          border: Border.all(color: selected ? tokens.ink : tokens.chipBorder),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int?>(
            key: const Key('contract-season'),
            value: season,
            isDense: true,
            dropdownColor: tokens.surface,
            borderRadius: BorderRadius.circular(AppRadii.input),
            icon: Icon(Icons.keyboard_arrow_down, color: fg),
            style: itemStyle,
            // The closed select shows its choice in the chip's colors.
            selectedItemBuilder: (context) => [
              for (final year in [null, ...seasons])
                Center(
                  widthFactor: 1,
                  child: Text(label(year), style: itemStyle.copyWith(color: fg)),
                ),
            ],
            onChanged: onChanged,
            items: [
              for (final year in [null, ...seasons])
                DropdownMenuItem<int?>(value: year, child: Text(label(year), style: itemStyle)),
            ],
          ),
        ),
      ),
    );
  }
}
