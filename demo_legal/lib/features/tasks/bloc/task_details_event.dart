part of 'task_details_bloc.dart';

sealed class TaskDetailsEvent extends Equatable {
  const TaskDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Load (or reload) the task, its updates and the assignee list. Added when
/// the drawer opens and on retry.
final class TaskDetailsLoadRequested extends TaskDetailsEvent {
  const TaskDetailsLoadRequested();
}

/// Read the task, its updates, history and assignee options again, quietly:
/// something changed elsewhere (heard from Realtime). Nothing is shown as
/// loading, and a failure keeps what is on screen.
final class TaskDetailsRefreshRequested extends TaskDetailsEvent {
  const TaskDetailsRefreshRequested();
}

/// One of the four status buttons. On a closed task it reopens it.
final class TaskDetailsStatusPicked extends TaskDetailsEvent {
  const TaskDetailsStatusPicked(this.status);

  final TaskStatus status;

  @override
  List<Object?> get props => [status];
}

final class TaskDetailsAssigneePicked extends TaskDetailsEvent {
  const TaskDetailsAssigneePicked(this.assigneeId);

  final String assigneeId;

  @override
  List<Object?> get props => [assigneeId];
}

final class TaskDetailsDuePicked extends TaskDetailsEvent {
  const TaskDetailsDuePicked(this.dueDate);

  /// A calendar date; the time of day is ignored.
  final DateTime dueDate;

  @override
  List<Object?> get props => [dueDate];
}

/// «تعليم كعاجلة يدويًا».
final class TaskDetailsUrgentToggled extends TaskDetailsEvent {
  const TaskDetailsUrgentToggled(this.isManualUrgent);

  final bool isManualUrgent;

  @override
  List<Object?> get props => [isManualUrgent];
}

/// «إلغاء المهمة», after the confirm dialog.
final class TaskDetailsCancelConfirmed extends TaskDetailsEvent {
  const TaskDetailsCancelConfirmed();
}

/// «تعديل»: the title and description turn into fields.
final class TaskDetailsEditStarted extends TaskDetailsEvent {
  const TaskDetailsEditStarted();
}

/// «إلغاء» in the edit form (or a confirmed discard): back to plain text.
final class TaskDetailsEditCancelled extends TaskDetailsEvent {
  const TaskDetailsEditCancelled();
}

/// «إضافة تحديث», with the text as typed (trimmed by the bloc).
final class TaskDetailsUpdatePosted extends TaskDetailsEvent {
  const TaskDetailsUpdatePosted(this.body);

  final String body;

  @override
  List<Object?> get props => [body];
}

/// «حفظ» in the edit form, with the fields as typed (trimmed by the bloc).
final class TaskDetailsTextSaved extends TaskDetailsEvent {
  const TaskDetailsTextSaved({required this.title, required this.description});

  final String title;
  final String description;

  @override
  List<Object?> get props => [title, description];
}
