import 'package:flutter/material.dart';

import '../../../../core/format/text_direction.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validation/task_text.dart';
import '../../../../l10n/gen/app_localizations.dart';
import 'form_error_line.dart';

/// The drawer's update box, above the updates (desktop_11): a textarea and
/// «إضافة تحديث», which stays at 45% while the text is blank.
///
/// It holds the typed text: a failed post keeps it, and it clears when
/// [postedRevision] goes up. Enter makes a new line; only the button posts.
class UpdateComposer extends StatefulWidget {
  const UpdateComposer({
    super.key,
    required this.onPost,
    required this.postedRevision,
    required this.onDirtyChanged,
    this.errorMessage,
  });

  /// Null while the task loads or an update is in flight; the box is then
  /// read-only, so nothing typed meanwhile is cleared with the posted text.
  final ValueChanged<String>? onPost;
  final int postedRevision;

  /// Whether something worth keeping is typed, for the drawer's discard
  /// prompt. Only reports changes; never calls `setState` on the caller.
  final ValueChanged<bool> onDirtyChanged;

  /// Why the last post failed, shown under the button.
  final String? errorMessage;

  @override
  State<UpdateComposer> createState() => _UpdateComposerState();
}

class _UpdateComposerState extends State<UpdateComposer> {
  final _body = TextEditingController();
  bool _reportedDirty = false;

  @override
  void didUpdateWidget(UpdateComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.postedRevision != oldWidget.postedRevision) {
      _body.clear();
      _report();
    }
  }

  @override
  void dispose() {
    if (_reportedDirty) widget.onDirtyChanged(false);
    _body.dispose();
    super.dispose();
  }

  /// Blank text can't be posted, so there is nothing to lose.
  bool get _dirty => _body.text.trim().isNotEmpty;

  void _report() {
    if (_dirty == _reportedDirty) return;
    _reportedDirty = _dirty;
    widget.onDirtyChanged(_dirty);
  }

  void _changed() {
    setState(() {});
    _report();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onPost = widget.onPost;
    final canSubmit = onPost != null && TaskText.isValidUpdate(_body.text);
    final error = widget.errorMessage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        // The canvas's label is visually hidden: screen readers only.
        Semantics(
          label: l10n.updateFieldLabel,
          child: TextField(
            key: const Key('update-field'),
            controller: _body,
            onChanged: (_) => _changed(),
            readOnly: onPost == null,
            textDirection: textDirectionOf(_body.text),
            keyboardType: TextInputType.multiline,
            minLines: 3,
            maxLines: 10,
            style: AppTextStyles.body.copyWith(color: context.tokens.ink),
            inputFormatters: const [CodePointLimitFormatter(TaskText.updateMax)],
            decoration: InputDecoration(hintText: l10n.updateHint),
          ),
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton(
            key: const Key('update-post'),
            onPressed: canSubmit ? () => onPost(_body.text) : null,
            style: FilledButton.styleFrom(padding: const EdgeInsetsDirectional.symmetric(horizontal: 18)),
            child: Text(l10n.updateAdd),
          ),
        ),
        if (error != null) FormErrorLine(error, key: const Key('update-error')),
      ],
    );
  }
}
