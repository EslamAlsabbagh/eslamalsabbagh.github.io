import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/shift_modal.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_tokens.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/widgets/mobile_avatar.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Daily view: one day at a time, employees grouped by shift kind.
class DailyMobileView extends StatelessWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  const DailyMobileView({super.key, required this.selectedDay, required this.onDaySelected});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final weekStart = state.weekStart;
        final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
        final effectiveDay = days.any((d) => _sameDay(d, selectedDay)) ? selectedDay : weekStart;
        final dayIdx = effectiveDay.difference(weekStart).inDays;

        // Group filteredTeam by shift kind for the selected day
        final groups = <String, List<({UserModel user, ScheduleModel? shift})>>{
          'overnight': [],
          'morning': [],
          'afternoon': [],
          'night': [],
          'leave': [],
          'off': [],
        };
        for (final emp in state.filteredTeam) {
          final key = '${emp.id}-$dayIdx';
          final shift = state.effectiveSchedule[key];
          final kind = shift == null ? 'off' : shift.summaryKind;
          groups[kind]!.add((user: emp, shift: shift));
        }

        final groupOrder = ['overnight', 'morning', 'afternoon', 'night', 'leave', 'off'];
        final groupLabels = {
          'overnight': l10n.shiftOvernight,
          'morning': l10n.shiftMorning,
          'afternoon': l10n.shiftAfternoon,
          'night': l10n.shiftNight,
          'leave': l10n.mobileOnLeave,
          'off': l10n.mobileDayOff,
        };
        final groupIcons = {
          'overnight': Icons.bedtime_outlined,
          'morning': Icons.wb_sunny_outlined,
          'afternoon': Icons.wb_twilight_outlined,
          'night': Icons.nightlight_outlined,
          'leave': Icons.flag_outlined,
          'off': Icons.remove_circle_outline,
        };

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildDayNav(context, days, effectiveDay, l10n)),
            for (final kind in groupOrder)
              if (groups[kind]!.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _GroupHeader(
                    kind: kind,
                    label: groupLabels[kind]!,
                    icon: groupIcons[kind]!,
                    count: groups[kind]!.length,
                    shift: groups[kind]!.first.shift,
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final item = groups[kind]![i];
                    final key = '${item.user.id}-$dayIdx';
                    final effectiveShift = (item.shift?.isLeave == true) ? state.leaveBackups[key] : item.shift;
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                      child: _EmployeeKindRow(
                        user: item.user,
                        onTap: () => showShiftModal(ctx, keys: [key], existing: effectiveShift, employee: item.user),
                      ),
                    );
                  }, childCount: groups[kind]!.length),
                ),
              ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        );
      },
    );
  }

  Widget _buildDayNav(BuildContext ctx, List<DateTime> days, DateTime day, AppLocalizations l10n) {
    final isRtl = Directionality.of(ctx) == TextDirection.rtl;
    final months = SC.localizedMonthNames(l10n);
    final dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final curIdx = days.indexWhere((d) => _sameDay(d, day));

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          _NavBtn(
            icon: isRtl ? Icons.chevron_right : Icons.chevron_left,
            onTap: curIdx > 0 ? () => onDaySelected(days[curIdx - 1]) : null,
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  dayNames[day.weekday],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: MT.text3,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  '${months[day.month]} ${day.day}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MT.text),
                ),
              ],
            ),
          ),
          _NavBtn(
            icon: isRtl ? Icons.chevron_left : Icons.chevron_right,
            onTap: curIdx < days.length - 1 ? () => onDaySelected(days[curIdx + 1]) : null,
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Group header with shift time ────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  final String kind;
  final String label;
  final IconData icon;
  final int count;
  final ScheduleModel? shift;

  const _GroupHeader({
    required this.kind,
    required this.label,
    required this.icon,
    required this.count,
    required this.shift,
  });

  @override
  Widget build(BuildContext context) {
    final style = MT.shiftStyle(kind);
    final timeLabel =
        shift != null && !shift!.isLeave ? '${SC.fmtHour(shift!.customStart)} – ${SC.fmtHour(shift!.customEnd)}' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: style.bg, borderRadius: MT.br12),
            child: Icon(icon, size: 16, color: style.ink),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MT.text)),
          if (timeLabel.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(timeLabel, style: const TextStyle(fontSize: 12, color: MT.text3)),
          ],
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(color: MT.hair2, borderRadius: MT.br24),
            child: Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MT.text2)),
          ),
        ],
      ),
    );
  }
}

// ── Employee row (compact, no shift chip — kind is shown by the group) ──────

class _EmployeeKindRow extends StatelessWidget {
  final UserModel user;
  final VoidCallback onTap;

  const _EmployeeKindRow({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final name =
        user.getLocalizedNickname(locale)?.isNotEmpty == true
            ? user.getLocalizedNickname(locale)!
            : user.getLocalizedName(locale);
    final dept =
        locale == 'ar'
            ? (user.department ?? user.englishDepartment ?? '')
            : (user.englishDepartment ?? user.department ?? '');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: MT.bgCard, borderRadius: MT.br12, border: Border.all(color: MT.hair2)),
        child: Row(
          children: [
            MobileAvatar(employee: user, size: 32),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MT.text),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(dept, style: const TextStyle(fontSize: 11, color: MT.text3), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 14, color: MT.hair),
          ],
        ),
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
