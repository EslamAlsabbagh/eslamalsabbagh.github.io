import 'package:equatable/equatable.dart';

import '../../../core/domain/contract_item_kind.dart';

/// One «النواقص والمستندات» row: a `contract_items` row.
///
/// A [ContractItemKind.document] belongs to the party ([partyId]) and shows on
/// every contract of that tenant; a [ContractItemKind.missing] item belongs to
/// one contract, annex or storage contract ([contractId]).
class ContractItem extends Equatable {
  const ContractItem({
    required this.id,
    required this.kind,
    required this.contractId,
    required this.partyId,
    required this.label,
    required this.detail,
    required this.needsSignature,
    required this.needsStamp,
    required this.side,
    required this.isResolved,
    required this.createdAt,
  });

  /// Builds from a row selected with [ContractItem.select].
  factory ContractItem.fromRow(Map<String, dynamic> row) => ContractItem(
        id: row['id'] as String,
        kind: ContractItemKind.fromDb(row['kind'] as String),
        contractId: row['contract_id'] as String?,
        partyId: row['party_id'] as String?,
        label: (row['label'] as String).trim(),
        detail: (row['detail'] as String? ?? '').trim(),
        needsSignature: row['needs_signature'] as bool,
        needsStamp: row['needs_stamp'] as bool,
        side: ContractItemSide.fromDb(row['side'] as String),
        isResolved: row['is_resolved'] as bool,
        createdAt: DateTime.parse(row['created_at'] as String),
      );

  /// PostgREST select for `contract_items`.
  static const String select =
      'id, kind, contract_id, party_id, label, detail, needs_signature, needs_stamp, side, is_resolved, created_at';

  final String id;
  final ContractItemKind kind;
  final String? contractId;
  final String? partyId;
  final String label;
  final String detail;
  final bool needsSignature;
  final bool needsStamp;
  final ContractItemSide side;
  final bool isResolved;
  final DateTime createdAt;

  /// The same item ticked or unticked, for the drawer's at-once tick.
  ContractItem resolved(bool value) => ContractItem(
        id: id,
        kind: kind,
        contractId: contractId,
        partyId: partyId,
        label: label,
        detail: detail,
        needsSignature: needsSignature,
        needsStamp: needsStamp,
        side: side,
        isResolved: value,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props =>
      [id, kind, contractId, partyId, label, detail, needsSignature, needsStamp, side, isResolved, createdAt];
}

/// What the inline add row saves. A document goes on [partyId], a missing
/// item on [contractId] with at least one of the signature and the stamp
/// (`contract_items_owner`, `contract_items_missing_needs`).
class ContractItemInput extends Equatable {
  const ContractItemInput.document({required String this.partyId, required this.label, required this.detail})
      : kind = ContractItemKind.document,
        contractId = null,
        needsSignature = false,
        needsStamp = false,
        side = ContractItemSide.client;

  const ContractItemInput.missing({
    required String this.contractId,
    required this.label,
    required this.detail,
    required this.needsSignature,
    required this.needsStamp,
    required this.side,
  })  : kind = ContractItemKind.missing,
        partyId = null;

  final ContractItemKind kind;
  final String? contractId;
  final String? partyId;
  final String label;
  final String detail;
  final bool needsSignature;
  final bool needsStamp;
  final ContractItemSide side;

  @override
  List<Object?> get props => [kind, contractId, partyId, label, detail, needsSignature, needsStamp, side];
}
