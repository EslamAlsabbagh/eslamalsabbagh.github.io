import 'package:hrms_demo/core/theme/app_colors.dart';
import 'package:hrms_demo/data/models/statistics/statistics_models.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/statistics/widgets/stat_widgets.dart';
import 'package:hrms_demo/presentation/statistics/widgets/stats_labels.dart';
import 'package:flutter/material.dart';

/// The oldest-pending "aging" list. Reuses a plain Material DataTable inside the
/// standard chart card; the age column is emphasized (bold + serious color past
/// a threshold) so bottlenecks jump out. Scrolls horizontally on narrow screens.
class AgingTable extends StatelessWidget {
  final String title;
  final List<AgingRow> rows;
  final double? width;

  const AgingTable({super.key, required this.title, required this.rows, this.width});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ChartCard(
      title: title,
      icon: Icons.hourglass_bottom_rounded,
      width: width,
      height: (rows.length * 44 + 80).clamp(140, 460).toDouble(),
      child:
          rows.isEmpty
              ? ChartEmptyState(message: l10n.statsNothingPending)
              : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowHeight: 36,
                    dataRowMinHeight: 40,
                    dataRowMaxHeight: 44,
                    columnSpacing: 24,
                    headingTextStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.inkSecondary,
                    ),
                    dataTextStyle: const TextStyle(fontSize: 12, color: AppColors.inkPrimary),
                    columns: [
                      DataColumn(label: Text(l10n.type)),
                      DataColumn(label: Text(l10n.statsPendingAt)),
                      DataColumn(label: Text(l10n.department)),
                      DataColumn(label: Text(l10n.statsAge), numeric: true),
                    ],
                    rows: [
                      for (final r in rows)
                        DataRow(
                          cells: [
                            DataCell(Text(StatsLabels.requestType(context, r.requestType))),
                            DataCell(_ApproverPill(StatsLabels.approver(context, r.approver))),
                            DataCell(
                              Text(
                                r.department == null
                                    ? '—'
                                    : StatsLabels.department(context, r.department!, r.departmentAr),
                              ),
                            ),
                            DataCell(
                              Text(
                                '${r.ageDays}d',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: r.ageDays >= 7 ? AppColors.statusOnHold : AppColors.inkSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
    );
  }
}

class _ApproverPill extends StatelessWidget {
  final String approver;
  const _ApproverPill(this.approver);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        approver.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
      ),
    );
  }
}
