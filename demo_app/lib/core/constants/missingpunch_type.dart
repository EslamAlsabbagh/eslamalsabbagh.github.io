import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

enum MissingPunchType {
  inType(label: 'In'),
  outType(label: 'Out');

  const MissingPunchType({required this.label});

  final String label;

  String localizedLabel(BuildContext context) {
    switch (this) {
      case MissingPunchType.inType:
        return AppLocalizations.of(context)!.inType;

      case MissingPunchType.outType:
        return AppLocalizations.of(context)!.outType;
    }
  }
}
