import 'package:equatable/equatable.dart';

/// A موضوع (tenant brand) in a file the user can see.
class TaskTopic extends Equatable {
  const TaskTopic({required this.id, required this.fileId, required this.name});

  /// Builds from a `topics` row selected as `id, file_id, name`.
  factory TaskTopic.fromRow(Map<String, dynamic> row) => TaskTopic(
        id: row['id'] as String,
        fileId: row['file_id'] as String,
        name: row['name'] as String,
      );

  final String id;
  final String fileId;
  final String name;

  @override
  List<Object?> get props => [id, fileId, name];
}
