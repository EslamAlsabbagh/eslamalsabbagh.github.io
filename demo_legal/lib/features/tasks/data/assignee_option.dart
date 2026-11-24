import 'package:equatable/equatable.dart';

import '../../../core/domain/user_role.dart';
import 'team_member.dart';

/// A person in the drawer's «الموظف المسؤول» list.
class AssigneeOption extends Equatable {
  const AssigneeOption({required this.id, required this.name});

  /// Who a manager or admin may pick for a task, in the order of [rows]:
  /// - active lawyers who are members of the task's file
  /// - active managers
  /// - the viewer, if they are an admin (admins assign tasks to themselves,
  ///   not to each other)
  /// - the current assignee, if none of the above (e.g. they have left), so
  ///   the field never shows blank
  ///
  /// This is a UI choice: the database accepts any active manager or admin.
  /// [rows] are `profiles` selected with [AssigneeOption.select], filtered to
  /// the task's file.
  static List<AssigneeOption> pick(
    List<Map<String, dynamic>> rows, {
    required String viewerId,
    required String currentAssigneeId,
    required String? currentAssigneeName,
  }) {
    final options = <AssigneeOption>[];
    for (final row in rows) {
      final id = row['id'] as String;
      final isMember = (row['file_members'] as List<dynamic>).isNotEmpty;
      if (row['is_active'] as bool &&
          _eligible(id: id, role: UserRole.fromDb(row['role'] as String), isMember: isMember, viewerId: viewerId)) {
        options.add(AssigneeOption(id: id, name: row['display_name'] as String));
      }
    }
    if (!options.any((o) => o.id == currentAssigneeId)) {
      options.add(AssigneeOption(id: currentAssigneeId, name: currentAssigneeName));
    }
    return options;
  }

  /// The same rule as [pick], for a new task in [fileId], from the shell's
  /// already loaded [team] (active people only), sorted by name like the
  /// drawer's list. There is no current assignee to keep.
  static List<AssigneeOption> fromTeam(List<TeamMember> team, {required String fileId, required String viewerId}) {
    final options = [
      for (final m in team)
        if (_eligible(id: m.id, role: m.role, isMember: m.fileIds.contains(fileId), viewerId: viewerId))
          AssigneeOption(id: m.id, name: m.name),
    ];
    options.sort((a, b) => a.name!.compareTo(b.name!));
    return options;
  }

  static bool _eligible({
    required String id,
    required UserRole role,
    required bool isMember,
    required String viewerId,
  }) =>
      switch (role) {
        UserRole.lawyer => isMember,
        UserRole.manager => true,
        UserRole.admin => id == viewerId,
      };

  /// Embeds only the memberships in the filtered file, so a lawyer's list is
  /// empty when they aren't a member.
  static const String select = 'id, display_name, role, is_active, file_members(file_id)';

  final String id;

  /// Null only for a current assignee whose profile is hidden.
  final String? name;

  @override
  List<Object?> get props => [id, name];
}
