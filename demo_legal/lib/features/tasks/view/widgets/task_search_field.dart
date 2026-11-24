import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/format/text_direction.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// The «اليوم» search field (DESIGN_SPEC §4 "Search"): a 44-high pill with a
/// round search icon at its start and, while there is text, a × at its end.
/// Esc clears it too. Reports every change; the bloc decides when to search.
///
/// «العقود» uses it with its own [hint], [label] and keys.
class TaskSearchField extends StatefulWidget {
  const TaskSearchField({
    super.key,
    required this.initialQuery,
    required this.onChanged,
    this.hint,
    this.label,
    this.fieldKey = const Key('task-search'),
    this.clearKey = const Key('task-search-clear'),
  });

  /// The bloc's query, so the text survives the field being rebuilt (for
  /// example when the layout switches between phone and wide).
  final String initialQuery;
  final ValueChanged<String> onChanged;

  /// The placeholder and the screen-reader label; the tasks' by default.
  final String? hint;
  final String? label;
  final Key fieldKey;
  final Key clearKey;

  @override
  State<TaskSearchField> createState() => _TaskSearchFieldState();
}

class _TaskSearchFieldState extends State<TaskSearchField> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialQuery);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    setState(() {});
    widget.onChanged(text);
  }

  void _clear() {
    if (_controller.text.isEmpty) return;
    _controller.clear();
    _changed('');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final text = _controller.text;

    OutlineInputBorder border(Color color, {double width = 1}) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.pill),
          borderSide: BorderSide(color: color, width: width),
        );

    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _clear},
      child: Semantics(
        label: widget.label ?? l10n.searchLabel,
        child: TextField(
          key: widget.fieldKey,
          controller: _controller,
          onChanged: _changed,
          // Mostly Arabic, but brand names may be typed in English.
          textDirection: textDirectionOf(text),
          textInputAction: TextInputAction.search,
          style: AppTextStyles.body.copyWith(color: tokens.ink),
          decoration: InputDecoration(
            hintText: widget.hint ?? l10n.searchHint,
            // Dense, so Material's 48px minimum for fields with icons gives way
            // to the theme's 44 (DESIGN_SPEC: 44 high).
            isDense: true,
            contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 4, vertical: 10),
            border: border(tokens.borderStrong),
            enabledBorder: border(tokens.borderStrong),
            focusedBorder: border(tokens.accent, width: 2),
            prefixIcon: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 6),
              child: ExcludeSemantics(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: tokens.accentOnDark, shape: BoxShape.circle),
                  child: Icon(Icons.search, size: 18, color: tokens.ink),
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(),
            suffixIcon: text.isEmpty
                ? null
                : IconButton(
                    key: widget.clearKey,
                    tooltip: l10n.searchClear,
                    constraints: const BoxConstraints.tightFor(
                      width: AppSpacing.touchTarget,
                      height: AppSpacing.touchTarget,
                    ),
                    color: tokens.textMuted,
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _clear,
                  ),
          ),
        ),
      ),
    );
  }
}
