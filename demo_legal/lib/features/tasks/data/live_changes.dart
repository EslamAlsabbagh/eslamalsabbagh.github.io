import 'package:equatable/equatable.dart';

import '../../../demo/demo_store.dart';

/// The tables whose changes the lists follow.
enum LiveTable {
  tasks('tasks'),
  taskUpdates('task_updates'),
  files('files'),
  topics('topics'),
  profiles('profiles'),
  fileMembers('file_members'),

  /// The viewer's own rows only (RLS); the bell follows them.
  notifications('notifications'),

  /// The contracts register (ADR-0013); the «العقود» list follows them.
  contracts('contracts'),
  contractUnits('contract_units'),
  contractItems('contract_items'),
  parties('parties'),
  units('units');

  /// The tables only the «العقود» list follows.
  static const Set<LiveTable> contractTables = {contracts, contractUnits, contractItems, parties, units};

  const LiveTable(this.dbName);

  final String dbName;
}

/// Something changed that the viewer may see. Only a signal: the blocs read
/// the data again, so urgency stays the database's and RLS picks the rows.
class LiveChange extends Equatable {
  const LiveChange(this.table, {this.taskId}) : resync = false;

  /// The channel (re)joined: changes may have been missed, so read everything.
  const LiveChange.resync() : table = null, taskId = null, resync = true;

  /// Null for a resync.
  final LiveTable? table;

  /// The task a `tasks` or `task_updates` row belongs to; null otherwise, and
  /// for a delete (its payload carries only the primary key).
  final String? taskId;
  final bool resync;

  @override
  List<Object?> get props => [table, taskId, resync];
}

/// Changes the viewer may see. In production this is one Realtime channel;
/// in the demo the store announces its own writes, so a task created as the
/// manager rings the lawyer's bell after a role switch, as it would live.
class LiveChanges {
  LiveChanges(this._store);

  final DemoStore _store;

  Stream<LiveChange> get changes => _store.liveChanges;
}
