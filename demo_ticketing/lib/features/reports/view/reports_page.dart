
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

import '../../../core/export/csv_export.dart';
import '../../../core/money.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/reports_cubit.dart';
import '../data/reports_repository.dart';
import '../data/sales_report_models.dart';
import 'range_dialog.dart';
import 'reports_messages.dart';

/// The sales report (task 4.4, `Reports.dc.html`): sales, refunds, tips and net for
/// a period, grouped by ticket type, cashier (with a ticket count per type,
/// 4.4a), gate (the same layout, 4.4b), payment method or day, with a CSV of
/// the grouping shown. Sales are
/// gross; a refund counts on the day it was made (ADR-0032).
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  /// Where the CSV goes; tests point it at a temporary folder.
  @visibleForTesting
  static Directory? Function() exportFolder = downloadsFolder;

  /// Picks the custom range; tests replace the dialog.
  @visibleForTesting
  static Future<DateTimeRange?> Function(
    BuildContext context,
    DateTime lastDate,
    DateTimeRange initial,
  )
  pickRange = (context, lastDate, initial) =>
      showReportRangeDialog(context, lastDate: lastDate, initial: initial);

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => ReportsCubit(context.read<ReportsRepository>())..start(),
    child: const _ReportsView(),
  );
}

class _ReportsView extends StatefulWidget {
  const _ReportsView();

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends State<_ReportsView> {
  bool _exporting = false;

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final state = context.read<ReportsCubit>().state;
    final report = state.report;
    if (report == null) return;
    void say(String text, {SnackBarAction? action}) =>
        messenger?.showSnackBar(SnackBar(content: Text(text), action: action));

    final folder = ReportsPage.exportFolder();
    if (folder == null) {
      say(l10n.actionsExportNoFolder);
      return;
    }
    setState(() => _exporting = true);
    try {
      // The answer on screen already has every grouping: no second call.
      final csv = encodeCsv(reportsCsvRows(l10n, report, state.group, languageCode));
      final day = DateFormat('yyyy-MM-dd');
      final name =
          'sales-${state.group.key}-${day.format(report.from)}-${day.format(report.to)}.csv';
      final file = await saveCsv(folder, name, csv);
      say(
        l10n.actionsExported(file.path),
        action: SnackBarAction(label: l10n.actionsOpenFolder, onPressed: () => showInFolder(file)),
      );
    } on FileSystemException {
      say(l10n.actionsExportFailed);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _pickRange() async {
    final cubit = context.read<ReportsCubit>();
    final state = cubit.state;
    final day = state.report?.day ?? DateUtils.dateOnly(DateTime.now());
    final initial = state.from != null && state.to != null
        ? DateTimeRange(start: state.from!, end: state.to!)
        : DateTimeRange(start: day.subtract(const Duration(days: 6)), end: day);
    final picked = await ReportsPage.pickRange(context, day, initial);
    if (picked == null || !mounted) return;
    await cubit.setRange(DateUtils.dateOnly(picked.start), DateUtils.dateOnly(picked.end));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final state = context.watch<ReportsCubit>().state;
    final cubit = context.read<ReportsCubit>();
    final report = state.report;

    final Widget body;
    if (report == null) {
      final failure = state.failure;
      body = failure == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.reportsLoading, style: TextStyle(color: tokens.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Text(
                    reportsFailureMessage(l10n, failure),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (failure != ReportsFailureKind.notAllowed)
                    FilledButton(onPressed: cubit.refresh, child: Text(l10n.retry)),
                ],
              ),
            );
    } else {
      body = SingleChildScrollView(
        key: const ValueKey('reports-scroll'),
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Tiles(totals: report.totals),
            const SizedBox(height: 18),
            _Table(report: report, group: state.group),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.reportsTitle,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    l10n.reportsSubtitle,
                    style: TextStyle(fontSize: 14, color: tokens.textSecondary),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l10n.actionsRefresh,
                    onPressed: state.loading ? null : cubit.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: AppSizes.touchTarget,
                    child: OutlinedButton.icon(
                      key: const ValueKey('reports-export'),
                      onPressed: report == null || _exporting ? null : _export,
                      icon: _exporting
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download, size: 18),
                      label: Text(
                        l10n.actionsExport,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          _FilterBar(state: state, onPickRange: _pickRange),
          if (report != null && state.failure != null) ...[
            const SizedBox(height: 12),
            _Banner(
              text: reportsFailureMessage(l10n, state.failure!),
              bg: tokens.warningBg,
              fg: tokens.warningText,
              border: tokens.warningBorder,
            ),
          ],
          // A refresh keeps the figures on screen; this shows it's running.
          SizedBox(
            height: 18,
            child: report != null && state.loading
                ? const Center(child: LinearProgressIndicator(key: ValueKey('reports-refreshing')))
                : null,
          ),
          // Scrolls by wheel or drag, with no scrollbar (as the other admin pages).
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: body,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.state, required this.onPickRange});

  final ReportsState state;
  final VoidCallback onPickRange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final cubit = context.read<ReportsCubit>();
    final report = state.report;
    final label = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tokens.textSecondary);

    String periodName(ReportPeriod p) => switch (p) {
      ReportPeriod.today => l10n.shiftsPeriodToday,
      ReportPeriod.yesterday => l10n.shiftsPeriodYesterday,
      ReportPeriod.week => l10n.shiftsPeriodWeek,
      ReportPeriod.month => l10n.reportsPeriodMonth,
      ReportPeriod.lastMonth => l10n.reportsPeriodLastMonth,
      ReportPeriod.range => switch ((state.from, state.to)) {
        (final from?, final to?) => reportDates(from, to),
        _ => l10n.reportsPeriodRange,
      },
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(l10n.reportsPeriod, style: label),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in ReportPeriod.values)
                _Pill(
                  key: ValueKey('period-${p.key}'),
                  text: periodName(p),
                  selected: p == state.period,
                  icon: p == ReportPeriod.range ? Icons.date_range : null,
                  onTap: () => p == ReportPeriod.range ? onPickRange() : cubit.setPeriod(p),
                ),
            ],
          ),
          SizedBox(height: 28, child: VerticalDivider(width: 1, color: tokens.border)),
          Text(l10n.reportsGroupBy, style: label),
          _Choices<ReportGroup>(
            values: ReportGroup.values,
            selected: state.group,
            label: (g) => reportGroupName(l10n, g),
            onPick: cubit.setGroup,
          ),
          // What the period is, in dates, so "last month" says which.
          if (report != null && state.period != ReportPeriod.range)
            Text(
              reportDates(report.from, report.to),
              key: const ValueKey('reports-dates'),
              style: TextStyle(fontSize: 14, color: tokens.textSecondary),
            ),
        ],
      ),
    );
  }
}

/// A period pill: filled with the primary color when picked (`Reports.dc.html`).
class _Pill extends StatelessWidget {
  const _Pill({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fg = selected ? tokens.surface : tokens.text;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? tokens.primary : tokens.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? tokens.primary : tokens.inputBorder),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: SizedBox(
            height: AppSizes.touchTarget,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              // Not a Container with an alignment: inside a Wrap that would
              // stretch the pill to the whole width.
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 6)],
                  Text(
                    text,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fg),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A row of choices in a grey well (the design's "group by" control).
class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.onPick,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) label;
  final void Function(T value) onPick;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: tokens.bg,
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final v in values)
            Semantics(
              key: ValueKey('group-$v'),
              selected: v == selected,
              button: true,
              child: Material(
                color: v == selected ? tokens.surface : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => onPick(v),
                  child: SizedBox(
                    height: AppSizes.touchTarget,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          label(v),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: v == selected ? tokens.text : tokens.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.totals});

  final ReportFigures totals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final count = NumberFormat('#,##0', l10n.localeName);
    Widget tile(String label, String value, {String? note, Key? key}) => Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: tokens.textSecondary)),
          const SizedBox(height: 4),
          // One line, shrunk to fit if it must: a year's total ("55,544,570 ج.م")
          // would otherwise wrap in a narrow card.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
          ),
          if (note != null) Text(note, style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
        ],
      ),
    );
    final tiles = [
      tile(
        l10n.reportsTileSales,
        formatMoney(l10n, totals.salesPiastres),
        key: const ValueKey('reports-tile-sales'),
      ),
      tile(
        l10n.reportsTileRefunds,
        refundText(l10n, totals.refundPiastres),
        note: totals.refundCount == 0 ? null : l10n.reportsRefundCount(totals.refundCount),
        key: const ValueKey('reports-tile-refunds'),
      ),
      tile(
        l10n.reportsTileTips,
        tipsText(l10n, totals.tipsPiastres ?? 0),
        key: const ValueKey('reports-tile-tips'),
      ),
      tile(
        l10n.reportsTileNet,
        netText(l10n, totals.netPiastres),
        key: const ValueKey('reports-tile-net'),
      ),
      tile(
        l10n.reportsTileTickets,
        count.format(totals.tickets),
        key: const ValueKey('reports-tile-tickets'),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final perRow = constraints.maxWidth >= 900
            ? tiles.length
            : constraints.maxWidth >= 560
            ? 3
            : 2;
        const gap = 14.0;
        // Row by row, each card stretched to the row's tallest (the refunds
        // card has an extra line), so the cards of a row are one height. A
        // short last row keeps the same card width.
        return Column(
          children: [
            for (var start = 0; start < tiles.length; start += perRow) ...[
              if (start > 0) const SizedBox(height: gap),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = start; i < start + perRow; i++) ...[
                      if (i > start) const SizedBox(width: gap),
                      Expanded(child: i < tiles.length ? tiles[i] : const SizedBox.shrink()),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.report, required this.group});

  final SalesReport report;
  final ReportGroup group;

  /// Below this width per flex unit the table scrolls sideways: with many
  /// ticket types the cashier view would squeeze its counts otherwise.
  static const _minWidthPerFlex = 30.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final languageCode = Localizations.localeOf(context).languageCode;
    final count = NumberFormat('#,##0', l10n.localeName);
    final header = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: tokens.textSecondary,
    );
    final rows = report.rows(group);

    // By cashier (4.4a): after the name, the counters sold at with their gate,
    // then a ticket count per type sold in the period. The Total tickets
    // column after them is their total. By gate (4.4b) the same, with the
    // counters that sold for the gate.
    final withTypes = reportHasTypeColumns(group);
    final types = withTypes ? report.typeColumns : const <ReportRow>[];
    // The counters get room for "شباك 2 · بوابة 1" on one line; the share bar
    // gives up one unit for it, so four types still fit a 1366 px screen.
    final flexes = withTypes
        ? [4, 5, for (final _ in types) 2, 3, 3, 3, 3, 3, 3]
        : [4, 3, 3, 3, 3, 3, 4];
    final minWidth = flexes.fold(0, (a, f) => a + f) * _minWidthPerFlex;

    Widget cells(List<Widget> children) => Row(
      children: [
        for (var i = 0; i < children.length; i++)
          Expanded(
            flex: flexes[i],
            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: children[i]),
          ),
      ],
    );

    // A line of the table: a group row, or the totals ([total]) with no share.
    Widget line(
      String name,
      ReportFigures f,
      Map<String, int> typeTickets, {
      List<ReportCounter> counters = const [],
      required bool total,
      required Key key,
    }) {
      final weight = total ? FontWeight.w700 : FontWeight.w400;
      return DecoratedBox(
        key: key,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: total ? tokens.border : tokens.rowDivider, width: total ? 2 : 1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          // Numbers stay on one line and shrink only when a cell is too narrow
          // (a long period's totals): the name and the counters wrap instead.
          child: cells([
            Text(name, style: TextStyle(fontWeight: total ? FontWeight.w700 : FontWeight.w600)),
            if (withTypes)
              total
                  ? const SizedBox.shrink()
                  : counters.isEmpty
                  ? Text('—', style: TextStyle(color: tokens.textSecondary))
                  : _CountersCell(counters: counters),
            for (final t in types) _FitNumber(count.format(typeTickets[t.id] ?? 0), weight: weight),
            _FitNumber(count.format(f.tickets), weight: weight),
            _FitNumber(reportAmount(l10n, f.salesPiastres, bare: true), weight: weight),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FitNumber(refundText(l10n, f.refundPiastres, bare: true), weight: weight),
                if (f.refundCount > 0)
                  Text(
                    l10n.reportsRefundCount(f.refundCount),
                    style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                  ),
              ],
            ),
            _FitNumber(tipsText(l10n, f.tipsPiastres, bare: true), weight: weight),
            _FitNumber(netText(l10n, f.netPiastres, bare: true), weight: FontWeight.w700),
            if (total) const SizedBox.shrink() else _ShareBar(share: reportShare(f, report.totals)),
          ]),
        ),
      );
    }

    final table = Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: cells([
                Text(reportGroupName(l10n, group), style: header),
                if (withTypes) Text(reportCountersHeader(l10n, group), style: header),
                for (final t in types)
                  Text(
                    reportRowName(l10n, t, ReportGroup.type, languageCode),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: header,
                  ),
                Text(l10n.reportsColTickets, style: header),
                Text(l10n.reportsColSales, style: header),
                Text(l10n.reportsColRefunds, style: header),
                Text(l10n.reportsColTips, style: header),
                Text(l10n.reportsColNet, style: header),
                Text(l10n.reportsColShare, style: header),
              ]),
            ),
            if (rows.isEmpty)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: tokens.rowDivider)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(l10n.reportsEmpty, style: TextStyle(color: tokens.textSecondary)),
                ),
              )
            else ...[
              for (final (i, r) in rows.indexed)
                line(
                  reportRowName(l10n, r, group, languageCode),
                  r.figures,
                  r.typeTickets,
                  counters: r.counters,
                  total: false,
                  key: ValueKey('reports-row-$i'),
                ),
              line(
                l10n.reportsTotal,
                report.totals,
                {for (final t in types) t.id!: t.figures.tickets},
                total: true,
                key: const ValueKey('reports-total'),
              ),
            ],
          ],
        ),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= minWidth ? table : _SidewaysScroll(width: minWidth, child: table),
    );
  }
}

/// A table wider than the page: it scrolls sideways, with a scrollbar always
/// shown and mouse drag, since the page turns scrollbars off and a mouse
/// wheel only scrolls down.
class _SidewaysScroll extends StatefulWidget {
  const _SidewaysScroll({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  State<_SidewaysScroll> createState() => _SidewaysScrollState();
}

class _SidewaysScrollState extends State<_SidewaysScroll> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScrollConfiguration(
    behavior: ScrollConfiguration.of(
      context,
    ).copyWith(scrollbars: false, dragDevices: PointerDeviceKind.values.toSet()),
    child: Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      child: SingleChildScrollView(
        key: const ValueKey('reports-table-scroll'),
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: 14),
        child: SizedBox(width: widget.width, child: widget.child),
      ),
    ),
  );
}

/// A number cell: one line, shrunk to fit only when the column is too
/// narrow for it, so a year's totals stay whole and a day's keep full size.
class _FitNumber extends StatelessWidget {
  const _FitNumber(this.text, {required this.weight});

  final String text;
  final FontWeight weight;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: AlignmentDirectional.centerStart,
    child: Text(text, maxLines: 1, softWrap: false, style: TextStyle(fontWeight: weight)),
  );
}

/// A cashier's or a gate's counters, one per line. A long period can list many, and a
/// long name wraps, so the cell is at most [maxLines] lines high and scrolls
/// inside past that, its scrollbar always shown so the rest is seen to be
/// there.
class _CountersCell extends StatefulWidget {
  const _CountersCell({required this.counters});

  final List<ReportCounter> counters;

  static const maxLines = 3;
  static const _style = TextStyle(fontSize: 14, height: 1.4);

  @override
  State<_CountersCell> createState() => _CountersCellState();
}

class _CountersCellState extends State<_CountersCell> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in widget.counters) Text(reportCounterText(c), style: _CountersCell._style),
      ],
    );
    final lineHeight = _CountersCell._style.fontSize! * _CountersCell._style.height!;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: lineHeight * _CountersCell.maxLines),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(
          context,
        ).copyWith(scrollbars: false, dragDevices: PointerDeviceKind.values.toSet()),
        child: Scrollbar(
          controller: _controller,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _controller,
            // Room for the scrollbar, so it doesn't cover the text.
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: list,
          ),
        ),
      ),
    );
  }
}

/// The share of sales: a bar in a rounded track, and the percent.
class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.share});

  final double share;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 10,
              color: tokens.inset,
              alignment: AlignmentDirectional.centerStart,
              child: FractionallySizedBox(
                widthFactor: share.clamp(0.0, 1.0),
                child: Container(color: tokens.primary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text(
            '${(share * 100).round()}%',
            style: TextStyle(fontSize: 13, color: tokens.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.bg, required this.fg, this.border});

  final String text;
  final Color bg;
  final Color fg;
  final Color? border;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: bg,
      border: border == null ? null : Border.all(color: border!),
      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
    ),
    child: Text(text, style: TextStyle(fontSize: 14, color: fg)),
  );
}
