import '../../../demo/demo_store.dart';
import 'task_activity_entry.dart';

/// [entries] with the people and topics their values point at (assignee and
/// topic changes) named. Used by the drawer's history and by the notifications.
List<TaskActivityEntry> nameActivityEntries(DemoStore store, List<TaskActivityEntry> entries) =>
    TaskActivityEntry.withNames(
      entries,
      profileNames: {for (final p in store.profiles) p.id: p.displayName},
      topicNames: {for (final t in store.topics) t.id: t.name},
    );
