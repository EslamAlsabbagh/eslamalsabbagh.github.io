part of 'task_details_bloc.dart';

enum TaskDetailsLoad { loading, success, failure }

final class TaskDetailsState extends Equatable {
  const TaskDetailsState({
    required this.item,
    required this.viewer,
    this.load = TaskDetailsLoad.loading,
    this.details,
    this.updates = const [],
    this.activity = const [],
    this.assignees = const [],
    this.saving = false,
    this.failure,
    this.savedRevision = 0,
    this.editingText = false,
    this.posting = false,
    this.postFailure,
    this.postedRevision = 0,
    this.editBaseTitle = '',
    this.editBaseDescription = '',
  });

  /// The latest known copy: the tapped row until the first load, then the
  /// database's after every load and save.
  final TaskListItem item;
  final UserProfile viewer;
  final TaskDetailsLoad load;

  /// Description and the manual-urgent flag; null until loaded.
  final TaskDetails? details;

  /// Newest first.
  final List<TaskUpdateEntry> updates;

  /// The change history, newest first; read again after every save.
  final List<TaskActivityEntry> activity;

  /// Empty unless the viewer can reassign.
  final List<AssigneeOption> assignees;
  final bool saving;

  /// Why the last change wasn't saved; cleared by the next attempt.
  final TaskSaveFailure? failure;

  /// Goes up after every successful save, so the list behind can refresh.
  final int savedRevision;

  /// The title and description are shown as an edit form. The typed text
  /// lives in the form; it leaves this mode once the save goes through.
  final bool editingText;

  /// An update is being posted. Separate from [saving], so posting and
  /// changing the task don't block each other.
  final bool posting;

  /// Why the last update wasn't posted; cleared by the next attempt.
  final TaskSaveFailure? postFailure;

  /// Goes up after every posted update, so the update box clears.
  final int postedRevision;

  /// The title and description the edit form opened with. A save sends only
  /// what differs from these, not from the latest copy: someone else may
  /// change the task while the form is open, and their text stays.
  final String editBaseTitle;
  final String editBaseDescription;

  /// What RLS allows (ADR-0003): managers and admins edit any task, a lawyer
  /// only the tasks assigned to them. The database enforces it; the drawer
  /// only mirrors it.
  bool get canEdit => viewer.role != UserRole.lawyer || item.assigneeId == viewer.id;

  /// Only managers and admins pick the assignee.
  bool get canReassign => viewer.role != UserRole.lawyer;

  /// Controls are live: loaded, nothing in flight, and allowed.
  bool get canSave => load == TaskDetailsLoad.success && !saving && canEdit;

  /// Anyone who sees a task may post on it (ADR-0003), open or closed, so
  /// this doesn't ask [canEdit].
  bool get canPost => load == TaskDetailsLoad.success && !posting;

  TaskDetailsState copyWith({
    TaskListItem? item,
    TaskDetailsLoad? load,
    TaskDetails? Function()? details,
    List<TaskUpdateEntry>? updates,
    List<TaskActivityEntry>? activity,
    List<AssigneeOption>? assignees,
    bool? saving,
    TaskSaveFailure? Function()? failure,
    int? savedRevision,
    bool? editingText,
    bool? posting,
    TaskSaveFailure? Function()? postFailure,
    int? postedRevision,
    String? editBaseTitle,
    String? editBaseDescription,
  }) =>
      TaskDetailsState(
        item: item ?? this.item,
        viewer: viewer,
        load: load ?? this.load,
        details: details != null ? details() : this.details,
        updates: updates ?? this.updates,
        activity: activity ?? this.activity,
        assignees: assignees ?? this.assignees,
        saving: saving ?? this.saving,
        failure: failure != null ? failure() : this.failure,
        savedRevision: savedRevision ?? this.savedRevision,
        editingText: editingText ?? this.editingText,
        posting: posting ?? this.posting,
        postFailure: postFailure != null ? postFailure() : this.postFailure,
        postedRevision: postedRevision ?? this.postedRevision,
        editBaseTitle: editBaseTitle ?? this.editBaseTitle,
        editBaseDescription: editBaseDescription ?? this.editBaseDescription,
      );

  @override
  List<Object?> get props => [
        item, viewer, load, details, updates, activity, assignees, saving, failure, savedRevision, editingText,
        posting, postFailure, postedRevision, editBaseTitle, editBaseDescription,
      ];
}
