part of 'new_task_bloc.dart';

sealed class NewTaskEvent extends Equatable {
  const NewTaskEvent();

  @override
  List<Object?> get props => [];
}

/// «الملف» changed.
final class NewTaskFileChanged extends NewTaskEvent {
  const NewTaskFileChanged(this.fileId);

  final String fileId;

  @override
  List<Object?> get props => [fileId];
}

/// «الموضوع (البراند)» changed.
final class NewTaskTopicChanged extends NewTaskEvent {
  const NewTaskTopicChanged(this.topicId);

  final String topicId;

  @override
  List<Object?> get props => [topicId];
}

/// A topic was made with «+ موضوع جديد» in the topic select.
final class NewTaskTopicAdded extends NewTaskEvent {
  const NewTaskTopicAdded(this.topic);

  final TaskTopic topic;

  @override
  List<Object?> get props => [topic];
}

/// «الموظف المسؤول» changed (managers and admins).
final class NewTaskAssigneeChanged extends NewTaskEvent {
  const NewTaskAssigneeChanged(this.assigneeId);

  final String assigneeId;

  @override
  List<Object?> get props => [assigneeId];
}

/// «موعد التسليم» picked.
final class NewTaskDueChanged extends NewTaskEvent {
  const NewTaskDueChanged(this.dueDate);

  final DateTime dueDate;

  @override
  List<Object?> get props => [dueDate];
}

/// «عاجلة (تُنجز اليوم)» toggled.
final class NewTaskUrgentChanged extends NewTaskEvent {
  const NewTaskUrgentChanged(this.isManualUrgent);

  final bool isManualUrgent;

  @override
  List<Object?> get props => [isManualUrgent];
}

/// «حفظ المهمة» or Enter in the title, with the fields' text (trimmed by the bloc).
final class NewTaskSubmitted extends NewTaskEvent {
  const NewTaskSubmitted({required this.title, required this.description});

  final String title;
  final String description;

  @override
  List<Object?> get props => [title, description];
}
