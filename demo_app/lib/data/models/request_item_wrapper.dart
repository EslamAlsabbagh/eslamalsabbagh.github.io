import 'package:flutter/material.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'package:hrms_demo/data/models/investigation_request_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';

enum RequestItemType { disciplinaryAction, investigation }

/// Unified wrapper for displaying both disciplinary actions and investigations
/// in the same list with consistent interface
class RequestItem {
  final RequestItemType type;
  final DisciplinaryActionRequestModel? disciplinaryAction;
  final InvestigationRequestModel? investigation;

  const RequestItem._({required this.type, this.disciplinaryAction, this.investigation});

  factory RequestItem.fromDisciplinary(DisciplinaryActionRequestModel action) {
    return RequestItem._(type: RequestItemType.disciplinaryAction, disciplinaryAction: action);
  }

  factory RequestItem.fromInvestigation(InvestigationRequestModel inv) {
    return RequestItem._(type: RequestItemType.investigation, investigation: inv);
  }

  // === Computed Properties for Unified Access ===

  bool get isInvestigation => type == RequestItemType.investigation;
  bool get isDisciplinaryAction => type == RequestItemType.disciplinaryAction;

  int? get id => isInvestigation ? investigation!.id : disciplinaryAction!.id;

  DateTime? get createdAt => isInvestigation ? investigation!.createdAt : disciplinaryAction!.createdAt;

  DateTime get tzCreatedAt => isInvestigation ? investigation!.tzCreatedAt : disciplinaryAction!.tzCreatedAt;

  String? get status => isInvestigation ? investigation!.status : disciplinaryAction!.status;

  int? get requestorCode => isInvestigation ? investigation!.requestorCode : disciplinaryAction!.requestorCode;

  String? get incidentDescription =>
      isInvestigation ? investigation!.incidentDescription : disciplinaryAction!.incidentDescription;

  DateTime? get violationDate => isInvestigation ? investigation!.violationDate : disciplinaryAction!.violationDate;

  String? get violationCategory =>
      isInvestigation ? investigation!.violationCategory : disciplinaryAction!.violationCategory;

  String? get violation => isInvestigation ? investigation!.violation : disciplinaryAction!.violation;

  // === Helper Methods for UI Display ===

  /// Returns employee display text:
  /// - For disciplinary actions: "John Doe (1234)"
  /// - For investigations: "3 employees"
  String getEmployeeDisplay(BuildContext context, bool isArabic) {
    if (isInvestigation) {
      final count = investigation!.employeeCount;
      return '$count ${count == 1 ? AppLocalizations.of(context)!.employee.toLowerCase() : AppLocalizations.of(context)!.employeesWithoutAl.toLowerCase()}';
    } else {
      final name = isArabic ? disciplinaryAction!.employeeArabicName : disciplinaryAction!.employeeEnglishName;
      return '$name (${disciplinaryAction!.employeeCode})';
    }
  }

  /// Returns true if this item should be shown with red styling
  bool shouldUseRedStyling(int currentUserCode) {
    if (isInvestigation) {
      // ALL investigations use red styling (not conditional on viewing user)
      return true;
    } else {
      // Disciplinary actions: only HR Investigation type uses red
      final isHrInvestigation = disciplinaryAction!.actionType == DisciplinaryActionType.hrInvestigation;
      final isEmployeeViewing = currentUserCode == disciplinaryAction!.employeeCode;
      return isHrInvestigation && !isEmployeeViewing;
    }
  }

  /// Returns true if item is actionable (pending, not cancelled)
  bool get isActionable {
    if (isInvestigation) {
      return investigation!.status == 'pending';
    } else {
      return disciplinaryAction!.isActionable;
    }
  }

  /// Returns true if item is cancelled
  bool get isCancelled {
    if (isInvestigation) {
      return investigation!.isCancelled;
    } else {
      return disciplinaryAction!.isCancelled;
    }
  }
}
