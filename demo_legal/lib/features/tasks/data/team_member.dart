import 'package:equatable/equatable.dart';

import '../../../core/domain/user_role.dart';

/// An active colleague for the «الموظفون» view, with the files they are a
/// member of (only those the viewer may see; RLS filters the embed).
class TeamMember extends Equatable {
  const TeamMember({required this.id, required this.name, required this.role, required this.fileIds});

  /// Builds from a `profiles` row selected with [TeamMember.select].
  factory TeamMember.fromRow(Map<String, dynamic> row) => TeamMember(
        id: row['id'] as String,
        name: row['display_name'] as String,
        role: UserRole.fromDb(row['role'] as String),
        fileIds: {
          for (final m in row['file_members'] as List<dynamic>) (m as Map<String, dynamic>)['file_id'] as String,
        },
      );

  static const String select = 'id, display_name, role, file_members(file_id)';

  final String id;
  final String name;
  final UserRole role;
  final Set<String> fileIds;

  @override
  List<Object?> get props => [id, name, role, fileIds];
}
