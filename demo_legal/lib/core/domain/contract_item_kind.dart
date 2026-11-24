/// A checklist item's kind. Names match the Postgres `contract_item_kind`
/// enum: a [document] the tenant must send belongs to the party, a [missing]
/// signature or stamp to a contract or annex (ADR-0013).
enum ContractItemKind {
  document,
  missing;

  /// Parses the DB value; throws [ArgumentError] on an unknown name.
  static ContractItemKind fromDb(String value) => ContractItemKind.values.byName(value);
}

/// Whose signature or stamp is missing. Names match `contract_item_side`.
enum ContractItemSide {
  client,
  us;

  /// Parses the DB value; throws [ArgumentError] on an unknown name.
  static ContractItemSide fromDb(String value) => ContractItemSide.values.byName(value);
}
