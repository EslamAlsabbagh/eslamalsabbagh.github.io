import 'package:equatable/equatable.dart';

/// One «تحديث» on a task (a `task_updates` row with its author's name).
class TaskUpdateEntry extends Equatable {
  const TaskUpdateEntry({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.body,
    required this.createdAt,
  });

  /// Builds from a row selected with [TaskUpdateEntry.select].
  factory TaskUpdateEntry.fromRow(Map<String, dynamic> row) {
    final author = row['author'] as Map<String, dynamic>?;
    return TaskUpdateEntry(
      id: row['id'] as String,
      authorId: row['author_id'] as String,
      authorName: author?['display_name'] as String?,
      body: row['body'] as String,
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  /// `task_updates` has one foreign key to `profiles`; naming it keeps the
  /// embed unambiguous if another is added.
  static const String select =
      'id, author_id, body, created_at, author:profiles!author_id(display_name)';

  final String id;
  final String authorId;

  /// Null if RLS hides the author's profile.
  final String? authorName;
  final String body;

  /// In the device's time zone.
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, authorId, authorName, body, createdAt];
}
