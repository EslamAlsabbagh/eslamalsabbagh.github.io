import 'package:timezone/timezone.dart' as tz;

class ShiftSwapRequestModel {
  final int? id;
  final int requesterId;
  final int? targetEmployeeId;
  final int? scheduleId;
  final String? reason;
  final String status;
  final DateTime? createdAt;
  // Enriched in-memory
  final String? requesterEnglishName;
  final String? requesterArabicName;
  final String? requesterEnglishNickname;
  final String? requesterArabicNickname;
  final String? targetEnglishName;
  final String? targetArabicName;
  final String? targetEnglishNickname;
  final String? targetArabicNickname;
  // Enriched from joined schedule (requester's shift)
  final int? scheduleEmployeeId;
  final DateTime? scheduleWeekStart;
  final int? scheduleDayIndex;
  final double? scheduleStart;
  final double? scheduleEnd;
  // Target's shift — persisted as target_schedule_id, times enriched in-memory
  final int? targetScheduleId;
  final double? targetScheduleStart;
  final double? targetScheduleEnd;
  final int? targetScheduleDayIndex;
  final double? targetScheduleHours;
  final int? targetScheduleTemplateId;

  const ShiftSwapRequestModel({
    this.id,
    required this.requesterId,
    this.targetEmployeeId,
    this.scheduleId,
    this.reason,
    this.status = 'pending',
    this.createdAt,
    this.requesterEnglishName,
    this.requesterArabicName,
    this.requesterEnglishNickname,
    this.requesterArabicNickname,
    this.targetEnglishName,
    this.targetArabicName,
    this.targetEnglishNickname,
    this.targetArabicNickname,
    this.scheduleEmployeeId,
    this.scheduleWeekStart,
    this.scheduleDayIndex,
    this.scheduleStart,
    this.scheduleEnd,
    this.targetScheduleId,
    this.targetScheduleStart,
    this.targetScheduleEnd,
    this.targetScheduleDayIndex,
    this.targetScheduleHours,
    this.targetScheduleTemplateId,
  });

  factory ShiftSwapRequestModel.fromJson(Map<String, dynamic> json) {
    return ShiftSwapRequestModel(
      id: json['id'] as int?,
      requesterId: json['requester_id'] as int,
      targetEmployeeId: json['target_employee_id'] as int?,
      scheduleId: json['schedule_id'] as int?,
      reason: json['reason'] as String?,
      status: (json['status'] as String?) ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      requesterEnglishName: json['requester_english_name'] as String?,
      requesterArabicName: json['requester_arabic_name'] as String?,
      requesterEnglishNickname: json['requester_english_nickname'] as String?,
      requesterArabicNickname: json['requester_arabic_nickname'] as String?,
      targetEnglishName: json['target_english_name'] as String?,
      targetArabicName: json['target_arabic_name'] as String?,
      targetEnglishNickname: json['target_english_nickname'] as String?,
      targetArabicNickname: json['target_arabic_nickname'] as String?,
      scheduleEmployeeId: json['schedule_employee_id'] as int?,
      scheduleWeekStart: json['schedule_week_start'] != null
          ? DateTime.tryParse(json['schedule_week_start'] as String)
          : null,
      scheduleDayIndex: json['schedule_day_index'] as int?,
      scheduleStart: json['schedule_start'] != null
          ? (json['schedule_start'] as num).toDouble()
          : null,
      scheduleEnd: json['schedule_end'] != null
          ? (json['schedule_end'] as num).toDouble()
          : null,
      targetScheduleId: json['target_schedule_id'] as int?,
      targetScheduleStart: json['target_schedule_start'] != null
          ? (json['target_schedule_start'] as num).toDouble()
          : null,
      targetScheduleEnd: json['target_schedule_end'] != null
          ? (json['target_schedule_end'] as num).toDouble()
          : null,
      targetScheduleDayIndex: json['target_schedule_day_index'] as int?,
      targetScheduleHours: json['target_schedule_hours'] != null
          ? (json['target_schedule_hours'] as num).toDouble()
          : null,
      targetScheduleTemplateId: json['target_schedule_template_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'requester_id': requesterId,
        if (targetEmployeeId != null) 'target_employee_id': targetEmployeeId,
        if (scheduleId != null) 'schedule_id': scheduleId,
        if (targetScheduleId != null) 'target_schedule_id': targetScheduleId,
        if (reason != null) 'reason': reason,
        'status': status,
      };

  /// True when the swap's shift day is today or earlier in Cairo/Egypt time.
  bool get isExpired {
    if (scheduleWeekStart == null || scheduleDayIndex == null) return false;
    final shiftDate = scheduleWeekStart!.add(Duration(days: scheduleDayIndex!));
    final cairo = tz.getLocation('Africa/Cairo');
    final nowCairo = tz.TZDateTime.now(cairo);
    final todayCairo = DateTime(nowCairo.year, nowCairo.month, nowCairo.day);
    final shiftDay = DateTime(shiftDate.year, shiftDate.month, shiftDate.day);
    return !shiftDay.isAfter(todayCairo);
  }

  ShiftSwapRequestModel copyWith({int? id, String? status}) {
    return ShiftSwapRequestModel(
      id: id ?? this.id,
      requesterId: requesterId,
      targetEmployeeId: targetEmployeeId,
      scheduleId: scheduleId,
      reason: reason,
      status: status ?? this.status,
      createdAt: createdAt,
      requesterEnglishName: requesterEnglishName,
      requesterArabicName: requesterArabicName,
      requesterEnglishNickname: requesterEnglishNickname,
      requesterArabicNickname: requesterArabicNickname,
      targetEnglishName: targetEnglishName,
      targetArabicName: targetArabicName,
      targetEnglishNickname: targetEnglishNickname,
      targetArabicNickname: targetArabicNickname,
      scheduleEmployeeId: scheduleEmployeeId,
      scheduleWeekStart: scheduleWeekStart,
      scheduleDayIndex: scheduleDayIndex,
      scheduleStart: scheduleStart,
      scheduleEnd: scheduleEnd,
      targetScheduleId: targetScheduleId,
      targetScheduleStart: targetScheduleStart,
      targetScheduleEnd: targetScheduleEnd,
      targetScheduleDayIndex: targetScheduleDayIndex,
      targetScheduleHours: targetScheduleHours,
      targetScheduleTemplateId: targetScheduleTemplateId,
    );
  }
}
