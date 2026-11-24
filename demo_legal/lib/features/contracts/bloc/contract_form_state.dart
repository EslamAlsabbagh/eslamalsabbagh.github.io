part of 'contract_form_bloc.dart';

/// The lease a storage contract hangs under, as the «مرتبط بعقد» field
/// shows it.
class LeaseRef extends Equatable {
  const LeaseRef({required this.id, required this.brand, required this.party});

  final String id;

  /// The lease's brand name; null when the brand is hidden.
  final String? brand;
  final PartyRef? party;

  @override
  List<Object?> get props => [id, brand, party];
}

/// A new storage contract started from a lease's drawer: «+ إضافة عقد
/// مخزن», or «تجديد للموسم التالي» with the storage contract it renews.
/// The kind and «مرتبط بعقد» are then fixed.
class StoragePreset extends Equatable {
  const StoragePreset({required this.fileId, required this.leaseId, this.renewing});

  final String fileId;
  final String leaseId;

  /// The storage contract to copy, one year on.
  final ContractRecord? renewing;

  @override
  List<Object?> get props => [fileId, leaseId, renewing];
}

/// Everything the contract form holds. Areas are kept as typed, so a
/// half-typed number isn't lost; [ContractFormBloc] parses them.
class ContractDraft extends Equatable {
  const ContractDraft({
    required this.kind,
    required this.fileId,
    this.topic,
    this.party,
    this.units = const [],
    this.lease,
    this.subject = '',
    this.activity = '',
    this.signedOn,
    this.startsOn,
    this.endsOn,
    this.endAsText = false,
    this.dateNote = '',
    this.areaAsText = false,
    this.areaInner = '',
    this.areaOuter = '',
    this.areaNote = '',
    this.notes = '',
  });

  final ContractKind kind;
  final String? fileId;

  /// The brand (a topic of [fileId]).
  final TaskTopic? topic;
  final PartyRef? party;
  final List<UnitRef> units;

  /// «مرتبط بعقد»: storage contracts only.
  final LeaseRef? lease;
  final String subject;
  final String activity;
  final DateTime? signedOn;
  final DateTime? startsOn;
  final DateTime? endsOn;

  /// «لا يوجد تاريخ نهاية محدد»: [dateNote] instead of [endsOn].
  final bool endAsText;
  final String dateNote;

  /// «المساحة لا تُكتب كرقم»: [areaNote] instead of the two areas.
  final bool areaAsText;
  final String areaInner;
  final String areaOuter;
  final String areaNote;

  final String notes;

  ContractDraft copyWith({
    ContractKind? kind,
    String? Function()? fileId,
    TaskTopic? Function()? topic,
    PartyRef? Function()? party,
    List<UnitRef>? units,
    LeaseRef? Function()? lease,
    String? subject,
    String? activity,
    DateTime? Function()? signedOn,
    DateTime? Function()? startsOn,
    DateTime? Function()? endsOn,
    bool? endAsText,
    String? dateNote,
    bool? areaAsText,
    String? areaInner,
    String? areaOuter,
    String? areaNote,
    String? notes,
  }) =>
      ContractDraft(
        kind: kind ?? this.kind,
        fileId: fileId == null ? this.fileId : fileId(),
        topic: topic == null ? this.topic : topic(),
        party: party == null ? this.party : party(),
        units: units ?? this.units,
        lease: lease == null ? this.lease : lease(),
        subject: subject ?? this.subject,
        activity: activity ?? this.activity,
        signedOn: signedOn == null ? this.signedOn : signedOn(),
        startsOn: startsOn == null ? this.startsOn : startsOn(),
        endsOn: endsOn == null ? this.endsOn : endsOn(),
        endAsText: endAsText ?? this.endAsText,
        dateNote: dateNote ?? this.dateNote,
        areaAsText: areaAsText ?? this.areaAsText,
        areaInner: areaInner ?? this.areaInner,
        areaOuter: areaOuter ?? this.areaOuter,
        areaNote: areaNote ?? this.areaNote,
        notes: notes ?? this.notes,
      );

  @override
  List<Object?> get props => [
        kind,
        fileId,
        topic,
        party,
        units,
        lease,
        subject,
        activity,
        signedOn,
        startsOn,
        endsOn,
        endAsText,
        dateNote,
        areaAsText,
        areaInner,
        areaOuter,
        areaNote,
        notes,
      ];
}

enum ContractFormStatus { editing, saving, saved }

class ContractFormState extends Equatable {
  const ContractFormState({
    required this.draft,
    this.status = ContractFormStatus.editing,
    this.failure,
    this.savedId,
  });

  final ContractDraft draft;
  final ContractFormStatus status;
  final ContractSaveFailure? failure;

  /// The saved contract's id, once [status] is saved.
  final String? savedId;

  bool get busy => status != ContractFormStatus.editing;

  ContractFormState copyWith({
    ContractDraft? draft,
    ContractFormStatus? status,
    ContractSaveFailure? Function()? failure,
    String? savedId,
  }) =>
      ContractFormState(
        draft: draft ?? this.draft,
        status: status ?? this.status,
        failure: failure == null ? this.failure : failure(),
        savedId: savedId ?? this.savedId,
      );

  @override
  List<Object?> get props => [draft, status, failure, savedId];
}
