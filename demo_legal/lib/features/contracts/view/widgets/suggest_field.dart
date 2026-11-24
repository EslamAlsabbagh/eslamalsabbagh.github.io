import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/format/arabic_count.dart';
import '../../../../core/format/text_direction.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/validation/task_text.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../tasks/view/widgets/confirm_dialog.dart';

/// One row of a [SuggestField]'s list.
class SuggestOption<T> {
  const SuggestOption({required this.value, required this.label, this.hint, this.score = 0, this.exact = false});

  final T value;

  /// The value as shown, read in its own direction.
  final String label;

  /// Shown at the row's `end` in `textMuted`: «كافيه ليمونة», «شاغرة», «٣ عقود».
  final String? hint;

  /// Whole-name similarity to the typed text, 0 to 1. A record field asks
  /// «يوجد … مشابه» before adding when a row reaches [similarThreshold].
  final double score;

  /// The row is the typed text itself (same normalized name or unit key), so
  /// there is nothing new to add.
  final bool exact;

  static const double similarThreshold = 0.5;
}

/// What a [SuggestField] holds (DESIGN_SPEC §4 "Suggest field").
enum SuggestMode {
  /// One record (brand, tenant, linked lease): the pick shows as the value
  /// with a × to clear it.
  single,

  /// Several records (units), shown as chips with ×.
  multi,

  /// Repeated wording (subject, activity): the text is free, and a row only
  /// fills it in. No add row.
  freeText,
}

/// What [SuggestField.onAdd] gets when «+ إضافة "…"» is picked.
class SuggestAddRequest<T> {
  const SuggestAddRequest({required this.text, required this.shown, required this.showPanel});

  /// The typed text, trimmed.
  final String text;

  /// The rows on show, for the «يوجد … مشابه» check.
  final List<SuggestOption<T>> shown;

  /// Shows [builder]'s widget under the box in place of the list (the new
  /// unit's «النوع» row) until it calls `done`; completes with what it gave.
  final Future<R?> Function<R>(Widget Function(void Function(R? result) done) builder) showPanel;
}

/// One component for every suggest field: a box styled like the login
/// inputs, with a list of at most 5 rows opening under it, inside the
/// modal's scroll (DESIGN_SPEC §4 "Suggest field").
///
/// - **Opening:** focus asks [fetch] for the empty text (the most used, or
///   the first records); typing asks again 200 ms after the last key. An
///   answer for older text is dropped.
/// - **Keyboard:** ↓ / ↑ move, Enter picks, Esc closes the list (a second Esc
///   reaches the modal), Tab picks nothing.
/// - **Records** ([SuggestMode.single], [SuggestMode.multi]): «+ إضافة "…"»
///   is the last row while no row is the typed text, and runs [onAdd].
///   Leaving the field with typed text and no pick shows
///   «اختر من القائمة أو أضف جديدًا».
/// - **Screen readers:** the box is a text field read with [label]; each row
///   is a button read «value، hint», and a live region reads the count
///   («٣ اقتراحات»). Flutter's combobox role has no debug check yet (3.44: it
///   throws), and the list item role makes the web engine drop a row's tap
///   (it renders `role=listitem` with no click handling), so neither is used.
///
/// Keys, under [keyPrefix]: `-input`, `-list`, `-option-<i>`, `-add`,
/// `-clear`, `-remove-<i>`, `-panel`.
class SuggestField<T> extends StatefulWidget {
  const SuggestField({
    super.key,
    required this.keyPrefix,
    required this.label,
    required this.fetch,
    this.mode = SuggestMode.single,
    this.picks = const [],
    this.pickLabel,
    this.onPicksChanged,
    this.controller,
    this.onTextChanged,
    this.onAdd,
    this.addLabel,
    this.maxLength = 200,
    this.hintText,
    this.errorText,
    this.enabled = true,
    this.debounce = const Duration(milliseconds: 200),
  });

  final String keyPrefix;

  /// What screen readers call the box (the visible label is the form's).
  final String label;
  final Future<List<SuggestOption<T>>> Function(String query) fetch;
  final SuggestMode mode;

  /// The picked records ([SuggestMode.single]: none or one).
  final List<T> picks;

  /// How a pick reads in the box or on its chip.
  final String Function(T value)? pickLabel;

  /// Records only; null with [enabled] makes the picks fixed.
  final ValueChanged<List<T>>? onPicksChanged;

  /// [SuggestMode.freeText] only: the text, owned by the form.
  final TextEditingController? controller;
  final ValueChanged<String>? onTextChanged;

  /// Records only: creates (or finds) what the typed text names, and gives
  /// back the records to pick, or null to pick nothing. Null hides the add
  /// row.
  final Future<List<T>?> Function(SuggestAddRequest<T> request)? onAdd;

  /// The add row's text for the typed text; «+ إضافة "…"» by default.
  final String Function(String text)? addLabel;

  /// In code points, as the database counts.
  final int maxLength;
  final String? hintText;

  /// Shown under the box, before the field's own «اختر من القائمة» line.
  final String? errorText;
  final bool enabled;
  final Duration debounce;

  @override
  State<SuggestField<T>> createState() => _SuggestFieldState<T>();
}

class _SuggestFieldState<T> extends State<SuggestField<T>> {
  TextEditingController? _ownController;
  final _focus = FocusNode();
  Timer? _timer;

  /// Closes the list a moment after focus leaves. A screen reader on the web
  /// activates a row by its DOM node, which takes focus off the input first;
  /// closing at once would remove the row before its tap lands.
  Timer? _blurTimer;
  int _generation = 0;

  bool _open = false;
  List<SuggestOption<T>> _options = const [];

  /// The highlighted row; -1 for none.
  int _highlight = -1;
  bool _adding = false;
  Widget? _panel;
  bool _unpicked = false;

  TextEditingController get _text => widget.controller ?? (_ownController ??= TextEditingController());

  bool get _records => widget.mode != SuggestMode.freeText;

  bool get _showsPick => widget.mode == SuggestMode.single && widget.picks.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _blurTimer?.cancel();
    _focus.dispose();
    _ownController?.dispose();
    super.dispose();
  }

  String get _typed => _text.text.trim();

  bool get _showsAddRow =>
      _records && widget.onAdd != null && _typed.isNotEmpty && !_options.any((option) => option.exact);

  int get _rowCount => _options.length + (_showsAddRow ? 1 : 0);

  void _onFocusChange() {
    _blurTimer?.cancel();
    if (_focus.hasFocus) {
      _query();
      return;
    }
    _timer?.cancel();
    if (_adding) return;
    _blurTimer = Timer(blurDelay, () {
      if (!mounted || _focus.hasFocus || _adding) return;
      setState(() {
        _open = false;
        _highlight = -1;
        _unpicked = _records && _typed.isNotEmpty;
      });
    });
  }

  /// How long the list stays after focus leaves (see [_blurTimer]).
  static const Duration blurDelay = Duration(milliseconds: 150);

  void _onChanged(String text) {
    widget.onTextChanged?.call(text);
    setState(() {
      _unpicked = false;
      _highlight = -1;
    });
    _timer?.cancel();
    _timer = Timer(widget.debounce, _query);
  }

  Future<void> _query() async {
    final generation = ++_generation;
    final query = _text.text.trim();
    List<SuggestOption<T>> options;
    try {
      options = await widget.fetch(query);
    } catch (_) {
      // A failed suggestion only means no list; the field still takes text.
      options = const [];
    }
    // A single field with a pick has no list (focus can come back to the
    // box as a dialog over it closes).
    if (!mounted || generation != _generation || !_focus.hasFocus || _showsPick) return;
    setState(() {
      _options = options.take(5).toList();
      _highlight = -1;
      _open = _rowCount > 0;
    });
  }

  void _close() => setState(() {
        _open = false;
        _highlight = -1;
      });

  void _pick(SuggestOption<T> option) {
    switch (widget.mode) {
      case SuggestMode.freeText:
        _text.value = TextEditingValue(
          text: option.label,
          selection: TextSelection.collapsed(offset: option.label.length),
        );
        widget.onTextChanged?.call(option.label);
        _close();
      case SuggestMode.single || SuggestMode.multi:
        _addPicks([option.value]);
    }
  }

  void _addPicks(List<T> values) {
    final onPicksChanged = widget.onPicksChanged;
    if (onPicksChanged == null) return;
    final picks = widget.mode == SuggestMode.single
        ? values.take(1).toList()
        : [...widget.picks, ...values.where((value) => !widget.picks.contains(value))];
    _generation++;
    _blurTimer?.cancel();
    _text.clear();
    setState(() {
      _open = false;
      _options = const [];
      _highlight = -1;
      _unpicked = false;
    });
    onPicksChanged(picks);
  }

  Future<void> _add() async {
    final onAdd = widget.onAdd;
    final text = _typed;
    if (onAdd == null || text.isEmpty || _adding) return;
    setState(() {
      _adding = true;
      _open = false;
    });
    List<T>? added;
    try {
      added = await onAdd(SuggestAddRequest(text: text, shown: _options, showPanel: _showPanel));
    } finally {
      if (mounted) {
        setState(() {
          _adding = false;
          _panel = null;
        });
      }
    }
    if (!mounted) return;
    if (added != null && added.isNotEmpty) {
      _addPicks(added);
    } else if (_focus.hasFocus) {
      _query();
    }
  }

  Future<R?> _showPanel<R>(Widget Function(void Function(R? result) done) builder) {
    final completer = Completer<R?>();
    void done(R? result) {
      if (completer.isCompleted) return;
      completer.complete(result);
      if (mounted) setState(() => _panel = null);
    }

    setState(() => _panel = KeyedSubtree(key: Key('${widget.keyPrefix}-panel'), child: builder(done)));
    return completer.future;
  }

  void _activate(int row) {
    if (row < _options.length) {
      _pick(_options[row]);
    } else if (_showsAddRow) {
      _add();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowUp) {
      if (!_open) {
        _query();
        return KeyEventResult.handled;
      }
      final count = _rowCount;
      if (count == 0) return KeyEventResult.handled;
      setState(() {
        _highlight = key == LogicalKeyboardKey.arrowDown
            ? (_highlight + 1) % count
            : (_highlight <= 0 ? count - 1 : _highlight - 1);
      });
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) && _open && _highlight >= 0) {
      _activate(_highlight);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && _open) {
      _close();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab && _open) _close();
    return KeyEventResult.ignored;
  }

  void _clear() {
    widget.onPicksChanged?.call(const []);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final textStyle = AppTextStyles.body.copyWith(color: tokens.ink);
    final editable = widget.enabled && (widget.mode == SuggestMode.freeText || widget.onPicksChanged != null);
    final prefix = widget.keyPrefix;
    final pickLabel = widget.pickLabel ?? (value) => '$value';

    final error = widget.errorText ?? (_unpicked && _panel == null ? l10n.suggestPickOrAdd : null);

    final Widget box;
    if (_showsPick) {
      final label = pickLabel(widget.picks.first);
      box = _PickBox(
        label: label,
        clearKey: Key('$prefix-clear'),
        onClear: editable ? _clear : null,
      );
    } else {
      box = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: Semantics(
          label: widget.label,
          child: TextField(
            key: Key('$prefix-input'),
            controller: _text,
            focusNode: _focus,
            enabled: widget.enabled,
            readOnly: !editable || _adding,
            onChanged: _onChanged,
            // A tap on the focused box reopens a closed list (after a pick
            // in a multi field, or Esc).
            onTap: () {
              if (_focus.hasFocus && !_open && !_adding) _query();
            },
            textDirection: textDirectionOf(_text.text),
            maxLines: 1,
            style: textStyle,
            decoration: InputDecoration(hintText: widget.hintText, errorText: error),
            inputFormatters: [
              FilteringTextInputFormatter.deny(RegExp(r'[\r\n]+'), replacementString: ' '),
              CodePointLimitFormatter(widget.maxLength),
            ],
          ),
        ),
      );
    }

    final rows = <Widget>[
      for (final (index, option) in _options.indexed)
        _OptionRow(
          key: Key('$prefix-option-$index'),
          label: option.label,
          hint: option.hint,
          highlighted: index == _highlight,
          onTap: () => _pick(option),
        ),
      if (_showsAddRow)
        _OptionRow(
          key: Key('$prefix-add'),
          label: widget.addLabel?.call(_typed) ?? l10n.suggestAdd(_typed),
          highlighted: _options.length == _highlight,
          accent: true,
          onTap: _add,
        ),
    ];

    return TextFieldTapRegion(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 6,
        children: [
          if (widget.mode == SuggestMode.multi && widget.picks.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final (index, value) in widget.picks.indexed)
                  _Chip(
                    label: pickLabel(value),
                    removeKey: Key('$prefix-remove-$index'),
                    onRemove: editable
                        ? () => widget.onPicksChanged?.call([...widget.picks]..removeAt(index))
                        : null,
                  ),
              ],
            ),
          box,
          if (_panel case final panel?)
            panel
          else if (_open && rows.isNotEmpty && !_showsPick) ...[
            // Read when the rows change; the add row alone isn't a suggestion.
            if (_options.isNotEmpty)
              Semantics(
                liveRegion: true,
                label: arabicCount(
                  _options.length,
                  one: l10n.suggestCountOne,
                  two: l10n.suggestCountTwo,
                  few: l10n.suggestCountFew,
                  many: l10n.suggestCountMany,
                ),
                child: const SizedBox.shrink(),
              ),
            DecoratedBox(
              key: Key('$prefix-list'),
              decoration: BoxDecoration(
                color: tokens.surface,
                border: Border.all(color: tokens.border),
                borderRadius: BorderRadius.circular(AppRadii.input),
                boxShadow: [BoxShadow(color: tokens.tabShadow, blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.input),
                child: Semantics(
                  container: true,
                  explicitChildNodes: true,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: rows),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A list row: 44 high, the value (15) and its hint (13 `textMuted`) at the
/// `end`; `subtleFill` while highlighted. [accent] is the add row's text.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    super.key,
    required this.label,
    required this.highlighted,
    required this.onTap,
    this.hint,
    this.accent = false,
  });

  final String label;
  final String? hint;
  final bool highlighted;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hint = this.hint;
    return Semantics(
      button: true,
      selected: highlighted,
      label: hint == null ? label : '$label، $hint',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: highlighted ? tokens.subtleFill : tokens.surface,
        child: InkWell(
          onTap: onTap,
          canRequestFocus: false,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: accent ? null : textDirectionOf(label),
                      textAlign: TextAlign.start,
                      style: AppTextStyles.body.copyWith(color: accent ? tokens.accent : tokens.ink),
                    ),
                  ),
                  if (hint != null)
                    Flexible(
                      child: Text(
                        hint,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.meta.copyWith(color: tokens.textMuted),
                      ),
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

/// A single field's pick, in the input's box, with a × to clear it.
class _PickBox extends StatelessWidget {
  const _PickBox({required this.label, required this.clearKey, required this.onClear});

  final String label;
  final Key clearKey;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final onClear = this.onClear;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.borderStrong),
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
          child: Row(
            spacing: 8,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: textDirectionOf(label),
                  style: AppTextStyles.body.copyWith(color: tokens.ink),
                ),
              ),
              if (onClear != null) _RemoveButton(buttonKey: clearKey, label: l10n.suggestRemove(label), onTap: onClear),
            ],
          ),
        ),
      ),
    );
  }
}

/// A multi field's pick: `mutedFill`, radius 999, the value and a ×.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.removeKey, required this.onRemove});

  final String label;
  final Key removeKey;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final onRemove = this.onRemove;
    return DecoratedBox(
      decoration: BoxDecoration(color: tokens.mutedFill, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: 12, end: onRemove == null ? 12 : 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                label,
                textDirection: textDirectionOf(label),
                style: AppTextStyles.meta.copyWith(color: tokens.ink, fontWeight: FontWeight.w600),
              ),
            ),
            if (onRemove != null) _RemoveButton(buttonKey: removeKey, label: l10n.suggestRemove(label), onTap: onRemove),
          ],
        ),
      ),
    );
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.buttonKey, required this.label, required this.onTap});

  final Key buttonKey;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        key: buttonKey,
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox.square(
          dimension: 36,
          child: Icon(Icons.close, size: 16, color: context.tokens.ink),
        ),
      ),
    );
  }
}

/// What «يوجد … مشابه» decided.
sealed class SimilarChoice<T> {
  const SimilarChoice();
}

/// «استخدام هذا»: pick the existing record.
class UseExisting<T> extends SimilarChoice<T> {
  const UseExisting(this.value);

  final T value;
}

/// «إضافة جديد على أي حال».
class AddAnyway<T> extends SimilarChoice<T> {
  const AddAnyway();
}

/// The rows of [shown] at least [SuggestOption.similarThreshold] alike and not
/// the typed text itself, best first, at most 3.
List<SuggestOption<T>> similarOptions<T>(List<SuggestOption<T>> shown) {
  final similar = shown.where((option) => !option.exact && option.score >= SuggestOption.similarThreshold).toList()
    ..sort((a, b) => b.score.compareTo(a.score));
  return similar.take(3).toList();
}

/// «يوجد مستأجر مشابه» / «توجد وحدة مشابهة» (DESIGN_SPEC §4 "Suggest field"):
/// up to 3 close [matches], each with «استخدام هذا», then «رجوع» and
/// «إضافة جديد على أي حال». Null when the person goes back.
Future<SimilarChoice<T>?> showSimilarDialog<T>(
  BuildContext context, {
  required String title,
  required List<SuggestOption<T>> matches,
}) {
  final tokens = context.tokens;
  final l10n = AppLocalizations.of(context);
  return showDialog<SimilarChoice<T>>(
    context: context,
    barrierColor: tokens.scrim,
    builder: (context) => AlertDialog(
      backgroundColor: tokens.surface,
      surfaceTintColor: tokens.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.modal)),
      titlePadding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 0),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 0),
      actionsPadding: const EdgeInsetsDirectional.all(20),
      title: Text(title, style: AppTextStyles.sectionTitle.copyWith(color: tokens.ink)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, match) in matches.indexed)
              DecoratedBox(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tokens.dividerSubtle))),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.label,
                              textDirection: textDirectionOf(match.label),
                              style: AppTextStyles.body.copyWith(color: tokens.ink),
                            ),
                            if (match.hint case final hint?)
                              Text(hint, style: AppTextStyles.meta.copyWith(color: tokens.textMuted)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        key: Key('similar-use-$index'),
                        onPressed: () => Navigator.of(context).pop(UseExisting<T>(match.value)),
                        style: quietOutlineButtonStyle(context),
                        child: Text(l10n.similarUse),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        OutlinedButton(
          key: const Key('similar-back'),
          onPressed: () => Navigator.of(context).pop(),
          style: quietOutlineButtonStyle(context),
          child: Text(l10n.cancelTaskBack),
        ),
        FilledButton(
          key: const Key('similar-add'),
          onPressed: () => Navigator.of(context).pop(AddAnyway<T>()),
          child: Text(l10n.similarAddAnyway),
        ),
      ],
    ),
  );
}
