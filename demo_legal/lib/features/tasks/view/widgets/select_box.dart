import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import 'field_box.dart';

/// The canvas's `<select>`, in the drawer's look: [items] maps ids to names,
/// in order. A null [value] shows [hint] (or nothing). An [action] is a last
/// menu entry that runs [onAction] instead of being picked. Used by the
/// new-task modal and the contract form.
class SelectBox extends StatelessWidget {
  const SelectBox({
    super.key,
    required this.selectKey,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
    this.action,
    this.onAction,
  });

  /// The [action] entry's value; never a row id.
  static const _actionValue = '';

  final Key selectKey;
  final String? value;
  final Map<String, String> items;

  /// Null makes it inert.
  final ValueChanged<String>? onChanged;
  final String? hint;
  final Widget? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final textStyle = AppTextStyles.body.copyWith(color: tokens.ink);
    final onChanged = this.onChanged;
    Text name(String text, {Color? color}) => Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: color == null ? textStyle : textStyle.copyWith(color: color),
        );
    final value = this.value;
    final hint = this.hint == null ? null : name(this.hint!, color: tokens.textMuted);

    return FieldBox(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: selectKey,
          value: value,
          isExpanded: true,
          style: textStyle,
          dropdownColor: tokens.surface,
          borderRadius: BorderRadius.circular(AppRadii.input),
          icon: Icon(Icons.keyboard_arrow_down, color: tokens.ink),
          hint: hint,
          disabledHint: value == null ? hint : name(items[value] ?? ''),
          onChanged: onChanged == null
              ? null
              : (id) => switch (id) {
                    null => null,
                    _actionValue => onAction?.call(),
                    _ => onChanged(id),
                  },
          items: [
            for (final MapEntry(:key, value: label) in items.entries)
              DropdownMenuItem(value: key, child: name(label)),
            if (action != null)
              DropdownMenuItem(
                key: const Key('select-action'),
                value: _actionValue,
                enabled: onAction != null,
                child: action!,
              ),
          ],
        ),
      ),
    );
  }
}
