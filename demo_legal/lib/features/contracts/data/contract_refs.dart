import 'package:equatable/equatable.dart';

import '../../../core/domain/unit_kind.dart';

/// A tenant (or other party) picked in a field: `parties` is shared across
/// files (ADR-0013).
class PartyRef extends Equatable {
  const PartyRef({required this.id, required this.name});

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

/// A unit picked in a field, in the contract's file.
class UnitRef extends Equatable {
  const UnitRef({required this.id, required this.code, required this.kind, this.keyNumber});

  final String id;

  /// As written (`C14-GF-U02`).
  final String code;
  final UnitKind kind;

  /// A storage unit's key number as typed («304»), when the row was read
  /// with it (a contract's own units). Shown only, so it isn't part of
  /// equality: the same unit picked again from a suggestion is equal.
  final String? keyNumber;

  @override
  List<Object?> get props => [id, code, kind];
}

/// A `suggest_parties` row.
class PartySuggestion extends Equatable {
  const PartySuggestion({required this.party, required this.contractCount, required this.score});

  factory PartySuggestion.fromRow(Map<String, dynamic> row) => PartySuggestion(
        party: PartyRef(id: row['id'] as String, name: row['name'] as String),
        contractCount: row['contract_count'] as int,
        score: (row['score'] as num).toDouble(),
      );

  final PartyRef party;

  /// The contracts naming it that the viewer can see (the row's hint).
  final int contractCount;

  /// Whole-name trigram similarity to the query, 0 to 1. At 0.5 or more,
  /// adding a new party asks «يوجد مستأجر مشابه» first.
  final double score;

  @override
  List<Object?> get props => [party, contractCount, score];
}

/// A `suggest_units` row.
class UnitSuggestion extends Equatable {
  const UnitSuggestion({
    required this.unit,
    required this.keyNumber,
    required this.currentBrand,
    required this.score,
  });

  factory UnitSuggestion.fromRow(Map<String, dynamic> row) => UnitSuggestion(
        unit: UnitRef(
          id: row['id'] as String,
          code: row['code'] as String,
          kind: UnitKind.fromDb(row['kind'] as String),
        ),
        keyNumber: row['key_number'] as String?,
        currentBrand: row['current_brand'] as String?,
        score: (row['score'] as num).toDouble(),
      );

  final UnitRef unit;

  /// A storage unit's key number.
  final String? keyNumber;

  /// The brand of the unit's newest contract in force; null shows «شاغرة».
  final String? currentBrand;

  /// As [PartySuggestion.score].
  final double score;

  @override
  List<Object?> get props => [unit, keyNumber, currentBrand, score];
}

/// The repeated wording `suggest_values` serves. Names are its `p_field`.
enum SuggestValueField {
  subject('subject'),
  annexSubject('annex_subject'),
  activity('activity'),
  itemLabel('item_label');

  const SuggestValueField(this.db);

  final String db;
}

/// A `suggest_values` row: wording in its most-used spelling.
class ValueSuggestion extends Equatable {
  const ValueSuggestion({required this.value, required this.uses});

  factory ValueSuggestion.fromRow(Map<String, dynamic> row) =>
      ValueSuggestion(value: row['value'] as String, uses: row['uses'] as int);

  final String value;
  final int uses;

  @override
  List<Object?> get props => [value, uses];
}
