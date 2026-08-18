import 'package:hrms_demo/core/theme/app_colors.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/statistics/widgets/stat_widgets.dart';
import 'package:flutter/material.dart';

/// A row×column heatmap (approver × request-type of live-pending counts). Cell
/// color is the single-hue sequential ramp scaled to the max cell — the correct
/// encoding for continuous magnitude. Counts are printed in-cell so meaning is
/// never color-alone. Scrolls horizontally inside its own container.
class HeatmapGrid extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> rowKeys; // approvers
  final List<String> colKeys; // request types
  final Map<String, Map<String, int>> values; // values[row][col] = count
  final double? width;

  /// Display labels for the raw keys. The keys stay raw because they index
  /// [values]; only their rendering is translated. Default to [humanize].
  final String Function(String)? rowLabel;
  final String Function(String)? colLabel;

  const HeatmapGrid({
    super.key,
    required this.title,
    required this.icon,
    required this.rowKeys,
    required this.colKeys,
    required this.values,
    this.width,
    this.rowLabel,
    this.colLabel,
  });

  @override
  Widget build(BuildContext context) {
    int maxCell = 0;
    for (final r in rowKeys) {
      for (final c in colKeys) {
        final v = values[r]?[c] ?? 0;
        if (v > maxCell) maxCell = v;
      }
    }
    return ChartCard(
      title: title,
      icon: icon,
      width: width,
      height: (rowKeys.length * 40 + 90).clamp(160, 460).toDouble(),
      child:
          rowKeys.isEmpty || colKeys.isEmpty || maxCell == 0
              ? ChartEmptyState(message: AppLocalizations.of(context)!.statsNothingPending)
              : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Column headers
                    Row(
                      children: [
                        const SizedBox(width: 84),
                        for (final c in colKeys)
                          SizedBox(
                            width: 64,
                            child: Text(
                              (colLabel ?? humanize)(c),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: const TextStyle(fontSize: 10, color: AppColors.inkMuted),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    for (final r in rowKeys)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 84,
                              child: Text(
                                (rowLabel ?? humanize)(r),
                                style: const TextStyle(fontSize: 11, color: AppColors.inkSecondary),
                              ),
                            ),
                            for (final c in colKeys) _cell(values[r]?[c] ?? 0, maxCell),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _cell(int v, int maxCell) {
    final t = maxCell == 0 ? 0.0 : v / maxCell;
    final bg = AppColors.sequentialFor(t);
    // Ink flips to white once the fill gets dark enough to keep contrast.
    final fg = t > 0.45 ? Colors.white : AppColors.inkSecondary;
    return Container(
      width: 60,
      height: 34,
      margin: const EdgeInsets.all(2), // 2px surface gap between cells
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      alignment: Alignment.center,
      child: Text(
        v == 0 ? '–' : '$v',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: v == 0 ? AppColors.inkMuted : fg),
      ),
    );
  }
}
