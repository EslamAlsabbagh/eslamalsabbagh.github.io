import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import 'close_icon_button.dart';

/// The centered form modal, with the canvas's new-task modal values:
/// `min(560, 100%)` wide, `surface`, radius 16, padding 20, 16 between parts.
/// The title row has the ×; the actions sit at the bottom, at the `start`,
/// and an optional [endAction] (the name modal's delete) at the `end`.
///
/// Shown with [showDialog] and `tokens.scrim` behind it; the scrim and Esc
/// close it like the ×, all through `maybePop`.
class FormModal extends StatelessWidget {
  const FormModal({
    super.key,
    required this.title,
    required this.children,
    required this.actions,
    this.endAction,
    this.maxWidth = defaultMaxWidth,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;
  final Widget? endAction;

  /// The contract form is 640 (DESIGN_SPEC §4 "Contract form").
  final double maxWidth;

  static const double defaultMaxWidth = 560;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Dialog(
      backgroundColor: tokens.surface,
      surfaceTintColor: tokens.surface,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.modal)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.modalPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.formGap,
            children: [
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(title, style: AppTextStyles.fileGroupTitle.copyWith(color: tokens.ink)),
                    ),
                  ),
                  CloseIconButton(
                    buttonKey: const Key('modal-close'),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              ...children,
              if (endAction case final endAction?)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Expanded(child: Wrap(spacing: 10, runSpacing: 10, children: actions)),
                    endAction,
                  ],
                )
              else
                Wrap(spacing: 10, runSpacing: 10, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}
