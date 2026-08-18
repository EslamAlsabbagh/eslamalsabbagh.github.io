import 'package:hrms_demo/core/theme/app_colors.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/statistics/widgets/stat_widgets.dart';
import 'package:hrms_demo/presentation/widgets/safe_tooltip.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

typedef BarDatum = ({String label, double value, Color color});

/// Horizontal bars ranked by magnitude — the correct form for "top N categories"
/// (departments, action types) where labels are long. Direct value labels sit at
/// each bar end (data-viz: selective direct labels, not axis-only).
class HorizontalBarCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<BarDatum> data;
  final double? width;
  final int maxBars;

  /// Show each bar's share of the total beside its count. Only meaningful when
  /// the bars partition a whole (headcount, tenure) — not for magnitudes like
  /// average days, where a "percent of the sum" would be nonsense.
  final bool showPercent;

  /// Renders the value text. Defaults to [formatValue] (whole → no decimals,
  /// fractional → one decimal, so the number matches the bar's length). Override
  /// to append a unit, e.g. `(v) => '${formatValue(v)}d'` for day averages.
  final String Function(double)? valueFormat;

  const HorizontalBarCard({
    super.key,
    required this.title,
    required this.icon,
    required this.data,
    this.width,
    this.maxBars = 10,
    this.showPercent = false,
    this.valueFormat,
  });

  @override
  Widget build(BuildContext context) {
    final items = data.take(maxBars).toList();
    final maxVal = items.fold<double>(0, (m, e) => e.value > m ? e.value : m);
    // Denominator is the FULL data set, not just the visible bars: when maxBars
    // truncates the tail, a share of the shown rows would overstate every bar.
    final total = data.fold<double>(0, (s, e) => s + e.value);
    return ChartCard(
      title: title,
      icon: icon,
      width: width,
      // Sized by its rows, not a computed height: a row's height depends on font
      // metrics, so any per-row constant is a guess that eventually under-counts
      // and reintroduces an inner scrollbar. maxBars bounds how tall this gets,
      // and the page itself scrolls.
      height: null,
      child:
          items.isEmpty
              ? SizedBox(height: 120, child: ChartEmptyState(message: AppLocalizations.of(context)!.statsNoData))
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final d in items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          // maxLines:1 is load-bearing, not cosmetic: without it
                          // the height here is unbounded, so ellipsis never fires
                          // and a long label ("Human Resources Department") wraps
                          // to 2-3 lines — blowing past the _rowHeight the card's
                          // height is computed from. The tooltip keeps the full
                          // name reachable now that it can truncate.
                          SizedBox(
                            width: 120,
                            child: SafeTooltip(
                              message: d.label,
                              child: Text(
                                d.label,
                                style: const TextStyle(fontSize: 12, color: AppColors.inkSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Stack(
                              children: [
                                Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: AppColors.gridline.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                FractionallySizedBox(
                                  // A true zero draws NO bar (a forced sliver would
                                  // contradict the printed 0); tiny positives keep a
                                  // 2% floor so they stay visible.
                                  widthFactor:
                                      (maxVal <= 0 || d.value <= 0) ? 0.0 : (d.value / maxVal).clamp(0.02, 1.0),
                                  child: Container(
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: d.color,
                                      borderRadius: BorderRadius.circular(4), // rounded data-end
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: showPercent ? 82 : 44,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    (valueFormat ?? formatValue)(d.value),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.inkPrimary,
                                    ),
                                  ),
                                ),
                                // The share is supporting detail, so it wears the
                                // muted ink token — the count stays the headline.
                                if (showPercent)
                                  Expanded(
                                    child: Text(
                                      formatPercent(d.value, total),
                                      style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
    );
  }
}

/// A stacked column per x-category (e.g. month), each stack split into series
/// segments. Used for request-volume-by-type over time. Series identity comes
/// from [seriesColors]; a legend is required and provided by the caller's tab.
class StackedBarChartCard extends StatelessWidget {
  final String title;
  final IconData icon;

  /// Ordered x labels (e.g. 'Jan', 'Feb'…).
  final List<String> xLabels;

  /// For each x index, the per-series values keyed by series name.
  final List<Map<String, double>> stacks;

  /// Series name → color, in draw order.
  final Map<String, Color> seriesColors;
  final double? width;

  /// Maps a raw series key to its display label for the legend. Defaults to
  /// [humanize]; pass a localizing resolver to translate the keys.
  final String Function(String)? seriesLabel;

  const StackedBarChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.xLabels,
    required this.stacks,
    required this.seriesColors,
    this.width,
    this.seriesLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = stacks.any((m) => m.values.any((v) => v > 0));
    return ChartCard(
      title: title,
      icon: icon,
      width: width,
      height: 320,
      child:
          !hasData
              ? ChartEmptyState(message: AppLocalizations.of(context)!.statsNoData)
              : Column(
                children: [
                  Expanded(
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (v) => FlLine(color: AppColors.gridline, strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 32,
                              getTitlesWidget:
                                  (v, meta) => Text(
                                    v.toInt().toString(),
                                    style: const TextStyle(fontSize: 10, color: AppColors.inkMuted),
                                  ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              getTitlesWidget: (v, meta) {
                                final i = v.toInt();
                                if (i < 0 || i >= xLabels.length) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    xLabels[i],
                                    style: const TextStyle(fontSize: 10, color: AppColors.inkMuted),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        barGroups: [for (int i = 0; i < stacks.length; i++) _group(i, stacks[i])],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ChartLegend([
                    for (final e in seriesColors.entries)
                      LegendEntry(label: (seriesLabel ?? humanize)(e.key), color: e.value),
                  ]),
                ],
              ),
    );
  }

  BarChartGroupData _group(int x, Map<String, double> bySeries) {
    final items = <BarChartRodStackItem>[];
    double running = 0;
    for (final entry in seriesColors.entries) {
      final v = bySeries[entry.key] ?? 0;
      if (v <= 0) continue;
      items.add(BarChartRodStackItem(running, running + v, entry.value));
      running += v;
    }
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: running,
          width: 16,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          rodStackItems: items,
        ),
      ],
    );
  }
}
