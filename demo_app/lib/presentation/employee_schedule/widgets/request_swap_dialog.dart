import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/data/models/shift_swap_request_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_event.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showRequestSwapDialog(
  BuildContext context, {
  required ScheduleModel shift,
  required DateTime shiftDate,
  required List<UserModel> teammates,
  required Map<int, ScheduleModel?> peerSchedulesForDay,
  required int currentUserId,
  required UserModel currentUser,
  int? preSelectedColleagueId,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black38,
    builder:
        (_) => BlocProvider.value(
          value: context.read<ScheduleBloc>(),
          child: _RequestSwapDialog(
            shift: shift,
            shiftDate: shiftDate,
            teammates: teammates,
            peerSchedulesForDay: peerSchedulesForDay,
            currentUserId: currentUserId,
            currentUser: currentUser,
            preSelectedColleagueId: preSelectedColleagueId,
          ),
        ),
  );
}

Future<void> showRequestSwapBottomSheet(
  BuildContext context, {
  required ScheduleModel shift,
  required DateTime shiftDate,
  required List<UserModel> teammates,
  required Map<int, ScheduleModel?> peerSchedulesForDay,
  required int currentUserId,
  required UserModel currentUser,
  int? preSelectedColleagueId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder:
        (_) => BlocProvider.value(
          value: context.read<ScheduleBloc>(),
          child: _RequestSwapDialog(
            shift: shift,
            shiftDate: shiftDate,
            teammates: teammates,
            peerSchedulesForDay: peerSchedulesForDay,
            currentUserId: currentUserId,
            currentUser: currentUser,
            preSelectedColleagueId: preSelectedColleagueId,
            asBottomSheet: true,
          ),
        ),
  );
}

Future<void> showShiftPickerDialog(
  BuildContext context, {
  required List<(DateTime, ScheduleModel)> swappableShifts,
  required List<UserModel> teammates,
  required Map<DateTime, Map<int, ScheduleModel?>> peerSchedulesByDate,
  required int currentUserId,
  required UserModel currentUser,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black38,
    builder:
        (_) => BlocProvider.value(
          value: context.read<ScheduleBloc>(),
          child: _ShiftPickerDialog(
            swappableShifts: swappableShifts,
            teammates: teammates,
            peerSchedulesByDate: peerSchedulesByDate,
            currentUserId: currentUserId,
            currentUser: currentUser,
          ),
        ),
  );
}

// ── Request Swap Dialog ──────────────────────────────────────────────────────

class _RequestSwapDialog extends StatefulWidget {
  final ScheduleModel shift;
  final DateTime shiftDate;
  final List<UserModel> teammates;
  final Map<int, ScheduleModel?> peerSchedulesForDay;
  final int currentUserId;
  final UserModel currentUser;
  final int? preSelectedColleagueId;
  final bool asBottomSheet;

  const _RequestSwapDialog({
    required this.shift,
    required this.shiftDate,
    required this.teammates,
    required this.peerSchedulesForDay,
    required this.currentUserId,
    required this.currentUser,
    this.preSelectedColleagueId,
    this.asBottomSheet = false,
  });

  @override
  State<_RequestSwapDialog> createState() => _RequestSwapDialogState();
}

class _RequestSwapDialogState extends State<_RequestSwapDialog> {
  UserModel? _selectedTeammate;
  ScheduleModel? _selectedTargetShift;
  final _reasonCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _submitting = false;
  bool _targetError = false;

  @override
  void initState() {
    super.initState();
    if (widget.preSelectedColleagueId != null) {
      final match = widget.teammates.where((u) => u.id == widget.preSelectedColleagueId).firstOrNull;
      if (match != null) {
        _selectedTeammate = match;
        _selectedTargetShift = widget.peerSchedulesForDay[match.id];
      }
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // Department-filtered pool — source of truth for eligibility
  List<UserModel> get _candidates {
    final dept = widget.currentUser.englishDepartment;
    return widget.teammates.where((u) {
      if (u.id == widget.currentUserId) return false;
      if (dept != null && u.englishDepartment != dept) return false;
      return true;
    }).toList();
  }

  // _candidates narrowed by search query and sorted: shift-holders first
  List<UserModel> get _sorted {
    final q = _searchQuery.toLowerCase();
    final filtered =
        q.isEmpty
            ? List<UserModel>.from(_candidates)
            : _candidates.where((u) => (u.englishName ?? u.arabicName ?? '').toLowerCase().contains(q)).toList();
    filtered.sort((a, b) {
      final aHasShift = widget.peerSchedulesForDay[a.id] != null ? 0 : 1;
      final bHasShift = widget.peerSchedulesForDay[b.id] != null ? 0 : 1;
      return aHasShift.compareTo(bHasShift);
    });
    return filtered;
  }

  bool get _hasEligibleCandidates => _candidates.any((u) {
    final s = widget.peerSchedulesForDay[u.id];
    if (s == null) return false;
    if (s.isLeaveType) return false;
    return s.customStart != widget.shift.customStart || s.customEnd != widget.shift.customEnd;
  });

  Future<void> _submit() async {
    if (_selectedTeammate == null) {
      setState(() => _targetError = true);
      return;
    }
    if (_selectedTargetShift == null || _selectedTargetShift!.isLeaveType) {
      setState(() => _targetError = true);
      return;
    }
    setState(() => _submitting = true);
    context.read<ScheduleBloc>().add(
      SubmitSwapRequest(
        ShiftSwapRequestModel(
          requesterId: widget.currentUserId,
          targetEmployeeId: _selectedTeammate!.id,
          scheduleId: widget.shift.id,
          targetScheduleId: _selectedTargetShift?.id,
          reason: _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim(),
          status: 'awaiting_target',
          // Requester identity
          requesterEnglishName: widget.currentUser.englishName,
          requesterArabicName: widget.currentUser.arabicName,
          requesterEnglishNickname: widget.currentUser.englishNickname,
          requesterArabicNickname: widget.currentUser.arabicNickname,
          // Target identity
          targetEnglishName: _selectedTeammate!.englishName,
          targetArabicName: _selectedTeammate!.arabicName,
          targetEnglishNickname: _selectedTeammate!.englishNickname,
          targetArabicNickname: _selectedTeammate!.arabicNickname,
          // Requester shift location
          scheduleEmployeeId: widget.shift.employeeId,
          scheduleWeekStart: widget.shift.weekStart,
          scheduleDayIndex: widget.shift.dayIndex,
          scheduleStart: widget.shift.customStart,
          scheduleEnd: widget.shift.customEnd,
          // Target shift location
          targetScheduleStart: _selectedTargetShift?.customStart,
          targetScheduleEnd: _selectedTargetShift?.customEnd,
          targetScheduleDayIndex: _selectedTargetShift?.dayIndex,
        ),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final months = SC.localizedMonthNames(l10n);
    final d = widget.shiftDate;
    final dateLabel = '${SC.localizedDayFromWeekday(l10n, d.weekday)}, ${d.day} ${months[d.month]}';
    final timeLabel = '${SC.fmtHour(widget.shift.customStart)} – ${SC.fmtHour(widget.shift.customEnd)}';

    if (widget.asBottomSheet) {
      return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder:
            (ctx, scrollCtrl) => Column(
              children: [
                _buildHeader(dateLabel, timeLabel),
                Flexible(
                  child: SingleChildScrollView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildShiftSummary(dateLabel, timeLabel),
                        const SizedBox(height: 20),
                        _buildColleaguePicker(),
                        const SizedBox(height: 16),
                        _buildReasonField(),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(dateLabel, timeLabel),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildShiftSummary(dateLabel, timeLabel),
                    const SizedBox(height: 20),
                    _buildColleaguePicker(),
                    const SizedBox(height: 16),
                    _buildReasonField(),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String date, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SC.lineColor))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.scheduleRequestSwapTitle,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SC.ink),
                ),
                Text('$date · $time', style: const TextStyle(fontSize: 12, color: SC.muted)),
              ],
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close, size: 18, color: SC.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftSummary(String date, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: widget.shift.shiftLightColor,
        border: Border.all(color: widget.shift.shiftColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 15, color: widget.shift.shiftColor),
          const SizedBox(width: 8),
          Text(
            '${SC.localizedShiftLabel(AppLocalizations.of(context)!, widget.shift)}  ·  $time  ·  $date',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: widget.shift.shiftColor),
          ),
        ],
      ),
    );
  }

  Widget _buildColleaguePicker() {
    final list = _sorted;
    final locale = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.scheduleSwapWith,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SC.ink),
            ),
            const SizedBox(width: 4),
            const Text('*', style: TextStyle(color: SC.rose, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: _targetError ? SC.rose : SC.lineColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged:
                      (v) => setState(() {
                        _searchQuery = v;
                        _targetError = false;
                      }),
                  style: const TextStyle(fontSize: 13, color: SC.ink),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.scheduleSearchColleague,
                    hintStyle: TextStyle(color: SC.muted2, fontSize: 13),
                    prefixIcon: Icon(Icons.search, size: 16, color: SC.muted2),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                  ),
                ),
              ),
              const Divider(height: 1, color: SC.lineColor),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final u = list[i];
                    final rawName = u.getLocalizedName(locale);
                    final name = rawName.isNotEmpty ? rawName : '—';
                    final dept = u.getLocalizedDepartment(locale);
                    final selected = _selectedTeammate?.id == u.id;
                    final peerShift = widget.peerSchedulesForDay[u.id];
                    final isSameShift =
                        peerShift != null &&
                        peerShift.customStart == widget.shift.customStart &&
                        peerShift.customEnd == widget.shift.customEnd;
                    final isIneligible =
                        isSameShift || peerShift == null || peerShift.isLeaveType || peerShift.isOffType;

                    final row = Container(
                      color: selected ? SC.blue50 : Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Opacity(
                            opacity: isIneligible ? 0.45 : 1.0,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: SC.avatarColor(i),
                              child: Text(
                                SC.avatarInitials(name),
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                    color: isIneligible ? SC.muted2 : SC.ink,
                                  ),
                                ),
                                if (dept.isNotEmpty) Text(dept, style: const TextStyle(fontSize: 11, color: SC.muted)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isSameShift)
                            Text(
                              AppLocalizations.of(context)!.scheduleSameShift,
                              style: const TextStyle(fontSize: 10.5, color: SC.muted2),
                            )
                          else if (isIneligible && peerShift != null)
                            Text(
                              SC.localizedShiftLabel(AppLocalizations.of(context)!, peerShift),
                              style: const TextStyle(fontSize: 10.5, color: SC.muted2),
                            )
                          else if (peerShift != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: peerShift.shiftLightColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                SC.localizedTimeLabel(AppLocalizations.of(context)!, peerShift),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: peerShift.shiftColor,
                                ),
                              ),
                            )
                          else
                            Text(
                              AppLocalizations.of(context)!.scheduleDayOff,
                              style: const TextStyle(fontSize: 10.5, color: SC.muted2),
                            ),
                          const SizedBox(width: 6),
                          if (selected) const Icon(Icons.check, size: 16, color: SC.blue),
                        ],
                      ),
                    );

                    if (isIneligible) return row;
                    return MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap:
                            () => setState(() {
                              _selectedTeammate = u;
                              _selectedTargetShift = peerShift;
                              _targetError = false;
                            }),
                        child: row,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (_targetError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text(
              AppLocalizations.of(context)!.schedulePleaseSelectColleague,
              style: const TextStyle(fontSize: 11, color: SC.rose),
            ),
          ),
      ],
    );
  }

  Widget _buildReasonField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.scheduleReasonOptional,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SC.ink),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _reasonCtrl,
          maxLines: 3,
          style: const TextStyle(fontSize: 13, color: SC.ink),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.scheduleWhySwapHint,
            hintStyle: const TextStyle(color: SC.muted2, fontSize: 13),
            contentPadding: const EdgeInsets.all(12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: SC.lineColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: SC.lineColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: SC.blue),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: SC.lineColor))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: SC.lineColor),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(fontSize: 13, color: SC.ink2)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          MouseRegion(
            cursor: (_submitting || !_hasEligibleCandidates) ? SystemMouseCursors.basic : SystemMouseCursors.click,
            child: GestureDetector(
              onTap: (_submitting || !_hasEligibleCandidates) ? null : _submit,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _hasEligibleCandidates ? SC.blue : SC.muted2,
                  borderRadius: BorderRadius.circular(7),
                ),
                child:
                    _submitting
                        ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                        : Text(
                          AppLocalizations.of(context)!.scheduleSendRequest,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shift Picker Dialog ──────────────────────────────────────────────────────

class _ShiftPickerDialog extends StatelessWidget {
  final List<(DateTime, ScheduleModel)> swappableShifts;
  final List<UserModel> teammates;
  final Map<DateTime, Map<int, ScheduleModel?>> peerSchedulesByDate;
  final int currentUserId;
  final UserModel currentUser;

  const _ShiftPickerDialog({
    required this.swappableShifts,
    required this.teammates,
    required this.peerSchedulesByDate,
    required this.currentUserId,
    required this.currentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            swappableShifts.isEmpty
                ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    AppLocalizations.of(context)!.scheduleNoUpcomingShifts,
                    style: const TextStyle(color: SC.muted, fontSize: 13),
                  ),
                )
                : Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: swappableShifts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (_, i) => _buildShiftTile(context, swappableShifts[i]),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: SC.lineColor))),
      child: Row(
        children: [
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.scheduleSelectShift,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SC.ink),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close, size: 18, color: SC.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftTile(BuildContext context, (DateTime, ScheduleModel) entry) {
    final (date, shift) = entry;
    final l10n = AppLocalizations.of(context)!;
    final months = SC.localizedMonthNames(l10n);
    final dateLabel = '${SC.localizedDayFromWeekday(l10n, date.weekday)}, ${date.day} ${months[date.month]}';
    final timeLabel = '${SC.fmtHour(shift.customStart)} – ${SC.fmtHour(shift.customEnd)}';

    // Lookup peers' schedules for this specific date
    final dateKey = DateTime(date.year, date.month, date.day);
    final peersForDay = peerSchedulesByDate[dateKey] ?? {};

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
          showRequestSwapDialog(
            context,
            shift: shift,
            shiftDate: date,
            teammates: teammates,
            peerSchedulesForDay: peersForDay,
            currentUserId: currentUserId,
            currentUser: currentUser,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: SC.lineColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 36,
                decoration: BoxDecoration(color: shift.shiftColor, borderRadius: BorderRadius.circular(3)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      SC.localizedShiftLabel(AppLocalizations.of(context)!, shift),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SC.ink),
                    ),
                    Text('$timeLabel  ·  $dateLabel', style: const TextStyle(fontSize: 11.5, color: SC.muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 16, color: SC.muted2),
            ],
          ),
        ),
      ),
    );
  }
}
