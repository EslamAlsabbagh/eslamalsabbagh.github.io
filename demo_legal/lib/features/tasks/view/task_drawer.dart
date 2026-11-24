import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/task_status.dart';
import '../../../core/format/text_direction.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/contract_l10n.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../contracts/bloc/contracts_bloc.dart';
import '../../contracts/view/contract_drawer.dart';
import '../bloc/task_details_bloc.dart';
import '../bloc/tasks_bloc.dart';
import '../data/live_changes.dart';
import '../data/task_list_item.dart';
import '../data/task_save_failure.dart';
import '../data/tasks_repository.dart';
import 'widgets/activity_history.dart';
import 'widgets/assignee_field.dart';
import 'widgets/cancel_task_button.dart';
import 'widgets/confirm_dialog.dart';
import 'widgets/drawer_frame.dart';
import 'widgets/due_date_field.dart';
import 'widgets/status_buttons.dart';
import 'widgets/status_pill.dart';
import 'widgets/task_flag.dart';
import 'widgets/task_text_editor.dart';
import 'widgets/update_composer.dart';
import 'widgets/update_list.dart';
import 'widgets/urgent_box.dart';

/// Opens the task drawer (spec §4 "Task drawer") for [task].
///
/// It slides in from the `end` side (the physical left in RTL) over the
/// scrim; the scrim, Esc and the close button dismiss it. The dialog route
/// sits above the shell, so the shell's [TasksBloc] is handed in explicitly.
///
/// A follow-up's drawer links to its contract. The shell's [ContractsBloc]
/// is handed in for the contract drawer only then, since reading it loads
/// the «العقود» list. [fromContractId] is the contract drawer this one was
/// opened from: its link closes this drawer instead of stacking another.
Future<void> showTaskDrawer(
  BuildContext context,
  TaskListItem task, {
  required DateTime Function() clock,
  String? fromContractId,
}) {
  final tasksBloc = context.read<TasksBloc>();
  final contractsBloc = task.contractId == null ? null : context.read<ContractsBloc>();
  final repository = context.read<TasksRepository>();
  final liveChanges = context.read<LiveChanges>();
  final viewer = context.read<AuthBloc>().state.profile!;

  return showSideDrawer<void>(
    context,
    builder: (context) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: tasksBloc),
        if (contractsBloc != null) BlocProvider.value(value: contractsBloc),
        BlocProvider(
          create: (_) => TaskDetailsBloc(
            task: task,
            viewer: viewer,
            tasksRepository: repository,
            liveChanges: liveChanges.changes,
          )..add(const TaskDetailsLoadRequested()),
        ),
      ],
      child: TaskDrawer(clock: clock, fromContractId: fromContractId, canOpenContract: contractsBloc != null),
    ),
  );
}

/// The drawer panel. Needs a [TaskDetailsBloc] and the shell's [TasksBloc]
/// (and its [ContractsBloc] when [canOpenContract]).
///
/// Closing it (×, the scrim, Esc) asks first while the edit form or the
/// update box holds unsaved text, with one dialog for both.
class TaskDrawer extends StatefulWidget {
  const TaskDrawer({super.key, required this.clock, this.fromContractId, this.canOpenContract = false});

  /// "Now" for the update times.
  final DateTime Function() clock;

  /// The contract drawer under this one, if it was opened from there.
  final String? fromContractId;

  /// Whether «العقد» may open the contract drawer: the [ContractsBloc] is
  /// provided.
  final bool canOpenContract;

  @override
  State<TaskDrawer> createState() => _TaskDrawerState();
}

class _TaskDrawerState extends State<TaskDrawer> {
  // Read only when closing, so the reports need no rebuild (they can arrive
  // while the drawer builds, e.g. when the update box clears).
  bool _editDirty = false;
  bool _updateDirty = false;

  Future<bool> _confirmDiscard() {
    final l10n = AppLocalizations.of(context);
    final (title, body, back) = switch ((_editDirty, _updateDirty)) {
      (true, true) => (l10n.discardAllTitle, l10n.discardAllBody, l10n.discardUpdateBack),
      (true, false) => (l10n.discardEditTitle, l10n.discardEditBody, l10n.discardEditBack),
      _ => (l10n.discardUpdateTitle, l10n.discardUpdateBody, l10n.discardUpdateBack),
    };
    return showConfirmDialog(
      context,
      title: title,
      body: body,
      backLabel: back,
      confirmLabel: l10n.discardEditConfirm,
      keyPrefix: 'discard-edit',
    );
  }

  /// «العقد»: back to the contract drawer this one was opened from (asking
  /// first, as the ×), or else that contract's drawer over this one. Null
  /// when neither is possible.
  VoidCallback? get _openContract {
    final contractId = context.read<TaskDetailsBloc>().state.item.contractId;
    if (contractId == null) return null;
    if (contractId == widget.fromContractId) return () => Navigator.of(context).maybePop();
    if (!widget.canOpenContract) return null;
    return () => showContractDrawer(context, contractId, clock: widget.clock);
  }

  @override
  Widget build(BuildContext context) {
    final task = context.select((TaskDetailsBloc bloc) => bloc.state.item);

    // Never pops by itself: the ×, the scrim and Esc all go through maybePop,
    // which lands here, and the drawer pops once nothing typed would be lost.
    // `pop()` itself ignores the PopScope.
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if ((!_editDirty && !_updateDirty) || await _confirmDiscard()) navigator.pop();
      },
      child: BlocListener<TaskDetailsBloc, TaskDetailsState>(
        // Each save changes what the list, the chips and the counters show.
        listenWhen: (previous, current) => previous.savedRevision != current.savedRevision,
        listener: (context, _) => context.read<TasksBloc>().add(const TasksRefreshRequested()),
        child: DrawerFrame(
          panelKey: const Key('task-drawer'),
          title: '${task.fileName} / ${task.topicName}',
          child: _Body(
            clock: widget.clock,
            onOpenContract: _openContract,
            onEditDirtyChanged: (dirty) => _editDirty = dirty,
            onUpdateDirtyChanged: (dirty) => _updateDirty = dirty,
          ),
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.clock,
    required this.onOpenContract,
    required this.onEditDirtyChanged,
    required this.onUpdateDirtyChanged,
  });

  final DateTime Function() clock;
  final VoidCallback? onOpenContract;
  final ValueChanged<bool> onEditDirtyChanged;
  final ValueChanged<bool> onUpdateDirtyChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<TaskDetailsBloc>();
    final state = context.watch<TaskDetailsBloc>().state;
    final task = state.item;
    final details = state.details;
    final failure = state.failure;
    // Read-only viewers see the controls dimmed; a save in flight only
    // blocks input, so the drawer doesn't flicker.
    final enabled = state.canSave;
    final dimmed = !state.canEdit;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.drawerGap,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 10,
          children: [
            if (task.isUrgentNow) TaskFlag(overdue: task.isOverdue, verticalPadding: 2),
            if (task.status == TaskStatus.cancelled) StatusPill(task.status),
            if (state.editingText && state.canEdit)
              // What the form opened with, not the latest copy: a live
              // re-read mustn't make untouched text look edited.
              TaskTextEditor(
                title: state.editBaseTitle,
                description: state.editBaseDescription,
                onSave: enabled
                    ? (title, description) =>
                        bloc.add(TaskDetailsTextSaved(title: title, description: description))
                    : null,
                onCancel: () => bloc.add(const TaskDetailsEditCancelled()),
                onDirtyChanged: onEditDirtyChanged,
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        task.title,
                        textDirection: textDirectionOf(task.title),
                        style: AppTextStyles.drawerTitle.copyWith(color: tokens.ink),
                      ),
                    ),
                  ),
                  // Hidden, not dimmed, for a lawyer on someone else's task.
                  if (state.canEdit)
                    _EditButton(onPressed: enabled ? () => bloc.add(const TaskDetailsEditStarted()) : null),
                ],
              ),
          ],
        ),
        if (failure != null) _ErrorLine(_saveMessage(l10n, failure)),
        _Labeled(
          label: l10n.drawerStatusLabel,
          gap: 8,
          child: StatusButtons(
            selected: task.status,
            dimmed: dimmed,
            onPicked: enabled ? (status) => bloc.add(TaskDetailsStatusPicked(status)) : null,
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final assignee = _Labeled(
              label: l10n.drawerAssigneeLabel,
              child: AssigneeField(
                assigneeId: task.assigneeId,
                assigneeName: task.assigneeName,
                options: state.canReassign ? state.assignees : null,
                dimmed: dimmed || !state.canReassign,
                onPicked: enabled && state.canReassign
                    ? (id) => bloc.add(TaskDetailsAssigneePicked(id))
                    : null,
              ),
            );
            final due = _Labeled(
              label: l10n.drawerDueLabel,
              child: DueDateField(
                task: task,
                dimmed: dimmed,
                onPicked: enabled ? (date) => bloc.add(TaskDetailsDuePicked(date)) : null,
              ),
            );
            // The canvas grid: two columns of at least 200 with a 14 gap.
            if (constraints.maxWidth < 2 * 200 + 14) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [assignee, due],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 14,
              children: [Expanded(child: assignee), Expanded(child: due)],
            );
          },
        ),
        UrgentBox(
          task: task,
          isManualUrgent: details?.isManualUrgent ?? false,
          dimmed: dimmed,
          onChanged: enabled ? (value) => bloc.add(TaskDetailsUrgentToggled(value)) : null,
        ),
        // A follow-up's contract (chosen 2026-11-15): live for everyone who
        // sees the task, since the contract is in the same file.
        if (details?.contract case final contract? when task.contractId != null)
          _Labeled(
            label: l10n.drawerContractLabel,
            child: _ContractLink(
              name: contractName(l10n, kind: contract.kind, subject: contract.subject),
              onPressed: onOpenContract,
            ),
          ),
        ...switch (state.load) {
          TaskDetailsLoad.failure => [const _LoadError()],
          TaskDetailsLoad.loading when details == null => [const _Loading()],
          _ => [
              // While editing, the description is a field in the form above.
              if (!state.editingText && details != null && details.description.trim().isNotEmpty)
                _Labeled(
                  label: l10n.drawerDescriptionLabel,
                  header: true,
                  child: Text(
                    details.description,
                    textDirection: textDirectionOf(details.description),
                    style: AppTextStyles.body.copyWith(height: 1.8, color: tokens.ink),
                  ),
                ),
              _Labeled(
                label: l10n.drawerUpdatesLabel,
                header: true,
                gap: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 14,
                  children: [
                    // Live for everyone who sees the task, open or closed
                    // (ADR-0003), even when the rest is faded.
                    UpdateComposer(
                      onPost: state.canPost ? (body) => bloc.add(TaskDetailsUpdatePosted(body)) : null,
                      postedRevision: state.postedRevision,
                      onDirtyChanged: onUpdateDirtyChanged,
                      errorMessage: switch (state.postFailure) {
                        null => null,
                        TaskSaveFailure.notAllowed => l10n.updateErrorNotAllowed,
                        TaskSaveFailure.network => l10n.loginErrorNetwork,
                        _ => l10n.updateErrorUnknown,
                      },
                    ),
                    UpdateList(updates: state.updates, now: clock()),
                  ],
                ),
              ),
              ActivityHistory(entries: state.activity, now: clock()),
            ],
        },
        if (state.canEdit && task.isOpen)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CancelTaskButton(
              onConfirmed: enabled ? () => bloc.add(const TaskDetailsCancelConfirmed()) : null,
            ),
          ),
      ],
    );
  }

  static String _saveMessage(AppLocalizations l10n, TaskSaveFailure failure) => switch (failure) {
        TaskSaveFailure.notAllowed => l10n.saveErrorNotAllowed,
        TaskSaveFailure.assigneeRejected => l10n.saveErrorAssignee,
        TaskSaveFailure.network => l10n.loginErrorNetwork,
        TaskSaveFailure.unknown => l10n.saveErrorUnknown,
      };
}

/// A 13 / 600 muted label above its content (the canvas's `<label>`,
/// `<legend>` and `<h3>`).
class _Labeled extends StatelessWidget {
  const _Labeled({required this.label, required this.child, this.gap = 6, this.header = false});

  final String label;
  final Widget child;
  final double gap;
  final bool header;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: gap,
      children: [
        Semantics(
          header: header,
          child: Text(label, style: AppTextStyles.fieldLabel.copyWith(color: context.tokens.textMuted)),
        ),
        child,
      ],
    );
  }
}

/// Error icon and 13 / 600 text in `overdue`, as on the login card.
class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = context.tokens.overdue;
    return Semantics(
      liveRegion: true,
      child: Row(
        key: const Key('drawer-error'),
        spacing: 6,
        children: [
          Icon(Icons.error_outline, size: 18, color: color),
          Expanded(child: Text(message, style: AppTextStyles.fieldLabel.copyWith(color: color))),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: context.tokens.accent),
      ),
    );
  }
}

/// The description and updates couldn't be loaded: message and retry.
class _LoadError extends StatelessWidget {
  const _LoadError();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: [
        _ErrorLine(l10n.drawerLoadError),
        OutlinedButton(
          key: const Key('drawer-retry'),
          onPressed: () => context.read<TaskDetailsBloc>().add(const TaskDetailsLoadRequested()),
          style: quietOutlineButtonStyle(context),
          child: Text(l10n.retry),
        ),
      ],
    );
  }
}

/// The follow-up's contract: its name (15, `ink`, in its own direction) and
/// a chevron toward `end`, as one quiet button at the `start`. Null
/// [onPressed] shows the name only.
class _ContractLink extends StatelessWidget {
  const _ContractLink({required this.name, required this.onPressed});

  final String name;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final style = AppTextStyles.body.copyWith(color: tokens.ink);
    final text = Text(name, textDirection: textDirectionOf(name), style: style);
    if (onPressed == null) return Align(alignment: AlignmentDirectional.centerStart, child: text);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton(
        key: const Key('task-contract-link'),
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: tokens.ink,
          textStyle: style,
          minimumSize: const Size(0, AppSpacing.touchTarget),
          padding: const EdgeInsetsDirectional.only(start: 8, end: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Flexible(child: text),
            Icon(Icons.chevron_right, size: 20, color: tokens.textMuted),
          ],
        ),
      ),
    );
  }
}

/// «تعديل» beside the title (not in the canvas): a quiet pencil-and-word
/// button with a 44px target. Null [onPressed] = inert (loading or saving).
class _EditButton extends StatelessWidget {
  const _EditButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return TextButton.icon(
      key: const Key('edit-task-text'),
      onPressed: onPressed,
      icon: const Icon(Icons.edit_outlined, size: 18),
      label: Text(AppLocalizations.of(context).editTask),
      style: TextButton.styleFrom(
        foregroundColor: tokens.ink,
        disabledForegroundColor: tokens.textMuted,
        textStyle: AppTextStyles.button,
        minimumSize: const Size(0, AppSpacing.touchTarget),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
      ),
    );
  }
}
