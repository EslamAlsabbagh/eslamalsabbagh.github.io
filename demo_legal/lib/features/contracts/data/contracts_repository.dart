import '../../../core/domain/contract_kind.dart';
import '../../../core/domain/contract_list_status.dart';
import '../../../core/domain/contract_status.dart';
import '../../../core/domain/unit_kind.dart';
import '../../../core/domain/user_role.dart';
import '../../../core/format/arabic_normalize.dart';
import '../../../demo/demo_store.dart';
import '../../tasks/data/live_changes.dart';
import 'contract_activity_entry.dart';
import 'contract_details.dart';
import 'contract_item.dart';
import 'contract_list_item.dart';
import 'contract_record.dart';
import 'contract_register_data.dart';
import 'contract_refs.dart';
import 'contract_save_failure.dart';

/// Reads, searches and writes the contracts register, and serves the
/// suggest fields.
///
/// Demo build: reads and writes [DemoStore]. What production computes in the
/// `contract_list` view (values after active annexes, the list status on
/// today's date, the counts) and what its triggers write (the history) is
/// computed here instead, so the drawer and the export see the same numbers.
class ContractsRepository {
  ContractsRepository(this._store);

  final DemoStore _store;

  /// Every visible main contract, in no particular order: the list sorts
  /// them per file section.
  Future<List<ContractListItem>> fetchContracts() async {
    await _store.latency();
    final viewer = _store.requireViewer();
    return [for (final c in _mains(viewer)) _listItem(c)];
  }

  /// Ids of the visible main contracts whose brand, activity, tenant, subject
  /// or unit codes contain every word of [query].
  Future<Set<String>> searchContractIds(String query) async {
    await _store.latency();
    final viewer = _store.requireViewer();
    return {
      for (final c in _mains(viewer))
        if (DemoStore.matchesAll(query, [
          _store.topic(c.topicId)?.name,
          c.activity,
          c.subject,
          _store.party(_store.effective(c).partyId)?.name,
          ..._store.unitCodes(_store.effective(c).unitIds),
        ]))
          c.id,
    };
  }

  // Drawer -------------------------------------------------------------------------------------------------

  /// One main contract with its effective values.
  Future<ContractDetails> fetchDetails(String id) async {
    await _store.latency();
    final c = _visible(id);
    final e = _store.effective(c);
    final status = _store.listStatus(c);
    final starts = c.startsOn ?? c.signedOn;
    return ContractDetails(
      id: c.id,
      fileId: c.fileId,
      topicId: c.topicId,
      kind: c.kind,
      subject: c.subject,
      activity: c.activity,
      status: c.status,
      listStatus: ContractListStatus.fromDb(status),
      signedOn: c.signedOn,
      startsOn: starts,
      endsOn: e.endsOn,
      dateNote: c.dateNote,
      areaInner: e.areaInner,
      areaOuter: e.areaOuter,
      areaNote: c.areaNote,
      partyId: e.partyId,
      partyName: _store.party(e.partyId)?.name,
      unitCodes: _store.unitCodes(e.unitIds),
      terminatedOn: c.terminatedOn,
      terminationReason: c.terminationReason,
      notes: c.notes,
      durationMonths: starts == null || e.endsOn == null ? null : _months(starts, e.endsOn!),
      daysUntilEnd: e.endsOn == null ? null : DemoStore.daysBetween(_store.today, e.endsOn!),
      annexCount: _store.childrenOf(c.id).where((x) => x.kind == ContractKind.annex).length,
      storageCount: _store.childrenOf(c.id).where((x) => x.kind == ContractKind.storage).length,
      openItemCount: _store.openItemCount(c),
      openTaskCount: _store.openTaskCount(c),
      endsOnAnnexNo: e.endsOnAnnexNo,
      areaInnerAnnexNo: e.areaInnerAnnexNo,
      areaOuterAnnexNo: e.areaOuterAnnexNo,
      partyAnnexNo: e.partyAnnexNo,
      unitsAnnexNo: e.unitsAnnexNo,
    );
  }

  /// A contract's own row, its units and what hangs on it.
  Future<ContractRecord> fetchRecord(String id) async {
    await _store.latency();
    return _record(_visible(id));
  }

  /// The annexes and storage contracts directly under [parentId].
  Future<List<ContractRecord>> fetchChildren(String parentId) async {
    _visible(parentId);
    return [for (final c in _store.childrenOf(parentId)) _record(c)];
  }

  /// A main contract's history, newest first, with parties and brands named.
  Future<List<ContractActivityEntry>> fetchActivity(String contractId) async {
    final rows = _store.contractActivity.where((a) => a.contractId == contractId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final entries = <ContractActivityEntry>[];
    for (final row in rows) {
      final action = ContractActivityAction.tryFromDb(row.action);
      if (action == null) continue;
      entries.add(ContractActivityEntry(
        id: row.id,
        targetId: row.targetId,
        action: action,
        actorId: row.actorId,
        actorName: _store.profile(row.actorId)?.displayName,
        oldValue: row.oldValue,
        newValue: row.newValue,
        createdAt: row.createdAt,
      ));
    }
    return ContractActivityEntry.withNames(
      entries,
      partyNames: {for (final p in _store.parties) p.id: p.name},
      topicNames: {for (final t in _store.topics) t.id: t.name},
    );
  }

  /// The missing items on [contractIds] and the documents asked of [partyId],
  /// oldest first.
  Future<List<ContractItem>> fetchItems({required List<String> contractIds, String? partyId}) async {
    final ids = contractIds.toSet();
    final rows = _store.items
        .where((i) => ids.contains(i.contractId) || (partyId != null && i.partyId == partyId))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return [for (final i in rows) _item(i)];
  }

  // Export -------------------------------------------------------------------------------------------------

  /// What the exported register shows for [mainIds].
  Future<ContractRegisterData> fetchRegister(List<String> mainIds) async {
    await _store.latency();
    final viewer = _store.requireViewer();
    final mains = <String, RegisterMain>{};
    final contracts = <String, RegisterContract>{};
    final ends = <String, RegisterEnd>{};
    for (final id in mainIds) {
      final main = _store.contract(id);
      if (main == null || !_store.canSeeContract(viewer, main)) continue;
      mains[id] = RegisterMain(
        id: id,
        season: main.signedOn?.year,
        terminatedOn: main.terminatedOn,
        terminationReason: main.terminationReason,
      );
      for (final c in _store.subtree(main)) {
        contracts[c.id] = _registerContract(c);
        if (c.kind != ContractKind.annex) {
          ends[c.id] = RegisterEnd(
            id: c.id,
            listStatus: ContractListStatus.fromDb(_store.listStatus(c)),
            endsOnAnnexNo: _store.effective(c).endsOnAnnexNo,
          );
        }
      }
    }
    final partyIds = {for (final c in contracts.values) ?c.partyId};
    final items = [
      for (final i in _store.items)
        if (!i.isResolved && (contracts.containsKey(i.contractId) || partyIds.contains(i.partyId))) _item(i),
    ];
    final followUps = [
      for (final t in _store.tasks)
        if (!t.status.isClosed && contracts.containsKey(t.contractId))
          RegisterFollowUp(contractId: t.contractId!, title: t.title),
    ];
    return ContractRegisterData(mains: mains, contracts: contracts, ends: ends, items: items, followUps: followUps);
  }

  // Writes -------------------------------------------------------------------------------------------------

  /// Adds a checklist item from the inline row.
  ///
  /// Throws [ContractSaveException].
  Future<void> addItem(ContractItemInput input) async {
    await _store.latency();
    _store.requireViewer();
    if (input.contractId != null) _visibleForWrite(input.contractId!);
    final item = DemoItem(
      id: _store.id('i'),
      kind: input.kind,
      contractId: input.contractId,
      partyId: input.partyId,
      label: input.label,
      detail: input.detail,
      needsSignature: input.needsSignature,
      needsStamp: input.needsStamp,
      side: input.side,
      createdAt: _store.now,
    );
    _store.items.add(item);
    _logItem(item, 'item_added', newValue: _itemMap(item));
    _store.changed(LiveTable.contractItems);
  }

  /// Ticks or unticks an item.
  ///
  /// Throws [ContractSaveException].
  Future<void> setItemResolved(String id, {required bool resolved}) async {
    await _store.latency();
    _store.requireViewer();
    final item = _store.items.where((i) => i.id == id).firstOrNull;
    if (item == null) throw const ContractSaveException(ContractSaveFailure.notAllowed);
    if (item.isResolved == resolved) return;
    item.isResolved = resolved;
    _logItem(item, resolved ? 'item_resolved' : 'item_reopened', newValue: _itemMap(item));
    _store.changed(LiveTable.contractItems);
  }

  /// Deletes an item added by mistake.
  ///
  /// Throws [ContractSaveException].
  Future<void> deleteItem(String id) async {
    await _store.latency();
    _store.requireViewer();
    final item = _store.items.where((i) => i.id == id).firstOrNull;
    if (item == null) throw const ContractSaveException(ContractSaveFailure.notAllowed);
    _logItem(item, 'item_deleted', oldValue: _itemMap(item));
    _store.items.remove(item);
    _store.changed(LiveTable.contractItems);
  }

  /// Creates or edits a contract and sets its own units; returns its id.
  ///
  /// Throws [ContractSaveException].
  Future<String> saveContract(ContractInput input) async {
    await _store.latency();
    final viewer = _store.requireViewer();
    if (!_store.visibleFileIds(viewer).contains(input.fileId)) {
      throw const ContractSaveException(ContractSaveFailure.notAllowed);
    }
    final topic = _store.topic(input.topicId);
    final badTopic = input.topicId != null && (topic == null || topic.fileId != input.fileId);
    final badUnits = input.unitIds.any((u) => _store.unit(u)?.fileId != input.fileId);
    final leaseWithoutBrand = input.kind == ContractKind.lease && input.topicId == null;
    if (badTopic || badUnits || leaseWithoutBrand) throw const ContractSaveException(ContractSaveFailure.rejected);

    if (input.id == null) {
      final c = DemoContract(
        id: _store.id('c'),
        fileId: input.fileId,
        kind: input.kind,
        createdAt: _store.now,
        topicId: input.topicId,
        parentId: input.parentId,
        subject: input.subject,
        activity: input.activity,
        signedOn: input.signedOn,
        startsOn: input.startsOn,
        endsOn: input.endsOn,
        dateNote: input.dateNote,
        areaInner: input.areaInner,
        areaOuter: input.areaOuter,
        areaNote: input.areaNote,
        notes: input.notes,
        partyId: input.partyId,
        unitIds: [...input.unitIds],
      );
      _store.contracts.add(c);
      _store.logContract(c, 'created', newValue: _rowMap(c));
      _store.changed(LiveTable.contracts);
      return c.id;
    }

    final c = _visibleForWrite(input.id!);
    String? d(DateTime? v) => v == null ? null : DemoStore.ymd(v);
    if (c.partyId != input.partyId) {
      _store.logContract(c, 'party_changed', oldValue: c.partyId, newValue: input.partyId);
    }
    if (c.topicId != input.topicId) {
      _store.logContract(c, 'topic_changed', oldValue: c.topicId, newValue: input.topicId);
    }
    if (d(c.signedOn) != d(input.signedOn) || d(c.startsOn) != d(input.startsOn) || d(c.endsOn) != d(input.endsOn)) {
      _store.logContract(c, 'dates_changed',
          oldValue: {'signed_on': d(c.signedOn), 'starts_on': d(c.startsOn), 'ends_on': d(c.endsOn)},
          newValue: {'signed_on': d(input.signedOn), 'starts_on': d(input.startsOn), 'ends_on': d(input.endsOn)});
    }
    if (c.areaInner != input.areaInner || c.areaOuter != input.areaOuter) {
      _store.logContract(c, 'areas_changed',
          oldValue: {'area_inner': c.areaInner, 'area_outer': c.areaOuter},
          newValue: {'area_inner': input.areaInner, 'area_outer': input.areaOuter});
    }
    if (c.subject != input.subject || c.activity != input.activity || c.notes != input.notes) {
      _store.logContract(c, 'details_changed',
          oldValue: {'subject': c.subject, 'activity': c.activity, 'notes': c.notes},
          newValue: {'subject': input.subject, 'activity': input.activity, 'notes': input.notes});
    }
    _logUnits(c, c.unitIds, input.unitIds);
    c
      ..kind = input.kind
      ..topicId = input.topicId
      ..parentId = input.parentId
      ..partyId = input.partyId
      ..subject = input.subject
      ..activity = input.activity
      ..signedOn = input.signedOn
      ..startsOn = input.startsOn
      ..endsOn = input.endsOn
      ..dateNote = input.dateNote
      ..areaInner = input.areaInner
      ..areaOuter = input.areaOuter
      ..areaNote = input.areaNote
      ..notes = input.notes
      ..unitIds = [...input.unitIds];
    _store.changed(LiveTable.contracts);
    return c.id;
  }

  /// Creates or edits an annex and sets the units it replaces; returns its id.
  ///
  /// Throws [ContractSaveException].
  Future<String> saveAnnex(AnnexInput input) async {
    await _store.latency();
    final parent = _visibleForWrite(input.parentId);
    final taken = _store
        .childrenOf(parent.id)
        .any((a) => a.kind == ContractKind.annex && a.annexNo == input.annexNo && a.id != input.id);
    if (taken) throw const ContractSaveException(ContractSaveFailure.duplicateAnnexNo);

    if (input.id == null) {
      final a = DemoContract(
        id: _store.id('c'),
        fileId: parent.fileId,
        kind: ContractKind.annex,
        createdAt: _store.now,
        topicId: parent.topicId,
        parentId: parent.id,
        annexNo: input.annexNo,
        subject: input.subject,
        signedOn: input.signedOn,
        notes: input.notes,
        endsOn: input.endsOn,
        areaInner: input.areaInner,
        areaOuter: input.areaOuter,
        partyId: input.partyId,
        unitIds: [...input.unitIds],
      );
      _store.contracts.add(a);
      _store.logContract(a, 'created', newValue: _rowMap(a));
      _store.changed(LiveTable.contracts);
      return a.id;
    }

    final a = _visibleForWrite(input.id!);
    if (a.annexNo != input.annexNo || a.subject != input.subject || a.notes != input.notes) {
      _store.logContract(a, 'details_changed',
          oldValue: {'annex_no': a.annexNo, 'subject': a.subject, 'notes': a.notes},
          newValue: {'annex_no': input.annexNo, 'subject': input.subject, 'notes': input.notes});
    }
    if (a.endsOn != input.endsOn) {
      String? d(DateTime? v) => v == null ? null : DemoStore.ymd(v);
      _store.logContract(a, 'dates_changed', oldValue: {'ends_on': d(a.endsOn)}, newValue: {'ends_on': d(input.endsOn)});
    }
    _logUnits(a, a.unitIds, input.unitIds);
    a
      ..annexNo = input.annexNo
      ..subject = input.subject
      ..signedOn = input.signedOn
      ..notes = input.notes
      ..endsOn = input.endsOn
      ..areaInner = input.areaInner
      ..areaOuter = input.areaOuter
      ..partyId = input.partyId
      ..unitIds = [...input.unitIds];
    _store.changed(LiveTable.contracts);
    return a.id;
  }

  /// «إنهاء العقد» on [on] (a calendar date) for [reason].
  Future<void> terminate(String id, {required DateTime on, required String reason}) async {
    await _store.latency();
    final c = _visibleForWrite(id);
    if (c.status == ContractStatus.terminated) return;
    c
      ..status = ContractStatus.terminated
      ..terminatedOn = DemoStore.dateOnly(on)
      ..terminationReason = reason;
    _store.logContract(c, 'status_changed',
        oldValue: {'status': 'active'},
        newValue: {'status': 'terminated', 'termination_reason': reason, 'terminated_on': DemoStore.ymd(on)});
    _store.changed(LiveTable.contracts);
  }

  /// «إعادة تفعيل»: managers and admins only (`contracts_reopen_guard`).
  Future<void> reopen(String id) async {
    await _store.latency();
    final viewer = _store.requireViewer();
    if (viewer.role == UserRole.lawyer) throw const ContractSaveException(ContractSaveFailure.notAllowed);
    final c = _visibleForWrite(id);
    c
      ..status = ContractStatus.active
      ..terminatedOn = null
      ..terminationReason = '';
    _store.logContract(c, 'status_changed', oldValue: {'status': 'terminated'}, newValue: {'status': 'active'});
    _store.changed(LiveTable.contracts);
  }

  /// «حذف العقد»: only an active contract with nothing hanging on it.
  Future<void> delete(String id) async {
    await _store.latency();
    final c = _visibleForWrite(id);
    if (c.status != ContractStatus.active) throw const ContractSaveException(ContractSaveFailure.notAllowed);
    if (!_record(c).canDelete) throw const ContractSaveException(ContractSaveFailure.notEmpty);
    if (c.parentId != null) _store.logContract(c, 'deleted', oldValue: _rowMap(c));
    _store.contracts.remove(c);
    _store.contractActivity.removeWhere((a) => a.contractId == c.id);
    _store.changed(LiveTable.contracts);
  }

  /// A new party named [name]. Any active user may add one.
  Future<PartyRef> createParty(String name) async {
    await _store.latency();
    _store.requireViewer();
    final key = DemoStore.searchable(name.trim());
    if (_store.parties.any((p) => DemoStore.searchable(p.name) == key)) {
      throw const ContractSaveException(ContractSaveFailure.duplicateParty);
    }
    final p = DemoParty(id: _store.id('pa'), name: name.trim());
    _store.parties.add(p);
    _store.changed(LiveTable.parties);
    return PartyRef(id: p.id, name: p.name);
  }

  /// A new unit [code] in [fileId].
  Future<UnitRef> createUnit({
    required String fileId,
    required String code,
    required UnitKind kind,
    String? keyNumber,
  }) async {
    await _store.latency();
    final viewer = _store.requireViewer();
    if (!_store.visibleFileIds(viewer).contains(fileId)) {
      throw const ContractSaveException(ContractSaveFailure.notAllowed);
    }
    final key = unitCodeKey(code);
    if (_store.units.any((u) => u.fileId == fileId && unitCodeKey(u.code) == key)) {
      throw const ContractSaveException(ContractSaveFailure.duplicateUnit);
    }
    final u = DemoUnit(id: _store.id('un'), fileId: fileId, code: code.trim(), kind: kind, keyNumber: keyNumber);
    _store.units.add(u);
    _store.changed(LiveTable.units);
    return UnitRef(id: u.id, code: u.code, kind: u.kind, keyNumber: u.keyNumber);
  }

  // Suggestions --------------------------------------------------------------------------------------------

  /// At most 5 parties for [query]; with an empty query, the most used.
  Future<List<PartySuggestion>> suggestParties(String query) async {
    final viewer = _store.requireViewer();
    int uses(String partyId) => _store.contracts
        .where((c) => c.partyId == partyId && _store.canSeeContract(viewer, c))
        .length;
    final q = query.trim();
    final ranked = [
      for (final p in _store.parties)
        if (q.isEmpty || DemoStore.matchesAll(q, [p.name]) || DemoStore.similarity(p.name, q) >= .3)
          PartySuggestion(
            party: PartyRef(id: p.id, name: p.name),
            contractCount: uses(p.id),
            score: q.isEmpty ? 0 : DemoStore.similarity(p.name, q),
          ),
    ]..sort((a, b) => q.isEmpty ? b.contractCount.compareTo(a.contractCount) : b.score.compareTo(a.score));
    return ranked.take(5).toList();
  }

  /// At most 5 units of [fileId] for [query], of [kinds] only when given.
  Future<List<UnitSuggestion>> suggestUnits(String fileId, String query, {List<UnitKind>? kinds}) async {
    final q = query.trim();
    final matches = [
      for (final u in _store.units)
        if (u.fileId == fileId &&
            (kinds == null || kinds.contains(u.kind)) &&
            (q.isEmpty || DemoStore.searchable(u.code).contains(DemoStore.searchable(q))))
          UnitSuggestion(
            unit: UnitRef(id: u.id, code: u.code, kind: u.kind),
            keyNumber: u.keyNumber,
            currentBrand: _currentBrand(u.id),
            score: q.isEmpty ? 0 : DemoStore.similarity(u.code, q),
          ),
    ]..sort((a, b) => unitCodeKey(a.unit.code).compareTo(unitCodeKey(b.unit.code)));
    return matches.take(5).toList();
  }

  /// At most 5 spellings of [field] wording for [query].
  Future<List<ValueSuggestion>> suggestValues(SuggestValueField field, String query) async {
    final values = switch (field) {
      SuggestValueField.subject => [
          for (final c in _store.contracts)
            if (c.kind != ContractKind.annex) c.subject,
        ],
      SuggestValueField.annexSubject => [
          for (final c in _store.contracts)
            if (c.kind == ContractKind.annex) c.subject,
        ],
      SuggestValueField.activity => [for (final c in _store.contracts) c.activity],
      SuggestValueField.itemLabel => [for (final i in _store.items) i.label],
    };
    final counts = <String, int>{};
    for (final v in values.map((v) => v.trim()).where((v) => v.isNotEmpty)) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    final q = query.trim();
    final list = [
      for (final e in counts.entries)
        if (q.isEmpty || DemoStore.matchesAll(q, [e.key])) ValueSuggestion(value: e.key, uses: e.value),
    ]..sort((a, b) => b.uses.compareTo(a.uses));
    return list.take(5).toList();
  }

  // Helpers ------------------------------------------------------------------------------------------------

  Iterable<DemoContract> _mains(DemoProfile viewer) => _store.contracts
      .where((c) => c.parentId == null && c.kind != ContractKind.annex && _store.canSeeContract(viewer, c));

  DemoContract _visible(String id) {
    final viewer = _store.requireViewer();
    final c = _store.contract(id);
    if (c == null || !_store.canSeeContract(viewer, c)) throw StateError('contract $id not found');
    return c;
  }

  DemoContract _visibleForWrite(String id) {
    try {
      return _visible(id);
    } on StateError {
      throw const ContractSaveException(ContractSaveFailure.notAllowed);
    }
  }

  ContractListItem _listItem(DemoContract c) {
    final e = _store.effective(c);
    final status = _store.listStatus(c);
    final dateNote = c.dateNote.trim();
    return ContractListItem(
      id: c.id,
      fileId: c.fileId,
      topicId: c.topicId,
      kind: c.kind,
      listStatus: ContractListStatus.fromDb(status),
      sortGroup: DemoStore.sortGroupOf(status),
      endsOn: e.endsOn,
      dateNote: dateNote.isEmpty ? null : dateNote,
      partyId: e.partyId,
      partyName: _store.party(e.partyId)?.name,
      unitCodes: _store.unitCodes(e.unitIds),
      season: c.signedOn?.year,
      terminatedOn: c.terminatedOn,
      createdAt: c.createdAt,
      annexCount: _store.childrenOf(c.id).where((x) => x.kind == ContractKind.annex).length,
      storageCount: _store.childrenOf(c.id).where((x) => x.kind == ContractKind.storage).length,
      openItemCount: _store.openItemCount(c),
      openTaskCount: _store.openTaskCount(c),
    );
  }

  ContractRecord _record(DemoContract c) {
    final own = _store.items.where((i) => i.contractId == c.id);
    final party = _store.party(c.partyId);
    final units = [
      for (final id in c.unitIds)
        if (_store.unit(id) case final u?) UnitRef(id: u.id, code: u.code, kind: u.kind, keyNumber: u.keyNumber),
    ]..sort((a, b) => a.code.compareTo(b.code));
    return ContractRecord(
      id: c.id,
      fileId: c.fileId,
      topicId: c.topicId,
      parentId: c.parentId,
      kind: c.kind,
      subject: c.subject,
      activity: c.activity,
      signedOn: c.signedOn,
      startsOn: c.startsOn,
      endsOn: c.endsOn,
      dateNote: c.dateNote,
      areaInner: c.areaInner,
      areaOuter: c.areaOuter,
      areaNote: c.areaNote,
      status: c.status,
      notes: c.notes,
      party: party == null ? null : PartyRef(id: party.id, name: party.name),
      units: units,
      itemCount: own.length,
      taskCount: _store.tasks.where((t) => t.contractId == c.id).length,
      childCount: _store.childrenOf(c.id).length,
      annexNo: c.annexNo,
      openItemCount: own.where((i) => !i.isResolved).length,
    );
  }

  RegisterContract _registerContract(DemoContract c) {
    final party = _store.party(c.partyId);
    final units = [
      for (final id in c.unitIds)
        if (_store.unit(id) case final u?) RegisterUnit(code: u.code, keyNumber: u.keyNumber),
    ]..sort((a, b) => a.code.compareTo(b.code));
    return RegisterContract(
      id: c.id,
      parentId: c.parentId,
      kind: c.kind,
      subject: c.subject,
      annexNo: c.annexNo,
      activity: c.activity,
      signedOn: c.signedOn,
      startsOn: c.startsOn,
      endsOn: c.endsOn,
      dateNote: c.dateNote,
      areaInner: c.areaInner,
      areaOuter: c.areaOuter,
      areaNote: c.areaNote,
      notes: c.notes,
      partyId: party?.id,
      partyName: party?.name,
      brand: _store.topic(c.topicId)?.name,
      units: units,
      createdAt: c.createdAt,
    );
  }

  static ContractItem _item(DemoItem i) => ContractItem(
        id: i.id,
        kind: i.kind,
        contractId: i.contractId,
        partyId: i.partyId,
        label: i.label,
        detail: i.detail,
        needsSignature: i.needsSignature,
        needsStamp: i.needsStamp,
        side: i.side,
        isResolved: i.isResolved,
        createdAt: i.createdAt,
      );

  static Map<String, Object?> _itemMap(DemoItem i) => {'label': i.label, 'contract_id': i.contractId};

  static Map<String, Object?> _rowMap(DemoContract c) =>
      {'kind': c.kind.name, 'annex_no': c.annexNo, 'subject': c.subject};

  /// Item actions go into the history of the item's contract, or for a
  /// tenant's document, of every main contract of that tenant.
  void _logItem(DemoItem item, String action, {Object? oldValue, Object? newValue}) {
    final targets = item.contractId != null
        ? [?_store.contract(item.contractId)]
        : [
            for (final c in _store.contracts)
              if (c.parentId == null && _store.effective(c).partyId == item.partyId) c,
          ];
    for (final target in targets) {
      _store.logContract(target, action, oldValue: oldValue, newValue: newValue);
    }
  }

  void _logUnits(DemoContract c, List<String> before, List<String> after) {
    for (final id in after.where((u) => !before.contains(u))) {
      _store.logContract(c, 'units_changed', newValue: {'code': _store.unit(id)?.code});
    }
    for (final id in before.where((u) => !after.contains(u))) {
      _store.logContract(c, 'units_changed', oldValue: {'code': _store.unit(id)?.code});
    }
  }

  /// The brand of the newest contract in force that holds [unitId].
  String? _currentBrand(String unitId) {
    final holding = [
      for (final c in _store.contracts)
        if (c.parentId == null &&
            c.kind != ContractKind.annex &&
            _store.listStatus(c) != 'terminated' &&
            _store.listStatus(c) != 'expired' &&
            _store.effective(c).unitIds.contains(unitId))
          c,
    ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return holding.isEmpty ? null : _store.topic(holding.first.topicId)?.name;
  }

  /// From [start] to [end], end day included, in whole months.
  static int _months(DateTime start, DateTime end) {
    final after = end.add(const Duration(days: 1));
    var months = (after.year - start.year) * 12 + after.month - start.month;
    if (after.day < start.day) months--;
    return months;
  }
}
