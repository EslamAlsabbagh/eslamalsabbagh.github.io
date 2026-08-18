import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/data/models/shift_swap_request_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/request_swap_dialog.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_tokens.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/widgets/mobile_avatar.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/widgets/mobile_card.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/widgets/mobile_section_header.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// My Schedule view: personal hours card, upcoming 14-day shifts, swap history.
class MyScheduleMobileView extends StatelessWidget {
  const MyScheduleMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final selfUser = state.selfUser;
        final userId = state.managerId;

        // Mirror the desktop SelfView guard — don't render until user is known.
        if (selfUser == null || userId == null) {
          return CustomScrollView(
            slivers: [
              SliverFillRemaining(
                child: Center(child: Text(l10n.scheduleLoading, style: const TextStyle(color: MT.text3, fontSize: 14))),
              ),
            ],
          );
        }

        // Build the next 14 days from the real current week, independent from
        // whichever week is open in the planner.
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final todayWeekStart = DateTime(today.year, today.month, today.day - (today.weekday % 7));
        final selfShifts = <({DateTime date, ScheduleModel? shift})>[];
        for (int offset = 0; offset < 14; offset++) {
          final date = todayDate.add(Duration(days: offset));
          final dayIdx = date.difference(todayWeekStart).inDays;
          final useNext = dayIdx >= 7;
          final localIdx = useNext ? dayIdx - 7 : dayIdx;
          final map = useNext ? state.nextWeekTodaySelfSchedule : state.todaySelfSchedule;
          final shift = map['$userId-$localIdx'];
          if (shift != null) {
            selfShifts.add((date: date, shift: shift));
          }
        }
        selfShifts.sort((a, b) => a.date.compareTo(b.date));

        // Week hours from the real current week self schedule.
        final weekHours = state.todaySelfSchedule.values.where((s) => !s.isLeave).fold<double>(0, (acc, s) {
          final dur = s.customEnd < s.customStart ? (24 - s.customStart + s.customEnd) : (s.customEnd - s.customStart);
          return acc + dur;
        });

        final upcoming = selfShifts;

        // Swap request lookup helpers — ported from self_view.dart
        final seen = <int?>{};
        final allSwapRequests =
            [
              ...state.mySwapRequests,
              ...state.incomingSwapRequests,
              ...state.acceptedIncomingSwapRequests,
              ...state.declinedSwapRequests,
              ...state.processedSwapRequests,
            ].where((r) => seen.add(r.id)).toList();

        final outgoingByShiftId = <int, List<ShiftSwapRequestModel>>{};
        for (final r in allSwapRequests) {
          if (r.requesterId == (selfUser.id ?? 0) && r.scheduleId != null) {
            outgoingByShiftId.putIfAbsent(r.scheduleId!, () => []).add(r);
          }
        }

        Map<int, ScheduleModel?> peersForDay(DateTime date) {
          final dayIdx = date.difference(todayWeekStart).inDays;
          final useNext = dayIdx >= 7;
          final idx = useNext ? dayIdx - 7 : dayIdx;
          final scheduleMap = useNext ? state.nextWeekTodayPeersSchedule : state.todayPeersSchedule;
          return {
            for (final p in state.peers)
              if (p.id != null) p.id!: scheduleMap['${p.id}-$idx'],
          };
        }

        bool hasOpenSwapOnDay(int? shiftId, DateTime date) {
          const openStatuses = {'awaiting_target', 'pending'};
          final outgoing =
              shiftId != null
                  ? (outgoingByShiftId[shiftId] ?? const <ShiftSwapRequestModel>[])
                  : const <ShiftSwapRequestModel>[];
          if (outgoing.any((r) => openStatuses.contains(r.status))) return true;
          return allSwapRequests.any((r) {
            if (r.targetEmployeeId != (selfUser.id ?? 0)) return false;
            if (!openStatuses.contains(r.status)) return false;
            if (r.scheduleWeekStart == null || r.targetScheduleDayIndex == null) return false;
            final targetDate = r.scheduleWeekStart!.add(Duration(days: r.targetScheduleDayIndex!));
            return _sameDay(targetDate, date);
          });
        }

        bool hasEligibleCandidates(ScheduleModel shift, Map<int, ScheduleModel?> peerSchedules) {
          final dept = selfUser.englishDepartment;
          return state.peers.any((u) {
            if (dept != null && u.englishDepartment != dept) return false;
            final s = peerSchedules[u.id];
            if (s == null) return false;
            if (s.isLeaveType) return false;
            return s.customStart != shift.customStart || s.customEnd != shift.customEnd;
          });
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: _WeekSummaryCard(
                  user: selfUser,
                  weekHours: weekHours.round(),
                  shiftCount: state.todaySelfSchedule.values.where((s) => !s.isLeave).length,
                  l10n: l10n,
                ),
              ),
            ),
            SliverToBoxAdapter(child: MobileSectionHeader(title: l10n.mobileUpcoming14Days)),
            SliverList(
              delegate: SliverChildBuilderDelegate((ctx, i) {
                final item = upcoming[i];
                final isToday = _sameDay(item.date, today);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: _UpcomingShiftRow(
                    date: item.date,
                    shift: item.shift,
                    isToday: isToday,
                    onTap: null,
                    onSwap:
                        (item.shift != null &&
                                !isToday &&
                                !item.shift!.isLeaveType &&
                                !hasOpenSwapOnDay(item.shift!.id, item.date) &&
                                hasEligibleCandidates(item.shift!, peersForDay(item.date)))
                            ? () => showRequestSwapBottomSheet(
                              ctx,
                              shift: item.shift!,
                              shiftDate: item.date,
                              teammates: state.peers,
                              peerSchedulesForDay: peersForDay(item.date),
                              currentUserId: selfUser.id ?? 0,
                              currentUser: selfUser,
                            )
                            : null,
                    l10n: l10n,
                  ),
                );
              }, childCount: upcoming.length),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Week summary card ────────────────────────────────────────────────────────

class _WeekSummaryCard extends StatelessWidget {
  final dynamic user;
  final int weekHours;
  final int shiftCount;
  final AppLocalizations l10n;

  const _WeekSummaryCard({required this.user, required this.weekHours, required this.shiftCount, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return MobileCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (user != null) MobileAvatar(employee: user, size: 44),
          if (user != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.mobileThisWeek,
                  style: const TextStyle(fontSize: 12, color: MT.text3, fontWeight: FontWeight.w600),
                ),
                Text(
                  l10n.mobileWeekHoursScheduled(weekHours),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: MT.text),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: MT.eveningBg, borderRadius: MT.br24),
            child: Text(
              '$shiftCount shifts',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MT.eveningText),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Upcoming shift row ────────────────────────────────────────────────────────

class _UpcomingShiftRow extends StatelessWidget {
  final DateTime date;
  final ScheduleModel? shift;
  final bool isToday;
  final VoidCallback? onTap;
  final VoidCallback? onSwap;
  final AppLocalizations l10n;

  const _UpcomingShiftRow({
    required this.date,
    required this.shift,
    required this.isToday,
    this.onTap,
    required this.onSwap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final months = SC.localizedMonthNames(l10n);
    final isWorking = shift != null && !shift!.isLeave && !shift!.isOffType;
    final kind = shift == null ? 'off' : shift!.summaryKind;
    final shiftStyle = MT.shiftStyle(kind);

    return MobileCard(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date column
            Container(
              width: 60,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isToday ? MT.brandBg : MT.hair2,
                borderRadius: const BorderRadiusDirectional.only(topStart: MT.r12, bottomStart: MT.r12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    SC.localizedDayFromWeekday(l10n, date.weekday),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isToday ? MT.brand : MT.text3,
                      letterSpacing: 0.6,
                    ),
                  ),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isToday ? MT.brand : MT.text,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    months[date.month],
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: MT.text3),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: shiftStyle.stripe, borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          shift == null
                              ? l10n.mobileDayOff
                              : shift!.isLeave
                              ? l10n.mobileOnLeave
                              : SC.localizedShiftLabel(l10n, shift!),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MT.text),
                        ),
                      ],
                    ),
                    if (shift != null && shift!.isLeave && shift!.leaveType != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: SC.rose50,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: SC.rose.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          SC.localizedLeaveType(l10n, shift!.leaveType),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SC.rose),
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      isWorking
                          ? '${SC.fmtHour(shift!.customStart)} – ${SC.fmtHour(shift!.customEnd)}'
                          : shift?.isLeave == true
                          ? l10n.mobileApprovedTimeOff
                          : l10n.mobileNoShiftScheduled,
                      style: const TextStyle(fontSize: 12, color: MT.text3),
                    ),
                    if (shift != null && !shift!.isLeave && shift!.leaveType != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: SC.rose50,
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: SC.rose.withValues(alpha: 0.35)),
                        ),
                        child: Text(
                          SC.localizedLeaveType(l10n, shift!.leaveType),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SC.rose),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Swap button for working shifts
            if (isWorking && onSwap != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: MT.brand),
                    shape: RoundedRectangleBorder(borderRadius: MT.br24),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onSwap,
                  child: Text(
                    l10n.scheduleSwapWith,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MT.brand),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
