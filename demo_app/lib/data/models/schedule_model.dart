import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:flutter/material.dart';

class ScheduleModel {
  final int? id;
  final int employeeId;
  final int managerId;
  final DateTime weekStart;
  final int dayIndex;
  final int? shiftTemplateId;
  final double customStart;
  final double customEnd;
  final String? note;
  final bool isPublished;
  final double hours;
  final bool removed;
  // Last writer of the row (user Code). Falls back to managerId for legacy
  // rows written before the column existed.
  final int? createdBy;
  // Set in-memory when leave is detected from leave_requests overlay
  final bool isLeave;
  final String? leaveType;
  // Set in-memory after client-side conflict detection
  final ShiftConflictType? conflict;

  const ScheduleModel({
    this.id,
    required this.employeeId,
    required this.managerId,
    required this.weekStart,
    required this.dayIndex,
    this.shiftTemplateId,
    required this.customStart,
    required this.customEnd,
    this.note,
    this.isPublished = false,
    required this.hours,
    this.removed = false,
    this.createdBy,
    this.isLeave = false,
    this.leaveType,
    this.conflict,
  });

  // ── Off-type sentinel values stored in the `note` field ───────────────────
  static const String kNoteOff             = 'day_off';
  static const String kNotePlannedLeave    = 'planned_leave';
  static const String kNoteUnplannedLeave  = 'unplanned_leave';
  static const String kNoteHoliday         = 'holiday';

  /// True when this cell is a manager-assigned off type
  /// (day off / planned leave / unplanned leave / holiday).
  bool get isOffType =>
      note == kNoteOff ||
      note == kNotePlannedLeave ||
      note == kNoteUnplannedLeave ||
      note == kNoteHoliday;

  /// True when this cell is a leave type that blocks shift swapping.
  bool get isLeaveType =>
      note == kNotePlannedLeave ||
      note == kNoteUnplannedLeave ||
      isLeave ||
      conflict == ShiftConflictType.approvedLeave;

  /// Map key used throughout the BLoC state
  String get key => '$employeeId-$dayIndex';

  /// Effective owner of the row: last writer, legacy rows fall back to manager.
  int get owner => createdBy ?? managerId;

  /// True when this is a draft the employee proposed for themselves —
  /// rendered with the "Proposed" treatment in the manager's team view.
  bool get isEmployeeProposed => !isPublished && owner == employeeId;

  /// Color derived from start hour: 0–5:59 orange, 6–11:59 blue, 12–17:59 teal, 18–23:59 purple
  Color get shiftColor {
    if (isLeave) return const Color(0xFFE91E63);
    if (note == kNoteOff)             return const Color(0xFF9E9E9E);
    if (note == kNotePlannedLeave)    return const Color(0xFFB45309);
    if (note == kNoteUnplannedLeave)  return const Color(0xFFDC2626);
    if (note == kNoteHoliday)         return const Color(0xFF16A34A);
    if (customStart < 6)  return const Color(0xFFF57C00);
    if (customStart < 12) return const Color(0xFF1E88E5);
    if (customStart < 18) return const Color(0xFF26A69A);
    return const Color(0xFF7E57C2);
  }

  Color get shiftLightColor {
    if (isLeave) return const Color(0xFFFCE4EC);
    if (note == kNoteOff)             return const Color(0xFFF5F5F5);
    if (note == kNotePlannedLeave)    return const Color(0xFFFEF3C7);
    if (note == kNoteUnplannedLeave)  return const Color(0xFFFEE2E2);
    if (note == kNoteHoliday)         return const Color(0xFFDCFCE7);
    if (customStart < 6)  return const Color(0xFFFFF3E0);
    if (customStart < 12) return const Color(0xFFE3F2FD);
    if (customStart < 18) return const Color(0xFFE0F2F1);
    return const Color(0xFFEDE7F6);
  }

  String get timeLabel {
    if (isLeave) return 'Full day';
    if (isOffType) return '—';
    return '${_fmtHour(customStart)} – ${_fmtHour(customEnd)}';
  }

  String get shiftLabel {
    if (isLeave) return leaveType ?? 'Leave';
    if (note == kNoteOff)             return 'Day Off';
    if (note == kNotePlannedLeave)    return 'Planned Leave';
    if (note == kNoteUnplannedLeave)  return 'Unplanned Leave';
    if (note == kNoteHoliday)         return 'Holiday';
    if (customStart < 6)  return 'Overnight';
    if (customStart < 12) return 'Morning';
    if (customStart < 18) return 'Afternoon';
    return 'Night';
  }

  /// Bucket key used by the summary counters (monthly grids, legends).
  ///
  /// Off-type cells are stored with `customStart == 0`, so they must be
  /// classified *before* falling through to the start-hour buckets — otherwise
  /// they land in `overnight` (`customStart < 6`).
  ///
  /// Deliberately does not use [isLeaveType]: that getter also matches a real
  /// working shift flagged with [ShiftConflictType.approvedLeave], which is a
  /// warning on a shift, not a leave cell.
  String get summaryKind {
    if (isLeave) return 'leave';
    if (note == kNotePlannedLeave || note == kNoteUnplannedLeave) return 'leave';
    if (note == kNoteOff || note == kNoteHoliday) return 'off';
    if (customStart < 6)  return 'overnight';
    if (customStart < 12) return 'morning';
    if (customStart < 18) return 'afternoon';
    return 'night';
  }

  static String _fmtHour(double h) {
    final hh = h.floor() % 24;
    final mm = ((h - h.floor()) * 60).round();
    return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
  }

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] as int?,
      employeeId: json['employee_id'] as int,
      managerId: json['manager_id'] as int,
      weekStart: DateTime.parse(json['week_start'] as String),
      dayIndex: json['day_index'] as int,
      shiftTemplateId: json['shift_template_id'] as int?,
      customStart: (json['custom_start'] as num).toDouble(),
      customEnd: (json['custom_end'] as num).toDouble(),
      note: json['note'] as String?,
      isPublished: (json['is_published'] as bool?) ?? false,
      hours: (json['hours'] as num).toDouble(),
      removed: (json['removed'] as bool?) ?? false,
      createdBy: json['created_by'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'employee_id': employeeId,
        'manager_id': managerId,
        'week_start': weekStart.toIso8601String().split('T').first,
        'day_index': dayIndex,
        if (shiftTemplateId != null) 'shift_template_id': shiftTemplateId,
        'custom_start': customStart,
        'custom_end': customEnd,
        'note': note,
        'is_published': isPublished,
        'hours': hours,
        'removed': removed,
        'created_by': owner,
      };

  ScheduleModel copyWith({
    int? id,
    int? employeeId,
    int? managerId,
    DateTime? weekStart,
    int? dayIndex,
    int? shiftTemplateId,
    double? customStart,
    double? customEnd,
    String? note,
    bool? isPublished,
    double? hours,
    bool? removed,
    int? createdBy,
    bool? isLeave,
    String? leaveType,
    ShiftConflictType? conflict,
    bool clearConflict = false,
    bool clearLeave = false,
  }) {
    return ScheduleModel(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      managerId: managerId ?? this.managerId,
      weekStart: weekStart ?? this.weekStart,
      dayIndex: dayIndex ?? this.dayIndex,
      shiftTemplateId: shiftTemplateId ?? this.shiftTemplateId,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      note: note ?? this.note,
      isPublished: isPublished ?? this.isPublished,
      hours: hours ?? this.hours,
      removed: removed ?? this.removed,
      createdBy: createdBy ?? this.createdBy,
      isLeave: clearLeave ? false : (isLeave ?? this.isLeave),
      leaveType: clearLeave ? null : (leaveType ?? this.leaveType),
      conflict: clearConflict ? null : (conflict ?? this.conflict),
    );
  }

  /// Factory for creating a leave placeholder (not stored in DB)
  factory ScheduleModel.leave({
    required int employeeId,
    required int managerId,
    required DateTime weekStart,
    required int dayIndex,
    String leaveType = 'Annual Leave',
  }) {
    return ScheduleModel(
      employeeId: employeeId,
      managerId: managerId,
      weekStart: weekStart,
      dayIndex: dayIndex,
      customStart: 0,
      customEnd: 0,
      hours: 0,
      isPublished: true,
      createdBy: managerId,
      isLeave: true,
      leaveType: leaveType,
    );
  }
}
