import 'package:equatable/equatable.dart';

import '../data/task_file.dart';
import '../data/task_topic.dart';

/// What the name modal creates or renames (spec §4 "Managing files and topics").
sealed class NameTarget extends Equatable {
  const NameTarget();

  /// The name already saved; empty when creating.
  String get currentName => '';

  /// The file a topic modal belongs to («الملف: …»); null for file modals.
  TaskFile? get parentFile => null;

  bool get isFile;
  bool get isNew;

  /// Whether the modal offers delete: a rename of a file with no topics, or
  /// of a topic with no tasks. The foreign keys still decide on the server.
  bool get canDelete => false;

  @override
  List<Object?> get props => [];
}

final class NewFile extends NameTarget {
  const NewFile();

  @override
  bool get isFile => true;
  @override
  bool get isNew => true;
}

final class RenameFile extends NameTarget {
  const RenameFile(this.file, {this.canDelete = false});

  final TaskFile file;

  @override
  final bool canDelete;

  @override
  String get currentName => file.name;
  @override
  bool get isFile => true;
  @override
  bool get isNew => false;

  @override
  List<Object?> get props => [file, canDelete];
}

final class NewTopic extends NameTarget {
  const NewTopic(this.file);

  final TaskFile file;

  @override
  TaskFile get parentFile => file;
  @override
  bool get isFile => false;
  @override
  bool get isNew => true;

  @override
  List<Object?> get props => [file];
}

final class RenameTopic extends NameTarget {
  const RenameTopic(this.topic, this.file, {this.canDelete = false});

  final TaskTopic topic;
  final TaskFile file;

  @override
  final bool canDelete;

  @override
  String get currentName => topic.name;
  @override
  TaskFile get parentFile => file;
  @override
  bool get isFile => false;
  @override
  bool get isNew => false;

  @override
  List<Object?> get props => [topic, file, canDelete];
}
