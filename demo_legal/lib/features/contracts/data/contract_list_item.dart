import 'package:equatable/equatable.dart';

import '../../../core/domain/contract_kind.dart';
import '../../../core/domain/contract_list_status.dart';

/// One row of the «العقود» list: a `contract_list` row, i.e. a main contract
/// with its values after its active annexes (ADR-0013).
///
/// The list status is computed by the database on the Cairo date; the app
/// never derives it from the clock. The brand and file names come from the
/// topics and files the shell already holds.
class ContractListItem extends Equatable {
  const ContractListItem({
    required this.id,
    required this.fileId,
    required this.topicId,
    required this.kind,
    required this.listStatus,
    required this.sortGroup,
    required this.endsOn,
    required this.dateNote,
    required this.partyName,
    this.partyId,
    required this.unitCodes,
    required this.season,
    required this.terminatedOn,
    required this.createdAt,
    required this.annexCount,
    required this.storageCount,
    required this.openItemCount,
    required this.openTaskCount,
  });

  /// Builds from a row selected with [ContractListItem.select].
  factory ContractListItem.fromRow(Map<String, dynamic> row) {
    DateTime? date(String key) {
      final value = row[key] as String?;
      return value == null ? null : DateTime.parse(value);
    }

    final dateNote = (row['date_note'] as String?)?.trim();
    return ContractListItem(
      id: row['id'] as String,
      fileId: row['file_id'] as String,
      topicId: row['topic_id'] as String?,
      kind: ContractKind.fromDb(row['kind'] as String),
      listStatus: ContractListStatus.fromDb(row['list_status'] as String),
      sortGroup: row['sort_group'] as int,
      endsOn: date('ends_on'),
      dateNote: dateNote == null || dateNote.isEmpty ? null : dateNote,
      partyId: row['party_id'] as String?,
      partyName: row['party_name'] as String?,
      unitCodes: (row['unit_codes'] as List<dynamic>? ?? const []).cast<String>(),
      season: row['season'] as int?,
      terminatedOn: date('terminated_on'),
      createdAt: DateTime.parse(row['created_at'] as String),
      annexCount: row['annex_count'] as int,
      storageCount: row['storage_count'] as int,
      openItemCount: row['open_item_count'] as int,
      openTaskCount: row['open_task_count'] as int,
    );
  }

  /// PostgREST select for `contract_list`.
  static const String select = 'id, file_id, topic_id, kind, list_status, sort_group, ends_on, date_note, '
      'party_id, party_name, unit_codes, season, terminated_on, created_at, '
      'annex_count, storage_count, open_item_count, open_task_count';

  final String id;
  final String fileId;

  /// The brand; null for a contract without one (a service contract).
  final String? topicId;
  final ContractKind kind;
  final ContractListStatus listStatus;

  /// 0 expired, 1 ending, 2 active, 4 terminated (3 was drafts).
  final int sortGroup;

  /// The effective end date (an active annex may move it). A calendar date.
  final DateTime? endsOn;

  /// Text in place of an end date («نهاية موسم صيف 2028»); null when blank.
  final String? dateNote;

  /// The effective tenant (an annex may transfer it); null when none is set.
  final String? partyName;

  /// Its id: picking a lease in the storage form's «مرتبط بعقد» fills the
  /// tenant in.
  final String? partyId;

  /// The effective unit codes, as written, ordered by their `code_key`.
  final List<String> unitCodes;

  /// The signing year; null for an undated contract.
  final int? season;
  final DateTime? terminatedOn;
  final DateTime createdAt;
  final int annexCount;

  /// Storage contracts linked to this one (a lease's).
  final int storageCount;

  /// Open checklist items on it, everything under it, and its tenant.
  final int openItemCount;

  /// Open follow-up tasks on it and everything under it.
  final int openTaskCount;

  bool get isTerminated => listStatus == ContractListStatus.terminated;

  @override
  List<Object?> get props => [
        id,
        fileId,
        topicId,
        kind,
        listStatus,
        sortGroup,
        endsOn,
        dateNote,
        partyId,
        partyName,
        unitCodes,
        season,
        terminatedOn,
        createdAt,
        annexCount,
        storageCount,
        openItemCount,
        openTaskCount,
      ];
}
