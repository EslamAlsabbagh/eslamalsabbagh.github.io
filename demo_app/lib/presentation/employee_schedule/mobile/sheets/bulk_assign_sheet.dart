import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/data/models/shift_template_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_event.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_tokens.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/widgets/mobile_avatar.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows the Bulk Assign bottom sheet.
///
/// [presetDayIndex] pre-selects a day chip (0–6). When null every chip starts
/// unselected. [presetEmployeeIds] pre-checks specific employees.
Future<void> showBulkAssignSheet(BuildContext context, {int? presetDayIndex, List<int>? presetEmployeeIds}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: MT.bgPage,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder:
        (_) => BlocProvider.value(
          value: context.read<ScheduleBloc>(),
          child: BulkAssignSheet(presetDayIndex: presetDayIndex, presetEmployeeIds: presetEmployeeIds ?? []),
        ),
  );
}

class BulkAssignSheet extends StatefulWidget {
  final int? presetDayIndex;
  final List<int> presetEmployeeIds;

  const BulkAssignSheet({super.key, this.presetDayIndex, this.presetEmployeeIds = const []});

  @override
  State<BulkAssignSheet> createState() => _BulkAssignSheetState();
}

class _BulkAssignSheetState extends State<BulkAssignSheet> {
  ShiftTemplateModel? _selectedTemplate;
  String? _offTypeNote;
  double _customStart = 8.0;
  double _customEnd = 16.0;
  bool _saveAsTemplate = false;
  bool _nameError = false;
  bool _initialized = false;
  final TextEditingController _nameCtrl = TextEditingController();
  final Set<int> _selectedDays = {};
  final Set<int> _selectedEmpIds = {};
  final Set<String> _expandedDepts = {};
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.presetDayIndex != null) _selectedDays.add(widget.presetDayIndex!);
    _selectedEmpIds.addAll(widget.presetEmployeeIds);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final state = context.read<ScheduleBloc>().state;
    final templates = state.topTemplates;
    if (templates.isNotEmpty) {
      _selectedTemplate = templates.first;
      _customStart = templates.first.customStart;
      _customEnd = templates.first.customEnd;
    }
    // Self-draft mode: the sheet only assigns to my own row.
    if (state.isSelfOnly && state.managerId != null) {
      _selectedEmpIds
        ..clear()
        ..add(state.managerId!);
    }
  }

  /// Self-draft mode: days I may not touch (published shifts, leave days,
  /// drafts my manager owns) are locked in the day picker.
  bool _isDayLocked(ScheduleState state, int dayIndex) {
    if (!state.isSelfOnly) return false;
    if (state.reservedSelfDays.contains(dayIndex)) return true;
    return !state.canSelfEdit(state.selfSchedule['${state.managerId}-$dayIndex']);
  }

  /// True when I (a manager) have at least one day this week I'm allowed to
  /// draft on my own row. Gates the self row in the picker — no editable days
  /// means I shouldn't appear as a bulk-assign target at all.
  bool _hasEditableSelfDays(ScheduleState state) {
    if (state.isPastWeek || state.selfUser == null || state.managerId == null) {
      return false;
    }
    for (int d = 0; d < 7; d++) {
      if (!state.reservedSelfDays.contains(d) && state.canSelfEdit(state.selfSchedule['${state.managerId}-$d'])) {
        return true;
      }
    }
    return false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  double _computeHours() => _customEnd > _customStart ? _customEnd - _customStart : (24 - _customStart) + _customEnd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final total = _selectedDays.length * _selectedEmpIds.length;
        return DraggableScrollableSheet(
          initialChildSize: 0.94,
          minChildSize: 0.5,
          maxChildSize: 0.94,
          expand: false,
          builder:
              (ctx, scrollCtrl) => Column(
                children: [
                  // ── Handle + title ───────────────────────────────────────
                  _SheetHeader(title: l10n.mobileBulkAssignTitle),
                  // ── Scrollable body ──────────────────────────────────────
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.only(bottom: 8),
                      children: [
                        _buildStep1(l10n, state),
                        _buildStep2(l10n, state),
                        _buildStep3(l10n, state),
                        _buildSummary(l10n, state, total),
                      ],
                    ),
                  ),
                  // ── Footer CTAs ──────────────────────────────────────────
                  _buildFooter(context, l10n, state, total),
                ],
              ),
        );
      },
    );
  }

  // ── Step 1: Shift template ─────────────────────────────────────────────────

  Widget _buildStep1(AppLocalizations l10n, ScheduleState state) {
    final endLabel = _customEnd == 0.0 ? '00:00' : SC.fmtHour(_customEnd);
    final timeLabel = '${SC.fmtHour(_customStart)} – $endLabel';
    final templates = state.topTemplates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
          child: Row(
            children: [
              Text(
                l10n.mobileBulkStep1Shift,
                style: const TextStyle(fontSize: 12, color: MT.text3, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const Spacer(),
              Text(timeLabel, style: const TextStyle(fontSize: 12, color: MT.text3)),
            ],
          ),
        ),
        // Quick off-type chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.scheduleQuickTypes,
                style: const TextStyle(fontSize: 11, color: MT.text3, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children:
                    [
                      (
                        label: l10n.scheduleOffTypeDayOff,
                        note: ScheduleModel.kNoteOff,
                        color: const Color(0xFF9E9E9E),
                        bg: const Color(0xFFF5F5F5),
                      ),
                      (
                        label: l10n.scheduleOffTypePlannedLeave,
                        note: ScheduleModel.kNotePlannedLeave,
                        color: const Color(0xFFB45309),
                        bg: const Color(0xFFFEF3C7),
                      ),
                      (
                        label: l10n.scheduleOffTypeUnplannedLeave,
                        note: ScheduleModel.kNoteUnplannedLeave,
                        color: const Color(0xFFDC2626),
                        bg: const Color(0xFFFEE2E2),
                      ),
                      (
                        label: l10n.scheduleOffTypeHoliday,
                        note: ScheduleModel.kNoteHoliday,
                        color: const Color(0xFF16A34A),
                        bg: const Color(0xFFDCFCE7),
                      ),
                    ].map((c) {
                      final isSelected = _offTypeNote == c.note;
                      return GestureDetector(
                        onTap:
                            () => setState(() {
                              _offTypeNote = isSelected ? null : c.note;
                              if (_offTypeNote != null) {
                                _selectedTemplate = null;
                                _customStart = 0;
                                _customEnd = 0;
                              }
                            }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? c.color.withValues(alpha: 0.15) : c.bg,
                            border:
                                isSelected
                                    ? Border.all(color: c.color, width: 1.5)
                                    : Border(left: BorderSide(color: c.color, width: 3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                Icon(Icons.check_circle, size: 14, color: c.color),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                c.label,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.color),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
        // Template chips
        if (templates.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: MT.bgCard, borderRadius: MT.br12, border: Border.all(color: MT.hair)),
              child: Text(l10n.scheduleNoTemplatesYet, style: const TextStyle(fontSize: 13, color: MT.text3)),
            ),
          )
        else
          SizedBox(
            height: 72,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final t = templates[i];
                final active = _selectedTemplate?.id == t.id;
                return GestureDetector(
                  onTap:
                      () => setState(() {
                        _selectedTemplate = t;
                        _customStart = t.customStart;
                        _customEnd = t.customEnd;
                        _saveAsTemplate = false;
                        _offTypeNote = null;
                      }),
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: active ? t.lightColor : MT.bgCard,
                      borderRadius: MT.br14,
                      border: Border.all(color: active ? t.color : MT.hair, width: active ? 2 : 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(color: t.color, borderRadius: BorderRadius.circular(2)),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                t.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: active ? t.color : MT.text,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.timeLabel,
                          style: TextStyle(fontSize: 11, color: (active ? t.color : MT.text3).withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        // Custom time pickers
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: _MobileTimeField(
                  label: l10n.scheduleStartTime,
                  value: _customStart,
                  onChanged:
                      (v) => setState(() {
                        _customStart = v;
                        _selectedTemplate = null;
                        _offTypeNote = null;
                      }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MobileTimeField(
                  label: l10n.scheduleEndTime,
                  value: _customEnd,
                  onChanged:
                      (v) => setState(() {
                        _customEnd = v;
                        _selectedTemplate = null;
                        _offTypeNote = null;
                      }),
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('hrs', style: TextStyle(fontSize: 11, color: MT.text3, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: MT.bgCard,
                      borderRadius: MT.br12,
                      border: Border.all(color: MT.hair),
                    ),
                    child: Text(
                      '${_computeHours().toStringAsFixed(1)}h',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: MT.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Save as template — hidden when a template or off-type is already selected
        if (_selectedTemplate == null && _offTypeNote == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l10n.scheduleSaveAsTemplate,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MT.text2),
                    ),
                    const Spacer(),
                    Switch(
                      value: _saveAsTemplate,
                      onChanged:
                          (v) => setState(() {
                            _saveAsTemplate = v;
                            if (!v) _nameError = false;
                          }),
                      activeColor: MT.brand,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
                if (_saveAsTemplate) ...[
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameCtrl,
                    onChanged: (_) {
                      if (_nameError) setState(() => _nameError = false);
                    },
                    decoration: InputDecoration(
                      hintText: l10n.scheduleTemplateNameHint,
                      errorText: _nameError ? l10n.scheduleTemplateNameRequired : null,
                      border: OutlineInputBorder(borderRadius: MT.br12),
                      focusedBorder: OutlineInputBorder(borderRadius: MT.br12, borderSide: BorderSide(color: MT.brand)),
                      errorBorder: OutlineInputBorder(
                        borderRadius: MT.br12,
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  // ── Step 2: Day chips ──────────────────────────────────────────────────────

  Widget _buildStep2(AppLocalizations l10n, ScheduleState state) {
    final weekStart = state.weekStart;
    final days = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final dayNames = SC.localizedDayNames(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
          child: Row(
            children: [
              Text(
                l10n.mobileBulkStep2Days,
                style: const TextStyle(fontSize: 12, color: MT.text3, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const Spacer(),
              _TextAction(
                label: l10n.mobileBulkWholeWeek,
                onTap:
                    () => setState(() {
                      _selectedDays.clear();
                      _selectedDays.addAll(List.generate(7, (i) => i).where((i) => !_isDayLocked(state, i)));
                    }),
              ),
              const SizedBox(width: 10),
              _TextAction(label: l10n.mobileBulkClear, onTap: () => setState(() => _selectedDays.clear())),
            ],
          ),
        ),
        SizedBox(
          height: 62,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            scrollDirection: Axis.horizontal,
            itemCount: 7,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final day = days[i];
              final locked = _isDayLocked(state, i);
              final active = !locked && _selectedDays.contains(i);
              final name = dayNames[day.weekday % 7];
              return GestureDetector(
                onTap: locked ? null : () => setState(() => active ? _selectedDays.remove(i) : _selectedDays.add(i)),
                child: Container(
                  width: 52,
                  decoration: BoxDecoration(
                    color: active ? MT.brand : (locked ? MT.hair2 : MT.bgCard),
                    borderRadius: MT.br12,
                    border: Border.all(color: active ? MT.brand : MT.hair),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: active ? Colors.white.withValues(alpha: 0.8) : MT.text3,
                        ),
                      ),
                      locked
                          ? const Icon(Icons.lock_outline, size: 15, color: MT.text3)
                          : Text(
                            '${day.day}',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: active ? Colors.white : MT.text,
                            ),
                          ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Step 3: Employee picker ────────────────────────────────────────────────

  Widget _buildStep3(AppLocalizations l10n, ScheduleState state) {
    // Self-draft mode: no picker — the sheet is locked to my own row.
    if (state.isSelfOnly) {
      final self = state.selfUser;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: MT.bgCard, borderRadius: MT.br12, border: Border.all(color: MT.hair)),
          child: Row(
            children: [
              if (self != null) MobileAvatar(employee: self, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  self?.getLocalizedName(Localizations.localeOf(context).languageCode) ?? '',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MT.text),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.lock_outline, size: 14, color: MT.text3),
              const SizedBox(width: 4),
              Text(
                l10n.scheduleDraftHint,
                style: const TextStyle(fontSize: 11, color: MT.text3, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    final query = _searchCtrl.text.toLowerCase();
    final locale = Localizations.localeOf(context).languageCode;

    // My own row is intentionally kept out of filteredTeam (team-only KPIs), so
    // surface it as a dedicated "You" row at the top — but only when I actually
    // have a day I'm allowed to draft on.
    final showSelf = _hasEditableSelfDays(state);

    // Group filteredTeam by department
    final grouped = <String, List<UserModel>>{};
    for (final emp in state.filteredTeam) {
      final name = locale == 'ar' ? (emp.getLocalizedName('ar')) : (emp.getLocalizedName('en'));
      final dept =
          (locale == 'ar'
              ? (emp.department ?? emp.englishDepartment ?? '')
              : (emp.englishDepartment ?? emp.department ?? ''));
      if (query.isNotEmpty && !name.toLowerCase().contains(query) && !dept.toLowerCase().contains(query)) {
        continue;
      }
      (grouped[dept] = grouped[dept] ?? []).add(emp);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
          child: Row(
            children: [
              Text(
                '${l10n.mobileBulkStep3Employees} · ${_selectedEmpIds.length} selected',
                style: const TextStyle(fontSize: 12, color: MT.text3, fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
              const Spacer(),
              _TextAction(
                label: l10n.mobileBulkAll,
                onTap:
                    () => setState(() {
                      _selectedEmpIds.clear();
                      if (showSelf) _selectedEmpIds.add(state.managerId!);
                      _selectedEmpIds.addAll(state.filteredTeam.map((e) => e.id!));
                    }),
              ),
              const SizedBox(width: 10),
              _TextAction(label: l10n.mobileBulkClear, onTap: () => setState(() => _selectedEmpIds.clear())),
            ],
          ),
        ),
        // Search box
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Container(
            decoration: BoxDecoration(color: MT.hair2, borderRadius: MT.br12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.search, size: 16, color: MT.text3),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: l10n.mobileBulkSearchHint,
                      hintStyle: const TextStyle(fontSize: 14, color: MT.text3),
                    ),
                    style: const TextStyle(fontSize: 14, color: MT.text),
                  ),
                ),
              ],
            ),
          ),
        ),
        // My own "You" row — kept separate from the dept groups so team counts
        // stay correct, and only shown when I have editable days.
        if (showSelf && state.selfUser != null) _buildSelfPickerRow(l10n, state, locale, query),
        // Dept groups
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children:
                grouped.entries.map((entry) {
                  final dept = entry.key;
                  final emps = entry.value;
                  final deptIds = emps.map((e) => e.id!).toSet();
                  final allOn = deptIds.every(_selectedEmpIds.contains);
                  final isExpanded = _expandedDepts.contains(dept) || query.isNotEmpty;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: MT.bgCard,
                      borderRadius: MT.br14,
                      border: Border.all(color: MT.hair2),
                    ),
                    child: Column(
                      children: [
                        // Dept header row
                        InkWell(
                          borderRadius: MT.br14,
                          onTap:
                              () => setState(() => isExpanded ? _expandedDepts.remove(dept) : _expandedDepts.add(dept)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                _Checkbox(
                                  checked: allOn,
                                  partial: deptIds.any(_selectedEmpIds.contains) && !allOn,
                                  onTap:
                                      () => setState(() {
                                        if (allOn) {
                                          _selectedEmpIds.removeAll(deptIds);
                                        } else {
                                          _selectedEmpIds.addAll(deptIds);
                                        }
                                      }),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Row(
                                    children: [
                                      Text(
                                        dept,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: MT.text,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${deptIds.where(_selectedEmpIds.contains).length}/${emps.length}',
                                        style: const TextStyle(fontSize: 12, color: MT.text3),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                  size: 18,
                                  color: MT.text3,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Employee rows (expanded)
                        if (isExpanded)
                          Column(
                            children:
                                emps.map((emp) {
                                  final on = _selectedEmpIds.contains(emp.id);
                                  final name =
                                      emp.getLocalizedNickname(locale)?.isNotEmpty == true
                                          ? emp.getLocalizedNickname(locale)!
                                          : emp.getLocalizedName(locale);
                                  return InkWell(
                                    onTap:
                                        () => setState(
                                          () => on ? _selectedEmpIds.remove(emp.id) : _selectedEmpIds.add(emp.id!),
                                        ),
                                    child: Padding(
                                      padding: const EdgeInsetsDirectional.fromSTEB(44, 8, 12, 8),
                                      child: Row(
                                        children: [
                                          _Checkbox(
                                            checked: on,
                                            onTap:
                                                () => setState(
                                                  () =>
                                                      on
                                                          ? _selectedEmpIds.remove(emp.id)
                                                          : _selectedEmpIds.add(emp.id!),
                                                ),
                                          ),
                                          const SizedBox(width: 10),
                                          MobileAvatar(employee: emp, size: 28),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: MT.text,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  emp.getLocalizedName(locale == 'ar' ? 'en' : 'ar'),
                                                  style: const TextStyle(fontSize: 11, color: MT.text3),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                          ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  /// The current user's own row in the employee picker, rendered above the
  /// department groups. Backed by [ScheduleState.selfUser] (self is not part of
  /// filteredTeam), it toggles [ScheduleState.managerId] in [_selectedEmpIds].
  Widget _buildSelfPickerRow(AppLocalizations l10n, ScheduleState state, String locale, String query) {
    final self = state.selfUser!;
    final name =
        self.getLocalizedNickname(locale)?.isNotEmpty == true
            ? self.getLocalizedNickname(locale)!
            : self.getLocalizedName(locale);
    // Respect the search box: hide my row when the query clearly targets others.
    if (query.isNotEmpty && !name.toLowerCase().contains(query)) {
      return const SizedBox.shrink();
    }
    final on = _selectedEmpIds.contains(state.managerId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: MT.bgCard,
          borderRadius: MT.br14,
          border: Border.all(color: on ? MT.brand : MT.hair2),
        ),
        child: InkWell(
          borderRadius: MT.br14,
          onTap:
              () =>
                  setState(() => on ? _selectedEmpIds.remove(state.managerId) : _selectedEmpIds.add(state.managerId!)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _Checkbox(
                  checked: on,
                  onTap:
                      () => setState(
                        () => on ? _selectedEmpIds.remove(state.managerId) : _selectedEmpIds.add(state.managerId!),
                      ),
                ),
                const SizedBox(width: 10),
                MobileAvatar(employee: self, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MT.text),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(color: MT.brandBg, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    l10n.schedulePinnedSelfBadge,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: MT.brand),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Live summary card ──────────────────────────────────────────────────────

  Widget _buildSummary(AppLocalizations l10n, ScheduleState state, int total) {
    final conflicts =
        total > 0
            ? _selectedEmpIds
                .where(
                  (id) => _selectedDays.any((d) {
                    final key = '$id-$d';
                    return state.leaveKeys.containsKey(key);
                  }),
                )
                .length
            : 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: total > 0 ? MT.brandBg : MT.hair2,
          borderRadius: MT.br14,
          border: Border.all(color: total > 0 ? MT.brand.withValues(alpha: 0.3) : MT.hair2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month_outlined, size: 16, color: total > 0 ? MT.brand : MT.text3),
                const SizedBox(width: 6),
                Text(
                  total > 0 ? l10n.mobileBulkAssignN(total) : 'Select days and employees',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: total > 0 ? MT.brand : MT.text3),
                ),
              ],
            ),
            if (conflicts > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.warning_amber_outlined, size: 14, color: Color(0xFF9A6A00)),
                  const SizedBox(width: 4),
                  Text(
                    l10n.mobileConflictWarning(conflicts),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9A6A00)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────────────────

  Widget _buildFooter(BuildContext ctx, AppLocalizations l10n, ScheduleState state, int total) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: MT.hair),
                  shape: RoundedRectangleBorder(borderRadius: MT.br12),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.cancel, style: const TextStyle(color: MT.text2, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: total > 0 ? MT.brand : MT.hair,
                  shape: RoundedRectangleBorder(borderRadius: MT.br12),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed:
                    total == 0
                        ? null
                        : () {
                          if (_saveAsTemplate && _nameCtrl.text.trim().isEmpty) {
                            setState(() => _nameError = true);
                            return;
                          }
                          final template =
                              _saveAsTemplate
                                  ? ShiftTemplateModel(
                                    managerId: state.managerId ?? 0,
                                    name: _nameCtrl.text.trim(),
                                    customStart: _customStart,
                                    customEnd: _customEnd,
                                  )
                                  : null;
                          ctx.read<ScheduleBloc>().add(
                            BulkAssignShifts(
                              customStart: _offTypeNote != null ? 0 : _customStart,
                              customEnd: _offTypeNote != null ? 0 : _customEnd,
                              dayIndices: _selectedDays.toList(),
                              employeeIds: _selectedEmpIds.toList(),
                              template: _offTypeNote != null ? null : template,
                              note: _offTypeNote,
                            ),
                          );
                          Navigator.of(ctx).pop();
                        },
                child: Text(
                  l10n.mobileBulkAssignN(total),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small shared widgets ────────────────────────────────────────────────────

class _SheetHeader extends StatelessWidget {
  final String title;
  const _SheetHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(color: MT.hair, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
          child: Row(
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: MT.text)),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(color: MT.hair2, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 16, color: MT.text2),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: MT.hair2),
      ],
    );
  }
}

class _TextAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TextAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: MT.brand)),
  );
}

class _MobileTimeField extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _MobileTimeField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final hh = value.floor();
    final mm = ((value - hh) * 60).round();
    final display = '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
    return InkWell(
      borderRadius: MT.br12,
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hh % 24, minute: mm),
          initialEntryMode: TimePickerEntryMode.input,
        );
        if (picked != null) onChanged(picked.hour + picked.minute / 60.0);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: MT.text3, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(color: MT.bgCard, borderRadius: MT.br12, border: Border.all(color: MT.hair)),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: MT.text3),
                const SizedBox(width: 6),
                Text(display, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: MT.text)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool checked;
  final bool partial;
  final VoidCallback onTap;
  const _Checkbox({required this.checked, this.partial = false, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color:
            checked
                ? MT.brand
                : partial
                ? MT.brandBg
                : MT.bgCard,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: checked || partial ? MT.brand : MT.hair, width: 2),
      ),
      child:
          checked
              ? const Icon(Icons.check, size: 13, color: Colors.white)
              : partial
              ? Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(color: MT.brand, borderRadius: BorderRadius.circular(2)),
              )
              : null,
    ),
  );
}
