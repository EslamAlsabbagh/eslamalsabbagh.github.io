import 'package:hrms_demo/core/constants/business_trips.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class BusinesstripRequestModel {
  final int? id;
  final int userId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? location;
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
  final int? numberOfDays;
  final int? numberOfHours;
  final String? amPm;
  final bool? cancelled;
  final bool? removed;
  final bool? removedN1;
  final bool? hasPendingCancellation;
  final DateTime? n1ApprovalDate;
  final DateTime? n2ApprovalDate;
  final DateTime? hrApprovalDate;
  final int? hrApproverCode;
  final String? hrEnglishName;
  final String? hrArabicName;
  final bool transportationFeeRequested;
  final double? transportationFeeAmount;

  /// Whether this trip overlaps a same-user missing-punch day. Computed by the
  /// server on the paged path (`has_missing_punch_conflict` in
  /// `businesstrip_request_row_payload`); on the legacy whole-list path it stays
  /// `false` and the ids come from `SameDayConflictService` instead.
  final bool hasMissingPunchConflict;

  /// Whether this request's location entitles the employee to transportation fees.
  bool get deservesTransportationFees => locationDeservesTransportationFees(location);

  /// Whether this request should trigger the transportation-fee side effects
  /// (PDF generation + HR/Finance notification) — true when the location is
  /// auto-eligible OR the employee explicitly requested a fee.
  bool get needsFeeNotification => deservesTransportationFees || transportationFeeRequested;

  String getLocalizedLocation(BuildContext context) {
    if (location == null) return AppLocalizations.of(context)!.location;

    switch (location!.toLowerCase()) {
      case 'riverside':
        return AppLocalizations.of(context)!.riverside;
      case 'riverside park':
        return AppLocalizations.of(context)!.riversidePark;
      case 'north square':
        return AppLocalizations.of(context)!.northSquare;
      case 'other':
        return AppLocalizations.of(context)!.other;
      default:
        return location!;
    }
  }

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

  bool get canBeCancelledDirectly =>
      status?.toLowerCase() == 'pending' && cancelled != true && currentApprover?.toLowerCase() == 'n1';

  bool get canRequestCancellation {
    if (cancelled == true) return false;
    if (status?.toLowerCase() == 'declined') return false;
    if (dateTo == null) return false;
    if (hasPendingCancellation == true) return false;

    // Can only cancel if passed N+1 approval (current_approver moved to hr)
    // OR if fully approved
    bool passedN1 = currentApprover?.toLowerCase() == 'hr' || status?.toLowerCase() == 'approved';
    if (!passedN1) return false;

    // Can only cancel future requests
    final today = DateTime.now();
    final endDate = DateTime(dateTo!.year, dateTo!.month, dateTo!.day);
    final currentDate = DateTime(today.year, today.month, today.day);

    return currentDate.isBefore(endDate.add(const Duration(days: 1)));
  }

  bool get isPending => status?.toLowerCase() == 'pending' && cancelled != true;

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
      default:
        name = currentApprover ?? '';
    }

    // Truncate to 20 characters if longer
    return name.length > 20 ? '${name.substring(0, 20)}...' : name;
  }

  BusinesstripRequestModel({
    this.id,
    required this.userId,
    this.dateFrom,
    this.dateTo,
    this.location,
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
    this.requestType = 'business_trip',
    this.numberOfDays,
    this.numberOfHours,
    this.amPm,
    this.cancelled,
    this.removed,
    this.removedN1,
    this.hasPendingCancellation,
    this.n1ApprovalDate,
    this.n2ApprovalDate,
    this.hrApprovalDate,
    this.hrApproverCode,
    this.hrEnglishName,
    this.hrArabicName,
    this.transportationFeeRequested = false,
    this.transportationFeeAmount,
    this.hasMissingPunchConflict = false,
  });

  factory BusinesstripRequestModel.fromJson(Map<String, dynamic> json) {
    return BusinesstripRequestModel(
      id: json['id'],
      userId: json['user_id'],
      dateFrom: DateTime.tryParse(json['date_from'] ?? ''),
      dateTo: DateTime.tryParse(json['date_to'] ?? ''),
      location: json['location'],
      status: json['status'],
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
      currentApprover: json['current_approver'],
      n1Code: json['n1_code'],
      n2Code: json['n2_code'],
      n1EnglishName: json['n1_english_name'],
      n1ArabicName: json['n1_arabic_name'],
      n2EnglishName: json['n2_english_name'],
      n2ArabicName: json['n2_arabic_name'],
      lastActionAt: DateTime.tryParse(json['last_action_at'] ?? ''),
      userEnglishName: json['users']?['English Name'],
      userArabicName: json['users']?['Arabic Name'],
      userTitle: json['users']?['Title'],
      userEnglishTitle: json['users']?['english_title'],
      userDepartment: json['users']?['Department'],
      userEnglishDepartment: json['users']?['english_department'],
      userHireDate: json['users']?['Hire Date'],
      declineReason: json['decline_reason'],
      numberOfDays: json['number_of_days'],
      numberOfHours: json['number_of_hours'],
      amPm: json['am_pm'],
      cancelled: json['cancelled'],
      removed: json['removed'] as bool?,
      removedN1: json['removed_n1'] as bool?,
      hasPendingCancellation: json['has_pending_cancellation'] as bool?,
      n1ApprovalDate: json['n1_approval_date'] != null ? DateTime.tryParse(json['n1_approval_date']) : null,
      n2ApprovalDate: json['n2_approval_date'] != null ? DateTime.tryParse(json['n2_approval_date']) : null,
      hrApprovalDate: json['hr_approval_date'] != null ? DateTime.tryParse(json['hr_approval_date']) : null,
      hrApproverCode: json['hr_approver_code'],
      hrEnglishName: json['hr_english_name'],
      hrArabicName: json['hr_arabic_name'],
      transportationFeeRequested: json['transportation_fee_requested'] as bool? ?? false,
      transportationFeeAmount: (json['transportation_fee_amount'] as num?)?.toDouble(),
      hasMissingPunchConflict: json['has_missing_punch_conflict'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'date_from': dateFrom?.toIso8601String(),
      'date_to': dateTo?.toIso8601String(),
      'location': location,
      'number_of_hours': numberOfHours,
      'am_pm': amPm,
      'n1_code': n1Code,
      'n2_code': n2Code,
      'transportation_fee_requested': transportationFeeRequested,
      'transportation_fee_amount': transportationFeeAmount,
    };
  }

  BusinesstripRequestModel copyWith({
    int? id,
    int? userId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? location,
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
    int? numberOfDays,
    int? numberOfHours,
    String? amPm,
    bool? cancelled,
    bool? removed,
    bool? removedN1,
    bool? hasPendingCancellation,
    DateTime? n1ApprovalDate,
    DateTime? n2ApprovalDate,
    DateTime? hrApprovalDate,
    int? hrApproverCode,
    String? hrEnglishName,
    String? hrArabicName,
    bool? transportationFeeRequested,
    double? transportationFeeAmount,
    bool? hasMissingPunchConflict,
  }) {
    return BusinesstripRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      location: location ?? this.location,
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
      numberOfDays: numberOfDays ?? this.numberOfDays,
      numberOfHours: numberOfHours ?? this.numberOfHours,
      amPm: amPm ?? this.amPm,
      cancelled: cancelled ?? this.cancelled,
      removed: removed ?? this.removed,
      removedN1: removedN1 ?? this.removedN1,
      hasPendingCancellation: hasPendingCancellation ?? this.hasPendingCancellation,
      n1ApprovalDate: n1ApprovalDate ?? this.n1ApprovalDate,
      n2ApprovalDate: n2ApprovalDate ?? this.n2ApprovalDate,
      hrApprovalDate: hrApprovalDate ?? this.hrApprovalDate,
      hrApproverCode: hrApproverCode ?? this.hrApproverCode,
      hrEnglishName: hrEnglishName ?? this.hrEnglishName,
      hrArabicName: hrArabicName ?? this.hrArabicName,
      transportationFeeRequested: transportationFeeRequested ?? this.transportationFeeRequested,
      transportationFeeAmount: transportationFeeAmount ?? this.transportationFeeAmount,
      hasMissingPunchConflict: hasMissingPunchConflict ?? this.hasMissingPunchConflict,
    );
  }
}
