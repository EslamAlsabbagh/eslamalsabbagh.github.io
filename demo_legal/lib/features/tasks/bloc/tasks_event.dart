part of 'tasks_bloc.dart';

sealed class TasksEvent extends Equatable {
  const TasksEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or reload) tasks, files and topics. Added when the shell opens and on retry.
final class TasksLoadRequested extends TasksEvent {
  const TasksLoadRequested();
}

/// Reload quietly after a change made in the task drawer or the name modal,
/// or one heard from Realtime: the list stays on screen, and a failure keeps
/// it (it is only logged).
final class TasksRefreshRequested extends TasksEvent {
  const TasksRefreshRequested({this.selectFileId});

  /// A file to select once the reload has it (a file just created), so the
  /// chips never point at a file they don't show.
  final String? selectFileId;

  @override
  List<Object?> get props => [selectFileId];
}

/// The date changed (midnight): the header date moves on, and urgency is read
/// again from the database for the new day.
final class TasksDayChanged extends TasksEvent {
  const TasksDayChanged();
}

/// A task was created in [fileId]. Shows it: the tasks tab, the task's file
/// if another file's chip is selected, no search. Then reloads quietly.
final class TasksTaskCreated extends TasksEvent {
  const TasksTaskCreated(this.fileId);

  final String fileId;

  @override
  List<Object?> get props => [fileId];
}

/// A view tab was picked.
final class TasksTabSelected extends TasksEvent {
  const TasksTabSelected(this.tab);

  final TasksTab tab;

  @override
  List<Object?> get props => [tab];
}

/// A file chip was picked; null is «كل الملفات».
final class TasksFileSelected extends TasksEvent {
  const TasksFileSelected(this.fileId);

  final String? fileId;

  @override
  List<Object?> get props => [fileId];
}

/// «عرض / إخفاء المكتملة».
final class TasksClosedToggled extends TasksEvent {
  const TasksClosedToggled();
}

/// The search field changed. The bloc waits for a short pause in typing,
/// then searches once there are at least [TasksState.minSearchLength] letters.
final class TasksSearchChanged extends TasksEvent {
  const TasksSearchChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
