import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../bloc/tasks_bloc.dart';

/// The segmented control above the file chips (spec §4 "View tabs"): a
/// `segmentBg` track, the selected tab white with a subtle shadow. It hugs
/// its tabs at the start, and scrolls if they ever outgrow the screen.
class ViewTabs extends StatelessWidget {
  const ViewTabs({super.key, required this.selected, required this.onSelected});

  final TasksTab selected;
  final ValueChanged<TasksTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    String label(TasksTab tab) => switch (tab) {
          TasksTab.tasks => l10n.tabTasks,
          TasksTab.topics => l10n.tabTopics,
          TasksTab.people => l10n.tabPeople,
          TasksTab.contracts => l10n.tabContracts,
        };

    return Semantics(
      label: l10n.viewTabsLabel,
      container: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.segmentBg,
              borderRadius: BorderRadius.circular(AppRadii.tabTrack),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  for (final tab in TasksTab.values)
                    _Tab(
                      key: Key('view-tab-${tab.name}'),
                      label: label(tab),
                      selected: tab == selected,
                      onTap: () => onSelected(tab),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = BorderRadius.circular(AppRadii.tab);

    return Semantics(
      button: true,
      selected: selected,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: selected
              ? [BoxShadow(color: tokens.tabShadow, offset: const Offset(0, 1), blurRadius: 2)]
              : null,
        ),
        child: Material(
          color: tokens.surface.withValues(alpha: selected ? 1 : 0),
          borderRadius: radius,
          child: InkWell(
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSpacing.chipHeight),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    label,
                    style: AppTextStyles.button.copyWith(
                      color: selected ? tokens.ink : tokens.textSoft,
                    ),
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
