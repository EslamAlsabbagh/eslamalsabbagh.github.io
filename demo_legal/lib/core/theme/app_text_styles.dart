import 'package:flutter/painting.dart';

/// Bundled font families (see `pubspec.yaml` and `assets/fonts/`).
abstract final class AppFonts {
  /// Body text.
  static const String body = 'IBM Plex Sans Arabic';

  /// Headings and numbers.
  static const String display = 'Readex Pro';
}

/// Typography roles from `docs/design/DESIGN_SPEC.md` §1 "Typography".
///
/// Styles carry no color; widgets apply one from `context.tokens`.
abstract final class AppTextStyles {
  static const double _bodyHeight = 1.55;

  static const TextStyle appTitle = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: _bodyHeight,
  );

  static const TextStyle headerStat = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.1,
  );

  static const TextStyle drawerTitle = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: _bodyHeight,
  );

  static const TextStyle fileGroupTitle = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: _bodyHeight,
  );

  static const TextStyle cardTitle = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: _bodyHeight,
  );

  static const TextStyle taskTitle = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: _bodyHeight,
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: _bodyHeight,
  );

  static const TextStyle button = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: _bodyHeight,
  );

  static const TextStyle meta = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: _bodyHeight,
  );

  /// Form field labels (13 / 600, from the design's `<label>` elements).
  static const TextStyle fieldLabel = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: _bodyHeight,
  );

  static const TextStyle badge = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: _bodyHeight,
  );
}
