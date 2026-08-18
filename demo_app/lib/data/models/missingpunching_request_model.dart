import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class MissingpunchingRequestModel {
  final int? id;
  final int userId;
  final DateTime? date;
  final DateTime? time;
  final String? type;
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
  final String? requestType;
  final bool? cancelled;
  final bool? removed;
  final bool? removedN1;
  final DateTime? n1ApprovalDate;
  final DateTime? n2ApprovalDate;
  final DateTime? hrApprovalDate;
  final int? hrApproverCode;
  final String? hrEnglishName;
  final String? hrArabicName;

  /// Whether this punch falls on a day the same employee is on a business trip.
  ///
  /// Server-computed (`has_businesstrip_conflict` in
  /// `missingpunch_request_row_payload`). It replaces
  /// [SameDayConflictService.missingPunchConflicts], which scanned the whole
  /// fetched list — a scan that cannot see rows outside the current page once
  /// the list is server-paged. `false` on the legacy path, where the service
  /// still supplies the ids.
  final bool hasBusinesstripConflict;

  String getLocalizedType(BuildContext context) {
    if (type == null) return AppLocalizations.of(context)!.missingPunching;
    switch (type) {
      case 'In':
        return AppLocalizations.of(context)!.inType;
      case 'Out':
        return AppLocalizations.of(context)!.outType;
      default:
        return type!;
    }
  }

  String getLocalizedStatus(BuildContext context) {
    if (isCancelled) {
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

  MissingpunchingRequestModel({
    this.id,
    required this.userId,
    this.date,
    this.time,
    this.type,
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
    this.requestType = 'missing_punching',
    this.cancelled,
    this.removed,
    this.removedN1,
    this.n1ApprovalDate,
    this.n2ApprovalDate,
    this.hrApprovalDate,
    this.hrApproverCode,
    this.hrEnglishName,
    this.hrArabicName,
    this.hasBusinesstripConflict = false,
  });

  MissingpunchingRequestModel copyWith({
    int? id,
    int? userId,
    DateTime? date,
    DateTime? time,
    String? type,
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
    String? requestType,
    bool? cancelled,
    bool? removed,
    bool? removedN1,
    DateTime? n1ApprovalDate,
    DateTime? n2ApprovalDate,
    DateTime? hrApprovalDate,
    int? hrApproverCode,
    String? hrEnglishName,
    String? hrArabicName,
    bool? hasBusinesstripConflict,
  }) {
    return MissingpunchingRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
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
      requestType: requestType ?? this.requestType,
      cancelled: cancelled ?? this.cancelled,
      removed: removed ?? this.removed,
      removedN1: removedN1 ?? this.removedN1,
      n1ApprovalDate: n1ApprovalDate ?? this.n1ApprovalDate,
      n2ApprovalDate: n2ApprovalDate ?? this.n2ApprovalDate,
      hrApprovalDate: hrApprovalDate ?? this.hrApprovalDate,
      hrApproverCode: hrApproverCode ?? this.hrApproverCode,
      hrEnglishName: hrEnglishName ?? this.hrEnglishName,
      hrArabicName: hrArabicName ?? this.hrArabicName,
      hasBusinesstripConflict: hasBusinesstripConflict ?? this.hasBusinesstripConflict,
    );
  }

  factory MissingpunchingRequestModel.fromJson(Map<String, dynamic> json) {
    return MissingpunchingRequestModel(
      id: json['id'],
      userId: json['user_id'],
      date: DateTime.tryParse(json['date']),
      time: DateTime.tryParse(json['time']),
      type: json['type'],
      status: json['status'],
      createdAt: DateTime.tryParse(json['created_at']),
      currentApprover: json['current_approver'],
      n1Code: json['n1_code'],
      n2Code: json['n2_code'],
      lastActionAt: DateTime.tryParse(json['last_action_at']),
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
      declineReason: json['decline_reason'],
      cancelled: json['cancelled'],
      removed: json['removed'] as bool?,
      removedN1: json['removed_n1'] as bool?,
      n1ApprovalDate: json['n1_approval_date'] != null ? DateTime.tryParse(json['n1_approval_date']) : null,
      n2ApprovalDate: json['n2_approval_date'] != null ? DateTime.tryParse(json['n2_approval_date']) : null,
      hrApprovalDate: json['hr_approval_date'] != null ? DateTime.tryParse(json['hr_approval_date']) : null,
      hrApproverCode: json['hr_approver_code'],
      hrEnglishName: json['hr_english_name'],
      hrArabicName: json['hr_arabic_name'],
      // Only the paged RPC emits this key; the legacy `select *` path does not,
      // and there the conflict ids come from SameDayConflictService instead.
      hasBusinesstripConflict: json['has_businesstrip_conflict'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'date': date?.toString(),
      'time': time?.toString(),
      'type': type,
      'n1_code': n1Code,
      'n2_code': n2Code,
    };
  }
}
