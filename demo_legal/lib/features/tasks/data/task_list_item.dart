import 'package:equatable/equatable.dart';

import '../../../core/domain/task_status.dart';

/// One row of the tasks view: a `task_list` row with its file, topic,
/// assignee name and update count.
///
/// Urgency fields are computed by the database on the Cairo date
/// (`docs/notes/task-triggers.md`); the app never derives them from the clock.
class TaskListItem extends Equatable {
  const TaskListItem({
    required this.id,
    required this.title,
    required this.status,
    required this.dueDate,
    required this.completedAt,
    required this.isOpen,
    required this.isOverdue,
    required this.isUrgentNow,
    required this.daysUntilDue,
    required this.sortGroup,
    required this.fileId,
    required this.fileName,
    required this.topicId,
    required this.topicName,
    required this.assigneeId,
    required this.assigneeName,
    required this.updateCount,
    this.contractId,
  });

  /// Builds from a row selected with [TaskListItem.select].
  factory TaskListItem.fromRow(Map<String, dynamic> row) {
    final topic = row['topic'] as Map<String, dynamic>;
    final file = topic['file'] as Map<String, dynamic>;
    final assignee = row['assignee'] as Map<String, dynamic>?;
    final updates = row['task_updates'] as List<dynamic>;
    final completedAt = row['completed_at'] as String?;

    return TaskListItem(
      id: row['id'] as String,
      title: row['title'] as String,
      status: TaskStatus.fromDb(row['status'] as String),
      dueDate: DateTime.parse(row['due_date'] as String),
      completedAt: completedAt == null ? null : DateTime.parse(completedAt),
      isOpen: row['is_open'] as bool,
      isOverdue: row['is_overdue'] as bool,
      isUrgentNow: row['is_urgent_now'] as bool,
      daysUntilDue: row['days_until_due'] as int,
      sortGroup: row['sort_group'] as int,
      fileId: row['file_id'] as String,
      fileName: file['name'] as String,
      topicId: row['topic_id'] as String,
      topicName: topic['name'] as String,
      assigneeId: row['assignee_id'] as String,
      assigneeName: assignee?['display_name'] as String?,
      updateCount: updates.isEmpty ? 0 : (updates.first as Map<String, dynamic>)['count'] as int,
      contractId: row['contract_id'] as String?,
    );
  }

  /// PostgREST select for `task_list`. The embeds go through the view's
  /// `topic_id`, `assignee_id` and `id` to the base tables' foreign keys.
  static const String select = 'id, title, status, due_date, completed_at, '
      'is_open, is_overdue, is_urgent_now, days_until_due, sort_group, file_id, topic_id, assignee_id, contract_id, '
      'topic:topics(name, file:files(name)), '
      'assignee:profiles!assignee_id(display_name), '
      'task_updates(count)';

  final String id;
  final String title;
  final TaskStatus status;

  /// A calendar date (no time zone meaning).
  final DateTime dueDate;

  /// Set only on closed tasks.
  final DateTime? completedAt;
  final bool isOpen;
  final bool isOverdue;

  /// Open and (due today or earlier, or manually flagged).
  final bool isUrgentNow;

  /// Due date minus the Cairo date; negative when overdue.
  final int daysUntilDue;

  /// 0 overdue, 1 urgent, 2 upcoming, 3 closed.
  final int sortGroup;
  final String fileId;
  final String fileName;
  final String topicId;
  final String topicName;
  final String assigneeId;

  /// Null if RLS hides the assignee's profile.
  final String? assigneeName;
  final int updateCount;

  /// The contract a follow-up task belongs to (ADR-0013); null otherwise.
  final String? contractId;

  @override
  List<Object?> get props => [
        id,
        title,
        status,
        dueDate,
        completedAt,
        isOpen,
        isOverdue,
        isUrgentNow,
        daysUntilDue,
        sortGroup,
        fileId,
        fileName,
        topicId,
        topicName,
        assigneeId,
        assigneeName,
        updateCount,
        contractId,
      ];
}
