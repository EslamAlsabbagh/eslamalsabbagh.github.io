/// A contract's stored status. Names match the Postgres `contract_status`
/// enum. The list shows a finer state computed on the Cairo date
/// (`ContractListStatus`). There are no drafts (chosen 2026-11-15): the
/// enum's `draft` value is refused by the `contracts_not_draft` check.
enum ContractStatus {
  active,
  terminated;

  /// Parses the DB value; throws [ArgumentError] on an unknown name.
  static ContractStatus fromDb(String value) => ContractStatus.values.byName(value);
}
