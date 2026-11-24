import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'reports_messages.dart';

/// Picks a report's dates: two calendars, first day and last day, each with
/// month arrows and a year list. Nothing is typed, so no date can be written
/// wrong. Returns null on Cancel.
Future<DateTimeRange?> showReportRangeDialog(
  BuildContext context, {
  required DateTime lastDate,
  required DateTimeRange initial,
}) => showDialog<DateTimeRange>(
  context: context,
  builder: (context) => ReportRangeDialog(lastDate: lastDate, initial: initial),
);

class ReportRangeDialog extends StatefulWidget {
  const ReportRangeDialog({super.key, required this.lastDate, required this.initial});

  /// The venue's day: no later date can be picked.
  final DateTime lastDate;
  final DateTimeRange initial;

  static final firstDate = DateTime(2020);

  @override
  State<ReportRangeDialog> createState() => _ReportRangeDialogState();
}

class _ReportRangeDialogState extends State<ReportRangeDialog> {
  late DateTime _from = _clamp(widget.initial.start);
  late DateTime _to = _clamp(widget.initial.end);

  // Bumped when one date moves the other, so that calendar shows it.
  int _fromVersion = 0;
  int _toVersion = 0;

  DateTime _clamp(DateTime d) {
    final day = DateUtils.dateOnly(d);
    if (day.isBefore(ReportRangeDialog.firstDate)) return ReportRangeDialog.firstDate;
    if (day.isAfter(widget.lastDate)) return widget.lastDate;
    return day;
  }

  void _pickFrom(DateTime d) => setState(() {
    _from = d;
    if (_to.isBefore(d)) {
      _to = d;
      _toVersion++;
    }
  });

  void _pickTo(DateTime d) => setState(() {
    _to = d;
    if (_from.isAfter(d)) {
      _from = d;
      _fromVersion++;
    }
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final days = _to.difference(_from).inDays + 1;

    Widget calendar(String label, Key key, DateTime value, ValueChanged<DateTime> onPick) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 12, bottom: 4),
          child: Text(
            '$label  ${reportDates(value, value)}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        Container(
          width: 320,
          height: 340,
          decoration: BoxDecoration(
            border: Border.all(color: tokens.border),
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          ),
          child: CalendarDatePicker(
            key: key,
            initialDate: value,
            currentDate: widget.lastDate,
            firstDate: ReportRangeDialog.firstDate,
            lastDate: widget.lastDate,
            onDateChanged: onPick,
          ),
        ),
      ],
    );

    return AlertDialog(
      title: Text(l10n.reportsRangeHelp),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // A Row, not a Wrap: the dialog sizes its content to the widest
            // child, so a Wrap would put the two calendars one under the other.
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                calendar(
                  l10n.reportsRangeFrom,
                  ValueKey('range-from-$_fromVersion'),
                  _from,
                  _pickFrom,
                ),
                const SizedBox(width: 20),
                calendar(l10n.reportsRangeTo, ValueKey('range-to-$_toVersion'), _to, _pickTo),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              key: const ValueKey('range-summary'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.primaryTint,
                borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              ),
              child: Text(
                '${reportDates(_from, _to)} · ${l10n.reportsRangeDays(days)}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: tokens.onPrimaryTint,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('range-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('range-apply'),
          onPressed: () => Navigator.of(context).pop(DateTimeRange(start: _from, end: _to)),
          child: Text(l10n.reportsRangeApply),
        ),
      ],
    );
  }
}
