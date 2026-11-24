import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'register_document.dart';
import 'register_palette.dart';

/// The register as an .xlsx file: a small SpreadsheetML writer, zipped with
/// `archive`.
///
/// Each sheet is right-to-left. Its top rows are the legend and the header,
/// both frozen: the header is the same for every band, so it stays right
/// while scrolling (Excel's frozen rows can't change per band; chosen with
/// the user 2026-11-16). Then come the bands, each a title merged A:O that
/// scrolls with its groups, with a spacer row between bands. Printing is set
/// to A3 landscape, one page wide, with the header repeated on every page.
Uint8List writeXlsx(RegisterDocument doc) {
  final styles = _Styles();
  final sheets = [for (final sheet in doc.sheets) _sheetXml(sheet, doc, styles)];
  final archive = Archive()
    ..add(ArchiveFile.string('[Content_Types].xml', _contentTypes(sheets.length)))
    ..add(ArchiveFile.string('_rels/.rels', _rootRels))
    ..add(ArchiveFile.string('xl/workbook.xml', _workbook(doc)))
    ..add(ArchiveFile.string('xl/_rels/workbook.xml.rels', _workbookRels(sheets.length)))
    ..add(ArchiveFile.string('xl/styles.xml', styles.xml()));
  for (final (i, xml) in sheets.indexed) {
    archive.add(ArchiveFile.string('xl/worksheets/sheet${i + 1}.xml', xml));
  }
  return ZipEncoder().encodeBytes(archive);
}

/// The MIME type of the file [writeXlsx] makes.
const String xlsxMimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

/// The legend and the header: frozen, and the header repeats on printed
/// pages.
const int _frozenRows = 2;
const int _headerRow = 2;

// Sheets ---------------------------------------------------------------------------------------------------

String _sheetXml(RegisterSheet sheet, RegisterDocument doc, _Styles styles) {
  final rows = StringBuffer();
  final merges = <String>[];
  var r = 0;

  void row(List<String> cells, double height) {
    r++;
    rows.write('<row r="$r" ht="${height.toStringAsFixed(1)}" customHeight="1">${cells.join()}</row>');
  }

  // The legend: its title, then a swatch per color with what it means.
  final legend = doc.legend;
  int swatch(String fill, String color) => styles.id(_Formats.legend(fill, color));
  row([
    _cell('A', 1, null, styles.id(_Formats.normal)),
    _cell('B', 1, RegisterText(legend.title), styles.id(_Formats.legendTitle)),
    _cell('C', 1, RegisterText(legend.expired), swatch(RegisterPalette.expiredFill, RegisterPalette.expiredText)),
    _cell('D', 1, RegisterText(legend.ending), swatch(RegisterPalette.endingFill, RegisterPalette.endingText)),
    _cell('E', 1, RegisterText(legend.annex), swatch(RegisterPalette.annexRow, RegisterPalette.ink)),
    _cell('F', 1, RegisterText(legend.storage), swatch(RegisterPalette.storageRow, RegisterPalette.ink)),
  ], 22);

  // The header, once: frozen under the legend.
  row([
    for (final column in RegisterColumn.values)
      _cell(
        _col(column),
        r + 1,
        RegisterText(doc.headers[column.index]),
        styles.id(_Formats.header(column.headerTone)),
      ),
  ], _height([
    for (final (i, header) in doc.headers.indexed) (header, registerColumnWidths[i]),
  ], bold: true));

  for (final (b, band) in sheet.bands.indexed) {
    if (b > 0) row(const [], 10);
    final title = styles.id(_Formats.title);
    row([
      for (final column in RegisterColumn.values)
        _cell(_col(column), r + 1, column.index == 0 ? RegisterText(band.title) : null, title),
    ], 30);
    merges.add('A$r:O$r');

    for (final group in band.groups) {
      final first = r + 1;
      final heights = [
        for (final (i, line) in group.rows.indexed)
          _height([
            for (final column in RegisterColumn.values)
              // A merged cell's text is spread over the group's rows below.
              if (group.rows.length == 1 || !_merged(column, group) || i > 0) ?_textOf(line[column], column),
          ]),
      ];
      // The merged cells need the group's rows to be tall enough together.
      final mergedNeed = _height([
        for (final column in RegisterColumn.values)
          if (_merged(column, group)) ?_textOf(group.rows.first[column], column),
      ]);
      final total = heights.fold<double>(0, (sum, h) => sum + h);
      if (mergedNeed > total) heights[0] += mergedNeed - total;

      for (final (i, line) in group.rows.indexed) {
        row([
          for (final column in RegisterColumn.values)
            _cell(
              _col(column),
              r + 1,
              i > 0 && _merged(column, group) ? null : line[column],
              styles.id(_Formats.cell(line, column)),
            ),
        ], heights[i]);
      }
      if (group.rows.length > 1) {
        for (final column in RegisterColumn.values) {
          if (_merged(column, group)) merges.add('${_col(column)}$first:${_col(column)}$r');
        }
      }
    }
  }

  final cols = [
    for (final (i, width) in registerColumnWidths.indexed)
      '<col min="${i + 1}" max="${i + 1}" width="$width" customWidth="1"/>',
  ].join();
  final mergeXml = merges.isEmpty
      ? ''
      : '<mergeCells count="${merges.length}">${merges.map((m) => '<mergeCell ref="$m"/>').join()}</mergeCells>';
  const top = 'A${_frozenRows + 1}';
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<worksheet xmlns="$_main" xmlns:r="$_rel">'
      '<sheetPr><pageSetUpPr fitToPage="1"/></sheetPr>'
      '<sheetViews><sheetView rightToLeft="1" workbookViewId="0">'
      '<pane ySplit="$_frozenRows" topLeftCell="$top" activePane="bottomLeft" state="frozen"/>'
      '<selection pane="bottomLeft" activeCell="$top" sqref="$top"/>'
      '</sheetView></sheetViews>'
      '<sheetFormatPr defaultRowHeight="15"/>'
      '<cols>$cols</cols>'
      '<sheetData>$rows</sheetData>'
      '$mergeXml'
      '<printOptions horizontalCentered="1"/>'
      '<pageMargins left="0.25" right="0.25" top="0.4" bottom="0.4" header="0.2" footer="0.2"/>'
      // 8 is A3; fitToHeight 0 lets the pages run on.
      '<pageSetup paperSize="8" orientation="landscape" fitToWidth="1" fitToHeight="0"/>'
      '<headerFooter><oddFooter>&amp;C&amp;P / &amp;N</oddFooter></headerFooter>'
      '</worksheet>';
}

bool _merged(RegisterColumn column, RegisterGroup group) => switch (column) {
      RegisterColumn.number => true,
      RegisterColumn.tenant => group.mergeTenant,
      RegisterColumn.brand => group.mergeBrand,
      _ => false,
    };

String _col(RegisterColumn column) => String.fromCharCode(0x41 + column.index);

String _cell(String col, int row, RegisterValue? value, int style) {
  final ref = '$col$row';
  return switch (value) {
    null => '<c r="$ref" s="$style"/>',
    RegisterText(:final text) =>
      '<c r="$ref" s="$style" t="inlineStr"><is><t xml:space="preserve">${_escape(text)}</t></is></c>',
    RegisterNumber(:final value) => '<c r="$ref" s="$style"><v>${_number(value)}</v></c>',
    RegisterDate(:final date) => '<c r="$ref" s="$style"><v>${excelDateSerial(date)}</v></c>',
  };
}

/// Days since 1899-12-30: Excel's date number (1900 date system, valid
/// from March 1900).
int excelDateSerial(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(1899, 12, 30)).inDays;

String _number(num value) => value == value.roundToDouble() ? value.toInt().toString() : value.toString();

/// A cell's text and its column's width, for the row height.
(String, double)? _textOf(RegisterValue? value, RegisterColumn column) => switch (value) {
      RegisterText(:final text) => (text, registerColumnWidths[column.index]),
      null => null,
      _ => ('0', registerColumnWidths[column.index]),
    };

/// Excel doesn't fit wrapped rows to their text when it opens a file, so
/// each row's height is estimated: the most lines any of its cells needs at
/// its column's width.
double _height(List<(String, double)> cells, {bool bold = false}) {
  var lines = 1;
  for (final (text, width) in cells) {
    final perLine = width * (bold ? 1.0 : 1.15);
    final needed = text.split('\n').fold<int>(0, (n, part) => n + math.max(1, (part.length / perLine).ceil()));
    lines = math.max(lines, needed);
  }
  return lines * 15.0 + 6;
}

/// XML text: escapes markup and drops the control characters XML 1.0
/// can't hold.
String _escape(String text) => text
    .replaceAll(RegExp('[\u0000-\u0008\u000B\u000C\u000E-\u001F\uFFFE\uFFFF]'), '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

// Styles ---------------------------------------------------------------------------------------------------

/// One cell format. Records compare by value, so equal formats share an id.
typedef _Style = ({String? fill, bool bold, double size, String color, int numFmt, bool border});

/// The register's cell formats.
abstract final class _Formats {
  /// Style 0, for cells outside the register.
  static const _Style normal =
      (fill: null, bold: false, size: 11, color: RegisterPalette.ink, numFmt: 0, border: false);
  static const _Style title =
      (fill: RegisterPalette.title, bold: true, size: 14, color: RegisterPalette.ink, numFmt: 0, border: true);
  static const _Style legendTitle =
      (fill: null, bold: true, size: 10, color: RegisterPalette.muted, numFmt: 0, border: false);

  static _Style legend(String fill, String color) =>
      (fill: fill, bold: true, size: 10, color: color, numFmt: 0, border: true);

  static _Style header(RegisterHeaderTone tone) => (
        fill: switch (tone) {
          RegisterHeaderTone.plain => RegisterPalette.header,
          RegisterHeaderTone.documents => RegisterPalette.headerDocuments,
          RegisterHeaderTone.notes => RegisterPalette.headerNotes,
        },
        bold: true,
        size: 11,
        color: RegisterPalette.ink,
        numFmt: 0,
        border: true,
      );

  /// A group row's cell: the row's tint, the end date's tone on its cell,
  /// the date format on dates, and bold for «م», the tenant and the brand.
  static _Style cell(RegisterRow row, RegisterColumn column) {
    final value = row[column];
    final toned = column == RegisterColumn.endsOn && row.endsTone != RegisterTone.none;
    final fill = toned
        ? (row.endsTone == RegisterTone.expired ? RegisterPalette.expiredFill : RegisterPalette.endingFill)
        : switch (row.kind) {
            RegisterRowKind.main => null,
            RegisterRowKind.annex => RegisterPalette.annexRow,
            RegisterRowKind.storage => RegisterPalette.storageRow,
          };
    final color = !toned
        ? RegisterPalette.ink
        : (row.endsTone == RegisterTone.expired ? RegisterPalette.expiredText : RegisterPalette.endingText);
    final bold = toned ||
        (row.kind == RegisterRowKind.main &&
            (column == RegisterColumn.number || column == RegisterColumn.tenant || column == RegisterColumn.brand));
    final numFmt = value is RegisterDate ? _dateFormat : 0;
    return (fill: fill, bold: bold, size: 11, color: color, numFmt: numFmt, border: true);
  }
}

/// `dd/mm/yyyy`, the first custom number format id.
const int _dateFormat = 164;

class _Styles {
  _Styles() {
    id(_Formats.normal);
  }

  final _ids = <_Style, int>{};
  final _fonts = <(bool, double, String)>[];
  final _fills = <String>[];

  int id(_Style style) => _ids.putIfAbsent(style, () {
        if (!_fonts.contains((style.bold, style.size, style.color))) _fonts.add((style.bold, style.size, style.color));
        if (style.fill case final fill? when !_fills.contains(fill)) _fills.add(fill);
        return _ids.length;
      });

  String xml() {
    final fonts = [
      for (final (bold, size, color) in _fonts)
        '<font>${bold ? '<b/>' : ''}<sz val="${_number(size)}"/><color rgb="FF$color"/>'
            '<name val="Arial"/><family val="2"/></font>',
    ].join();
    // Fills 0 and 1 are reserved by Excel.
    final fills = [
      '<fill><patternFill patternType="none"/></fill>',
      '<fill><patternFill patternType="gray125"/></fill>',
      for (final fill in _fills)
        '<fill><patternFill patternType="solid"><fgColor rgb="FF$fill"/><bgColor indexed="64"/></patternFill></fill>',
    ].join();
    const side = '<color rgb="FF${RegisterPalette.border}"/>';
    const borders = '<border><left/><right/><top/><bottom/><diagonal/></border>'
        '<border><left style="thin">$side</left><right style="thin">$side</right>'
        '<top style="thin">$side</top><bottom style="thin">$side</bottom><diagonal/></border>';
    final xfs = [
      for (final style in _ids.keys)
        '<xf numFmtId="${style.numFmt}" fontId="${_fonts.indexOf((style.bold, style.size, style.color))}" '
            'fillId="${style.fill == null ? 0 : _fills.indexOf(style.fill!) + 2}" borderId="${style.border ? 1 : 0}" '
            'xfId="0" applyNumberFormat="1" applyFont="1" applyFill="1" applyBorder="1" applyAlignment="1">'
            '<alignment horizontal="center" vertical="center" wrapText="1" readingOrder="2"/></xf>',
    ].join();
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
        '<styleSheet xmlns="$_main">'
        '<numFmts count="1"><numFmt numFmtId="$_dateFormat" formatCode="dd/mm/yyyy"/></numFmts>'
        '<fonts count="${_fonts.length}">$fonts</fonts>'
        '<fills count="${_fills.length + 2}">$fills</fills>'
        '<borders count="2">$borders</borders>'
        '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
        '<cellXfs count="${_ids.length}">$xfs</cellXfs>'
        '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
        '</styleSheet>';
  }
}

// Package parts --------------------------------------------------------------------------------------------

const String _main = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
const String _rel = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';

String _contentTypes(int sheets) => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
    '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
    '<Default Extension="xml" ContentType="application/xml"/>'
    '<Override PartName="/xl/workbook.xml" '
    'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
    '${[for (var i = 1; i <= sheets; i++) '<Override PartName="/xl/worksheets/sheet$i.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join()}'
    '<Override PartName="/xl/styles.xml" '
    'ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
    '</Types>';

const String _rootRels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" '
    'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
    'Target="xl/workbook.xml"/>'
    '</Relationships>';

String _workbook(RegisterDocument doc) {
  final sheets = [
    for (final (i, sheet) in doc.sheets.indexed)
      '<sheet name="${_escape(sheet.name).replaceAll("'", '&apos;')}" sheetId="${i + 1}" r:id="rId${i + 1}"/>',
  ].join();
  // The first header row, repeated on every printed page.
  final titles = [
    for (final (i, sheet) in doc.sheets.indexed)
      '<definedName name="_xlnm.Print_Titles" localSheetId="$i">'
          "${_escape("'${sheet.name.replaceAll("'", "''")}'")}!\$$_headerRow:\$$_headerRow</definedName>",
  ].join();
  return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
      '<workbook xmlns="$_main" xmlns:r="$_rel">'
      '<bookViews><workbookView/></bookViews>'
      '<sheets>$sheets</sheets>'
      '${titles.isEmpty ? '' : '<definedNames>$titles</definedNames>'}'
      '</workbook>';
}

String _workbookRels(int sheets) => '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '${[for (var i = 1; i <= sheets; i++) '<Relationship Id="rId$i" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" '
        'Target="worksheets/sheet$i.xml"/>'].join()}'
    '<Relationship Id="rId${sheets + 1}" '
    'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
    '</Relationships>';
