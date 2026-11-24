import 'package:equatable/equatable.dart';

/// What a `contract_activity` row records. Names match the Postgres
/// `contract_activity_action` enum values.
enum ContractActivityAction {
  created,
  statusChanged,
  partyChanged,
  topicChanged,
  datesChanged,
  areasChanged,
  detailsChanged,
  unitsChanged,
  deleted,
  itemAdded,
  itemResolved,
  itemReopened,
  itemDeleted;

  /// Null for a value this app doesn't know yet (a newer migration), so the
  /// row is skipped instead of breaking the drawer.
  static ContractActivityAction? tryFromDb(String value) => switch (value) {
        'created' => created,
        'status_changed' => statusChanged,
        'party_changed' => partyChanged,
        'topic_changed' => topicChanged,
        'dates_changed' => datesChanged,
        'areas_changed' => areasChanged,
        'details_changed' => detailsChanged,
        'units_changed' => unitsChanged,
        'deleted' => deleted,
        'item_added' => itemAdded,
        'item_resolved' => itemResolved,
        'item_reopened' => itemReopened,
        'item_deleted' => itemDeleted,
        _ => null,
      };
}

/// One line of a contract's history: a `contract_activity` row, written by
/// the triggers on the main contract, whichever row changed
/// (docs/notes/contracts-db.md).
class ContractActivityEntry extends Equatable {
  const ContractActivityEntry({
    required this.id,
    required this.targetId,
    required this.action,
    required this.actorId,
    required this.actorName,
    required this.oldValue,
    required this.newValue,
    required this.createdAt,
    this.oldName,
    this.newName,
  });

  /// Builds from a row selected with [ContractActivityEntry.select]; null for
  /// an unknown action.
  static ContractActivityEntry? tryFromRow(Map<String, dynamic> row) {
    final action = ContractActivityAction.tryFromDb(row['action'] as String);
    if (action == null) return null;
    final actor = row['actor'] as Map<String, dynamic>?;
    return ContractActivityEntry(
      id: row['id'] as String,
      targetId: row['target_id'] as String,
      action: action,
      actorId: row['actor_id'] as String?,
      actorName: actor?['display_name'] as String?,
      oldValue: row['old_value'],
      newValue: row['new_value'],
      createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
    );
  }

  static const String select =
      'id, target_id, actor_id, action, old_value, new_value, created_at, actor:profiles!actor_id(display_name)';

  /// Party ids stored as values (a tenant change), to look their names up.
  static Set<String> partyIdsIn(Iterable<ContractActivityEntry> entries) =>
      _idsIn(entries, ContractActivityAction.partyChanged);

  /// Topic ids stored as values (a brand change), to look their names up.
  static Set<String> topicIdsIn(Iterable<ContractActivityEntry> entries) =>
      _idsIn(entries, ContractActivityAction.topicChanged);

  static Set<String> _idsIn(Iterable<ContractActivityEntry> entries, ContractActivityAction action) => {
        for (final entry in entries)
          if (entry.action == action) ...[?entry.oldValue as String?, ?entry.newValue as String?],
      };

  /// [entries] with [oldName] / [newName] filled from the looked-up names. An
  /// id missing from the maps (RLS hides it) stays null.
  static List<ContractActivityEntry> withNames(
    List<ContractActivityEntry> entries, {
    required Map<String, String> partyNames,
    required Map<String, String> topicNames,
  }) =>
      [
        for (final entry in entries)
          switch (entry.action) {
            ContractActivityAction.partyChanged => entry._named(partyNames),
            ContractActivityAction.topicChanged => entry._named(topicNames),
            _ => entry,
          },
      ];

  ContractActivityEntry _named(Map<String, String> names) => ContractActivityEntry(
        id: id,
        targetId: targetId,
        action: action,
        actorId: actorId,
        actorName: actorName,
        oldValue: oldValue,
        newValue: newValue,
        createdAt: createdAt,
        oldName: names[oldValue],
        newName: names[newValue],
      );

  final String id;

  /// The row that changed: the contract itself, an annex or storage contract
  /// under it, or (for item actions) the contract the item is on.
  final String targetId;
  final ContractActivityAction action;

  /// Null for a system change (seeds, maintenance).
  final String? actorId;

  /// Null if RLS hides the actor's profile.
  final String? actorName;

  /// The stored jsonb: a map for most actions, a uuid for party and brand
  /// changes, null on the side that doesn't apply.
  final Object? oldValue;
  final Object? newValue;

  /// In the device's time zone.
  final DateTime createdAt;

  /// The party or brand behind a uuid value.
  final String? oldName;
  final String? newName;

  /// The value map on [newValue] or [oldValue], or an empty one.
  Map<String, dynamic> get newMap => newValue is Map<String, dynamic> ? newValue! as Map<String, dynamic> : const {};
  Map<String, dynamic> get oldMap => oldValue is Map<String, dynamic> ? oldValue! as Map<String, dynamic> : const {};

  @override
  List<Object?> get props =>
      [id, targetId, action, actorId, actorName, oldValue, newValue, createdAt, oldName, newName];
}
