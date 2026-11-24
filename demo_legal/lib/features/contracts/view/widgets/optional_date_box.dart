import 'package:flutter/material.dart';

import '../../../../core/format/app_formats.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../tasks/view/widgets/field_box.dart';

/// A date that may be empty, in the canvas's input box: «١٣ أكتوبر ٢٠٢٦»
/// or [placeholder] in `textMuted`, a × that clears a date, and a calendar
/// icon. Tapping the box opens the date picker at the date, or at
/// [initialDate] when there is none. The contract form's three dates and
/// the termination date.
///
/// Read by screen readers as a button named [label] with the date as its
/// value; the × is a button of its own («مسح تاريخ النهاية»).
class OptionalDateBox extends StatelessWidget {
  const OptionalDateBox({
    super.key,
    required this.keyName,
    required this.label,
    required this.date,
    required this.initialDate,
    required this.onPicked,
    this.onCleared,
    this.placeholder,
  });

  /// The box is keyed [keyName], its × `<keyName>-clear`.
  final String keyName;
  final String label;
  final DateTime? date;
  final DateTime initialDate;

  /// Null makes the box inert.
  final ValueChanged<DateTime>? onPicked;

  /// Null hides the ×.
  final VoidCallback? onCleared;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final date = this.date;
    final onPicked = this.onPicked;
    final onCleared = this.onCleared;
    final shown = date == null ? (placeholder ?? l10n.contractPickDate) : AppFormats.fullDate(date);

    final pick = onPicked == null
        ? null
        : () async {
            final start = date ?? initialDate;
            final picked = await showDatePicker(
              context: context,
              initialDate: start,
              firstDate: DateTime(start.year - 30),
              lastDate: DateTime(start.year + 30, 12, 31),
            );
            if (picked != null) onPicked(picked);
          };

    return Row(
      spacing: 6,
      children: [
        Expanded(
          child: Semantics(
            button: true,
            label: label,
            value: date == null ? '' : AppFormats.fullDate(date),
            excludeSemantics: true,
            onTap: pick,
            child: FieldBox(
              key: Key(keyName),
              dimmed: onPicked == null,
              onTap: pick,
              child: Row(
                spacing: 8,
                children: [
                  Expanded(
                    child: Text(
                      shown,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(color: date == null ? tokens.textMuted : tokens.ink),
                    ),
                  ),
                  Icon(Icons.calendar_today_outlined, size: 18, color: tokens.ink),
                ],
              ),
            ),
          ),
        ),
        if (date != null && onCleared != null && onPicked != null)
          Semantics(
            button: true,
            label: l10n.contractClearDate(label),
            excludeSemantics: true,
            onTap: onCleared,
            child: IconButton(
              key: Key('$keyName-clear'),
              onPressed: onCleared,
              icon: Icon(Icons.close, size: 18, color: tokens.ink),
            ),
          ),
      ],
    );
  }
}
