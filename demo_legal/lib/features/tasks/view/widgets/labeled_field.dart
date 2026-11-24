import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// How a [LabeledField]'s label reaches screen readers.
enum FieldLabelSemantics {
  /// On the field itself, so the field is read with its label.
  onField,

  /// As a text of its own, read before a group of buttons or checkboxes.
  group,

  /// Not at all: the field already names itself (the date box's
  /// «اختيار موعد التسليم»), and a second label would be read out of order.
  hidden,
}

/// A 13 / 600 muted label 6px above its field, as in the canvas's forms.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.semantics = FieldLabelSemantics.onField,
  });

  final String label;
  final Widget child;
  final FieldLabelSemantics semantics;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, style: AppTextStyles.fieldLabel.copyWith(color: context.tokens.textMuted));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: switch (semantics) {
        FieldLabelSemantics.onField => [ExcludeSemantics(child: text), Semantics(label: label, child: child)],
        FieldLabelSemantics.group => [text, child],
        FieldLabelSemantics.hidden => [ExcludeSemantics(child: text), child],
      },
    );
  }
}
