import 'package:hrms_demo/core/theme/app_colors.dart';
import 'package:hrms_demo/presentation/shared/form_styling.dart';
import 'package:flutter/material.dart';

/// Turns a raw DB key ('missing_punching', 'on_hold') into a human label
/// ('Missing Punching', 'On Hold'). Category labels are data-driven (departments
/// already arrive in English), so we humanize rather than hard-code an l10n key
/// per value — the fixed chrome (titles, KPI captions) is localized separately.
String humanize(String raw) => raw
    .replaceAll('_', ' ')
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

/// Formats a bar's value so the printed number always agrees with the bar's
/// length: whole numbers print without decimals (312), fractional ones keep one
/// decimal (3.6). Truncating to an integer here is what previously made two
/// different-length bars both read "4".
String formatValue(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// Formats [value] as a share of [total] for display next to a count.
///
/// Renders whole percents (a decimal on every row is noise at this density) but
/// falls back to '<1%' rather than a misleading '0%' for a category that is
/// genuinely present — e.g. a 1-person department out of 300.
String formatPercent(double value, double total) {
  if (total <= 0) return '';
  final p = value / total * 100;
  if (p > 0 && p < 1) return '<1%';
  return '${p.toStringAsFixed(0)}%';
}

/// Card shell for a chart — reuses [FormContainer]/[FormHeader] so the dashboard
/// inherits the app's exact card look (white, radius 12, soft shadow).
class ChartCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final double? width;

  /// Fixed plot height. Pass null to size to the child's intrinsic height —
  /// correct for content whose height is its own business (a list of bars),
  /// where a fixed box can only ever be a guess that clips or leaves dead space.
  /// fl_chart plots need a bounded height, so those keep a value here.
  final double? height;

  final Widget? trailing;

  const ChartCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.width,
    this.height = 260,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: FormContainer(
        header: Row(
          children: [
            Expanded(child: FormHeader(icon: icon, title: title, color: AppColors.primary)),
            if (trailing != null) trailing!,
          ],
        ),
        child: SizedBox(height: height, width: double.infinity, child: child),
      ),
    );
  }
}

/// A single KPI headline tile: big number + caption + optional delta.
class StatKpiTile extends StatelessWidget {
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;
  final String? delta;
  final bool? deltaGood;
  final double width;

  const StatKpiTile({
    super.key,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
    this.delta,
    this.deltaGood,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: FormContainer(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const Spacer(),
                if (delta != null)
                  Row(
                    children: [
                      Icon(
                        (deltaGood ?? true) ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: (deltaGood ?? true) ? AppColors.deltaGood : AppColors.deltaBad,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        delta!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: (deltaGood ?? true) ? AppColors.deltaGood : AppColors.deltaBad,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.inkPrimary)),
            const SizedBox(height: 4),
            Text(caption, style: const TextStyle(fontSize: 13, color: AppColors.inkSecondary)),
          ],
        ),
      ),
    );
  }
}

/// One legend row: a color swatch plus its label, and optionally the raw count
/// and its share. [count]/[percent] are pre-formatted strings so the legend stays
/// presentation-only.
class LegendEntry {
  final String label;
  final Color color;
  final String? count;
  final String? percent;

  const LegendEntry({required this.label, required this.color, this.count, this.percent});
}

/// A wrap-based legend. Identity is never color-alone — every swatch is paired
/// with its text label (data-viz accessibility rule).
///
/// Count and percent wear the same type styles as the bar charts' value column
/// (count bold in primary ink, percent muted) so a number reads identically
/// wherever it appears on the dashboard.
class ChartLegend extends StatelessWidget {
  final List<LegendEntry> items;
  const ChartLegend(this.items, {super.key});

  static const TextStyle _labelStyle = TextStyle(fontSize: 12, color: AppColors.inkSecondary);
  static const TextStyle _countStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.inkPrimary,
  );
  static const TextStyle _percentStyle = TextStyle(fontSize: 11, color: AppColors.inkMuted);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children:
          items
              .map(
                (e) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: e.color, borderRadius: BorderRadius.circular(3)),
                    ),
                    const SizedBox(width: 6),
                    // Text.rich keeps label/count/percent as one wrapping unit while
                    // still letting each part carry its own style.
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: e.label, style: _labelStyle),
                          if (e.count != null) TextSpan(text: '  ${e.count}', style: _countStyle),
                          if (e.percent != null && e.percent!.isNotEmpty)
                            TextSpan(text: '  ${e.percent}', style: _percentStyle),
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
    );
  }
}

/// Consistent empty state so a no-data filter never renders a broken chart.
class ChartEmptyState extends StatelessWidget {
  final String message;
  const ChartEmptyState({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 40, color: AppColors.inkMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(fontSize: 13, color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}
