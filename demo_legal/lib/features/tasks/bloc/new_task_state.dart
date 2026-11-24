part of 'new_task_bloc.dart';

enum NewTaskStatus { editing, saving, saved }

/// A contract's follow-up (DESIGN_SPEC §4 "Contract drawer" → «المتابعات»):
/// the file and brand are fixed, the task links to [contractId], and the
/// title starts as [title] (still editable).
final class NewTaskPreset extends Equatable {
  const NewTaskPreset({
    required this.fileId,
    required this.topicId,
    required this.contractId,
    required this.contractLabel,
    this.title = '',
  });

  final String fileId;
  final String topicId;

  /// The main contract (ADR-0013: a follow-up always links to it).
  final String contractId;

  /// The fixed «العقد» line.
  final String contractLabel;
  final String title;

  @override
  List<Object?> get props => [fileId, topicId, contractId, contractLabel, title];
}

/// The modal's picks. Null means nothing to pick (no files, or a file with no
/// topics) or, for the assignee, nobody picked yet.
final class NewTaskDraft extends Equatable {
  const NewTaskDraft({
    required this.fileId,
    required this.topicId,
    required this.assigneeId,
    required this.dueDate,
    this.isManualUrgent = false,
  });

  final String? fileId;
  final String? topicId;
  final String? assigneeId;

  /// A calendar date; defaults to the Cairo «today».
  final DateTime dueDate;
  final bool isManualUrgent;

  NewTaskDraft copyWith({
    String? Function()? fileId,
    String? Function()? topicId,
    String? Function()? assigneeId,
    DateTime? dueDate,
    bool? isManualUrgent,
  }) =>
      NewTaskDraft(
        fileId: fileId != null ? fileId() : this.fileId,
        topicId: topicId != null ? topicId() : this.topicId,
        assigneeId: assigneeId != null ? assigneeId() : this.assigneeId,
        dueDate: dueDate ?? this.dueDate,
        isManualUrgent: isManualUrgent ?? this.isManualUrgent,
      );

  @override
  List<Object?> get props => [fileId, topicId, assigneeId, dueDate, isManualUrgent];
}

final class NewTaskState extends Equatable {
  const NewTaskState({required this.draft, this.status = NewTaskStatus.editing, this.failure, this.savedId});

  final NewTaskDraft draft;
  final NewTaskStatus status;

  /// Why the last save failed; cleared by the next edit or submit.
  final TaskSaveFailure? failure;

  /// The new task's id, once [NewTaskStatus.saved].
  final String? savedId;

  bool get busy => status != NewTaskStatus.editing;

  @override
  List<Object?> get props => [draft, status, failure, savedId];
}
