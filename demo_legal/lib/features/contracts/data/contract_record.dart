import 'package:equatable/equatable.dart';

import '../../../core/domain/contract_kind.dart';
import '../../../core/domain/contract_status.dart';
import '../../../core/domain/unit_kind.dart';
import 'contract_refs.dart';

/// A contract's own row (not its effective values), for the form, plus
/// what hangs on it, for «حذف المسودة».
///
/// The form edits the contract's own values: an annex that moved the end
/// date stays in force over whatever is typed here (ADR-0013).
class ContractRecord extends Equatable {
  const ContractRecord({
    required this.id,
    required this.fileId,
    required this.topicId,
    required this.parentId,
    required this.kind,
    required this.subject,
    required this.activity,
    required this.signedOn,
    required this.startsOn,
    required this.endsOn,
    required this.dateNote,
    required this.areaInner,
    required this.areaOuter,
    required this.areaNote,
    required this.status,
    required this.notes,
    required this.party,
    required this.units,
    required this.itemCount,
    required this.taskCount,
    required this.childCount,
    this.annexNo,
    this.openItemCount = 0,
  });

  /// Builds from a row selected with [ContractRecord.select], and the number
  /// of rows under it (read separately: a self-embed would be ambiguous).
  factory ContractRecord.fromRow(Map<String, dynamic> row, {required int childCount}) {
    DateTime? date(String key) {
      final value = row[key] as String?;
      return value == null ? null : DateTime.parse(value);
    }

    String text(String key) => (row[key] as String? ?? '').trim();

    int count(String key) {
      final embedded = row[key] as List<dynamic>? ?? const [];
      return embedded.isEmpty ? 0 : (embedded.first as Map<String, dynamic>)['count'] as int;
    }

    final items = [for (final item in row['contract_items'] as List<dynamic>? ?? const []) item as Map<String, dynamic>];

    final party = row['party'] as Map<String, dynamic>?;
    final units = [
      for (final link in row['contract_units'] as List<dynamic>? ?? const [])
        if ((link as Map<String, dynamic>)['unit'] case final Map<String, dynamic> unit)
          UnitRef(
            id: unit['id'] as String,
            code: unit['code'] as String,
            kind: UnitKind.fromDb(unit['kind'] as String),
            keyNumber: unit['key_number'] as String?,
          ),
    ]..sort((a, b) => a.code.compareTo(b.code));

    return ContractRecord(
      id: row['id'] as String,
      fileId: row['file_id'] as String,
      topicId: row['topic_id'] as String?,
      parentId: row['parent_id'] as String?,
      kind: ContractKind.fromDb(row['kind'] as String),
      subject: text('subject'),
      activity: text('activity'),
      signedOn: date('signed_on'),
      startsOn: date('starts_on'),
      endsOn: date('ends_on'),
      dateNote: text('date_note'),
      areaInner: (row['area_inner'] as num?)?.toDouble(),
      areaOuter: (row['area_outer'] as num?)?.toDouble(),
      areaNote: text('area_note'),
      status: ContractStatus.fromDb(row['status'] as String),
      notes: text('notes'),
      party: party == null ? null : PartyRef(id: party['id'] as String, name: party['name'] as String),
      units: units,
      itemCount: items.length,
      taskCount: count('tasks'),
      childCount: childCount,
      annexNo: row['annex_no'] as int?,
      openItemCount: items.where((item) => item['is_resolved'] != true).length,
    );
  }

  /// PostgREST select for one `contracts` row. Each embed has one foreign
  /// key to follow, so none needs a hint. The checklist items come as their
  /// `is_resolved` only: a contract has a handful, and both counts come from
  /// the one embed.
  static const String select = 'id, file_id, topic_id, parent_id, kind, subject, annex_no, activity, signed_on, '
      'starts_on, ends_on, date_note, area_inner, area_outer, area_note, status, notes, party:parties(id, name), '
      'contract_units(unit:units(id, code, kind, key_number)), contract_items(is_resolved), tasks(count)';

  final String id;
  final String fileId;
  final String? topicId;

  /// The lease a storage contract hangs under.
  final String? parentId;
  final ContractKind kind;
  final String subject;
  final String activity;
  final DateTime? signedOn;

  /// Null means "the same as the signing date".
  final DateTime? startsOn;
  final DateTime? endsOn;
  final String dateNote;
  final double? areaInner;
  final double? areaOuter;
  final String areaNote;
  final ContractStatus status;
  final String notes;
  final PartyRef? party;

  /// The contract's own units, by code.
  final List<UnitRef> units;

  /// Checklist items on it, resolved ones included (the foreign key counts
  /// them all, as the topic delete counts closed tasks).
  final int itemCount;

  /// Tasks linked to it, closed ones included.
  final int taskCount;

  /// Annexes and storage contracts under it.
  final int childCount;

  /// An annex's number (ملحق ٢); null for any other kind.
  final int? annexNo;

  /// Its open missing items: an annex row's «n نواقص» badge.
  final int openItemCount;

  /// «حذف العقد»: an active contract with nothing hanging on it can be
  /// deleted (one made by mistake); anything else the foreign keys keep, and
  /// a terminated one stays as history.
  bool get canDelete => status == ContractStatus.active && itemCount == 0 && taskCount == 0 && childCount == 0;

  @override
  List<Object?> get props => [
        id,
        fileId,
        topicId,
        parentId,
        kind,
        subject,
        activity,
        signedOn,
        startsOn,
        endsOn,
        dateNote,
        areaInner,
        areaOuter,
        areaNote,
        status,
        notes,
        party,
        units,
        itemCount,
        taskCount,
        childCount,
        annexNo,
        openItemCount,
      ];
}

/// What the annex form saves (`save_annex`). [id] null creates under
/// [parentId]; an edit keeps the parent.
///
/// What the annex changes: a null [endsOn], [areaInner], [areaOuter] or
/// [partyId] changes nothing, and empty [unitIds] keep the contract's units.
class AnnexInput extends Equatable {
  const AnnexInput({
    required this.id,
    required this.parentId,
    required this.annexNo,
    required this.subject,
    required this.signedOn,
    required this.notes,
    required this.endsOn,
    required this.areaInner,
    required this.areaOuter,
    required this.partyId,
    required this.unitIds,
  });

  final String? id;
  final String parentId;
  final int annexNo;
  final String subject;
  final DateTime? signedOn;
  final String notes;
  final DateTime? endsOn;
  final double? areaInner;
  final double? areaOuter;
  final String? partyId;
  final List<String> unitIds;

  @override
  List<Object?> get props =>
      [id, parentId, annexNo, subject, signedOn, notes, endsOn, areaInner, areaOuter, partyId, unitIds];
}

/// What the contract form saves (`save_contract`). [id] null creates.
class ContractInput extends Equatable {
  const ContractInput({
    required this.id,
    required this.fileId,
    required this.kind,
    required this.parentId,
    required this.topicId,
    required this.partyId,
    required this.subject,
    required this.activity,
    required this.signedOn,
    required this.startsOn,
    required this.endsOn,
    required this.dateNote,
    required this.areaInner,
    required this.areaOuter,
    required this.areaNote,
    required this.notes,
    required this.unitIds,
  });

  final String? id;
  final String fileId;
  final ContractKind kind;
  final String? parentId;
  final String? topicId;
  final String? partyId;
  final String subject;
  final String activity;
  final DateTime? signedOn;
  final DateTime? startsOn;
  final DateTime? endsOn;
  final String dateNote;
  final double? areaInner;
  final double? areaOuter;
  final String areaNote;

  final String notes;
  final List<String> unitIds;

  @override
  List<Object?> get props => [
        id,
        fileId,
        kind,
        parentId,
        topicId,
        partyId,
        subject,
        activity,
        signedOn,
        startsOn,
        endsOn,
        dateNote,
        areaInner,
        areaOuter,
        areaNote,
        notes,
        unitIds,
      ];
}
