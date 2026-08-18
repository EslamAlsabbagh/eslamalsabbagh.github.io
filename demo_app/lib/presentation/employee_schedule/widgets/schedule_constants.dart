import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class SC {
  SC._();

  static const blue = Color(0xFF1E88E5);
  static const blueDark = Color(0xFF1976D2);
  static const blue50 = Color(0xFFE3F2FD);
  static const green = Color(0xFF43A047);
  static const green50 = Color(0xFFE8F5E9);
  static const amber = Color(0xFFF59E0B);
  static const amber50 = Color(0xFFFEF3C7);
  static const rose = Color(0xFFE91E63);
  static const rose50 = Color(0xFFFCE4EC);
  static const teal = Color(0xFF26A69A);
  static const teal50 = Color(0xFFE0F2F1);
  static const purple = Color(0xFF7E57C2);
  static const purple50 = Color(0xFFEDE7F6);
  static const orange = Color(0xFFF57C00);
  static const orange50 = Color(0xFFFFF3E0);

  /// Off types (day off / holiday) — mirrors MT.offStripe on mobile.
  static const slate = Color(0xFF64748B);
  static const bgPage = Color(0xFFF7F9FC);
  static const lineColor = Color(0xFFE4E9F0);
  static const lineColor2 = Color(0xFFEEF1F6);
  static const ink = Color(0xFF1F2937);
  static const ink2 = Color(0xFF374151);
  static const muted = Color(0xFF6B7280);
  static const muted2 = Color(0xFF9CA3AF);

  static Color shiftColor(double h) {
    if (h < 6) return orange;
    if (h < 12) return blue;
    if (h < 18) return teal;
    return purple;
  }

  static Color shiftLightColor(double h) {
    if (h < 6) return orange50;
    if (h < 12) return blue50;
    if (h < 18) return teal50;
    return purple50;
  }

  static String fmtHour(double h) {
    final hh = h.floor() % 24;
    final mm = ((h - h.floor()) * 60).round();
    return '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
  }

  static String weekLabel(DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[weekStart.month]} ${weekStart.day} – '
        '${months[end.month]} ${end.day}, ${end.year}';
  }

  static int weekNumber(DateTime date) {
    final firstJan = DateTime(date.year, 1, 1);
    return ((date.difference(firstJan).inDays + firstJan.weekday) / 7).ceil();
  }

  static DateTime mondayOf(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday - 1));
  }

  static DateTime weekStartOf(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday % 7));
  }

  static const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  static const _months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  static List<String> localizedDayNames(AppLocalizations l10n) => [
    l10n.daySun,
    l10n.dayMon,
    l10n.dayTue,
    l10n.dayWed,
    l10n.dayThu,
    l10n.dayFri,
    l10n.daySat,
  ];

  /// Maps Dart's ISO weekday (1=Mon … 7=Sun) to a localized abbreviation.
  static String localizedDayFromWeekday(AppLocalizations l10n, int weekday) {
    switch (weekday) {
      case 1:
        return l10n.dayMon;
      case 2:
        return l10n.dayTue;
      case 3:
        return l10n.dayWed;
      case 4:
        return l10n.dayThu;
      case 5:
        return l10n.dayFri;
      case 6:
        return l10n.daySat;
      case 7:
        return l10n.daySun;
      default:
        return '';
    }
  }

  static List<String> localizedMonthNames(AppLocalizations l10n) => [
    '',
    l10n.monthJan,
    l10n.monthFeb,
    l10n.monthMar,
    l10n.monthApr,
    l10n.monthMay,
    l10n.monthJun,
    l10n.monthJul,
    l10n.monthAug,
    l10n.monthSep,
    l10n.monthOct,
    l10n.monthNov,
    l10n.monthDec,
  ];

  /// Returns a compact date label, e.g. "Sat 10 May".
  static String fmtShiftDate(DateTime date) {
    final dayName = dayNames[(date.weekday % 7)];
    return '$dayName ${date.day} ${_months[date.month]}';
  }

  static String localizedFmtShiftDate(AppLocalizations l10n, DateTime date) {
    final dayName = localizedDayNames(l10n)[date.weekday % 7];
    return '$dayName ${date.day} ${localizedMonthNames(l10n)[date.month]}';
  }

  static String localizedWeekLabel(AppLocalizations l10n, DateTime weekStart) {
    final end = weekStart.add(const Duration(days: 6));
    final months = localizedMonthNames(l10n);
    return '${months[weekStart.month]} ${weekStart.day} – '
        '${months[end.month]} ${end.day}, ${end.year}';
  }

  static String localizedLeaveType(AppLocalizations l10n, String? raw) {
    if (raw == null) return l10n.scheduleLegendLeave;
    final lower = raw.toLowerCase();
    if (lower.contains('annual')) return l10n.leaveTypeAnnual;
    if (lower.contains('sick')) return l10n.leaveTypeSick;
    if (lower.contains('emergency')) return l10n.leaveTypeEmergency;
    if (lower.contains('compensation')) return l10n.leaveTypeCompensation;
    if (lower.contains('unpaid')) return l10n.leaveTypeUnpaid;
    return raw;
  }

  static String localizedShiftLabel(AppLocalizations l10n, ScheduleModel shift) {
    if (shift.isLeave) return localizedLeaveType(l10n, shift.leaveType);
    if (shift.note == ScheduleModel.kNoteOff) return l10n.scheduleOffTypeDayOff;
    if (shift.note == ScheduleModel.kNotePlannedLeave) return l10n.scheduleOffTypePlannedLeave;
    if (shift.note == ScheduleModel.kNoteUnplannedLeave) return l10n.scheduleOffTypeUnplannedLeave;
    if (shift.note == ScheduleModel.kNoteHoliday) return l10n.scheduleOffTypeHoliday;
    if (shift.customStart < 6) return l10n.shiftOvernight;
    if (shift.customStart < 12) return l10n.shiftMorning;
    if (shift.customStart < 18) return l10n.shiftAfternoon;
    return l10n.shiftNight;
  }

  static String localizedTimeLabel(AppLocalizations l10n, ScheduleModel shift) {
    if (shift.isLeave) return l10n.shiftFullDay;
    if (shift.isOffType) return '';
    return '${fmtHour(shift.customStart)} – ${fmtHour(shift.customEnd)}';
  }

  static String avatarInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  static Color avatarColor(int index) {
    const colors = [
      Color(0xFF1E88E5),
      Color(0xFF26A69A),
      Color(0xFF7E57C2),
      Color(0xFF43A047),
      Color(0xFFF59E0B),
      Color(0xFFE91E63),
      Color(0xFF5C6BC0),
      Color(0xFF00897B),
      Color(0xFF8E24AA),
    ];
    return colors[index % colors.length];
  }
}
