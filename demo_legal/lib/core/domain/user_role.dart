/// User role. Names match the Postgres `user_role` enum values.
enum UserRole {
  lawyer,
  manager,
  admin;

  /// Creates and renames files and topics (RLS `private.is_manager()`:
  /// managers and admins).
  bool get managesFiles => this != lawyer;

  /// Creates accounts and sets roles, files and deactivation
  /// (`private.is_admin()`, ADR-0006).
  bool get managesUsers => this == admin;

  /// Sees only the files they're a member of; the others see every file.
  bool get needsFiles => this == lawyer;

  /// Parses the DB value; throws [ArgumentError] on an unknown name.
  static UserRole fromDb(String value) => UserRole.values.byName(value);
}
