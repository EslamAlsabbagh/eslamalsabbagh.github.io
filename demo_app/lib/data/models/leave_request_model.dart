import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

class LeaveRequestModel {
  final int? id;
  final int userId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String leaveType;
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
  final double? numberOfDays;
  final double? userLeaveBalance;
  final double? userOvertimeBalance;
  final int? userShiftHours;
  final String? declineReason;
  final List<String>? attachments;
  final String? requestType;
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

  String getLocalizedLeaveType(BuildContext context) {
    switch (leaveType) {
      case 'Annual':
        return AppLocalizations.of(context)!.annual;
      case 'Emergency':
        return AppLocalizations.of(context)!.emergency;
      case 'Compensation':
        return AppLocalizations.of(context)!.compensation;
      case 'Sick':
        return AppLocalizations.of(context)!.sick;
      case 'Unpaid':
        return AppLocalizations.of(context)!.unpaid;
      default:
        return leaveType;
    }
  }

  DateTime get tzCreatedAt {
    if (createdAt == null) {
      throw Exception('dateFrom is null');
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
    if (dateFrom == null) return false;
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
        break;
      default:
        name = currentApprover ?? '';
    }

    // Truncate to 20 characters if longer
    return name.length > 20 ? '${name.substring(0, 20)}...' : name;
  }

  LeaveRequestModel({
    this.id,
    required this.userId,
    required this.dateFrom,
    required this.dateTo,
    required this.leaveType,
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
    this.numberOfDays,
    this.userLeaveBalance,
    this.userOvertimeBalance,
    this.userShiftHours,
    this.declineReason,
    this.attachments,
    this.requestType = 'leave',
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
  });

  factory LeaveRequestModel.fromJson(Map<String, dynamic> json) {
    return LeaveRequestModel(
      id: json['id'],
      userId: json['user_id'],
      dateFrom: DateTime.tryParse(json['date_from']),
      dateTo: DateTime.tryParse(json['date_to']),
      leaveType: json['leave_type'],
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
      // `num_of_days` is double precision, but Postgres renders a whole value
      // as `2`, not `2.0`, and jsonDecode turns that into an int — which does
      // not assign to a double? field. Every other numeric field here already
      // goes through toDouble(); this one did not.
      numberOfDays: (json['num_of_days'] as num?)?.toDouble(),
      userLeaveBalance: json['users']?['Leave Balance']?.toDouble(),
      userOvertimeBalance: json['users']?['overtime_balance']?.toDouble(),
      userShiftHours: json['users']?['Shift Hours'],
      declineReason: json['decline_reason'],
      attachments: json['attachments'] != null ? List<String>.from(json['attachments']) : null,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'date_from': dateFrom.toString(),
      'date_to': dateTo.toString(),
      'leave_type': leaveType,
      'n1_code': n1Code,
      'n2_code': n2Code,
      'num_of_days': numberOfDays,
    };
  }

  LeaveRequestModel copyWith({
    int? id,
    int? userId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? leaveType,
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
    double? numberOfDays,
    double? userLeaveBalance,
    double? userOvertimeBalance,
    int? userShiftHours,
    String? declineReason,
    List<String>? attachments,
    String? requestType,
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
  }) {
    return LeaveRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      leaveType: leaveType ?? this.leaveType,
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
      numberOfDays: numberOfDays ?? this.numberOfDays,
      userLeaveBalance: userLeaveBalance ?? this.userLeaveBalance,
      userOvertimeBalance: userOvertimeBalance ?? this.userOvertimeBalance,
      userShiftHours: userShiftHours ?? this.userShiftHours,
      declineReason: declineReason ?? this.declineReason,
      attachments: attachments ?? this.attachments,
      requestType: requestType ?? this.requestType,
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
    );
  }
}
