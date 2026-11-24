import 'dart:async';

import 'package:flutter/widgets.dart';

import '../core/domain/contract_item_kind.dart';
import '../core/domain/contract_kind.dart';
import '../core/domain/contract_status.dart';
import '../core/domain/task_status.dart';
import '../core/domain/unit_kind.dart';
import '../core/domain/user_role.dart';
import '../core/format/app_formats.dart';
import '../core/format/arabic_normalize.dart';
import '../features/auth/data/auth_user.dart';
import '../features/tasks/data/live_changes.dart';
import 'demo_seed.dart';

/// The demo's whole backend: mutable in-memory tables.
///
/// In production every repository talks to a self-hosted Postgres, where Row
/// Level Security and triggers hold the business rules. In the demo the same
/// repository classes keep their public API and read and write these tables
/// instead, re-implementing those rules in Dart, so **no network call is made
/// from anywhere in the application**. [reset] restores the seeded state.
class DemoStore {
  DemoStore._() {
    reset();
  }

  static final DemoStore instance = DemoStore._();

  /// The default password of every seeded account.
  static const String password = 'demo1234';

  // ── Tables ──────────────────────────────────────────────────────────────────
  final profiles = <DemoProfile>[];
  final files = <DemoFile>[];
  final topics = <DemoTopic>[];
  final tasks = <DemoTask>[];
  final updates = <DemoUpdate>[];
  final taskActivity = <DemoTaskActivity>[];
  final notifications = <DemoNotification>[];
  final parties = <DemoParty>[];
  final units = <DemoUnit>[];
  final contracts = <DemoContract>[];
  final items = <DemoItem>[];
  final contractActivity = <DemoContractActivity>[];

  int _nextId = 1;

  /// A fresh id. Prefixed so a stray id in a log says what it points at.
  String id(String prefix) => '$prefix-${_nextId++}';

  // ── Session ─────────────────────────────────────────────────────────────────
  String? _currentUserId;
  final _authChanges = StreamController<AuthUser?>.broadcast();
  final _liveChanges = StreamController<LiveChange>.broadcast();

  /// The UI language, switched from the demo bar. English first, since most
  /// visitors read English; the product itself is Arabic-first.
  final ValueNotifier<Locale> locale = ValueNotifier(const Locale('en'));

  /// Bumped on [reset], so the demo bar can rebuild what depends on the data.
  final ValueNotifier<int> generation = ValueNotifier(0);

  Stream<AuthUser?> get authChanges => _authChanges.stream;
  Stream<LiveChange> get liveChanges => _liveChanges.stream;

  DemoProfile? get currentUser =>
      _currentUserId == null ? null : profiles.where((p) => p.id == _currentUserId).firstOrNull;

  AuthUser? get currentAuthUser {
    final user = currentUser;
    return user == null ? null : AuthUser(id: user.id, email: user.email);
  }

  /// Signs in as [userId], as the role buttons in the demo bar do.
  void signInAs(String userId) {
    _currentUserId = userId;
    _authChanges.add(currentAuthUser);
  }

  void signOut() {
    _currentUserId = null;
    _authChanges.add(null);
  }

  void setLocale(Locale value) {
    AppFormats.locale = value.languageCode == 'ar' ? 'ar_EG' : 'en_US';
    locale.value = value;
  }

  /// Back to the seeded data, signed in as the same person if they still
  /// exist (the default manager otherwise).
  void reset() {
    final keep = _currentUserId;
    for (final table in <List<Object>>[
      profiles, files, topics, tasks, updates, taskActivity, notifications, parties, units, contracts, items,
      contractActivity,
    ]) {
      table.clear();
    }
    _nextId = 1;
    DemoSeed.populate(this);
    _currentUserId = profiles.any((p) => p.id == keep) ? keep : DemoSeed.managerId;
    generation.value++;
    _authChanges.add(currentAuthUser);
    _liveChanges.add(const LiveChange.resync());
  }

  /// Tells the open lists and the bell that [table] changed, as Realtime does.
  void changed(LiveTable table, {String? taskId}) => _liveChanges.add(LiveChange(table, taskId: taskId));

  /// A short pause on every call, so loading states look as they do over a LAN.
  Future<void> latency() => Future<void>.delayed(const Duration(milliseconds: 90));

  // ── Clock ───────────────────────────────────────────────────────────────────
  DateTime get now => DateTime.now();
  DateTime get today => dateOnly(now);
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  static int daysBetween(DateTime from, DateTime to) =>
      DateTime.utc(to.year, to.month, to.day).difference(DateTime.utc(from.year, from.month, from.day)).inDays;
  static String ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Lookups ─────────────────────────────────────────────────────────────────
  DemoProfile? profile(String? id) => id == null ? null : profiles.where((p) => p.id == id).firstOrNull;
  DemoFile? file(String? id) => id == null ? null : files.where((f) => f.id == id).firstOrNull;
  DemoTopic? topic(String? id) => id == null ? null : topics.where((t) => t.id == id).firstOrNull;
  DemoTask? task(String? id) => id == null ? null : tasks.where((t) => t.id == id).firstOrNull;
  DemoParty? party(String? id) => id == null ? null : parties.where((p) => p.id == id).firstOrNull;
  DemoUnit? unit(String? id) => id == null ? null : units.where((u) => u.id == id).firstOrNull;
  DemoContract? contract(String? id) => id == null ? null : contracts.where((c) => c.id == id).firstOrNull;

  String fileIdOfTask(DemoTask task) => topic(task.topicId)!.fileId;

  // ── Row Level Security, re-stated ───────────────────────────────────────────

  /// The files [viewer] may see: a lawyer's member files, everything for others.
  Set<String> visibleFileIds(DemoProfile viewer) =>
      viewer.role == UserRole.lawyer ? {...viewer.fileIds} : {for (final f in files) f.id};

  bool canSeeTask(DemoProfile viewer, DemoTask task) => visibleFileIds(viewer).contains(fileIdOfTask(task));

  bool canSeeContract(DemoProfile viewer, DemoContract contract) =>
      visibleFileIds(viewer).contains(contract.fileId);

  /// The signed-in, active user, or a refusal. Every write starts here.
  DemoProfile requireViewer() {
    final viewer = currentUser;
    if (viewer == null || !viewer.isActive) throw StateError('not signed in');
    return viewer;
  }

  // ── Notifications (the `notify_users` trigger) ──────────────────────────────

  /// Notifies [recipients] about [task], skipping the actor, inactive people
  /// and lawyers who are no longer members of the task's file.
  void notify(
    DemoTask task, {
    required String type,
    required String? actorId,
    required Iterable<String?> recipients,
    String? activityId,
    DateTime? at,
  }) {
    final fileId = fileIdOfTask(task);
    for (final id in {...recipients.whereType<String>()}) {
      final person = profile(id);
      if (person == null || id == actorId || !person.isActive) continue;
      if (person.role == UserRole.lawyer && !person.fileIds.contains(fileId)) continue;
      notifications.add(DemoNotification(
        id: this.id('n'),
        userId: id,
        type: type,
        taskId: task.id,
        actorId: actorId,
        activityId: activityId,
        createdAt: at ?? now,
      ));
    }
    changed(LiveTable.notifications);
  }

  /// Writes a task_activity row and the notifications its trigger sends.
  DemoTaskActivity logTask(
    DemoTask task,
    String action, {
    required String? actorId,
    Object? oldValue,
    Object? newValue,
    DateTime? at,
    bool notifyPeople = true,
  }) {
    final entry = DemoTaskActivity(
      id: id('ta'),
      taskId: task.id,
      actorId: actorId,
      action: action,
      oldValue: oldValue,
      newValue: newValue,
      createdAt: at ?? now,
    );
    taskActivity.add(entry);
    if (!notifyPeople) return entry;
    switch (action) {
      case 'created':
        notify(task,
            type: 'assigned', actorId: actorId, recipients: [task.assigneeId], activityId: entry.id, at: entry.createdAt);
      case 'assignee_changed':
        notify(task,
            type: 'assigned',
            actorId: actorId,
            recipients: [newValue as String?],
            activityId: entry.id,
            at: entry.createdAt);
        notify(task,
            type: 'task_changed',
            actorId: actorId,
            recipients: [oldValue as String?, task.createdBy].where((id) => id != newValue),
            activityId: entry.id,
            at: entry.createdAt);
      case 'status_changed' || 'due_date_changed' || 'urgency_changed':
        notify(task,
            type: 'task_changed',
            actorId: actorId,
            recipients: [task.assigneeId, task.createdBy],
            activityId: entry.id,
            at: entry.createdAt);
    }
    return entry;
  }

  // ── Contracts ───────────────────────────────────────────────────────────────

  /// The main contract [c] belongs to: itself, or the top of its parents.
  DemoContract mainOf(DemoContract c) {
    var current = c;
    while (current.parentId != null) {
      current = contract(current.parentId)!;
    }
    return current;
  }

  List<DemoContract> childrenOf(String id) => [for (final c in contracts) if (c.parentId == id) c];

  /// [c] and every row under it.
  List<DemoContract> subtree(DemoContract c) => [c, for (final child in childrenOf(c.id)) ...subtree(child)];

  /// Writes a contract_activity row on [target]'s main contract.
  void logContract(
    DemoContract target,
    String action, {
    Object? oldValue,
    Object? newValue,
    String? actorId,
    DateTime? at,
  }) {
    contractActivity.add(DemoContractActivity(
      id: id('ca'),
      contractId: mainOf(target).id,
      targetId: target.id,
      actorId: actorId ?? currentUser?.id,
      action: action,
      oldValue: oldValue,
      newValue: newValue,
      createdAt: at ?? now,
    ));
  }

  /// A contract's values after its active annexes (the `contract_list` view):
  /// the newest annex that sets a value wins, and says which annex set it.
  EffectiveContract effective(DemoContract c) {
    final annexes = [
      for (final a in childrenOf(c.id))
        if (a.kind == ContractKind.annex && a.status == ContractStatus.active) a,
    ]..sort((a, b) => (a.annexNo ?? 0).compareTo(b.annexNo ?? 0));
    var result = EffectiveContract(
      endsOn: c.endsOn,
      areaInner: c.areaInner,
      areaOuter: c.areaOuter,
      partyId: c.partyId,
      unitIds: c.unitIds,
    );
    for (final a in annexes) {
      result = EffectiveContract(
        endsOn: a.endsOn ?? result.endsOn,
        endsOnAnnexNo: a.endsOn != null ? a.annexNo : result.endsOnAnnexNo,
        areaInner: a.areaInner ?? result.areaInner,
        areaInnerAnnexNo: a.areaInner != null ? a.annexNo : result.areaInnerAnnexNo,
        areaOuter: a.areaOuter ?? result.areaOuter,
        areaOuterAnnexNo: a.areaOuter != null ? a.annexNo : result.areaOuterAnnexNo,
        partyId: a.partyId ?? result.partyId,
        partyAnnexNo: a.partyId != null ? a.annexNo : result.partyAnnexNo,
        unitIds: a.unitIds.isNotEmpty ? a.unitIds : result.unitIds,
        unitsAnnexNo: a.unitIds.isNotEmpty ? a.annexNo : result.unitsAnnexNo,
      );
    }
    return result;
  }

  /// `list_status` on today's date: terminated, expired, ending within 90
  /// days, or active.
  String listStatus(DemoContract c) {
    if (c.status == ContractStatus.terminated) return 'terminated';
    final ends = effective(c).endsOn;
    if (ends == null) return 'active';
    if (ends.isBefore(today)) return 'expired';
    if (!ends.isAfter(today.add(const Duration(days: 90)))) return 'ending';
    return 'active';
  }

  static int sortGroupOf(String listStatus) =>
      switch (listStatus) { 'expired' => 0, 'ending' => 1, 'active' => 2, _ => 4 };

  /// Codes of [unitIds], ordered by their code key, as the view orders them.
  List<String> unitCodes(Iterable<String> unitIds) {
    final list = [for (final id in unitIds) ?unit(id)]..sort((a, b) => unitCodeKey(a.code).compareTo(unitCodeKey(b.code)));
    return [for (final u in list) u.code];
  }

  /// Open checklist items on [c], everything under it, and its tenant.
  int openItemCount(DemoContract c) {
    final ids = {for (final x in subtree(c)) x.id};
    final partyId = effective(c).partyId;
    return items
        .where((i) => !i.isResolved && (ids.contains(i.contractId) || (partyId != null && i.partyId == partyId)))
        .length;
  }

  /// Open follow-up tasks on [c] and everything under it.
  int openTaskCount(DemoContract c) {
    final ids = {for (final x in subtree(c)) x.id};
    return tasks.where((t) => !t.status.isClosed && ids.contains(t.contractId)).length;
  }

  /// Lower-cased, Arabic-normalized text for the searches.
  static String searchable(String text) => normalizeAr(text).toLowerCase();

  /// Whether every word of [query] appears in one of [fields].
  static bool matchesAll(String query, Iterable<String?> fields) {
    final haystack = searchable(fields.whereType<String>().join(' '));
    final words = searchable(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return words.every(haystack.contains);
  }

  /// Whole-string trigram similarity, 0 to 1, like `pg_trgm`'s.
  static double similarity(String a, String b) {
    Set<String> grams(String s) {
      final padded = '  ${searchable(s)} ';
      return {for (var i = 0; i + 3 <= padded.length; i++) padded.substring(i, i + 3)};
    }

    final x = grams(a), y = grams(b);
    if (x.isEmpty || y.isEmpty) return 0;
    return x.intersection(y).length / x.union(y).length;
  }
}

// ── Rows ──────────────────────────────────────────────────────────────────────

class DemoProfile {
  DemoProfile({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.createdAt,
    Set<String>? fileIds,
    this.isActive = true,
    this.password = DemoStore.password,
  }) : fileIds = fileIds ?? {};

  final String id;
  String displayName;
  String email;
  UserRole role;
  bool isActive;
  String password;
  final DateTime createdAt;

  /// `file_members`: only a lawyer's decide what they see.
  final Set<String> fileIds;
}

class DemoFile {
  DemoFile({required this.id, required this.name, required this.createdAt});

  final String id;
  String name;
  final DateTime createdAt;
}

class DemoTopic {
  DemoTopic({required this.id, required this.fileId, required this.name, required this.createdAt});

  final String id;
  final String fileId;
  String name;
  final DateTime createdAt;
}

class DemoTask {
  DemoTask({
    required this.id,
    required this.topicId,
    required this.title,
    required this.description,
    required this.assigneeId,
    required this.createdBy,
    required this.status,
    required this.isUrgent,
    required this.dueDate,
    required this.createdAt,
    this.completedAt,
    this.contractId,
  });

  final String id;
  String topicId;
  String title;
  String description;
  String assigneeId;
  final String createdBy;
  TaskStatus status;
  bool isUrgent;
  DateTime dueDate;
  DateTime? completedAt;
  final DateTime createdAt;
  String? contractId;
}

class DemoUpdate {
  DemoUpdate({required this.id, required this.taskId, required this.authorId, required this.body, required this.createdAt});

  final String id;
  final String taskId;
  final String authorId;
  final String body;
  final DateTime createdAt;
}

class DemoTaskActivity {
  DemoTaskActivity({
    required this.id,
    required this.taskId,
    required this.actorId,
    required this.action,
    required this.oldValue,
    required this.newValue,
    required this.createdAt,
  });

  final String id;
  final String taskId;
  final String? actorId;
  final String action;
  final Object? oldValue;
  final Object? newValue;
  final DateTime createdAt;
}

class DemoNotification {
  DemoNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.taskId,
    required this.actorId,
    required this.createdAt,
    this.activityId,
    this.readAt,
  });

  final String id;
  final String userId;
  final String type;
  final String taskId;
  final String? actorId;
  final String? activityId;
  final DateTime createdAt;
  DateTime? readAt;
}

class DemoParty {
  DemoParty({required this.id, required this.name});

  final String id;
  final String name;
}

class DemoUnit {
  DemoUnit({required this.id, required this.fileId, required this.code, required this.kind, this.keyNumber});

  final String id;
  final String fileId;
  final String code;
  final UnitKind kind;
  final String? keyNumber;
}

class DemoContract {
  DemoContract({
    required this.id,
    required this.fileId,
    required this.kind,
    required this.createdAt,
    this.topicId,
    this.parentId,
    this.subject = '',
    this.annexNo,
    this.activity = '',
    this.signedOn,
    this.startsOn,
    this.endsOn,
    this.dateNote = '',
    this.areaInner,
    this.areaOuter,
    this.areaNote = '',
    this.status = ContractStatus.active,
    this.notes = '',
    this.partyId,
    List<String>? unitIds,
    this.terminatedOn,
    this.terminationReason = '',
  }) : unitIds = unitIds ?? [];

  final String id;
  String fileId;
  ContractKind kind;
  String? topicId;
  String? parentId;
  String subject;
  int? annexNo;
  String activity;
  DateTime? signedOn;
  DateTime? startsOn;
  DateTime? endsOn;
  String dateNote;
  double? areaInner;
  double? areaOuter;
  String areaNote;
  ContractStatus status;
  String notes;
  String? partyId;
  List<String> unitIds;
  DateTime? terminatedOn;
  String terminationReason;
  final DateTime createdAt;
}

class EffectiveContract {
  const EffectiveContract({
    required this.endsOn,
    required this.areaInner,
    required this.areaOuter,
    required this.partyId,
    required this.unitIds,
    this.endsOnAnnexNo,
    this.areaInnerAnnexNo,
    this.areaOuterAnnexNo,
    this.partyAnnexNo,
    this.unitsAnnexNo,
  });

  final DateTime? endsOn;
  final double? areaInner;
  final double? areaOuter;
  final String? partyId;
  final List<String> unitIds;
  final int? endsOnAnnexNo;
  final int? areaInnerAnnexNo;
  final int? areaOuterAnnexNo;
  final int? partyAnnexNo;
  final int? unitsAnnexNo;
}

class DemoItem {
  DemoItem({
    required this.id,
    required this.kind,
    required this.label,
    required this.createdAt,
    this.contractId,
    this.partyId,
    this.detail = '',
    this.needsSignature = false,
    this.needsStamp = false,
    this.side = ContractItemSide.client,
    this.isResolved = false,
  });

  final String id;
  final ContractItemKind kind;
  final String? contractId;
  final String? partyId;
  final String label;
  final String detail;
  final bool needsSignature;
  final bool needsStamp;
  final ContractItemSide side;
  bool isResolved;
  final DateTime createdAt;
}

class DemoContractActivity {
  DemoContractActivity({
    required this.id,
    required this.contractId,
    required this.targetId,
    required this.actorId,
    required this.action,
    required this.oldValue,
    required this.newValue,
    required this.createdAt,
  });

  final String id;

  /// The main contract whose history shows it.
  final String contractId;
  final String targetId;
  final String? actorId;
  final String action;
  final Object? oldValue;
  final Object? newValue;
  final DateTime createdAt;
}
