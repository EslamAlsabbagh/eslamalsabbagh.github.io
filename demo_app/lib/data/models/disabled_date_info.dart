class DisabledDateInfo {
  final DateTime date;
  final String type; // 'leave', 'business_trip', or 'missing_punch'
  final String? leaveType; // For leave: 'Annual', 'Emergency', 'Sick', 'Compensation', 'Unpaid'
  final String? missingPunchType; // For missing_punch: 'In' or 'Out'
  final int? numberOfHours; // For business_trip: number of hours if partial day

  const DisabledDateInfo({
    required this.date,
    required this.type,
    this.leaveType,
    this.missingPunchType,
    this.numberOfHours,
  });

  /// Whether this business trip is partial-day (has specific hours)
  bool get isPartialDay => numberOfHours != null;

  // Helper method to check if two dates are the same day
  bool isSameDay(DateTime other) {
    return date.year == other.year &&
        date.month == other.month &&
        date.day == other.day;
  }
}
