import 'package:hrms_demo/core/widgets/flash_border.dart';
import 'package:hrms_demo/data/models/shift_swap_request_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_event.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:hrms_demo/presentation/widgets/safe_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

String _conflictMessage(AppLocalizations l10n, ShiftConflictType type) {
  switch (type) {
    case ShiftConflictType.approvedLeave:
      return l10n.scheduleConflictApprovedLeave;
    case ShiftConflictType.exceedsMaxHours:
      return l10n.scheduleConflictExceedsMaxHours;
    case ShiftConflictType.insufficientRestAfter:
      return l10n.scheduleConflictInsufficientRestAfter;
    case ShiftConflictType.insufficientRestBefore:
      return l10n.scheduleConflictInsufficientRestBefore;
  }
}

class ScheduleSidePanel extends StatefulWidget {
  final bool highlightSwaps;

  const ScheduleSidePanel({super.key, this.highlightSwaps = false});

  @override
  State<ScheduleSidePanel> createState() => _ScheduleSidePanelState();
}

class _ScheduleSidePanelState extends State<ScheduleSidePanel> {
  // Expanded shows full content; collapsed shrinks to a thin rail of just each
  // section's icon + count, reclaiming horizontal space for the grid + summary.
  // _collapsedW is tunable — narrower frees more grid width.
  static const double _expandedW = 320;
  static const double _collapsedW = 56;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          clipBehavior: Clip.hardEdge,
          width: _collapsed ? _collapsedW : _expandedW,
          decoration: BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: SC.lineColor))),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Collapse/expand toggle — trailing edge when open, centered on the rail.
                Align(
                  alignment: _collapsed ? AlignmentDirectional.center : AlignmentDirectional.centerEnd,
                  child: SafeTooltip(
                    message: _collapsed ? l10n.scheduleSidePanelExpand : l10n.scheduleSidePanelCollapse,
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        mouseCursor: SystemMouseCursors.click,
                        onTap: () => setState(() => _collapsed = !_collapsed),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: AnimatedRotation(
                            turns: _collapsed ? 0.5 : 0,
                            duration: const Duration(milliseconds: 100),
                            child: const Icon(Icons.chevron_right, size: 20, color: SC.muted),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FlashBorder(
                  triggered: widget.highlightSwaps,
                  color: const Color(0xFFF59E0B),
                  child: _SwapRequestsPanel(state: state, collapsed: _collapsed),
                ),
                const SizedBox(height: 12),
                _ConflictsPanel(state: state, collapsed: _collapsed),
                const SizedBox(height: 12),
                _LeaveOverlayPanel(state: state, collapsed: _collapsed),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Swap Requests ─────────────────────────────────────────────────────────

class _SwapRequestsPanel extends StatelessWidget {
  final ScheduleState state;
  final bool collapsed;
  const _SwapRequestsPanel({required this.state, this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredIds = state.filteredTeam.map((e) => e.id).whereType<int>().toSet();
    final pending =
        state.swapRequests.where((r) => r.status == 'pending' && filteredIds.contains(r.requesterId)).toList();

    return _Panel(
      title: l10n.schedulePanelSwapRequests,
      icon: Icons.swap_horiz,
      badge: pending.isEmpty ? null : pending.length,
      badgeColor: SC.amber,
      collapsed: collapsed,
      child:
          collapsed
              ? const SizedBox.shrink()
              : (pending.isEmpty
                  ? _EmptyHint(icon: Icons.swap_horiz, text: l10n.scheduleNoPendingSwaps)
                  : Column(children: pending.map((r) => _SwapCard(swap: r)).toList())),
    );
  }
}

class _SwapCard extends StatelessWidget {
  final ShiftSwapRequestModel swap;
  const _SwapCard({required this.swap});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ScheduleBloc>();
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final isArabic = locale == 'ar';
    final requesterNick =
        (isArabic
            ? swap.requesterArabicNickname ?? swap.requesterArabicName
            : swap.requesterEnglishNickname ?? swap.requesterEnglishName) ??
        'Employee #${swap.requesterId}';
    final requesterFull = (isArabic ? swap.requesterArabicName : swap.requesterEnglishName) ?? requesterNick;
    final targetNick =
        (isArabic
            ? swap.targetArabicNickname ?? swap.targetArabicName
            : swap.targetEnglishNickname ?? swap.targetEnglishName) ??
        l10n.scheduleOpenSlot;
    final targetFull = (isArabic ? swap.targetArabicName : swap.targetEnglishName) ?? targetNick;
    String requesterDate = '';
    String requesterHours = '';
    if (swap.scheduleDayIndex != null && swap.scheduleWeekStart != null) {
      requesterDate = SC.localizedFmtShiftDate(
        l10n,
        swap.scheduleWeekStart!.add(Duration(days: swap.scheduleDayIndex!)),
      );
    } else if (swap.scheduleDayIndex != null) {
      requesterDate = SC.localizedDayNames(l10n)[swap.scheduleDayIndex!];
    }
    if (swap.scheduleStart != null && swap.scheduleEnd != null) {
      requesterHours = '${SC.fmtHour(swap.scheduleStart!)} – ${SC.fmtHour(swap.scheduleEnd!)}';
    }

    String targetDate = '';
    String targetHours = '';
    if (swap.targetScheduleDayIndex != null && swap.scheduleWeekStart != null) {
      targetDate = SC.localizedFmtShiftDate(
        l10n,
        swap.scheduleWeekStart!.add(Duration(days: swap.targetScheduleDayIndex!)),
      );
    } else if (swap.targetScheduleDayIndex != null) {
      targetDate = SC.localizedDayNames(l10n)[swap.targetScheduleDayIndex!];
    }
    if (swap.targetScheduleStart != null && swap.targetScheduleEnd != null) {
      targetHours = '${SC.fmtHour(swap.targetScheduleStart!)} – ${SC.fmtHour(swap.targetScheduleEnd!)}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(border: Border.all(color: SC.lineColor), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Two employee blocks side-by-side with a single arrow between them
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: requesterFull,
                      child: Text(
                        requesterNick,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SC.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (requesterDate.isNotEmpty)
                      Text(requesterDate, style: const TextStyle(fontSize: 10.5, color: SC.muted)),
                    if (requesterHours.isNotEmpty)
                      Text(requesterHours, style: const TextStyle(fontSize: 10.5, color: SC.muted)),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward, size: 14, color: SC.muted),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: targetFull,
                      child: Text(
                        targetNick,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SC.ink),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (targetDate.isNotEmpty)
                      Text(targetDate, style: const TextStyle(fontSize: 10.5, color: SC.muted)),
                    if (targetHours.isNotEmpty)
                      Text(targetHours, style: const TextStyle(fontSize: 10.5, color: SC.muted)),
                  ],
                ),
              ),
            ],
          ),
          if (swap.reason != null && swap.reason!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              swap.reason!,
              style: const TextStyle(fontSize: 11, color: SC.muted2),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _ActionBtn(label: l10n.approve, color: SC.green, onTap: () => bloc.add(ApproveSwap(swap.id!))),
              const SizedBox(width: 6),
              _ActionBtn(label: l10n.decline, color: SC.rose, onTap: () => bloc.add(DeclineSwap(swap.id!))),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Conflicts ─────────────────────────────────────────────────────────────

class _ConflictsPanel extends StatelessWidget {
  final ScheduleState state;
  final bool collapsed;
  const _ConflictsPanel({required this.state, this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    final filteredIds = state.filteredTeam.map((e) => e.id.toString()).toSet();
    final conflicts =
        state.schedule.entries
            .where((e) => e.value.conflict != null && filteredIds.contains(e.key.split('-').first))
            .toList();

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final days = SC.localizedDayNames(l10n);
    return _Panel(
      title: l10n.schedulePanelConflicts,
      icon: Icons.warning_amber_rounded,
      badge: conflicts.isEmpty ? null : conflicts.length,
      badgeColor: SC.amber,
      collapsed: collapsed,
      child:
          collapsed
              ? const SizedBox.shrink()
              : conflicts.isEmpty
              ? _EmptyHint(icon: Icons.check_circle_outline, text: l10n.scheduleNoConflicts, color: SC.green)
              : Column(
                children:
                    conflicts.map((e) {
                      final parts = e.key.split('-');
                      final empId = parts[0];
                      final dayIdx = int.parse(parts[1]);
                      final emp = state.allTeam.where((u) => u.id.toString() == empId).firstOrNull;
                      if (emp == null) return const SizedBox.shrink();
                      final rawName = emp.getLocalizedName(locale);
                      final name = rawName.isNotEmpty ? rawName : 'Employee #$empId';
                      return _ConflictRow(
                        name: name,
                        day: days[dayIdx],
                        message: _conflictMessage(l10n, e.value.conflict!),
                      );
                    }).toList(),
              ),
    );
  }
}

class _ConflictRow extends StatelessWidget {
  final String name;
  final String day;
  final String message;

  const _ConflictRow({required this.name, required this.day, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 15, color: SC.amber),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name · $day',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: SC.ink),
                ),
                Text(message, style: const TextStyle(fontSize: 11, color: SC.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Leave Overlay ─────────────────────────────────────────────────────────

class _LeaveOverlayPanel extends StatelessWidget {
  final ScheduleState state;
  final bool collapsed;
  const _LeaveOverlayPanel({required this.state, this.collapsed = false});

  @override
  Widget build(BuildContext context) {
    final filteredIds = state.filteredTeam.map((e) => e.id.toString()).toSet();
    final leaves = state.leaveKeys.entries.where((e) => filteredIds.contains(e.key.split('-').first)).toList();

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final days = SC.localizedDayNames(l10n);
    return _Panel(
      title: l10n.schedulePanelTimeOff,
      icon: Icons.back_hand_outlined,
      badge: leaves.isEmpty ? null : leaves.length,
      badgeColor: SC.rose,
      collapsed: collapsed,
      child:
          collapsed
              ? const SizedBox.shrink()
              : leaves.isEmpty
              ? _EmptyHint(icon: Icons.event_available_outlined, text: l10n.scheduleNoApprovedLeaves)
              : Column(
                children:
                    leaves.map((e) {
                      final parts = e.key.split('-');
                      final empId = parts[0];
                      final dayIdx = int.parse(parts[1]);
                      final emp = state.allTeam.where((u) => u.id.toString() == empId).firstOrNull;
                      if (emp == null) return const SizedBox.shrink();
                      final rawName = emp.getLocalizedName(locale);
                      final name = rawName.isNotEmpty ? rawName : 'Employee #$empId';
                      return _LeaveRow(name: name, day: days[dayIdx], leaveType: e.value);
                    }).toList(),
              ),
    );
  }
}

class _LeaveRow extends StatelessWidget {
  final String name;
  final String day;
  final String leaveType;

  const _LeaveRow({required this.name, required this.day, required this.leaveType});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: SC.rose, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: SC.ink)),
                Text('$day · $leaveType', style: const TextStyle(fontSize: 11, color: SC.rose)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────

class _Panel extends StatelessWidget {
  final String title;
  // Representative icon shown on the collapsed rail in place of the title.
  final IconData icon;
  final int? badge;
  final Color? badgeColor;
  final Widget child;
  // When true (collapsed rail), only an icon + count chip renders (title moves to
  // a tooltip); the divider and body are dropped.
  final bool collapsed;

  const _Panel({
    required this.title,
    required this.icon,
    this.badge,
    this.badgeColor,
    required this.child,
    this.collapsed = false,
  });

  // Small rounded count pill reused by both the expanded header and the rail.
  Widget _countBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
    decoration: BoxDecoration(color: badgeColor ?? SC.amber, borderRadius: BorderRadius.circular(10)),
    child: Text('$badge', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: SC.lineColor), borderRadius: BorderRadius.circular(8)),
      // Ease the size change as content shows/hides; width is animated by the parent.
      child: AnimatedSize(
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: collapsed ? _buildCollapsed() : _buildExpanded(),
      ),
    );
  }

  // Collapsed rail: centered icon + count, title surfaced via tooltip.
  Widget _buildCollapsed() {
    return SafeTooltip(
      message: badge == null ? title : '$title ($badge)',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: SizedBox(
          width: 36,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: badge == null ? SC.muted2 : (badgeColor ?? SC.amber)),
              if (badge != null) ...[const SizedBox(height: 5), _countBadge()],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpanded() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: SC.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[const SizedBox(width: 6), _countBadge()],
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(padding: const EdgeInsets.all(10), child: child),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _EmptyHint({required this.icon, required this.text, this.color = SC.muted2});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(fontSize: 11.5, color: color)),
        ],
      ),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border.all(color: color.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
        ),
      ),
    );
  }
}
