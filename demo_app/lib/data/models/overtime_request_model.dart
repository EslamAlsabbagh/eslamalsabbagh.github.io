import 'package:hrms_demo/core/constants/overtime_type.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class OvertimeRequestModel {
  final int? id;
  final int userId;
  final DateTime? date;
  final DateTime? timeFrom;
  final DateTime? timeTo;
  final String? status;
  final DateTime? createdAt;
  final String? currentApprover;
  final int? n1Code;
  final int? n2Code;
  final DateTime? lastActionAt;
  final String? userEnglishName;
  final String? userArabicName;
  final String? n1EnglishName;
  final String? n1ArabicName;
  final String? n2EnglishName;
  final String? n2ArabicName;
  final String? userTitle;
  final String? userEnglishTitle;
  final String? userDepartment;
  final String? userEnglishDepartment;
  final String? userHireDate;
  final String? declineReason;
  final String? reason;
  final String? overtimeType;
  final String? requestType;
  final double? numberOfHours;
  final bool? cancelled;
  final bool? removed;
  final bool? removedN1;
  final DateTime? n1ApprovalDate;
  final DateTime? n2ApprovalDate;
  final DateTime? hrApprovalDate;
  final int? hrApproverCode;
  final String? hrEnglishName;
  final String? hrArabicName;

  String getLocalizedOvertimeType(BuildContext context) {
    if (overtimeType == null) return AppLocalizations.of(context)!.overtime;
    switch (overtimeType) {
      case 'holidays':
        return AppLocalizations.of(context)!.holidays;
      case 'other':
        return AppLocalizations.of(context)!.other;
      default:
        return overtimeType!;
    }
  }

  bool get isCancelled => cancelled == true;

  bool get isActionable =>
      status?.toLowerCase() == 'pending' && cancelled != true && currentApprover?.toLowerCase() == 'n1';

  bool get isPending => status?.toLowerCase() == 'pending' && cancelled != true;

  DateTime get tzCreatedAt {
    if (createdAt == null) {
      throw Exception('createdAt is null');
    }
    final location = tz.getLocation('Africa/Cairo');
    return tz.TZDateTime.from(createdAt!, location);
  }

  String getLocalizedApproverName(BuildContext context, {String? hrApproverEnglishName, String? hrApproverArabicName}) {
    if (status?.toLowerCase() != 'pending' || currentApprover == null) {
      return '-';
    }
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    String name;

    switch (currentApprover?.toLowerCase()) {
      case 'n1':
        if (isArabic && n1ArabicName != null && n1ArabicName!.isNotEmpty) {
          name = n1ArabicName!;
        } else {
          name = n1EnglishName ?? 'N+1';
        }
        break;
      case 'n2':
        if (isArabic && n2ArabicName != null && n2ArabicName!.isNotEmpty) {
          name = n2ArabicName!;
        } else {
          name = n2EnglishName ?? 'N+2';
        }
        break;
      case 'hr':
        // Use provided approver name if available, otherwise use stored name, fallback to department label
        final englishName = hrApproverEnglishName ?? hrEnglishName;
        final arabicName = hrApproverArabicName ?? hrArabicName;

        if (englishName != null || arabicName != null) {
          name = isArabic ? (arabicName ?? englishName ?? 'HR') : (englishName ?? arabicName ?? 'HR');
        } else {
          // Backward compatibility: show dept name if no approver code
          return isArabic ? 'الموارد البشرية' : 'HR';
        }
        break;
      default:
        name = currentApprover ?? '';
    }

    // Truncate to 20 characters if longer
    return name.length > 20 ? '${name.substring(0, 20)}...' : name;
  }

  String getLocalizedStatus(BuildContext context) {
    // Check if cancelled first, as this overrides the status field
    if (cancelled == true) {
      return AppLocalizations.of(context)!.cancelled;
    }
    switch (status?.toLowerCase()) {
      case 'pending':
        return AppLocalizations.of(context)!.pending;
      case 'approved':
        return AppLocalizations.of(context)!.approved;
      case 'declined':
        return AppLocalizations.of(context)!.declined;
    }
    return status!;
  }

  OvertimeRequestModel({
    this.id,
    required this.userId,
    required this.date,
    required this.timeFrom,
    required this.timeTo,
    this.status,
    this.createdAt,
    this.currentApprover,
    this.n1Code,
    this.n2Code,
    this.lastActionAt,
    this.userEnglishName,
    this.userArabicName,
    this.n1EnglishName,
    this.n1ArabicName,
    this.n2EnglishName,
    this.n2ArabicName,
    this.userTitle,
    this.userEnglishTitle,
    this.userDepartment,
    this.userEnglishDepartment,
    this.userHireDate,
    this.declineReason,
    this.reason,
    this.overtimeType, // Default to holiday type
    this.requestType = 'overtime',
    this.numberOfHours,
    this.cancelled,
    this.removed,
    this.removedN1,
    this.n1ApprovalDate,
    this.n2ApprovalDate,
    this.hrApprovalDate,
    this.hrApproverCode,
    this.hrEnglishName,
    this.hrArabicName,
  });

  factory OvertimeRequestModel.fromJson(Map<String, dynamic> json) {
    return OvertimeRequestModel(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.tryParse(json['date']),
      timeFrom: DateTime.tryParse(json['time_from']),
      timeTo: DateTime.tryParse(json['time_to']),
      status: json['status'],
      createdAt: DateTime.tryParse(json['created_at']),
      currentApprover: json['current_approver'],
      n1Code: json['n1_code'],
      n2Code: json['n2_code'],
      userEnglishName: json['users']?['English Name'],
      userArabicName: json['users']?['Arabic Name'],
      n1EnglishName: json['n1_english_name'],
      n1ArabicName: json['n1_arabic_name'],
      n2EnglishName: json['n2_english_name'],
      n2ArabicName: json['n2_arabic_name'],
      userTitle: json['users']?['Title'],
      userEnglishTitle: json['users']?['english_title'],
      userDepartment: json['users']?['Department'],
      userEnglishDepartment: json['users']?['english_department'],
      userHireDate: json['users']?['Hire Date'],
      lastActionAt: DateTime.tryParse(json['last_action_at']),
      declineReason: json['decline_reason'],
      reason: json['reason'],
      overtimeType: json['overtime_type'],
      numberOfHours: json['number_of_hours'],
      cancelled: json['cancelled'],
      removed: json['removed'] as bool?,
      removedN1: json['removed_n1'] as bool?,
      n1ApprovalDate: json['n1_approval_date'] != null ? DateTime.tryParse(json['n1_approval_date']) : null,
      n2ApprovalDate: json['n2_approval_date'] != null ? DateTime.tryParse(json['n2_approval_date']) : null,
      hrApprovalDate: json['hr_approval_date'] != null ? DateTime.tryParse(json['hr_approval_date']) : null,
      hrApproverCode: json['hr_approver_code'],
      hrEnglishName: json['hr_english_name'],
      hrArabicName: json['hr_arabic_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'date': date.toString(),
      'time_from': timeFrom.toString(),
      'time_to': timeTo.toString(),
      'n1_code': n1Code,
      'n2_code': n2Code,
      'reason': reason,
      'overtime_type': overtimeType ?? OvertimeType.holidays.name,
    };
  }

  OvertimeRequestModel copyWith({
    int? id,
    int? userId,
    DateTime? date,
    DateTime? timeFrom,
    DateTime? timeTo,
    String? status,
    DateTime? createdAt,
    String? currentApprover,
    int? n1Code,
    int? n2Code,
    DateTime? lastActionAt,
    String? userEnglishName,
    String? userArabicName,
    String? n1EnglishName,
    String? n1ArabicName,
    String? n2EnglishName,
    String? n2ArabicName,
    String? userTitle,
    String? userEnglishTitle,
    String? userDepartment,
    String? userEnglishDepartment,
    String? userHireDate,
    String? declineReason,
    String? reason,
    String? overtimeType,
    String? requestType,
    double? numberOfHours,
    bool? cancelled,
    bool? removed,
    bool? removedN1,
    DateTime? n1ApprovalDate,
    DateTime? n2ApprovalDate,
    DateTime? hrApprovalDate,
    int? hrApproverCode,
    String? hrEnglishName,
    String? hrArabicName,
  }) {
    return OvertimeRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      timeFrom: timeFrom ?? this.timeFrom,
      timeTo: timeTo ?? this.timeTo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      currentApprover: currentApprover ?? this.currentApprover,
      n1Code: n1Code ?? this.n1Code,
      n2Code: n2Code ?? this.n2Code,
      lastActionAt: lastActionAt ?? this.lastActionAt,
      userEnglishName: userEnglishName ?? this.userEnglishName,
      userArabicName: userArabicName ?? this.userArabicName,
      n1EnglishName: n1EnglishName ?? this.n1EnglishName,
      n1ArabicName: n1ArabicName ?? this.n1ArabicName,
      n2EnglishName: n2EnglishName ?? this.n2EnglishName,
      n2ArabicName: n2ArabicName ?? this.n2ArabicName,
      userTitle: userTitle ?? this.userTitle,
      userEnglishTitle: userEnglishTitle ?? this.userEnglishTitle,
      userDepartment: userDepartment ?? this.userDepartment,
      userEnglishDepartment: userEnglishDepartment ?? this.userEnglishDepartment,
      userHireDate: userHireDate ?? this.userHireDate,
      declineReason: declineReason ?? this.declineReason,
      reason: reason ?? this.reason,
      overtimeType: overtimeType ?? this.overtimeType,
      requestType: requestType ?? this.requestType,
      numberOfHours: numberOfHours ?? this.numberOfHours,
      cancelled: cancelled ?? this.cancelled,
      removed: removed ?? this.removed,
      removedN1: removedN1 ?? this.removedN1,
      n1ApprovalDate: n1ApprovalDate ?? this.n1ApprovalDate,
      n2ApprovalDate: n2ApprovalDate ?? this.n2ApprovalDate,
      hrApprovalDate: hrApprovalDate ?? this.hrApprovalDate,
      hrApproverCode: hrApproverCode ?? this.hrApproverCode,
      hrEnglishName: hrEnglishName ?? this.hrEnglishName,
      hrArabicName: hrArabicName ?? this.hrArabicName,
    );
  }
}
