import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_event.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MonthlyCalendarView extends StatelessWidget {
  final ScheduleState state;

  const MonthlyCalendarView({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final displayMonth = state.loadedMonth ?? state.weekStart;
    final year = displayMonth.year;
    final month = displayMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Padding before first: weekday 1=Mon, so pad (weekday-1) empty cells
    final leadingEmpty = firstDay.weekday % 7;
    final today = DateTime.now();

    return Column(
      children: [
        _MonthHeader(
          year: year,
          month: month,
          onPrev: () => context.read<ScheduleBloc>().add(ChangeMonth(DateTime(year, month - 1))),
          onNext: () => context.read<ScheduleBloc>().add(ChangeMonth(DateTime(year, month + 1))),
          disabled: state.monthLoading,
        ),
        const SizedBox(height: 8),
        // Weekday labels
        _WeekdayRow(),
        const SizedBox(height: 4),
        // Calendar grid — natural height; page-level scroll handles vertical
        state.monthLoading
            ? _MonthGridSkeleton(leadingEmpty: leadingEmpty, daysInMonth: daysInMonth)
            : _buildGrid(context, year, month, daysInMonth, leadingEmpty, today),
      ],
    );
  }

  Widget _buildGrid(BuildContext context, int year, int month, int daysInMonth, int leadingEmpty, DateTime today) {
    final cells = <Widget>[];

    // Leading empty cells (previous month)
    for (int i = 0; i < leadingEmpty; i++) {
      final prevDay = DateTime(year, month, 0).day - (leadingEmpty - 1 - i);
      cells.add(_DayCell(date: DateTime(year, month - 1, prevDay), isCurrentMonth: false, state: state, today: today));
    }

    // Current month
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(_DayCell(date: DateTime(year, month, d), isCurrentMonth: true, state: state, today: today));
    }

    // Trailing empty cells
    final trailing = (7 - (cells.length % 7)) % 7;
    for (int i = 1; i <= trailing; i++) {
      cells.add(_DayCell(date: DateTime(year, month + 1, i), isCurrentMonth: false, state: state, today: today));
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.1,
      mainAxisSpacing: 0,
      crossAxisSpacing: 0,
      children: cells,
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final int year;
  final int month;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final bool disabled;

  const _MonthHeader({
    required this.year,
    required this.month,
    required this.onPrev,
    required this.onNext,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final months = SC.localizedMonthNames(AppLocalizations.of(context)!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          _MonthNavBtn(icon: Icons.chevron_left, onTap: onPrev, disabled: disabled),
          const SizedBox(width: 6),
          Text(
            '${months[month]} $year',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SC.ink),
          ),
          const SizedBox(width: 6),
          _MonthNavBtn(icon: Icons.chevron_right, onTap: onNext, disabled: disabled),
        ],
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children:
          SC
              .localizedDayNames(AppLocalizations.of(context)!)
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SC.muted)),
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime date;
  final bool isCurrentMonth;
  final ScheduleState state;
  final DateTime today;

  const _DayCell({required this.date, required this.isCurrentMonth, required this.state, required this.today});

  @override
  Widget build(BuildContext context) {
    final isToday = _sameDay(date, today);
    final isWeekend = date.weekday == 5 || date.weekday == 6;

    final filteredIds = state.filteredTeam.map((e) => e.id).whereType<int>().toSet();
    final shiftsThisDay =
        state.effectiveMonthSchedule.values.where((shift) {
          final shiftDate = shift.weekStart.add(Duration(days: shift.dayIndex));
          return filteredIds.contains(shift.employeeId) && _sameDay(shiftDate, date);
        }).toList();

    // Bucket by ScheduleModel.summaryKind so off-type cells (day off, holiday,
    // planned/unplanned leave) are classified by their `note` sentinel instead
    // of falling through to the start-hour buckets — they carry
    // customStart == 0 and would otherwise all be counted as overnight.
    final counts = <String, int>{};
    for (final s in shiftsThisDay) {
      // Approved leave shows regardless of publish state; everything else is
      // part of the schedule and only counts once published.
      if (!s.isLeave && !s.isPublished) continue;
      final kind = s.summaryKind;
      counts[kind] = (counts[kind] ?? 0) + 1;
    }

    final overnight = counts['overnight'] ?? 0;
    final morning = counts['morning'] ?? 0;
    final afternoon = counts['afternoon'] ?? 0;
    final night = counts['night'] ?? 0;
    final leave = counts['leave'] ?? 0;
    final off = counts['off'] ?? 0;

    final total = state.filteredTeam.length;
    final staffed = overnight + morning + afternoon + night;
    final ratio = total == 0 ? 0.0 : staffed / total;
    final barColor =
        ratio >= 0.7
            ? SC.green
            : ratio > 0
            ? SC.amber
            : SC.rose;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          final bloc = context.read<ScheduleBloc>();
          final weekStart = SC.weekStartOf(date);
          final dayIndex = date.difference(weekStart).inDays.clamp(0, 6);
          bloc.add(ChangeView(ScheduleView.day, dayIndex: dayIndex));
          bloc.add(ChangeWeek(weekStart));
        },
        child: Container(
          decoration: BoxDecoration(
            color:
                isWeekend && isCurrentMonth
                    ? const Color(0xFFFAFBFD)
                    : isCurrentMonth
                    ? Colors.white
                    : const Color(0xFFF3F4F6),
            border: Border.all(color: SC.lineColor2, width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date number
              Text(
                '${date.day}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color:
                      isToday
                          ? SC.blue
                          : isCurrentMonth
                          ? SC.ink
                          : SC.muted2,
                ),
              ),
              const SizedBox(height: 15),
              // Shift type summaries
              Expanded(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 15,
                    direction: Axis.vertical,
                    alignment: WrapAlignment.start,
                    children: [
                      if (overnight > 0)
                        _ShiftSummaryChip(
                          icon: '⊙',
                          label: '$overnight',
                          color: isCurrentMonth ? SC.orange : SC.muted2,
                        ),
                      if (morning > 0)
                        _ShiftSummaryChip(icon: '☀', label: '$morning', color: isCurrentMonth ? SC.blue : SC.muted2),
                      if (afternoon > 0)
                        _ShiftSummaryChip(icon: '◐', label: '$afternoon', color: isCurrentMonth ? SC.teal : SC.muted2),
                      if (night > 0)
                        _ShiftSummaryChip(icon: '☾', label: '$night', color: isCurrentMonth ? SC.purple : SC.muted2),
                      if (leave > 0)
                        _ShiftSummaryChip(icon: '⚐', label: '$leave', color: isCurrentMonth ? SC.rose : SC.muted2),
                      if (off > 0)
                        _ShiftSummaryChip(icon: '⊘', label: '$off', color: isCurrentMonth ? SC.slate : SC.muted2),
                    ],
                  ),
                ),
              ),
              // Heat bar
              if (isCurrentMonth && total > 0)
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: staffed > 0 ? barColor : SC.lineColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class _MonthGridSkeleton extends StatelessWidget {
  final int leadingEmpty;
  final int daysInMonth;

  const _MonthGridSkeleton({required this.leadingEmpty, required this.daysInMonth});

  @override
  Widget build(BuildContext context) {
    final total = leadingEmpty + daysInMonth;
    final trailing = (7 - (total % 7)) % 7;
    final cellCount = total + trailing;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      childAspectRatio: 1.1,
      children: List.generate(cellCount, (i) {
        final isCurrentMonth = i >= leadingEmpty && i < leadingEmpty + daysInMonth;
        return Container(
          decoration: BoxDecoration(
            color: isCurrentMonth ? const Color(0xFFE5E7EB) : const Color(0xFFF3F4F6),
            border: Border.all(color: SC.lineColor2, width: 0.5),
          ),
        );
      }),
    );
  }
}

class _MonthNavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  const _MonthNavBtn({required this.icon, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: disabled ? const Color(0xFFF3F4F6) : Colors.white,
            border: Border.all(color: disabled ? SC.lineColor2 : SC.lineColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: disabled ? SC.muted2 : SC.ink2),
        ),
      ),
    );
  }
}

class _ShiftSummaryChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;

  const _ShiftSummaryChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 20, height: 20, child: Text(icon, style: TextStyle(fontSize: 14, color: color))),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 14.5, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
