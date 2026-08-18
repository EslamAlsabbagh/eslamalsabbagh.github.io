import 'package:hrms_demo/core/theme/app_colors.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/statistics/widgets/stat_widgets.dart';
import 'package:hrms_demo/presentation/widgets/safe_tooltip.dart';
import 'package:flutter/material.dart';

/// One category with the two values being compared.
typedef PairedBarDatum = ({String label, double a, double b});

/// Two horizontal bars per category — the form for comparing two measures of
/// the SAME unit across categories (e.g. avg leave days taken vs available).
///
/// Both series share one scale (max over both), so bar lengths are comparable
/// across the pair as well as down the column — separate scales would make a
/// shorter bar look bigger than a longer one. Values are printed with
/// [formatValue] so the number always matches the bar's length.
class PairedBarCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<PairedBarDatum> data;
  final String seriesALabel;
  final String seriesBLabel;
  final Color seriesAColor;
  final Color seriesBColor;
  final double? width;
  final String Function(double)? valueFormat;

  const PairedBarCard({
    super.key,
    required this.title,
    required this.icon,
    required this.data,
    required this.seriesALabel,
    required this.seriesBLabel,
    this.seriesAColor = AppColors.cat1Blue,
    this.seriesBColor = AppColors.cat2Aqua,
    this.width,
    this.valueFormat,
  });

  @override
  Widget build(BuildContext context) {
    double maxVal = 0;
    for (final d in data) {
      if (d.a > maxVal) maxVal = d.a;
      if (d.b > maxVal) maxVal = d.b;
    }
    return ChartCard(
      title: title,
      icon: icon,
      width: width,
      height: null, // sized by its rows — see HorizontalBarCard for the rationale
      child:
          data.isEmpty
              ? SizedBox(height: 120, child: ChartEmptyState(message: AppLocalizations.of(context)!.statsNoData))
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final d in data)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
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
                            child: Column(
                              children: [
                                _bar(d.a, maxVal, seriesAColor),
                                const SizedBox(height: 2), // 2px surface gap between the pair
                                _bar(d.b, maxVal, seriesBColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  ChartLegend([
                    LegendEntry(label: seriesALabel, color: seriesAColor),
                    LegendEntry(label: seriesBLabel, color: seriesBColor),
                  ]),
                ],
              ),
    );
  }

  Widget _bar(double value, double maxVal, Color color) {
    return Row(
      children: [
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.gridline.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                // Same honesty rule as HorizontalBarCard: zero draws no bar.
                widthFactor: (maxVal <= 0 || value <= 0) ? 0.0 : (value / maxVal).clamp(0.02, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(
            (valueFormat ?? formatValue)(value),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkPrimary),
          ),
        ),
      ],
    );
  }
}
