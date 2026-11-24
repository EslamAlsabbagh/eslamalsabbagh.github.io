import 'package:flutter/material.dart';

import '../../core/format/app_formats.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/gen/app_localizations.dart';

/// The header's عاجلة / متأخرة / مفتوحة counters for the selected file.
class HeaderCounters extends StatelessWidget {
  const HeaderCounters({
    super.key,
    required this.urgent,
    required this.overdue,
    required this.open,
  });

  final int urgent;
  final int overdue;
  final int open;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 18,
      children: [
        _Counter(key: const Key('counter-urgent'), value: urgent, label: l10n.counterUrgent, color: tokens.statUrgent),
        _Counter(key: const Key('counter-overdue'), value: overdue, label: l10n.counterOverdue, color: tokens.statOverdue),
        _Counter(key: const Key('counter-open'), value: open, label: l10n.counterOpen, color: tokens.statOpen),
      ],
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter({super.key, required this.value, required this.label, required this.color});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final number = AppFormats.number(value);
    return Semantics(
      label: '$number $label',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(number, style: AppTextStyles.headerStat.copyWith(color: color)),
          Text(
            label,
            style: AppTextStyles.badge.copyWith(
              fontWeight: FontWeight.w400,
              color: context.tokens.onDarkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
