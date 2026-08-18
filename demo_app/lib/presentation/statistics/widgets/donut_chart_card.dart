import 'package:hrms_demo/core/theme/app_colors.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/statistics/widgets/stat_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// One donut slice — the tab layer maps a DTO onto this, choosing the color
/// (categorical slot or reserved status color) so the widget stays generic.
typedef DonutSlice = ({String label, double value, Color color});

/// A donut (magnitude-by-identity) with a paired legend. Center shows the total.
/// Legend is always present for ≥2 slices so identity is never color-alone.
class DonutChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<DonutSlice> slices;
  final double? width;
  final String? centerCaption;

  /// Also print each slice's raw count in the legend, not just its share.
  final bool showCounts;

  const DonutChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.slices,
    this.width,
    this.centerCaption,
    this.showCounts = false,
  });

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(0, (s, e) => s + e.value);
    return ChartCard(
      title: title,
      icon: icon,
      width: width,
      height: 300,
      child:
          total <= 0
              ? ChartEmptyState(message: AppLocalizations.of(context)!.statsNoData)
              : Column(
                children: [
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 2, // 2px surface gap between fills
                            centerSpaceRadius: 54,
                            sections: [
                              for (final s in slices)
                                PieChartSectionData(value: s.value, color: s.color, radius: 34, showTitle: false),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              total.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.inkPrimary,
                              ),
                            ),
                            Text(
                              centerCaption ?? AppLocalizations.of(context)!.total,
                              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ChartLegend([
                    for (final s in slices)
                      LegendEntry(
                        label: s.label,
                        color: s.color,
                        count: showCounts ? s.value.toStringAsFixed(0) : null,
                        percent: formatPercent(s.value, total),
                      ),
                  ]),
                ],
              ),
    );
  }
}
