import 'package:flutter/material.dart';

/// Centralized design tokens for the app — introduced with the Statistics
/// dashboard because the codebase previously had no `AppColors`/`AppTheme`
/// (theme was inline in `main.dart` and colors were hardcoded ad-hoc).
///
/// The categorical palette, sequential ramp and status colors are the
/// CVD-validated values from the data-viz design system (worst adjacent
/// colorblind ΔE ≈ 24 in light mode, well clear of the ≥12 target). Assign
/// categorical hues in the fixed slot order below — never cycle them.
class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────────────────
  // Mirrors the inline ThemeData seed (Colors.blue) so charts sit in the
  // same visual family as the rest of the app.
  static const Color primary = Color(0xFF2196F3);

  // ── Categorical palette (fixed slot order — never cycle) ─────────────
  // Light-mode steps. Used for generic series (departments, locations …).
  static const Color cat1Blue = Color(0xFF2A78D6);
  static const Color cat2Aqua = Color(0xFF1BAF7A);
  static const Color cat3Yellow = Color(0xFFEDA100);
  static const Color cat4Green = Color(0xFF008300);
  static const Color cat5Violet = Color(0xFF4A3AA7);
  static const Color cat6Red = Color(0xFFE34948);
  static const Color cat7Magenta = Color(0xFFE87BA4);
  static const Color cat8Orange = Color(0xFFEB6834);

  /// The categorical palette in slot order. Index into this for series color;
  /// a 9th series must fold into "Other", never generate a new hue.
  static const List<Color> categorical = [
    cat1Blue,
    cat2Aqua,
    cat3Yellow,
    cat4Green,
    cat5Violet,
    cat6Red,
    cat7Magenta,
    cat8Orange,
  ];

  /// Deterministic color for the Nth series; folds anything past slot 8 into
  /// a neutral "Other" grey so identity stays stable and CVD-safe.
  static Color categoricalAt(int index) =>
      index < categorical.length ? categorical[index] : neutralOther;

  static const Color neutralOther = Color(0xFF898781);

  // ── Request-type identity ────────────────────────────────────────────
  // Keeps the existing dashboard's per-type intent (leave≈blue, trip≈green,
  // advance≈teal/aqua, disciplinary≈red …) but snapped onto validated slots
  // so the stacked/volume charts stay colorblind-safe. `requestType` values
  // match the models' `requestType` string field.
  static const Map<String, Color> requestType = {
    'leave': cat1Blue,
    'leave_cancellation': cat1Blue,
    'business_trip': cat4Green,
    'businesstrip_cancellation': cat4Green,
    'overtime': cat8Orange,
    'missing_punching': cat5Violet,
    'advance_on_salary': cat2Aqua,
    'disciplinary_action': cat6Red,
    'investigation': cat3Yellow,
    'hr_letter': cat7Magenta,
  };

  static Color forRequestType(String? type) =>
      requestType[type?.toLowerCase()] ?? neutralOther;

  // ── Status palette (reserved — never reused as a series color) ───────
  // Canonical (normalized) status → color. Pair with an icon+label in the UI;
  // a status color must never carry meaning by color alone.
  static const Color statusApproved = Color(0xFF0CA30C); // good
  static const Color statusPending = Color(0xFFFAB219); // warning
  static const Color statusOnHold = Color(0xFFEC835A); // serious
  static const Color statusDeclined = Color(0xFFD03B3B); // critical
  static const Color statusCancelled = Color(0xFF898781); // muted/neutral

  static Color forStatus(String? status) {
    switch (status?.toLowerCase().trim()) {
      case 'approved':
      case 'closed':
      case 'completed':
      case 'acknowledged':
        return statusApproved;
      case 'pending':
        return statusPending;
      case 'on_hold':
      case 'converted_to_investigation':
        return statusOnHold;
      case 'declined':
        return statusDeclined;
      case 'cancelled':
        return statusCancelled;
      default:
        return neutralOther;
    }
  }

  // ── Sequential ramp (single hue, light→dark) for the heatmap ─────────
  // Continuous magnitude: lightest ≈ near-zero (recedes toward surface).
  static const List<Color> sequentialBlue = [
    Color(0xFFCDE2FB), // 100
    Color(0xFF9EC5F4), // 200
    Color(0xFF6DA7EC), // 300
    Color(0xFF3987E5), // 400
    Color(0xFF256ABF), // 500
    Color(0xFF184F95), // 600
    Color(0xFF0D366B), // 700
  ];

  /// Maps a 0..1 magnitude onto the sequential ramp for heatmap cells.
  static Color sequentialFor(double t) {
    if (t <= 0) return const Color(0xFFEFF5FE); // near-empty, barely tinted
    final clamped = t.clamp(0.0, 1.0);
    final idx = (clamped * (sequentialBlue.length - 1)).round();
    return sequentialBlue[idx];
  }

  // ── Chart chrome & ink (light surface — the app renders light) ───────
  static const Color surface = Color(0xFFFFFFFF); // matches FormContainer card
  static const Color pagePlane = Color(0xFFF9F9F7);
  static const Color inkPrimary = Color(0xFF0B0B0B);
  static const Color inkSecondary = Color(0xFF52514E);
  static const Color inkMuted = Color(0xFF898781); // axis/labels
  static const Color gridline = Color(0xFFE1E0D9);
  static const Color baseline = Color(0xFFC3C2B7);
  static const Color deltaGood = Color(0xFF006300);
  static const Color deltaBad = Color(0xFFD03B3B);
}
