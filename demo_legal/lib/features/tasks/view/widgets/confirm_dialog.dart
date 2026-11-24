import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// The drawer's "are you sure?" dialog (radius 16): a title, a line of body
/// text, a quiet outline [backLabel] and an `accent` [confirmLabel].
///
/// True only when confirmed; the scrim and Esc count as going back. The
/// buttons are keyed `<keyPrefix>-back` and `<keyPrefix>-confirm`.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String backLabel,
  required String confirmLabel,
  required String keyPrefix,
}) async {
  final tokens = context.tokens;
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: tokens.scrim,
    builder: (context) => AlertDialog(
      backgroundColor: tokens.surface,
      surfaceTintColor: tokens.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.modal)),
      titlePadding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 0),
      contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 10, 20, 0),
      actionsPadding: const EdgeInsetsDirectional.all(20),
      title: Text(title, style: AppTextStyles.sectionTitle.copyWith(color: tokens.ink)),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Text(body, style: AppTextStyles.body.copyWith(color: tokens.ink)),
      ),
      actions: [
        OutlinedButton(
          key: Key('$keyPrefix-back'),
          onPressed: () => Navigator.of(context).pop(false),
          style: quietOutlineButtonStyle(context),
          child: Text(backLabel),
        ),
        FilledButton(
          key: Key('$keyPrefix-confirm'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}

/// The drawer's secondary button: 44 high, `borderStrong` outline, ink text.
ButtonStyle quietOutlineButtonStyle(BuildContext context) {
  final tokens = context.tokens;
  return OutlinedButton.styleFrom(
    foregroundColor: tokens.ink,
    textStyle: AppTextStyles.button,
    minimumSize: const Size(0, AppSpacing.touchTarget),
    padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
    side: BorderSide(color: tokens.borderStrong),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
  );
}
