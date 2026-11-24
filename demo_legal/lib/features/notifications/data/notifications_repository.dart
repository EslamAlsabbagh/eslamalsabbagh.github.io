import '../../../demo/demo_store.dart';
import '../../tasks/data/activity_names.dart';
import '../../tasks/data/live_changes.dart';
import '../../tasks/data/task_activity_entry.dart';
import '../../tasks/data/tasks_repository.dart' show activityEntry;
import 'app_notification.dart';

/// Reads the viewer's notifications and marks them read.
///
/// Demo build: the store writes them on each task change, as the production
/// triggers do (ADR-0008), and returns only the viewer's own rows.
class NotificationsRepository {
  NotificationsRepository(this._store);

  final DemoStore _store;

  /// How many of the newest the panel lists. Older ones stay in the table.
  static const int listLimit = 50;

  /// The newest [listLimit] notifications, newest first, with the people in
  /// assignee changes named.
  Future<List<AppNotification>> fetchNotifications() async {
    final viewer = _store.requireViewer();
    final rows = _store.notifications.where((n) => n.userId == viewer.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final items = <AppNotification>[];
    for (final n in rows.take(listLimit)) {
      final type = NotificationType.tryFromDb(n.type);
      if (type == null) continue;
      final row = _store.taskActivity.where((a) => a.id == n.activityId).firstOrNull;
      final TaskActivityEntry? activity = row == null ? null : activityEntry(_store, row);
      items.add(AppNotification(
        id: n.id,
        type: type,
        taskId: n.taskId,
        actorId: n.actorId,
        actorName: _store.profile(n.actorId)?.displayName,
        createdAt: n.createdAt,
        isRead: n.readAt != null,
        activity: activity == null ? null : nameActivityEntries(_store, [activity]).first,
      ));
    }
    return items;
  }

  /// All the viewer's unread notifications, not only the listed ones.
  Future<int> fetchUnreadCount() async {
    final viewer = _store.requireViewer();
    return _store.notifications.where((n) => n.userId == viewer.id && n.readAt == null).length;
  }

  /// Marks one read. A row already read keeps its time.
  Future<void> markRead(String id) async {
    final viewer = _store.requireViewer();
    for (final n in _store.notifications) {
      if (n.id == id && n.userId == viewer.id) n.readAt ??= _store.now;
    }
    _store.changed(LiveTable.notifications);
  }

  /// Marks every unread notification of the viewer read.
  Future<void> markAllRead() async {
    final viewer = _store.requireViewer();
    for (final n in _store.notifications) {
      if (n.userId == viewer.id) n.readAt ??= _store.now;
    }
    _store.changed(LiveTable.notifications);
  }
}
