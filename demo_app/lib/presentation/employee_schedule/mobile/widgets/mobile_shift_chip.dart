import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_tokens.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:hrms_demo/presentation/widgets/safe_tooltip.dart';
import 'package:flutter/material.dart';

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

/// Compact shift pill shown in weekly row cards and day headers.
class MobileShiftChip extends StatelessWidget {
  final ScheduleModel? shift;
  final String? leaveType;
  final bool showConflict;

  const MobileShiftChip({super.key, this.shift, this.leaveType, this.showConflict = true});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDraft = shift != null && !shift!.isPublished && !shift!.isLeave;

    Widget chip;

    if (shift == null) {
      chip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: MT.hair2, borderRadius: MT.br24),
        child: Text('—', style: const TextStyle(fontSize: 12, color: MT.text3, fontWeight: FontWeight.w600)),
      );
    } else if (shift!.isOffType) {
      chip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isDraft ? Colors.white : shift!.shiftLightColor,
          borderRadius: MT.br24,
          border:
              isDraft
                  ? Border.all(color: SC.amber, width: 1.5)
                  : Border.all(color: shift!.shiftColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isDraft ? SC.amber : shift!.shiftColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              SC.localizedShiftLabel(l10n, shift!),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDraft ? SC.amber : shift!.shiftColor,
              ),
            ),
          ],
        ),
      );
    } else {
      final kind = shift!.summaryKind;
      final style = MT.shiftStyle(kind);
      final label = SC.localizedShiftLabel(l10n, shift!);
      final timeLabel = shift!.isLeave ? l10n.shiftFullDay : SC.localizedTimeLabel(l10n, shift!);

      chip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: isDraft ? Colors.white : style.bg,
          borderRadius: MT.br24,
          border:
              isDraft
                  ? Border.all(color: SC.amber, width: 1.5)
                  : Border.all(color: style.stripe.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isDraft ? SC.amber : style.stripe,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDraft ? SC.amber : style.ink),
                ),
              ],
            ),
            Text(
              timeLabel,
              style: TextStyle(fontSize: 10, color: isDraft ? SC.muted : style.ink.withValues(alpha: 0.7)),
            ),
          ],
        ),
      );
    }

    // Employee-proposed draft (last writer = the employee): show a small
    // "Proposed" pill next to the draft chip so managers can tell it apart
    // from their own drafts.
    if (isDraft && shift!.isEmployeeProposed) {
      chip = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Text(
              l10n.scheduleProposedBadge,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(width: 6),
          chip,
        ],
      );
    }

    final shouldShowLeavePill = shift != null && !shift!.isLeave && leaveType != null;

    final chipWithLeave =
        shouldShowLeavePill
            ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: SC.rose50,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: SC.rose.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    SC.localizedLeaveType(l10n, leaveType),
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: SC.rose),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                chip,
              ],
            )
            : chip;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        chipWithLeave,
        if (showConflict && shift != null && shift!.conflict != null)
          Positioned(
            top: -4,
            right: -4,
            child: SafeTooltip(
              message: _conflictMessage(l10n, shift!.conflict!),
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(color: SC.amber, shape: BoxShape.circle),
                child: const Icon(Icons.warning, size: 10, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
