/// The register's colors (DESIGN_SPEC §4 View 4 "Export and print"), as
/// `RRGGBB` for the file formats: the .xlsx styles and the print page's CSS.
/// They are not widget colors. The status colors repeat light `AppTokens`
/// values, and a test keeps them equal; the rest are the firm's workbook's
/// own colors, plus light row tints.
abstract final class RegisterPalette {
  /// Text, as `AppTokens.ink`.
  static const String ink = '16201C';

  /// The legend's title, as `AppTokens.textMuted`.
  static const String muted = '56605B';

  /// Cell borders: darker than the app's, so they survive printing.
  static const String border = '9AA39E';

  /// The band title, the workbook's green.
  static const String title = '92D050';

  /// The header row, as `AppTokens.segmentBg`.
  static const String header = 'E3E6E1';

  /// «المستندات المطلوبة»'s header, the workbook's yellow.
  static const String headerDocuments = 'FFFF00';

  /// «الملاحظات» and «الاجراء المطلوب»'s headers, the workbook's blue.
  static const String headerNotes = '00B0F0';

  /// Annex rows: a light tint of `AppTokens.accent`.
  static const String annexRow = 'EAEFFA';

  /// Storage contract rows: a light green-grey.
  static const String storageRow = 'EEF4EC';

  /// An expired end date: `AppTokens.overdue` on `overdueRowBorder` (the row
  /// background is too pale for one cell).
  static const String expiredFill = 'EBC2BF';
  static const String expiredText = '8E1B1B';

  /// An end date within 90 days: the `waiting` status colors.
  static const String endingFill = 'FAEFD6';
  static const String endingText = '744600';
}
