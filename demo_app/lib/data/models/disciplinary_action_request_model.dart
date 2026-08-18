import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

enum DisciplinaryActionType {
  verbalRemark('verbal_remark'),
  writtenRemark('written_remark'),
  writtenWarning('written_warning'),
  hrInvestigation('hr_investigation');

  const DisciplinaryActionType(this.value);
  final String value;

  static DisciplinaryActionType fromString(String value) {
    return DisciplinaryActionType.values.firstWhere((type) => type.value == value);
  }

  String getLocalizedName(BuildContext context) {
    switch (this) {
      case DisciplinaryActionType.verbalRemark:
        return AppLocalizations.of(context)!.verbalRemark;
      case DisciplinaryActionType.writtenRemark:
        return AppLocalizations.of(context)!.writtenRemark;
      case DisciplinaryActionType.writtenWarning:
        return AppLocalizations.of(context)!.writtenWarning;
      case DisciplinaryActionType.hrInvestigation:
        return AppLocalizations.of(context)!.investigation;
    }
  }
}

class WrittenWarningOptions {
  final double? deductDays;
  final int? suspensionDays;

  WrittenWarningOptions({this.deductDays, this.suspensionDays});

  factory WrittenWarningOptions.fromJson(Map<String, dynamic> json) {
    return WrittenWarningOptions(
      deductDays: (json['deduct_days'] as num?)?.toDouble(),
      suspensionDays: json['suspension_days'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'deduct_days': deductDays, 'suspension_days': suspensionDays};
  }

  WrittenWarningOptions copyWith({double? deductDays, int? suspensionDays}) {
    return WrittenWarningOptions(
      deductDays: deductDays ?? this.deductDays,
      suspensionDays: suspensionDays ?? this.suspensionDays,
    );
  }

  bool get hasDeduction => deductDays != null && deductDays! > 0;
  bool get hasSuspension => suspensionDays != null && suspensionDays! > 0;
}

class DisciplinaryActionRequestModel {
  final int? id;
  final int? requestorCode;
  final int? employeeCode;
  final int? n2Code;
  final String? violationCategory;
  final String? violation;
  final DisciplinaryActionType? actionType;
  final String? incidentDescription;
  final DateTime? violationDate;
  final WrittenWarningOptions? writtenWarningOptions;
  final String? status;
  final DateTime? createdAt;
  final DateTime? lastActionAt;
  final String? currentApprover;
  final String? declineReason;
  final String? requestType;
  final String? pdfUrl;
  final DateTime? pdfGeneratedAt;
  final String? requestorEnglishName;
  final String? requestorArabicName;
  final String? employeeEnglishName;
  final String? employeeArabicName;
  final String? n2EnglishName;
  final String? n2ArabicName;
  final String? requestorTitle;
  final String? requestorEnglishTitle;
  final String? requestorDepartment;
  final String? requestorEnglishDepartment;
  final String? requestorHireDate;
  final String? employeeTitle;
  final String? employeeEnglishTitle;
  final String? employeeDepartment;
  final String? employeeEnglishDepartment;
  final String? employeeHireDate;
  final int? hrApproverCode;
  final String? hrEnglishName;
  final String? hrArabicName;
  final DateTime? n2ApprovalDate;
  final DateTime? hrApprovalDate;
  final bool? cancelled;
  final String? n2ApprovalReason;
  final String? hrApprovalReason;
  final String? holdReason;
  final String? n2InvestigationReason;
  final String? comments;
  final String? hrInvestigationPdfUrl;
  final DateTime? hrInvestigationPdfUploadedAt;
  final DateTime? employeeAcknowledgmentDate;
  final String? employeeAcknowledgmentRemark;
  final String? employeeAcknowledgmentType;
  final bool? autoEscalated;
  final bool? escalatedToLegal;
  final String? legalInvestigationPdfUrl;
  final DateTime? legalInvestigationPdfUploadedAt;
  final int? legalApproverCode;
  final DateTime? legalEscalationDate;
  final String? legalEscalationReason;
  final DateTime? legalCompletionDate;
  final String? hrFinalAction;
  final int? suspensionDaysField;
  final DateTime? suspensionStartDate;
  final DateTime? suspensionEndDate;
  final DateTime? terminationRecommendedDate;
  final bool? closedAtHR;
  final String? legalEnglishName;
  final String? legalArabicName;
  final bool? legalAcknowledged;
  final List<String>? attachments;
  final int? investigationId;
  final String? sourceType;
  final bool? createdFromInvestigation;

  DisciplinaryActionRequestModel({
    this.id,
    this.requestorCode,
    this.employeeCode,
    this.n2Code,
    this.violationCategory,
    this.violation,
    this.actionType,
    this.incidentDescription,
    this.violationDate,
    this.writtenWarningOptions,
    this.status,
    this.createdAt,
    this.lastActionAt,
    this.currentApprover,
    this.declineReason,
    this.requestType = 'disciplinary_action',
    this.pdfUrl,
    this.pdfGeneratedAt,
    this.requestorEnglishName,
    this.requestorArabicName,
    this.employeeEnglishName,
    this.employeeArabicName,
    this.n2EnglishName,
    this.n2ArabicName,
    this.requestorTitle,
    this.requestorEnglishTitle,
    this.requestorDepartment,
    this.requestorEnglishDepartment,
    this.requestorHireDate,
    this.employeeTitle,
    this.employeeEnglishTitle,
    this.employeeDepartment,
    this.employeeEnglishDepartment,
    this.employeeHireDate,
    this.hrApproverCode,
    this.hrEnglishName,
    this.hrArabicName,
    this.n2ApprovalDate,
    this.hrApprovalDate,
    this.cancelled,
    this.n2ApprovalReason,
    this.hrApprovalReason,
    this.holdReason,
    this.n2InvestigationReason,
    this.comments,
    this.hrInvestigationPdfUrl,
    this.hrInvestigationPdfUploadedAt,
    this.employeeAcknowledgmentDate,
    this.employeeAcknowledgmentRemark,
    this.employeeAcknowledgmentType,
    this.autoEscalated,
    this.escalatedToLegal,
    this.legalInvestigationPdfUrl,
    this.legalInvestigationPdfUploadedAt,
    this.legalApproverCode,
    this.legalEscalationDate,
    this.legalEscalationReason,
    this.legalCompletionDate,
    this.hrFinalAction,
    this.suspensionDaysField,
    this.suspensionStartDate,
    this.suspensionEndDate,
    this.terminationRecommendedDate,
    this.closedAtHR,
    this.legalEnglishName,
    this.legalArabicName,
    this.legalAcknowledged,
    this.attachments,
    this.investigationId,
    this.sourceType = 'direct',
    this.createdFromInvestigation = false,
  });

  DateTime get tzCreatedAt {
    if (createdAt == null) {
      throw Exception('createdAt is null');
    }
    final location = tz.getLocation('Africa/Cairo');
    return tz.TZDateTime.from(createdAt!, location);
  }

  String getLocalizedApproverName(BuildContext context, {String? hrApproverEnglishName, String? hrApproverArabicName}) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    String name;

    switch (currentApprover?.toLowerCase()) {
      case 'employee':
        if (isArabic && employeeArabicName != null && employeeArabicName!.isNotEmpty) {
          name = employeeArabicName!;
        } else {
          name = employeeEnglishName ?? 'Employee';
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
      case 'legal':
        final englishName = legalEnglishName;
        final arabicName = legalArabicName;

        if (englishName != null || arabicName != null) {
          name = isArabic ? (arabicName ?? englishName ?? 'Legal') : (englishName ?? arabicName ?? 'Legal');
        } else {
          return isArabic ? 'الشؤون القانونية' : 'Legal';
        }
        break;
      default:
        name = currentApprover ?? '';
    }

    // Truncate to 20 characters if longer
    return name.length > 20 ? '${name.substring(0, 20)}...' : name;
  }

  String getLocalizedStatus(BuildContext context) {
    // Check if closed at HR level first (hides actual action from employee)
    if (closedAtHR == true) {
      return AppLocalizations.of(context)!.closedAtHR;
    }

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
      case 'on_hold':
        return AppLocalizations.of(context)!.onHold;
      case 'converted_to_investigation':
        return AppLocalizations.of(context)!.convertedToInvestigation;
    }
    return status!;
  }

  bool get isCancelled => cancelled == true;
  bool get isActionable =>
      (status?.toLowerCase() == 'pending' ||
          (status?.toLowerCase() == 'on_hold' && currentApprover?.toLowerCase() == 'hr')) &&
      cancelled != true;
  bool get shouldHavePDF => status?.toLowerCase() == 'approved';
  bool get isAtHrApproval => currentApprover?.toLowerCase() == 'hr';
  bool get shouldGeneratePDF => status?.toLowerCase() == 'approved' && currentApprover?.toLowerCase() == 'hr';

  String getLocalizedActionType(BuildContext context) {
    return actionType?.getLocalizedName(context) ?? '';
  }

  String getEmployeeName(bool isArabic) {
    return isArabic
        ? (employeeArabicName ?? employeeEnglishName ?? '')
        : (employeeEnglishName ?? employeeArabicName ?? '');
  }

  String getRequestorName(bool isArabic) {
    return isArabic
        ? (requestorArabicName ?? requestorEnglishName ?? '')
        : (requestorEnglishName ?? requestorArabicName ?? '');
  }

  bool get isWrittenWarning => actionType == DisciplinaryActionType.writtenWarning;
  bool get hasDeductionDays => writtenWarningOptions?.hasDeduction == true;
  bool get hasSuspensionDays => writtenWarningOptions?.hasSuspension == true;

  double get deductionDays => writtenWarningOptions?.deductDays ?? 0;
  int get suspensionDays => writtenWarningOptions?.suspensionDays ?? 0;

  bool get hasInvestigationPdf => hrInvestigationPdfUrl != null && hrInvestigationPdfUrl!.isNotEmpty;
  bool get isEscalatedToLegal => escalatedToLegal == true;
  bool get isAtLegalApproval => currentApprover?.toLowerCase() == 'legal';
  bool get hasLegalInvestigationPdf => legalInvestigationPdfUrl != null && legalInvestigationPdfUrl!.isNotEmpty;
  bool get isClosedAtHR => closedAtHR == true;
  bool get isSuspended => hrFinalAction == 'suspend';
  bool get isTerminated => hrFinalAction == 'terminate';

  /// Add a change log entry to comments
  DisciplinaryActionRequestModel addChangeLog(String change) {
    final timestamp = DateTime.now().toString().substring(0, 19);
    final newChange = "[$timestamp] $change";
    final updatedComments = comments != null ? "$comments\n$newChange" : newChange;

    return copyWith(comments: updatedComments);
  }

  /// Add a bilingual change log entry to comments
  DisciplinaryActionRequestModel addBilingualChangeLog({required String englishChange, required String arabicChange}) {
    final timestamp = DateTime.now().toString().substring(0, 19);
    final newChange = "[$timestamp] EN: $englishChange | AR: $arabicChange";
    final updatedComments = comments != null ? "$comments\n$newChange" : newChange;

    return copyWith(comments: updatedComments);
  }

  factory DisciplinaryActionRequestModel.fromJson(Map<String, dynamic> json) {
    return DisciplinaryActionRequestModel(
      id: json['id'],
      requestorCode: json['requestor_code'],
      employeeCode: json['employee_code'],
      n2Code: json['n2_code'],
      violationCategory: json['violation_category'],
      violation: json['violation'],
      actionType: json['action_type'] != null ? DisciplinaryActionType.fromString(json['action_type']) : null,
      incidentDescription: json['incident_description'],
      violationDate: DateTime.tryParse(json['violation_date'] ?? ''),
      writtenWarningOptions:
          json['written_warning_options'] != null
              ? WrittenWarningOptions.fromJson(json['written_warning_options'])
              : null,
      status: json['status'],
      createdAt: DateTime.tryParse(json['created_at'] ?? ''),
      lastActionAt: DateTime.tryParse(json['last_action_at'] ?? ''),
      currentApprover: json['current_approver'],
      declineReason: json['decline_reason'],
      requestorEnglishName: json['requestor_english_name'],
      requestorArabicName: json['requestor_arabic_name'],
      employeeEnglishName: json['employee_english_name'],
      employeeArabicName: json['employee_arabic_name'],
      n2EnglishName: json['n2']?['English Name'],
      n2ArabicName: json['n2']?['Arabic Name'],
      requestorTitle: json['requestor']?['Title'],
      requestorEnglishTitle: json['requestor']?['english_title'],
      requestorDepartment: json['requestor']?['Department'],
      requestorEnglishDepartment: json['requestor']?['english_department'],
      requestorHireDate: json['requestor']?['Hire Date'],
      employeeTitle: json['employee']?['Title'],
      employeeEnglishTitle: json['employee']?['english_title'],
      employeeDepartment: json['employee']?['Department'],
      employeeEnglishDepartment: json['employee']?['english_department'],
      employeeHireDate: json['employee']?['Hire Date'],
      hrApproverCode: json['hr_approver_code'],
      hrEnglishName: json['hr_english_name'],
      hrArabicName: json['hr_arabic_name'],
      n2ApprovalDate: DateTime.tryParse(json['n2_approval_date'] ?? ''),
      hrApprovalDate: DateTime.tryParse(json['hr_approval_date'] ?? ''),
      cancelled: json['cancelled'],
      n2ApprovalReason: json['n2_approval_reason'],
      hrApprovalReason: json['hr_approval_reason'],
      holdReason: json['hold_reason'],
      n2InvestigationReason: json['n2_investigation_reason'],
      comments: json['comments'],
      hrInvestigationPdfUrl: json['hr_investigation_pdf_url'],
      hrInvestigationPdfUploadedAt: DateTime.tryParse(json['hr_investigation_pdf_uploaded_at'] ?? ''),
      employeeAcknowledgmentDate: DateTime.tryParse(json['employee_acknowledgment_date'] ?? ''),
      employeeAcknowledgmentRemark: json['employee_acknowledgment_remark'],
      employeeAcknowledgmentType: json['employee_acknowledgment_type'],
      autoEscalated: json['auto_escalated'],
      escalatedToLegal: json['escalated_to_legal'],
      legalInvestigationPdfUrl: json['legal_investigation_pdf_url'],
      legalInvestigationPdfUploadedAt: DateTime.tryParse(json['legal_investigation_pdf_uploaded_at'] ?? ''),
      legalApproverCode: json['legal_approver_code'],
      legalEscalationDate: DateTime.tryParse(json['legal_escalation_date'] ?? ''),
      legalEscalationReason: json['legal_escalation_reason'],
      legalCompletionDate: DateTime.tryParse(json['legal_completion_date'] ?? ''),
      hrFinalAction: json['hr_final_action'],
      suspensionDaysField: json['suspension_days'],
      suspensionStartDate: DateTime.tryParse(json['suspension_start_date'] ?? ''),
      suspensionEndDate: DateTime.tryParse(json['suspension_end_date'] ?? ''),
      terminationRecommendedDate: DateTime.tryParse(json['termination_recommended_date'] ?? ''),
      closedAtHR: json['closed_at_hr'],
      legalEnglishName: json['legal_english_name'],
      legalArabicName: json['legal_arabic_name'],
      legalAcknowledged: json['legal_acknowledged'],
      attachments: json['attachments'] != null ? List<String>.from(json['attachments'] as List) : null,
      investigationId: json['investigation_id'],
      sourceType: json['source_type'] ?? 'direct',
      createdFromInvestigation: json['created_from_investigation'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestor_code': requestorCode,
      'employee_code': employeeCode,
      'n2_code': n2Code,
      'violation_category': violationCategory,
      'violation': violation,
      'action_type': actionType?.value,
      'incident_description': incidentDescription,
      'violation_date': violationDate?.toIso8601String(),
      'written_warning_options': writtenWarningOptions?.toJson(),
      if (currentApprover != null) 'current_approver': currentApprover,
      if (status != null) 'status': status,
      if (attachments != null && attachments!.isNotEmpty) 'attachments': attachments,
      if (investigationId != null) 'investigation_id': investigationId,
      if (sourceType != null) 'source_type': sourceType,
      if (createdFromInvestigation != null) 'created_from_investigation': createdFromInvestigation,
    };
  }

  DisciplinaryActionRequestModel copyWith({
    int? id,
    int? requestorCode,
    int? employeeCode,
    int? n2Code,
    String? violationCategory,
    String? violation,
    DisciplinaryActionType? actionType,
    String? incidentDescription,
    DateTime? violationDate,
    WrittenWarningOptions? writtenWarningOptions,
    String? status,
    DateTime? createdAt,
    DateTime? lastActionAt,
    String? currentApprover,
    String? declineReason,
    String? requestType,
    String? pdfUrl,
    DateTime? pdfGeneratedAt,
    String? requestorEnglishName,
    String? requestorArabicName,
    String? employeeEnglishName,
    String? employeeArabicName,
    String? n2EnglishName,
    String? n2ArabicName,
    String? requestorTitle,
    String? requestorEnglishTitle,
    String? requestorDepartment,
    String? requestorEnglishDepartment,
    String? requestorHireDate,
    String? employeeTitle,
    String? employeeEnglishTitle,
    String? employeeDepartment,
    String? employeeEnglishDepartment,
    String? employeeHireDate,
    int? hrApproverCode,
    String? hrEnglishName,
    String? hrArabicName,
    DateTime? n2ApprovalDate,
    DateTime? hrApprovalDate,
    bool? cancelled,
    String? n2ApprovalReason,
    String? hrApprovalReason,
    String? holdReason,
    String? n2InvestigationReason,
    String? comments,
    String? hrInvestigationPdfUrl,
    DateTime? hrInvestigationPdfUploadedAt,
    DateTime? employeeAcknowledgmentDate,
    String? employeeAcknowledgmentRemark,
    String? employeeAcknowledgmentType,
    bool? autoEscalated,
    bool? escalatedToLegal,
    String? legalInvestigationPdfUrl,
    DateTime? legalInvestigationPdfUploadedAt,
    int? legalApproverCode,
    DateTime? legalEscalationDate,
    String? legalEscalationReason,
    DateTime? legalCompletionDate,
    String? hrFinalAction,
    int? suspensionDaysField,
    DateTime? suspensionStartDate,
    DateTime? suspensionEndDate,
    DateTime? terminationRecommendedDate,
    bool? closedAtHR,
    String? legalEnglishName,
    String? legalArabicName,
    bool? legalAcknowledged,
    List<String>? attachments,
    int? investigationId,
    String? sourceType,
    bool? createdFromInvestigation,
  }) {
    return DisciplinaryActionRequestModel(
      id: id ?? this.id,
      requestorCode: requestorCode ?? this.requestorCode,
      employeeCode: employeeCode ?? this.employeeCode,
      n2Code: n2Code ?? this.n2Code,
      violationCategory: violationCategory ?? this.violationCategory,
      violation: violation ?? this.violation,
      actionType: actionType ?? this.actionType,
      incidentDescription: incidentDescription ?? this.incidentDescription,
      violationDate: violationDate ?? this.violationDate,
      writtenWarningOptions: writtenWarningOptions ?? this.writtenWarningOptions,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastActionAt: lastActionAt ?? this.lastActionAt,
      currentApprover: currentApprover ?? this.currentApprover,
      declineReason: declineReason ?? this.declineReason,
      requestType: requestType ?? this.requestType,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfGeneratedAt: pdfGeneratedAt ?? this.pdfGeneratedAt,
      requestorEnglishName: requestorEnglishName ?? this.requestorEnglishName,
      requestorArabicName: requestorArabicName ?? this.requestorArabicName,
      employeeEnglishName: employeeEnglishName ?? this.employeeEnglishName,
      employeeArabicName: employeeArabicName ?? this.employeeArabicName,
      n2EnglishName: n2EnglishName ?? this.n2EnglishName,
      n2ArabicName: n2ArabicName ?? this.n2ArabicName,
      requestorTitle: requestorTitle ?? this.requestorTitle,
      requestorEnglishTitle: requestorEnglishTitle ?? this.requestorEnglishTitle,
      requestorDepartment: requestorDepartment ?? this.requestorDepartment,
      requestorEnglishDepartment: requestorEnglishDepartment ?? this.requestorEnglishDepartment,
      requestorHireDate: requestorHireDate ?? this.requestorHireDate,
      employeeTitle: employeeTitle ?? this.employeeTitle,
      employeeEnglishTitle: employeeEnglishTitle ?? this.employeeEnglishTitle,
      employeeDepartment: employeeDepartment ?? this.employeeDepartment,
      employeeEnglishDepartment: employeeEnglishDepartment ?? this.employeeEnglishDepartment,
      employeeHireDate: employeeHireDate ?? this.employeeHireDate,
      hrApproverCode: hrApproverCode ?? this.hrApproverCode,
      hrEnglishName: hrEnglishName ?? this.hrEnglishName,
      hrArabicName: hrArabicName ?? this.hrArabicName,
      n2ApprovalDate: n2ApprovalDate ?? this.n2ApprovalDate,
      hrApprovalDate: hrApprovalDate ?? this.hrApprovalDate,
      cancelled: cancelled ?? this.cancelled,
      n2ApprovalReason: n2ApprovalReason ?? this.n2ApprovalReason,
      hrApprovalReason: hrApprovalReason ?? this.hrApprovalReason,
      holdReason: holdReason ?? this.holdReason,
      n2InvestigationReason: n2InvestigationReason ?? this.n2InvestigationReason,
      comments: comments ?? this.comments,
      hrInvestigationPdfUrl: hrInvestigationPdfUrl ?? this.hrInvestigationPdfUrl,
      hrInvestigationPdfUploadedAt: hrInvestigationPdfUploadedAt ?? this.hrInvestigationPdfUploadedAt,
      employeeAcknowledgmentDate: employeeAcknowledgmentDate ?? this.employeeAcknowledgmentDate,
      employeeAcknowledgmentRemark: employeeAcknowledgmentRemark ?? this.employeeAcknowledgmentRemark,
      employeeAcknowledgmentType: employeeAcknowledgmentType ?? this.employeeAcknowledgmentType,
      autoEscalated: autoEscalated ?? this.autoEscalated,
      escalatedToLegal: escalatedToLegal ?? this.escalatedToLegal,
      legalInvestigationPdfUrl: legalInvestigationPdfUrl ?? this.legalInvestigationPdfUrl,
      legalInvestigationPdfUploadedAt: legalInvestigationPdfUploadedAt ?? this.legalInvestigationPdfUploadedAt,
      legalApproverCode: legalApproverCode ?? this.legalApproverCode,
      legalEscalationDate: legalEscalationDate ?? this.legalEscalationDate,
      legalEscalationReason: legalEscalationReason ?? this.legalEscalationReason,
      legalCompletionDate: legalCompletionDate ?? this.legalCompletionDate,
      hrFinalAction: hrFinalAction ?? this.hrFinalAction,
      suspensionDaysField: suspensionDaysField ?? this.suspensionDaysField,
      suspensionStartDate: suspensionStartDate ?? this.suspensionStartDate,
      suspensionEndDate: suspensionEndDate ?? this.suspensionEndDate,
      terminationRecommendedDate: terminationRecommendedDate ?? this.terminationRecommendedDate,
      closedAtHR: closedAtHR ?? this.closedAtHR,
      legalEnglishName: legalEnglishName ?? this.legalEnglishName,
      legalArabicName: legalArabicName ?? this.legalArabicName,
      legalAcknowledged: legalAcknowledged ?? this.legalAcknowledged,
      attachments: attachments ?? this.attachments,
      investigationId: investigationId ?? this.investigationId,
      sourceType: sourceType ?? this.sourceType,
      createdFromInvestigation: createdFromInvestigation ?? this.createdFromInvestigation,
    );
  }
}
