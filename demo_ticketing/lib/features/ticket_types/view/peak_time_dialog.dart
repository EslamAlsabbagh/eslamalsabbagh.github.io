import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'ticket_types_messages.dart';

/// Picks a peak time: one tap for the hour (00-23), one for the minutes (00,
/// 15, 30 or 45). Nothing is typed, so no time can be written wrong, and the
/// digits are Western in both languages. Returns seconds after midnight, or
/// null on Cancel.
Future<int?> showPeakTimeDialog(
  BuildContext context, {
  required String title,
  required int initialSeconds,
}) => showDialog<int>(
  context: context,
  builder: (context) => PeakTimeDialog(title: title, initialSeconds: initialSeconds),
);

class PeakTimeDialog extends StatefulWidget {
  const PeakTimeDialog({super.key, required this.title, required this.initialSeconds});

  final String title;
  final int initialSeconds;

  static const minutes = [0, 15, 30, 45];

  @override
  State<PeakTimeDialog> createState() => _PeakTimeDialogState();
}

class _PeakTimeDialogState extends State<PeakTimeDialog> {
  late int _hour = widget.initialSeconds ~/ 3600 % 24;
  late int _minute = widget.initialSeconds % 3600 ~/ 60;

  /// The quarter hours, plus a saved minute that isn't one (set another way),
  /// so opening the dialog never changes the time by itself.
  List<int> get _minutes => {...PeakTimeDialog.minutes, _minute}.toList()..sort();

  String _two(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;

    Widget choice(String key, String label, bool selected, VoidCallback onTap) => SizedBox(
      width: 56,
      height: AppSizes.touchTarget,
      child: selected
          ? FilledButton(
              key: ValueKey(key),
              onPressed: onTap,
              style: FilledButton.styleFrom(padding: EdgeInsets.zero),
              child: Text(label, style: const TextStyle(fontSize: 16)),
            )
          : OutlinedButton(
              key: ValueKey(key),
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.zero,
                side: BorderSide(color: tokens.border),
              ),
              child: Text(label, style: TextStyle(fontSize: 16, color: tokens.text)),
            ),
    );

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
    );

    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  peakTimeText(_hour * 3600 + _minute * 60),
                  key: const ValueKey('peak-time-preview'),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 16),
              heading(l10n.peakPickHour),
              // 00..23 left to right, as a clock reads, in both languages.
              Directionality(
                textDirection: TextDirection.ltr,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var h = 0; h < 24; h++)
                      choice('peak-hour-$h', _two(h), h == _hour, () => setState(() => _hour = h)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              heading(l10n.peakPickMinute),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in _minutes)
                      choice(
                        'peak-minute-$m',
                        _two(m),
                        m == _minute,
                        () => setState(() => _minute = m),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('peak-time-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          key: const ValueKey('peak-time-ok'),
          onPressed: () => Navigator.of(context).pop(_hour * 3600 + _minute * 60),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
