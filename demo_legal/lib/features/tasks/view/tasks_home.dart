import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../contracts/bloc/contracts_bloc.dart';
import '../../contracts/view/contracts_view.dart';
import '../bloc/name_target.dart';
import '../bloc/tasks_bloc.dart';
import 'people_view.dart';
import 'tasks_view.dart';
import 'topics_view.dart';
import 'widgets/confirm_dialog.dart';
import 'widgets/file_chips.dart';
import 'widgets/name_dialog.dart';
import 'widgets/search_status_line.dart';
import 'widgets/task_search_field.dart';
import 'widgets/view_tabs.dart';

/// The shell's content: the view tabs, the file chips (and the search on
/// the tasks tab), then the selected view.
class TasksHome extends StatelessWidget {
  const TasksHome({super.key, this.clock = DateTime.now});

  /// "Now" for the drawer's update times; injectable for tests.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<TasksBloc>().state;
    final bloc = context.read<TasksBloc>();

    final Widget body;
    // A reload keeps showing the last views; only the first load is blank.
    if (state.status == TasksStatus.failure) {
      body = const _LoadError();
    } else if (state.status == TasksStatus.loading && state.tasks.isEmpty && state.files.isEmpty) {
      body = const _Loading();
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 20,
        children: [
          _SearchAndChips(state: state),
          switch (state.tab) {
            TasksTab.tasks => TasksView(clock: clock),
            TasksTab.topics => TopicsView(clock: clock),
            TasksTab.people => PeopleView(clock: clock),
            TasksTab.contracts => ContractsView(clock: clock),
          },
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        ViewTabs(selected: state.tab, onSelected: (tab) => bloc.add(TasksTabSelected(tab))),
        body,
      ],
    );
  }
}

/// The file chips, shared by every tab (counting open tasks, or contracts on
/// «العقود»), and at their end the search field
/// (tasks and contracts tabs) or, for managers and admins, «+ ملف جديد»
/// (topics tab): on one row when wide, on its own row above the chips on a
/// phone. Under the search, the result count or the search error. The people
/// tab has the chips alone.
class _SearchAndChips extends StatelessWidget {
  const _SearchAndChips({required this.state});

  final TasksState state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TasksBloc>();
    if (state.tab == TasksTab.contracts) return _ContractsSearch(tasks: state);
    final chips = FileChips(
      files: state.files,
      selectedFileId: state.selectedFileId,
      countFor: state.openCountFor,
      onSelected: (id) => bloc.add(TasksFileSelected(id)),
    );
    final canManage = context.select((AuthBloc bloc) => bloc.state.profile?.role.managesFiles ?? false);
    if (state.tab == TasksTab.people) return chips;
    if (state.tab == TasksTab.topics) {
      if (!canManage) return chips;
      return _ChipsRow(chips: chips, end: const _NewFileButton());
    }

    // This search belongs to «المهام والأولوية»; the query waits in the state.
    final field = TaskSearchField(
      // A new key empties it when the app clears the search (a new task).
      key: ValueKey(state.searchResets),
      initialQuery: state.searchQuery,
      onChanged: (query) => bloc.add(TasksSearchChanged(query)),
    );
    final count = state.searchResultCount;
    final failed = state.searchStatus == TasksSearchStatus.failure;
    final status = SearchStatusLine.shows(failed: failed, count: count)
        ? SearchStatusLine(failed: failed, count: count ?? 0, term: state.searchedTerm)
        : null;
    return _SearchRow(chips: chips, field: field, status: status);
  }
}

/// «العقود»'s own search, with its query in [ContractsBloc] (watching it
/// creates the bloc, so the list loads the first time the tab opens). Here
/// each chip counts the contracts the list would show for it: the filters
/// and the search apply, and terminated contracts count (chosen 2026-11-12).
/// The header counters stay about tasks.
class _ContractsSearch extends StatelessWidget {
  const _ContractsSearch({required this.tasks});

  final TasksState tasks;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ContractsBloc>().state;
    final l10n = AppLocalizations.of(context);
    final fileId = tasks.selectedFileId;
    final chips = FileChips(
      files: tasks.files,
      selectedFileId: fileId,
      countFor: (id) => state.visible(id).length,
      onSelected: (id) => context.read<TasksBloc>().add(TasksFileSelected(id)),
    );
    final field = TaskSearchField(
      key: const ValueKey('contracts-search'),
      initialQuery: state.searchQuery,
      onChanged: (query) => context.read<ContractsBloc>().add(ContractsSearchChanged(query)),
      hint: l10n.contractsSearchHint,
      label: l10n.contractsSearchLabel,
      fieldKey: const Key('contract-search'),
      clearKey: const Key('contract-search-clear'),
    );
    final count = state.searchResultCount(fileId);
    final failed = state.searchStatus == ContractsSearchStatus.failure;
    final status = SearchStatusLine.shows(failed: failed, count: count)
        ? SearchStatusLine(failed: failed, count: count ?? 0, term: state.searchedTerm)
        : null;
    return _SearchRow(chips: chips, field: field, status: status);
  }
}

/// The chips with a search [field] at their end and [status] under it when
/// wide; on a phone the field and [status] get their own rows above the
/// chips.
class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.chips, required this.field, required this.status});

  final Widget chips;
  final Widget field;
  final Widget? status;

  static const double _fieldWidth = 300;

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppSpacing.mobileBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [field, ?status],
              ),
              chips,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Row(
              spacing: 12,
              children: [
                Expanded(child: chips),
                SizedBox(width: _fieldWidth, child: field),
              ],
            ),
            if (status != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SizedBox(width: _fieldWidth, child: status),
              ),
          ],
        );
      },
    );
  }
}

/// The chips with [end] after them when wide, or [end] full width above
/// them on a phone (the search field's places).
class _ChipsRow extends StatelessWidget {
  const _ChipsRow({required this.chips, required this.end});

  final Widget chips;
  final Widget end;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AppSpacing.mobileBreakpoint) {
          return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: [end, chips]);
        }
        return Row(spacing: 12, children: [Expanded(child: chips), end]);
      },
    );
  }
}

/// «+ ملف جديد»: a quiet outline button that opens the new-file modal.
class _NewFileButton extends StatelessWidget {
  const _NewFileButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('new-file'),
      onPressed: () => openNameDialog(context, const NewFile()),
      icon: const Icon(Icons.add, size: 18),
      label: Text(AppLocalizations.of(context).newFileButton),
      style: quietOutlineButtonStyle(context),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 40),
      child: Center(
        child: SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: context.tokens.accent),
        ),
      ),
    );
  }
}

/// Error line in the login's error style, and a retry button.
class _LoadError extends StatelessWidget {
  const _LoadError();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 24),
      child: Column(
        spacing: 12,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              Icon(Icons.error_outline, size: 18, color: tokens.overdue),
              Flexible(
                child: Text(
                  l10n.tasksLoadError,
                  style: AppTextStyles.fieldLabel.copyWith(color: tokens.overdue),
                ),
              ),
            ],
          ),
          OutlinedButton(
            key: const Key('tasks-retry'),
            onPressed: () => context.read<TasksBloc>().add(const TasksLoadRequested()),
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.ink,
              textStyle: AppTextStyles.button,
              minimumSize: const Size(0, AppSpacing.touchTarget),
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
              side: BorderSide(color: tokens.borderStrong),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
            ),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
