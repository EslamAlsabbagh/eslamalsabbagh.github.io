import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/format/text_direction.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validation/name_text.dart';
import '../../../../core/validation/task_text.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../bloc/name_dialog_bloc.dart';
import '../../bloc/name_target.dart';
import '../../bloc/tasks_bloc.dart';
import '../../data/name_save_failure.dart';
import '../../data/tasks_repository.dart';
import 'confirm_dialog.dart';
import 'form_error_line.dart';
import 'form_modal.dart';

/// What the name modal closed with: the saved or deleted row's id and name.
typedef SavedName = ({String id, String name});

/// Opens the name modal for [target] and, once it saves or deletes, reloads
/// the shell's lists quietly and returns the row. A new file's chip is
/// selected after the reload; a deleted file's chip drops out with it.
Future<SavedName?> openNameDialog(BuildContext context, NameTarget target) async {
  final tasksBloc = context.read<TasksBloc>();
  final repository = context.read<TasksRepository>();
  final saved = await showDialog<SavedName>(
    context: context,
    barrierColor: context.tokens.scrim,
    barrierLabel: AppLocalizations.of(context).drawerClose,
    builder: (_) => BlocProvider(
      create: (_) => NameDialogBloc(target: target, tasksRepository: repository),
      child: const NameDialog(),
    ),
  );
  if (saved == null) return null;
  if (!tasksBloc.isClosed) tasksBloc.add(TasksRefreshRequested(selectFileId: target is NewFile ? saved.id : null));
  return saved;
}

/// Creates or renames a file or topic (spec §4 "Managing files and topics"):
/// one name field, «حفظ» and «إلغاء». A rename of an empty file or topic also
/// has «حذف الملف» / «حذف الموضوع» at the `end`, which asks first. Closes
/// with the saved or deleted [SavedName]; Esc, the scrim, × and «إلغاء» close it
/// without asking, except while saving or deleting.
class NameDialog extends StatefulWidget {
  const NameDialog({super.key});

  @override
  State<NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<NameDialog> {
  late final NameDialogBloc _bloc = context.read<NameDialogBloc>();
  late final TextEditingController _name = TextEditingController(text: _bloc.target.currentName)
    ..selection = TextSelection(baseOffset: 0, extentOffset: _bloc.target.currentName.length);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() => _bloc.add(NameSubmitted(_name.text));

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final target = _bloc.target;
    final name = target.currentName;
    final confirmed = await showConfirmDialog(
      context,
      title: target.isFile ? l10n.deleteFileTitle(name) : l10n.deleteTopicTitle(name),
      body: l10n.deleteNameBody,
      backLabel: l10n.cancelTaskBack,
      confirmLabel: l10n.deleteNameConfirm,
      keyPrefix: 'delete-name',
    );
    if (confirmed) _bloc.add(const NameDeleteRequested());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final target = _bloc.target;
    final file = target.parentFile;
    final label = target.isFile ? l10n.fileNameLabel : l10n.topicNameLabel;

    return BlocConsumer<NameDialogBloc, NameDialogState>(
      listenWhen: (previous, current) =>
          current.status == NameDialogStatus.saved || current.status == NameDialogStatus.deleted,
      listener: (context, state) => Navigator.of(context).pop((id: state.savedId!, name: state.savedName!)),
      builder: (context, state) {
        // Saving or deleting: the whole modal is inert.
        final busy = state.status != NameDialogStatus.editing;
        final saving = state.status == NameDialogStatus.saving;
        final deleting = state.status == NameDialogStatus.deleting;
        final canSave = !busy && _bloc.canSave(_name.text);
        final failure = state.failure;

        return PopScope<Object?>(
          canPop: !busy,
          child: FormModal(
            title: switch (target) {
              NewFile() => l10n.nameModalNewFile,
              RenameFile() => l10n.nameModalRenameFile,
              NewTopic() => l10n.nameModalNewTopic,
              RenameTopic() => l10n.nameModalRenameTopic,
            },
            actions: [
              FilledButton(
                key: const Key('name-save'),
                onPressed: canSave ? _submit : null,
                child: saving
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: tokens.surface),
                      )
                    : Text(l10n.editSave),
              ),
              OutlinedButton(
                key: const Key('name-cancel'),
                onPressed: busy ? null : () => Navigator.of(context).maybePop(),
                style: quietOutlineButtonStyle(context),
                child: Text(l10n.editCancel),
              ),
            ],
            endAction: target.canDelete
                ? _DeleteButton(
                    label: target.isFile ? l10n.deleteFile : l10n.deleteTopic,
                    semanticsLabel: target.isFile
                        ? l10n.deleteFileSemantics(target.currentName)
                        : l10n.deleteTopicSemantics(target.currentName),
                    deleting: deleting,
                    onPressed: busy ? null : _confirmDelete,
                  )
                : null,
            children: [
              if (file != null)
                Text(
                  l10n.nameModalFileLine(file.name),
                  key: const Key('name-file-line'),
                  style: AppTextStyles.meta.copyWith(color: tokens.textMuted),
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 6,
                children: [
                  // Screen readers get the label on the field itself.
                  ExcludeSemantics(
                    child: Text(label, style: AppTextStyles.fieldLabel.copyWith(color: tokens.textMuted)),
                  ),
                  // A delete makes the field ignore taps instead of turning it
                  // read-only. With semantics on, the autofocused field has no
                  // DOM input until someone types, and the web engine throws on
                  // a config change then (docs/notes/topics-view.md).
                  IgnorePointer(
                    ignoring: deleting,
                    child: Semantics(
                      label: label,
                      child: TextField(
                        key: const Key('name-field'),
                        controller: _name,
                        autofocus: true,
                        readOnly: saving,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _submit(),
                        textDirection: textDirectionOf(_name.text),
                        textInputAction: TextInputAction.done,
                        // Two lines, not one: a one-line field drops a pasted
                        // line break before the formatters below see it.
                        minLines: 1,
                        maxLines: 2,
                        style: AppTextStyles.body.copyWith(color: tokens.ink),
                        decoration: InputDecoration(
                          hintText: target.isFile ? l10n.fileNameHint : l10n.topicNameHint,
                        ),
                        inputFormatters: [
                          // A name is one line; a pasted line break becomes a space.
                          FilteringTextInputFormatter.deny(RegExp(r'[\r\n]+'), replacementString: ' '),
                          const CodePointLimitFormatter(NameText.max),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (failure != null)
                FormErrorLine(_message(l10n, failure, isFile: target.isFile), key: const Key('name-error')),
            ],
          ),
        );
      },
    );
  }

  static String _message(AppLocalizations l10n, NameSaveFailure failure, {required bool isFile}) =>
      switch (failure) {
        NameSaveFailure.duplicate => isFile ? l10n.nameErrorDuplicateFile : l10n.nameErrorDuplicateTopic,
        NameSaveFailure.notAllowed => l10n.nameErrorNotAllowed,
        NameSaveFailure.notEmpty => isFile ? l10n.nameErrorFileNotEmpty : l10n.nameErrorTopicNotEmpty,
        NameSaveFailure.network => l10n.loginErrorNetwork,
        NameSaveFailure.unknown => l10n.nameErrorUnknown,
      };
}

/// «حذف الملف» / «حذف الموضوع»: the quiet outline of the drawer's «إلغاء
/// المهمة», read as one button named after the file or topic. A spinner
/// replaces the label while deleting.
class _DeleteButton extends StatelessWidget {
  const _DeleteButton({
    required this.label,
    required this.semanticsLabel,
    required this.deleting,
    required this.onPressed,
  });

  final String label;
  final String semanticsLabel;
  final bool deleting;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: onPressed,
      child: OutlinedButton(
        key: const Key('name-delete'),
        onPressed: onPressed,
        style: quietOutlineButtonStyle(context),
        child: deleting
            ? SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: tokens.ink),
              )
            : Text(label),
      ),
    );
  }
}
