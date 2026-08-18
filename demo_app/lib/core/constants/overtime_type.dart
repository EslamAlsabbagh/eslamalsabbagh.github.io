import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

enum OvertimeType {
  holidays(label: "Holidays"),
  other(label: "Other");

  final String label;

  const OvertimeType({required this.label});

  String localizedLabel(BuildContext context) {
    switch (this) {
      case OvertimeType.holidays:
        return AppLocalizations.of(context)!.holidays;
      case OvertimeType.other:
        return AppLocalizations.of(context)!.other;
    }
  }
}