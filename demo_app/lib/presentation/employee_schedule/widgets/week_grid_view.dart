import 'package:hrms_demo/core/tutorial/tutorial_keys.dart';
import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/request_swap_dialog.dart';
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

/// One shift-type or off/leave type tallied for the Summary column, carrying the
/// same colors the day-cell chip uses so the summary chip visually maps back to it.
class _SummaryTally {
  final String label;
  int count;
  final Color color;
  final Color bg;

  _SummaryTally({required this.label, required this.count, required this.color, required this.bg});
}

/// Aggregates for a single employee's week, shown in the trailing Summary column.
class _WeekSummary {
  final double hours;
  // Worked shifts split by type (Morning/Afternoon/…), in first-seen day order.
  final List<_SummaryTally> shiftTallies;
  // Off/leave tallies in first-seen day order, each with its own chip colors.
  final List<_SummaryTally> offTallies;
  final int conflictCount;

  const _WeekSummary({
    required this.hours,
    required this.shiftTallies,
    required this.offTallies,
    required this.conflictCount,
  });
}

/// Tallies one employee's week from [sched] (keyed `'$empId-$dayIndex'`). Works for
/// both team rows (`effectiveSchedule` + `leaveKeys`) and the pinned manager row
/// (`pinnedManagerSchedule` + `pinnedManagerLeaveKeys`).
_WeekSummary _summaryFor(
  AppLocalizations l10n,
  Map<String, ScheduleModel> sched,
  Map<String, String> leaveKeys,
  int? empId,
) {
  double hours = 0;
  int conflictCount = 0;
  // Insertion-ordered so chips render in first-seen day order.
  final shifts = <String, _SummaryTally>{};
  final offs = <String, _SummaryTally>{};
  void addTo(Map<String, _SummaryTally> bucket, String label, Color color, Color bg) {
    final existing = bucket[label];
    if (existing != null) {
      existing.count++;
    } else {
      bucket[label] = _SummaryTally(label: label, count: 1, color: color, bg: bg);
    }
  }

  for (int d = 0; d < 7; d++) {
    final key = '$empId-$d';
    final s = sched[key];
    if (s == null) continue;
    hours += s.hours;
    if (s.conflict != null) conflictCount++;
    if (s.isLeave || s.isOffType) {
      // Off type or leave-only day — already self-describing; the off chip stands
      // in for any coinciding leave overlay (no double count on planned/unplanned).
      addTo(offs, SC.localizedShiftLabel(l10n, s), s.shiftColor, s.shiftLightColor);
    } else {
      // Working shift — bucket by type (Morning/Afternoon/…) with that type's color.
      addTo(shifts, SC.localizedShiftLabel(l10n, s), s.shiftColor, s.shiftLightColor);
      // If an approved leave is also overlaid that day, show it as a distinct
      // "leave on a shift day" chip so it doesn't merge with leave-only chips.
      final overlayLeave = leaveKeys[key];
      if (overlayLeave != null) {
        addTo(offs, l10n.scheduleSummaryLeaveOnShift(SC.localizedLeaveType(l10n, overlayLeave)), SC.rose, SC.rose50);
      }
    }
  }
  return _WeekSummary(
    hours: hours,
    shiftTallies: shifts.values.toList(),
    offTallies: offs.values.toList(),
    conflictCount: conflictCount,
  );
}

const double _empColW = 200;
const double _dayColW = 130;
const double _summaryColW = 200;
const double _cellMinH = 80;
const double _headerH = 52;
const double _rowH = 92;

// Pinned N+1 comparison row tint (indigo-50) and badge accent (indigo-600).
const Color _pinnedRowBg = Color(0xFFEEF2FF);
const Color _pinnedAccent = Color(0xFF4F46E5);

// Sentinel "row index" marking a drag that started on the pinned self row.
// Real team rows are indexed 0..n into filteredTeam; the pinned row isn't in
// that list, so its selection keys use the 'self-$d' prefix instead.
const int _kPinnedRow = -1;

class WeekGridView extends StatefulWidget {
  final VoidCallback? onNewShift;
  final void Function(String scheduleKey)? onAssignCell;
  final void Function(List<String> keys)? onBulkAssign;
  final void Function(ScheduleModel shift)? onEditShift;

  const WeekGridView({super.key, this.onNewShift, this.onAssignCell, this.onBulkAssign, this.onEditShift});

  @override
  State<WeekGridView> createState() => _WeekGridViewState();
}

class _WeekGridViewState extends State<WeekGridView> {
  final Set<String> _selected = {};

  // _isDragging: pointer button is currently held down over the grid.
  // _dragStarted: pointer has entered at least one cell beyond the starting
  //   cell — used to guard onTap from firing spuriously after a drag.
  bool _isDragging = false;
  bool _dragStarted = false;
  int _selStartRow = 0;
  int _selStartDay = 0;
  // Stored in state so onTap never relies on a stale closure after rebuild.
  String? _pendingCellKey;
  ScheduleModel? _pendingCellShift;
  Offset _lastTapPosition = Offset.zero;
  UserModel? _pendingCellEmp;
  int _pendingCellDay = 0;

  // Persistent (non-blocking) bottom sheet shown while cells are selected.
  PersistentBottomSheetController? _sheetController;
  // StateSetter saved from StatefulBuilder so we can refresh the count live.
  StateSetter? _setSheetState;

  final ScrollController _hScrollController = ScrollController();
  final ValueNotifier<Offset?> _mousePos = ValueNotifier(null);
  double _gridWidth = 0;

  void _scrollToEdge(bool toEnd) {
    if (!_hScrollController.hasClients) return;
    final target = toEnd ? _hScrollController.position.maxScrollExtent : 0.0;
    _hScrollController.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _sheetController?.close();
    _hScrollController.dispose();
    _mousePos.dispose();
    super.dispose();
  }

  void _showOrUpdateSheet(BuildContext context) {
    if (_sheetController != null) {
      _setSheetState?.call(() {});
      return;
    }

    _sheetController = showBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      backgroundColor: Colors.blue,
      builder:
          (_) => StatefulBuilder(
            builder: (ctx, setSheetState) {
              _setSheetState = setSheetState;
              final count = _selected.length;
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        count == 1
                            ? AppLocalizations.of(context)!.scheduleGridCellSelected(count)
                            : AppLocalizations.of(context)!.scheduleGridCellsSelected(count),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: _dismissSheet,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.6)),
                        ),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: () => _confirmBulkAssign(context),
                        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue),
                        child: Text(AppLocalizations.of(context)!.scheduleAssignShift),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );

    _sheetController!.closed.then((_) {
      _sheetController = null;
      _setSheetState = null;
      if (mounted && _selected.isNotEmpty) {
        setState(() => _selected.clear());
      }
    });
  }

  void _dismissSheet() {
    _sheetController?.close();
    _sheetController = null;
    _setSheetState = null;
    setState(() => _selected.clear());
  }

  void _confirmBulkAssign(BuildContext context) {
    final state = context.read<ScheduleBloc>().state;
    final liveTeam = state.filteredTeam;
    final myId = state.managerId;
    final scheduleKeys =
        _selected
            .map((s) {
              // Pinned self-row cell → my own '$managerId-$day' schedule key.
              if (_isSelfKey(s)) {
                if (myId == null) return null;
                return '$myId-${s.substring('self-'.length)}';
              }
              final parts = s.split('-');
              final empIdx = int.parse(parts[0]);
              final dayIdx = int.parse(parts[1]);
              if (empIdx >= liveTeam.length) return null;
              return '${liveTeam[empIdx].id}-$dayIdx';
            })
            .whereType<String>()
            .toList();

    _dismissSheet();
    if (scheduleKeys.isNotEmpty) widget.onBulkAssign?.call(scheduleKeys);
  }

  void _showColleagueSwapMenu(
    BuildContext context,
    ScheduleState state,
    UserModel emp,
    int dayIdx,
    ScheduleModel? shift,
    Offset tapPosition,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isSelf = emp.id == state.managerId;
    final shiftDate = state.weekStart.add(Duration(days: dayIdx));

    if (isSelf) {
      showMenu<void>(
        context: context,
        position: RelativeRect.fromLTRB(tapPosition.dx, tapPosition.dy, tapPosition.dx + 1, tapPosition.dy + 1),
        items: [
          PopupMenuItem(
            enabled: false,
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, size: 16),
                const SizedBox(width: 8),
                Text(l10n.scheduleSelectOtherShiftsToSwap),
              ],
            ),
          ),
        ],
      );
      return;
    }

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final shiftDay = DateTime(shiftDate.year, shiftDate.month, shiftDate.day);
    if (!shiftDay.isAfter(todayDate)) {
      showMenu<void>(
        context: context,
        position: RelativeRect.fromLTRB(tapPosition.dx, tapPosition.dy, tapPosition.dx + 1, tapPosition.dy + 1),
        items: [
          PopupMenuItem(
            enabled: false,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Flexible(child: Text(l10n.scheduleSwapPastDay)),
              ],
            ),
          ),
        ],
      );
      return;
    }

    if (shift == null) return;

    final selfShift = state.selfSchedule['${state.managerId}-$dayIdx'];
    final l10nLocal = AppLocalizations.of(context)!;

    if (selfShift != null && selfShift.isLeaveType) {
      showMenu<void>(
        context: context,
        position: RelativeRect.fromLTRB(tapPosition.dx, tapPosition.dy, tapPosition.dx + 1, tapPosition.dy + 1),
        items: [
          PopupMenuItem(
            enabled: false,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Flexible(child: Text(l10nLocal.scheduleSwapOnLeave)),
              ],
            ),
          ),
        ],
      );
      return;
    }

    // Inform when colleague has the same shift times
    if (selfShift != null && shift.customStart == selfShift.customStart && shift.customEnd == selfShift.customEnd) {
      showMenu<void>(
        context: context,
        position: RelativeRect.fromLTRB(tapPosition.dx, tapPosition.dy, tapPosition.dx + 1, tapPosition.dy + 1),
        items: [
          PopupMenuItem(
            enabled: false,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Text(l10nLocal.scheduleSwapSameShift),
              ],
            ),
          ),
        ],
      );
      return;
    }

    // Inform when there's already an open request for this day
    if (state.hasOpenSwapOnDay(selfShift?.id, shiftDate)) {
      showMenu<void>(
        context: context,
        position: RelativeRect.fromLTRB(tapPosition.dx, tapPosition.dy, tapPosition.dx + 1, tapPosition.dy + 1),
        items: [
          PopupMenuItem(
            enabled: false,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Flexible(child: Text(l10nLocal.scheduleSwapAlreadyPending)),
              ],
            ),
          ),
        ],
      );
      return;
    }

    if (shift.isLeaveType) {
      showMenu<void>(
        context: context,
        position: RelativeRect.fromLTRB(tapPosition.dx, tapPosition.dy, tapPosition.dx + 1, tapPosition.dy + 1),
        items: [
          PopupMenuItem(
            enabled: false,
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Flexible(child: Text(l10nLocal.scheduleSwapColleagueOnLeave)),
              ],
            ),
          ),
        ],
      );
      return;
    }

    showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(tapPosition.dx, tapPosition.dy, tapPosition.dx + 1, tapPosition.dy + 1),
      items: [
        PopupMenuItem(
          onTap: () {
            if (selfShift == null) {
              return;
            }
            final peerSchedulesForDay = {
              for (final p in state.peers)
                if (p.id != null) p.id!: state.peersSchedule['${p.id}-$dayIdx'],
            };
            showRequestSwapDialog(
              context,
              shift: selfShift,
              shiftDate: shiftDate,
              teammates: state.peers,
              peerSchedulesForDay: peerSchedulesForDay,
              currentUserId: state.managerId!,
              currentUser: state.selfUser!,
              preSelectedColleagueId: emp.id,
            );
          },
          child: Row(
            children: [
              const Icon(Icons.swap_horiz, size: 16),
              const SizedBox(width: 8),
              Text(l10n.scheduleRequestSwap),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final team = state.filteredTeam;
        final today = DateTime.now();

        return LayoutBuilder(
          builder: (_, constraints) {
            _gridWidth = constraints.maxWidth;
            return Listener(
              onPointerUp: (_) {
                if (_isDragging) setState(() => _isDragging = false);
              },
              child: MouseRegion(
                onHover: (e) => _mousePos.value = e.localPosition,
                onExit: (_) => _mousePos.value = null,
                child: Stack(
                  children: [
                    // Grid: pinned employee column + scrollable day columns.
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEmpHeaderCell(state),
                            if (state.showPinnedManagerRow) _buildPinnedEmpCell(state),
                            for (int r = 0; r < team.length; r++) _buildEmpCell(team[r], r, state),
                            _buildCoverageLabelCell(),
                          ],
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            controller: _hScrollController,
                            scrollDirection: Axis.horizontal,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDayHeaderRow(state, today),
                                if (state.showPinnedManagerRow) _buildPinnedDayCellRow(state),
                                for (int r = 0; r < team.length; r++)
                                  _buildDayCellRow(context, state, team[r], r, today),
                                _buildCoverageDataRow(state, today),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Positioned.fill(
                      child: ListenableBuilder(
                        listenable: Listenable.merge([_mousePos, _hScrollController]),
                        builder:
                            (_, __) => _buildArrowOverlay(_mousePos.value, team.length, state.showPinnedManagerRow),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildArrowOverlay(Offset? pos, int teamLength, bool hasPinnedRow) {
    if (pos == null || !_hScrollController.hasClients) return const SizedBox.shrink();

    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final scrollOffset = _hScrollController.offset;
    final maxScroll = _hScrollController.position.maxScrollExtent;
    final canScrollToStart = scrollOffset > 0;
    final canScrollToEnd = scrollOffset < maxScroll;

    const threshold = 80.0;
    // The employee column is pinned on the leading side (physical left in LTR, right
    // in RTL); the day area fills the rest. The "to-start" arrow sits at the day-area
    // edge next to the employee column, the "to-end" arrow at the far edge.
    final showStart =
        canScrollToStart && (isRtl ? pos.dx > _gridWidth - _empColW - threshold : pos.dx < _empColW + threshold);
    final showEnd = canScrollToEnd && (isRtl ? pos.dx < threshold : pos.dx > _gridWidth - threshold);
    if (!showStart && !showEnd) return const SizedBox.shrink();

    // Snap to the vertical center of the hovered row, not exact mouse Y.
    // The pinned N+1 row (when present) occupies one _rowH below the header.
    final pinnedH = hasPinnedRow ? _rowH : 0.0;
    final double rowCenterY;
    if (pos.dy < _headerH) {
      rowCenterY = _headerH / 2;
    } else if (hasPinnedRow && pos.dy < _headerH + pinnedH) {
      rowCenterY = _headerH + pinnedH / 2;
    } else {
      final rowIndex = ((pos.dy - _headerH - pinnedH) / _rowH).floor().clamp(0, (teamLength - 1).clamp(0, teamLength));
      rowCenterY = _headerH + pinnedH + rowIndex * _rowH + _rowH / 2;
    }
    final top = (rowCenterY - 14).clamp(0.0, double.infinity);

    return Stack(
      children: [
        if (showStart)
          Positioned(
            left: isRtl ? null : _empColW + 4,
            right: isRtl ? _empColW + 4 : null,
            top: top,
            child: _HScrollArrow(Icons.chevron_left, () => _scrollToEdge(false)),
          ),
        if (showEnd)
          Positioned(
            left: isRtl ? 4 : null,
            right: isRtl ? null : 4,
            top: top,
            child: _HScrollArrow(Icons.chevron_right, () => _scrollToEdge(true)),
          ),
      ],
    );
  }

  // ── Pinned employee column ──────────────────────────────────────────────

  Widget _buildEmpHeaderCell(ScheduleState state) {
    return Container(
      width: _empColW,
      height: _headerH,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: SC.lineColor), right: BorderSide(color: SC.lineColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          AppLocalizations.of(context)!.scheduleEmployeeColumn(state.filteredTeam.length),
          textAlign: TextAlign.start,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SC.muted, letterSpacing: 0.3),
        ),
      ),
    );
  }

  Widget _buildEmpCell(UserModel emp, int rowIndex, ScheduleState state) {
    return Container(
      width: _empColW,
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: SC.lineColor2))),
      child: _EmployeeCell(emp: emp, index: rowIndex),
    );
  }

  // ── Pinned comparison row ───────────────────────────────────────────────
  // Team view → my own row, self-draft editable (empty cells and my own
  // drafts open the editor; my N+1 publishes). Colleagues view → my N+1
  // manager, read-only.

  Widget _buildPinnedBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: _pinnedAccent, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Colors.white)),
    );
  }

  Widget _buildPinnedEmpCell(ScheduleState state) {
    final manager = state.pinnedManager!;
    final l10n = AppLocalizations.of(context)!;
    final badge =
        state.viewMode == ScheduleViewMode.colleagues ? l10n.schedulePinnedManagerBadge : l10n.schedulePinnedSelfBadge;
    return Container(
      key: TutorialKeys.schPinnedRow,
      width: _empColW,
      decoration: const BoxDecoration(color: _pinnedRowBg, border: Border(bottom: BorderSide(color: SC.lineColor2))),
      child: Stack(
        children: [
          _EmployeeCell(emp: manager, index: 0),
          PositionedDirectional(bottom: 6, end: 8, child: _buildPinnedBadge(badge)),
        ],
      ),
    );
  }

  Widget _buildPinnedDayCellRow(ScheduleState state) {
    final manager = state.pinnedManager!;
    final sched = state.pinnedManagerSchedule;
    // Team mode pins MY row: allow drafting my own schedule (published shifts
    // and days my manager reserved stay locked). Colleagues mode pins my N+1:
    // strictly read-only.
    final selfEditable = state.viewMode != ScheduleViewMode.colleagues && !state.isPastWeek;
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SC.lineColor2))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int d = 0; d < 7; d++)
            Builder(
              builder: (context) {
                final shift = sched['${manager.id}-$d'];
                final reserved = selfEditable && state.reservedSelfDays.contains(d);
                final canEdit = selfEditable && !reserved && state.canSelfEdit(shift);
                // Selection keys for the pinned self row use the 'self-$d' prefix
                // (mapped back to my own id in _confirmBulkAssign).
                final selKey = 'self-$d';
                final isSelected = canEdit && _selected.contains(selKey);
                final cell = _ShiftCell(
                  shift: shift,
                  leaveType:
                      (shift != null && !shift.isLeave) ? state.pinnedManagerLeaveKeys['${manager.id}-$d'] : null,
                  isWeekend: d == 5 || d == 6,
                  isSelected: isSelected,
                  hideAddIcon: !canEdit || widget.onAssignCell == null,
                  showConflict: false,
                  reserved: reserved,
                  width: _dayColW,
                  minHeight: _cellMinH,
                  rowHeight: _rowH,
                  bgOverride: _pinnedRowBg,
                );
                if (!canEdit) return cell;
                // Mirror the team-row bulk-select gestures, but scoped to this one
                // row: drag across days, long-press to start, tap to toggle.
                return Listener(
                  onPointerDown: (e) {
                    setState(() {
                      _isDragging = true;
                      _dragStarted = false;
                      _selStartRow = _kPinnedRow;
                      _selStartDay = d;
                      _lastTapPosition = e.position;
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) {
                      if (!_isDragging || _selStartRow != _kPinnedRow) return;
                      if (widget.onBulkAssign == null) return;
                      if (d != _selStartDay) {
                        setState(() => _dragStarted = true);
                        _expandPinnedSelection(_selStartDay, d, state);
                        _showOrUpdateSheet(context);
                      }
                    },
                    child: GestureDetector(
                      onLongPress: () {
                        if (widget.onBulkAssign == null) return;
                        setState(() => _addSelected(selKey));
                        _showOrUpdateSheet(context);
                      },
                      onTap: () {
                        if (_dragStarted) {
                          setState(() => _dragStarted = false);
                          return;
                        }
                        if (_selected.isEmpty) {
                          if (shift != null) {
                            widget.onEditShift?.call(shift);
                          } else {
                            widget.onAssignCell?.call('${manager.id}-$d');
                          }
                          return;
                        }
                        setState(() {
                          if (_selected.contains(selKey)) {
                            _selected.remove(selKey);
                            if (_selected.isEmpty) {
                              _dismissSheet();
                            } else {
                              _setSheetState?.call(() {});
                            }
                          } else {
                            _addSelected(selKey);
                            _showOrUpdateSheet(context);
                          }
                        });
                      },
                      child: cell,
                    ),
                  ),
                );
              },
            ),
          _SummaryCell(
            summary: _summaryFor(AppLocalizations.of(context)!, sched, state.pinnedManagerLeaveKeys, manager.id),
            bgOverride: _pinnedRowBg,
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageLabelCell() {
    return Container(
      width: _empColW,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FC),
        border: Border(top: BorderSide(color: SC.lineColor), right: BorderSide(color: SC.lineColor)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          AppLocalizations.of(context)!.scheduleCoverage,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: SC.muted),
        ),
      ),
    );
  }

  // ── Scrollable day columns ──────────────────────────────────────────────

  Widget _buildDayHeaderRow(ScheduleState state, DateTime today) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: SC.lineColor))),
      height: _headerH,
      child: Row(
        children: [
          for (int d = 0; d < 7; d++)
            _DayHeader(
              date: state.weekStart.add(Duration(days: d)),
              isToday: _sameDay(state.weekStart.add(Duration(days: d)), today),
              width: _dayColW,
              state: state,
              dayIndex: d,
            ),
          _buildSummaryHeaderCell(),
        ],
      ),
    );
  }

  Widget _buildSummaryHeaderCell() {
    return Container(
      width: _summaryColW,
      height: _headerH,
      decoration: BoxDecoration(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          AppLocalizations.of(context)!.scheduleSummary,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SC.muted, letterSpacing: 0.3),
        ),
      ),
    );
  }

  Widget _buildDayCellRow(BuildContext context, ScheduleState state, UserModel emp, int rowIndex, DateTime today) {
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: SC.lineColor2))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...List.generate(7, (d) {
            final key = '${emp.id}-$d';
            final shift = state.effectiveSchedule[key];
            final leaveType = (shift != null && !shift.isLeave) ? state.leaveKeys[key] : null;
            final isWeekend = d == 5 || d == 6;
            final selKey = '$rowIndex-$d';
            final isSelected = _selected.contains(selKey);
            return Listener(
              onPointerDown: (e) {
                setState(() {
                  _isDragging = true;
                  _dragStarted = false;
                  _selStartRow = rowIndex;
                  _selStartDay = d;
                  _pendingCellKey = key;
                  _pendingCellShift = shift;
                  _pendingCellEmp = emp;
                  _pendingCellDay = d;
                  _lastTapPosition = e.position;
                });
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) {
                  if (!_isDragging) return;
                  // A drag that began on the pinned self row stays there.
                  if (_selStartRow == _kPinnedRow) return;
                  // Colleagues mode: multi-select is limited to my own row's
                  // editable cells (self-draft feature).
                  if (state.viewMode == ScheduleViewMode.colleagues && !_canSelfSelect(state, emp, d, shift)) {
                    return;
                  }
                  if (widget.onBulkAssign == null) return;
                  if (rowIndex != _selStartRow || d != _selStartDay) {
                    setState(() => _dragStarted = true);
                    _expandSelection(
                      _selStartRow,
                      _selStartDay,
                      state.viewMode == ScheduleViewMode.colleagues ? _selStartRow : rowIndex,
                      d,
                      state: state,
                    );
                    _showOrUpdateSheet(context);
                  }
                },
                child: GestureDetector(
                  onLongPress: () {
                    if (state.viewMode == ScheduleViewMode.colleagues && !_canSelfSelect(state, emp, d, shift)) {
                      return;
                    }
                    if (widget.onBulkAssign == null) return;
                    setState(() => _addSelected(selKey));
                    _showOrUpdateSheet(context);
                  },
                  onTap: () {
                    if (_dragStarted) {
                      setState(() => _dragStarted = false);
                      return;
                    }
                    final cellKey = _pendingCellKey;
                    final cellShift = _pendingCellShift;
                    final cellEmp = _pendingCellEmp;
                    final cellDay = _pendingCellDay;
                    final tapPos = _lastTapPosition;
                    setState(() {
                      _pendingCellKey = null;
                      _pendingCellShift = null;
                      _pendingCellEmp = null;
                    });
                    if (_selected.isEmpty) {
                      if (state.viewMode == ScheduleViewMode.colleagues && cellEmp != null) {
                        // My own row: empty cells and my own drafts open the
                        // shift editor (self-draft). Reserved days (manager
                        // draft in progress) are inert; published shifts fall
                        // through to the swap menu as before.
                        if (cellEmp.id == state.managerId && state.reservedSelfDays.contains(cellDay)) {
                          return;
                        }
                        if (_canSelfSelect(state, cellEmp, cellDay, cellShift)) {
                          if (cellShift != null) {
                            widget.onEditShift?.call(cellShift);
                          } else if (cellKey != null) {
                            widget.onAssignCell?.call(cellKey);
                          }
                          return;
                        }
                        _showColleagueSwapMenu(context, state, cellEmp, cellDay, cellShift, tapPos);
                        return;
                      }
                      if (cellShift != null) {
                        widget.onEditShift?.call(cellShift);
                      } else if (cellKey != null) {
                        widget.onAssignCell?.call(cellKey);
                      }
                    } else {
                      if (state.viewMode == ScheduleViewMode.colleagues &&
                          !_selected.contains(selKey) &&
                          !_canSelfSelect(state, emp, d, shift)) {
                        return;
                      }
                      setState(() {
                        if (_selected.contains(selKey)) {
                          _selected.remove(selKey);
                          if (_selected.isEmpty) {
                            _dismissSheet();
                          } else {
                            _setSheetState?.call(() {});
                          }
                        } else {
                          _addSelected(selKey);
                          _showOrUpdateSheet(context);
                        }
                      });
                    }
                  },
                  child: _ShiftCell(
                    shift: shift,
                    leaveType: leaveType,
                    isWeekend: isWeekend,
                    isSelected: isSelected,
                    hideAddIcon:
                        (state.viewMode == ScheduleViewMode.colleagues && !_canSelfSelect(state, emp, d, shift)) ||
                        widget.onAssignCell == null,
                    showConflict: state.viewMode != ScheduleViewMode.colleagues,
                    reserved:
                        state.viewMode == ScheduleViewMode.colleagues &&
                        emp.id == state.managerId &&
                        state.reservedSelfDays.contains(d),
                    width: _dayColW,
                    minHeight: _cellMinH,
                    rowHeight: _rowH,
                  ),
                ),
              ),
            );
          }),
          _SummaryCell(
            summary: _summaryFor(AppLocalizations.of(context)!, state.effectiveSchedule, state.leaveKeys, emp.id),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverageDataRow(ScheduleState state, DateTime today) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFF7F9FC), border: Border(top: BorderSide(color: SC.lineColor))),
      child: Row(
        children: [
          ...List.generate(7, (d) {
            final date = state.weekStart.add(Duration(days: d));
            final isToday = _sameDay(date, today);
            final filteredIds = state.filteredTeam.map((e) => e.id.toString()).toSet();
            final dayEntries = state.effectiveSchedule.entries.where((e) {
              final parts = e.key.split('-');
              return parts[1] == '$d' &&
                  filteredIds.contains(parts[0]) &&
                  !e.value.isLeave &&
                  !e.value.isOffType &&
                  !state.leaveKeys.containsKey(e.key);
            });
            final staffed = dayEntries.length;
            final total = state.filteredTeam.length;
            final ratio = total == 0 ? 0.0 : staffed / total;
            final hours = dayEntries.fold(0.0, (s, e) => s + e.value.hours);
            final barColor =
                ratio >= 0.7
                    ? SC.green
                    : ratio > 1.05
                    ? SC.rose
                    : SC.amber;
            return Container(
              width: _dayColW,
              height: 44,
              decoration: BoxDecoration(
                color: isToday ? SC.blue50 : null,
                border: Border(right: BorderSide(color: SC.lineColor2)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$staffed / $total  ·  ${hours.toStringAsFixed(0)}h',
                    style: const TextStyle(fontSize: 10.5, color: SC.muted),
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: SC.lineColor,
                        valueColor: AlwaysStoppedAnimation(barColor),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Container(
            width: _summaryColW,
            height: 44,
            decoration: const BoxDecoration(border: Border(right: BorderSide(color: SC.lineColor2))),
          ),
        ],
      ),
    );
  }

  // A selection key for a pinned self-row cell (vs a numeric '$rowIndex-$d'
  // team-row key). Self keys map back to state.managerId in _confirmBulkAssign.
  bool _isSelfKey(String k) => k.startsWith('self-');

  // Selection is kept homogeneous — either all pinned self cells or all team
  // cells — because the downstream save path (_onSaveShift) files ownership per
  // batch, so a mixed batch would misfile the self row and fail RLS. Adding a
  // key of the other kind starts a fresh selection.
  void _addSelected(String key) {
    final self = _isSelfKey(key);
    if (_selected.any((k) => _isSelfKey(k) != self)) _selected.clear();
    _selected.add(key);
  }

  /// Self-draft gate: in colleagues mode only my own row's cells are
  /// selectable/editable, and only while the cell is empty or holds a draft I
  /// own — published shifts, leave days and manager-reserved days are locked.
  bool _canSelfSelect(ScheduleState state, UserModel emp, int d, ScheduleModel? shift) =>
      emp.id == state.managerId && !state.isPastWeek && !state.reservedSelfDays.contains(d) && state.canSelfEdit(shift);

  void _expandSelection(int r1, int d1, int r2, int d2, {ScheduleState? state}) {
    final minR = r1 < r2 ? r1 : r2;
    final maxR = r1 > r2 ? r1 : r2;
    final minD = d1 < d2 ? d1 : d2;
    final maxD = d1 > d2 ? d1 : d2;
    setState(() {
      _selected.clear();
      for (int r = minR; r <= maxR; r++) {
        for (int d = minD; d <= maxD; d++) {
          // Colleagues mode: skip cells I'm not allowed to draft over.
          if (state != null && state.viewMode == ScheduleViewMode.colleagues) {
            if (r >= state.filteredTeam.length) continue;
            final emp = state.filteredTeam[r];
            final shift = state.effectiveSchedule['${emp.id}-$d'];
            if (!_canSelfSelect(state, emp, d, shift)) continue;
          }
          _selected.add('$r-$d');
        }
      }
    });
  }

  /// Drag-expand across days within the single pinned self row. Only editable
  /// cells (empty or my own draft) are added, as 'self-$d' keys.
  void _expandPinnedSelection(int d1, int d2, ScheduleState state) {
    final manager = state.pinnedManager;
    if (manager == null) return;
    final minD = d1 < d2 ? d1 : d2;
    final maxD = d1 > d2 ? d1 : d2;
    setState(() {
      _selected.clear();
      for (int d = minD; d <= maxD; d++) {
        final shift = state.pinnedManagerSchedule['${manager.id}-$d'];
        if (!_canSelfSelect(state, manager, d, shift)) continue;
        _selected.add('self-$d');
      }
    });
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _DayHeader extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final double width;
  final ScheduleState state;
  final int dayIndex;

  const _DayHeader({
    required this.date,
    required this.isToday,
    required this.width,
    required this.state,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context) {
    final filteredIds = state.filteredTeam.map((e) => e.id.toString()).toSet();
    final dayEntries = state.schedule.entries.where((e) {
      final parts = e.key.split('-');
      return parts[1] == '$dayIndex' && filteredIds.contains(parts[0]);
    });
    final staffed = dayEntries.where((e) => !e.value.isLeave).length;
    final onLeave = dayEntries.where((e) => e.value.isLeave).length;
    final total = state.filteredTeam.length;
    final ratio = total == 0 ? 0.0 : staffed / total;

    return Container(
      width: width,
      height: _headerH,
      decoration: BoxDecoration(
        color: isToday ? SC.blue50 : null,
        border: Border(right: BorderSide(color: SC.lineColor2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                SC.localizedDayNames(AppLocalizations.of(context)!)[dayIndex],
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isToday ? SC.blue : SC.muted),
              ),
              const SizedBox(width: 4),
              Text(
                '${date.day}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isToday ? SC.blue : SC.ink),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _MiniBar(color: SC.green, value: staffed, total: total),
              const SizedBox(width: 2),
              if (onLeave > 0) _MiniBar(color: SC.rose, value: onLeave, total: total),
              if (ratio < 0.7 && staffed < total)
                _MiniBar(color: SC.amber, value: total - staffed - onLeave, total: total),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final Color color;
  final int value;
  final int total;

  const _MiniBar({required this.color, required this.value, required this.total});

  @override
  Widget build(BuildContext context) {
    if (value <= 0 || total <= 0) return const SizedBox.shrink();
    return Container(
      width: (value / total * 40).clamp(4.0, 40.0),
      height: 4,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
  }
}

class _EmployeeCell extends StatelessWidget {
  final UserModel emp;
  final int index;

  const _EmployeeCell({required this.emp, required this.index});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final rawName = emp.getLocalizedName(locale);
    final fullName = rawName.isNotEmpty ? rawName : '—';
    final nickname = emp.getLocalizedNickname(locale) ?? '—';
    final initials = SC.avatarInitials(nickname);
    final color = SC.avatarColor(index);
    final code = emp.id != null ? '#${emp.id}' : '';
    final position = emp.getLocalizedTitle(locale);
    final department = emp.getLocalizedDepartment(locale);

    return Container(
      height: _rowH,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(border: Border(right: BorderSide(color: SC.lineColor))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color,
            child: Text(
              initials,
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
          // Positioned(
          //   bottom: 0,
          //   right: 0,
          //   child: Container(
          //     width: 8,
          //     height: 8,
          //     decoration: BoxDecoration(
          //       color: SC.green,
          //       shape: BoxShape.circle,
          //       border: Border.all(color: Colors.white, width: 1.5),
          //     ),
          //   ),
          // ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                SafeTooltip(
                  message: fullName,
                  child: Text(
                    nickname,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SC.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (code.isNotEmpty)
                  Text(code, style: const TextStyle(fontSize: 9.5, color: SC.muted), overflow: TextOverflow.ellipsis),
                if (position.isNotEmpty)
                  Text(
                    position,
                    style: const TextStyle(fontSize: 9.5, color: SC.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (department.isNotEmpty)
                  Text(
                    department,
                    style: const TextStyle(fontSize: 9.5, color: SC.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftCell extends StatefulWidget {
  final ScheduleModel? shift;
  final String? leaveType;
  final bool isWeekend;
  final bool isSelected;
  final bool hideAddIcon;
  final bool showConflict;
  // Day is occupied by a draft my manager owns: render an inert neutral
  // placeholder instead of an empty (tappable-looking) cell.
  final bool reserved;
  final double width;
  final double minHeight;
  final double rowHeight;
  // When set, replaces the default white/weekend background (used by the pinned
  // N+1 comparison row to tint the whole row).
  final Color? bgOverride;

  const _ShiftCell({
    required this.shift,
    this.leaveType,
    required this.isWeekend,
    required this.isSelected,
    this.hideAddIcon = false,
    this.showConflict = true,
    this.reserved = false,
    required this.width,
    required this.minHeight,
    required this.rowHeight,
    this.bgOverride,
  });

  @override
  State<_ShiftCell> createState() => _ShiftCellState();
}

class _ShiftCellState extends State<_ShiftCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        width: widget.width,
        height: widget.rowHeight,
        decoration: BoxDecoration(
          color:
              widget.isSelected
                  ? SC.blue50
                  : widget.bgOverride ?? (widget.isWeekend ? const Color(0xFFFAFBFD) : Colors.white),
          border: Border(
            right: BorderSide(color: SC.lineColor2),
            bottom: widget.isSelected ? BorderSide(color: SC.blue, width: 2) : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.all(6),
        child:
            shift != null
                ? (widget.leaveType != null && !shift.isLeave
                    ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Flexible(child: _ShiftChip(shift: shift, showConflict: widget.showConflict)),
                        const SizedBox(height: 3),
                        _LeavePill(leaveType: widget.leaveType!),
                      ],
                    )
                    : _ShiftChip(shift: shift, showConflict: widget.showConflict))
                : widget.reserved
                ? const _ReservedCellPlaceholder()
                : !widget.hideAddIcon && (_hovered || widget.isSelected)
                ? Center(child: Icon(Icons.add, size: 18, color: SC.muted2))
                : null,
      ),
    );
  }
}

/// Neutral placeholder for a day my manager has a draft on ("reserved") —
/// shows that the slot is taken without leaking the draft's contents.
class _ReservedCellPlaceholder extends StatelessWidget {
  const _ReservedCellPlaceholder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeTooltip(
      message: l10n.scheduleReservedByManager,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: SC.lineColor2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 12, color: SC.muted2),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                l10n.scheduleReservedByManager,
                style: const TextStyle(fontSize: 9.5, color: SC.muted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShiftChip extends StatelessWidget {
  final ScheduleModel shift;
  final bool showConflict;
  const _ShiftChip({required this.shift, this.showConflict = true});

  @override
  Widget build(BuildContext context) {
    final isDraft = !shift.isPublished && !shift.isLeave;
    final color = shift.shiftColor;
    final lightColor = shift.shiftLightColor;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration:
              isDraft
                  ? BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border(
                      top: BorderSide(color: SC.amber, width: 1),
                      bottom: BorderSide(color: SC.amber, width: 1),
                      left: BorderSide(color: SC.amber, width: 4),
                      right: BorderSide(color: SC.amber, width: 1),
                    ),
                  )
                  : BoxDecoration(
                    color: lightColor,
                    borderRadius: BorderRadius.circular(5),
                    border: Border(
                      left: BorderSide(color: color, width: 4),
                      top: BorderSide(color: color, width: 1),
                      bottom: BorderSide(color: color, width: 1),
                      right: BorderSide(color: color, width: 1),
                    ),
                  ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!shift.isOffType)
                Text(
                  SC.localizedTimeLabel(AppLocalizations.of(context)!, shift),
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: isDraft ? SC.amber : color),
                ),
              Text(
                SC.localizedShiftLabel(AppLocalizations.of(context)!, shift),
                style: TextStyle(fontSize: 10, color: isDraft ? SC.muted : color.withValues(alpha: 0.9)),
              ),
              // Employee-proposed draft: the row's owner (last writer) is the
              // employee themself — flag it so the manager can tell their own
              // drafts from the employee's proposal.
              if (isDraft && shift.isEmployeeProposed)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: const Color(0xFFC7D2FE)),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.scheduleProposedBadge,
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                  ),
                ),
            ],
          ),
        ),
        if (showConflict && shift.conflict != null)
          Positioned(
            top: -4,
            right: -4,
            child: SafeTooltip(
              message: _conflictMessage(AppLocalizations.of(context)!, shift.conflict!),
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

class _LeavePill extends StatelessWidget {
  final String leaveType;
  const _LeavePill({required this.leaveType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: SC.rose50,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: SC.rose.withValues(alpha: 0.35)),
      ),
      child: Text(
        SC.localizedLeaveType(AppLocalizations.of(context)!, leaveType),
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: SC.rose),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final _WeekSummary summary;
  final Color? bgOverride;

  const _SummaryCell({required this.summary, this.bgOverride});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: _summaryColW,
      height: _rowH,
      decoration: BoxDecoration(
        color: bgOverride ?? Colors.white,
        border: Border(right: BorderSide(color: SC.lineColor2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: SingleChildScrollView(
          child: SizedBox(
            width: _summaryColW,
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${summary.hours.toStringAsFixed(0)}h',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SC.ink),
                ),
                for (final st in summary.shiftTallies)
                  _SummaryPill(color: st.color, bg: st.bg, text: '${st.count} × ${st.label}'),
                for (final off in summary.offTallies)
                  _SummaryPill(color: off.color, bg: off.bg, text: '${off.count} × ${off.label}'),
                if (summary.conflictCount > 0)
                  _SummaryPill(
                    color: SC.amber,
                    bg: SC.amber50,
                    icon: Icons.warning,
                    text: '${summary.conflictCount} ${l10n.scheduleSummaryConflicts}',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final Color color;
  final Color bg;
  final String text;
  final IconData? icon;

  const _SummaryPill({required this.color, required this.bg, required this.text, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 10, color: color), const SizedBox(width: 3)],
          Text(
            text,
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HScrollArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HScrollArrow(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return SafeTooltip(
      message: AppLocalizations.of(context)!.scheduleScrollTooltip,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 1,
        child: InkWell(
          customBorder: const CircleBorder(),
          mouseCursor: SystemMouseCursors.click,
          onTap: onTap,
          child: SizedBox(width: 28, height: 28, child: Icon(icon, size: 18, color: SC.muted)),
        ),
      ),
    );
  }
}
