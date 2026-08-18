import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class BusinesstripCancellationRequestModel {
  final int? id;
  final int originalBusinesstripRequestId;
  final int userId;
  final String reason;
  final String? status;
  final DateTime? createdAt;
  final String? currentApprover;
  final int? n1Code;
  final int? n2Code;
  final String? n1EnglishName;
  final String? n1ArabicName;
  final String? n2EnglishName;
  final String? n2ArabicName;
  final DateTime? lastActionAt;
  final String? userEnglishName;
  final String? userArabicName;
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
  // Original business trip request details for display
  final DateTime? originalTripFrom;
  final DateTime? originalTripTo;
  final String? originalLocation;
  final String? originalTripStatus;
  final int? originalNumberOfDays;
  final int? originalNumberOfHours;
  final String? originalAmPm;

  DateTime get tzCreatedAt {
    if (createdAt == null) {
      throw Exception('createdAt is null');
    }
    final location = tz.getLocation('Africa/Cairo');
    return tz.TZDateTime.from(createdAt!, location);
  }

  bool get isCancelled => cancelled == true;

  bool get isActionable =>
      status?.toLowerCase() == 'pending' && cancelled != true && currentApprover?.toLowerCase() == 'n1';

  bool get isPending => status?.toLowerCase() == 'pending' && cancelled != true;

  String getLocalizedStatus(BuildContext context) {
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

  String getLocalizedOriginalLocation(BuildContext context) {
    if (originalLocation == null) return AppLocalizations.of(context)!.location;

    switch (originalLocation!.toLowerCase()) {
      case 'riverside':
        return AppLocalizations.of(context)!.riverside;
      case 'riverside park':
        return AppLocalizations.of(context)!.riversidePark;
      case 'north square':
        return AppLocalizations.of(context)!.northSquare;
      case 'other':
        return AppLocalizations.of(context)!.other;
      default:
        return originalLocation!;
    }
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

  BusinesstripCancellationRequestModel({
    this.id,
    required this.originalBusinesstripRequestId,
    required this.userId,
    required this.reason,
    this.status,
    this.createdAt,
    this.currentApprover,
    this.n1Code,
    this.n2Code,
    this.n1EnglishName,
    this.n1ArabicName,
    this.n2EnglishName,
    this.n2ArabicName,
    this.lastActionAt,
    this.userEnglishName,
    this.userArabicName,
    this.userTitle,
    this.userEnglishTitle,
    this.userDepartment,
    this.userEnglishDepartment,
    this.userHireDate,
    this.declineReason,
    this.requestType = 'businesstrip_cancellation',
    this.cancelled,
    this.removed,
    this.removedN1,
    this.n1ApprovalDate,
    this.n2ApprovalDate,
    this.hrApprovalDate,
    this.hrApproverCode,
    this.hrEnglishName,
    this.hrArabicName,
    this.originalTripFrom,
    this.originalTripTo,
    this.originalLocation,
    this.originalTripStatus,
    this.originalNumberOfDays,
    this.originalNumberOfHours,
    this.originalAmPm,
  });

  factory BusinesstripCancellationRequestModel.fromJson(Map<String, dynamic> json) {
    return BusinesstripCancellationRequestModel(
      id: json['id'],
      originalBusinesstripRequestId: json['original_businesstrip_request_id'],
      userId: json['user_id'],
      reason: json['reason'],
      status: json['status'],
      createdAt: DateTime.tryParse(json['created_at']),
      currentApprover: json['current_approver'],
      n1Code: json['n1_code'],
      n2Code: json['n2_code'],
      n1EnglishName: json['n1_english_name'],
      n1ArabicName: json['n1_arabic_name'],
      n2EnglishName: json['n2_english_name'],
      n2ArabicName: json['n2_arabic_name'],
      userEnglishName: json['users']?['English Name'],
      userArabicName: json['users']?['Arabic Name'],
      userTitle: json['users']?['Title'],
      userEnglishTitle: json['users']?['english_title'],
      userDepartment: json['users']?['Department'],
      userEnglishDepartment: json['users']?['english_department'],
      userHireDate: json['users']?['Hire Date'],
      lastActionAt: DateTime.tryParse(json['last_action_at']),
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
      // Original business trip request details from joined query
      originalTripFrom: DateTime.tryParse(json['original_businesstrip_request']?['date_from']),
      originalTripTo: DateTime.tryParse(json['original_businesstrip_request']?['date_to']),
      originalLocation: json['original_businesstrip_request']?['location'],
      originalTripStatus: json['original_businesstrip_request']?['status'],
      originalNumberOfDays: json['original_businesstrip_request']?['number_of_days'],
      originalNumberOfHours: json['original_businesstrip_request']?['number_of_hours'],
      originalAmPm: json['original_businesstrip_request']?['am_pm'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'original_businesstrip_request_id': originalBusinesstripRequestId,
      'user_id': userId,
      'reason': reason,
      'n1_code': n1Code,
      'n2_code': n2Code,
    };
  }

  BusinesstripCancellationRequestModel copyWith({
    int? id,
    int? originalBusinesstripRequestId,
    int? userId,
    String? reason,
    String? status,
    DateTime? createdAt,
    String? currentApprover,
    int? n1Code,
    int? n2Code,
    String? n1EnglishName,
    String? n1ArabicName,
    String? n2EnglishName,
    String? n2ArabicName,
    DateTime? lastActionAt,
    String? userEnglishName,
    String? userArabicName,
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
    DateTime? originalTripFrom,
    DateTime? originalTripTo,
    String? originalLocation,
    String? originalTripStatus,
    int? originalNumberOfDays,
    int? originalNumberOfHours,
    String? originalAmPm,
  }) {
    return BusinesstripCancellationRequestModel(
      id: id ?? this.id,
      originalBusinesstripRequestId: originalBusinesstripRequestId ?? this.originalBusinesstripRequestId,
      userId: userId ?? this.userId,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      currentApprover: currentApprover ?? this.currentApprover,
      n1Code: n1Code ?? this.n1Code,
      n2Code: n2Code ?? this.n2Code,
      n1EnglishName: n1EnglishName ?? this.n1EnglishName,
      n1ArabicName: n1ArabicName ?? this.n1ArabicName,
      n2EnglishName: n2EnglishName ?? this.n2EnglishName,
      n2ArabicName: n2ArabicName ?? this.n2ArabicName,
      lastActionAt: lastActionAt ?? this.lastActionAt,
      userEnglishName: userEnglishName ?? this.userEnglishName,
      userArabicName: userArabicName ?? this.userArabicName,
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
      originalTripFrom: originalTripFrom ?? this.originalTripFrom,
      originalTripTo: originalTripTo ?? this.originalTripTo,
      originalLocation: originalLocation ?? this.originalLocation,
      originalTripStatus: originalTripStatus ?? this.originalTripStatus,
      originalNumberOfDays: originalNumberOfDays ?? this.originalNumberOfDays,
      originalNumberOfHours: originalNumberOfHours ?? this.originalNumberOfHours,
      originalAmPm: originalAmPm ?? this.originalAmPm,
    );
  }
}
