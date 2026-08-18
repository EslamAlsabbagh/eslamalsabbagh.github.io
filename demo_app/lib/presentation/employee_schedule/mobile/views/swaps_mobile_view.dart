import 'package:hrms_demo/core/tutorial/tutorial_keys.dart';
import 'package:hrms_demo/data/models/shift_swap_request_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_event.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_tokens.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/widgets/mobile_card.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/widgets/mobile_section_header.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Swaps tab: manager incoming requests + history, employee sent/received.
class SwapsMobileView extends StatelessWidget {
  const SwapsMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final isTeamMode = state.viewMode == ScheduleViewMode.team;
        final allTeamIds = state.allTeam.map((e) => e.id).whereType<int>().toSet();

        final managerPending =
            isTeamMode
                ? state.swapRequests.where((r) => r.status == 'pending' && allTeamIds.contains(r.requesterId)).toList()
                : <ShiftSwapRequestModel>[];

        final personalIncoming = isTeamMode ? <ShiftSwapRequestModel>[] : state.incomingSwapRequests;
        final sent = isTeamMode ? <ShiftSwapRequestModel>[] : state.mySwapRequests;
        final history =
            isTeamMode
                ? <ShiftSwapRequestModel>[]
                : [
                  ...state.declinedSwapRequests,
                  ...state.acceptedIncomingSwapRequests,
                  ...state.processedSwapRequests,
                ];

        return CustomScrollView(
          // Tour target: the tab ROOT, so the spotlight still has a live context
          // when the swap lists happen to be empty.
          key: TutorialKeys.schMobileSwapsTab,
          slivers: [
            if (managerPending.isNotEmpty) ...[
              SliverToBoxAdapter(child: MobileSectionHeader(title: l10n.mobilePendingAction)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _SwapCard(
                      swap: managerPending[i],
                      role: _SwapCardRole.managerPending,
                      onApprove: () => ctx.read<ScheduleBloc>().add(ApproveSwap(managerPending[i].id!)),
                      onDecline: () => ctx.read<ScheduleBloc>().add(DeclineSwap(managerPending[i].id!)),
                      l10n: l10n,
                    ),
                  ),
                  childCount: managerPending.length,
                ),
              ),
            ],
            if (personalIncoming.isNotEmpty) ...[
              SliverToBoxAdapter(child: MobileSectionHeader(title: l10n.scheduleSwapWantsToSwap)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _SwapCard(
                      swap: personalIncoming[i],
                      role: _SwapCardRole.personalIncoming,
                      onApprove: () => ctx.read<ScheduleBloc>().add(AcceptSwapAsTarget(personalIncoming[i].id!)),
                      onDecline: () => ctx.read<ScheduleBloc>().add(DeclineSwapAsTarget(personalIncoming[i].id!)),
                      l10n: l10n,
                    ),
                  ),
                  childCount: personalIncoming.length,
                ),
              ),
            ],
            if (sent.isNotEmpty) ...[
              SliverToBoxAdapter(child: MobileSectionHeader(title: l10n.mobileSentByMe)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: _SwapCard(
                      swap: sent[i],
                      role: _SwapCardRole.outgoing,
                      onCancel: () => ctx.read<ScheduleBloc>().add(CancelSwapRequest(sent[i].id!)),
                      l10n: l10n,
                    ),
                  ),
                  childCount: sent.length,
                ),
              ),
            ],
            if (history.isNotEmpty) ...[
              SliverToBoxAdapter(child: MobileSectionHeader(title: l10n.mobileSwapHistory)),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _SwapHistoryCard(swap: history[i], l10n: l10n),
                  ),
                  childCount: history.length,
                ),
              ),
            ],
            if (managerPending.isEmpty && personalIncoming.isEmpty && sent.isEmpty && history.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(l10n.scheduleNoPendingSwaps, style: const TextStyle(color: MT.text3, fontSize: 14)),
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
          ],
        );
      },
    );
  }
}

enum _SwapCardRole { managerPending, personalIncoming, outgoing }

class _SwapCard extends StatelessWidget {
  final ShiftSwapRequestModel swap;
  final _SwapCardRole role;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;
  final VoidCallback? onCancel;
  final AppLocalizations l10n;

  const _SwapCard({
    required this.swap,
    required this.role,
    required this.l10n,
    this.onApprove,
    this.onDecline,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final requester =
        locale == 'ar'
            ? (swap.requesterArabicName ?? swap.requesterArabicNickname ?? swap.requesterEnglishName ?? '-')
            : (swap.requesterEnglishName ?? swap.requesterEnglishNickname ?? swap.requesterArabicName ?? '-');
    final target =
        locale == 'ar'
            ? (swap.targetArabicName ?? swap.targetArabicNickname ?? swap.targetEnglishName ?? '-')
            : (swap.targetEnglishName ?? swap.targetEnglishNickname ?? swap.targetArabicName ?? '-');

    final detail = _statusDetailLabel();

    return MobileCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            requester,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: MT.text),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: Icon(Icons.swap_horiz, size: 16, color: MT.brand),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      target,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: MT.text),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: swap.status, l10n: l10n, role: role),
            ],
          ),
          if (swap.reason?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(swap.reason!, style: const TextStyle(fontSize: 12, color: MT.text3)),
          ],
          if (detail != null && detail.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(detail, style: const TextStyle(fontSize: 11.5, color: MT.text3)),
          ],
          const SizedBox(height: 10),
          _ShiftPair(swap: swap, l10n: l10n),
          if (role == _SwapCardRole.managerPending && swap.status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: MT.leaveStripe),
                      foregroundColor: MT.leaveText,
                      shape: RoundedRectangleBorder(borderRadius: MT.br12),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onDecline,
                    child: Text(l10n.decline, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: MT.eveningStripe,
                      shape: RoundedRectangleBorder(borderRadius: MT.br12),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onApprove,
                    child: Text(l10n.approve, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
          if (role == _SwapCardRole.personalIncoming && swap.status == 'awaiting_target') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: MT.leaveStripe),
                      foregroundColor: MT.leaveText,
                      shape: RoundedRectangleBorder(borderRadius: MT.br12),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onDecline,
                    child: Text(l10n.decline, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: MT.eveningStripe,
                      shape: RoundedRectangleBorder(borderRadius: MT.br12),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: onApprove,
                    child: Text(l10n.approve, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
          if (role == _SwapCardRole.outgoing && (swap.status == 'pending' || swap.status == 'awaiting_target')) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: onCancel,
              style: TextButton.styleFrom(
                foregroundColor: MT.text3,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(l10n.cancel),
            ),
          ],
        ],
      ),
    );
  }

  String? _statusDetailLabel() {
    switch (role) {
      case _SwapCardRole.managerPending:
        return null;
      case _SwapCardRole.personalIncoming:
        return switch (swap.status) {
          'awaiting_target' => l10n.scheduleSwapWantsToSwap,
          'pending' => l10n.scheduleSwapAwaitingManagerApproval,
          'approved' => l10n.scheduleSwapCompleted,
          'declined' => l10n.scheduleSwapDeclined,
          'cancelled' => l10n.scheduleSwapCancelledByRequester,
          _ => null,
        };
      case _SwapCardRole.outgoing:
        return switch (swap.status) {
          'awaiting_target' => l10n.scheduleSwapAwaitingColleague,
          'pending' => l10n.scheduleSwapAwaitingManager,
          'approved' => l10n.scheduleSwapCompleted,
          'declined' => l10n.scheduleSwapRequestDeclined,
          'cancelled' => l10n.scheduleSwapYouCancelled,
          _ => null,
        };
    }
  }
}

class _ShiftPair extends StatelessWidget {
  final ShiftSwapRequestModel swap;
  final AppLocalizations l10n;

  const _ShiftPair({required this.swap, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final reqStart = swap.scheduleStart;
    final reqEnd = swap.scheduleEnd;
    final tgtStart = swap.targetScheduleStart;
    final tgtEnd = swap.targetScheduleEnd;
    final reqDate = _swapDateLabel(context, swap.scheduleWeekStart, swap.scheduleDayIndex);
    final tgtDate = _swapDateLabel(context, swap.scheduleWeekStart, swap.targetScheduleDayIndex);

    final reqKind = reqStart != null ? MT.kindFromHour(reqStart) : 'off';
    final tgtKind = tgtStart != null ? MT.kindFromHour(tgtStart) : 'off';
    final reqStyle = MT.shiftStyle(reqKind);
    final tgtStyle = MT.shiftStyle(tgtKind);

    String shiftLabel(double? start) {
      if (start == null) return '-';
      if (start < 6) return l10n.shiftOvernight;
      if (start < 12) return l10n.shiftMorning;
      if (start < 18) return l10n.shiftAfternoon;
      return l10n.shiftNight;
    }

    String timeRange(double? start, double? end) {
      if (start == null || end == null) return '';
      return '${SC.fmtHour(start)} - ${SC.fmtHour(end)}';
    }

    return Row(
      children: [
        Expanded(
          child: _ShiftBox(
            label: shiftLabel(reqStart),
            dateLabel: reqDate,
            time: timeRange(reqStart, reqEnd),
            style: reqStyle,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.swap_horiz, color: MT.text3, size: 18),
        ),
        Expanded(
          child: _ShiftBox(
            label: shiftLabel(tgtStart),
            dateLabel: tgtDate,
            time: timeRange(tgtStart, tgtEnd),
            style: tgtStyle,
          ),
        ),
      ],
    );
  }
}

class _ShiftBox extends StatelessWidget {
  final String label;
  final String? dateLabel;
  final String time;
  final ({Color bg, Color stripe, Color ink}) style;

  const _ShiftBox({required this.label, required this.dateLabel, required this.time, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: style.bg, borderRadius: MT.br12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: style.stripe, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: style.ink),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (dateLabel?.isNotEmpty == true)
            Text(
              dateLabel!,
              style: TextStyle(fontSize: 10.5, color: style.ink.withValues(alpha: 0.78)),
              overflow: TextOverflow.ellipsis,
            ),
          if (time.isNotEmpty)
            Text(
              time,
              style: TextStyle(fontSize: 11, color: style.ink.withValues(alpha: 0.7)),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final AppLocalizations l10n;
  final _SwapCardRole? role;

  const _StatusBadge({required this.status, required this.l10n, this.role});

  @override
  Widget build(BuildContext context) {
    final map = {
      'awaiting_target': (bg: MT.morningBg, text: MT.morningText, label: l10n.scheduleAwaitingColleagueBadge),
      'pending': (
        bg: MT.morningBg,
        text: MT.morningText,
        label: role == _SwapCardRole.managerPending ? l10n.pending : l10n.scheduleAwaitingManagerBadge,
      ),
      'approved': (bg: MT.eveningBg, text: MT.eveningText, label: l10n.scheduleStatusApproved),
      'declined': (bg: MT.leaveBg, text: MT.leaveText, label: l10n.scheduleStatusDeclined),
      'cancelled': (bg: MT.offBg, text: MT.offText, label: l10n.scheduleStatusCancelled),
    };
    final s = map[status] ?? (bg: MT.hair2, text: MT.text3, label: status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: s.bg, borderRadius: MT.br24),
      child: Text(s.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: s.text)),
    );
  }
}

class _SwapHistoryCard extends StatelessWidget {
  final ShiftSwapRequestModel swap;
  final AppLocalizations l10n;

  const _SwapHistoryCard({required this.swap, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final requester =
        locale == 'ar'
            ? (swap.requesterArabicName ?? swap.requesterArabicNickname ?? swap.requesterEnglishName ?? '-')
            : (swap.requesterEnglishName ?? swap.requesterEnglishNickname ?? swap.requesterArabicName ?? '-');
    final target =
        locale == 'ar'
            ? (swap.targetArabicName ?? swap.targetArabicNickname ?? swap.targetEnglishName ?? '-')
            : (swap.targetEnglishName ?? swap.targetEnglishNickname ?? swap.targetArabicName ?? '-');
    return MobileCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            requester,
                            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: MT.text),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: Icon(Icons.swap_horiz, size: 16, color: MT.brand),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      target,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: MT.text),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(status: swap.status, l10n: l10n),
            ],
          ),
          const SizedBox(height: 10),
          _ShiftPair(swap: swap, l10n: l10n),
        ],
      ),
    );
  }
}

String? _swapDateLabel(BuildContext context, DateTime? weekStart, int? dayIndex) {
  if (weekStart == null || dayIndex == null) return null;
  final l10n = AppLocalizations.of(context)!;
  final date = weekStart.add(Duration(days: dayIndex));
  return SC.localizedFmtShiftDate(l10n, date);
}
