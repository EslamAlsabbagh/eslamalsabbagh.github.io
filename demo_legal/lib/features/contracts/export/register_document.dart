/// The exported contracts register (DESIGN_SPEC §4 View 4 "Export and
/// print"), laid out like the firm's workbook: sheets of season bands, each
/// band a title, the header and a group of rows per main contract.
///
/// Built by `buildRegister`, written by `writeXlsx` and `writeRegisterHtml`.
/// Plain data: no Flutter, no Supabase.
library;

/// The 15 columns, A to O, in the workbook's order.
enum RegisterColumn {
  number,
  tenant,
  brand,
  units,
  activity,
  subject,
  signedOn,
  endsOn,
  duration,
  areaInner,
  areaOuter,
  documents,
  missing,
  notes,
  followUps;

  /// Header fill: the workbook marks these columns.
  RegisterHeaderTone get headerTone => switch (this) {
        documents => RegisterHeaderTone.documents,
        notes || followUps => RegisterHeaderTone.notes,
        _ => RegisterHeaderTone.plain,
      };
}

enum RegisterHeaderTone { plain, documents, notes }

/// Column widths, A to O, in Excel's character units. The print page uses
/// them as proportions.
const List<double> registerColumnWidths = [6, 26, 22, 24, 18, 30, 13, 13, 14, 10, 10, 30, 34, 38, 34];

/// What a row is: the main contract, an annex (of the main contract or of a
/// storage contract), or a storage contract under a lease.
enum RegisterRowKind { main, annex, storage }

/// The end date's tint, on the cell holding the effective end date.
enum RegisterTone { none, expired, ending }

/// A cell's value.
sealed class RegisterValue {
  const RegisterValue();
}

final class RegisterText extends RegisterValue {
  const RegisterText(this.text);

  /// May hold line breaks (one item per line).
  final String text;

  @override
  bool operator ==(Object other) => other is RegisterText && other.text == text;

  @override
  int get hashCode => text.hashCode;

  @override
  String toString() => 'RegisterText($text)';
}

/// A calendar date (the time part is ignored).
final class RegisterDate extends RegisterValue {
  const RegisterDate(this.date);

  final DateTime date;

  @override
  bool operator ==(Object other) => other is RegisterDate && other.date == date;

  @override
  int get hashCode => date.hashCode;

  @override
  String toString() => 'RegisterDate($date)';
}

final class RegisterNumber extends RegisterValue {
  const RegisterNumber(this.value);

  final num value;

  @override
  bool operator ==(Object other) => other is RegisterNumber && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'RegisterNumber($value)';
}

class RegisterRow {
  RegisterRow({required this.kind, required this.cells, this.endsTone = RegisterTone.none})
      : assert(cells.length == RegisterColumn.values.length, 'a value (or null) per column');

  final RegisterRowKind kind;

  /// One per [RegisterColumn]; null is an empty cell.
  final List<RegisterValue?> cells;

  /// The tint of the «تاريخ انتهاء العقد» cell.
  final RegisterTone endsTone;

  RegisterValue? operator [](RegisterColumn column) => cells[column.index];
}

/// A main contract and the rows under it. «م» is merged down the group, and
/// so are the tenant and the brand while no row under the main one has its
/// own (those cells are then empty below the first row).
class RegisterGroup {
  const RegisterGroup({required this.rows, required this.mergeTenant, required this.mergeBrand});

  final List<RegisterRow> rows;
  final bool mergeTenant;
  final bool mergeBrand;
}

/// «بيان بجميع العقود السارية بمشروع … لموسم 2026» and its contracts.
class RegisterBand {
  const RegisterBand({required this.title, required this.groups});

  final String title;
  final List<RegisterGroup> groups;
}

class RegisterSheet {
  const RegisterSheet({required this.name, required this.bands});

  /// Already valid for Excel: at most 31 characters, none of `[]:*?/\`,
  /// unique in the workbook.
  final String name;
  final List<RegisterBand> bands;
}

/// The legend under each sheet's top: the colors and what they mean.
class RegisterLegend {
  const RegisterLegend({
    required this.title,
    required this.expired,
    required this.ending,
    required this.annex,
    required this.storage,
  });

  final String title;
  final String expired;
  final String ending;
  final String annex;
  final String storage;
}

class RegisterDocument {
  const RegisterDocument({required this.headers, required this.legend, required this.sheets})
      : assert(headers.length == 15, 'a header per column');

  /// The header row's texts, A to O.
  final List<String> headers;
  final RegisterLegend legend;
  final List<RegisterSheet> sheets;
}
