import 'package:flutter/material.dart';

/// Every color from the design tokens table in `docs/design/README.md`.
///
/// This is the only file in the app that may contain raw color values.
/// Widgets read colors through `context.tokens` (see `app_theme.dart`).
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens._();

  static const AppTokens light = AppTokens._();

  // Base
  Color get bg => const Color(0xFFF3F4F6);
  Color get surface => const Color(0xFFFFFFFF);
  Color get border => const Color(0xFFDDE1E6);

  /// Inset / row background.
  Color get inset => const Color(0xFFF6F7F9);
  Color get text => const Color(0xFF16191D);
  Color get textSecondary => const Color(0xFF5B6470);

  // Primary
  Color get primary => const Color(0xFF1D4ED8);
  Color get primaryTint => const Color(0xFFE8EEFC);
  Color get onPrimaryTint => const Color(0xFF1E3A8A);

  // Status
  Color get successBg => const Color(0xFFE7F5EC);
  Color get successText => const Color(0xFF14532D);
  Color get successDot => const Color(0xFF15803D);
  Color get warningBg => const Color(0xFFFEF3E2);
  Color get warningText => const Color(0xFF7C2D12);
  Color get warningBorder => const Color(0xFFF5C98A);
  Color get dangerBg => const Color(0xFFFDECEC);
  Color get dangerText => const Color(0xFF991B1B);
  Color get dangerAction => const Color(0xFFB91C1C);

  /// An offline gate card's border (`Dashboard.dc.html`).
  Color get dangerBorder => const Color(0xFFF5B5B5);

  /// Light divider between list rows, such as the scan feed's.
  Color get rowDivider => const Color(0xFFEEF0F3);

  // Charts (`Dashboard.dc.html`): bars, and the current hour in [primary].
  Color get chartBar => const Color(0xFF93AEEB);

  // Inputs
  Color get inputBorder => const Color(0xFFC9CED6);

  // Admin side menu
  Color get menuBg => const Color(0xFF16191D);
  Color get menuActive => const Color(0xFF2B3038);
  Color get menuText => const Color(0xFFD5D9DF);

  /// The count on a menu item (`Shifts.dc.html`: shifts to approve).
  Color get menuBadge => const Color(0xFFF59E0B);

  // Actions log (`ActionsLog.dc.html`): a row waiting for review, its flag line.
  Color get reviewRowBg => const Color(0xFFFFFBEB);
  Color get flagText => const Color(0xFF92400E);

  /// Body text a step lighter than [text] (the flag rules box).
  Color get textMuted => const Color(0xFF374151);

  // The admin role's pill on the Users page (`Users.dc.html`; not in the
  // README's table). Cashier uses primaryTint, supervisor the warning pair.
  Color get adminRoleBg => const Color(0xFFF1EAFE);
  Color get adminRoleText => const Color(0xFF4C1D95);

  // One fixed palette: nothing to copy or animate between.
  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(covariant AppTokens? other, double t) => this;
}
