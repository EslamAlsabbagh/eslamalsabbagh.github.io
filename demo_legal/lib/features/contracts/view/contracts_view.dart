import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/app_formats.dart';
import '../../../core/format/arabic_count.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/contract_l10n.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../tasks/bloc/tasks_bloc.dart';
import '../../tasks/view/widgets/confirm_dialog.dart';
import '../../tasks/view/widgets/empty_section.dart';
import '../../tasks/view/widgets/expand_toggle.dart';
import '../../tasks/view/widgets/file_section_header.dart';
import '../bloc/contract_export_bloc.dart';
import '../bloc/contracts_bloc.dart';
import '../data/contract_list_item.dart';
import 'contract_drawer.dart';
import 'widgets/contract_export_menu.dart';
import 'widgets/contract_filter_row.dart';
import 'widgets/contract_row.dart';

/// View 4, «العقود» (DESIGN_SPEC §4 "View 4 — العقود"): the filter row, then
/// a section per file with one row per main contract, narrowed by the file
/// chip, the search (on the chip row, in [TasksHome]) and the filters. A
/// row opens the contract drawer. «+ عقد جديد» is in the header on this tab
/// (`openNewContract`, chosen 2026-11-15). «تصدير» at the filter row's end
/// exports or prints what the list shows (chosen 2026-11-16).
class ContractsView extends StatelessWidget {
  const ContractsView({super.key, this.clock = DateTime.now});

  /// "Now" for the drawer.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksBloc>().state;
    final state = context.watch<ContractsBloc>().state;
    final bloc = context.read<ContractsBloc>();
    final fileId = tasks.selectedFileId;

    final Widget body;
    if (state.status == ContractsStatus.failure) {
      body = const _LoadError();
    } else if (state.status != ContractsStatus.success && state.contracts.isEmpty) {
      body = const _Loading();
    } else {
      body = _List(state: state, tasks: tasks, onOpen: (id) => showContractDrawer(context, id, clock: clock));
    }

    // The list status is on the Cairo date, so midnight reads it again.
    return BlocListener<TasksBloc, TasksState>(
      listenWhen: (previous, current) => previous.dayRevision != current.dayRevision,
      listener: (context, _) => bloc.add(const ContractsRefreshRequested()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: [
          ContractFilterRow(
            filters: state.filters,
            seasons: state.seasons(fileId),
            onChanged: (filters) => bloc.add(ContractsFiltersChanged(filters)),
            trailing: ContractExportMenu(onSelected: _export(context, state, tasks)),
          ),
          body,
        ],
      ),
    );
  }

  /// Exports the sections the list shows, or null (disabled) while it
  /// loads or shows none.
  ValueChanged<ContractExportFormat>? _export(BuildContext context, ContractsState state, TasksState tasks) {
    if (state.status != ContractsStatus.success) return null;
    final fileId = tasks.selectedFileId;
    final groups = state.groups(tasks.files, fileId);
    if (groups.isEmpty) return null;
    return (format) {
      final l10n = AppLocalizations.of(context);
      final file = fileId == null
          ? l10n.allFiles
          : tasks.files.where((f) => f.id == fileId).map((f) => f.name).firstOrNull ?? l10n.allFiles;
      final today = clock();
      final date = '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-'
          '${today.day.toString().padLeft(2, '0')}';
      context.read<ContractExportBloc>().add(ContractExportRequested(
            format: format,
            groups: groups,
            labels: registerLabels(l10n),
            // Characters Windows refuses in a file name.
            fileName: l10n.contractExportFileName(file, date).replaceAll(RegExp(r'[\\/:*?"<>|]'), ' ').trim(),
          ));
    };
  }
}

/// The sections, or the one empty box that says why there are none.
class _List extends StatelessWidget {
  const _List({required this.state, required this.tasks, required this.onOpen});

  final ContractsState state;
  final TasksState tasks;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final fileId = tasks.selectedFileId;

    if (state.fileScoped(fileId).isEmpty) {
      return EmptySection(
        fileId == null ? l10n.contractsEmpty : l10n.contractsEmptyFile,
        key: const Key('contracts-empty'),
      );
    }
    if (state.searchFoundNothing(fileId)) {
      return EmptySection(l10n.contractsNoSearchMatches(state.searchedTerm), key: const Key('contracts-search-empty'));
    }
    final groups = state.groups(tasks.files, fileId);
    if (groups.isEmpty) return const _NoFilterMatches();

    final brands = {for (final topic in tasks.topics) topic.id: topic.name};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 32,
      children: [
        for (final group in groups)
          _FileSection(
            key: Key('contracts-file-${group.file.id}'),
            group: group,
            brands: brands,
            terminatedOpen: state.openTerminated.contains(group.file.id),
            onOpen: onOpen,
          ),
      ],
    );
  }
}

/// The file's title and summary over a 2px ink line, its contracts, then
/// the collapsed «الملغاة» toggle.
class _FileSection extends StatelessWidget {
  const _FileSection({
    super.key,
    required this.group,
    required this.brands,
    required this.terminatedOpen,
    required this.onOpen,
  });

  final FileContracts group;
  final Map<String, String> brands;
  final bool terminatedOpen;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final terminated = group.terminated;
    Widget rows(List<ContractListItem> items) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.rowGap,
          children: [
            for (final item in items)
              ContractRow(
                key: ValueKey(item.id),
                contract: item,
                brand: brands[item.topicId],
                onTap: () => onOpen(item.id),
              ),
          ],
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        FileSectionHeader(title: group.file.name, caption: _summary(l10n, group)),
        if (group.current.isNotEmpty) rows(group.current),
        if (terminated.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ExpandToggle(
              buttonKey: Key('terminated-toggle-${group.file.id}'),
              expanded: terminatedOpen,
              label: terminatedOpen
                  ? l10n.hideTerminated(AppFormats.number(terminated.length))
                  : l10n.showTerminated(AppFormats.number(terminated.length)),
              onPressed: () => context.read<ContractsBloc>().add(ContractsTerminatedToggled(group.file.id)),
            ),
          ),
        if (terminated.isNotEmpty && terminatedOpen) rows(terminated),
      ],
    );
  }

  /// «٣ عقود · ١ تنتهي خلال ٩٠ يومًا · ٢ بها نواقص», over the contracts
  /// outside the toggle; the zero parts are left out (null when all are).
  static String? _summary(AppLocalizations l10n, FileContracts group) {
    final count = group.current.length;
    final parts = [
      if (count > 0)
        arabicCount(
          count,
          one: l10n.contractCountOne,
          two: l10n.contractCountTwo,
          few: l10n.contractCountFew,
          many: l10n.contractCountMany,
        ),
      if (group.endingCount > 0) l10n.contractsEndingLabel(AppFormats.number(group.endingCount)),
      if (group.missingCount > 0) l10n.contractsMissingLabel(AppFormats.number(group.missingCount)),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// «لا توجد عقود تطابق هذه الاختيارات» and a quiet «مسح الاختيارات».
class _NoFilterMatches extends StatelessWidget {
  const _NoFilterMatches();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const Key('contracts-filter-empty'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        EmptySection(l10n.contractsNoFilterMatches),
        Center(
          child: OutlinedButton(
            key: const Key('contracts-clear-filters'),
            onPressed: () => context.read<ContractsBloc>().add(const ContractsFiltersChanged(ContractFilters())),
            style: quietOutlineButtonStyle(context),
            child: Text(l10n.contractsClearFilters),
          ),
        ),
      ],
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 16),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: context.tokens.accent),
        ),
      ),
    );
  }
}

/// «تعذّر تحميل العقود.» in the error line's style, and a retry button.
class _LoadError extends StatelessWidget {
  const _LoadError();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return Column(
      spacing: 12,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 6,
          children: [
            Icon(Icons.error_outline, size: 18, color: tokens.overdue),
            Flexible(
              child: Text(l10n.contractsLoadError, style: AppTextStyles.fieldLabel.copyWith(color: tokens.overdue)),
            ),
          ],
        ),
        OutlinedButton(
          key: const Key('contracts-retry'),
          onPressed: () => context.read<ContractsBloc>().add(const ContractsLoadRequested()),
          style: quietOutlineButtonStyle(context),
          child: Text(l10n.retry),
        ),
      ],
    );
  }
}
