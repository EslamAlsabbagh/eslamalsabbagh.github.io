import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// A modal's error: icon and 13 / 600 text in `overdue`, as on the login
/// card. A live region, so a screen reader reads it when it appears.
class FormErrorLine extends StatelessWidget {
  const FormErrorLine(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final color = context.tokens.overdue;
    return Semantics(
      liveRegion: true,
      child: Row(
        spacing: 6,
        children: [
          Icon(Icons.error_outline, size: 18, color: color),
          Expanded(
            child: Text(message, style: AppTextStyles.fieldLabel.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
