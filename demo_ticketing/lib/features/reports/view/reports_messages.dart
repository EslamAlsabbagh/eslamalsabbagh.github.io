import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../core/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../actions_log/view/actions_log_messages.dart' show paymentMethodName;
import '../data/reports_repository.dart';
import '../data/sales_report_models.dart';

/// The Reports page's texts, shared by the page and the CSV.

String reportsFailureMessage(AppLocalizations l10n, ReportsFailureKind kind) => switch (kind) {
  ReportsFailureKind.notAllowed => l10n.reportsNotAllowed,
  ReportsFailureKind.invalidRange => l10n.reportsInvalidRange,
  ReportsFailureKind.busy => l10n.reportsBusy,
  ReportsFailureKind.tooSlow => l10n.reportsTooSlow,
  ReportsFailureKind.serverUnreachable => l10n.errorServerUnreachable,
  ReportsFailureKind.unexpected => l10n.reportsUnexpected,
};

String reportGroupName(AppLocalizations l10n, ReportGroup group) => switch (group) {
  ReportGroup.type => l10n.reportsGroupType,
  ReportGroup.cashier => l10n.reportsGroupCashier,
  ReportGroup.gate => l10n.reportsGroupGate,
  ReportGroup.method => l10n.reportsGroupMethod,
  ReportGroup.day => l10n.reportsGroupDay,
};

/// "09/11/2026", Western digits in both languages.
String reportDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

/// A period's two dates, isolated left to right so they keep their order next
/// to Arabic text. One date when they're the same day.
String reportDates(DateTime from, DateTime to) => from == to
    ? '\u2066${reportDate(from)}\u2069'
    : '\u2066${reportDate(from)} – ${reportDate(to)}\u2069';

/// A row's name in [group]: the type in the UI language, the cashier, the
/// gate ("من غير بوابة" for tickets with none), the method, or the day with
/// its weekday ("الأحد 09/11/2026").
String reportRowName(
  AppLocalizations l10n,
  ReportRow row,
  ReportGroup group,
  String languageCode,
) => switch (group) {
  ReportGroup.type =>
    (languageCode == 'ar' ? row.nameAr ?? row.nameEn : row.nameEn ?? row.nameAr) ?? '—',
  ReportGroup.cashier => row.name ?? '—',
  ReportGroup.gate => row.name ?? l10n.reportsNoGate,
  ReportGroup.method => paymentMethodName(l10n, row.method) ?? '—',
  ReportGroup.day => switch (row.date) {
    final d? => '${DateFormat('EEEE', l10n.localeName).format(d)} ${reportDate(d)}',
    null => '—',
  },
};

/// "شباك 2 · بوابة 1"; the counter alone when its tickets have no gate, and
/// in the gate view, where the row is the gate.
String reportCounterText(ReportCounter c) => c.gate == null ? c.name : '${c.name} · ${c.gate}';

/// A cashier's or a gate's counters in one CSV cell: "شباك 1 · بوابة 1، شباك 2 · بوابة 3".
String reportCountersText(List<ReportCounter> counters, String languageCode) =>
    counters.map(reportCounterText).join(languageCode == 'ar' ? '، ' : ', ');

/// The row's share of the period's sales (gross), 0 to 1.
double reportShare(ReportFigures row, ReportFigures totals) =>
    totals.salesPiastres <= 0 ? 0 : row.salesPiastres / totals.salesPiastres;

/// An amount for the tiles ("31,800 ج.م"), or [bare] for a table cell
/// ("31,800"), whose header names the currency.
String reportAmount(AppLocalizations l10n, int piastres, {bool bare = false}) => bare
    ? NumberFormat(
        piastres % 100 == 0 ? '#,##0' : '#,##0.00',
        l10n.localeName,
      ).format(piastres / 100)
    : formatMoney(l10n, piastres);

/// "− 2,100 ج.م"; "0" with no refund.
String refundText(AppLocalizations l10n, int piastres, {bool bare = false}) =>
    piastres == 0 ? '0' : '− ${reportAmount(l10n, piastres, bare: bare)}';

/// A tip cell: "—" on a type row (a tip has no type), "0" with none.
String tipsText(AppLocalizations l10n, int? piastres, {bool bare = false}) => switch (piastres) {
  null => '—',
  0 => '0',
  final p => reportAmount(l10n, p, bare: bare),
};

/// Net may be negative (a day with refunds only): "− 100 ج.م".
String netText(AppLocalizations l10n, int piastres, {bool bare = false}) => piastres < 0
    ? '− ${reportAmount(l10n, -piastres, bare: bare)}'
    : reportAmount(l10n, piastres, bare: bare);

/// Whether [group]'s table has the counters column and a count per type
/// after the name: by cashier (4.4a) and by gate (4.4b).
bool reportHasTypeColumns(ReportGroup group) =>
    group == ReportGroup.cashier || group == ReportGroup.gate;

/// The counters column's header: each counter with its gate by cashier, the
/// counters alone by gate.
String reportCountersHeader(AppLocalizations l10n, ReportGroup group) =>
    group == ReportGroup.gate ? l10n.reportsColCounters : l10n.reportsColCounterGate;

/// Piastres as pounds, a number for the CSV: 2100, or 12.5 with piastres.
num _pounds(int piastres) => piastres % 100 == 0 ? piastres ~/ 100 : piastres / 100;

/// The CSV of [group]'s rows plus a totals row, headers in the UI language.
/// Amounts are numbers in pounds; a day is `yyyy-MM-dd`. By cashier and by
/// gate, a counters cell and a count per type follow the name, as on the page
/// (4.4a, 4.4b).
List<List<Object?>> reportsCsvRows(
  AppLocalizations l10n,
  SalesReport report,
  ReportGroup group,
  String languageCode,
) {
  final withTypes = reportHasTypeColumns(group);
  final types = withTypes ? report.typeColumns : const <ReportRow>[];
  List<Object?> figures(ReportFigures f) => [
    f.tickets,
    _pounds(f.salesPiastres),
    f.refundCount,
    _pounds(f.refundPiastres),
    if (f.tipsPiastres case final t?) _pounds(t) else null,
    _pounds(f.netPiastres),
  ];
  return [
    [
      reportGroupName(l10n, group),
      if (withTypes) reportCountersHeader(l10n, group),
      for (final t in types) reportRowName(l10n, t, ReportGroup.type, languageCode),
      l10n.reportsColTickets,
      l10n.reportsCsvSales,
      l10n.reportsCsvRefundCount,
      l10n.reportsCsvRefunds,
      l10n.reportsCsvTips,
      l10n.reportsCsvNet,
      l10n.reportsCsvShare,
    ],
    for (final r in report.rows(group))
      [
        if (group == ReportGroup.day && r.date != null)
          DateFormat('yyyy-MM-dd').format(r.date!)
        else
          reportRowName(l10n, r, group, languageCode),
        if (withTypes) reportCountersText(r.counters, languageCode),
        for (final t in types) r.typeTickets[t.id] ?? 0,
        ...figures(r.figures),
        (reportShare(r.figures, report.totals) * 100).round(),
      ],
    [
      l10n.reportsTotal,
      if (withTypes) null,
      for (final t in types) t.figures.tickets,
      ...figures(report.totals),
      report.totals.salesPiastres > 0 ? 100 : 0,
    ],
  ];
}
