import 'package:equatable/equatable.dart';

/// What a `task_activity` row records. Names match the Postgres
/// `task_activity_action` enum values.
enum TaskActivityAction {
  created,
  statusChanged,
  assigneeChanged,
  dueDateChanged,
  urgencyChanged,
  titleChanged,
  descriptionChanged,
  topicChanged,

  /// A follow-up's contract link changed (ADR-0013). No screen changes it
  /// yet, so only an API write logs it.
  contractChanged;

  /// Null for a value this app doesn't know yet (a newer migration), so the
  /// row is skipped instead of breaking the drawer.
  static TaskActivityAction? tryFromDb(String value) => switch (value) {
        'created' => created,
        'status_changed' => statusChanged,
        'assignee_changed' => assigneeChanged,
        'due_date_changed' => dueDateChanged,
        'urgency_changed' => urgencyChanged,
        'title_changed' => titleChanged,
        'description_changed' => descriptionChanged,
        'topic_changed' => topicChanged,
        'contract_changed' => contractChanged,
        _ => null,
      };
}

/// One line of a task's change history (a `task_activity` row, written by
/// the triggers; see docs/notes/task-triggers.md).
class TaskActivityEntry extends Equatable {
  const TaskActivityEntry({
    required this.id,
    required this.action,
    required this.actorId,
    required this.actorName,
    required this.oldValue,
    required this.newValue,
    required this.createdAt,
    this.oldName,
    this.newName,
  });

  /// Builds from a row selected with [TaskActivityEntry.select]; null for an
  /// unknown action.
  static TaskActivityEntry? tryFromRow(Map<String, dynamic> row) {
    final action = TaskActivityAction.tryFromDb(row['action'] as String);
    if (action == null) return null;
    final actor = row['actor'] as Map<String, dynamic>?;
    return TaskActivityEntry(
      id: row['id'] as String,
      action: action,
      actorId: row['actor_id'] as String?,
      actorName: actor?['display_name'] as String?,
      oldValue: row['old_value'],
      newValue: row['new_value'],
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  /// `task_activity` has one foreign key to `profiles`; naming it keeps the
  /// embed unambiguous if another is added.
  static const String select =
      'id, actor_id, action, old_value, new_value, created_at, actor:profiles!actor_id(display_name)';

  /// Profile ids stored as values (assignee changes), to look their names up.
  static Set<String> profileIdsIn(Iterable<TaskActivityEntry> entries) =>
      _idsIn(entries, TaskActivityAction.assigneeChanged);

  /// Topic ids stored as values (topic changes), to look their names up.
  static Set<String> topicIdsIn(Iterable<TaskActivityEntry> entries) =>
      _idsIn(entries, TaskActivityAction.topicChanged);

  static Set<String> _idsIn(Iterable<TaskActivityEntry> entries, TaskActivityAction action) => {
        for (final entry in entries)
          if (entry.action == action) ...[?entry.oldValue as String?, ?entry.newValue as String?],
      };

  /// [entries] with [oldName] / [newName] filled from the looked-up names. An
  /// id missing from the maps (RLS hides it) stays null.
  static List<TaskActivityEntry> withNames(
    List<TaskActivityEntry> entries, {
    required Map<String, String> profileNames,
    required Map<String, String> topicNames,
  }) =>
      [
        for (final entry in entries)
          switch (entry.action) {
            TaskActivityAction.assigneeChanged => entry._named(profileNames),
            TaskActivityAction.topicChanged => entry._named(topicNames),
            _ => entry,
          },
      ];

  TaskActivityEntry _named(Map<String, String> names) => TaskActivityEntry(
        id: id,
        action: action,
        actorId: actorId,
        actorName: actorName,
        oldValue: oldValue,
        newValue: newValue,
        createdAt: createdAt,
        oldName: names[oldValue],
        newName: names[newValue],
      );

  final String id;
  final TaskActivityAction action;

  /// Null for a system change (seeds, later cron or email intake).
  final String? actorId;

  /// Null if RLS hides the actor's profile.
  final String? actorName;

  /// The stored jsonb scalars: a status name, a uuid, `yyyy-MM-dd`, a bool or
  /// a title. Null on `created` (and `newValue` is then a snapshot map).
  final Object? oldValue;
  final Object? newValue;

  /// In the device's time zone.
  final DateTime createdAt;

  /// The person or topic behind a uuid value, for assignee and topic changes.
  final String? oldName;
  final String? newName;

  @override
  List<Object?> get props => [id, action, actorId, actorName, oldValue, newValue, createdAt, oldName, newName];
}
