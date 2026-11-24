import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/contract_kind.dart';
import '../../../core/domain/unit_kind.dart';
import '../../../core/format/arabic_normalize.dart';
import '../../../core/format/calendar.dart';
import '../../../core/validation/contract_text.dart';
import '../../tasks/data/task_file.dart';
import '../../tasks/data/task_topic.dart';
import '../../tasks/data/tasks_repository.dart';
import '../data/contract_list_item.dart';
import '../data/contract_record.dart';
import '../data/contract_refs.dart';
import '../data/contract_save_failure.dart';
import '../data/contracts_repository.dart';
import 'contract_lookups.dart';

part 'contract_form_event.dart';
part 'contract_form_state.dart';

/// The contract form (DESIGN_SPEC §4 "Contract form"): a new contract of
/// one of four kinds, or an edit of an existing one's own values.
///
/// Built from the shell's loaded files and topics and the contracts list,
/// so opening it sends nothing. The suggest fields ask through it
/// ([suggestParties], [suggestUnits], [suggestValues]) and create records
/// through it ([createParty], [createUnits], [createTopic]); the save is
/// one `save_contract` call. An edit keeps the file, kind and linked lease
/// (written once) and the status (the drawer's).
class ContractFormBloc extends Bloc<ContractFormEvent, ContractFormState> with ContractLookups {
  ContractFormBloc({
    required this.files,
    required List<TaskTopic> topics,
    required List<ContractListItem> contracts,
    required String? initialFileId,
    required this.defaultSubjects,
    required this._repository,
    required this._tasksRepository,
    this.record,
    this.preset,
  })  : _topics = [...topics],
        _contracts = contracts,
        super(ContractFormState(
          draft: record != null
              ? _editDraft(record, topics, contracts)
              : preset != null
                  ? _presetDraft(preset, topics, contracts, defaultSubjects)
                  : _newDraft(files, initialFileId: initialFileId, subject: defaultSubjects[ContractKind.lease] ?? ''),
        )) {
    initialDraft = state.draft;
    on<ContractFormKindChanged>(_onKindChanged);
    on<ContractFormFileChanged>(_onFileChanged);
    on<ContractFormTopicPicked>((event, emit) => _edit(emit, state.draft.copyWith(topic: () => event.topic)));
    on<ContractFormTopicAdded>(_onTopicAdded);
    on<ContractFormPartyPicked>((event, emit) => _edit(emit, state.draft.copyWith(party: () => event.party)));
    on<ContractFormUnitsChanged>((event, emit) => _edit(emit, state.draft.copyWith(units: event.units)));
    on<ContractFormLeasePicked>(_onLeasePicked);
    on<ContractFormTextChanged>(_onTextChanged);
    on<ContractFormDateChanged>(_onDateChanged);
    on<ContractFormEndAsTextToggled>(
      (event, emit) => _edit(emit, state.draft.copyWith(endAsText: !state.draft.endAsText)),
    );
    on<ContractFormAreaAsTextToggled>(
      (event, emit) => _edit(emit, state.draft.copyWith(areaAsText: !state.draft.areaAsText)),
    );
    on<ContractFormSubmitted>(_onSubmitted);
  }

  /// The files the viewer sees (RLS: a lawyer's own files).
  final List<TaskFile> files;

  /// The contract being edited; null for a new one.
  final ContractRecord? record;

  /// A new storage contract started from the lease's drawer; null otherwise.
  final StoragePreset? preset;

  /// The kind chips are fixed: an edit, or a storage contract started from
  /// a lease.
  bool get kindLocked => isEditing || preset != null;

  /// «مرتبط بعقد» is fixed, for the same reasons.
  bool get leaseLocked => isEditing || preset != null;

  /// The subject each kind starts with («عقد ايجار وحدة»), from the
  /// strings; a subject still equal to the old kind's follows a kind change.
  final Map<ContractKind, String> defaultSubjects;

  final List<TaskTopic> _topics;
  final List<ContractListItem> _contracts;
  final ContractsRepository _repository;
  final TasksRepository _tasksRepository;

  /// The draft as the form opened, for [isDirty].
  late final ContractDraft initialDraft;

  bool get isEditing => record != null;

  bool get isDirty => state.draft != initialDraft;

  static ContractDraft _newDraft(List<TaskFile> files, {required String? initialFileId, required String subject}) {
    final fileId = files.any((f) => f.id == initialFileId) ? initialFileId : files.firstOrNull?.id;
    return ContractDraft(kind: ContractKind.lease, fileId: fileId, subject: subject);
  }

  static ContractDraft _editDraft(ContractRecord record, List<TaskTopic> topics, List<ContractListItem> contracts) {
    final topicId = record.topicId;
    final parentId = record.parentId;
    final parent = contracts.where((c) => c.id == parentId).firstOrNull;
    return ContractDraft(
      kind: record.kind,
      fileId: record.fileId,
      topic: topicId == null
          ? null
          : topics.where((t) => t.id == topicId).firstOrNull ?? TaskTopic(id: topicId, fileId: record.fileId, name: ''),
      party: record.party,
      units: record.units,
      lease: parentId == null ? null : _leaseRef(parent, parentId, topics),
      subject: record.subject,
      activity: record.activity,
      signedOn: record.signedOn,
      startsOn: record.startsOn,
      endsOn: record.endsOn,
      endAsText: record.endsOn == null && record.dateNote.isNotEmpty,
      dateNote: record.dateNote,
      areaAsText: record.areaInner == null && record.areaOuter == null && record.areaNote.isNotEmpty,
      areaInner: _areaText(record.areaInner),
      areaOuter: _areaText(record.areaOuter),
      areaNote: record.areaNote,
      notes: record.notes,
    );
  }

  /// A storage contract under [StoragePreset.leaseId]. A renewal copies the
  /// storage contract it renews, with every date one year on; otherwise the
  /// brand and tenant are the lease's, as picking the lease would fill them.
  static ContractDraft _presetDraft(
    StoragePreset preset,
    List<TaskTopic> topics,
    List<ContractListItem> contracts,
    Map<ContractKind, String> defaultSubjects,
  ) {
    final lease = contracts.where((c) => c.id == preset.leaseId).firstOrNull;
    final leaseRef = _leaseRef(lease, preset.leaseId, topics);
    final leaseTopic = topics.where((t) => t.id == lease?.topicId).firstOrNull;
    final from = preset.renewing;
    if (from == null) {
      return ContractDraft(
        kind: ContractKind.storage,
        fileId: preset.fileId,
        topic: leaseTopic,
        party: leaseRef.party,
        lease: leaseRef,
        subject: defaultSubjects[ContractKind.storage] ?? '',
      );
    }
    final copy = _editDraft(from, topics, contracts);
    DateTime? next(DateTime? date) => date == null ? null : addYear(date);
    return copy.copyWith(
      lease: () => leaseRef,
      topic: copy.topic == null ? () => leaseTopic : null,
      signedOn: () => next(from.signedOn),
      startsOn: () => next(from.startsOn),
      endsOn: () => next(from.endsOn),
    );
  }

  static LeaseRef _leaseRef(ContractListItem? lease, String id, List<TaskTopic> topics) {
    final partyId = lease?.partyId;
    final partyName = lease?.partyName;
    return LeaseRef(
      id: id,
      brand: topics.where((t) => t.id == lease?.topicId).firstOrNull?.name,
      party: partyId == null || partyName == null ? null : PartyRef(id: partyId, name: partyName),
    );
  }

  /// `120.5` as «120.5», `120.0` as «120».
  static String _areaText(double? area) {
    if (area == null) return '';
    return area == area.truncateToDouble() ? area.toInt().toString() : area.toString();
  }

  // Lists ----------------------------------------------------------------------------------------------------

  /// The brands of the draft's file, oldest first (made ones included).
  List<TaskTopic> get fileTopics => [
        for (final t in _topics)
          if (t.fileId == state.draft.fileId) t,
      ];

  /// The draft's file's leases in force or draft, for «مرتبط بعقد».
  List<LeaseRef> get fileLeases => [
        for (final c in _contracts)
          if (c.fileId == state.draft.fileId && c.kind == ContractKind.lease && !c.isTerminated)
            _leaseRef(c, c.id, _topics),
      ];

  /// The brands whose name contains [query] (normalized), exact first, then
  /// those starting with it; at most 5.
  List<TaskTopic> matchTopics(String query) => _match(fileTopics, query, (t) => [t.name]);

  /// The leases whose brand or tenant contains [query]; at most 5.
  List<LeaseRef> matchLeases(String query) =>
      _match(fileLeases, query, (l) => [l.brand ?? '', l.party?.name ?? '']);

  static List<T> _match<T>(List<T> items, String query, List<String> Function(T item) names) {
    final key = normalizeAr(query);
    if (key.isEmpty) return items.take(5).toList();
    int rank(T item) {
      final keys = names(item).map(normalizeAr);
      if (keys.any((k) => k == key)) return 0;
      if (keys.any((k) => k.startsWith(key))) return 1;
      return keys.any((k) => k.contains(key)) ? 2 : 3;
    }

    final ranked = [
      for (final (index, item) in items.indexed)
        if (rank(item) < 3) (rank(item), index, item),
    ]..sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2));
    return [for (final (_, _, item) in ranked.take(5)) item];
  }

  // Suggestions and records -----------------------------------------------------------------------------------

  @override
  ContractsRepository get lookupRepository => _repository;

  @override
  String? get lookupFileId => state.draft.fileId;

  /// Storage units only for a storage contract.
  @override
  List<UnitKind>? get lookupUnitKinds => state.draft.kind == ContractKind.storage ? const [UnitKind.storage] : null;

  /// A new brand (topic) in the draft's file, as «+ موضوع جديد» makes one.
  /// Throws `NameSaveException`.
  Future<TaskTopic> createTopic(String name) async {
    final fileId = state.draft.fileId!;
    final id = await _tasksRepository.createTopic(fileId, name);
    return TaskTopic(id: id, fileId: fileId, name: name);
  }

  /// «حذف عقد المخزن»: deletes [record] (a storage contract under a lease
  /// with nothing hanging on it). Throws [ContractSaveException]; the
  /// foreign keys refuse it if something was added since
  /// ([ContractSaveFailure.notEmpty]).
  Future<void> deleteRecord() => _repository.delete(record!.id);

  // Validation -------------------------------------------------------------------------------------------------

  /// An area box's text is a number (or blank); text mode skips them.
  bool areaValid(String text) => state.draft.areaAsText || parseArea(text).valid;

  /// The end date is on or after the start (or signing) date.
  bool get datesOrdered {
    final draft = state.draft;
    final ends = draft.endAsText ? null : draft.endsOn;
    final from = draft.startsOn ?? draft.signedOn;
    return ends == null || from == null || !ends.isBefore(from);
  }

  bool get canSave {
    final draft = state.draft;
    return !state.busy &&
        draft.fileId != null &&
        draft.party != null &&
        (draft.kind != ContractKind.lease || draft.topic != null) &&
        areaValid(draft.areaInner) &&
        areaValid(draft.areaOuter) &&
        datesOrdered &&
        (!isEditing || isDirty);
  }

  // Events -------------------------------------------------------------------------------------------------------

  void _edit(Emitter<ContractFormState> emit, ContractDraft draft) {
    if (state.busy) return;
    emit(state.copyWith(draft: draft, failure: () => null));
  }

  void _onKindChanged(ContractFormKindChanged event, Emitter<ContractFormState> emit) {
    final draft = state.draft;
    if (kindLocked || event.kind == draft.kind) return;
    final oldDefault = defaultSubjects[draft.kind] ?? '';
    final subject = draft.subject.trim().isEmpty || draft.subject == oldDefault
        ? defaultSubjects[event.kind] ?? ''
        : draft.subject;
    _edit(
      emit,
      draft.copyWith(
        kind: event.kind,
        subject: subject,
        lease: event.kind == ContractKind.storage ? null : () => null,
      ),
    );
  }

  void _onFileChanged(ContractFormFileChanged event, Emitter<ContractFormState> emit) {
    if (isEditing || preset != null || event.fileId == state.draft.fileId) return;
    _edit(
      emit,
      state.draft.copyWith(fileId: () => event.fileId, topic: () => null, units: const [], lease: () => null),
    );
  }

  void _onTopicAdded(ContractFormTopicAdded event, Emitter<ContractFormState> emit) {
    if (!_topics.contains(event.topic)) _topics.add(event.topic);
    _edit(emit, state.draft.copyWith(topic: () => event.topic));
  }

  /// A lease fills in its brand and tenant; clearing it leaves them.
  void _onLeasePicked(ContractFormLeasePicked event, Emitter<ContractFormState> emit) {
    final lease = event.lease;
    if (leaseLocked) return;
    final picked = _contracts.where((c) => c.id == lease?.id).firstOrNull;
    final topic = _topics.where((t) => t.id == picked?.topicId).firstOrNull;
    _edit(
      emit,
      state.draft.copyWith(
        lease: () => lease,
        topic: topic == null ? null : () => topic,
        party: lease?.party == null ? null : () => lease!.party,
      ),
    );
  }

  void _onTextChanged(ContractFormTextChanged event, Emitter<ContractFormState> emit) {
    final draft = state.draft;
    final text = event.text;
    _edit(
      emit,
      switch (event.field) {
        ContractTextField.subject => draft.copyWith(subject: text),
        ContractTextField.activity => draft.copyWith(activity: text),
        ContractTextField.dateNote => draft.copyWith(dateNote: text),
        ContractTextField.areaInner => draft.copyWith(areaInner: text),
        ContractTextField.areaOuter => draft.copyWith(areaOuter: text),
        ContractTextField.areaNote => draft.copyWith(areaNote: text),
        ContractTextField.notes => draft.copyWith(notes: text),
      },
    );
  }

  void _onDateChanged(ContractFormDateChanged event, Emitter<ContractFormState> emit) {
    final draft = state.draft;
    final date = event.date;
    _edit(
      emit,
      switch (event.field) {
        ContractDateField.signed => draft.copyWith(signedOn: () => date),
        ContractDateField.starts => draft.copyWith(startsOn: () => date),
        ContractDateField.ends => draft.copyWith(endsOn: () => date),
      },
    );
  }

  Future<void> _onSubmitted(ContractFormSubmitted event, Emitter<ContractFormState> emit) async {
    if (!canSave) return;
    final draft = state.draft;
    emit(state.copyWith(status: ContractFormStatus.saving, failure: () => null));
    final input = ContractInput(
      id: record?.id,
      fileId: draft.fileId!,
      kind: draft.kind,
      parentId: draft.kind == ContractKind.storage ? draft.lease?.id : null,
      topicId: draft.topic?.id,
      partyId: draft.party?.id,
      subject: draft.subject.trim(),
      activity: draft.activity.trim(),
      signedOn: draft.signedOn,
      startsOn: draft.startsOn,
      endsOn: draft.endAsText ? null : draft.endsOn,
      dateNote: draft.endAsText ? draft.dateNote.trim() : '',
      areaInner: draft.areaAsText ? null : parseArea(draft.areaInner).value,
      areaOuter: draft.areaAsText ? null : parseArea(draft.areaOuter).value,
      areaNote: draft.areaAsText ? draft.areaNote.trim() : '',
      notes: draft.notes.trim(),
      unitIds: [for (final unit in draft.units) unit.id],
    );
    try {
      final id = await _repository.saveContract(input);
      emit(state.copyWith(status: ContractFormStatus.saved, savedId: id));
    } on ContractSaveException catch (error) {
      log('Saving the contract failed: ${error.failure}', name: 'contracts');
      emit(state.copyWith(status: ContractFormStatus.editing, failure: () => error.failure));
    }
  }
}
