import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/data/models/shift_template_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_event.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows the shift assignment dialog. Pass [keys] as schedule map keys
/// ("empId-dayIndex"). Pass [existing] to pre-populate for editing.
Future<void> showShiftModal(
  BuildContext context, {
  required List<String> keys,
  ScheduleModel? existing,
  UserModel? employee,
}) {
  return showDialog(
    context: context,
    barrierColor: Colors.black38,
    builder:
        (_) => BlocProvider.value(
          value: context.read<ScheduleBloc>(),
          child: ShiftModal(keys: keys, existing: existing, employee: employee),
        ),
  );
}

/// Mobile variant — opens the shift form as a bottom sheet instead of a dialog.
Future<void> showShiftBottomSheet(
  BuildContext context, {
  required List<String> keys,
  ScheduleModel? existing,
  UserModel? employee,
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
          child: ShiftModal(keys: keys, existing: existing, employee: employee, bottomSheet: true),
        ),
  );
}

DateTime _shiftDateTime(DateTime weekDay, double hour, {bool nextDay = false}) {
  final h = hour.floor();
  final m = ((hour - h) * 60).round();
  final base = DateTime(weekDay.year, weekDay.month, weekDay.day, h, m);
  return nextDay ? base.add(const Duration(days: 1)) : base;
}

class ShiftModal extends StatefulWidget {
  final List<String> keys;
  final ScheduleModel? existing;
  final UserModel? employee;
  final bool bottomSheet;

  const ShiftModal({super.key, required this.keys, this.existing, this.employee, this.bottomSheet = false});

  @override
  State<ShiftModal> createState() => _ShiftModalState();
}

class _ShiftModalState extends State<ShiftModal> {
  ShiftTemplateModel? _selectedTemplate;
  String? _selectedOffTypeNote;
  double _start = 8.0;
  double _end = 16.0;
  final _noteCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _saveAsTemplate = false;
  bool _nameError = false;

  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _start = widget.existing!.customStart;
      _end = widget.existing!.customEnd;
      if (widget.existing!.isOffType) {
        _selectedOffTypeNote = widget.existing!.note;
        _noteCtrl.text = '';
      } else {
        _noteCtrl.text = widget.existing!.note ?? '';
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final templates = context.read<ScheduleBloc>().state.topTemplates;
    if (widget.existing != null) {
      // editing — find matching template by times
      _selectedTemplate =
          templates
              .where((t) => t.customStart == widget.existing!.customStart && t.customEnd == widget.existing!.customEnd)
              .firstOrNull;
    } else if (templates.isNotEmpty) {
      // new shift — pre-select and apply the most-used template
      _selectedTemplate = templates.first;
      _start = templates.first.customStart;
      _end = templates.first.customEnd;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  bool get _isBulk => widget.keys.length > 1;
  bool get _isEdit => widget.existing != null;

  String _title(AppLocalizations l10n) {
    if (_isBulk) return l10n.scheduleShiftAssignCells(widget.keys.length);
    if (_isEdit) return l10n.scheduleShiftEditShift;
    return l10n.scheduleShiftNewShift;
  }

  String _subtitle(AppLocalizations l10n, String locale) {
    if (_isBulk) return l10n.scheduleShiftBulkAssign;
    if (widget.employee != null) {
      final name = widget.employee!.getLocalizedName(locale);
      if (widget.keys.isNotEmpty) {
        final parts = widget.keys.first.split('-');
        final dayIdx = int.parse(parts[1]);
        return '$name · ${SC.localizedDayNames(l10n)[dayIdx]}';
      }
      return name;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        final conflicts = _selectedOffTypeNote != null ? <ShiftConflictType>[] : _detectLocalConflicts(state);

        final sharedContent = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (conflicts.isNotEmpty) _buildConflictBanner(conflicts, state),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickTypes(),
                    _buildTemplatePicker(state),
                    const SizedBox(height: 16),
                    _buildTimeRow(),
                    const SizedBox(height: 14),
                    if (_selectedOffTypeNote == null &&
                        (_saveAsTemplate || _selectedTemplate == null) &&
                        !state.topTemplates.any((t) => t.customStart == _start && t.customEnd == _end))
                      _buildNameField(),
                    if (_selectedOffTypeNote == null) _buildNoteField(),
                  ],
                ),
              ),
            ),
            _buildFooter(state),
          ],
        );

        if (widget.bottomSheet) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: sharedContent,
          );
        }

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: sharedContent),
        );
      },
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final title = _title(l10n);
    final subtitle = _subtitle(l10n, locale);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: SC.lineColor))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: SC.ink)),
                if (subtitle.isNotEmpty) Text(subtitle, style: const TextStyle(fontSize: 12, color: SC.muted)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => Navigator.pop(context),
            color: SC.muted,
            splashRadius: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildConflictBanner(List<ShiftConflictType> conflicts, ScheduleState state) {
    final l10n = AppLocalizations.of(context)!;
    String conflictLabel(ShiftConflictType t) => switch (t) {
      ShiftConflictType.approvedLeave => () {
        final key = widget.keys.firstOrNull ?? '';
        final typeLabel = SC.localizedLeaveType(l10n, state.leaveKeys[key]);
        return '${l10n.scheduleConflictApprovedLeave} · $typeLabel';
      }(),
      ShiftConflictType.exceedsMaxHours => l10n.scheduleConflictExceedsMaxHours,
      ShiftConflictType.insufficientRestAfter => l10n.scheduleConflictInsufficientRestAfter,
      ShiftConflictType.insufficientRestBefore => l10n.scheduleConflictInsufficientRestBefore,
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SC.amber50,
        border: Border.all(color: SC.amber.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 14, color: SC.amber),
              const SizedBox(width: 5),
              Text(
                l10n.scheduleConflictDetected,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: SC.amber),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...() {
            final counts = <ShiftConflictType, int>{};
            for (final c in conflicts) {
              counts[c] = (counts[c] ?? 0) + 1;
            }
            return counts.entries.map(
              (e) => Text(
                e.value > 1 ? '• ${conflictLabel(e.key)}  × ${e.value}' : '• ${conflictLabel(e.key)}',
                style: const TextStyle(fontSize: 11.5, color: SC.ink2),
              ),
            );
          }(),
        ],
      ),
    );
  }

  void _saveOffType(BuildContext ctx, ScheduleState state, String noteValue) {
    if (widget.keys.isEmpty) return;
    final firstParts = widget.keys.first.split('-');
    final payload = ScheduleModel(
      employeeId: int.parse(firstParts[0]),
      managerId: state.managerId ?? 0,
      weekStart: state.weekStart,
      dayIndex: int.parse(firstParts[1]),
      customStart: 0,
      customEnd: 0,
      hours: 0,
      note: noteValue,
      isPublished: false,
    );
    ctx.read<ScheduleBloc>().add(SaveShift(keys: widget.keys, payload: payload));
    Navigator.pop(ctx);
  }

  Widget _buildQuickTypes() {
    final l10n = AppLocalizations.of(context)!;
    final chips = [
      (
        note: ScheduleModel.kNoteOff,
        label: l10n.scheduleOffTypeDayOff,
        color: const Color(0xFF9E9E9E),
        bg: const Color(0xFFF5F5F5),
      ),
      (
        note: ScheduleModel.kNotePlannedLeave,
        label: l10n.scheduleOffTypePlannedLeave,
        color: const Color(0xFFB45309),
        bg: const Color(0xFFFEF3C7),
      ),
      (
        note: ScheduleModel.kNoteUnplannedLeave,
        label: l10n.scheduleOffTypeUnplannedLeave,
        color: const Color(0xFFDC2626),
        bg: const Color(0xFFFEE2E2),
      ),
      (
        note: ScheduleModel.kNoteHoliday,
        label: l10n.scheduleOffTypeHoliday,
        color: const Color(0xFF16A34A),
        bg: const Color(0xFFDCFCE7),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.scheduleQuickTypes,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SC.muted),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              chips.map((c) {
                final isSelected = _selectedOffTypeNote == c.note;
                return BlocBuilder<ScheduleBloc, ScheduleState>(
                  builder:
                      (ctx, state) => MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _saveOffType(ctx, state, c.note),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? c.color.withValues(alpha: 0.15) : c.bg,
                              border:
                                  isSelected
                                      ? Border.all(color: c.color, width: 1.5)
                                      : Border(left: BorderSide(color: c.color, width: 3)),
                              borderRadius: BorderRadius.circular(6),
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
                        ),
                      ),
                );
              }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTemplatePicker(ScheduleState state) {
    final templates = state.topTemplates;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.scheduleQuickTemplates,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: SC.muted),
        ),
        const SizedBox(height: 8),
        templates.isEmpty
            ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: SC.lineColor),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                AppLocalizations.of(context)!.scheduleNoTemplatesYet,
                style: const TextStyle(fontSize: 12, color: SC.muted2),
              ),
            )
            : Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  templates
                      .map(
                        (t) => _TemplateChip(
                          template: t,
                          isSelected: _selectedTemplate?.id == t.id,
                          onTap: () {
                            setState(() {
                              _selectedTemplate = t;
                              _start = t.customStart;
                              _end = t.customEnd;
                              _saveAsTemplate = false;
                              _selectedOffTypeNote = null;
                            });
                          },
                          onDelete: () {
                            if (t.id != null) {
                              context.read<ScheduleBloc>().add(DeleteTemplate(t.id!));
                              if (_selectedTemplate?.id == t.id) {
                                setState(() => _selectedTemplate = null);
                              }
                            }
                          },
                        ),
                      )
                      .toList(),
            ),
      ],
    );
  }

  Widget _buildTimeRow() {
    return Row(
      children: [
        Expanded(
          child: _TimeField(
            label: AppLocalizations.of(context)!.scheduleStartTime,
            value: _start,
            onChanged:
                (v) => setState(() {
                  _start = v;
                  _selectedTemplate = null;
                  _selectedOffTypeNote = null;
                }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TimeField(
            label: AppLocalizations.of(context)!.scheduleEndTime,
            value: _end,
            onChanged:
                (v) => setState(() {
                  _end = v;
                  _selectedTemplate = null;
                  _selectedOffTypeNote = null;
                }),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.scheduleHours, style: const TextStyle(fontSize: 11.5, color: SC.muted)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: SC.lineColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_computeHours().toStringAsFixed(1)}h',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: SC.ink),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                AppLocalizations.of(context)!.scheduleSaveAsTemplate,
                style: const TextStyle(fontSize: 11.5, color: SC.muted),
              ),
              const Spacer(),
              Switch(
                value: _saveAsTemplate,
                onChanged: (v) => setState(() => _saveAsTemplate = v),
                activeColor: SC.blue,
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
                labelText: AppLocalizations.of(context)!.scheduleTemplateName,
                hintText: AppLocalizations.of(context)!.scheduleTemplateNameHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: SC.rose),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: SC.rose, width: 1.5),
                ),
                errorText: _nameError ? AppLocalizations.of(context)!.scheduleTemplateNameRequired : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteField() {
    return TextField(
      controller: _noteCtrl,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.scheduleNoteOptional,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
      style: const TextStyle(fontSize: 13),
      maxLines: 2,
    );
  }

  Widget _buildFooter(ScheduleState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: SC.lineColor))),
      child: Row(
        children: [
          if (_isEdit)
            _FooterBtn(
              label: AppLocalizations.of(context)!.scheduleRemoveShift,
              color: SC.rose,
              outlined: true,
              onTap: () {
                context.read<ScheduleBloc>().add(DeleteShift(widget.keys));
                Navigator.pop(context);
              },
            ),
          const Spacer(),
          _FooterBtn(
            label: AppLocalizations.of(context)!.cancel,
            color: SC.muted,
            outlined: true,
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          _FooterBtn(
            label: AppLocalizations.of(context)!.scheduleSaveAsDraft,
            color: SC.blue,
            onTap: () => _save(context, state),
          ),
        ],
      ),
    );
  }

  void _save(BuildContext context, ScheduleState state) {
    if (widget.keys.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.scheduleTapCellFirst)));
      return;
    }

    if (_saveAsTemplate && _nameCtrl.text.trim().isEmpty) {
      setState(() => _nameError = true);
      return;
    }

    final isOffType = _selectedOffTypeNote != null;
    final hours = isOffType ? 0.0 : _computeHours();
    final saveStart = isOffType ? 0.0 : _start;
    final saveEnd = isOffType ? 0.0 : _end;
    final note = _selectedOffTypeNote ?? (_noteCtrl.text.isEmpty ? null : _noteCtrl.text);
    final managerId = state.managerId ?? 0;
    final weekStart = state.weekStart;

    final firstParts = widget.keys.first.split('-');
    final empId = int.parse(firstParts[0]);
    final dayIdx = int.parse(firstParts[1]);

    final payload = ScheduleModel(
      employeeId: empId,
      managerId: managerId,
      weekStart: weekStart,
      dayIndex: dayIdx,
      customStart: saveStart,
      customEnd: saveEnd,
      hours: hours,
      note: note,
      isPublished: false,
    );

    ShiftTemplateModel? templateToSave;
    if (_saveAsTemplate && _nameCtrl.text.isNotEmpty) {
      // Prevent duplicate by times — reuse existing template if same start/end
      final existing = state.topTemplates.where((t) => t.customStart == _start && t.customEnd == _end).firstOrNull;
      templateToSave =
          existing != null
              ? existing.copyWith(useCount: existing.useCount + 1)
              : ShiftTemplateModel(
                managerId: managerId,
                name: _nameCtrl.text.trim(),
                customStart: _start,
                customEnd: _end,
                useCount: 1,
              );
    } else if (_selectedTemplate != null) {
      templateToSave = _selectedTemplate!.copyWith(useCount: _selectedTemplate!.useCount + 1);
    }

    context.read<ScheduleBloc>().add(SaveShift(keys: widget.keys, payload: payload, template: templateToSave));
    Navigator.pop(context);
  }

  double _computeHours() {
    if (_end > _start) return _end - _start;
    return (_end + 24) - _start;
  }

  List<ShiftConflictType> _detectLocalConflicts(ScheduleState state) {
    final conflicts = <ShiftConflictType>[];
    for (final key in widget.keys) {
      final parts = key.split('-');
      final empId = parts[0];
      final dayIdx = int.parse(parts[1]);

      if (state.schedule[key]?.isLeave == true || state.leaveKeys.containsKey(key)) {
        conflicts.add(ShiftConflictType.approvedLeave);
        continue;
      }

      // Max shift duration (16 hours)
      final hours = _end > _start ? _end - _start : (_end + 24) - _start;
      if (hours > 16) {
        conflicts.add(ShiftConflictType.exceedsMaxHours);
        continue;
      }

      // < 8h rest from previous week's last day (boundary: dayIdx == 0 only)
      if (dayIdx == 0) {
        final empIdInt = int.tryParse(empId);
        final prev = empIdInt != null ? state.prevWeekLastDay[empIdInt] : null;
        if (prev != null && !prev.isLeave && !prev.isOffType) {
          final prevDay = state.weekStart.subtract(const Duration(days: 1));
          final curDay = state.weekStart;
          final prevEnd = _shiftDateTime(prevDay, prev.customEnd, nextDay: prev.customEnd < prev.customStart);
          final curStart = _shiftDateTime(curDay, _start);
          if (curStart.difference(prevEnd).inMinutes < 8 * 60) {
            conflicts.add(ShiftConflictType.insufficientRestAfter);
          }
        }
      }

      // < 8h rest from previous day
      if (dayIdx > 0) {
        final prev = state.schedule['$empId-${dayIdx - 1}'];
        if (prev != null && !prev.isLeave && !prev.isOffType) {
          final prevDay = state.weekStart.add(Duration(days: dayIdx - 1));
          final curDay = state.weekStart.add(Duration(days: dayIdx));
          final prevEnd = _shiftDateTime(prevDay, prev.customEnd, nextDay: prev.customEnd < prev.customStart);
          final curStart = _shiftDateTime(curDay, _start);
          if (curStart.difference(prevEnd).inMinutes < 8 * 60) {
            conflicts.add(ShiftConflictType.insufficientRestAfter);
          }
        }
      }

      // < 8h rest before next day
      if (dayIdx < 6) {
        final next = state.schedule['$empId-${dayIdx + 1}'];
        if (next != null && !next.isLeave && !next.isOffType) {
          final curDay = state.weekStart.add(Duration(days: dayIdx));
          final nextDay = state.weekStart.add(Duration(days: dayIdx + 1));
          final curEnd = _shiftDateTime(curDay, _end, nextDay: _end < _start);
          final nextStart = _shiftDateTime(nextDay, next.customStart);
          if (nextStart.difference(curEnd).inMinutes < 8 * 60) {
            conflicts.add(ShiftConflictType.insufficientRestBefore);
          }
        }
      }

      // < 8h rest before next week's first day (boundary: dayIdx == 6 only)
      if (dayIdx == 6) {
        final empIdInt = int.tryParse(empId);
        final next = empIdInt != null ? state.nextWeekFirstDay[empIdInt] : null;
        if (next != null && !next.isLeave && !next.isOffType) {
          final curDay = state.weekStart.add(const Duration(days: 6));
          final nextDay = state.weekStart.add(const Duration(days: 7));
          final curEnd = _shiftDateTime(curDay, _end, nextDay: _end < _start);
          final nextStart = _shiftDateTime(nextDay, next.customStart);
          if (nextStart.difference(curEnd).inMinutes < 8 * 60) {
            conflicts.add(ShiftConflictType.insufficientRestBefore);
          }
        }
      }
    }
    return conflicts;
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _TemplateChip extends StatelessWidget {
  final ShiftTemplateModel template;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TemplateChip({required this.template, required this.isSelected, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Chip content shifted down+left by 6px to make room for the delete circle
    // at the top-right corner — circle stays fully within the Stack's bounds
    // so hit-testing covers it completely.
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: 6),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected ? SC.blue50 : Colors.white,
                  border: Border.all(color: isSelected ? SC.blue : SC.lineColor, width: isSelected ? 1.5 : 1),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 4,
                      decoration: BoxDecoration(color: template.color, borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(width: 7),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? SC.blue : SC.ink,
                          ),
                        ),
                        Text(
                          template.timeLabel,
                          style: TextStyle(fontSize: 10.5, color: isSelected ? SC.blue : SC.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(color: SC.muted2, shape: BoxShape.circle),
                child: const Icon(Icons.remove, size: 10, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _TimeField({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final hh = value.floor();
    final mm = ((value - hh) * 60).round();
    final display = '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: TimeOfDay(hour: hh, minute: mm),
            initialEntryMode: TimePickerEntryMode.input,
          );
          if (picked != null) {
            onChanged(picked.hour + picked.minute / 60.0);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11.5, color: SC.muted)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                border: Border.all(color: SC.lineColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: SC.muted),
                  const SizedBox(width: 6),
                  Text(display, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: SC.ink)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _FooterBtn({required this.label, required this.color, this.outlined = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: outlined ? Colors.white : color,
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: outlined ? color : Colors.white),
          ),
        ),
      ),
    );
  }
}
