import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum LeaveType {
  annual(label: 'Annual'),
  emergency(label: 'Emergency'),
  compensation(label: 'Compensation'),
  sick(label: 'Sick'),
  unpaid(label: 'Unpaid');

  const LeaveType({required this.label});

  final String label;

   String localizedLabel(BuildContext context) { 
    switch (this) {
      case LeaveType.annual:
        return AppLocalizations.of(context)!.annual;
      case LeaveType.emergency:
        return AppLocalizations.of(context)!.emergency;
      case LeaveType.compensation:
        return AppLocalizations.of(context)!.compensation;
      case LeaveType.sick:
        return AppLocalizations.of(context)!.sick;
      case LeaveType.unpaid:
        return AppLocalizations.of(context)!.unpaid;
    }
  }
}
