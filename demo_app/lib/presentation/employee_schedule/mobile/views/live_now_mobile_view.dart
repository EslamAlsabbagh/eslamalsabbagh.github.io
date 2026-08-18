import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_tokens.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/widgets/mobile_avatar.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/widgets/mobile_card.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/widgets/mobile_section_header.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// On-Shift-Now mobile view: 3 status tiles + employee cards by status.
class LiveNowMobileView extends StatelessWidget {
  const LiveNowMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final now = DateTime.now();
        final nowHour = now.hour + now.minute / 60.0;

        // Classify each member in filteredTeam against the real current week,
        // independent from whichever week is open in the planner.
        final todayWeekStart = DateTime(now.year, now.month, now.day - (now.weekday % 7));
        final dayIdx = DateTime(now.year, now.month, now.day).difference(todayWeekStart).inDays;
        final onShift = <({UserModel user, ScheduleModel? shift})>[];
        final late = <({UserModel user, ScheduleModel? shift})>[];
        final off = <({UserModel user, ScheduleModel? shift})>[];

        for (final emp in state.filteredTeam) {
          final key = '${emp.id}-$dayIdx';
          final shift = state.effectiveTodaySchedule[key];

          if (shift == null) {
            off.add((user: emp, shift: null));
            continue;
          }

          if (shift.isLeave || !shift.isPublished) {
            off.add((user: emp, shift: shift.isLeave ? shift : null));
            continue;
          }

          final end = shift.customEnd < shift.customStart ? shift.customEnd + 24 : shift.customEnd;
          final adjustedNow =
              shift.customEnd < shift.customStart && nowHour < shift.customStart ? nowHour + 24 : nowHour;

          if (adjustedNow < shift.customStart || adjustedNow > end) {
            off.add((user: emp, shift: shift));
          } else {
            // Within shift window - mark late if no clock-in data (simplified)
            onShift.add((user: emp, shift: shift));
          }
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _StatusTile(
                        color: MT.statusOn,
                        bg: MT.statusOnBg,
                        n: onShift.length,
                        label: l10n.mobileOnShiftNow,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatusTile(
                        color: MT.statusLate,
                        bg: MT.statusLateBg,
                        n: late.length,
                        label: l10n.mobileLateNoPunch,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatusTile(
                        color: MT.statusOff,
                        bg: MT.statusOffBg,
                        n: off.length,
                        label: l10n.mobileOffShift,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onShift.isNotEmpty) ...[
              SliverToBoxAdapter(child: MobileSectionHeader(title: l10n.mobileCurrentlyOnShift)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _LiveCard(item: onShift[i], status: 'on', nowHour: nowHour),
                  ),
                  childCount: onShift.length,
                ),
              ),
            ],
            if (late.isNotEmpty) ...[
              SliverToBoxAdapter(child: MobileSectionHeader(title: l10n.mobileLateTitle)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _LiveCard(item: late[i], status: 'late', nowHour: nowHour),
                  ),
                  childCount: late.length,
                ),
              ),
            ],
            if (off.isNotEmpty) ...[
              SliverToBoxAdapter(child: MobileSectionHeader(title: l10n.mobileOffTitle)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _LiveCard(item: off[i], status: 'off', nowHour: nowHour),
                  ),
                  childCount: off.length,
                ),
              ),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        );
      },
    );
  }
}

class _StatusTile extends StatelessWidget {
  final Color color;
  final Color bg;
  final int n;
  final String label;

  const _StatusTile({required this.color, required this.bg, required this.n, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: MT.br12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('$n', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  final ({UserModel user, ScheduleModel? shift}) item;
  final String status;
  final double nowHour;

  const _LiveCard({required this.item, required this.status, required this.nowHour});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final l10n = AppLocalizations.of(context)!;
    final name =
        item.user.getLocalizedNickname(locale)?.isNotEmpty == true
            ? item.user.getLocalizedNickname(locale)!
            : item.user.getLocalizedName(locale);
    final dept =
        locale == 'ar'
            ? (item.user.department ?? item.user.englishDepartment ?? '')
            : (item.user.englishDepartment ?? item.user.department ?? '');

    final statusColor =
        status == 'on'
            ? MT.statusOn
            : status == 'late'
            ? MT.statusLate
            : MT.statusOff;
    final statusBg =
        status == 'on'
            ? MT.statusOnBg
            : status == 'late'
            ? MT.statusLateBg
            : MT.statusOffBg;
    final statusLabel =
        status == 'on'
            ? l10n.mobileOnShiftNow
            : status == 'late'
            ? l10n.mobileLateNoPunch
            : l10n.mobileOffShift;

    double progress = 0;
    if (status == 'on' && item.shift != null && !item.shift!.isLeave) {
      final start = item.shift!.customStart;
      final end = item.shift!.customEnd < start ? item.shift!.customEnd + 24 : item.shift!.customEnd;
      final adj = item.shift!.customEnd < start && nowHour < start ? nowHour + 24 : nowHour;
      progress = ((adj - start) / (end - start)).clamp(0.0, 1.0);
    }

    final kind = item.shift == null ? 'off' : item.shift!.summaryKind;
    final shiftStyle = MT.shiftStyle(kind);

    return MobileCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          MobileAvatar(employee: item.user, size: 40, ring: status == 'on'),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: MT.text),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(dept, style: const TextStyle(fontSize: 12, color: MT.text3), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: shiftStyle.bg, borderRadius: MT.br12),
                      child: Text(
                        item.shift == null ? l10n.mobileNoShiftScheduled : SC.localizedShiftLabel(l10n, item.shift!),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: shiftStyle.ink),
                      ),
                    ),
                    if (item.shift != null && !item.shift!.isLeave && !item.shift!.isOffType) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${SC.fmtHour(item.shift!.customStart)}-${SC.fmtHour(item.shift!.customEnd)}',
                        style: const TextStyle(fontSize: 12, color: MT.text2),
                      ),
                    ],
                  ],
                ),
                if (status == 'on') ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      backgroundColor: MT.hair2,
                      color: MT.statusOn,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusBg, borderRadius: MT.br24),
            child: Text(statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
          ),
        ],
      ),
    );
  }
}
