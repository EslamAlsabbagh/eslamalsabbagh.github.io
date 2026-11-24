import 'package:equatable/equatable.dart';

import '../../../core/domain/contract_kind.dart';
import '../../../core/domain/contract_list_status.dart';
import 'contract_item.dart';

/// Everything the exported register needs about a set of main contracts
/// (`ContractsRepository.fetchRegister`): their `contract_list` values, the
/// contracts' own rows (the mains, their annexes and storage contracts, and
/// the storage contracts' annexes), the end-date status of every main and
/// storage contract, the open checklist items and the open follow-ups. RLS
/// decided what is in it.
class ContractRegisterData extends Equatable {
  const ContractRegisterData({
    required this.mains,
    required this.contracts,
    this.ends = const {},
    required this.items,
    required this.followUps,
  });

  /// `contract_list` values, by main contract id.
  final Map<String, RegisterMain> mains;

  /// Own rows, by id.
  final Map<String, RegisterContract> contracts;

  /// `contract_end_status`, by contract id: every main and storage contract
  /// (a storage contract under a lease included).
  final Map<String, RegisterEnd> ends;

  /// Open items only: `missing` on any of [contracts], `document` on their
  /// parties.
  final List<ContractItem> items;

  /// Open follow-up tasks, oldest first.
  final List<RegisterFollowUp> followUps;

  @override
  List<Object?> get props => [mains, contracts, ends, items, followUps];
}

/// A main contract's season and termination, from `contract_list`.
class RegisterMain extends Equatable {
  const RegisterMain({
    required this.id,
    required this.season,
    required this.terminatedOn,
    required this.terminationReason,
  });

  factory RegisterMain.fromRow(Map<String, dynamic> row) => RegisterMain(
        id: row['id'] as String,
        season: row['season'] as int?,
        terminatedOn: _date(row['terminated_on']),
        terminationReason: (row['termination_reason'] as String? ?? '').trim(),
      );

  /// PostgREST select for `contract_list`.
  static const String select = 'id, season, terminated_on, termination_reason';

  final String id;

  /// The signing year; null for an undated contract.
  final int? season;
  final DateTime? terminatedOn;
  final String terminationReason;

  @override
  List<Object?> get props => [id, season, terminatedOn, terminationReason];
}

/// A main or storage contract's end-date status on the Cairo date, from
/// `contract_end_status` (contract_list's rule, kept in the database).
class RegisterEnd extends Equatable {
  const RegisterEnd({required this.id, required this.listStatus, this.endsOnAnnexNo});

  factory RegisterEnd.fromRow(Map<String, dynamic> row) => RegisterEnd(
        id: row['id'] as String,
        listStatus: ContractListStatus.fromDb(row['list_status'] as String),
        endsOnAnnexNo: row['ends_on_annex_no'] as int?,
      );

  /// PostgREST select for `contract_end_status`.
  static const String select = 'id, list_status, ends_on_annex_no';

  final String id;
  final ContractListStatus listStatus;

  /// The annex that set the effective end date; null when the contract's own.
  final int? endsOnAnnexNo;

  @override
  List<Object?> get props => [id, listStatus, endsOnAnnexNo];
}

/// One contract's own row, as signed (not its effective values).
class RegisterContract extends Equatable {
  const RegisterContract({
    required this.id,
    required this.parentId,
    required this.kind,
    required this.subject,
    required this.annexNo,
    required this.activity,
    required this.signedOn,
    required this.startsOn,
    required this.endsOn,
    required this.dateNote,
    required this.areaInner,
    required this.areaOuter,
    required this.areaNote,
    required this.notes,
    required this.partyId,
    required this.partyName,
    required this.brand,
    required this.units,
    required this.createdAt,
  });

  factory RegisterContract.fromRow(Map<String, dynamic> row) {
    String text(String key) => (row[key] as String? ?? '').trim();
    final party = row['party'] as Map<String, dynamic>?;
    final topic = row['topic'] as Map<String, dynamic>?;
    final units = [
      for (final link in row['contract_units'] as List<dynamic>? ?? const [])
        if ((link as Map<String, dynamic>)['unit'] case final Map<String, dynamic> unit)
          RegisterUnit(code: unit['code'] as String, keyNumber: unit['key_number'] as String?),
    ]..sort((a, b) => a.code.compareTo(b.code));
    return RegisterContract(
      id: row['id'] as String,
      parentId: row['parent_id'] as String?,
      kind: ContractKind.fromDb(row['kind'] as String),
      subject: text('subject'),
      annexNo: row['annex_no'] as int?,
      activity: text('activity'),
      signedOn: _date(row['signed_on']),
      startsOn: _date(row['starts_on']),
      endsOn: _date(row['ends_on']),
      dateNote: text('date_note'),
      areaInner: (row['area_inner'] as num?)?.toDouble(),
      areaOuter: (row['area_outer'] as num?)?.toDouble(),
      areaNote: text('area_note'),
      notes: text('notes'),
      partyId: party?['id'] as String?,
      partyName: (party?['name'] as String?)?.trim(),
      brand: (topic?['name'] as String?)?.trim(),
      units: units,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  /// PostgREST select for `contracts`. Each embed has one foreign key to
  /// follow, so none needs a hint.
  static const String select = 'id, parent_id, kind, subject, annex_no, activity, signed_on, starts_on, ends_on, '
      'date_note, area_inner, area_outer, area_note, notes, created_at, party:parties(id, name), '
      'topic:topics(name), contract_units(unit:units(code, key_number))';

  final String id;
  final String? parentId;
  final ContractKind kind;
  final String subject;
  final int? annexNo;
  final String activity;
  final DateTime? signedOn;

  /// Empty means the same as [signedOn].
  final DateTime? startsOn;
  final DateTime? endsOn;
  final String dateNote;
  final double? areaInner;
  final double? areaOuter;
  final String areaNote;
  final String notes;

  /// Null on an annex that doesn't transfer the contract.
  final String? partyId;
  final String? partyName;

  /// The topic's name; null for an annex, or a contract without a brand.
  final String? brand;

  /// The contract's own units, by code. On an annex, the units it sets.
  final List<RegisterUnit> units;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        parentId,
        kind,
        subject,
        annexNo,
        activity,
        signedOn,
        startsOn,
        endsOn,
        dateNote,
        areaInner,
        areaOuter,
        areaNote,
        notes,
        partyId,
        partyName,
        brand,
        units,
        createdAt,
      ];
}

class RegisterUnit extends Equatable {
  const RegisterUnit({required this.code, this.keyNumber});

  final String code;

  /// A storage unit's key («مفتاح ٣٠٤»).
  final String? keyNumber;

  @override
  List<Object?> get props => [code, keyNumber];
}

/// An open follow-up task on a contract.
class RegisterFollowUp extends Equatable {
  const RegisterFollowUp({required this.contractId, required this.title});

  factory RegisterFollowUp.fromRow(Map<String, dynamic> row) =>
      RegisterFollowUp(contractId: row['contract_id'] as String, title: (row['title'] as String).trim());

  final String contractId;
  final String title;

  @override
  List<Object?> get props => [contractId, title];
}

DateTime? _date(Object? value) => value == null ? null : DateTime.parse(value as String);
