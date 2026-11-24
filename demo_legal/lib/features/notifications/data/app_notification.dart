import 'package:equatable/equatable.dart';

import '../../tasks/data/task_activity_entry.dart';

/// What a notification is about. Names match the Postgres
/// `notification_type` enum values (ADR-0008).
enum NotificationType {
  /// A task was created for the viewer, or handed to them.
  assigned,

  /// A status, due date, urgent flag or assignee change on a task the viewer
  /// is assigned to or created.
  taskChanged,

  /// Someone posted an update on such a task.
  updatePosted;

  /// Null for a value this app doesn't know yet (a newer migration), so the
  /// row is skipped instead of breaking the panel.
  static NotificationType? tryFromDb(String value) => switch (value) {
        'assigned' => assigned,
        'task_changed' => taskChanged,
        'update_posted' => updatePosted,
        _ => null,
      };
}

/// One row of the bell's panel. The task itself (title, file, topic) comes
/// from the shell's task list, so it is always the current one and RLS
/// decides whether it is still there.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.taskId,
    required this.actorId,
    required this.actorName,
    required this.createdAt,
    required this.isRead,
    this.activity,
  });

  /// Builds from a row selected with [AppNotification.select]; null for an
  /// unknown type.
  static AppNotification? tryFromRow(Map<String, dynamic> row) {
    final type = NotificationType.tryFromDb(row['type'] as String);
    if (type == null) return null;
    final actor = row['actor'] as Map<String, dynamic>?;
    final activity = row['activity'] as Map<String, dynamic>?;
    return AppNotification(
      id: row['id'] as String,
      type: type,
      taskId: row['task_id'] as String,
      actorId: row['actor_id'] as String?,
      actorName: actor?['display_name'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
      isRead: row['read_at'] != null,
      activity: activity == null ? null : TaskActivityEntry.tryFromRow(activity),
    );
  }

  /// `notifications` has two foreign keys to `profiles` (owner and actor), so
  /// the embed names its column.
  static const String select = 'id, type, task_id, actor_id, read_at, created_at, '
      'actor:profiles!actor_id(display_name), '
      'activity:task_activity!activity_id(${TaskActivityEntry.select})';

  final String id;
  final NotificationType type;
  final String taskId;

  /// Null for a system change (cron, email intake).
  final String? actorId;

  /// Null if RLS hides the actor's profile.
  final String? actorName;
  final DateTime createdAt;
  final bool isRead;

  /// The change behind a [NotificationType.taskChanged] row, with assignee
  /// names filled in, worded like the drawer's history. Null for the other
  /// types, and when the row can't be read or isn't known.
  final TaskActivityEntry? activity;

  AppNotification copyWith({bool? isRead, TaskActivityEntry? activity}) => AppNotification(
        id: id,
        type: type,
        taskId: taskId,
        actorId: actorId,
        actorName: actorName,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        activity: activity ?? this.activity,
      );

  @override
  List<Object?> get props => [id, type, taskId, actorId, actorName, createdAt, isRead, activity];
}
