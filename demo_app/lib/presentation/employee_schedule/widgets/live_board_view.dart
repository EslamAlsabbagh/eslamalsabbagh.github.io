import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';

enum _AttendanceStatus { onShift, /* onBreak, */ late, off }

class LiveBoardView extends StatefulWidget {
  final ScheduleState state;
  const LiveBoardView({super.key, required this.state});

  @override
  State<LiveBoardView> createState() => _LiveBoardViewState();
}

class _LiveBoardViewState extends State<LiveBoardView> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final now = DateTime.now();
    final nowHour = now.hour + now.minute / 60.0;
    final todayIdx = now.weekday % 7; // 0=Sun

    final team = state.filteredTeam;
    final cards =
        team.asMap().entries.map((entry) {
          final idx = entry.key;
          final emp = entry.value;
          final key = '${emp.id}-$todayIdx';
          final shift = state.effectiveTodaySchedule[key];
          final status = _statusFor(shift, nowHour);
          return _LiveCard(emp: emp, index: idx, shift: shift, status: status, nowHour: nowHour, pulseAnim: _pulseAnim);
        }).toList();

    cards.sort((a, b) {
      final aOn = a.status == _AttendanceStatus.onShift;
      final bOn = b.status == _AttendanceStatus.onShift;
      if (aOn != bOn) return aOn ? -1 : 1;
      final aStart = a.shift?.customStart;
      final bStart = b.shift?.customStart;
      if (aStart == null && bStart == null) return 0;
      if (aStart == null) return 1;
      if (bStart == null) return -1;
      return aStart.compareTo(bStart);
    });

    final onShiftCount = cards.where((c) => c.status == _AttendanceStatus.onShift).length;
    // final onBreakCount = cards.where((c) => c.status == _AttendanceStatus.onBreak).length;
    final lateCount = cards.where((c) => c.status == _AttendanceStatus.late).length;
    final offCount = cards.where((c) => c.status == _AttendanceStatus.off).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPI chips
        _KpiChipRow(
          onShift: onShiftCount,
          // onBreak: onBreakCount,
          late: lateCount,
          off: offCount,
          pulseAnim: _pulseAnim,
        ),
        const SizedBox(height: 16),
        // Card grid — natural height; page-level scroll handles vertical
        Wrap(spacing: 12, runSpacing: 12, children: cards),
      ],
    );
  }

  _AttendanceStatus _statusFor(ScheduleModel? shift, double nowHour) {
    if (shift == null || shift.isLeave || !shift.isPublished) return _AttendanceStatus.off;
    final overnight = shift.customEnd < shift.customStart;
    final onShift =
        overnight
            ? nowHour >= shift.customStart || nowHour < shift.customEnd
            : nowHour >= shift.customStart && nowHour < shift.customEnd;
    if (onShift) return _AttendanceStatus.onShift;
    // Late: within 30 min after shift start and not yet on shift
    if (nowHour >= shift.customStart && nowHour < shift.customStart + 0.5) {
      return _AttendanceStatus.late;
    }
    return _AttendanceStatus.off;
  }
}

class _KpiChipRow extends StatelessWidget {
  final int onShift;
  // final int onBreak;
  final int late;
  final int off;
  final Animation<double> pulseAnim;

  const _KpiChipRow({
    required this.onShift,
    // required this.onBreak,
    required this.late,
    required this.off,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        _KpiChip(
          label: l10n.scheduleOnShift,
          count: onShift,
          color: SC.green,
          bg: SC.green50,
          pulse: true,
          pulseAnim: pulseAnim,
        ),
        const SizedBox(width: 10),
        // _KpiChip(label: l10n.scheduleOnBreak, count: onBreak, color: SC.amber, bg: SC.amber50),
        // const SizedBox(width: 10),
        _KpiChip(label: l10n.scheduleLateNoPunch, count: late, color: SC.rose, bg: SC.rose50),
        const SizedBox(width: 10),
        _KpiChip(label: l10n.scheduleOff, count: off, color: SC.muted, bg: SC.lineColor),
      ],
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final Color bg;
  final bool pulse;
  final Animation<double>? pulseAnim;

  const _KpiChip({
    required this.label,
    required this.count,
    required this.color,
    required this.bg,
    this.pulse = false,
    this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulse && pulseAnim != null)
            AnimatedBuilder(
              animation: pulseAnim!,
              builder:
                  (_, __) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: pulseAnim!.value * 0.6),
                          blurRadius: 4 + pulseAnim!.value * 6,
                          spreadRadius: pulseAnim!.value * 4,
                          blurStyle: BlurStyle.inner,
                        ),
                      ],
                    ),
                  ),
            )
          else
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11.5, color: color)),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final UserModel emp;
  final int index;
  final ScheduleModel? shift;
  final _AttendanceStatus status;
  final double nowHour;
  final Animation<double> pulseAnim;

  const _LiveCard({
    required this.emp,
    required this.index,
    required this.shift,
    required this.status,
    required this.nowHour,
    required this.pulseAnim,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final rawName = emp.getLocalizedName(locale);
    final name = rawName.isNotEmpty ? rawName : '—';
    final avatarColor = SC.avatarColor(index);
    final l10n = AppLocalizations.of(context)!;
    final (statusLabel, statusColor, statusBg) = _statusProps(l10n);
    final progress = _computeProgress();

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SC.lineColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + status dot
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: avatarColor,
                    child: Text(
                      SC.avatarInitials(name),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (status == _AttendanceStatus.onShift)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: AnimatedBuilder(
                        animation: pulseAnim,
                        builder:
                            (_, __) => Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: SC.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: SC.green.withValues(alpha: pulseAnim.value * 0.7),
                                    blurRadius: 4 + pulseAnim.value * 6,
                                    spreadRadius: pulseAnim.value * 3,
                                    blurStyle: BlurStyle.inner,
                                  ),
                                ],
                              ),
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SC.ink),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      emp.getLocalizedDepartment(locale),
                      style: const TextStyle(fontSize: 11, color: SC.muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(20)),
            child: Text(statusLabel, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: statusColor)),
          ),
          // Shift info
          if (shift != null && shift!.isPublished) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    SC.localizedShiftLabel(AppLocalizations.of(context)!, shift!),
                    style: const TextStyle(fontSize: 11, color: SC.muted),
                  ),
                ),
                Text(
                  SC.localizedTimeLabel(AppLocalizations.of(context)!, shift!),
                  style: const TextStyle(fontSize: 11, color: SC.ink2),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: SC.lineColor,
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  (String, Color, Color) _statusProps(AppLocalizations l10n) {
    switch (status) {
      case _AttendanceStatus.onShift:
        return (l10n.scheduleOnShift, SC.green, SC.green50);
      // case _AttendanceStatus.onBreak:
      //   return (l10n.scheduleOnBreak, SC.amber, SC.amber50);
      case _AttendanceStatus.late:
        return (l10n.scheduleLateNoPunch, SC.rose, SC.rose50);
      case _AttendanceStatus.off:
        return (l10n.scheduleOff, SC.muted, SC.lineColor);
    }
  }

  double _computeProgress() {
    if (shift == null || shift!.isLeave) return 0.0;
    final overnight = shift!.customEnd < shift!.customStart;
    // Shift hasn't started yet — return empty bar
    final notStarted =
        overnight ? nowHour >= shift!.customEnd && nowHour < shift!.customStart : nowHour < shift!.customStart;
    if (notStarted) return 0.0;
    final total = overnight ? shift!.customEnd + 24 - shift!.customStart : shift!.customEnd - shift!.customStart;
    if (total <= 0) return 0.0;
    final elapsed =
        overnight && nowHour < shift!.customStart ? nowHour + 24 - shift!.customStart : nowHour - shift!.customStart;
    return elapsed / total;
  }
}
