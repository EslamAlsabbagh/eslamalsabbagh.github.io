import 'package:hrms_demo/core/tutorial/tutorial_keys.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_event.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_tokens.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/widgets/mobile_card.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// More tab — publish week, copy last week, and week stats summary.
class MoreMobileView extends StatelessWidget {
  const MoreMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final filteredIds = state.filteredTeam.map((e) => e.id).whereType<int>().toSet();
        final shifts = state.schedule.values.where((s) => !s.isLeave && filteredIds.contains(s.employeeId)).toList();
        final draftCount = shifts.where((s) => !s.isPublished).length;
        final isPublished = shifts.isNotEmpty && shifts.every((s) => s.isPublished);
        final isDraft = shifts.any((s) => !s.isPublished);
        final canPublish = isDraft && state.allWeekCellsFilled;
        final emptyCount = state.emptyCount;
        // Team copy also copies the manager's own pinned row — enable it when
        // either the team can be copied (reports have source shifts AND room to
        // paste into) OR my own row can be copied. Both sides need source AND
        // room, since copy skips already-occupied days.
        final canCopy = (state.hasLastWeekShifts && state.teamHasRoomToCopy) || state.canSelfCopyLastWeek;
        final copyShiftCount =
            state.lastWeekShiftCount + (state.canSelfCopyLastWeek ? state.selfLastWeekShiftCount : 0);

        return ListView(
          // Tour target: the tab ROOT — individual tiles can be disabled/absent.
          key: TutorialKeys.schMobileMoreTab,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // ── Week label ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                SC.localizedWeekLabel(l10n, state.weekStart),
                style: const TextStyle(fontSize: 13, color: MT.text3, fontWeight: FontWeight.w600),
              ),
            ),
            // ── Publish ──────────────────────────────────────────────
            _ActionTile(
              icon: Icons.send_outlined,
              iconColor: MT.brand,
              iconBg: MT.brandBg,
              title: l10n.mobilePublishWeek,
              subtitle:
                  isPublished
                      ? l10n.mobileStatAllPublished
                      : emptyCount > 0
                      ? l10n.scheduleEmptyCellsRemaining(emptyCount)
                      : isDraft
                      ? '${l10n.schedulePublishToBePublished}: $draftCount'
                      : l10n.mobileStatAllPublished,
              badge: isDraft ? '$draftCount' : null,
              enabled: canPublish,
              onTap: () => _confirmPublish(context, state, l10n),
            ),
            const SizedBox(height: 10),
            // ── Copy last week ───────────────────────────────────────
            _ActionTile(
              icon: Icons.copy_outlined,
              iconColor: const Color(0xFF7E57C2),
              iconBg: const Color(0xFFEDE7F6),
              title: l10n.mobileCopyLastWeek,
              subtitle:
                  canCopy
                      ? '$copyShiftCount ${l10n.scheduleCopyShiftsToCopy}'
                      : ((state.hasLastWeekShifts || state.hasSelfLastWeekShifts)
                          ? l10n.scheduleCopyNoRoom
                          : l10n.scheduleCopyLastWeekNoShifts),
              enabled: canCopy,
              onTap: () => _confirmCopy(context, state, l10n),
            ),
            const SizedBox(height: 24),
            // ── Conflict summary ─────────────────────────────────────
            if (state.conflictCount > 0) ...[
              _InfoCard(
                icon: Icons.warning_amber_outlined,
                color: const Color(0xFF9A6A00),
                bg: const Color(0xFFFFF3D6),
                title: '${state.conflictCount} ${l10n.mobileStatConflicts}',
                subtitle: l10n.schedulePublishNote,
              ),
              const SizedBox(height: 10),
            ],
            // ── Leave overlay info ───────────────────────────────────
            if (state.leaveCount > 0)
              _InfoCard(
                icon: Icons.flag_outlined,
                color: MT.leaveText,
                bg: MT.leaveBg,
                title: '${state.leaveCount} ${l10n.scheduleLegendLeave}',
                subtitle: l10n.scheduleLegendLeave,
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmPublish(BuildContext context, ScheduleState state, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => _ConfirmSheet(
            icon: Icons.send_outlined,
            title: l10n.schedulePublishDialogTitle,
            body: l10n.schedulePublishNote,
            confirmLabel: l10n.schedulePublishButton,
          ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ScheduleBloc>().add(const PublishWeek());
    }
  }

  Future<void> _confirmCopy(BuildContext context, ScheduleState state, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (_) => _ConfirmSheet(
            icon: Icons.copy_outlined,
            title: l10n.scheduleCopyDialogTitle,
            body: l10n.scheduleCopyNote,
            confirmLabel: l10n.scheduleCopyButton,
          ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ScheduleBloc>().add(const CopyLastWeek());
    }
  }
}

// ── Action tile ─────────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? badge;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: MobileCard(
        onTap: enabled ? onTap : null,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: iconBg, borderRadius: MT.br12),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: MT.text)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: MT.text3)),
                ],
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: MT.brandBg, borderRadius: MT.br24),
                child: Text(badge!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: MT.brand)),
              )
            else
              const Icon(Icons.chevron_right, size: 18, color: MT.text3),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String subtitle;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: MT.br12,
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color))),
        ],
      ),
    );
  }
}

// ── Lightweight confirmation dialog ─────────────────────────────────────────

class _ConfirmSheet extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String confirmLabel;

  const _ConfirmSheet({required this.icon, required this.title, required this.body, required this.confirmLabel});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: MT.br16),
      title: Row(
        children: [
          Icon(icon, size: 20, color: MT.brand),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
        ],
      ),
      content: Text(body, style: const TextStyle(fontSize: 13, color: MT.text3)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel, style: const TextStyle(color: MT.text3)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: MT.brand,
            shape: RoundedRectangleBorder(borderRadius: MT.br12),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
