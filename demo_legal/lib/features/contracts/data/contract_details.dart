import 'package:equatable/equatable.dart';

import '../../../core/domain/contract_kind.dart';
import '../../../core/domain/contract_list_status.dart';
import '../../../core/domain/contract_status.dart';

/// A main contract for the drawer: one `contract_list` row with every column.
///
/// The values are effective ones, after the contract's active annexes, and
/// each `*AnnexNo` says which annex set its value (null: the contract's own),
/// for «(بموجب ملحق ٢)». The database decides both, and the list status on
/// the Cairo date (ADR-0013).
class ContractDetails extends Equatable {
  const ContractDetails({
    required this.id,
    required this.fileId,
    required this.topicId,
    required this.kind,
    required this.subject,
    required this.activity,
    required this.status,
    required this.listStatus,
    required this.signedOn,
    required this.startsOn,
    required this.endsOn,
    required this.dateNote,
    required this.areaInner,
    required this.areaOuter,
    required this.areaNote,
    required this.partyId,
    required this.partyName,
    required this.unitCodes,
    required this.terminatedOn,
    required this.terminationReason,
    required this.notes,
    required this.durationMonths,
    required this.daysUntilEnd,
    required this.annexCount,
    required this.storageCount,
    required this.openItemCount,
    required this.openTaskCount,
    this.endsOnAnnexNo,
    this.areaInnerAnnexNo,
    this.areaOuterAnnexNo,
    this.partyAnnexNo,
    this.unitsAnnexNo,
  });

  /// Builds from a row selected with [ContractDetails.select].
  factory ContractDetails.fromRow(Map<String, dynamic> row) {
    DateTime? date(String key) {
      final value = row[key] as String?;
      return value == null ? null : DateTime.parse(value);
    }

    String text(String key) => (row[key] as String? ?? '').trim();

    return ContractDetails(
      id: row['id'] as String,
      fileId: row['file_id'] as String,
      topicId: row['topic_id'] as String?,
      kind: ContractKind.fromDb(row['kind'] as String),
      subject: text('subject'),
      activity: text('activity'),
      status: ContractStatus.fromDb(row['status'] as String),
      listStatus: ContractListStatus.fromDb(row['list_status'] as String),
      signedOn: date('signed_on'),
      startsOn: date('starts_on'),
      endsOn: date('ends_on'),
      dateNote: text('date_note'),
      areaInner: (row['area_inner'] as num?)?.toDouble(),
      areaOuter: (row['area_outer'] as num?)?.toDouble(),
      areaNote: text('area_note'),
      partyId: row['party_id'] as String?,
      partyName: row['party_name'] as String?,
      unitCodes: (row['unit_codes'] as List<dynamic>? ?? const []).cast<String>(),
      terminatedOn: date('terminated_on'),
      terminationReason: text('termination_reason'),
      notes: text('notes'),
      durationMonths: row['duration_months'] as int?,
      daysUntilEnd: row['days_until_end'] as int?,
      annexCount: row['annex_count'] as int,
      storageCount: row['storage_count'] as int,
      openItemCount: row['open_item_count'] as int,
      openTaskCount: row['open_task_count'] as int,
      endsOnAnnexNo: row['ends_on_annex_no'] as int?,
      areaInnerAnnexNo: row['area_inner_annex_no'] as int?,
      areaOuterAnnexNo: row['area_outer_annex_no'] as int?,
      partyAnnexNo: row['party_annex_no'] as int?,
      unitsAnnexNo: row['units_annex_no'] as int?,
    );
  }

  /// PostgREST select for one `contract_list` row.
  static const String select = 'id, file_id, topic_id, kind, subject, activity, status, list_status, '
      'signed_on, starts_on, ends_on, date_note, area_inner, area_outer, area_note, party_id, party_name, '
      'unit_codes, terminated_on, termination_reason, notes, duration_months, days_until_end, '
      'annex_count, storage_count, open_item_count, open_task_count, '
      'ends_on_annex_no, area_inner_annex_no, area_outer_annex_no, party_annex_no, units_annex_no';

  final String id;
  final String fileId;
  final String? topicId;
  final ContractKind kind;
  final String subject;
  final String activity;
  final ContractStatus status;
  final ContractListStatus listStatus;
  final DateTime? signedOn;

  /// The start date, or the signing date when none is set (the view's).
  final DateTime? startsOn;
  final DateTime? endsOn;

  /// Text in place of an end date; empty when none.
  final String dateNote;
  final double? areaInner;
  final double? areaOuter;

  /// Text in place of the areas; empty when none.
  final String areaNote;
  final String? partyId;
  final String? partyName;
  final List<String> unitCodes;
  final DateTime? terminatedOn;
  final String terminationReason;
  final String notes;

  /// From the start to the end date, end day included; null without both.
  final int? durationMonths;

  /// The end date minus the Cairo today; negative once it has passed.
  final int? daysUntilEnd;
  final int annexCount;
  final int storageCount;
  final int openItemCount;
  final int openTaskCount;
  final int? endsOnAnnexNo;
  final int? areaInnerAnnexNo;
  final int? areaOuterAnnexNo;
  final int? partyAnnexNo;
  final int? unitsAnnexNo;

  @override
  List<Object?> get props => [
        id,
        fileId,
        topicId,
        kind,
        subject,
        activity,
        status,
        listStatus,
        signedOn,
        startsOn,
        endsOn,
        dateNote,
        areaInner,
        areaOuter,
        areaNote,
        partyId,
        partyName,
        unitCodes,
        terminatedOn,
        terminationReason,
        notes,
        durationMonths,
        daysUntilEnd,
        annexCount,
        storageCount,
        openItemCount,
        openTaskCount,
        endsOnAnnexNo,
        areaInnerAnnexNo,
        areaOuterAnnexNo,
        partyAnnexNo,
        unitsAnnexNo,
      ];
}
