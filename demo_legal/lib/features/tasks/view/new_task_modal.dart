import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/text_direction.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/task_text.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/name_target.dart';
import '../bloc/new_task_bloc.dart';
import '../bloc/tasks_bloc.dart';
import '../data/task_file.dart';
import '../data/task_save_failure.dart';
import '../data/task_topic.dart';
import '../data/tasks_repository.dart';
import 'widgets/confirm_dialog.dart';
import 'widgets/date_field_box.dart';
import 'widgets/field_box.dart';
import 'widgets/form_error_line.dart';
import 'widgets/form_modal.dart';
import 'widgets/labeled_field.dart';
import 'widgets/name_dialog.dart';
import 'widgets/select_box.dart';
import 'widgets/urgent_checkbox.dart';

/// Opens the new-task modal from the shell's loaded lists and, once it
/// saves, shows the new task (tasks tab, its file, no search) and reloads.
/// The shell's [TasksBloc] goes along for «+ موضوع جديد», whose name modal
/// reloads the lists after a save.
///
/// With a [preset] (a contract's follow-up, from the contract drawer) the
/// shell stays where it is: the lists only reload. Returns the new task's
/// id, or null when nothing was saved.
Future<String?> openNewTaskModal(
  BuildContext context, {
  required DateTime Function() clock,
  NewTaskPreset? preset,
}) async {
  final tasksBloc = context.read<TasksBloc>();
  final repository = context.read<TasksRepository>();
  final viewer = context.read<AuthBloc>().state.profile!;
  final tasks = tasksBloc.state;
  final saved = await showDialog<(String, String)>(
    context: context,
    barrierColor: context.tokens.scrim,
    barrierLabel: AppLocalizations.of(context).drawerClose,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: tasksBloc),
        BlocProvider(
          create: (_) => NewTaskBloc(
            files: tasks.files,
            topics: tasks.topics,
            team: tasks.team,
            viewer: viewer,
            initialFileId: tasks.selectedFileId,
            today: tasks.cairoToday(clock()),
            tasksRepository: repository,
            preset: preset,
          ),
        ),
      ],
      child: const NewTaskModal(),
    ),
  );
  if (saved == null) return null;
  final (fileId, id) = saved;
  if (!tasksBloc.isClosed) tasksBloc.add(preset == null ? TasksTaskCreated(fileId) : const TasksRefreshRequested());
  return id;
}

/// «مهمة جديدة» (spec §4 "New task modal"): title, file, topic, assignee, due
/// date, urgent flag and description, then «حفظ المهمة» / «إلغاء». Closes
/// with the new task's file id and id. Leaving with something typed or picked asks
/// first; nothing closes it while saving.
class NewTaskModal extends StatefulWidget {
  const NewTaskModal({super.key});

  /// Below this the four selects stack in one column (the canvas's
  /// `minmax(220px, 1fr)` cells with a 14px gap).
  static const double twoColumnWidth = 220 * 2 + 14;

  @override
  State<NewTaskModal> createState() => _NewTaskModalState();
}

class _NewTaskModalState extends State<NewTaskModal> {
  late final NewTaskBloc _bloc = context.read<NewTaskBloc>();
  late final _title = TextEditingController(text: _bloc.initialTitle);
  final _description = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() => _bloc.add(NewTaskSubmitted(title: _title.text, description: _description.text));

  /// «+ موضوع جديد»: the «المواضيع» name modal over this one; a saved topic
  /// is picked.
  Future<void> _addTopic(TaskFile file) async {
    final saved = await openNameDialog(context, NewTopic(file));
    if (saved == null || !mounted) return;
    _bloc.add(NewTaskTopicAdded(TaskTopic(id: saved.id, fileId: file.id, name: saved.name)));
  }

  Future<void> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final discard = await showConfirmDialog(
      context,
      title: l10n.discardEditTitle,
      body: l10n.newTaskDiscardBody,
      backLabel: l10n.discardEditBack,
      confirmLabel: l10n.discardEditConfirm,
      keyPrefix: 'new-task-discard',
    );
    if (discard && mounted) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final textStyle = AppTextStyles.body.copyWith(color: tokens.ink);

    return BlocConsumer<NewTaskBloc, NewTaskState>(
      listenWhen: (previous, current) => current.status == NewTaskStatus.saved,
      listener: (context, state) => Navigator.of(context).pop((state.draft.fileId!, state.savedId!)),
      builder: (context, state) {
        final busy = state.busy;
        final draft = state.draft;
        final dirty = _bloc.isDirty(_title.text, _description.text);
        final canSave = _bloc.canSave(_title.text, _description.text);
        final failure = state.failure;
        final muted = AppTextStyles.body.copyWith(color: tokens.textMuted);

        final preset = _bloc.preset;
        Widget fixed(String keyName, String text) => FieldBox(
              child: Text(
                text,
                key: Key(keyName),
                textDirection: textDirectionOf(text),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            );
        final file = LabeledField(
          label: l10n.newTaskFileLabel,
          child: preset != null
              ? fixed('new-task-fixed-file', _bloc.files.where((f) => f.id == preset.fileId).firstOrNull?.name ?? '')
              : _bloc.files.isEmpty
              ? FieldBox(child: Text(l10n.userFilesNone, key: const Key('new-task-no-files'), style: muted))
              : SelectBox(
                  selectKey: const Key('new-task-file'),
                  value: draft.fileId,
                  items: {for (final f in _bloc.files) f.id: f.name},
                  onChanged: busy ? null : (id) => _bloc.add(NewTaskFileChanged(id)),
                ),
        );
        final topics = _bloc.fileTopics;
        final selectedFile = _bloc.files.where((f) => f.id == draft.fileId).firstOrNull;
        final addTopic = selectedFile == null || busy ? null : () => _addTopic(selectedFile);
        final topic = LabeledField(
          label: l10n.newTaskTopicLabel,
          child: preset != null
              ? fixed('new-task-fixed-topic', _bloc.topics.where((t) => t.id == preset.topicId).firstOrNull?.name ?? '')
              : selectedFile == null
              ? FieldBox(dimmed: true, child: Text('', key: const Key('new-task-no-topics'), style: muted))
              : topics.isEmpty
                  // A file with no topics: the box itself adds one.
                  ? FieldBox(
                      key: const Key('new-task-add-topic'),
                      onTap: addTopic,
                      child: _NewTopicLabel(fileName: selectedFile.name),
                    )
                  : SelectBox(
                      selectKey: const Key('new-task-topic'),
                      value: draft.topicId,
                      items: {for (final t in topics) t.id: t.name},
                      onChanged: busy ? null : (id) => _bloc.add(NewTaskTopicChanged(id)),
                      action: _NewTopicLabel(fileName: selectedFile.name),
                      onAction: addTopic,
                    ),
        );
        final assignee = LabeledField(
          label: l10n.drawerAssigneeLabel,
          child: _bloc.assignsSelf
              ? FieldBox(
                  child: Text(
                    _bloc.viewer.displayName,
                    key: const Key('new-task-self'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                )
              : SelectBox(
                  selectKey: const Key('new-task-assignee'),
                  value: draft.assigneeId,
                  hint: l10n.newTaskAssigneeHint,
                  items: {for (final o in _bloc.assigneeOptions) o.id: o.name ?? l10n.formerEmployee},
                  onChanged: busy ? null : (id) => _bloc.add(NewTaskAssigneeChanged(id)),
                ),
        );
        final contract = preset == null
            ? null
            : LabeledField(label: l10n.newTaskContractLabel, child: fixed('new-task-fixed-contract', preset.contractLabel));
        final due = LabeledField(
          label: l10n.drawerDueLabel,
          // The box names itself («اختيار موعد التسليم»), as in the drawer.
          semantics: FieldLabelSemantics.hidden,
          child: DateFieldBox(
            date: draft.dueDate,
            onPicked: busy ? null : (date) => _bloc.add(NewTaskDueChanged(date)),
          ),
        );

        return PopScope<Object?>(
          canPop: !busy && !dirty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !busy) _confirmDiscard();
          },
          child: FormModal(
            title: l10n.newTask,
            actions: [
              FilledButton(
                key: const Key('new-task-save'),
                onPressed: canSave ? _submit : null,
                child: state.status == NewTaskStatus.editing
                    ? Text(l10n.newTaskSave)
                    : SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: tokens.surface),
                      ),
              ),
              OutlinedButton(
                key: const Key('new-task-cancel'),
                onPressed: busy ? null : () => Navigator.of(context).maybePop(),
                style: quietOutlineButtonStyle(context),
                child: Text(l10n.editCancel),
              ),
            ],
            children: [
              LabeledField(
                label: l10n.editTitleLabel,
                child: TextField(
                  key: const Key('new-task-title'),
                  controller: _title,
                  autofocus: true,
                  readOnly: busy,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  textDirection: textDirectionOf(_title.text),
                  textInputAction: TextInputAction.done,
                  // Wraps like the drawer's title field; a one-line field
                  // would drop a pasted line break before the formatter.
                  minLines: 1,
                  maxLines: 3,
                  style: textStyle,
                  decoration: InputDecoration(hintText: l10n.newTaskTitleHint),
                  inputFormatters: [
                    // A title is one line; a pasted line break becomes a space.
                    FilteringTextInputFormatter.deny(RegExp(r'[\r\n]+'), replacementString: ' '),
                    const CodePointLimitFormatter(TaskText.titleMax),
                  ],
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth < NewTaskModal.twoColumnWidth) {
                    return Column(
                      key: const Key('new-task-grid-1'),
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: AppSpacing.formGap,
                      children: [file, topic, ?contract, assignee, due],
                    );
                  }
                  Widget pair(Widget a, Widget b) => Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 14,
                        children: [Expanded(child: a), Expanded(child: b)],
                      );
                  return Column(
                    key: const Key('new-task-grid-2'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 14,
                    children: [pair(file, topic), ?contract, pair(assignee, due)],
                  );
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  UrgentCheckbox(
                    key: const Key('new-task-urgent'),
                    label: l10n.newTaskUrgent,
                    value: draft.isManualUrgent,
                    onChanged: busy ? null : (value) => _bloc.add(NewTaskUrgentChanged(value)),
                  ),
                  Text(l10n.newTaskUrgentHelp, style: AppTextStyles.meta.copyWith(color: tokens.textMuted)),
                ],
              ),
              LabeledField(
                label: l10n.drawerDescriptionLabel,
                child: TextField(
                  key: const Key('new-task-description'),
                  controller: _description,
                  readOnly: busy,
                  onChanged: (_) => setState(() {}),
                  textDirection: textDirectionOf(_description.text),
                  keyboardType: TextInputType.multiline,
                  minLines: 4,
                  maxLines: null,
                  style: textStyle,
                  inputFormatters: const [CodePointLimitFormatter(TaskText.descriptionMax)],
                ),
              ),
              if (failure != null)
                FormErrorLine(_message(l10n, failure, assignsSelf: _bloc.assignsSelf), key: const Key('new-task-error')),
            ],
          ),
        );
      },
    );
  }

  /// A lawyer is always their own assignee, so the assignee guard refusing
  /// them means they are no longer a member of the file: not allowed.
  static String _message(AppLocalizations l10n, TaskSaveFailure failure, {required bool assignsSelf}) =>
      switch (failure) {
        TaskSaveFailure.notAllowed => l10n.newTaskErrorNotAllowed,
        TaskSaveFailure.assigneeRejected when assignsSelf => l10n.newTaskErrorNotAllowed,
        TaskSaveFailure.assigneeRejected => l10n.saveErrorAssignee,
        TaskSaveFailure.network => l10n.loginErrorNetwork,
        TaskSaveFailure.unknown => l10n.newTaskErrorUnknown,
      };
}

/// «+ موضوع جديد» in the topic select (its last menu entry, or the whole
/// box for a file with no topics), read as «إضافة موضوع إلى الممشى».
class _NewTopicLabel extends StatelessWidget {
  const _NewTopicLabel({required this.fileName});

  final String fileName;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.newTopicSemantics(fileName),
      excludeSemantics: true,
      child: Row(
        spacing: 6,
        children: [
          Icon(Icons.add, size: 18, color: tokens.textMuted),
          Flexible(
            child: Text(
              l10n.newTopicCard,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(color: tokens.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
