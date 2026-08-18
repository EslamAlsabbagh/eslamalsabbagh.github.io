import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_event.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_tokens.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Monthly view: compact 7-col grid with per-day shift-type count dots.
class MonthlyMobileView extends StatelessWidget {
  const MonthlyMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final loadedMonth = state.loadedMonth ?? DateTime.now();

        if (state.monthLoading) {
          return _MonthlyMobileSkeleton(month: loadedMonth);
        }

        final today = DateTime.now();
        final dayNames = SC.localizedDayNames(l10n); // [Sat, Sun, Mon, ...]

        // Build 6-week grid (42 cells) starting from Saturday of the first week
        final firstOfMonth = DateTime(loadedMonth.year, loadedMonth.month, 1);
        // weekday: 1=Mon…7=Sun; our week starts Sunday (offset = weekday%7)
        final startOffset = firstOfMonth.weekday % 7;
        final gridStart = firstOfMonth.subtract(Duration(days: startOffset));
        final cells = List.generate(42, (i) => gridStart.add(Duration(days: i)));

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildMonthNav(context, state, l10n, loadedMonth)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
                child: Row(
                  children:
                      dayNames
                          .map(
                            (n) => Expanded(
                              child: Text(
                                n,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: MT.text3),
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 0.88,
                ),
                delegate: SliverChildBuilderDelegate((ctx, i) {
                  final day = cells[i];
                  final inMonth = day.month == loadedMonth.month;
                  final isToday = _sameDay(day, today);
                  final counts = _countForDay(state, day);
                  return _DayCell(day: day, inMonth: inMonth, isToday: isToday, counts: counts);
                }, childCount: 42),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _LegendPill(bg: MT.overnightBg, color: MT.overnightText, label: l10n.shiftOvernight),
                    _LegendPill(bg: MT.morningBg, color: MT.morningText, label: l10n.shiftMorning),
                    _LegendPill(bg: MT.eveningBg, color: MT.eveningText, label: l10n.shiftAfternoon),
                    _LegendPill(bg: MT.nightBg, color: MT.nightText, label: l10n.shiftNight),
                    _LegendPill(bg: MT.leaveBg, color: MT.leaveText, label: l10n.scheduleLegendLeave),
                    _LegendPill(bg: MT.offBg, color: MT.offText, label: l10n.scheduleOffTypeDayOff),
                  ],
                ),
              ),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        );
      },
    );
  }

  Widget _buildMonthNav(BuildContext ctx, ScheduleState state, AppLocalizations l10n, DateTime month) {
    final isRtl = Directionality.of(ctx) == TextDirection.rtl;
    final months = SC.localizedMonthNames(l10n);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          _NavBtn(
            icon: isRtl ? Icons.chevron_right : Icons.chevron_left,
            onTap:
                state.monthLoading
                    ? null
                    : () => ctx.read<ScheduleBloc>().add(ChangeMonth(DateTime(month.year, month.month - 1))),
          ),
          Expanded(
            child: Text(
              '${months[month.month]} ${month.year}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MT.text),
            ),
          ),
          _NavBtn(
            icon: isRtl ? Icons.chevron_left : Icons.chevron_right,
            onTap:
                state.monthLoading
                    ? null
                    : () => ctx.read<ScheduleBloc>().add(ChangeMonth(DateTime(month.year, month.month + 1))),
          ),
        ],
      ),
    );
  }

  Map<String, int> _countForDay(ScheduleState state, DateTime day) {
    final counts = <String, int>{};
    for (final shift in state.effectiveMonthSchedule.values) {
      final shiftDate = shift.weekStart.add(Duration(days: shift.dayIndex));
      if (!_sameDay(shiftDate, day)) continue;
      if (!state.filteredTeam.any((u) => u.id == shift.employeeId)) continue;
      // Published shifts and leaves count for everyone; my own drafts count
      // too (self-draft feature).
      if (!shift.isLeave && !shift.isPublished && !state.isOwnDraft(shift)) continue;
      final kind = shift.summaryKind;
      counts[kind] = (counts[kind] ?? 0) + 1;
    }
    return counts;
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final Map<String, int> counts;

  const _DayCell({required this.day, required this.inMonth, required this.isToday, required this.counts});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: inMonth ? 1.0 : 0.35,
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? MT.brandBg : MT.bgCard,
          border: Border.all(color: isToday ? MT.brand : MT.hair2, width: isToday ? 2 : 1),
          borderRadius: MT.br12,
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isToday ? MT.brand : MT.text),
            ),
            const SizedBox(height: 2),
            if (inMonth)
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Wrap(
                    clipBehavior: Clip.hardEdge,
                    spacing: 0,
                    runSpacing: 5,
                    direction: Axis.vertical,
                    alignment: WrapAlignment.start,
                    children: [
                      if ((counts['overnight'] ?? 0) > 0) _CountDot(color: MT.overnightStripe, n: counts['overnight']!),
                      if ((counts['morning'] ?? 0) > 0) _CountDot(color: MT.morningStripe, n: counts['morning']!),
                      if ((counts['afternoon'] ?? 0) > 0) _CountDot(color: MT.eveningStripe, n: counts['afternoon']!),
                      if ((counts['night'] ?? 0) > 0) _CountDot(color: MT.nightStripe, n: counts['night']!),
                      if ((counts['leave'] ?? 0) > 0) _CountDot(color: MT.leaveStripe, n: counts['leave']!),
                      if ((counts['off'] ?? 0) > 0) _CountDot(color: MT.offStripe, n: counts['off']!),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountDot extends StatelessWidget {
  final Color color;
  final int n;

  const _CountDot({required this.color, required this.n});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 5, height: 5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 2),
        Text('$n', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _LegendPill extends StatelessWidget {
  final Color bg;
  final Color color;
  final String label;

  const _LegendPill({required this.bg, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: MT.br24),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── Skeleton loading ────────────────────────────────────────────────────────

Widget _sBox(double w, double h, double opacity, {double radius = 6}) => Container(
  width: w,
  height: h,
  decoration: BoxDecoration(
    color: const Color(0xFFD1D5DB).withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(radius),
  ),
);

class _ShimmerProvider extends StatefulWidget {
  final Widget Function(double opacity) builder;
  const _ShimmerProvider({required this.builder});
  @override
  State<_ShimmerProvider> createState() => _ShimmerProviderState();
}

class _ShimmerProviderState extends State<_ShimmerProvider> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.45, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: _opacity, builder: (_, __) => widget.builder(_opacity.value));
}

class _MonthlyMobileSkeleton extends StatelessWidget {
  final DateTime month;
  const _MonthlyMobileSkeleton({required this.month});

  @override
  Widget build(BuildContext context) {
    return _ShimmerProvider(
      builder:
          (opacity) => CustomScrollView(
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildNavSkeleton(context, opacity)),
              SliverToBoxAdapter(child: _buildDayHeaderSkeleton(opacity)),
              _buildGridSkeleton(opacity),
              SliverToBoxAdapter(child: _buildLegendSkeleton(opacity)),
              const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
            ],
          ),
    );
  }

  Widget _buildNavSkeleton(BuildContext ctx, double opacity) {
    final isRtl = Directionality.of(ctx) == TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          _NavBtn(icon: isRtl ? Icons.chevron_right : Icons.chevron_left),
          Expanded(child: Center(child: _sBox(140, 16, opacity * 0.7))),
          _NavBtn(icon: isRtl ? Icons.chevron_left : Icons.chevron_right),
        ],
      ),
    );
  }

  Widget _buildDayHeaderSkeleton(double opacity) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
      child: Row(children: List.generate(7, (_) => Expanded(child: Center(child: _sBox(20, 10, opacity * 0.5))))),
    );
  }

  Widget _buildGridSkeleton(double opacity) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 0.88,
        ),
        delegate: SliverChildBuilderDelegate(
          (_, __) => Container(
            decoration: BoxDecoration(color: MT.bgCard, border: Border.all(color: MT.hair2), borderRadius: MT.br12),
            padding: const EdgeInsets.all(4),
            child: Align(alignment: AlignmentDirectional.topStart, child: _sBox(14, 9, opacity * 0.6)),
          ),
          childCount: 42,
        ),
      ),
    );
  }

  Widget _buildLegendSkeleton(double opacity) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: List.generate(4, (_) => _sBox(70, 26, opacity * 0.5, radius: 20)),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null ? MT.bgCard : MT.hair2,
          border: Border.all(color: MT.hair),
          borderRadius: MT.br12,
        ),
        child: Icon(icon, size: 18, color: onTap != null ? MT.text2 : MT.text3),
      ),
    );
  }
}
