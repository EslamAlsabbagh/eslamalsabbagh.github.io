import 'package:hrms_demo/core/constants/sizes.dart';
import 'package:flutter/material.dart';

extension MaxInputSizeExtension on BuildContext {
  double get maxInputWidth =>
      kMaxInputWidth < MediaQuery.of(this).size.width * 0.8
          ? kMaxInputWidth
          : MediaQuery.of(this).size.width * 0.7;
}

extension ScreenSizeExtension on BuildContext {
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
}

/// Extension for responsive width calculations
extension ResponsiveWidthExtension on BuildContext {
  /// Returns true if screen width is below mobile breakpoint (600px)
  bool get isMobile => screenWidth < 600;

  /// Returns true if screen width is between mobile and desktop (600-1024px)
  bool get isTablet => screenWidth >= 600 && screenWidth < 1024;

  /// Returns true if screen width is above tablet breakpoint (1024px)
  bool get isDesktop => screenWidth >= 1024;

  /// Returns full width for mobile, half width for desktop
  /// Useful for form fields that should be side-by-side on desktop
  double responsiveFieldWidth({double desktopFactor = 0.5}) {
    return isMobile ? maxInputWidth : maxInputWidth * desktopFactor;
  }
}
