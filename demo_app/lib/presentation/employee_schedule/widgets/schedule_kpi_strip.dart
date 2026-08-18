import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';

class ScheduleKpiStrip extends StatelessWidget {
  final ScheduleState state;

  const ScheduleKpiStrip({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final filteredIds = state.filteredTeam.map((e) => e.id).whereType<int>().toSet();
    final filteredIdStrings = filteredIds.map((id) => id.toString()).toSet();

    final filteredShifts = state.effectiveSchedule.values.where((s) => filteredIds.contains(s.employeeId)).toList();

    final peopleScheduled =
        state.effectiveSchedule.keys.map((k) => k.split('-').first).where(filteredIdStrings.contains).toSet().length;

    final shiftCount = filteredShifts.where((s) => !s.isLeave).length;
    final totalHours = filteredShifts.where((s) => !s.isLeave).fold(0.0, (sum, s) => sum + s.hours);
    final conflictCount = filteredShifts.where((s) => s.conflict != null).length;
    final draftCount = filteredShifts.where((s) => !s.isPublished && !s.isLeave).length;
    final leaveCount = state.leaveKeys.keys.where((k) => filteredIdStrings.contains(k.split('-').first)).length;

    final l10n = AppLocalizations.of(context)!;
    final isColleagues = state.viewMode == ScheduleViewMode.colleagues;
    final items = [
      _KpiData(
        icon: Icons.people_outline,
        color: SC.blue,
        bg: SC.blue50,
        label: l10n.scheduleKpiPeopleScheduled,
        value: '$peopleScheduled',
        sub: l10n.scheduleKpiOfInView(state.filteredTeam.length),
      ),
      _KpiData(
        icon: Icons.access_time_outlined,
        color: SC.teal,
        bg: SC.teal50,
        label: l10n.scheduleKpiShiftsThisWeek,
        value: '$shiftCount',
        sub: l10n.scheduleKpiTotalHours(totalHours.toInt()),
      ),
      if (!isColleagues) ...[
        _KpiData(
          icon: Icons.warning_amber_outlined,
          color: SC.amber,
          bg: SC.amber50,
          label: l10n.scheduleKpiConflicts,
          value: '$conflictCount',
          sub: conflictCount == 0 ? l10n.scheduleKpiAllClear : l10n.scheduleKpiNeedReview,
        ),
        _KpiData(
          icon: Icons.drafts_outlined,
          color: SC.purple,
          bg: SC.purple50,
          label: l10n.scheduleKpiUnpublishedDrafts,
          value: '$draftCount',
          sub: draftCount == 0 ? l10n.scheduleKpiAllPublished : l10n.scheduleKpiPendingPublish,
        ),
        _KpiData(
          icon: Icons.back_hand_outlined,
          color: SC.rose,
          bg: SC.rose50,
          label: l10n.scheduleKpiOnApprovedLeave,
          value: '$leaveCount',
          sub: l10n.scheduleKpiThisWeek,
        ),
      ],
    ];

    return Row(children: items.map((d) => Expanded(child: _KpiCard(data: d))).toList());
  }
}

class _KpiData {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  final String value;
  final String sub;

  const _KpiData({
    required this.icon,
    required this.color,
    required this.bg,
    required this.label,
    required this.value,
    required this.sub,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SC.lineColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: data.bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(data.icon, color: data.color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: data.color, height: 1.1),
                ),
                Text(
                  data.label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: SC.muted, height: 1.3),
                ),
                Text(
                  data.sub,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10.5, color: SC.muted2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
