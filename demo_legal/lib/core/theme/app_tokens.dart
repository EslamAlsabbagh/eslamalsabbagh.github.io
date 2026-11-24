import 'package:flutter/material.dart';

import '../domain/task_status.dart';

/// Background / foreground pair used by pills, avatars and status buttons.
@immutable
class ColorPair {
  const ColorPair(this.bg, this.fg);

  final Color bg;
  final Color fg;
}

/// Every color from `docs/design/DESIGN_SPEC.md` §1.
///
/// This is the only file in the app that may contain raw color values.
/// Widgets read colors through `context.tokens` (see `app_theme.dart`).
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens._();

  static const AppTokens light = AppTokens._();

  // Base
  Color get ink => const Color(0xFF16201C);
  Color get bg => const Color(0xFFF3F4F1);
  Color get surface => const Color(0xFFFFFFFF);
  Color get textMuted => const Color(0xFF56605B);
  Color get textSoft => const Color(0xFF4A5450);
  Color get onDarkMuted => const Color(0xFFB7C0BB);

  // Lines and fills
  Color get border => const Color(0xFFDDE1DC);
  Color get borderStrong => const Color(0xFFC9CFCA);
  Color get chipBorder => const Color(0xFFCFD5D0);
  Color get segmentBg => const Color(0xFFE3E6E1);

  /// Drawer header border.
  Color get divider => const Color(0xFFE3E6E2);

  /// Separators between comments.
  Color get dividerSubtle => const Color(0xFFECEEEB);
  Color get subtleFill => const Color(0xFFF0F2EF);
  Color get mutedFill => const Color(0xFFECEEEA);

  /// Text on [mutedFill] (unselected chip count badge).
  Color get onMutedFill => const Color(0xFF3E4642);
  Color get progressTrack => const Color(0xFFE8EBE7);

  // Accents
  Color get accent => const Color(0xFF2F4A9A);
  Color get accentOnDark => const Color(0xFFF3D9A4);

  // Urgency
  Color get urgent => const Color(0xFFC2410C);
  Color get urgentText => const Color(0xFFA8380A);
  Color get urgentRowBg => const Color(0xFFFFF6F0);
  Color get urgentRowBorder => const Color(0xFFEFCBB3);
  Color get overdue => const Color(0xFF8E1B1B);
  Color get overdueRowBg => const Color(0xFFFDF3F2);
  Color get overdueRowBorder => const Color(0xFFEBC2BF);
  Color get urgentPanelBg => const Color(0xFFFBF4EF);
  Color get urgentPanelBorder => const Color(0xFFF0D5C2);
  Color get urgentPanelText => const Color(0xFF6B3A1C);

  // Row variants
  Color get doneRowBg => const Color(0xFFF8F9F7);
  Color get doneRowBorder => const Color(0xFFE1E4E0);
  Color get miniBg => const Color(0xFFF6F7F5);
  Color get miniBorder => const Color(0xFFE3E6E2);

  // Header counters
  Color get statUrgent => const Color(0xFFFFB48A);
  Color get statOverdue => const Color(0xFFFF9B9B);
  Color get statOpen => const Color(0xFFFFFFFF);

  /// Modal / drawer overlay: ink at 42% opacity.
  Color get scrim => const Color(0x6B16201C);

  /// Selected view tab shadow (`0 1px 2px rgba(0,0,0,0.12)`).
  Color get tabShadow => const Color(0x1F000000);

  /// Task drawer shadow (`0 0 40px rgba(0,0,0,0.18)`).
  Color get drawerShadow => const Color(0x2E000000);

  /// Status pill colors, keyed by the DB enum.
  ColorPair status(TaskStatus status) => switch (status) {
        TaskStatus.todo => const ColorPair(Color(0xFFECEEEA), Color(0xFF3E4642)),
        TaskStatus.doing => const ColorPair(Color(0xFFE2E9FA), Color(0xFF23408E)),
        TaskStatus.waiting => const ColorPair(Color(0xFFFAEFD6), Color(0xFF744600)),
        TaskStatus.done => const ColorPair(Color(0xFFDFF1E4), Color(0xFF1E5B33)),
        // Not in the canvas; chosen 2026-10-14 (same values as segmentBg / textSoft).
        TaskStatus.cancelled => const ColorPair(Color(0xFFE3E6E1), Color(0xFF4A5450)),
      };

  /// Fixed avatar palette; pick one per user with [avatarFor].
  List<ColorPair> get avatarPalette => const [
        ColorPair(Color(0xFFDCE4F7), Color(0xFF1F3A80)),
        ColorPair(Color(0xFFF6E2D3), Color(0xFF7A3410)),
        ColorPair(Color(0xFFDDEEE4), Color(0xFF1E5B33)),
        ColorPair(Color(0xFFECE0F3), Color(0xFF5B2A7A)),
      ];

  /// Stable avatar colors for a user id.
  ColorPair avatarFor(String userId) {
    final hash = userId.codeUnits.fold<int>(0, (h, c) => (h * 31 + c) & 0x7fffffff);
    return avatarPalette[hash % avatarPalette.length];
  }

  // There is one fixed theme, so there is nothing to copy or interpolate.
  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(covariant AppTokens? other, double t) => this;
}
