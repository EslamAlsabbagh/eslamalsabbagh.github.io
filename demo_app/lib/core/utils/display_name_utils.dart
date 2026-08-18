import 'package:flutter/material.dart';

/// Utility class for retrieving localized display names based on current locale.
class DisplayNameUtils {
  /// Returns the appropriate display name based on the current locale.
  /// For Arabic locale, prioritizes Arabic name; for other locales, prioritizes English name.
  static String getDisplayName(
    BuildContext context,
    String? englishName,
    String? arabicName,
  ) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic
        ? (arabicName ?? englishName ?? '')
        : (englishName ?? arabicName ?? '');
  }

  /// Returns true if the current locale is Arabic.
  static bool isArabicLocale(BuildContext context) {
    return Localizations.localeOf(context).languageCode == 'ar';
  }
}
