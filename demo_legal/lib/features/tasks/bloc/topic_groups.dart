import 'package:equatable/equatable.dart';

import '../../../core/domain/task_status.dart';
import '../data/task_file.dart';
import '../data/task_list_item.dart';
import '../data/task_topic.dart';

/// One topic card in the «المواضيع» view (spec §4 View 2).
final class TopicSummary extends Equatable {
  const TopicSummary({
    required this.topic,
    required this.openTasks,
    required this.doneCount,
    required this.progressTotal,
    required this.taskCount,
  });

  final TaskTopic topic;

  /// In the repository's order: overdue, urgent, then upcoming by due date.
  final List<TaskListItem> openTasks;

  /// Tasks with status `done`.
  final int doneCount;

  /// Every task except the cancelled ones (spec §3: cancelled tasks are left
  /// out of topic progress).
  final int progressTotal;

  /// Every task, cancelled and done included. A topic can be deleted only
  /// at 0 (the `tasks.topic_id` foreign key is `on delete restrict`).
  final int taskCount;

  /// The badge: open tasks that are urgent now (overdue included).
  int get urgentCount => openTasks.where((t) => t.isUrgentNow).length;

  @override
  List<Object?> get props => [topic, openTasks, doneCount, progressTotal, taskCount];
}

/// One file section: its topic cards and the summary line's totals.
final class FileTopics extends Equatable {
  const FileTopics({required this.file, required this.topics});

  final TaskFile file;
  final List<TopicSummary> topics;

  int get openCount => topics.fold(0, (sum, t) => sum + t.openTasks.length);
  int get urgentCount => topics.fold(0, (sum, t) => sum + t.urgentCount);

  @override
  List<Object?> get props => [file, topics];
}

/// Groups [tasks] by topic, and topics by file, in the order of [files] and
/// [topics]. Only [files] get a section, so pass the chip-filtered list.
List<FileTopics> buildTopicGroups({
  required List<TaskFile> files,
  required List<TaskTopic> topics,
  required List<TaskListItem> tasks,
}) {
  final tasksByTopic = <String, List<TaskListItem>>{};
  for (final task in tasks) {
    (tasksByTopic[task.topicId] ??= []).add(task);
  }

  TopicSummary summarize(TaskTopic topic) {
    final all = tasksByTopic[topic.id] ?? const <TaskListItem>[];
    return TopicSummary(
      topic: topic,
      openTasks: all.where((t) => t.isOpen).toList(),
      doneCount: all.where((t) => t.status == TaskStatus.done).length,
      progressTotal: all.where((t) => t.status != TaskStatus.cancelled).length,
      taskCount: all.length,
    );
  }

  return [
    for (final file in files)
      FileTopics(
        file: file,
        topics: [
          for (final topic in topics)
            if (topic.fileId == file.id) summarize(topic),
        ],
      ),
  ];
}
