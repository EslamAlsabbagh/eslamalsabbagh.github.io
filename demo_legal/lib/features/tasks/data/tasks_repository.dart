import '../../../core/domain/task_status.dart';
import '../../../core/domain/user_role.dart';
import '../../../demo/demo_store.dart';
import 'activity_names.dart';
import 'assignee_option.dart';
import 'live_changes.dart';
import 'name_save_failure.dart';
import 'task_activity_entry.dart';
import 'task_details.dart';
import 'task_file.dart';
import 'task_list_item.dart';
import 'task_save_failure.dart';
import 'task_topic.dart';
import 'task_update_entry.dart';
import 'team_member.dart';

/// Reads, creates and edits tasks, reads their history, posts their updates,
/// and creates and renames files and topics.
///
/// Demo build: reads and writes [DemoStore]. The rules production keeps in
/// Row Level Security and triggers are re-stated here: a lawyer sees only
/// their member files and edits only their own tasks, every change writes
/// the history and the notifications, and urgency is computed on today's
/// date rather than by the app's widgets.
class TasksRepository {
  TasksRepository(this._store);

  final DemoStore _store;

  /// Every visible task, open ones in display order (overdue, urgent,
  /// upcoming; then by due date). Closed tasks come last.
  Future<List<TaskListItem>> fetchTasks() async {
    await _store.latency();
    final viewer = _store.requireViewer();
    final items = [
      for (final t in _store.tasks)
        if (_store.canSeeTask(viewer, t)) _item(t),
    ];
    final open = items.where((i) => i.isOpen).toList()
      ..sort((a, b) {
        final byGroup = a.sortGroup.compareTo(b.sortGroup);
        if (byGroup != 0) return byGroup;
        final byDue = a.dueDate.compareTo(b.dueDate);
        return byDue != 0 ? byDue : a.id.compareTo(b.id);
      });
    final closed = items.where((i) => !i.isOpen).toList()
      ..sort((a, b) => (b.completedAt ?? b.dueDate).compareTo(a.completedAt ?? a.dueDate));
    return [...open, ...closed];
  }

  /// Files for the filter chips, oldest first.
  Future<List<TaskFile>> fetchFiles() async {
    final viewer = _store.requireViewer();
    final visible = _store.visibleFileIds(viewer);
    return [
      for (final f in _store.files)
        if (visible.contains(f.id)) TaskFile(id: f.id, name: f.name),
    ];
  }

  /// Topics for the «المواضيع» view, including those with no tasks yet.
  Future<List<TaskTopic>> fetchTopics() async {
    final viewer = _store.requireViewer();
    final visible = _store.visibleFileIds(viewer);
    return [
      for (final t in _store.topics)
        if (visible.contains(t.fileId)) TaskTopic(id: t.id, fileId: t.fileId, name: t.name),
    ];
  }

  /// Active people for the «الموظفون» view. A lawyer sees only the
  /// memberships in their own files.
  Future<List<TeamMember>> fetchTeam() async {
    final viewer = _store.requireViewer();
    final visible = _store.visibleFileIds(viewer);
    return [
      for (final p in _store.profiles)
        if (p.isActive)
          TeamMember(id: p.id, name: p.displayName, role: p.role, fileIds: p.fileIds.intersection(visible)),
    ];
  }

  /// Ids of the visible tasks whose title, topic or file name contain every
  /// word of [query], compared with Arabic normalization.
  Future<Set<String>> searchTaskIds(String query) async {
    await _store.latency();
    final viewer = _store.requireViewer();
    return {
      for (final t in _store.tasks)
        if (_store.canSeeTask(viewer, t) &&
            DemoStore.matchesAll(query, [
              t.title,
              _store.topic(t.topicId)?.name,
              _store.file(_store.fileIdOfTask(t))?.name,
            ]))
          t.id,
    };
  }

  /// One task for the drawer.
  Future<TaskDetails> fetchTask(String id) async {
    await _store.latency();
    final viewer = _store.requireViewer();
    final t = _store.task(id);
    if (t == null || !_store.canSeeTask(viewer, t)) throw StateError('task $id not found');
    final contract = _store.contract(t.contractId);
    return TaskDetails(
      item: _item(t),
      description: t.description,
      isManualUrgent: t.isUrgent,
      contract: contract == null || !_store.canSeeContract(viewer, contract)
          ? null
          : (kind: contract.kind, subject: contract.subject),
    );
  }

  /// A task's updates, newest first.
  Future<List<TaskUpdateEntry>> fetchUpdates(String taskId) async {
    final rows = _store.updates.where((u) => u.taskId == taskId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return [
      for (final u in rows)
        TaskUpdateEntry(
          id: u.id,
          authorId: u.authorId,
          authorName: _store.profile(u.authorId)?.displayName,
          body: u.body,
          createdAt: u.createdAt,
        ),
    ];
  }

  /// A task's change history, newest first, with people and topics named.
  Future<List<TaskActivityEntry>> fetchActivity(String taskId) async {
    final rows = _store.taskActivity.where((a) => a.taskId == taskId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return nameActivityEntries(_store, [for (final row in rows) ?activityEntry(_store, row)]);
  }

  /// Posts an update on a task. Anyone who can see the task may post.
  ///
  /// Throws [TaskSaveException], like [updateTask].
  Future<void> addUpdate(String taskId, String body) async {
    await _store.latency();
    final viewer = _store.requireViewer();
    final t = _store.task(taskId);
    if (t == null || !_store.canSeeTask(viewer, t)) throw const TaskSaveException(TaskSaveFailure.notAllowed);
    final update = DemoUpdate(id: _store.id('u'), taskId: taskId, authorId: viewer.id, body: body, createdAt: _store.now);
    _store.updates.add(update);
    _store.notify(t, type: 'update_posted', actorId: viewer.id, recipients: [t.assigneeId, t.createdBy]);
    _store.changed(LiveTable.taskUpdates, taskId: taskId);
  }

  /// Who [viewerId] may assign a task in [fileId] to (see [AssigneeOption.pick]).
  Future<List<AssigneeOption>> fetchAssigneeOptions({
    required String fileId,
    required String viewerId,
    required String currentAssigneeId,
    required String? currentAssigneeName,
  }) async {
    final people = [for (final p in _store.profiles) if (p.isActive) p]
      ..sort((a, b) => a.displayName.compareTo(b.displayName));
    final rows = [
      for (final p in people)
        <String, dynamic>{
          'id': p.id,
          'display_name': p.displayName,
          'role': p.role.name,
          'is_active': p.isActive,
          'file_members': [
            if (p.fileIds.contains(fileId)) {'file_id': fileId},
          ],
        },
    ];
    return AssigneeOption.pick(
      rows,
      viewerId: viewerId,
      currentAssigneeId: currentAssigneeId,
      currentAssigneeName: currentAssigneeName,
    );
  }

  /// Saves the given fields of a task; null fields are left alone.
  ///
  /// Throws [TaskSaveException]: [TaskSaveFailure.notAllowed] for a task the
  /// viewer may not edit, [TaskSaveFailure.assigneeRejected] for an inactive
  /// assignee or a lawyer outside the task's file.
  Future<void> updateTask(
    String id, {
    TaskStatus? status,
    String? assigneeId,
    DateTime? dueDate,
    bool? isManualUrgent,
    String? title,
    String? description,
  }) async {
    await _store.latency();
    final viewer = _store.requireViewer();
    final t = _store.task(id);
    if (t == null || !_canEdit(viewer, t)) throw const TaskSaveException(TaskSaveFailure.notAllowed);
    if (assigneeId != null && assigneeId != t.assigneeId) {
      // A lawyer's tasks stay their own (RLS with check).
      if (viewer.role == UserRole.lawyer) throw const TaskSaveException(TaskSaveFailure.notAllowed);
      _guardAssignee(assigneeId, _store.fileIdOfTask(t));
    }

    void log(String action, Object? oldValue, Object? newValue) =>
        _store.logTask(t, action, actorId: viewer.id, oldValue: oldValue, newValue: newValue);

    if (status != null && status != t.status) {
      final old = t.status;
      t.status = status;
      t.completedAt = status.isClosed ? _store.now : null;
      log('status_changed', old.name, status.name);
    }
    if (assigneeId != null && assigneeId != t.assigneeId) {
      final old = t.assigneeId;
      t.assigneeId = assigneeId;
      log('assignee_changed', old, assigneeId);
    }
    if (dueDate != null && DemoStore.dateOnly(dueDate) != t.dueDate) {
      final old = t.dueDate;
      t.dueDate = DemoStore.dateOnly(dueDate);
      log('due_date_changed', DemoStore.ymd(old), DemoStore.ymd(t.dueDate));
    }
    if (isManualUrgent != null && isManualUrgent != t.isUrgent) {
      final old = t.isUrgent;
      t.isUrgent = isManualUrgent;
      log('urgency_changed', old, isManualUrgent);
    }
    if (title != null && title != t.title) {
      final old = t.title;
      t.title = title;
      log('title_changed', old, title);
    }
    if (description != null && description != t.description) {
      final old = t.description;
      t.description = description;
      log('description_changed', old, description);
    }
    _store.changed(LiveTable.tasks, taskId: t.id);
  }

  /// Creates a task and returns its id. A lawyer may create only a task
  /// assigned to themselves, in their own files.
  ///
  /// Throws [TaskSaveException], like [updateTask].
  Future<String> createTask({
    required String topicId,
    required String title,
    required String description,
    required String assigneeId,
    required DateTime dueDate,
    required bool isManualUrgent,
    String? contractId,
  }) async {
    await _store.latency();
    final viewer = _store.requireViewer();
    final topic = _store.topic(topicId);
    if (topic == null || !_store.visibleFileIds(viewer).contains(topic.fileId)) {
      throw const TaskSaveException(TaskSaveFailure.notAllowed);
    }
    if (viewer.role == UserRole.lawyer && assigneeId != viewer.id) {
      throw const TaskSaveException(TaskSaveFailure.notAllowed);
    }
    _guardAssignee(assigneeId, topic.fileId);
    // A follow-up stays under its contract's brand (`tasks_contract_topic`).
    final contract = _store.contract(contractId);
    final t = DemoTask(
      id: _store.id('t'),
      topicId: contract?.topicId ?? topicId,
      title: title,
      description: description,
      assigneeId: assigneeId,
      createdBy: viewer.id,
      status: TaskStatus.todo,
      isUrgent: isManualUrgent,
      dueDate: DemoStore.dateOnly(dueDate),
      createdAt: _store.now,
      contractId: contractId,
    );
    _store.tasks.add(t);
    _store.logTask(t, 'created', actorId: viewer.id, newValue: _snapshot(t));
    _store.changed(LiveTable.tasks, taskId: t.id);
    if (contract != null) _store.changed(LiveTable.contracts);
    return t.id;
  }

  /// Creates a ملف and returns its id. Managers and admins only.
  Future<String> createFile(String name) async {
    await _store.latency();
    _requireManager();
    _guardUniqueName(name, _store.files.map((f) => (f.id, f.name)));
    final f = DemoFile(id: _store.id('f'), name: name.trim(), createdAt: _store.now);
    _store.files.add(f);
    _store.changed(LiveTable.files);
    return f.id;
  }

  /// Renames a ملف.
  Future<void> renameFile(String id, String name) async {
    await _store.latency();
    _requireManager();
    final f = _store.file(id);
    if (f == null) throw const NameSaveException(NameSaveFailure.notAllowed);
    _guardUniqueName(name, _store.files.map((x) => (x.id, x.name)), except: id);
    f.name = name.trim();
    _store.changed(LiveTable.files);
  }

  /// Creates a موضوع in [fileId] and returns its id.
  Future<String> createTopic(String fileId, String name) async {
    await _store.latency();
    _requireTopicEditor(fileId);
    _guardUniqueName(name, [for (final t in _store.topics) if (t.fileId == fileId) (t.id, t.name)]);
    final t = DemoTopic(id: _store.id('tp'), fileId: fileId, name: name.trim(), createdAt: _store.now);
    _store.topics.add(t);
    _store.changed(LiveTable.topics);
    return t.id;
  }

  /// Renames a موضوع.
  Future<void> renameTopic(String id, String name) async {
    await _store.latency();
    final t = _store.topic(id);
    if (t == null) throw const NameSaveException(NameSaveFailure.notAllowed);
    _requireTopicEditor(t.fileId);
    _guardUniqueName(name, [for (final x in _store.topics) if (x.fileId == t.fileId) (x.id, x.name)], except: id);
    t.name = name.trim();
    _store.changed(LiveTable.topics);
  }

  /// Deletes a ملف with no topics (managers and admins).
  Future<void> deleteFile(String id) async {
    await _store.latency();
    _requireManager();
    if (_store.topics.any((t) => t.fileId == id) || _store.contracts.any((c) => c.fileId == id)) {
      throw const NameSaveException(NameSaveFailure.notEmpty);
    }
    _store.files.removeWhere((f) => f.id == id);
    for (final p in _store.profiles) {
      p.fileIds.remove(id);
    }
    _store.changed(LiveTable.files);
  }

  /// Deletes a موضوع with no tasks, cancelled and done ones included.
  Future<void> deleteTopic(String id) async {
    await _store.latency();
    final t = _store.topic(id);
    if (t == null) throw const NameSaveException(NameSaveFailure.notAllowed);
    _requireTopicEditor(t.fileId);
    if (_store.tasks.any((k) => k.topicId == id) || _store.contracts.any((c) => c.topicId == id)) {
      throw const NameSaveException(NameSaveFailure.notEmpty);
    }
    _store.topics.removeWhere((x) => x.id == id);
    _store.changed(LiveTable.topics);
  }

  // ── Rules ───────────────────────────────────────────────────────────────────

  TaskListItem _item(DemoTask t) => taskListItem(_store, t);

  /// Lawyers edit only tasks assigned to them; managers and admins any.
  bool _canEdit(DemoProfile viewer, DemoTask t) =>
      _store.canSeeTask(viewer, t) && (viewer.role != UserRole.lawyer || t.assigneeId == viewer.id);

  /// `guard_task_assignee`: an active person, and a lawyer only in their files.
  void _guardAssignee(String assigneeId, String fileId) {
    final person = _store.profile(assigneeId);
    final ok = person != null &&
        person.isActive &&
        (person.role != UserRole.lawyer || person.fileIds.contains(fileId));
    if (!ok) throw const TaskSaveException(TaskSaveFailure.assigneeRejected);
  }

  DemoProfile _requireManager() {
    final viewer = _store.requireViewer();
    if (viewer.role == UserRole.lawyer) throw const NameSaveException(NameSaveFailure.notAllowed);
    return viewer;
  }

  /// Managers and admins in any file; a lawyer in their own files.
  void _requireTopicEditor(String fileId) {
    final viewer = _store.requireViewer();
    if (!_store.visibleFileIds(viewer).contains(fileId)) throw const NameSaveException(NameSaveFailure.notAllowed);
  }

  /// The unique normalized name: أ/ا, ة/ه, ى/ي and tashkeel are ignored.
  void _guardUniqueName(String name, Iterable<(String, String)> existing, {String? except}) {
    final key = DemoStore.searchable(name.trim());
    if (existing.any((e) => e.$1 != except && DemoStore.searchable(e.$2) == key)) {
      throw const NameSaveException(NameSaveFailure.duplicate);
    }
  }

  static Map<String, Object?> _snapshot(DemoTask t) => {
        'title': t.title,
        'status': t.status.name,
        'assignee_id': t.assigneeId,
        'due_date': DemoStore.ymd(t.dueDate),
        'is_urgent': t.isUrgent,
        'topic_id': t.topicId,
      };
}

/// A task as the `task_list` view returns it, with urgency on today's date.
TaskListItem taskListItem(DemoStore store, DemoTask t) {
  final topic = store.topic(t.topicId)!;
  final file = store.file(topic.fileId)!;
  final today = store.today;
  final open = !t.status.isClosed;
  final overdue = open && t.dueDate.isBefore(today);
  final urgentNow = open && (!t.dueDate.isAfter(today) || t.isUrgent);
  return TaskListItem(
    id: t.id,
    title: t.title,
    status: t.status,
    dueDate: t.dueDate,
    completedAt: t.completedAt,
    isOpen: open,
    isOverdue: overdue,
    isUrgentNow: urgentNow,
    daysUntilDue: DemoStore.daysBetween(today, t.dueDate),
    sortGroup: !open
        ? 3
        : overdue
            ? 0
            : urgentNow
                ? 1
                : 2,
    fileId: file.id,
    fileName: file.name,
    topicId: topic.id,
    topicName: topic.name,
    assigneeId: t.assigneeId,
    assigneeName: store.profile(t.assigneeId)?.displayName,
    updateCount: store.updates.where((u) => u.taskId == t.id).length,
    contractId: t.contractId,
  );
}

/// A `task_activity` row as the app's model; null for an unknown action.
TaskActivityEntry? activityEntry(DemoStore store, DemoTaskActivity row) {
  final action = TaskActivityAction.tryFromDb(row.action);
  if (action == null) return null;
  return TaskActivityEntry(
    id: row.id,
    action: action,
    actorId: row.actorId,
    actorName: store.profile(row.actorId)?.displayName,
    oldValue: row.oldValue,
    newValue: row.newValue,
    createdAt: row.createdAt,
  );
}
