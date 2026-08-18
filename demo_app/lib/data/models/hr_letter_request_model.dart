import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class HrLetterRequestModel {
  final int? id;
  final DateTime? createdAt;
  final DateTime? lastActionAt;
  final int? employeeCode;
  final String? nationalId;
  final String? letterPurpose; // 'bank' | 'embassy' | 'other'
  final DateTime? travelFromDate;
  final DateTime? travelToDate;
  final String? details;
  final String? status; // 'pending' | 'acknowledged' | 'completed' | 'declined' | 'cancelled'
  final int? hrHandlerCode;
  final DateTime? acknowledgedAt;
  final DateTime? completedAt;
  final DateTime? declinedAt;
  final String? declineReason;
  final DateTime? cancelledAt;

  // Denormalized fields - populated by repo, NOT stored in DB
  final String? employeeEnglishName;
  final String? employeeArabicName;
  final String? employeeTitle;
  final String? employeeEnglishTitle;
  final String? employeeDepartment;
  final String? employeeEnglishDepartment;
  final String? employeeHireDate;
  final String? hrHandlerEnglishName;
  final String? hrHandlerArabicName;

  const HrLetterRequestModel({
    this.id,
    this.createdAt,
    this.lastActionAt,
    this.employeeCode,
    this.nationalId,
    this.letterPurpose,
    this.travelFromDate,
    this.travelToDate,
    this.details,
    this.status,
    this.hrHandlerCode,
    this.acknowledgedAt,
    this.completedAt,
    this.declinedAt,
    this.declineReason,
    this.cancelledAt,
    this.employeeEnglishName,
    this.employeeArabicName,
    this.employeeTitle,
    this.employeeEnglishTitle,
    this.employeeDepartment,
    this.employeeEnglishDepartment,
    this.employeeHireDate,
    this.hrHandlerEnglishName,
    this.hrHandlerArabicName,
  });

  String get requestType => 'hr_letter';
  int? get userId => employeeCode;

  bool get isPending => status == 'pending';
  bool get isAcknowledged => status == 'acknowledged';
  bool get isCompleted => status == 'completed';
  bool get isDeclined => status == 'declined';
  bool get isCancelled => status == 'cancelled';
  bool get isEmbassy => letterPurpose == 'embassy';
  bool get isActionable => status == 'pending' || status == 'acknowledged';

  String getLocalizedEmployeeName(bool isArabic) {
    return isArabic
        ? (employeeArabicName ?? employeeEnglishName ?? '')
        : (employeeEnglishName ?? employeeArabicName ?? '');
  }

  String getLocalizedHrHandlerName(bool isArabic) {
    return isArabic
        ? (hrHandlerArabicName ?? hrHandlerEnglishName ?? '')
        : (hrHandlerEnglishName ?? hrHandlerArabicName ?? '');
  }

  String getLocalizedLetterPurpose(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (letterPurpose) {
      case 'bank':
        return l10n.letterPurposeBank;
      case 'embassy':
        return l10n.letterPurposeEmbassy;
      case 'other':
        return l10n.letterPurposeOther;
      default:
        return letterPurpose ?? '';
    }
  }

  String getLocalizedStatus(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'pending':
        return l10n.pending;
      case 'acknowledged':
        return l10n.acknowledged;
      case 'completed':
        return l10n.completed;
      case 'declined':
        return l10n.declined;
      case 'cancelled':
        return l10n.cancelled;
      default:
        return status ?? '';
    }
  }

  factory HrLetterRequestModel.fromJson(Map<String, dynamic> json) {
    return HrLetterRequestModel(
      id: json['id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']).toLocal() : null,
      lastActionAt: json['last_action_at'] != null ? DateTime.parse(json['last_action_at']).toLocal() : null,
      employeeCode: json['employee_code'],
      nationalId: json['national_id'],
      letterPurpose: json['letter_purpose'],
      travelFromDate: json['travel_from_date'] != null ? DateTime.parse(json['travel_from_date']) : null,
      travelToDate: json['travel_to_date'] != null ? DateTime.parse(json['travel_to_date']) : null,
      details: json['details'],
      status: json['status'],
      hrHandlerCode: json['hr_handler_code'],
      acknowledgedAt: json['acknowledged_at'] != null ? DateTime.parse(json['acknowledged_at']).toLocal() : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']).toLocal() : null,
      declinedAt: json['declined_at'] != null ? DateTime.parse(json['declined_at']).toLocal() : null,
      declineReason: json['decline_reason'],
      cancelledAt: json['cancelled_at'] != null ? DateTime.parse(json['cancelled_at']).toLocal() : null,
      // Denormalized
      employeeEnglishName: json['employee_english_name'],
      employeeArabicName: json['employee_arabic_name'],
      employeeTitle: json['employee_title'],
      employeeEnglishTitle: json['employee_english_title'],
      employeeDepartment: json['employee_department'],
      employeeEnglishDepartment: json['employee_english_department'],
      employeeHireDate: json['employee_hire_date'],
      hrHandlerEnglishName: json['hr_handler_english_name'],
      hrHandlerArabicName: json['hr_handler_arabic_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (lastActionAt != null) 'last_action_at': lastActionAt!.toIso8601String(),
      if (employeeCode != null) 'employee_code': employeeCode,
      if (nationalId != null) 'national_id': nationalId,
      if (letterPurpose != null) 'letter_purpose': letterPurpose,
      if (travelFromDate != null) 'travel_from_date': travelFromDate!.toIso8601String().split('T')[0],
      if (travelToDate != null) 'travel_to_date': travelToDate!.toIso8601String().split('T')[0],
      if (details != null && details!.isNotEmpty) 'details': details,
      if (status != null) 'status': status,
      if (hrHandlerCode != null) 'hr_handler_code': hrHandlerCode,
      if (acknowledgedAt != null) 'acknowledged_at': acknowledgedAt!.toIso8601String(),
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (declinedAt != null) 'declined_at': declinedAt!.toIso8601String(),
      if (declineReason != null) 'decline_reason': declineReason,
      if (cancelledAt != null) 'cancelled_at': cancelledAt!.toIso8601String(),
    };
  }

  HrLetterRequestModel copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? lastActionAt,
    int? employeeCode,
    String? nationalId,
    String? letterPurpose,
    DateTime? travelFromDate,
    DateTime? travelToDate,
    String? details,
    String? status,
    int? hrHandlerCode,
    DateTime? acknowledgedAt,
    DateTime? completedAt,
    DateTime? declinedAt,
    String? declineReason,
    DateTime? cancelledAt,
    String? employeeEnglishName,
    String? employeeArabicName,
    String? employeeTitle,
    String? employeeEnglishTitle,
    String? employeeDepartment,
    String? employeeEnglishDepartment,
    String? employeeHireDate,
    String? hrHandlerEnglishName,
    String? hrHandlerArabicName,
    bool clearTravelFromDate = false,
    bool clearTravelToDate = false,
  }) {
    return HrLetterRequestModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      lastActionAt: lastActionAt ?? this.lastActionAt,
      employeeCode: employeeCode ?? this.employeeCode,
      nationalId: nationalId ?? this.nationalId,
      letterPurpose: letterPurpose ?? this.letterPurpose,
      travelFromDate: clearTravelFromDate ? null : (travelFromDate ?? this.travelFromDate),
      travelToDate: clearTravelToDate ? null : (travelToDate ?? this.travelToDate),
      details: details ?? this.details,
      status: status ?? this.status,
      hrHandlerCode: hrHandlerCode ?? this.hrHandlerCode,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      completedAt: completedAt ?? this.completedAt,
      declinedAt: declinedAt ?? this.declinedAt,
      declineReason: declineReason ?? this.declineReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      employeeEnglishName: employeeEnglishName ?? this.employeeEnglishName,
      employeeArabicName: employeeArabicName ?? this.employeeArabicName,
      employeeTitle: employeeTitle ?? this.employeeTitle,
      employeeEnglishTitle: employeeEnglishTitle ?? this.employeeEnglishTitle,
      employeeDepartment: employeeDepartment ?? this.employeeDepartment,
      employeeEnglishDepartment: employeeEnglishDepartment ?? this.employeeEnglishDepartment,
      employeeHireDate: employeeHireDate ?? this.employeeHireDate,
      hrHandlerEnglishName: hrHandlerEnglishName ?? this.hrHandlerEnglishName,
      hrHandlerArabicName: hrHandlerArabicName ?? this.hrHandlerArabicName,
    );
  }
}
