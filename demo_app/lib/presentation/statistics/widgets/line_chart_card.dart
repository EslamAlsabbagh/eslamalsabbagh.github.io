import 'package:hrms_demo/core/theme/app_colors.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/statistics/widgets/stat_widgets.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A single-series line for change-over-time (leave seasonality, advances
/// disbursed per month). One series → no legend box; the title names it.
class LineChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> xLabels;
  final List<double> values;
  final Color color;
  final double? width;
  final String Function(double)? valueFormatter;

  const LineChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.xLabels,
    required this.values,
    this.color = AppColors.cat1Blue,
    this.width,
    this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = values.any((v) => v > 0);
    final maxVal = values.fold<double>(0, (m, v) => v > m ? v : m);
    return ChartCard(
      title: title,
      icon: icon,
      width: width,
      height: 300,
      child:
          !hasData
              ? ChartEmptyState(message: AppLocalizations.of(context)!.statsNoData)
              : Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: maxVal == 0 ? 1 : maxVal * 1.2,
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
                          reservedSize: 36,
                          getTitlesWidget:
                              (v, meta) => Text(
                                valueFormatter?.call(v) ?? v.toInt().toString(),
                                style: const TextStyle(fontSize: 10, color: AppColors.inkMuted),
                              ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 24,
                          interval: 1,
                          getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i < 0 || i >= xLabels.length) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(xLabels[i], style: const TextStyle(fontSize: 10, color: AppColors.inkMuted)),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
                        isCurved: true,
                        color: color,
                        barWidth: 2, // 2px lines
                        dotData: FlDotData(
                          show: true,
                          getDotPainter:
                              (spot, pct, bar, i) => FlDotCirclePainter(
                                radius: 4,
                                color: color,
                                strokeWidth: 2,
                                strokeColor: AppColors.surface,
                              ),
                        ),
                        belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }
}
