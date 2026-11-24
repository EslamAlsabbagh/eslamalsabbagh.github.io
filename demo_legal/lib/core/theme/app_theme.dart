import 'package:flutter/material.dart';

import 'app_dimens.dart';
import 'app_text_styles.dart';
import 'app_tokens.dart';

abstract final class AppTheme {
  static ThemeData light() {
    const t = AppTokens.light;
    final colorScheme = ColorScheme.light(
      primary: t.accent,
      onPrimary: t.surface,
      secondary: t.ink,
      onSecondary: t.bg,
      error: t.overdue,
      onError: t.surface,
      surface: t.surface,
      onSurface: t.ink,
      onSurfaceVariant: t.textMuted,
      outline: t.borderStrong,
      outlineVariant: t.border,
      scrim: t.scrim,
    );

    OutlineInputBorder inputBorder(Color color, {double width = 1}) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.input),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      // Material shrinks buttons by 8px on desktop (compact density). The
      // design's sizes (44 targets, 40 chips/tabs) hold on every platform.
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: t.bg,
      dividerColor: t.divider,
      textTheme: const TextTheme(
        bodyLarge: AppTextStyles.body,
        bodyMedium: AppTextStyles.body,
        bodySmall: AppTextStyles.meta,
        labelLarge: AppTextStyles.button,
        titleLarge: AppTextStyles.sectionTitle,
        titleMedium: AppTextStyles.cardTitle,
      ).apply(bodyColor: t.ink, displayColor: t.ink),
      // Design inputs: min height 44, 12px side padding, 1px borderStrong, radius 10.
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: t.surface,
        // Design inputs stay white on hover (Material would tint them grey).
        hoverColor: t.surface,
        constraints: const BoxConstraints(minHeight: AppSpacing.touchTarget),
        contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 10),
        hintStyle: AppTextStyles.body.copyWith(color: t.textMuted),
        // Same look as the login error row: 13 / 600 in `overdue`.
        errorStyle: AppTextStyles.fieldLabel.copyWith(color: t.overdue),
        border: inputBorder(t.borderStrong),
        enabledBorder: inputBorder(t.borderStrong),
        focusedBorder: inputBorder(t.accent, width: 2),
        errorBorder: inputBorder(t.overdue),
        focusedErrorBorder: inputBorder(t.overdue, width: 2),
      ),
      // Primary action ("حفظ المهمة", «دخول»): accent fill, white text;
      // disabled = the same at 45% opacity, as in the design.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.accent,
          foregroundColor: t.surface,
          disabledBackgroundColor: t.accent.withValues(alpha: 0.45),
          disabledForegroundColor: t.surface,
          minimumSize: const Size(0, AppSpacing.touchTarget),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 22),
          textStyle: AppTextStyles.button,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
        ),
      ),
      extensions: const [AppTokens.light],
    );
  }
}

extension AppThemeContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
