import 'package:flutter/material.dart';

import '../../../../core/format/app_formats.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import 'field_box.dart';

/// A due date («١٣ أكتوبر ٢٠٢٦») with a calendar icon, in the canvas's input
/// box; tapping it opens the date picker. Used by the drawer and the new-task
/// modal.
class DateFieldBox extends StatelessWidget {
  const DateFieldBox({super.key, required this.date, required this.onPicked, this.dimmed = false});

  final DateTime date;

  /// Null makes the field inert.
  final ValueChanged<DateTime>? onPicked;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final onPicked = this.onPicked;

    final pick = onPicked == null
        ? null
        : () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(date.year - 5),
              lastDate: DateTime(date.year + 5, 12, 31),
            );
            if (picked != null) onPicked(picked);
          };

    return Semantics(
      button: true,
      label: l10n.drawerPickDue,
      value: AppFormats.fullDate(date),
      // Replaces the InkWell's node, so the tap is declared here too.
      excludeSemantics: true,
      onTap: pick,
      child: FieldBox(
        key: const Key('due-field'),
        dimmed: dimmed,
        onTap: pick,
        child: Row(
          spacing: 8,
          children: [
            Expanded(
              child: Text(
                AppFormats.fullDate(date),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(color: tokens.ink),
              ),
            ),
            Icon(Icons.calendar_today_outlined, size: 18, color: tokens.ink),
          ],
        ),
      ),
    );
  }
}
