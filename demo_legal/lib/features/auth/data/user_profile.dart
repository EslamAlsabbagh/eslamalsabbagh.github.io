import 'package:equatable/equatable.dart';

import '../../../core/domain/user_role.dart';

/// The signed-in user's row in `public.profiles`.
///
/// RLS only shows active profiles, so having one means the account is active.
class UserProfile extends Equatable {
  const UserProfile({required this.id, required this.displayName, required this.role});

  /// Builds from a `profiles` row selected as `id, display_name, role`.
  factory UserProfile.fromRow(Map<String, dynamic> row) => UserProfile(
        id: row['id'] as String,
        displayName: row['display_name'] as String,
        role: UserRole.fromDb(row['role'] as String),
      );

  final String id;
  final String displayName;
  final UserRole role;

  @override
  List<Object?> get props => [id, displayName, role];
}
