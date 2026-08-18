import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/data/models/shift_swap_request_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_event.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/request_swap_dialog.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelfView extends StatelessWidget {
  final ScheduleState state;
  final int currentUserId;
  const SelfView({super.key, required this.state, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    final user = state.selfUser ?? state.allTeam.where((u) => u.id == currentUserId).firstOrNull;
    if (user == null) {
      return Center(child: Text(AppLocalizations.of(context)!.scheduleNoData, style: const TextStyle(color: SC.muted)));
    }

    // final name = user.englishName ?? user.arabicName ?? '—';
    // final dept = user.englishDepartment ?? user.department ?? '';

    // Collect next 14 days of shifts from the real current week, independent
    // from the planner week currently selected.
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final todayWeekStart = DateTime(today.year, today.month, today.day - (today.weekday % 7));
    final nextWeekStart = todayWeekStart.add(const Duration(days: 7));
    final currentWeekScheduled = state.todaySelfSchedule.entries.any(
      (e) => e.key.startsWith('$currentUserId-') && e.value.isPublished && !e.value.isLeave,
    );
    final nextWeekScheduled = state.nextWeekTodaySelfSchedule.entries.any(
      (e) => e.key.startsWith('$currentUserId-') && e.value.isPublished && !e.value.isLeave,
    );
    final upcoming = <_UpcomingShift>[];
    for (int d = 0; d < 14; d++) {
      final date = todayDate.add(Duration(days: d));
      final dayIdx = date.difference(todayWeekStart).inDays;
      ScheduleModel? shift;
      if (dayIdx >= 0 && dayIdx <= 6) {
        final raw = state.todaySelfSchedule['$currentUserId-$dayIdx'];
        if (raw != null && (raw.isLeave || raw.isPublished)) shift = raw;
      } else {
        final nextDayIdx = date.difference(nextWeekStart).inDays;
        if (nextDayIdx >= 0 && nextDayIdx <= 6) {
          final raw = state.nextWeekTodaySelfSchedule['$currentUserId-$nextDayIdx'];
          if (raw != null && (raw.isLeave || raw.isPublished)) shift = raw;
        }
      }
      if (shift != null) {
        upcoming.add(_UpcomingShift(date: date, shift: shift));
      }
    }

    // Stats
    // final hoursThisWeek = state.selfSchedule.entries
    //     .where((e) => e.key.startsWith('$currentUserId-') && !e.value.isLeave && e.value.isPublished)
    //     .fold(0.0, (s, e) => s + e.value.hours);
    // final shiftsLeft =
    //     upcoming.where((u) {
    //       final diff = u.date.difference(today).inDays;
    //       return diff >= 0 && u.shift != null && !u.shift!.isLeave;
    //     }).length;
    // final leaveBalance = user.leaveBalance?.toStringAsFixed(1) ?? '—';
    // final openSwaps = state.mySwapRequests.length;

    // Swappable shifts for quick action picker (published, non-leave, today or future)
    // final swappableShifts =
    //     upcoming
    //         .where(
    //           (u) =>
    //               u.shift != null &&
    //               !u.shift!.isLeave &&
    //               !u.date.isBefore(DateTime(today.year, today.month, today.day)),
    //         )
    //         .map((u) => (u.date, u.shift!))
    //         .toList();

    final teammates = state.peers;

    // Peers' schedule lookup helpers
    Map<int, ScheduleModel?> peersForDay(DateTime date) {
      final dayIdx = date.difference(todayWeekStart).inDays;
      final useNext = dayIdx >= 7;
      final idx = useNext ? dayIdx - 7 : dayIdx;
      final scheduleMap = useNext ? state.nextWeekTodayPeersSchedule : state.todayPeersSchedule;
      return {for (final p in teammates) p.id!: scheduleMap['${p.id}-$idx']};
    }

    bool hasEligibleCandidates(ScheduleModel shift, Map<int, ScheduleModel?> peerSchedules) {
      final dept = user.englishDepartment;
      return teammates.any((u) {
        if (dept != null && u.englishDepartment != dept) return false;
        final s = peerSchedules[u.id];
        if (s == null) return false;
        if (s.isLeaveType) return false;
        return s.customStart != shift.customStart || s.customEnd != shift.customEnd;
      });
    }

    // Pre-build map keyed by date for the shift picker dialog
    // final peerSchedulesByDate = <DateTime, Map<int, ScheduleModel?>>{
    //   for (final entry in swappableShifts) DateTime(entry.$1.year, entry.$1.month, entry.$1.day): peersForDay(entry.$1),
    // };

    // Classify by role — outgoing = I am the requester, incoming = I am the target.
    // Merge + de-duplicate both lists so a request in the wrong list still renders correctly.
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
    final incomingByDate = <String, List<ShiftSwapRequestModel>>{};

    for (final r in allSwapRequests) {
      if (r.requesterId == currentUserId && r.scheduleId != null) {
        outgoingByShiftId.putIfAbsent(r.scheduleId!, () => []).add(r);
      } else if (r.targetEmployeeId == currentUserId && r.scheduleWeekStart != null && r.scheduleDayIndex != null) {
        final d = r.scheduleWeekStart!.add(Duration(days: r.scheduleDayIndex!));
        final key = '${d.year}-${d.month}-${d.day}';
        incomingByDate.putIfAbsent(key, () => []).add(r);
      }
    }

    bool hasOpenSwapOnDay(int? shiftId, DateTime date) {
      const openStatuses = {'awaiting_target', 'pending'};
      final outgoing =
          shiftId != null
              ? (outgoingByShiftId[shiftId] ?? const <ShiftSwapRequestModel>[])
              : const <ShiftSwapRequestModel>[];
      if (outgoing.any((r) => openStatuses.contains(r.status))) return true;
      return allSwapRequests.any((r) {
        if (r.targetEmployeeId != currentUserId) return false;
        if (!openStatuses.contains(r.status)) return false;
        if (r.scheduleWeekStart == null || r.targetScheduleDayIndex == null) return false;
        final targetShiftDate = r.scheduleWeekStart!.add(Duration(days: r.targetScheduleDayIndex!));
        return _sameDay(targetShiftDate, date);
      });
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // // ── Left panel ──────────────────────────────────────────────
          // SizedBox(
          //   width: 300,
          //   child: Padding(
          //     padding: const EdgeInsets.only(right: 16),
          //     child: Column(
          //       children: [
          //         _PersonalCard(
          //           name: name,
          //           dept: dept,
          //           avatarColor: SC.avatarColor(0),
          //           initials: SC.avatarInitials(name),
          //         ),
          //         const SizedBox(height: 12),
          //         _StatsGrid(
          //           hoursThisWeek: hoursThisWeek,
          //           shiftsLeft: shiftsLeft,
          //           leaveBalance: leaveBalance,
          //           openSwaps: openSwaps,
          //         ),
          //         const SizedBox(height: 12),
          //         _QuickActionsCard(
          //           onRequestSwap:
          //               swappableShifts.isEmpty
          //                   ? null
          //                   : () => showShiftPickerDialog(
          //                     context,
          //                     swappableShifts: swappableShifts,
          //                     teammates: teammates,
          //                     peerSchedulesByDate: peerSchedulesByDate,
          //                     currentUserId: currentUserId,
          //                   ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          // ── Right panel ─────────────────────────────────────────────
          SizedBox(
            width: context.screenWidth > 660 ? context.screenWidth - 100 : 660,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppLocalizations.of(context)!.scheduleUpcomingShifts,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: SC.ink),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    for (int i = 0; i < upcoming.length; i++) ...[
                      _ShiftRow(
                        upcoming: upcoming[i],
                        isToday: _sameDay(upcoming[i].date, today),
                        weekIsScheduled:
                            upcoming[i].date.difference(todayWeekStart).inDays < 7
                                ? currentWeekScheduled
                                : nextWeekScheduled,
                        onRequestSwap:
                            (upcoming[i].shift != null &&
                                    !upcoming[i].shift!.isLeaveType &&
                                    !_sameDay(upcoming[i].date, today) &&
                                    !hasOpenSwapOnDay(upcoming[i].shift!.id, upcoming[i].date) &&
                                    hasEligibleCandidates(upcoming[i].shift!, peersForDay(upcoming[i].date)))
                                ? () => showRequestSwapDialog(
                                  context,
                                  shift: upcoming[i].shift!,
                                  shiftDate: upcoming[i].date,
                                  teammates: teammates,
                                  peerSchedulesForDay: peersForDay(upcoming[i].date),
                                  currentUserId: currentUserId,
                                  currentUser: user,
                                )
                                : null,
                        outgoingRequests: outgoingByShiftId[upcoming[i].shift?.id] ?? const [],
                        incomingRequests:
                            incomingByDate['${upcoming[i].date.year}-${upcoming[i].date.month}-${upcoming[i].date.day}'] ??
                            const [],
                        onAccept: (id) => context.read<ScheduleBloc>().add(AcceptSwapAsTarget(id)),
                        onDecline: (id) => context.read<ScheduleBloc>().add(DeclineSwapAsTarget(id)),
                        onCancel: (id) => context.read<ScheduleBloc>().add(CancelSwapRequest(id)),
                      ),
                      if (i < upcoming.length - 1) const SizedBox(height: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

/*
class _PersonalCard extends StatelessWidget {
  final String name;
  final String dept;
  final Color avatarColor;
  final String initials;

  const _PersonalCard({required this.name, required this.dept, required this.avatarColor, required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SC.lineColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: avatarColor,
            child: Text(
              initials,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            name,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SC.ink),
            textAlign: TextAlign.center,
          ),
          Text(dept, style: const TextStyle(fontSize: 12, color: SC.muted), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _ClockBtn(label: 'Clock In', color: SC.green, icon: Icons.login)),
              const SizedBox(width: 8),
              Expanded(child: _ClockBtn(label: 'Clock Out', color: SC.rose, icon: Icons.logout)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClockBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _ClockBtn({required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final double hoursThisWeek;
  final int shiftsLeft;
  final String leaveBalance;
  final int openSwaps;

  const _StatsGrid({
    required this.hoursThisWeek,
    required this.shiftsLeft,
    required this.leaveBalance,
    required this.openSwaps,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _StatItem(label: 'Hours this week', value: '${hoursThisWeek.toStringAsFixed(0)}h', color: SC.blue),
      _StatItem(label: 'Shifts left', value: '$shiftsLeft', color: SC.teal),
      _StatItem(label: 'Leave balance', value: leaveBalance, color: SC.green),
      _StatItem(label: 'Open swap requests', value: '$openSwaps', color: SC.amber),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.0,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: items.map((s) => _StatCard(item: s)).toList(),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});
}

class _StatCard extends StatelessWidget {
  final _StatItem item;
  const _StatCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SC.lineColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: item.color),
          ),
          Text(item.label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: SC.muted)),
        ],
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final VoidCallback? onRequestSwap;

  const _QuickActionsCard({this.onRequestSwap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SC.lineColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: SC.ink)),
          const SizedBox(height: 10),
          _ActionRow(label: 'Request leave', icon: Icons.beach_access_outlined, onTap: () {}),
          _ActionRow(label: 'Request shift swap', icon: Icons.swap_horiz, onTap: onRequestSwap),
          _ActionRow(label: 'Report missing punch', icon: Icons.fingerprint, onTap: () {}),
          _ActionRow(label: 'Export to calendar', icon: Icons.calendar_today_outlined, onTap: () {}),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _ActionRow({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(border: Border.all(color: SC.lineColor), borderRadius: BorderRadius.circular(7)),
            child: Row(
              children: [
                Icon(icon, size: 15, color: disabled ? SC.muted2 : SC.blue),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(fontSize: 12.5, color: disabled ? SC.muted2 : SC.ink2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
*/

class _UpcomingShift {
  final DateTime date;
  final ScheduleModel? shift;
  const _UpcomingShift({required this.date, required this.shift});
}

class _ShiftRow extends StatelessWidget {
  final _UpcomingShift upcoming;
  final bool isToday;
  final bool weekIsScheduled;
  final VoidCallback? onRequestSwap;
  final List<ShiftSwapRequestModel> outgoingRequests;
  final List<ShiftSwapRequestModel> incomingRequests;
  final void Function(int id) onAccept;
  final void Function(int id) onDecline;
  final void Function(int id) onCancel;

  const _ShiftRow({
    required this.upcoming,
    required this.isToday,
    required this.weekIsScheduled,
    this.onRequestSwap,
    this.outgoingRequests = const [],
    this.incomingRequests = const [],
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final date = upcoming.date;
    final shift = upcoming.shift;
    final l10n = AppLocalizations.of(context)!;
    final dayName = SC.localizedDayFromWeekday(l10n, date.weekday);
    final months = SC.localizedMonthNames(l10n);
    final hasSubRows = outgoingRequests.isNotEmpty || incomingRequests.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: isToday ? SC.blue50 : Colors.white,
        border: Border.all(color: isToday ? SC.blue.withValues(alpha: 0.4) : SC.lineColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // ── Main shift row ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Column(
                    children: [
                      Text(
                        dayName,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: isToday ? SC.blue : SC.muted,
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isToday ? SC.blue : SC.ink,
                          height: 1.1,
                        ),
                      ),
                      Text(months[date.month], style: const TextStyle(fontSize: 10, color: SC.muted)),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: SC.lineColor,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child:
                      shift == null || shift.isLeave
                          ? shift != null
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.mobileOnLeave,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SC.rose),
                                  ),
                                  if (shift.leaveType != null) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: SC.rose50,
                                        borderRadius: BorderRadius.circular(3),
                                        border: Border.all(color: SC.rose.withValues(alpha: 0.35)),
                                      ),
                                      child: Text(
                                        SC.localizedLeaveType(l10n, shift.leaveType),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: SC.rose,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              )
                              : Text(
                                weekIsScheduled ? l10n.scheduleDayOff : l10n.scheduleNotAssigned,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, color: SC.muted2),
                              )
                          : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                SC.localizedShiftLabel(AppLocalizations.of(context)!, shift),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SC.ink),
                              ),
                              Text(
                                SC.localizedTimeLabel(AppLocalizations.of(context)!, shift),
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11.5, color: SC.muted),
                              ),
                              if (shift.leaveType != null) ...[
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: SC.rose50,
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(color: SC.rose.withValues(alpha: 0.35)),
                                  ),
                                  child: Text(
                                    SC.localizedLeaveType(l10n, shift.leaveType),
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: SC.rose),
                                  ),
                                ),
                              ],
                            ],
                          ),
                ),
                if (onRequestSwap != null)
                  Flexible(
                    flex: 0,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: onRequestSwap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: SC.blue.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.scheduleRequestSwap,
                            style: const TextStyle(fontSize: 11, color: SC.blue, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // ── Sub-rows ────────────────────────────────────────────────
          if (hasSubRows) ...[
            Divider(height: 1, color: SC.lineColor.withValues(alpha: 0.7)),
            for (final r in outgoingRequests) _SwapSubRow.outgoing(request: r, onCancel: onCancel),
            for (final r in incomingRequests)
              _SwapSubRow.incoming(request: r, onAccept: onAccept, onDecline: onDecline),
          ],
        ],
      ),
    );
  }
}

class _SwapSubRow extends StatelessWidget {
  final ShiftSwapRequestModel request;
  final bool isIncoming;
  final void Function(int id)? onAccept;
  final void Function(int id)? onDecline;
  final void Function(int id)? onCancel;

  const _SwapSubRow.outgoing({required this.request, required void Function(int id) this.onCancel})
    : isIncoming = false,
      onAccept = null,
      onDecline = null;

  const _SwapSubRow.incoming({
    required this.request,
    required void Function(int id) this.onAccept,
    required void Function(int id) this.onDecline,
  }) : isIncoming = true,
       onCancel = null;

  bool get _showTimeChip => request.status == 'awaiting_target' || request.status == 'pending';

  String _contextLabel(AppLocalizations l10n) {
    if (isIncoming) {
      return switch (request.status) {
        'awaiting_target' => l10n.scheduleSwapWantsToSwap,
        'pending' => l10n.scheduleSwapAwaitingManagerApproval,
        'approved' => l10n.scheduleSwapCompleted,
        'declined' => l10n.scheduleSwapDeclined,
        'cancelled' => l10n.scheduleSwapCancelledByRequester,
        _ => '',
      };
    } else {
      return switch (request.status) {
        'awaiting_target' => l10n.scheduleSwapAwaitingColleague,
        'pending' => l10n.scheduleSwapAwaitingManager,
        'approved' => l10n.scheduleSwapCompleted,
        'declined' => l10n.scheduleSwapRequestDeclined,
        'cancelled' => l10n.scheduleSwapYouCancelled,
        _ => '',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final accentColor = isIncoming ? SC.amber : SC.blue;
    final name =
        isIncoming
            ? ((isArabic ? request.requesterArabicName : request.requesterEnglishName) ??
                (isArabic ? request.requesterEnglishName : request.requesterArabicName) ??
                'Employee #${request.requesterId}')
            : ((isArabic ? request.targetArabicName : request.targetEnglishName) ??
                (isArabic ? request.targetEnglishName : request.targetArabicName) ??
                'Employee #${request.targetEmployeeId}');
    final avatarIndex = isIncoming ? request.requesterId % 9 : (request.targetEmployeeId ?? 0) % 9;
    final timeLabel =
        (request.scheduleStart != null && request.scheduleEnd != null)
            ? '${SC.fmtHour(request.scheduleStart!)} – ${SC.fmtHour(request.scheduleEnd!)}'
            : null;

    Widget trailing;
    if (isIncoming) {
      final status = request.status;
      if (status == 'awaiting_target') {
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ActionBtn(label: l10n.approve, color: SC.green, onTap: () => onAccept!(request.id!)),
            const SizedBox(width: 6),
            _ActionBtn(label: l10n.decline, color: SC.rose, onTap: () => onDecline!(request.id!)),
          ],
        );
      } else {
        final (label, color) = switch (status) {
          'pending' => (l10n.scheduleAwaitingManagerBadge, SC.amber),
          'approved' => (l10n.scheduleStatusApproved, SC.green),
          'cancelled' => (l10n.scheduleStatusCancelled, SC.muted2),
          _ => (l10n.scheduleStatusDeclined, SC.rose),
        };
        trailing = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        );
      }
    } else {
      final status = request.status;
      if (status == 'approved' || status == 'declined' || status == 'cancelled') {
        final color =
            status == 'approved'
                ? SC.green
                : status == 'cancelled'
                ? SC.muted2
                : SC.rose;
        final label =
            status == 'approved'
                ? l10n.scheduleStatusApproved
                : status == 'cancelled'
                ? l10n.scheduleStatusCancelled
                : l10n.scheduleStatusDeclined;
        trailing = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        );
      } else {
        final isAwaitingTarget = status == 'awaiting_target';
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: isAwaitingTarget ? SC.amber50 : SC.blue50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isAwaitingTarget ? l10n.scheduleAwaitingColleagueBadge : l10n.scheduleAwaitingManagerBadge,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: accentColor),
              ),
            ),
            const SizedBox(width: 6),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onCancel!(request.id!),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: SC.rose.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    l10n.cancel,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: SC.rose),
                  ),
                ),
              ),
            ),
          ],
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        children: [
          // Indent to align with shift info (date block 44 + divider 1 + margin 12 = 57)
          SizedBox(
            width: 57,
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(Icons.swap_horiz_rounded, size: 18, color: accentColor),
            ),
          ),
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 12,
            backgroundColor: SC.avatarColor(avatarIndex),
            child: Text(
              SC.avatarInitials(name),
              style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: SC.ink),
                  overflow: TextOverflow.ellipsis,
                ),
                if (_showTimeChip) ...[
                  if (isIncoming && timeLabel != null) ...[
                    const SizedBox(height: 3),
                    _TimeChip(
                      label: timeLabel,
                      color: SC.shiftColor(request.scheduleStart!),
                      bgColor: SC.shiftLightColor(request.scheduleStart!),
                    ),
                  ],
                  if (!isIncoming && timeLabel != null) ...[
                    const SizedBox(height: 3),
                    if (request.targetScheduleStart != null && request.targetScheduleEnd != null)
                      _TimeChip(
                        label:
                            '→  ${SC.fmtHour(request.targetScheduleStart!)} – ${SC.fmtHour(request.targetScheduleEnd!)}',
                        color: SC.shiftColor(request.targetScheduleStart!),
                        bgColor: SC.shiftLightColor(request.targetScheduleStart!),
                      )
                    else
                      _TimeChip(
                        label: timeLabel,
                        color: SC.shiftColor(request.scheduleStart!),
                        bgColor: SC.shiftLightColor(request.scheduleStart!),
                      ),
                  ],
                ],
                if (request.reason != null && request.reason!.isNotEmpty)
                  Text(
                    '"${request.reason}"',
                    style: const TextStyle(fontSize: 10.5, color: SC.muted2, fontStyle: FontStyle.italic),
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 2),
                Text(
                  _contextLabel(l10n),
                  style: const TextStyle(fontSize: 10.5, color: SC.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _TimeChip({required this.label, required this.color, required this.bgColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(5)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ),
      ),
    );
  }
}
