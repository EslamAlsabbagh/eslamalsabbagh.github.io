/// Employee type selection for request forms (Advance on Salary, Disciplinary Action)
enum EmployeeTypeSelection {
  /// Direct employees - N+1 = current user (level 1)
  direct,

  /// Indirect employees - N+2 = current user (level 2)
  indirect,

  /// All subordinates at level 3+ (N+3, N+4, ...)
  allSubordinates;
}
