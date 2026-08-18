import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/tutorial/tutorial_keys.dart';
import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_event.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/sheets/bulk_assign_sheet.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/request_swap_dialog.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/shift_modal.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_tokens.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/widgets/mobile_avatar.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/widgets/mobile_card.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/widgets/mobile_section_header.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/widgets/mobile_shift_chip.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WeeklyMobileView extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const WeeklyMobileView({super.key, required this.selectedDay, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final weekStart = state.weekStart;

        if (state.status == Status.loading) {
          return _WeeklyMobileSkeleton(weekStart: weekStart);
        }

        final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
        final today = DateTime.now();

        // Clamp selectedDay to current loaded week
        final effectiveDay = days.any((d) => _sameDay(d, selectedDay)) ? selectedDay : weekStart;
        final dayIdx = effectiveDay.difference(weekStart).inDays;
        final sortedTeam = [...state.filteredTeam]..sort((a, b) {
          final sa = state.effectiveSchedule['${a.id}-$dayIdx'];
          final sb = state.effectiveSchedule['${b.id}-$dayIdx'];
          final ta = (sa != null && !sa.isLeave && !sa.isOffType) ? sa.customStart : double.infinity;
          final tb = (sb != null && !sb.isLeave && !sb.isOffType) ? sb.customStart : double.infinity;
          return ta.compareTo(tb);
        });

        // Pinned N+1 comparison row data for the selected day.
        final pinnedKey = state.showPinnedManagerRow ? '${state.pinnedManager!.id}-$dayIdx' : null;
        final pinnedShift = pinnedKey != null ? state.pinnedManagerSchedule[pinnedKey] : null;
        final pinnedLeaveType =
            (pinnedKey != null && pinnedShift != null && !pinnedShift.isLeave)
                ? state.pinnedManagerLeaveKeys[pinnedKey]
                : null;
        // Team mode pins MY row: a day my manager is drafting shows the same
        // "reserved by your manager" badge as the colleagues-view self row.
        final pinnedReserved = state.viewMode != ScheduleViewMode.colleagues && state.reservedSelfDays.contains(dayIdx);

        return Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildWeekNav(context, state, l10n, weekStart)),
                  SliverToBoxAdapter(child: _buildStats(context, state, l10n)),
                  SliverToBoxAdapter(child: _buildDayChips(context, days, effectiveDay, today, l10n)),
                  SliverToBoxAdapter(
                    child: MobileSectionHeader(
                      title: '${l10n.scheduleTabWeekly} · ${_dayLabel(effectiveDay, l10n)}',
                      // Self-only users get the bulk action too — the sheet is
                      // locked to their own row (self-draft feature).
                      action:
                          ((state.viewMode == ScheduleViewMode.colleagues && !state.isSelfOnly) || state.isPastWeek)
                              ? null
                              : l10n.mobileBulkFillDay,
                      onAction:
                          ((state.viewMode == ScheduleViewMode.colleagues && !state.isSelfOnly) || state.isPastWeek)
                              ? null
                              : () => _openBulkAssign(context, state, presetDay: effectiveDay),
                    ),
                  ),
                  if (state.showPinnedManagerRow)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _EmployeeShiftRow(
                          employee: state.pinnedManager!,
                          shift: pinnedShift,
                          leaveType: pinnedLeaveType,
                          reserved: pinnedReserved,
                          // Team mode pins MY row: I can draft my own schedule
                          // here (my N+1 publishes). Reserved days (my manager is
                          // drafting) explain themselves. Colleagues mode pins my
                          // N+1 → read-only.
                          onTap:
                              pinnedReserved
                                  ? () => _showReservedSnack(context, l10n)
                                  : state.viewMode != ScheduleViewMode.colleagues &&
                                      !state.isPastWeek &&
                                      state.canSelfEdit(pinnedShift)
                                  ? () => _editShift(context, state, state.pinnedManager!, dayIdx, pinnedShift)
                                  : null,
                          showConflict: false,
                          pinned: true,
                          badge:
                              state.viewMode == ScheduleViewMode.colleagues
                                  ? l10n.schedulePinnedManagerBadge
                                  : l10n.schedulePinnedSelfBadge,
                        ),
                      ),
                    ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((ctx, i) {
                      final row = sortedTeam[i];
                      final key = '${row.id}-$dayIdx';
                      final shift = state.effectiveSchedule[key];
                      final leaveType = (shift != null && !shift.isLeave) ? state.leaveKeys[key] : null;
                      final isSelfRow = row.id == state.managerId;
                      final reserved = isSelfRow && state.reservedSelfDays.contains(dayIdx);
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _EmployeeShiftRow(
                          employee: row,
                          shift: shift,
                          leaveType: leaveType,
                          reserved: reserved,
                          onTap:
                              state.viewMode == ScheduleViewMode.colleagues
                                  // My own row: empty cells / my drafts open the
                                  // editor; reserved days explain themselves;
                                  // published shifts keep the swap sheet.
                                  ? reserved
                                      ? () => _showReservedSnack(ctx, l10n)
                                      : (isSelfRow && !state.isPastWeek && state.canSelfEdit(shift))
                                      ? () => _editShift(context, state, row, dayIdx, shift)
                                      : () => _showColleagueTapSheet(ctx, state, row, dayIdx, shift)
                                  : state.isPastWeek
                                  ? null
                                  : () => _editShift(context, state, row, dayIdx, shift),
                          showConflict: state.viewMode != ScheduleViewMode.colleagues,
                        ),
                      );
                    }, childCount: sortedTeam.length),
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 8)),
                ],
              ),
            ),
            // Managers in team mode, and self-only users (sheet locked to their
            // own row — self-draft feature). Self-only users also get a
            // self-scoped "copy last week" action here (managers have theirs
            // in the More tab).
            if (state.viewMode != ScheduleViewMode.colleagues || state.isSelfOnly)
              Container(
                key: TutorialKeys.schMobileBulkAssign,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(color: MT.bgCard, border: Border(top: BorderSide(color: MT.hair))),
                child: Row(
                  children: [
                    if (state.isSelfOnly) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: MT.brand,
                            minimumSize: const Size.fromHeight(48),
                            side: BorderSide(color: MT.brand.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: MT.br12),
                          ),
                          icon: const Icon(Icons.copy_outlined, size: 18),
                          label: Text(l10n.scheduleCopyLastWeek, style: const TextStyle(fontWeight: FontWeight.w700)),
                          onPressed:
                              state.isPastWeek || !state.canSelfCopyLastWeek
                                  ? null
                                  : () => _confirmSelfCopyLastWeek(context, l10n),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: MT.brand,
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(borderRadius: MT.br12),
                        ),
                        icon: const Icon(Icons.calendar_month_outlined, size: 18),
                        label: Text(l10n.mobileBulkAssignShifts, style: const TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: state.isPastWeek ? null : () => _openBulkAssign(context, state),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildWeekNav(BuildContext ctx, ScheduleState state, AppLocalizations l10n, DateTime weekStart) {
    final isRtl = Directionality.of(ctx) == TextDirection.rtl;
    final isBusy = state.status == Status.loading || state.publishState == PublishState.publishing;
    return Padding(
      key: TutorialKeys.schMobileWeekNav,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          _NavButton(
            icon: isRtl ? Icons.chevron_right : Icons.chevron_left,
            onTap:
                isBusy
                    ? null
                    : () => ctx.read<ScheduleBloc>().add(ChangeWeek(weekStart.subtract(const Duration(days: 7)))),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  SC.localizedWeekLabel(l10n, weekStart),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MT.text),
                ),
                Text('Wk ${SC.weekNumber(weekStart)}', style: const TextStyle(fontSize: 11, color: MT.text3)),
              ],
            ),
          ),
          _NavButton(
            icon: isRtl ? Icons.chevron_left : Icons.chevron_right,
            onTap:
                isBusy ? null : () => ctx.read<ScheduleBloc>().add(ChangeWeek(weekStart.add(const Duration(days: 7)))),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext ctx, ScheduleState state, AppLocalizations l10n) {
    final filteredIdStrs = state.filteredTeam.map((e) => e.id?.toString()).whereType<String>().toSet();
    final scheduled =
        state.effectiveSchedule.keys.map((k) => k.split('-').first).where(filteredIdStrs.contains).toSet().length;
    final total = state.filteredTeam.length;
    final shiftCount =
        state.effectiveSchedule.values
            .where((s) => !s.isLeave && state.filteredTeam.any((u) => u.id == s.employeeId))
            .length;
    final hoursTotal = shiftCount * 8;
    final isColleagues = state.viewMode == ScheduleViewMode.colleagues;
    final conflicts =
        state.effectiveSchedule.values
            .where((s) => s.conflict != null && state.filteredTeam.any((u) => u.id == s.employeeId))
            .length;
    final drafts =
        state.effectiveSchedule.values
            .where((s) => !s.isPublished && !s.isLeave && state.filteredTeam.any((u) => u.id == s.employeeId))
            .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 2.4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        key: TutorialKeys.schMobileStats,
        children: [
          _StatTile(
            icon: Icons.people_outline,
            color: MT.morningStripe,
            bg: MT.morningBg,
            label: l10n.mobileStatPeople,
            value: '$scheduled',
            sub: l10n.mobileStatOfTotal(total),
          ),
          _StatTile(
            icon: Icons.access_time_outlined,
            color: MT.eveningStripe,
            bg: MT.eveningBg,
            label: l10n.mobileStatShifts,
            value: '$shiftCount',
            sub: l10n.mobileStatHoursTotal(hoursTotal),
          ),
          if (!isColleagues) ...[
            _StatTile(
              icon: Icons.warning_amber_outlined,
              color: const Color(0xFF9A6A00),
              bg: const Color(0xFFFFF3D6),
              label: l10n.mobileStatConflicts,
              value: '$conflicts',
              sub: conflicts == 0 ? l10n.mobileStatAllClear : '$conflicts conflicts',
            ),
            _StatTile(
              icon: Icons.notifications_outlined,
              color: MT.nightStripe,
              bg: MT.nightBg,
              label: l10n.mobileStatUnpublished,
              value: '$drafts',
              sub: drafts == 0 ? l10n.mobileStatAllPublished : '$drafts drafts',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayChips(
    BuildContext ctx,
    List<DateTime> days,
    DateTime selected,
    DateTime today,
    AppLocalizations l10n,
  ) {
    final dayNames = SC.localizedDayNames(l10n);
    return SizedBox(
      key: TutorialKeys.schMobileDayPicker,
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final day = days[i];
          final isSelected = _sameDay(day, selected);
          final isToday = _sameDay(day, today);
          final dayName = dayNames[day.weekday % 7];
          return GestureDetector(
            onTap: () => onDaySelected(day),
            child: Container(
              width: 52,
              decoration: BoxDecoration(
                color: isSelected ? MT.brand : MT.bgCard,
                borderRadius: MT.br12,
                border: Border.all(
                  color: isSelected ? MT.brand : (isToday ? MT.brand.withValues(alpha: 0.5) : MT.hair),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white.withValues(alpha: 0.8) : MT.text3,
                    ),
                  ),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : MT.text,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _openBulkAssign(BuildContext ctx, ScheduleState state, {DateTime? presetDay}) {
    final presetIdx = presetDay?.difference(state.weekStart).inDays.clamp(0, 6);
    showBulkAssignSheet(ctx, presetDayIndex: presetIdx);
  }

  void _editShift(BuildContext ctx, ScheduleState state, UserModel employee, int dayIdx, ScheduleModel? existing) {
    final key = '${employee.id}-$dayIdx';
    final effectiveShift = (existing?.isLeave == true) ? state.leaveBackups[key] : existing;
    showShiftBottomSheet(ctx, keys: [key], existing: effectiveShift, employee: employee);
  }

  Future<void> _confirmSelfCopyLastWeek(BuildContext ctx, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder:
          (dCtx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: MT.br12),
            title: Text(
              l10n.scheduleCopyDialogTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            content: Text(l10n.scheduleCopyNote, style: const TextStyle(fontSize: 13, color: MT.text2)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dCtx, false), child: Text(l10n.cancel)),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: MT.brand),
                onPressed: () => Navigator.pop(dCtx, true),
                child: Text(l10n.scheduleCopyButton),
              ),
            ],
          ),
    );
    if (confirmed == true && ctx.mounted) {
      ctx.read<ScheduleBloc>().add(const CopyLastWeek());
    }
  }

  void _showReservedSnack(BuildContext ctx, AppLocalizations l10n) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(l10n.scheduleReservedByManager),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showColleagueTapSheet(BuildContext ctx, ScheduleState state, UserModel emp, int dayIdx, ScheduleModel? shift) {
    final isSelf = emp.id == state.managerId;
    final shiftDate = state.weekStart.add(Duration(days: dayIdx));
    final l10n = AppLocalizations.of(ctx)!;

    if (isSelf) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(l10n.scheduleSelectOtherShiftsToSwap),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final shiftDay = DateTime(shiftDate.year, shiftDate.month, shiftDate.day);
    if (!shiftDay.isAfter(todayDate)) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(l10n.scheduleSwapPastDay),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (shift == null) return;

    final selfShift = state.selfSchedule['${state.managerId}-$dayIdx'];

    if (selfShift != null && selfShift.isLeaveType) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(l10n.scheduleSwapOnLeave),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Don't offer swap when colleague has the same shift times
    if (selfShift != null && shift.customStart == selfShift.customStart && shift.customEnd == selfShift.customEnd) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(l10n.scheduleSwapSameShift),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (state.hasOpenSwapOnDay(selfShift?.id, shiftDate)) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(l10n.scheduleSwapAlreadyPending),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (shift.isLeaveType) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(l10n.scheduleSwapColleagueOnLeave),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: ctx,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder:
          (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: Text(l10n.scheduleRequestSwap),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (selfShift == null) {
                      return;
                    }
                    final peerSchedulesForDay = {
                      for (final p in state.peers)
                        if (p.id != null) p.id!: state.peersSchedule['${p.id}-$dayIdx'],
                    };
                    showRequestSwapBottomSheet(
                      ctx,
                      shift: selfShift,
                      shiftDate: shiftDate,
                      teammates: state.peers,
                      peerSchedulesForDay: peerSchedulesForDay,
                      currentUserId: state.managerId!,
                      currentUser: state.selfUser!,
                      preSelectedColleagueId: emp.id,
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
  }

  String _dayLabel(DateTime day, AppLocalizations l10n) {
    final months = SC.localizedMonthNames(l10n);
    return '${SC.localizedDayFromWeekday(l10n, day.weekday)} ${day.day} ${months[day.month]}';
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Employee row card ──────────────────────────────────────────────────────

class _EmployeeShiftRow extends StatelessWidget {
  final UserModel employee;
  final ScheduleModel? shift;
  final String? leaveType;
  final VoidCallback? onTap;
  final bool showConflict;
  // Day occupied by a draft my manager owns — neutral placeholder chip,
  // contents stay manager-internal.
  final bool reserved;
  // Pinned N+1 comparison row: tinted background + a small badge, read-only.
  final bool pinned;
  final String? badge;

  const _EmployeeShiftRow({
    required this.employee,
    required this.shift,
    this.leaveType,
    this.onTap,
    this.showConflict = true,
    this.reserved = false,
    this.pinned = false,
    this.badge,
  });

  // Indigo-50 tint / indigo-600 accent, matching the desktop pinned row.
  static const Color _pinnedBg = Color(0xFFEEF2FF);
  static const Color _pinnedAccent = Color(0xFF4F46E5);

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final name =
        employee.getLocalizedNickname(locale)?.isNotEmpty == true
            ? employee.getLocalizedNickname(locale)!
            : employee.getLocalizedName(locale);
    final dept =
        locale == 'ar'
            ? (employee.department ?? employee.englishDepartment ?? '')
            : (employee.englishDepartment ?? employee.department ?? '');

    return MobileCard(
      onTap: onTap,
      color: pinned ? _pinnedBg : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          MobileAvatar(employee: employee, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: MT.text),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (pinned && badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: _pinnedAccent, borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          badge!,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(dept, style: const TextStyle(fontSize: 11, color: MT.text3), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (reserved && shift == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: MT.hair),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 12, color: MT.text3),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.scheduleReservedByManager,
                    style: const TextStyle(fontSize: 10, color: MT.text3, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else
            MobileShiftChip(shift: shift, leaveType: leaveType, showConflict: showConflict),
        ],
      ),
    );
  }
}

// ── Stat tile ──────────────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  final String value;
  final String sub;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.bg,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return MobileCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: bg, borderRadius: MT.br12),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: MT.text3, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: MT.text)),
                Text(sub, style: const TextStyle(fontSize: 10, color: MT.text3), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Nav button ─────────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _NavButton({required this.icon, this.onTap});

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

class _WeeklyMobileSkeleton extends StatelessWidget {
  final DateTime weekStart;
  const _WeeklyMobileSkeleton({required this.weekStart});

  @override
  Widget build(BuildContext context) {
    return _ShimmerProvider(
      builder:
          (opacity) => Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildNavSkeleton(context, opacity)),
                    SliverToBoxAdapter(child: _buildStatsSkeleton(opacity)),
                    SliverToBoxAdapter(child: _buildDayChipsSkeleton(opacity)),
                    SliverToBoxAdapter(child: _buildHeaderSkeleton(opacity)),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => _buildEmployeeRowSkeleton(opacity),
                        childCount: 7,
                      ),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 8)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                decoration: BoxDecoration(color: MT.bgCard, border: Border(top: BorderSide(color: MT.hair))),
                child: _sBox(double.infinity, 48, opacity * 0.5, radius: 12),
              ),
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
          _NavButton(icon: isRtl ? Icons.chevron_right : Icons.chevron_left),
          Expanded(
            child: Column(
              children: [_sBox(130, 14, opacity * 0.7), const SizedBox(height: 4), _sBox(50, 10, opacity * 0.5)],
            ),
          ),
          _NavButton(icon: isRtl ? Icons.chevron_left : Icons.chevron_right),
        ],
      ),
    );
  }

  Widget _buildStatsSkeleton(double opacity) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 2.4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: List.generate(
          4,
          (i) => Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: MT.bgCard, borderRadius: MT.br14, border: Border.all(color: MT.hair2)),
            child: Row(
              children: [
                _sBox(34, 34, opacity * 0.6, radius: 12),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _sBox(60, 8, opacity * 0.5),
                      const SizedBox(height: 4),
                      _sBox(40, 18, opacity * 0.9),
                      const SizedBox(height: 4),
                      _sBox(80, 8, opacity * 0.4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayChipsSkeleton(double opacity) {
    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, __) => _sBox(52, 52, opacity * 0.6, radius: 12),
      ),
    );
  }

  Widget _buildHeaderSkeleton(double opacity) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
      child: Row(children: [_sBox(160, 12, opacity * 0.7), const Spacer(), _sBox(60, 12, opacity * 0.5)]),
    );
  }

  Widget _buildEmployeeRowSkeleton(double opacity) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: MT.bgCard, borderRadius: MT.br14, border: Border.all(color: MT.hair2)),
        child: Row(
          children: [
            _sBox(36, 36, opacity * 0.7, radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [_sBox(120, 12, opacity * 0.8), const SizedBox(height: 4), _sBox(80, 10, opacity * 0.5)],
              ),
            ),
            _sBox(72, 34, opacity * 0.6, radius: 20),
          ],
        ),
      ),
    );
  }
}
