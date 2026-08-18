import 'package:equatable/equatable.dart';
import 'package:hrms_demo/data/models/investigation_decision.dart';
import 'package:hrms_demo/data/models/employee_basic_info.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';

/// Model representing an investigation request for multiple employees.
///
/// Investigations can be initiated from scratch or escalated from disciplinary actions.
/// They follow a workflow through HR, optionally Legal, and Top Management for serious cases.
class InvestigationRequestModel extends Equatable {
  // ============== Identity ==============
  /// Unique identifier for the investigation
  final int? id;

  /// Timestamp when the investigation was created
  final DateTime? createdAt;

  /// Timestamp of the last action taken on this investigation
  /// Automatically updated by database trigger when current_approver changes
  final DateTime? lastActionAt;

  // ============== Requestor & Hierarchy ==============
  /// Code of the user who initiated the investigation
  final int? requestorCode;

  /// Array of employee codes being investigated
  final List<int> employeeCodes;

  // ============== Name Enrichment (Runtime Only) ==============
  /// English name of the requestor (fetched from users table at runtime)
  /// This field is populated by the repository enrichment method, not stored in database
  final String? requestorEnglishName;

  /// Arabic name of the requestor (fetched from users table at runtime)
  /// This field is populated by the repository enrichment method, not stored in database
  final String? requestorArabicName;

  /// Employee information map: employee_code -> basic info
  /// Contains names and departments for all employees in this investigation
  /// Populated by repository enrichment, not stored in database
  final Map<int, EmployeeBasicInfo>? employeeInfoMap;

  /// HR personnel English name (fetched from users table at runtime)
  /// Populated by repository enrichment, not stored in database
  final String? hrEnglishName;

  /// HR personnel Arabic name (fetched from users table at runtime)
  /// Populated by repository enrichment, not stored in database
  final String? hrArabicName;

  /// Legal personnel English name (fetched from users table at runtime)
  /// Populated by repository enrichment, not stored in database
  final String? legalEnglishName;

  /// Legal personnel Arabic name (fetched from users table at runtime)
  /// Populated by repository enrichment, not stored in database
  final String? legalArabicName;

  /// Top management English name (fetched from users table at runtime)
  /// Populated by repository enrichment, not stored in database
  final String? topManagementEnglishName;

  /// Top management Arabic name (fetched from users table at runtime)
  /// Populated by repository enrichment, not stored in database
  final String? topManagementArabicName;

  // ============== Investigation Details (SHARED) ==============
  /// Detailed description of the incident being investigated
  final String? incidentDescription;

  /// Date when the violation occurred
  final DateTime? violationDate;

  /// Category of the violation (e.g., "Attendance", "Conduct")
  final String? violationCategory;

  /// Specific violation within the category
  final String? violation;

  // ============== Workflow ==============
  /// Current status of the investigation
  /// Values: 'pending', 'closed', 'cancelled'
  final String? status;

  /// Current approver in the workflow
  /// Values: 'hr', 'legal', 'top_management'
  final String? currentApprover;

  // ============== HR Layer ==============
  /// HR personnel code handling this investigation
  final int? hrCode;

  /// HR decisions for each investigated employee
  /// Format: [{employee_code, decision, disciplinary_id}]
  final List<InvestigationDecision>? hrDecisions;

  /// URL to the HR investigation report PDF
  final String? hrInvestigationPdfUrl;

  /// Timestamp when HR uploaded the investigation PDF
  final DateTime? hrInvestigationPdfUploadedAt;

  // ============== Legal Layer ==============
  /// Legal personnel code if escalated to legal
  final int? legalCode;

  /// Legal decisions for each investigated employee
  /// Format: [{employee_code, decision, disciplinary_id}]
  final List<InvestigationDecision>? legalDecisions;

  /// URL to the legal investigation report PDF
  final String? legalInvestigationPdfUrl;

  /// Timestamp when Legal uploaded the investigation PDF
  final DateTime? legalInvestigationPdfUploadedAt;

  /// Whether this investigation was escalated to legal
  final bool? escalatedToLegal;

  /// Timestamp when the investigation was escalated to legal
  final DateTime? legalEscalationDate;

  /// Reason provided by HR when escalating the investigation to legal
  final String? legalEscalationReason;

  /// Whether legal has acknowledged the investigation
  final bool? legalAcknowledged;

  // ============== Top Management Layer ==============
  /// Top management personnel code (for suspension/termination cases)
  final int? topManagementCode;

  /// Top management decisions for each employee
  /// Format: [{employee_code, decision, disciplinary_id}]
  final List<InvestigationDecision>? topManagementDecisions;

  // ============== Bidirectional Link ==============
  /// Whether this investigation was escalated from a disciplinary action
  final bool? escalatedFromDisciplinary;

  /// ID of the disciplinary action that escalated to this investigation
  final int? escalatedDisciplinaryActionId;

  /// List of attachment file paths in storage
  final List<String>? attachments;

  // ============== Runtime Visibility Flag ==============
  /// Set by the repo when fetching processed investigations.
  /// True when the viewer is N+1 or N+2 of any investigated employee but is NOT the requestor.
  /// This flag overrides group membership — even HR/legal/TM group members are restricted
  /// if they have a direct hierarchical relationship with the investigated employee.
  /// Not stored in the database; not included in fromJson/toJson.
  final bool? viewerIsPassiveObserver;

  const InvestigationRequestModel({
    this.id,
    this.createdAt,
    this.lastActionAt,
    this.requestorCode,
    this.employeeCodes = const [],
    this.requestorEnglishName,
    this.requestorArabicName,
    this.employeeInfoMap,
    this.hrEnglishName,
    this.hrArabicName,
    this.legalEnglishName,
    this.legalArabicName,
    this.topManagementEnglishName,
    this.topManagementArabicName,
    this.incidentDescription,
    this.violationDate,
    this.violationCategory,
    this.violation,
    this.status = 'pending',
    this.currentApprover = 'hr',
    this.hrCode,
    this.hrDecisions,
    this.hrInvestigationPdfUrl,
    this.hrInvestigationPdfUploadedAt,
    this.legalCode,
    this.legalDecisions,
    this.legalInvestigationPdfUrl,
    this.legalInvestigationPdfUploadedAt,
    this.escalatedToLegal = false,
    this.legalEscalationDate,
    this.legalEscalationReason,
    this.legalAcknowledged = false,
    this.topManagementCode,
    this.topManagementDecisions,
    this.escalatedFromDisciplinary = false,
    this.escalatedDisciplinaryActionId,
    this.attachments,
    this.viewerIsPassiveObserver,
  });

  // ============== Computed Properties ==============
  String get requestType => 'investigation';

  /// Whether the investigation is pending
  bool get isPending => status == 'pending';

  /// Whether the investigation is closed
  bool get isClosed => status == 'closed';

  DateTime get tzCreatedAt {
    if (createdAt == null) {
      throw Exception('createdAt is null');
    }
    final location = tz.getLocation('Africa/Cairo');
    return tz.TZDateTime.from(createdAt!, location);
  }

  /// Whether the investigation is cancelled
  bool get isCancelled => status == 'cancelled';

  /// Whether the investigation is currently at HR
  bool get isAtHr => currentApprover == 'hr';

  /// Whether the investigation is currently at Legal
  bool get isAtLegal => currentApprover == 'legal';

  /// Whether the investigation is currently at Top Management
  bool get isAtTopManagement => currentApprover == 'top_management';

  /// Number of employees being investigated
  int get employeeCount => employeeCodes.length;

  /// Whether HR has made decisions
  bool get hasHrDecisions => hrDecisions != null && hrDecisions!.isNotEmpty;

  /// Whether Top Management has made decisions
  bool get hasTopManagementDecisions => topManagementDecisions != null && topManagementDecisions!.isNotEmpty;

  /// Whether this investigation was escalated from a disciplinary action
  bool get wasEscalatedFromDisciplinary => escalatedFromDisciplinary == true;

  /// Whether this investigation is escalated to legal
  bool get isEscalatedToLegal => escalatedToLegal == true;

  /// Whether HR has uploaded an investigation PDF
  bool get hasHrPdf => hrInvestigationPdfUrl != null && hrInvestigationPdfUrl!.isNotEmpty;

  /// Whether Legal has uploaded an investigation PDF
  bool get hasLegalPdf => legalInvestigationPdfUrl != null && legalInvestigationPdfUrl!.isNotEmpty;

  // ============== Name Helper Methods ==============
  /// Gets requestor display name based on locale
  /// Returns Arabic name if isArabic is true, otherwise English name
  /// Falls back to the other language if primary is null
  String getRequestorName(bool isArabic) {
    if (isArabic) {
      return requestorArabicName ?? requestorEnglishName ?? 'Unknown Requestor';
    } else {
      return requestorEnglishName ?? requestorArabicName ?? 'Unknown Requestor';
    }
  }

  /// Gets employee display name by code based on locale
  /// Returns employee name from employeeInfoMap or a fallback with the code
  String getEmployeeName(int employeeCode, bool isArabic) {
    final info = employeeInfoMap?[employeeCode];
    if (info == null) {
      return 'Employee $employeeCode';
    }
    return info.getDisplayName(isArabic);
  }

  /// Gets HR approver display name based on locale
  String getHrName(bool isArabic) {
    final cropedHrArabicName = _cropName(hrArabicName ?? hrEnglishName ?? '', maxLength: 20);
    final cropedHrEnglishName = _cropName(hrEnglishName ?? hrArabicName ?? '', maxLength: 20);
    if (isArabic) {
      return cropedHrArabicName;
    } else {
      return cropedHrEnglishName;
    }
  }

  /// Crops a name to a maximum length and adds ellipsis if it exceeds that length
  String _cropName(String name, {int maxLength = 20}) {
    if (name.length > maxLength) {
      return '${name.substring(0, maxLength)}...';
    }
    return name;
  }

  /// Gets Legal approver display name based on locale
  String getLegalName(bool isArabic) {
    final cropedLegalArabicName = _cropName(legalArabicName ?? legalEnglishName ?? '', maxLength: 20);
    final cropedLegalEnglishName = _cropName(legalEnglishName ?? legalArabicName ?? '', maxLength: 20);

    if (isArabic) {
      return cropedLegalArabicName;
    } else {
      return cropedLegalEnglishName;
    }
  }

  /// Gets Top Management approver display name based on locale
  String getTopManagementName(bool isArabic) {
    final cropedTopManagementArabicName = _cropName(
      topManagementArabicName ?? topManagementEnglishName ?? '',
      maxLength: 20,
    );
    final cropedTopManagementEnglishName = _cropName(
      topManagementEnglishName ?? topManagementArabicName ?? '',
      maxLength: 20,
    );
    if (isArabic) {
      return cropedTopManagementArabicName;
    } else {
      return cropedTopManagementEnglishName;
    }
  }

  String getLocalizedStatus(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (status?.toLowerCase()) {
      case 'closed':
        return l10n.closed;
      case 'cancelled':
        return l10n.cancelledStatus;
      case 'acknowledged':
        return l10n.acknowledged;
      case 'pending':
        return l10n.pending;
      default:
        return status ?? l10n.unknown;
    }
  }

  String getLocalizedCurrentApprover(bool isArabic) {
    switch (currentApprover) {
      case 'legal':
        return isArabic ? 'الشؤون القانونية' : 'Legal';
      case 'hr':
        return isArabic ? 'الموارد البشرية' : 'HR';
      case 'top_management':
        return isArabic ? 'الإدارة العليا' : 'Top Management';
      default:
        return isArabic ? 'غير معروف' : 'Unknown';
    }
  }

  @override
  List<Object?> get props => [
    id,
    createdAt,
    lastActionAt,
    requestorCode,
    employeeCodes,
    requestorEnglishName,
    requestorArabicName,
    employeeInfoMap,
    hrEnglishName,
    hrArabicName,
    legalEnglishName,
    legalArabicName,
    topManagementEnglishName,
    topManagementArabicName,
    incidentDescription,
    violationDate,
    violationCategory,
    violation,
    status,
    currentApprover,
    hrCode,
    hrDecisions,
    hrInvestigationPdfUrl,
    hrInvestigationPdfUploadedAt,
    legalCode,
    legalDecisions,
    legalInvestigationPdfUrl,
    legalInvestigationPdfUploadedAt,
    escalatedToLegal,
    legalEscalationDate,
    legalEscalationReason,
    legalAcknowledged,
    topManagementCode,
    topManagementDecisions,
    escalatedFromDisciplinary,
    escalatedDisciplinaryActionId,
    attachments,
    viewerIsPassiveObserver,
  ];

  /// Creates a copy of this investigation with the given fields replaced
  InvestigationRequestModel copyWith({
    int? id,
    DateTime? createdAt,
    DateTime? lastActionAt,
    int? requestorCode,
    List<int>? employeeCodes,
    String? requestorEnglishName,
    String? requestorArabicName,
    Map<int, EmployeeBasicInfo>? employeeInfoMap,
    String? hrEnglishName,
    String? hrArabicName,
    String? legalEnglishName,
    String? legalArabicName,
    String? topManagementEnglishName,
    String? topManagementArabicName,
    String? incidentDescription,
    DateTime? violationDate,
    String? violationCategory,
    String? violation,
    String? status,
    String? currentApprover,
    int? hrCode,
    List<InvestigationDecision>? hrDecisions,
    String? hrInvestigationPdfUrl,
    DateTime? hrInvestigationPdfUploadedAt,
    int? legalCode,
    List<InvestigationDecision>? legalDecisions,
    String? legalInvestigationPdfUrl,
    DateTime? legalInvestigationPdfUploadedAt,
    bool? escalatedToLegal,
    DateTime? legalEscalationDate,
    String? legalEscalationReason,
    bool? legalAcknowledged,
    int? topManagementCode,
    List<InvestigationDecision>? topManagementDecisions,
    bool? escalatedFromDisciplinary,
    int? escalatedDisciplinaryActionId,
    List<String>? attachments,
    bool? viewerIsPassiveObserver,
  }) {
    return InvestigationRequestModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      lastActionAt: lastActionAt ?? this.lastActionAt,
      requestorCode: requestorCode ?? this.requestorCode,
      employeeCodes: employeeCodes ?? this.employeeCodes,
      requestorEnglishName: requestorEnglishName ?? this.requestorEnglishName,
      requestorArabicName: requestorArabicName ?? this.requestorArabicName,
      employeeInfoMap: employeeInfoMap ?? this.employeeInfoMap,
      hrEnglishName: hrEnglishName ?? this.hrEnglishName,
      hrArabicName: hrArabicName ?? this.hrArabicName,
      legalEnglishName: legalEnglishName ?? this.legalEnglishName,
      legalArabicName: legalArabicName ?? this.legalArabicName,
      topManagementEnglishName: topManagementEnglishName ?? this.topManagementEnglishName,
      topManagementArabicName: topManagementArabicName ?? this.topManagementArabicName,
      incidentDescription: incidentDescription ?? this.incidentDescription,
      violationDate: violationDate ?? this.violationDate,
      violationCategory: violationCategory ?? this.violationCategory,
      violation: violation ?? this.violation,
      status: status ?? this.status,
      currentApprover: currentApprover ?? this.currentApprover,
      hrCode: hrCode ?? this.hrCode,
      hrDecisions: hrDecisions ?? this.hrDecisions,
      hrInvestigationPdfUrl: hrInvestigationPdfUrl ?? this.hrInvestigationPdfUrl,
      hrInvestigationPdfUploadedAt: hrInvestigationPdfUploadedAt ?? this.hrInvestigationPdfUploadedAt,
      legalCode: legalCode ?? this.legalCode,
      legalDecisions: legalDecisions ?? this.legalDecisions,
      legalInvestigationPdfUrl: legalInvestigationPdfUrl ?? this.legalInvestigationPdfUrl,
      legalInvestigationPdfUploadedAt: legalInvestigationPdfUploadedAt ?? this.legalInvestigationPdfUploadedAt,
      escalatedToLegal: escalatedToLegal ?? this.escalatedToLegal,
      legalEscalationDate: legalEscalationDate ?? this.legalEscalationDate,
      legalEscalationReason: legalEscalationReason ?? this.legalEscalationReason,
      legalAcknowledged: legalAcknowledged ?? this.legalAcknowledged,
      topManagementCode: topManagementCode ?? this.topManagementCode,
      topManagementDecisions: topManagementDecisions ?? this.topManagementDecisions,
      escalatedFromDisciplinary: escalatedFromDisciplinary ?? this.escalatedFromDisciplinary,
      escalatedDisciplinaryActionId: escalatedDisciplinaryActionId ?? this.escalatedDisciplinaryActionId,
      attachments: attachments ?? this.attachments,
      viewerIsPassiveObserver: viewerIsPassiveObserver ?? this.viewerIsPassiveObserver,
    );
  }

  /// Converts this investigation to a JSON map for API submission
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (lastActionAt != null) 'last_action_at': lastActionAt!.toIso8601String(),
      if (requestorCode != null) 'requestor_code': requestorCode,
      'employee_codes': employeeCodes,
      if (incidentDescription != null) 'incident_description': incidentDescription,
      if (violationDate != null) 'violation_date': violationDate!.toIso8601String(),
      if (violationCategory != null) 'violation_category': violationCategory,
      if (violation != null) 'violation': violation,
      if (status != null) 'status': status,
      if (currentApprover != null) 'current_approver': currentApprover,
      if (hrCode != null) 'hr_code': hrCode,
      if (hrDecisions != null) 'hr_decisions': hrDecisions!.map((d) => d.toJson()).toList(),
      if (hrInvestigationPdfUrl != null) 'hr_investigation_pdf_url': hrInvestigationPdfUrl,
      if (hrInvestigationPdfUploadedAt != null)
        'hr_investigation_pdf_uploaded_at': hrInvestigationPdfUploadedAt!.toIso8601String(),
      if (legalCode != null) 'legal_code': legalCode,
      if (legalDecisions != null) 'legal_decisions': legalDecisions!.map((d) => d.toJson()).toList(),
      if (legalInvestigationPdfUrl != null) 'legal_investigation_pdf_url': legalInvestigationPdfUrl,
      if (legalInvestigationPdfUploadedAt != null)
        'legal_investigation_pdf_uploaded_at': legalInvestigationPdfUploadedAt!.toIso8601String(),
      if (escalatedToLegal != null) 'escalated_to_legal': escalatedToLegal,
      if (legalEscalationDate != null) 'legal_escalation_date': legalEscalationDate!.toIso8601String(),
      if (legalEscalationReason != null) 'legal_escalation_reason': legalEscalationReason,
      if (legalAcknowledged != null) 'legal_acknowledged': legalAcknowledged,
      if (topManagementCode != null) 'top_management_code': topManagementCode,
      if (topManagementDecisions != null)
        'top_management_decisions': topManagementDecisions!.map((d) => d.toJson()).toList(),
      if (escalatedFromDisciplinary != null) 'escalated_from_disciplinary': escalatedFromDisciplinary,
      if (escalatedDisciplinaryActionId != null) 'escalated_disciplinary_action_id': escalatedDisciplinaryActionId,
      if (attachments != null && attachments!.isNotEmpty) 'attachments': attachments,
    };
  }

  /// Creates an InvestigationRequestModel from a JSON map (database response)
  factory InvestigationRequestModel.fromJson(Map<String, dynamic> json) {
    return InvestigationRequestModel(
      id: json['id'] as int?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      lastActionAt: json['last_action_at'] != null ? DateTime.parse(json['last_action_at'] as String) : null,
      requestorCode: json['requestor_code'] as int?,
      employeeCodes:
          json['employee_codes'] != null
              ? (json['employee_codes'] as List).map((e) => (e as num).toInt()).toList()
              : const [],
      incidentDescription: json['incident_description'] as String?,
      violationDate: json['violation_date'] != null ? DateTime.parse(json['violation_date'] as String) : null,
      violationCategory: json['violation_category'] as String?,
      violation: json['violation'] as String?,
      status: json['status'] as String? ?? 'pending',
      currentApprover: json['current_approver'] as String? ?? 'hr',
      hrCode: json['hr_code'] as int?,
      hrDecisions:
          json['hr_decisions'] != null
              ? (json['hr_decisions'] as List)
                  .map((d) => InvestigationDecision.fromJson(d as Map<String, dynamic>))
                  .toList()
              : null,
      hrInvestigationPdfUrl: json['hr_investigation_pdf_url'] as String?,
      hrInvestigationPdfUploadedAt:
          json['hr_investigation_pdf_uploaded_at'] != null
              ? DateTime.parse(json['hr_investigation_pdf_uploaded_at'] as String)
              : null,
      legalCode: json['legal_code'] as int?,
      legalDecisions:
          json['legal_decisions'] != null
              ? (json['legal_decisions'] as List)
                  .map((d) => InvestigationDecision.fromJson(d as Map<String, dynamic>))
                  .toList()
              : null,
      legalInvestigationPdfUrl: json['legal_investigation_pdf_url'] as String?,
      legalInvestigationPdfUploadedAt:
          json['legal_investigation_pdf_uploaded_at'] != null
              ? DateTime.parse(json['legal_investigation_pdf_uploaded_at'] as String)
              : null,
      escalatedToLegal: json['escalated_to_legal'] as bool? ?? false,
      legalEscalationDate:
          json['legal_escalation_date'] != null ? DateTime.parse(json['legal_escalation_date'] as String) : null,
      legalEscalationReason: json['legal_escalation_reason'] as String?,
      legalAcknowledged: json['legal_acknowledged'] as bool? ?? false,
      topManagementCode: json['top_management_code'] as int?,
      topManagementDecisions:
          json['top_management_decisions'] != null
              ? (json['top_management_decisions'] as List)
                  .map((d) => InvestigationDecision.fromJson(d as Map<String, dynamic>))
                  .toList()
              : null,
      escalatedFromDisciplinary: json['escalated_from_disciplinary'] as bool? ?? false,
      escalatedDisciplinaryActionId: json['escalated_disciplinary_action_id'] as int?,
      attachments: json['attachments'] != null ? List<String>.from(json['attachments'] as List) : null,
      // Parse enriched name fields (added by repository enrichment, not in database)
      requestorEnglishName: json['requestor_english_name'] as String?,
      requestorArabicName: json['requestor_arabic_name'] as String?,
      hrEnglishName: json['hr_english_name'] as String?,
      hrArabicName: json['hr_arabic_name'] as String?,
      legalEnglishName: json['legal_english_name'] as String?,
      legalArabicName: json['legal_arabic_name'] as String?,
      topManagementEnglishName: json['top_management_english_name'] as String?,
      topManagementArabicName: json['top_management_arabic_name'] as String?,
      // Parse employee info map from JSON array (added by repository enrichment)
      employeeInfoMap:
          json['employee_info'] != null
              ? Map<int, EmployeeBasicInfo>.fromEntries(
                (json['employee_info'] as List).map((item) {
                  final info = EmployeeBasicInfo.fromJson(item as Map<String, dynamic>);
                  return MapEntry(info.code, info);
                }),
              )
              : null,
      // Runtime visibility flag stamped by the repo for processed-requests view (not in DB)
      viewerIsPassiveObserver: json['viewer_is_passive_observer'] as bool?,
    );
  }

  @override
  String toString() {
    return 'InvestigationRequestModel(id: $id, requestorCode: $requestorCode, '
        'employeeCount: $employeeCount, status: $status, currentApprover: $currentApprover)';
  }
}
