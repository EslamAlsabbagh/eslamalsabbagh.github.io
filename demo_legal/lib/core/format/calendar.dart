/// The same calendar date one year later, for «تجديد للموسم التالي».
/// 29 February becomes 28 February in a year without one; `DateTime` alone
/// would roll it over to 1 March.
DateTime addYear(DateTime date) {
  final year = date.year + 1;
  final lastDay = DateTime(year, date.month + 1, 0).day;
  return DateTime(year, date.month, date.day > lastDay ? lastDay : date.day);
}
