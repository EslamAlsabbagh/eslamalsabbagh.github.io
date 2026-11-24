/// What a unit is. Names match the Postgres `unit_kind` enum.
enum UnitKind {
  shop,
  kiosk,
  storage,
  space,
  site;

  /// Parses the DB value; throws [ArgumentError] on an unknown name.
  static UnitKind fromDb(String value) => UnitKind.values.byName(value);
}
