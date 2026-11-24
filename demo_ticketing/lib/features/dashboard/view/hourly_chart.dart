import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../data/dashboard_snapshot.dart';

/// Entries per hour (`Dashboard.dc.html`): one bar per hour, from the first
/// hour with an entry up to the hour now, with the hour now in the primary
/// color. Plain widgets; no chart package.
///
/// The venue day starts at [startHour] (ADR-0038), so the hours run from it
/// and wrap past midnight: 22, 23, 00, 01 on a day open after midnight.
class HourlyChart extends StatelessWidget {
  const HourlyChart({
    super.key,
    required this.hours,
    required this.currentHour,
    this.startHour = 0,
  });

  final List<HourCount> hours;
  final int currentHour;
  final int startHour;

  static const _barArea = 150.0;

  /// Every hour to draw, in the venue day's order, with 0 for an hour with
  /// no entry.
  static List<HourCount> filled(List<HourCount> hours, int currentHour, {int startHour = 0}) {
    if (hours.isEmpty) return const [];
    int place(int hour) => (hour - startHour) % 24;
    final byHour = {for (final h in hours) h.hour: h.entries};
    final first = hours.map((h) => place(h.hour)).reduce(math.min);
    final last = math.max(place(currentHour), hours.map((h) => place(h.hour)).reduce(math.max));
    return [
      for (var i = first; i <= last; i++)
        HourCount((startHour + i) % 24, byHour[(startHour + i) % 24] ?? 0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final bars = filled(hours, currentHour, startHour: startHour);
    if (bars.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            l10n.dashboardHourlyEmpty,
            style: TextStyle(fontSize: 14, color: tokens.textSecondary),
          ),
        ),
      );
    }
    final max = bars.map((h) => h.entries).reduce(math.max);
    final small = TextStyle(fontSize: 12, color: tokens.textSecondary);

    return Semantics(
      label: l10n.dashboardHourlyLabel,
      container: true,
      child: Column(
        children: [
          Container(
            height: 200,
            padding: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: tokens.border)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, bar) in bars.indexed) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('${bar.entries}', style: small),
                        const SizedBox(height: 4),
                        Container(
                          key: ValueKey('hour-bar-${bar.hour}'),
                          constraints: const BoxConstraints(maxWidth: 40),
                          height: max == 0 ? 0 : (bar.entries / max * _barArea).roundToDouble(),
                          decoration: BoxDecoration(
                            color: bar.hour == currentHour ? tokens.primary : tokens.chartBar,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final (i, bar) in bars.indexed) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Text('${bar.hour}', textAlign: TextAlign.center, style: small),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
