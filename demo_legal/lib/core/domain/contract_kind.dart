/// A contract's kind. Names match the Postgres `contract_kind` enum values.
/// The «العقود» list only has main contracts, so never [annex].
enum ContractKind {
  lease,
  storage,
  service,
  other,
  annex;

  /// Parses the DB value; throws [ArgumentError] on an unknown name.
  static ContractKind fromDb(String value) => ContractKind.values.byName(value);
}
