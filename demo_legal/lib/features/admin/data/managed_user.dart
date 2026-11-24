import 'package:equatable/equatable.dart';

import '../../../core/domain/user_role.dart';

/// One account on the admin users page: its profile, its file memberships,
/// and its login email (from `public.user_emails()`, admins only).
class ManagedUser extends Equatable {
  const ManagedUser({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.isActive,
    required this.fileIds,
  });

  /// The `profiles` columns, with the memberships embedded.
  static const select = 'id, display_name, role, is_active, file_members(file_id)';

  /// Builds from a `profiles` row selected as [select], with [email] looked
  /// up separately (null if `auth.users` has no row, which shouldn't happen).
  factory ManagedUser.fromRow(Map<String, dynamic> row, {required String? email}) => ManagedUser(
    id: row['id'] as String,
    displayName: row['display_name'] as String,
    email: email,
    role: UserRole.fromDb(row['role'] as String),
    isActive: row['is_active'] as bool,
    fileIds: {
      for (final member in (row['file_members'] as List<dynamic>? ?? const []))
        (member as Map<String, dynamic>)['file_id'] as String,
    },
  );

  final String id;
  final String displayName;
  final String? email;
  final UserRole role;
  final bool isActive;

  /// The files this user is a member of. Only a lawyer's decide what they see.
  final Set<String> fileIds;

  @override
  List<Object?> get props => [id, displayName, email, role, isActive, fileIds];
}
