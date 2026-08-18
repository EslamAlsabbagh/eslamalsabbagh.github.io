import 'package:flutter/material.dart';

/// Mobile-specific design tokens for the schedule feature.
/// Extends the desktop [SC] palette with softened shift backgrounds
/// and mobile-first spacing values.
class MT {
  MT._();

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const brand = Color(0xFF2563EB);
  static const brandBg = Color(0xFFEAF1FE);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const text = Color(0xFF1E293B);
  static const text2 = Color(0xFF334155);
  static const text3 = Color(0xFF94A3B8);

  // ── Surface ───────────────────────────────────────────────────────────────
  static const bgPage = Color(0xFFF8FAFC);
  static const bgCard = Colors.white;

  // ── Borders ───────────────────────────────────────────────────────────────
  static const hair = Color(0xFFE2E8F0);
  static const hair2 = Color(0xFFF1F5F9);

  // ── Shift colours (softened for mobile) ───────────────────────────────────
  // Morning
  static const morningBg = Color(0xFFE3F0FE);
  static const morningStripe = Color(0xFF1D6CD9);
  static const morningText = Color(0xFF1D4ED8);

  // Evening
  static const eveningBg = Color(0xFFDCEFE3);
  static const eveningStripe = Color(0xFF0C8A5B);
  static const eveningText = Color(0xFF065F46);

  // Night
  static const nightBg = Color(0xFFECE3F8);
  static const nightStripe = Color(0xFF6B4DBA);
  static const nightText = Color(0xFF5B21B6);

  // Overnight (00:00 – 05:59)
  static const overnightBg = Color(0xFFFFF3E0);
  static const overnightStripe = Color(0xFFF57C00);
  static const overnightText = Color(0xFFBF360C);

  // Leave
  static const leaveBg = Color(0xFFFCE4E4);
  static const leaveStripe = Color(0xFFB54343);
  static const leaveText = Color(0xFF9B1C1C);

  // Off
  static const offBg = Color(0xFFF1F5F9);
  static const offStripe = Color(0xFF64748B);
  static const offText = Color(0xFF475569);

  // ── Status ────────────────────────────────────────────────────────────────
  static const statusOn = Color(0xFF1EB476);
  static const statusOnBg = Color(0xFFDCEFE3);
  static const statusLate = Color(0xFFE35858);
  static const statusLateBg = Color(0xFFFCE4E4);
  static const statusOff = Color(0xFF9AA3AF);
  static const statusOffBg = Color(0xFFEEEFF3);

  // ── Radius ────────────────────────────────────────────────────────────────
  static const r8 = Radius.circular(8);
  static const r12 = Radius.circular(12);
  static const r14 = Radius.circular(14);
  static const r16 = Radius.circular(16);
  static const r24 = Radius.circular(24);

  static BorderRadius get br8 => const BorderRadius.all(r8);
  static BorderRadius get br12 => const BorderRadius.all(r12);
  static BorderRadius get br14 => const BorderRadius.all(r14);
  static BorderRadius get br16 => const BorderRadius.all(r16);
  static BorderRadius get br24 => const BorderRadius.all(r24);

  // ── Spacing ───────────────────────────────────────────────────────────────
  static const pageH = EdgeInsets.symmetric(horizontal: 16);

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns (bg, stripe, text) for a shift kind string.
  static ({Color bg, Color stripe, Color ink}) shiftStyle(String kind) {
    switch (kind) {
      case 'overnight':
        return (bg: overnightBg, stripe: overnightStripe, ink: overnightText);
      case 'morning':
        return (bg: morningBg, stripe: morningStripe, ink: morningText);
      case 'afternoon':
        return (bg: eveningBg, stripe: eveningStripe, ink: eveningText);
      case 'night':
        return (bg: nightBg, stripe: nightStripe, ink: nightText);
      case 'leave':
        return (bg: leaveBg, stripe: leaveStripe, ink: leaveText);
      default:
        return (bg: offBg, stripe: offStripe, ink: offText);
    }
  }

  /// Maps a shift's start hour to a kind string.
  static String kindFromHour(double startHour) {
    if (startHour < 6) return 'overnight';
    if (startHour < 12) return 'morning';
    if (startHour < 18) return 'afternoon';
    return 'night';
  }
}
