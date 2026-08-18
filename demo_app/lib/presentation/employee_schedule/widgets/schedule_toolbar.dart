import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/tutorial/tutorial_keys.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_event.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:hrms_demo/presentation/widgets/safe_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScheduleToolbar extends StatelessWidget {
  final VoidCallback onCopyLastWeek;
  final VoidCallback onPublish;
  final VoidCallback? onNewShift;
  final bool hideManagerActions;

  const ScheduleToolbar({
    super.key,
    required this.onCopyLastWeek,
    required this.onPublish,
    this.onNewShift,
    this.hideManagerActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final l10n = AppLocalizations.of(context)!;
        final bloc = context.read<ScheduleBloc>();
        final filteredIds = state.filteredTeam.map((e) => e.id).whereType<int>().toSet();
        final filteredShifts =
            state.schedule.values.where((s) => !s.isLeave && filteredIds.contains(s.employeeId)).toList();
        final isPublished = filteredShifts.isNotEmpty && filteredShifts.every((s) => s.isPublished);
        final canPublish = filteredShifts.any((s) => !s.isPublished) && state.allWeekCellsFilled;
        final isPublishing = state.publishState == PublishState.publishing;
        final emptyCount = state.emptyCount;
        final publishTooltip = emptyCount > 0 ? l10n.scheduleEmptyCellsRemaining(emptyCount) : '';
        final departmentOptions = _departmentOptions(context, state, l10n);
        // Team copy also copies the manager's own pinned row, so enable it when
        // either the team can be copied (reports have source shifts AND room to
        // paste into) OR my own row can be copied. Both sides need source AND
        // room, since copy skips already-occupied days.
        final canCopyTeam = (state.hasLastWeekShifts && state.teamHasRoomToCopy) || state.canSelfCopyLastWeek;
        // Disabled-copy tooltips: distinguish "nothing to copy last week" from
        // "this week is already full" so the reason isn't misleading.
        final selfCopyMsg =
            state.canSelfCopyLastWeek
                ? ''
                : (state.hasSelfLastWeekShifts ? l10n.scheduleCopyNoRoom : l10n.scheduleCopyLastWeekNoShifts);
        final teamCopyMsg =
            canCopyTeam
                ? ''
                : ((state.hasLastWeekShifts || state.hasSelfLastWeekShifts)
                    ? l10n.scheduleCopyNoRoom
                    : l10n.scheduleCopyLastWeekNoShifts);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: SC.lineColor),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Left: date navigator + separator + filters — fills available space
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Date navigator
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SafeTooltip(
                          message: isPublishing ? l10n.schedulePublishingPleaseWait : '',
                          child: _ToolBtn(
                            label: l10n.scheduleToolbarToday,
                            disabled: isPublishing,
                            onTap:
                                isPublishing
                                    ? null
                                    : () {
                                      final weekStart = SC.weekStartOf(DateTime.now());
                                      bloc.add(ChangeWeek(weekStart));
                                      if (state.view == ScheduleView.day) {
                                        final dayIndex = DateTime.now().difference(weekStart).inDays.clamp(0, 6);
                                        bloc.add(ChangeView(ScheduleView.day, dayIndex: dayIndex));
                                      }
                                    },
                          ),
                        ),
                        const SizedBox(width: 4),
                        SafeTooltip(
                          message: isPublishing ? l10n.schedulePublishingPleaseWait : '',
                          child: _ArrowBtn(
                            icon: Icons.chevron_left,
                            disabled: state.status == Status.loading || isPublishing,
                            onTap:
                                () => bloc.add(
                                  ChangeWeek(
                                    DateTime(state.weekStart.year, state.weekStart.month, state.weekStart.day - 7),
                                  ),
                                ),
                          ),
                        ),
                        SafeTooltip(
                          message: isPublishing ? l10n.schedulePublishingPleaseWait : '',
                          child: _ArrowBtn(
                            icon: Icons.chevron_right,
                            disabled: state.status == Status.loading || isPublishing,
                            onTap:
                                () => bloc.add(
                                  ChangeWeek(
                                    DateTime(state.weekStart.year, state.weekStart.month, state.weekStart.day + 7),
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          SC.localizedWeekLabel(l10n, state.weekStart),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SC.ink),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.scheduleToolbarWeek(SC.weekNumber(state.weekStart)),
                          style: const TextStyle(fontSize: 11.5, color: SC.muted),
                        ),
                      ],
                    ),
                    if (!hideManagerActions) const _Sep(),
                    // Filters
                    if (!hideManagerActions)
                      _FilterDrop(
                        hint: l10n.scheduleAllDepartments,
                        value: state.filters.department,
                        items: departmentOptions.values,
                        displayLabels: departmentOptions.labels,
                        onChanged:
                            (v) => bloc.add(
                              ChangeFilters(
                                state.filters.copyWith(
                                  department: v == l10n.scheduleAllDepartments ? null : v,
                                  clearDepartment: v == l10n.scheduleAllDepartments,
                                ),
                              ),
                            ),
                      ),
                    if (!hideManagerActions)
                      _FilterDrop(
                        hint: l10n.scheduleAllLocations,
                        value: state.filters.location,
                        items: _uniqueLocs(state, l10n),
                        onChanged:
                            (v) => bloc.add(
                              ChangeFilters(
                                state.filters.copyWith(
                                  location: v == l10n.scheduleAllLocations ? null : v,
                                  clearLocation: v == l10n.scheduleAllLocations,
                                ),
                              ),
                            ),
                      ),
                    if (!hideManagerActions)
                      _FilterDrop(
                        hint: l10n.scheduleDirectPlusIndirect,
                        value: _scopeLabel(state.filters.teamScope, l10n),
                        items: [
                          l10n.scheduleDirectPlusIndirect,
                          l10n.scheduleDirectReportsOnly,
                          l10n.scheduleIndirectOnly,
                        ],
                        onChanged: (v) {
                          final scope =
                              v == l10n.scheduleDirectReportsOnly
                                  ? TeamScope.direct
                                  : v == l10n.scheduleIndirectOnly
                                  ? TeamScope.indirect
                                  : TeamScope.all;
                          bloc.add(ChangeFilters(state.filters.copyWith(teamScope: scope)));
                        },
                      ),
                  ],
                ),
              ),
              // Self-draft actions (colleagues mode, any user): copy-last-week
              // for MY OWN row + a hint that drafts are published by my
              // manager. No publish.
              if (hideManagerActions)
                Row(
                  key: TutorialKeys.schSelfActions,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: SC.amber.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_note, size: 14, color: SC.amber),
                          const SizedBox(width: 4),
                          Text(
                            l10n.scheduleDraftHint,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SC.amber),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SafeTooltip(
                      message: selfCopyMsg,
                      child: _ToolBtn(
                        icon: Icons.copy_outlined,
                        label: l10n.scheduleCopyLastWeek,
                        labelColor: state.canSelfCopyLastWeek && !state.isPastWeek ? null : SC.muted2,
                        disabled: !state.canSelfCopyLastWeek || state.isPastWeek,
                        onTap: state.canSelfCopyLastWeek && !state.isPastWeek ? onCopyLastWeek : null,
                      ),
                    ),
                  ],
                ),
              // Right: action buttons — fixed-width, never wraps
              if (!hideManagerActions)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SafeTooltip(
                      message: teamCopyMsg,
                      child: KeyedSubtree(
                        key: TutorialKeys.schCopyLastWeek,
                        child: _ToolBtn(
                          icon: Icons.copy_outlined,
                          label: l10n.scheduleCopyLastWeek,
                          labelColor: canCopyTeam ? null : SC.muted2,
                          disabled: !canCopyTeam,
                          onTap: canCopyTeam ? onCopyLastWeek : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: publishTooltip,
                      child: KeyedSubtree(
                        key: TutorialKeys.schPublish,
                        child: _ToolBtn(
                          labelColor: isPublished || !canPublish ? SC.muted2 : null,
                          disabled: !canPublish,
                          primary: isPublished || !canPublish ? false : true,
                          icon: isPublished ? Icons.check_circle_outline : Icons.send_outlined,
                          label:
                              isPublishing
                                  ? l10n.schedulePublishing
                                  : isPublished
                                  ? l10n.scheduleStatusPublished
                                  : l10n.schedulePublishWeek,
                          onTap: isPublishing || !canPublish ? null : onPublish,
                          color: isPublished ? SC.green : SC.blue,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  ({List<String> values, List<String> labels}) _departmentOptions(
    BuildContext context,
    ScheduleState state,
    AppLocalizations l10n,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final labelsByValue = <String, String>{};

    for (final employee in state.allTeam) {
      final value = employee.englishDepartment ?? employee.department;
      if (value == null || value.isEmpty) continue;

      final label = employee.getLocalizedDepartment(locale);
      labelsByValue[value] = label.isNotEmpty ? label : value;
    }

    final entries = labelsByValue.entries.toList()..sort((a, b) => a.value.compareTo(b.value));

    return (
      values: [l10n.scheduleAllDepartments, ...entries.map((entry) => entry.key)],
      labels: [l10n.scheduleAllDepartments, ...entries.map((entry) => entry.value)],
    );
  }

  List<String> _uniqueLocs(ScheduleState state, AppLocalizations l10n) {
    final set = <String>{};
    for (final e in state.allTeam) {
      if (e.location != null) set.add(e.location!);
    }
    return [l10n.scheduleAllLocations, ...set.toList()..sort()];
  }

  String _scopeLabel(TeamScope scope, AppLocalizations l10n) {
    switch (scope) {
      case TeamScope.direct:
        return l10n.scheduleDirectReportsOnly;
      case TeamScope.indirect:
        return l10n.scheduleIndirectOnly;
      case TeamScope.all:
        return l10n.scheduleDirectPlusIndirect;
    }
  }
}

class _ToolBtn extends StatelessWidget {
  final String label;
  final Color? labelColor;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool primary;
  final Color? color;
  final bool disabled;

  const _ToolBtn({
    required this.label,
    this.labelColor,
    this.icon,
    this.onTap,
    this.primary = false,
    this.color,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? SC.blue : Colors.white;
    final fg = primary ? Colors.white : (labelColor ?? color ?? SC.ink2);

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: primary ? SC.blue : SC.lineColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 5)],
              Text(label, style: TextStyle(fontSize: 12.5, color: fg, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  const _ArrowBtn({required this.icon, this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: disabled ? const Color(0xFFF3F4F6) : Colors.white,
            border: Border.all(color: disabled ? SC.lineColor2 : SC.lineColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: disabled ? SC.muted2 : SC.ink2),
        ),
      ),
    );
  }
}

class _Sep extends StatelessWidget {
  const _Sep();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 22, color: SC.lineColor, margin: const EdgeInsets.symmetric(horizontal: 4));
  }
}

class _FilterDrop extends StatelessWidget {
  final String hint;
  final String? value;
  final List<String> items;
  final List<String>? displayLabels;
  final ValueChanged<String?> onChanged;

  const _FilterDrop({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.displayLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SC.lineColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value ?? hint,
          isDense: true,
          style: const TextStyle(fontSize: 12.5, color: SC.ink2),
          items:
              items.asMap().entries.map((entry) {
                final label =
                    (displayLabels != null && entry.key < displayLabels!.length)
                        ? displayLabels![entry.key]
                        : entry.value;
                return DropdownMenuItem(value: entry.value, child: Text(label));
              }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
