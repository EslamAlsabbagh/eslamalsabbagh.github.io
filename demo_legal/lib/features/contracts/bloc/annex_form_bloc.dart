import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/contract_kind.dart';
import '../../../core/domain/unit_kind.dart';
import '../../../core/format/app_formats.dart';
import '../../../core/validation/contract_text.dart';
import '../data/contract_details.dart';
import '../data/contract_record.dart';
import '../data/contract_refs.dart';
import '../data/contract_save_failure.dart';
import '../data/contracts_repository.dart';
import 'contract_lookups.dart';

/// What an annex may change (DESIGN_SPEC §4 "Annex form" → «ما الذي يغيّره
/// الملحق؟»).
enum AnnexChange { ends, area, party, units }

enum AnnexTextField { number, subject, notes, areaInner, areaOuter }

/// Everything the annex form holds. Every value field starts filled (with
/// the annex's own value, or the contract's effective one), and the toggles
/// in [changes] decide what is saved, so a toggle turned off and on again
/// keeps what was there.
class AnnexDraft extends Equatable {
  const AnnexDraft({
    required this.number,
    this.subject = '',
    this.signedOn,
    this.notes = '',
    this.changes = const {},
    this.endsOn,
    this.areaInner = '',
    this.areaOuter = '',
    this.party,
    this.units = const [],
  });

  /// As typed.
  final String number;
  final String subject;
  final DateTime? signedOn;
  final String notes;
  final Set<AnnexChange> changes;
  final DateTime? endsOn;

  /// As typed; parsed with `parseArea`.
  final String areaInner;
  final String areaOuter;
  final PartyRef? party;
  final List<UnitRef> units;

  AnnexDraft copyWith({
    String? number,
    String? subject,
    DateTime? Function()? signedOn,
    String? notes,
    Set<AnnexChange>? changes,
    DateTime? Function()? endsOn,
    String? areaInner,
    String? areaOuter,
    PartyRef? Function()? party,
    List<UnitRef>? units,
  }) =>
      AnnexDraft(
        number: number ?? this.number,
        subject: subject ?? this.subject,
        signedOn: signedOn == null ? this.signedOn : signedOn(),
        notes: notes ?? this.notes,
        changes: changes ?? this.changes,
        endsOn: endsOn == null ? this.endsOn : endsOn(),
        areaInner: areaInner ?? this.areaInner,
        areaOuter: areaOuter ?? this.areaOuter,
        party: party == null ? this.party : party(),
        units: units ?? this.units,
      );

  @override
  List<Object?> get props => [number, subject, signedOn, notes, changes, endsOn, areaInner, areaOuter, party, units];
}

enum AnnexFormStatus { editing, saving, saved, deleting, deleted }

class AnnexFormState extends Equatable {
  const AnnexFormState({
    required this.draft,
    this.status = AnnexFormStatus.editing,
    this.failure,
    this.deleteFailure,
    this.savedId,
  });

  final AnnexDraft draft;
  final AnnexFormStatus status;
  final ContractSaveFailure? failure;

  /// «حذف الملحق» was refused with this.
  final ContractSaveFailure? deleteFailure;

  /// The saved annex's id, once [status] is saved.
  final String? savedId;

  bool get busy => status != AnnexFormStatus.editing;

  AnnexFormState copyWith({
    AnnexDraft? draft,
    AnnexFormStatus? status,
    ContractSaveFailure? Function()? failure,
    ContractSaveFailure? Function()? deleteFailure,
    String? savedId,
  }) =>
      AnnexFormState(
        draft: draft ?? this.draft,
        status: status ?? this.status,
        failure: failure == null ? this.failure : failure(),
        deleteFailure: deleteFailure == null ? this.deleteFailure : deleteFailure(),
        savedId: savedId ?? this.savedId,
      );

  @override
  List<Object?> get props => [draft, status, failure, deleteFailure, savedId];
}

sealed class AnnexFormEvent extends Equatable {
  const AnnexFormEvent();

  @override
  List<Object?> get props => [];
}

final class AnnexFormTextChanged extends AnnexFormEvent {
  const AnnexFormTextChanged(this.field, this.text);

  final AnnexTextField field;
  final String text;

  @override
  List<Object?> get props => [field, text];
}

final class AnnexFormSignedChanged extends AnnexFormEvent {
  const AnnexFormSignedChanged(this.date);

  final DateTime? date;

  @override
  List<Object?> get props => [date];
}

final class AnnexFormEndsChanged extends AnnexFormEvent {
  const AnnexFormEndsChanged(this.date);

  final DateTime? date;

  @override
  List<Object?> get props => [date];
}

final class AnnexFormChangeToggled extends AnnexFormEvent {
  const AnnexFormChangeToggled(this.change);

  final AnnexChange change;

  @override
  List<Object?> get props => [change];
}

final class AnnexFormPartyPicked extends AnnexFormEvent {
  const AnnexFormPartyPicked(this.party);

  final PartyRef? party;

  @override
  List<Object?> get props => [party];
}

final class AnnexFormUnitsChanged extends AnnexFormEvent {
  const AnnexFormUnitsChanged(this.units);

  final List<UnitRef> units;

  @override
  List<Object?> get props => [units];
}

final class AnnexFormSubmitted extends AnnexFormEvent {
  const AnnexFormSubmitted();
}

/// «حذف الملحق», after its confirmation.
final class AnnexFormDeleteConfirmed extends AnnexFormEvent {
  const AnnexFormDeleteConfirmed();
}

/// The annex form (DESIGN_SPEC §4 "Annex form"): a new annex under
/// [parent], or an edit of [annex]. The save is one `save_annex` call; the
/// tenant and units fields ask through it ([ContractLookups]).
class AnnexFormBloc extends Bloc<AnnexFormEvent, AnnexFormState> with ContractLookups {
  AnnexFormBloc({
    required this.parent,
    required ContractRecord parentRecord,
    required List<ContractRecord> annexes,
    required this._repository,
    this.annex,
  }) : super(AnnexFormState(draft: _draft(parent, parentRecord, annexes, annex))) {
    initialDraft = state.draft;
    on<AnnexFormTextChanged>(_onTextChanged);
    on<AnnexFormSignedChanged>((event, emit) => _edit(emit, state.draft.copyWith(signedOn: () => event.date)));
    on<AnnexFormEndsChanged>((event, emit) => _edit(emit, state.draft.copyWith(endsOn: () => event.date)));
    on<AnnexFormChangeToggled>(_onChangeToggled);
    on<AnnexFormPartyPicked>((event, emit) => _edit(emit, state.draft.copyWith(party: () => event.party)));
    on<AnnexFormUnitsChanged>((event, emit) => _edit(emit, state.draft.copyWith(units: event.units)));
    on<AnnexFormSubmitted>(_onSubmitted);
    on<AnnexFormDeleteConfirmed>(_onDeleteConfirmed);
  }

  /// The main contract, with its effective values.
  final ContractDetails parent;

  /// The annex being edited; null for a new one.
  final ContractRecord? annex;

  final ContractsRepository _repository;

  /// The draft as the form opened, for [isDirty].
  late final AnnexDraft initialDraft;

  bool get isEditing => annex != null;

  bool get isDirty => state.draft != initialDraft;

  /// «حذف الملحق» shows: an annex with nothing hanging on it, until the
  /// server says otherwise.
  bool get canDelete => (annex?.canDelete ?? false) && state.deleteFailure != ContractSaveFailure.notEmpty;

  static AnnexDraft _draft(
    ContractDetails parent,
    ContractRecord parentRecord,
    List<ContractRecord> annexes,
    ContractRecord? annex,
  ) {
    // The contract's units now: the annex that set them, or its own.
    final unitsBy = annexes.where((a) => a.annexNo != null && a.annexNo == parent.unitsAnnexNo).firstOrNull;
    final effectiveUnits = (unitsBy ?? parentRecord).units;
    final partyId = parent.partyId;
    final partyName = parent.partyName;
    final effectiveParty = partyId == null || partyName == null ? null : PartyRef(id: partyId, name: partyName);

    if (annex == null) {
      final numbers = [for (final a in annexes) ?a.annexNo];
      final next = numbers.isEmpty ? 1 : numbers.reduce((a, b) => a > b ? a : b) + 1;
      return AnnexDraft(
        number: AppFormats.number(next),
        endsOn: parent.endsOn,
        areaInner: _areaText(parent.areaInner),
        areaOuter: _areaText(parent.areaOuter),
        party: effectiveParty,
        units: effectiveUnits,
      );
    }
    final ownArea = annex.areaInner != null || annex.areaOuter != null;
    return AnnexDraft(
      number: annex.annexNo == null ? '' : AppFormats.number(annex.annexNo!),
      subject: annex.subject,
      signedOn: annex.signedOn,
      notes: annex.notes,
      changes: {
        if (annex.endsOn != null) AnnexChange.ends,
        if (ownArea) AnnexChange.area,
        if (annex.party != null) AnnexChange.party,
        if (annex.units.isNotEmpty) AnnexChange.units,
      },
      endsOn: annex.endsOn ?? parent.endsOn,
      areaInner: _areaText(ownArea ? annex.areaInner : parent.areaInner),
      areaOuter: _areaText(ownArea ? annex.areaOuter : parent.areaOuter),
      party: annex.party ?? effectiveParty,
      units: annex.units.isNotEmpty ? annex.units : effectiveUnits,
    );
  }

  /// `120.5` as «120.5», `120.0` as «120».
  static String _areaText(double? area) {
    if (area == null) return '';
    return area == area.truncateToDouble() ? area.toInt().toString() : area.toString();
  }

  // Lookups --------------------------------------------------------------------------------------------------

  @override
  ContractsRepository get lookupRepository => _repository;

  @override
  String? get lookupFileId => parent.fileId;

  /// A storage contract's annex lists storage units only.
  @override
  List<UnitKind>? get lookupUnitKinds => parent.kind == ContractKind.storage ? const [UnitKind.storage] : null;

  // Validation -------------------------------------------------------------------------------------------------

  bool get numberValid => parseAnnexNo(state.draft.number) != null;

  bool areaValid(String text) => parseArea(text).valid;

  /// Each change that is on has its value: a date, at least one area (and
  /// both numbers), a tenant, a unit.
  bool get changesValid {
    final draft = state.draft;
    final c = draft.changes;
    final inner = parseArea(draft.areaInner);
    final outer = parseArea(draft.areaOuter);
    return (!c.contains(AnnexChange.ends) || draft.endsOn != null) &&
        (!c.contains(AnnexChange.area) || (inner.valid && outer.valid && (inner.value != null || outer.value != null))) &&
        (!c.contains(AnnexChange.party) || draft.party != null) &&
        (!c.contains(AnnexChange.units) || draft.units.isNotEmpty);
  }

  bool get canSave {
    final draft = state.draft;
    return !state.busy &&
        numberValid &&
        ContractText.isFilled(draft.subject, ContractText.subjectMax) &&
        changesValid &&
        (!isEditing || isDirty);
  }

  // Events -----------------------------------------------------------------------------------------------------

  void _edit(Emitter<AnnexFormState> emit, AnnexDraft draft) {
    if (state.busy) return;
    emit(state.copyWith(draft: draft, failure: () => null));
  }

  void _onTextChanged(AnnexFormTextChanged event, Emitter<AnnexFormState> emit) {
    final draft = state.draft;
    final text = event.text;
    _edit(
      emit,
      switch (event.field) {
        AnnexTextField.number => draft.copyWith(number: text),
        AnnexTextField.subject => draft.copyWith(subject: text),
        AnnexTextField.notes => draft.copyWith(notes: text),
        AnnexTextField.areaInner => draft.copyWith(areaInner: text),
        AnnexTextField.areaOuter => draft.copyWith(areaOuter: text),
      },
    );
  }

  void _onChangeToggled(AnnexFormChangeToggled event, Emitter<AnnexFormState> emit) {
    final changes = {...state.draft.changes};
    if (!changes.remove(event.change)) changes.add(event.change);
    _edit(emit, state.draft.copyWith(changes: changes));
  }

  Future<void> _onSubmitted(AnnexFormSubmitted event, Emitter<AnnexFormState> emit) async {
    if (!canSave) return;
    final draft = state.draft;
    final c = draft.changes;
    final area = c.contains(AnnexChange.area);
    emit(state.copyWith(status: AnnexFormStatus.saving, failure: () => null));
    final input = AnnexInput(
      id: annex?.id,
      parentId: parent.id,
      annexNo: parseAnnexNo(draft.number)!,
      subject: draft.subject.trim(),
      signedOn: draft.signedOn,
      notes: draft.notes.trim(),
      endsOn: c.contains(AnnexChange.ends) ? draft.endsOn : null,
      areaInner: area ? parseArea(draft.areaInner).value : null,
      areaOuter: area ? parseArea(draft.areaOuter).value : null,
      partyId: c.contains(AnnexChange.party) ? draft.party?.id : null,
      unitIds: c.contains(AnnexChange.units) ? [for (final unit in draft.units) unit.id] : const [],
    );
    try {
      final id = await _repository.saveAnnex(input);
      emit(state.copyWith(status: AnnexFormStatus.saved, savedId: id));
    } on ContractSaveException catch (error) {
      log('Saving the annex failed: ${error.failure}', name: 'contracts');
      emit(state.copyWith(status: AnnexFormStatus.editing, failure: () => error.failure));
    }
  }

  Future<void> _onDeleteConfirmed(AnnexFormDeleteConfirmed event, Emitter<AnnexFormState> emit) async {
    final annex = this.annex;
    if (annex == null || state.busy) return;
    emit(state.copyWith(status: AnnexFormStatus.deleting, failure: () => null, deleteFailure: () => null));
    try {
      await _repository.delete(annex.id);
      emit(state.copyWith(status: AnnexFormStatus.deleted, savedId: annex.id));
    } on ContractSaveException catch (error) {
      emit(state.copyWith(status: AnnexFormStatus.editing, deleteFailure: () => error.failure));
    }
  }
}
