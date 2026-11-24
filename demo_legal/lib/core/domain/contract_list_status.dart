/// A main contract's state in the «العقود» list, computed by `contract_list`
/// on the Cairo date (ADR-0013). Names match the view's `list_status` values.
enum ContractListStatus {
  /// In force, ending more than 90 days from today or undated.
  active,

  /// In force, ending within 90 days (today included).
  ending,

  /// Its end date has passed.
  expired,
  terminated;

  /// Parses the DB value; throws [ArgumentError] on an unknown name.
  static ContractListStatus fromDb(String value) => ContractListStatus.values.byName(value);
}
