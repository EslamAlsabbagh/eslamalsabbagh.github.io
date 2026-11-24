import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/format/text_direction.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validation/task_text.dart';
import '../../../../l10n/gen/app_localizations.dart';
import 'confirm_dialog.dart';
import 'labeled_field.dart';

/// The drawer's edit form for the title and description (not in the canvas,
/// chosen 2026-10-15): two fields, «حفظ» and «إلغاء».
///
/// While the text differs from what was opened, closing the drawer (×, the
/// scrim, Esc outside the fields) asks first: the form reports it through
/// [onDirtyChanged], and the drawer asks. Esc inside a field is «إلغاء»,
/// asking first too when something was typed.
class TaskTextEditor extends StatefulWidget {
  const TaskTextEditor({
    super.key,
    required this.title,
    required this.description,
    required this.onSave,
    required this.onCancel,
    required this.onDirtyChanged,
  });

  /// The saved text the form opens with.
  final String title;
  final String description;

  /// Null while a save is in flight.
  final void Function(String title, String description)? onSave;
  final VoidCallback onCancel;

  /// Whether the text differs from what was opened. Only reports changes;
  /// never calls `setState` on the caller.
  final ValueChanged<bool> onDirtyChanged;

  @override
  State<TaskTextEditor> createState() => _TaskTextEditorState();
}

class _TaskTextEditorState extends State<TaskTextEditor> {
  late final TextEditingController _title = TextEditingController(text: widget.title);
  late final TextEditingController _description = TextEditingController(text: widget.description);
  bool _reportedDirty = false;

  @override
  void dispose() {
    if (_reportedDirty) widget.onDirtyChanged(false);
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Anything typed counts, even spaces the save would trim away.
  bool get _dirty => _title.text != widget.title || _description.text != widget.description;

  void _changed() {
    setState(() {});
    if (_dirty == _reportedDirty) return;
    _reportedDirty = _dirty;
    widget.onDirtyChanged(_dirty);
  }

  bool get _canSubmit =>
      widget.onSave != null &&
      _dirty &&
      TaskText.isValidTitle(_title.text) &&
      TaskText.isValidDescription(_description.text);

  void _submit() {
    if (_canSubmit) widget.onSave!(_title.text, _description.text);
  }

  Future<bool> _confirmDiscard() {
    final l10n = AppLocalizations.of(context);
    return showConfirmDialog(
      context,
      title: l10n.discardEditTitle,
      body: l10n.discardEditBody,
      backLabel: l10n.discardEditBack,
      confirmLabel: l10n.discardEditConfirm,
      keyPrefix: 'discard-edit',
    );
  }

  Future<void> _escape() async {
    if (!_dirty || await _confirmDiscard()) widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final textStyle = AppTextStyles.body.copyWith(color: tokens.ink);

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _escape},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          LabeledField(
            label: l10n.editTitleLabel,
            child: TextField(
              key: const Key('edit-title'),
              controller: _title,
              autofocus: true,
              onChanged: (_) => _changed(),
              onSubmitted: (_) => _submit(),
              textDirection: textDirectionOf(_title.text),
              textInputAction: TextInputAction.done,
              minLines: 1,
              maxLines: 3,
              style: textStyle,
              inputFormatters: [
                // A title is one line; a pasted line break becomes a space.
                FilteringTextInputFormatter.deny(RegExp(r'[\r\n]+'), replacementString: ' '),
                const CodePointLimitFormatter(TaskText.titleMax),
              ],
            ),
          ),
          LabeledField(
            label: l10n.drawerDescriptionLabel,
            child: TextField(
              key: const Key('edit-description'),
              controller: _description,
              onChanged: (_) => _changed(),
              textDirection: textDirectionOf(_description.text),
              keyboardType: TextInputType.multiline,
              minLines: 4,
              maxLines: null,
              style: textStyle.copyWith(height: 1.8),
              inputFormatters: const [CodePointLimitFormatter(TaskText.descriptionMax)],
            ),
          ),
          Row(
            spacing: 10,
            children: [
              FilledButton(
                key: const Key('edit-save'),
                onPressed: _canSubmit ? _submit : null,
                child: Text(l10n.editSave),
              ),
              OutlinedButton(
                key: const Key('edit-cancel'),
                onPressed: widget.onCancel,
                style: quietOutlineButtonStyle(context),
                child: Text(l10n.editCancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
