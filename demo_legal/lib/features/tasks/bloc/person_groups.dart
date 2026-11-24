import 'package:equatable/equatable.dart';

import '../../../core/domain/user_role.dart';
import '../data/task_list_item.dart';
import '../data/team_member.dart';

/// One person card in the «الموظفون» view (spec §4 View 3).
final class PersonSummary extends Equatable {
  const PersonSummary({required this.id, required this.name, required this.openTasks});

  final String id;

  /// Null when RLS hides the profile (someone who has left).
  final String? name;

  /// In the repository's order: overdue, urgent, then upcoming by due date.
  final List<TaskListItem> openTasks;

  /// The badge: open tasks that are urgent now (overdue included).
  int get urgentCount => openTasks.where((t) => t.isUrgentNow).length;

  @override
  List<Object?> get props => [id, name, openTasks];
}

/// A card per person, in [team] order (oldest account first):
/// - each lawyer who is a member of one of [fileIds], even with nothing open
/// - anyone else with an open task in [tasks], such as a manager
///
/// Then the assignees of open tasks who aren't in [team] (hidden profiles).
/// Pass the chip-scoped [fileIds] and [tasks].
List<PersonSummary> buildPersonGroups({
  required List<TeamMember> team,
  required Set<String> fileIds,
  required List<TaskListItem> tasks,
}) {
  final openByAssignee = <String, List<TaskListItem>>{};
  for (final task in tasks) {
    if (task.isOpen) (openByAssignee[task.assigneeId] ??= []).add(task);
  }

  final groups = <PersonSummary>[];
  for (final member in team) {
    final open = openByAssignee.remove(member.id);
    final isMember = member.role == UserRole.lawyer && member.fileIds.any(fileIds.contains);
    if (open != null || isMember) {
      groups.add(PersonSummary(id: member.id, name: member.name, openTasks: open ?? const []));
    }
  }
  for (final MapEntry(key: id, value: open) in openByAssignee.entries) {
    groups.add(PersonSummary(id: id, name: open.first.assigneeName, openTasks: open));
  }
  return groups;
}
