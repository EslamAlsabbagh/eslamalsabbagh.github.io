/// Utility class for calculating available months from requests
class RequestMonthUtils {
  /// Calculates available months from a list of dates
  ///
  /// Takes a list of DateTime objects (typically createdAt fields from requests)
  /// and returns a Set of DateTime objects representing year-month combinations.
  /// Each DateTime in the returned Set has day=1 for normalized comparison.
  ///
  /// Null dates are automatically filtered out.
  ///
  /// Example:
  /// ```dart
  /// final availableMonths = RequestMonthUtils.calculateAvailableMonths(
  ///   requests.map((r) => r.createdAt).toList(),
  /// );
  /// ```
  static Set<DateTime> calculateAvailableMonths(List<DateTime?> dates) {
    final months = <DateTime>{};

    for (final date in dates) {
      if (date != null) {
        // Normalize to first day of month for consistent comparison
        final normalizedDate = DateTime(date.year, date.month, 1);
        months.add(normalizedDate);
      }
    }

    return months;
  }

  /// Calculates available months from multiple request lists
  ///
  /// Useful when you have multiple types of requests (e.g., main requests + cancellation requests)
  /// that should all be considered when determining available months.
  ///
  /// Example:
  /// ```dart
  /// final availableMonths = RequestMonthUtils.calculateAvailableMonthsFromMultiple([
  ///   requests.map((r) => r.createdAt).toList(),
  ///   cancellationRequests.map((r) => r.createdAt).toList(),
  /// ]);
  /// ```
  static Set<DateTime> calculateAvailableMonthsFromMultiple(List<List<DateTime?>> dateLists) {
    final months = <DateTime>{};

    for (final dateList in dateLists) {
      months.addAll(calculateAvailableMonths(dateList));
    }

    return months;
  }
}
