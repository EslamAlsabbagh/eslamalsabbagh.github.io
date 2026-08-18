import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_tokens.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';

const double _empColW = 220;
const double _hourW = 60.0;
const double _rowH = 56.0;
const double _headerH = 36.0;

class DailyTimelineView extends StatefulWidget {
  const DailyTimelineView({super.key});

  @override
  State<DailyTimelineView> createState() => _DailyTimelineViewState();
}

class _DailyTimelineViewState extends State<DailyTimelineView> {
  final _hScroll = ScrollController();

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access state from nearest BlocBuilder ancestor via InheritedWidget
    return _TimelineContent(hScroll: _hScroll);
  }
}

class _TimelineContent extends StatelessWidget {
  final ScrollController hScroll;
  const _TimelineContent({required this.hScroll});

  @override
  Widget build(BuildContext context) => const _TimelineScaffold();
}

/// Accepts ScheduleState directly so the parent can pass it in.
class DailyTimeline extends StatefulWidget {
  final ScheduleState state;
  const DailyTimeline({super.key, required this.state});

  @override
  State<DailyTimeline> createState() => _DailyTimelineState();
}

class _DailyTimelineState extends State<DailyTimeline> {
  int _selectedDay = 0;
  final _hScroll = ScrollController();
  TextDirection? _lastAppliedScrollDirection;
  bool _hScrollAttached = false;

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.state.selectedDayIndex != null) {
      _selectedDay = widget.state.selectedDayIndex!.clamp(0, 6);
    } else {
      final today = DateTime.now();
      final diff = today.difference(widget.state.weekStart).inDays;
      _selectedDay = diff.clamp(0, 6);
    }
  }

  @override
  void didUpdateWidget(DailyTimeline old) {
    super.didUpdateWidget(old);
    final newIdx = widget.state.selectedDayIndex;
    if (newIdx != null && newIdx != old.state.selectedDayIndex) {
      setState(() => _selectedDay = newIdx.clamp(0, 6));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final team = state.filteredTeam;
    final sortedTeam = [...team]..sort((a, b) {
      final sa = state.effectiveSchedule['${a.id}-$_selectedDay'];
      final sb = state.effectiveSchedule['${b.id}-$_selectedDay'];
      final ta = (sa != null && !sa.isLeave && !sa.isOffType) ? sa.customStart : double.infinity;
      final tb = (sb != null && !sb.isLeave && !sb.isOffType) ? sb.customStart : double.infinity;
      return ta.compareTo(tb);
    });
    final now = DateTime.now();
    final nowHour = now.hour + now.minute / 60.0;
    final nowFraction = nowHour / 24.0;
    final selectedDate = state.weekStart.add(Duration(days: _selectedDay));
    final isSelectedToday =
        selectedDate.year == now.year && selectedDate.month == now.month && selectedDate.day == now.day;

    // Status summary for the selected day. "On shift now" is a live concept, so
    // it only applies when the selected day is today — on past/future days every
    // employee is counted as Off. Ports the mobile classification
    // (live_now_mobile_view.dart) sourced from the selected day's column. `late`
    // has no punch data wired in yet, so it stays 0 — matching the mobile view.
    var onShiftCount = 0;
    var lateCount = 0;
    var offCount = 0;
    if (!isSelectedToday) {
      offCount = team.length;
    } else {
      for (final emp in team) {
        final shift = state.effectiveSchedule['${emp.id}-$_selectedDay'];
        if (shift == null || shift.isLeave || !shift.isPublished) {
          offCount++;
          continue;
        }
        final end = shift.customEnd < shift.customStart ? shift.customEnd + 24 : shift.customEnd;
        final adjustedNow = shift.customEnd < shift.customStart && nowHour < shift.customStart ? nowHour + 24 : nowHour;
        if (adjustedNow < shift.customStart || adjustedNow > end) {
          offCount++;
        } else {
          onShiftCount++;
        }
      }
    }
    final gridWidth = _empColW + 24 * _hourW;
    final localeTextDirection = Directionality.of(context);
    final employeeColumnOnEnd = localeTextDirection == TextDirection.rtl;
    _alignHorizontalScrollForDirection(localeTextDirection);

    // The widget may live inside a vertical SingleChildScrollView (unbounded
    // height). LayoutBuilder detects this; when infinite we derive an explicit
    // height from the viewport so Expanded children remain valid.
    return LayoutBuilder(
      builder: (context, constraints) {
        final availH =
            constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : (MediaQuery.sizeOf(context).height - 235).clamp(300.0, double.infinity);

        return SizedBox(
          height: availH,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DaySelector(
                weekStart: state.weekStart,
                selectedDay: _selectedDay,
                onSelect: (d) => setState(() => _selectedDay = d),
                onShiftCount: onShiftCount,
                lateCount: lateCount,
                offCount: offCount,
              ),
              const SizedBox(height: 8),
              // Expanded + Scrollbar keeps the scrollbar pinned to the bottom of the
              // viewport regardless of how many employees are listed.
              Expanded(
                child: Scrollbar(
                  controller: _hScroll,
                  thumbVisibility: _hScrollAttached,
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _hScroll,
                      child: SizedBox(
                        width: gridWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hour header — stays pinned at top while rows scroll vertically
                            Row(
                              children: [
                                if (!employeeColumnOnEnd)
                                  _EmployeeHeader(
                                    employeeCount: team.length,
                                    textDirection: localeTextDirection,
                                    columnOnEnd: employeeColumnOnEnd,
                                  ),
                                _HourHeader(),
                                if (employeeColumnOnEnd)
                                  _EmployeeHeader(
                                    employeeCount: team.length,
                                    textDirection: localeTextDirection,
                                    columnOnEnd: employeeColumnOnEnd,
                                  ),
                              ],
                            ),
                            // Employee rows scroll vertically; now-line overlays them
                            Expanded(
                              child: Stack(
                                children: [
                                  Scrollbar(
                                    thumbVisibility: false,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children:
                                            sortedTeam.asMap().entries.map((entry) {
                                              final idx = entry.key;
                                              final emp = entry.value;
                                              final key = '${emp.id}-$_selectedDay';
                                              final shift = state.effectiveSchedule[key];
                                              final rowLeaveType =
                                                  (shift != null && !shift.isLeave) ? state.leaveKeys[key] : null;
                                              final prevShift =
                                                  _selectedDay > 0
                                                      ? state.effectiveSchedule['${emp.id}-${_selectedDay - 1}']
                                                      : state.prevWeekLastDayOvernight[emp.id];
                                              final carryOver =
                                                  (prevShift != null &&
                                                          !prevShift.isLeave &&
                                                          prevShift.customEnd < prevShift.customStart)
                                                      ? prevShift
                                                      : null;
                                              return _TimelineRow(
                                                emp: emp,
                                                index: idx,
                                                shift: shift != null && !shift.isLeave ? shift : null,
                                                isLeave: shift?.isLeave ?? false,
                                                leaveType: rowLeaveType,
                                                carryOverShift: carryOver,
                                                employeeTextDirection: localeTextDirection,
                                                employeeColumnOnEnd: employeeColumnOnEnd,
                                              );
                                            }).toList(),
                                      ),
                                    ),
                                  ),
                                  // Now line — only shown when the selected day is today
                                  if (isSelectedToday)
                                    Positioned(
                                      top: 0,
                                      bottom: 0,
                                      left: (employeeColumnOnEnd ? 0 : _empColW) + nowFraction * 24 * _hourW,
                                      child: IgnorePointer(
                                        child: Container(
                                          width: 2,
                                          color: SC.rose,
                                          child: Align(
                                            alignment: Alignment.topCenter,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(color: SC.rose, shape: BoxShape.circle),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _alignHorizontalScrollForDirection(TextDirection textDirection) {
    if (_hScrollAttached && _lastAppliedScrollDirection == textDirection) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_hScroll.hasClients) return;

      final target =
          textDirection == TextDirection.rtl ? _hScroll.position.maxScrollExtent : _hScroll.position.minScrollExtent;
      if ((_hScroll.offset - target).abs() > 0.5) {
        _hScroll.jumpTo(target);
      }
      if (!_hScrollAttached || _lastAppliedScrollDirection != textDirection) {
        setState(() {
          _hScrollAttached = true;
          _lastAppliedScrollDirection = textDirection;
        });
      }
    });
  }
}

class _EmployeeHeader extends StatelessWidget {
  final int employeeCount;
  final TextDirection textDirection;
  final bool columnOnEnd;

  const _EmployeeHeader({required this.employeeCount, required this.textDirection, required this.columnOnEnd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _empColW,
      height: _headerH,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: SC.lineColor),
          left: columnOnEnd ? BorderSide(color: SC.lineColor) : BorderSide.none,
          right: columnOnEnd ? BorderSide.none : BorderSide(color: SC.lineColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Directionality(
        textDirection: textDirection,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            AppLocalizations.of(context)!.scheduleEmployeeColumn(employeeCount),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SC.muted, letterSpacing: 0.3),
          ),
        ),
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final DateTime weekStart;
  final int selectedDay;
  final ValueChanged<int> onSelect;
  final int onShiftCount;
  final int lateCount;
  final int offCount;

  const _DaySelector({
    required this.weekStart,
    required this.selectedDay,
    required this.onSelect,
    required this.onShiftCount,
    required this.lateCount,
    required this.offCount,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 44,
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: SC.lineColor))),
      child: Row(
        children: [
          ...List.generate(7, (d) {
            final date = weekStart.add(Duration(days: d));
            final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
            final isSelected = d == selectedDay;
            return Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => onSelect(d),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: isSelected ? SC.blue : Colors.transparent, width: 2)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          SC.localizedDayNames(AppLocalizations.of(context)!)[d],
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isSelected ? SC.blue : SC.muted,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                          ),
                        ),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isToday ? SC.blue : (isSelected ? SC.ink : SC.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(width: 8),
          _SummaryChip(color: MT.statusOn, bg: MT.statusOnBg, n: onShiftCount, label: l10n.mobileOnShiftNow),
          const SizedBox(width: 6),
          _SummaryChip(color: MT.statusLate, bg: MT.statusLateBg, n: lateCount, label: l10n.mobileLateNoPunch),
          const SizedBox(width: 6),
          _SummaryChip(color: MT.statusOff, bg: MT.statusOffBg, n: offCount, label: l10n.mobileOffShift),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Compact horizontal status chip for the daily day-selector row. Mirrors the
/// mobile `_StatusTile` palette but fits the 44px row height (dot + count +
/// label on a single line) rather than stacking a large number over a label.
class _SummaryChip extends StatelessWidget {
  final Color color;
  final Color bg;
  final int n;
  final String label;

  const _SummaryChip({required this.color, required this.bg, required this.n, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          Text('$n', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HourHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _headerH,
      child: Row(
        children: List.generate(24, (h) {
          return SizedBox(
            width: _hourW,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text('${h.toString().padLeft(2, '0')}:00', style: const TextStyle(fontSize: 10, color: SC.muted)),
            ),
          );
        }),
      ),
    );
  }
}

class LeavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = SC.rose50
          ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width + size.height, size.height), paint);

    final stripe =
        Paint()
          ..color = SC.rose.withValues(alpha: 0.15)
          ..strokeWidth = 6;
    for (double x = 0; x < size.width + size.height; x += 12) {
      if (x < size.height - 12) {
        canvas.drawLine(Offset(0, x + 12), Offset(size.height - x - 12, size.height - 1), stripe);
      }
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height - 1), stripe);
    }
  }

  @override
  bool shouldRepaint(LeavePainter old) => false;
}

class _TimelineRow extends StatelessWidget {
  final UserModel emp;
  final int index;
  final dynamic shift; // ScheduleModel or null
  final bool isLeave;
  final dynamic carryOverShift; // previous day's overnight shift tail, or null
  final String? leaveType;
  final TextDirection employeeTextDirection;
  final bool employeeColumnOnEnd;

  const _TimelineRow({
    required this.emp,
    required this.index,
    required this.shift,
    required this.isLeave,
    required this.employeeTextDirection,
    required this.employeeColumnOnEnd,
    this.carryOverShift,
    this.leaveType,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final rawName = emp.getLocalizedName(locale);
    final name = rawName.isNotEmpty ? rawName : '—';
    final color = SC.avatarColor(index);

    return Container(
      height: _rowH,
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: SC.lineColor2))),
      child: Row(
        children: [
          if (!employeeColumnOnEnd) _buildEmployeeCell(locale, name, color),
          // Timeline area — width is fixed; outer SingleChildScrollView handles horizontal scroll
          SizedBox(
            width: 24 * _hourW,
            height: _rowH,
            child: Stack(
              children: [
                // Grid lines
                Row(
                  children: List.generate(
                    24,
                    (h) => Container(
                      width: _hourW,
                      decoration: BoxDecoration(border: Border(right: BorderSide(color: SC.lineColor2, width: 0.5))),
                    ),
                  ),
                ),
                // Carryover tail from previous day's overnight shift
                if (carryOverShift != null)
                  Positioned(
                    left: 0,
                    width: (carryOverShift.customEnd / 24) * 24 * _hourW,
                    top: 8,
                    bottom: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: (!carryOverShift.isPublished) ? Colors.white : carryOverShift.shiftLightColor,
                        border:
                            (!carryOverShift.isPublished)
                                ? Border(
                                  right: BorderSide(color: SC.amber, width: 4),
                                  top: BorderSide(color: SC.amber, width: 1),
                                  bottom: BorderSide(color: SC.amber, width: 1),
                                )
                                : Border(
                                  right: BorderSide(color: carryOverShift.shiftColor, width: 4),
                                  top: BorderSide(color: carryOverShift.shiftColor, width: 1),
                                  bottom: BorderSide(color: carryOverShift.shiftColor, width: 1),
                                ),
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(4),
                          bottomRight: Radius.circular(4),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.scheduleCarryOverEnds(SC.fmtHour(carryOverShift.customEnd)),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: (!carryOverShift.isPublished) ? SC.amber : carryOverShift.shiftColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isLeave)
                  Positioned.fill(child: CustomPaint(painter: LeavePainter()))
                else if (shift != null)
                  Positioned(
                    left: (shift.customStart / 24) * 24 * _hourW,
                    width:
                        ((shift.customEnd > shift.customStart
                                ? shift.customEnd - shift.customStart
                                : shift.customEnd + 24 - shift.customStart) /
                            24) *
                        24 *
                        _hourW,
                    top: 8,
                    bottom: 8,
                    child: Builder(
                      builder: (context) {
                        final isDraft = !shift.isPublished && !shift.isLeave;
                        final textColor = isDraft ? SC.amber : shift.shiftColor;
                        return Container(
                          decoration: BoxDecoration(
                            color: isDraft ? Colors.white : shift.shiftLightColor,
                            border:
                                isDraft
                                    ? Border(
                                      left: BorderSide(color: SC.amber, width: 4),
                                      right: BorderSide(color: SC.amber, width: 4),
                                      top: BorderSide(color: SC.amber, width: 1),
                                      bottom: BorderSide(color: SC.amber, width: 1),
                                    )
                                    : Border(
                                      left: BorderSide(color: shift.shiftColor, width: 4),
                                      right: BorderSide(color: shift.shiftColor, width: 4),
                                      top: BorderSide(color: shift.shiftColor, width: 1),
                                      bottom: BorderSide(color: shift.shiftColor, width: 1),
                                    ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (shift.isOffType)
                                Directionality(
                                  textDirection: employeeTextDirection,
                                  child: Align(
                                    alignment: AlignmentDirectional.centerStart,
                                    child: Text(
                                      SC.localizedShiftLabel(AppLocalizations.of(context)!, shift),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                              else ...[
                                Text(
                                  SC.localizedTimeLabel(AppLocalizations.of(context)!, shift),
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor),
                                ),
                                Text(
                                  '${shift.hours.toStringAsFixed(1)}h',
                                  style: TextStyle(fontSize: 10, color: textColor),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                if (leaveType != null && !isLeave && shift != null)
                  Positioned.fill(child: Opacity(opacity: 0.5, child: CustomPaint(painter: LeavePainter()))),
              ],
            ),
          ),
          if (employeeColumnOnEnd) _buildEmployeeCell(locale, name, color),
        ],
      ),
    );
  }

  Widget _buildEmployeeCell(String locale, String name, Color color) {
    return Container(
      width: _empColW,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          left: employeeColumnOnEnd ? BorderSide(color: SC.lineColor) : BorderSide.none,
          right: employeeColumnOnEnd ? BorderSide.none : BorderSide(color: SC.lineColor),
        ),
      ),
      child: Directionality(
        textDirection: employeeTextDirection,
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: color,
              child: Text(
                SC.avatarInitials(name),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: SC.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    emp.getLocalizedDepartment(locale),
                    style: const TextStyle(fontSize: 10.5, color: SC.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Dummy scaffold kept for the _TimelineBody import chain
class _TimelineScaffold extends StatelessWidget {
  const _TimelineScaffold();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
