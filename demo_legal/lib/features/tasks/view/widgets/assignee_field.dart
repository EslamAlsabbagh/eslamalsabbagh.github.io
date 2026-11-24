import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/assignee_option.dart';
import 'field_box.dart';

/// «الموظف المسؤول»: a select for managers and admins, otherwise the
/// assignee's name in the same (dimmed) box.
class AssigneeField extends StatelessWidget {
  const AssigneeField({
    super.key,
    required this.assigneeId,
    required this.assigneeName,
    required this.options,
    required this.onPicked,
    this.dimmed = false,
  });

  final String assigneeId;
  final String? assigneeName;

  /// Null when the viewer can't reassign; empty until loaded.
  final List<AssigneeOption>? options;

  /// Null makes the field inert.
  final ValueChanged<String>? onPicked;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final options = this.options;
    final onPicked = this.onPicked;
    final textStyle = AppTextStyles.body.copyWith(color: tokens.ink);
    final current = Text(
      assigneeName ?? l10n.formerEmployee,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: textStyle,
    );

    // The list always holds the current assignee once loaded (see
    // AssigneeOption.pick); until then, show the name.
    if (options == null || !options.any((o) => o.id == assigneeId)) {
      return FieldBox(dimmed: dimmed, child: current);
    }
    return FieldBox(
      dimmed: dimmed,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: const Key('assignee-field'),
          value: assigneeId,
          isExpanded: true,
          style: textStyle,
          dropdownColor: tokens.surface,
          borderRadius: BorderRadius.circular(AppRadii.input),
          icon: Icon(Icons.keyboard_arrow_down, color: tokens.ink),
          disabledHint: current,
          onChanged: onPicked == null ? null : (id) => id == null ? null : onPicked(id),
          items: [
            for (final option in options)
              DropdownMenuItem(
                value: option.id,
                child: Text(
                  option.name ?? l10n.formerEmployee,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
