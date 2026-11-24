import 'register_document.dart';
import 'register_labels.dart';
import 'register_palette.dart';

/// The register as one right-to-left HTML page for the browser's print
/// dialog, laid out like the .xlsx: a table per sheet whose head (the legend
/// and the header) repeats on every printed page, with the bands as
/// full-width rows and «م» (and the tenant and brand, when merged) spanning
/// the group.
///
/// The page is A3 landscape and its fills print. Its `@page` margin is 0, so
/// the browser has no room for its own headers and footers (the app's
/// address, the date); the margins are the body's side padding and an empty
/// row at the top and bottom of every page (in the repeating head and foot). Its fonts are the app's
/// bundled ones, at [regularFontUrl] and [boldFontUrl] (same origin), so
/// nothing is fetched from the internet. Cells read in their own direction
/// (`dir="auto"`), with no bidi control characters.
String writeRegisterHtml(
  RegisterDocument doc, {
  required String title,
  required String regularFontUrl,
  required String boldFontUrl,
}) {
  final out = StringBuffer()
    ..write('<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8">')
    ..write('<title>${_escape(title)}</title><style>')
    ..write(_css(regularFontUrl, boldFontUrl))
    ..write('</style></head><body>');
  // The page's text is wider for its size than Excel's, so the two date
  // columns get more room: a date never wraps.
  final widths = [
    for (final column in RegisterColumn.values)
      column == RegisterColumn.signedOn || column == RegisterColumn.endsOn ? 18.0 : registerColumnWidths[column.index],
  ];
  final total = widths.fold<double>(0, (sum, w) => sum + w);
  final cols = [
    for (final width in widths) '<col style="width:${(width / total * 100).toStringAsFixed(2)}%">',
  ].join();
  final header = [
    for (final column in RegisterColumn.values)
      '<th class="${column.headerTone.name}">${_escape(doc.headers[column.index])}</th>',
  ].join();
  final legend = doc.legend;
  final span = RegisterColumn.values.length;
  // The page's top and bottom margins.
  final spacer = '<tr class="spacer"><td colspan="$span"></td></tr>';
  final legendRow = '<tr class="legend-row"><td colspan="$span"><div class="legend">'
      '<span class="legend-title">${_escape(legend.title)}</span>'
      '<span class="swatch expired">${_escape(legend.expired)}</span>'
      '<span class="swatch ending">${_escape(legend.ending)}</span>'
      '<span class="swatch annex">${_escape(legend.annex)}</span>'
      '<span class="swatch storage">${_escape(legend.storage)}</span></div></td></tr>';

  for (final sheet in doc.sheets) {
    out
      ..write('<section class="sheet">')
      ..write('<table><colgroup>$cols</colgroup>')
      ..write('<thead>$spacer$legendRow<tr>$header</tr></thead>')
      ..write('<tfoot>$spacer</tfoot>');
    for (final band in sheet.bands) {
      out.write('<tbody><tr class="band">'
          '<td colspan="${RegisterColumn.values.length}">${_escape(band.title)}</td></tr>');
      for (final group in band.groups) {
        for (final (i, row) in group.rows.indexed) {
          out.write('<tr class="${row.kind.name}${i == 0 ? ' first' : ''}">');
          for (final column in RegisterColumn.values) {
            final merged = _merged(column, group) && group.rows.length > 1;
            if (merged && i > 0) continue;
            final classes = [
              if (column == RegisterColumn.endsOn && row.endsTone != RegisterTone.none) row.endsTone.name,
              if (row.kind == RegisterRowKind.main &&
                  (column == RegisterColumn.number ||
                      column == RegisterColumn.tenant ||
                      column == RegisterColumn.brand))
                'strong',
              // A merged cell takes the main row's (white) background.
              if (merged) 'main-cell',
              // A date never breaks inside.
              if (row[column] is RegisterDate) 'date',
            ];
            out
              ..write('<td dir="auto"')
              ..write(merged ? ' rowspan="${group.rows.length}"' : '')
              ..write(classes.isEmpty ? '' : ' class="${classes.join(' ')}"')
              ..write('>${_text(row[column])}</td>');
          }
          out.write('</tr>');
        }
      }
      out.write('</tbody>');
    }
    out.write('</table></section>');
  }
  out.write('</body></html>');
  return out.toString();
}

bool _merged(RegisterColumn column, RegisterGroup group) => switch (column) {
      RegisterColumn.number => true,
      RegisterColumn.tenant => group.mergeTenant,
      RegisterColumn.brand => group.mergeBrand,
      _ => false,
    };

String _text(RegisterValue? value) => switch (value) {
      null => '',
      RegisterText(:final text) => _escape(text),
      RegisterDate(:final date) => registerDateText(date),
      RegisterNumber(:final value) => value == value.roundToDouble() ? '${value.toInt()}' : '$value',
    };

String _escape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');

String _css(String regular, String bold) {
  String url(String value) => value.replaceAll('"', '%22');
  return '@font-face{font-family:"Register";src:url("${url(regular)}") format("truetype");font-weight:400}'
      '@font-face{font-family:"Register";src:url("${url(bold)}") format("truetype");font-weight:700}'
      '@page{size:A3 landscape;margin:0}'
      'html{-webkit-print-color-adjust:exact;print-color-adjust:exact}'
      'body{margin:0;padding:0 10mm;font-family:"Register",sans-serif;font-size:9pt;line-height:1.35;color:#${RegisterPalette.ink}}'
      '.sheet+.sheet{break-before:page}'
      '.legend{display:flex;gap:8px;align-items:center;font-size:8pt;font-weight:700}'
      'tr.spacer td,tr.legend-row td{border:none;background:none;padding:0}'
      'tr.spacer td{height:10mm}'
      'tr.legend-row td{padding:0 0 6px;text-align:start}'
      '.legend-title{color:#${RegisterPalette.muted}}'
      '.swatch{padding:2px 8px;border:0.5pt solid #${RegisterPalette.border}}'
      '.swatch.expired{background:#${RegisterPalette.expiredFill};color:#${RegisterPalette.expiredText}}'
      '.swatch.ending{background:#${RegisterPalette.endingFill};color:#${RegisterPalette.endingText}}'
      '.swatch.annex{background:#${RegisterPalette.annexRow}}'
      '.swatch.storage{background:#${RegisterPalette.storageRow}}'
      'table{width:100%;border-collapse:collapse;table-layout:fixed}'
      'thead{display:table-header-group}'
      'tfoot{display:table-footer-group}'
      'th,td{border:0.5pt solid #${RegisterPalette.border};padding:3px 4px;text-align:center;vertical-align:middle;'
      'white-space:pre-line;overflow-wrap:break-word}'
      'th{background:#${RegisterPalette.header};font-weight:700}'
      'th.documents{background:#${RegisterPalette.headerDocuments}}'
      'th.notes{background:#${RegisterPalette.headerNotes}}'
      'tr{break-inside:avoid}'
      'tr.band td{background:#${RegisterPalette.title};font-weight:700;font-size:11pt;padding:6px}'
      'tr.annex td{background:#${RegisterPalette.annexRow}}'
      'tr.storage td{background:#${RegisterPalette.storageRow}}'
      'tr.first td{border-top:1.2pt solid #${RegisterPalette.ink}}'
      'td.main-cell{background:#fff}'
      'td.strong{font-weight:700}'
      'td.date{white-space:nowrap}'
      'td.expired{background:#${RegisterPalette.expiredFill};color:#${RegisterPalette.expiredText};font-weight:700}'
      'td.ending{background:#${RegisterPalette.endingFill};color:#${RegisterPalette.endingText};font-weight:700}';
}
