import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Sizes from the design tokens table in `docs/design/README.md`.
abstract final class AppSizes {
  static const fontFamily = 'IBM Plex Sans Arabic';

  /// Minimum touch target everywhere. The sell screen uses larger ones.
  static const touchTarget = 44.0;
  static const inputHeight = 46.0;
  static const inputRadius = 10.0;
  static const cardRadius = 14.0;
}

abstract final class AppTheme {
  static ThemeData light() {
    const t = AppTokens.light;
    final colorScheme = ColorScheme.light(
      primary: t.primary,
      onPrimary: t.surface,
      primaryContainer: t.primaryTint,
      onPrimaryContainer: t.onPrimaryTint,
      error: t.dangerAction,
      onError: t.surface,
      surface: t.surface,
      onSurface: t.text,
      onSurfaceVariant: t.textSecondary,
      outline: t.inputBorder,
      outlineVariant: t.border,
    );

    OutlineInputBorder inputBorder(Color color, {double width = 1}) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
          borderSide: BorderSide(color: color, width: width),
        );

    const buttonMinSize = Size(0, AppSizes.touchTarget);
    final buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.inputRadius));

    return ThemeData(
      useMaterial3: true,
      // Material shrinks controls on desktop (compact density); the design's
      // touch targets must hold on the Windows counters.
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
      fontFamily: AppSizes.fontFamily,
      scaffoldBackgroundColor: t.bg,
      dividerColor: t.border,
      cardTheme: CardThemeData(
        color: t.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          side: BorderSide(color: t.border),
        ),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: t.surface,
        constraints: const BoxConstraints(minHeight: AppSizes.inputHeight),
        contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 12),
        border: inputBorder(t.inputBorder),
        enabledBorder: inputBorder(t.inputBorder),
        focusedBorder: inputBorder(t.primary, width: 2),
        errorBorder: inputBorder(t.dangerAction),
        focusedErrorBorder: inputBorder(t.dangerAction, width: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinSize,
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonMinSize,
          shape: buttonShape,
          foregroundColor: t.text,
          side: BorderSide(color: t.inputBorder),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: buttonMinSize, shape: buttonShape),
      ),
      extensions: const [AppTokens.light],
    );
  }
}

extension AppThemeContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
