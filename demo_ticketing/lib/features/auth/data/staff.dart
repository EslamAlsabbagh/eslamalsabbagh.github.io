import 'package:equatable/equatable.dart';

/// `public.staff_role`.
enum StaffRole {
  cashier,
  supervisor,
  admin;

  /// Supervisors and admins land on the admin area; they can still sell.
  bool get seesAdmin => this != cashier;

  static StaffRole fromName(String name) => values.byName(name);
}

/// The logged-in staff member, from their own `staff` row (RLS lets active
/// staff read it).
class Staff extends Equatable {
  const Staff({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    required this.language,
  });

  final String id;
  final String fullName;
  final String username;
  final StaffRole role;

  /// The language in effect: `staff.language`, or `settings.default_language`
  /// when that is null.
  final String language;

  factory Staff.fromRow(Map<String, dynamic> row, {required String defaultLanguage}) => Staff(
        id: row['id'] as String,
        fullName: row['full_name'] as String,
        username: row['username'] as String,
        role: StaffRole.fromName(row['role'] as String),
        language: (row['language'] as String?) ?? defaultLanguage,
      );

  /// What [fromRow] reads back: the copy for a start with the server down.
  Map<String, Object> toRow({String? language}) => {
        'id': id,
        'full_name': fullName,
        'username': username,
        'role': role.name,
        'language': language ?? this.language,
      };

  @override
  List<Object?> get props => [id, fullName, username, role, language];
}
