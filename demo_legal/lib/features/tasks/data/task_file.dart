import 'package:equatable/equatable.dart';

/// A ملف the user can see (RLS: member files for a lawyer, all for others).
class TaskFile extends Equatable {
  const TaskFile({required this.id, required this.name});

  /// Builds from a `files` row selected as `id, name`.
  factory TaskFile.fromRow(Map<String, dynamic> row) =>
      TaskFile(id: row['id'] as String, name: row['name'] as String);

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
