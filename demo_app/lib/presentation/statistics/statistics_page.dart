import 'package:hrms_demo/core/constants/department.dart';
import 'package:hrms_demo/core/constants/locations.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/theme/app_colors.dart';
import 'package:hrms_demo/data/models/statistics/statistics_models.dart';
import 'package:hrms_demo/data/repos/statistics/statistics_repo.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_state.dart';
import 'package:hrms_demo/presentation/statistics/bloc/statistics_bloc.dart';
import 'package:hrms_demo/presentation/statistics/bloc/statistics_event.dart';
import 'package:hrms_demo/presentation/statistics/bloc/statistics_state.dart';
import 'package:hrms_demo/presentation/statistics/widgets/aging_table.dart';
import 'package:hrms_demo/presentation/statistics/widgets/bar_chart_card.dart';
import 'package:hrms_demo/presentation/statistics/widgets/donut_chart_card.dart';
import 'package:hrms_demo/presentation/statistics/widgets/funnel_card.dart';
import 'package:hrms_demo/presentation/statistics/widgets/heatmap_grid.dart';
import 'package:hrms_demo/presentation/statistics/widgets/line_chart_card.dart';
import 'package:hrms_demo/presentation/statistics/widgets/paired_bar_card.dart';
import 'package:hrms_demo/presentation/statistics/widgets/stat_widgets.dart';
import 'package:hrms_demo/presentation/statistics/widgets/stats_labels.dart';
import 'package:hrms_demo/presentation/widgets/loading_logo.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

/// Company-wide Statistics dashboard. Gated to the `dashboard` group (the
/// sidebar hides the entry; this screen double-checks and the RPCs enforce it
/// server-side). Six tabbed perspectives, each lazily loaded via [StatisticsBloc].
class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  static StatsFilter _defaultFilter() {
    final now = DateTime.now();
    return StatsFilter(dateFrom: DateTime(now.year, 1, 1), dateTo: now);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MainLayout(
      title: l10n.statistics,
      child: BlocBuilder<UserBloc, UserState>(
        builder: (context, userState) {
          if (userState.status != Status.success || userState.user == null) {
            return const Center(child: LoadingLogo());
          }
          final user = userState.user!;
          final isMember = user.groups?.contains('dashboard') ?? false;
          if (!isMember) {
            return Center(
              child: Text(l10n.statsAccessDenied, style: const TextStyle(fontSize: 15, color: AppColors.inkSecondary)),
            );
          }
          return BlocProvider<StatisticsBloc>(
            create:
                (_) => StatisticsBloc(
                  repo: context.read<StatisticsRepo>(),
                  requestorCode: user.id!,
                  initialFilter: _defaultFilter(),
                  // Must be the FIRST tab, not a fixed perspective: the tab listener
                  // only fires on index CHANGE, so whatever opens first would never
                  // load itself and would spin forever.
                )..add(StatsPerspectiveOpened(_tabOrder.first)),
            child: const _StatisticsView(),
          );
        },
      ),
    );
  }
}

/// Tab order — the single source of truth. The TabBar labels, the TabBarView
/// children and the initial load all derive from this list, so reordering the
/// tabs means editing only here.
const List<StatsPerspective> _tabOrder = [
  StatsPerspective.workforce,
  StatsPerspective.overview,
  StatsPerspective.funnel,
  StatsPerspective.leave,
  StatsPerspective.financial,
  StatsPerspective.disciplinary,
];

class _StatisticsView extends StatefulWidget {
  const _StatisticsView();

  @override
  State<_StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<_StatisticsView> with SingleTickerProviderStateMixin {
  late final TabController _tab;
  int _activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabOrder.length, vsync: this);
    _tab.addListener(() {
      // The index guard covers both taps and swipes, and the setState is what
      // lets the filter bar re-render for the newly active tab — without it the
      // bar would keep showing the previous tab's filters.
      if (_tab.index != _activeIndex) {
        setState(() => _activeIndex = _tab.index);
        context.read<StatisticsBloc>().add(StatsPerspectiveOpened(_tabOrder[_tab.index]));
      }
    });
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  StatsPerspective get _active => _tabOrder[_activeIndex];

  /// Localized tab label. Kept next to [_builderFor] so a perspective's label and
  /// its content can never drift apart when the order changes.
  String _tabLabel(BuildContext context, StatsPerspective p) {
    final l10n = AppLocalizations.of(context)!;
    switch (p) {
      case StatsPerspective.overview:
        return l10n.statsOverview;
      case StatsPerspective.funnel:
        return l10n.statsApprovalFunnel;
      case StatsPerspective.leave:
        return l10n.statsLeaveAttendance;
      case StatsPerspective.financial:
        return l10n.statsFinancial;
      case StatsPerspective.disciplinary:
        return l10n.statsDisciplinary;
      case StatsPerspective.workforce:
        return l10n.statsWorkforce;
    }
  }

  Widget Function(BuildContext, StatisticsState, double) _builderFor(StatsPerspective p) {
    switch (p) {
      case StatsPerspective.overview:
        return _overview;
      case StatsPerspective.funnel:
        return _funnel;
      case StatsPerspective.leave:
        return _leave;
      case StatsPerspective.financial:
        return _financial;
      case StatsPerspective.disciplinary:
        return _disciplinary;
      case StatsPerspective.workforce:
        return _workforce;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.white,
          child: TabBar(
            controller: _tab,
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.inkMuted,
            indicatorColor: AppColors.primary,
            tabs: [for (final p in _tabOrder) Tab(text: _tabLabel(context, p))],
          ),
        ),
        // Filters sit UNDER the tabs: they scope the active tab's content, so
        // they belong to the tab rather than reading as page-level chrome.
        _FilterBar(
          active: _active,
          onChanged: (f) => context.read<StatisticsBloc>().add(StatsFilterChanged(f, _active)),
        ),
        Expanded(
          child: Container(
            color: AppColors.pagePlane,
            child: TabBarView(
              controller: _tab,
              children: [for (final p in _tabOrder) _Perspective(p, builder: _builderFor(p))],
            ),
          ),
        ),
      ],
    );
  }

  // ── Responsive card sizing ──────────────────────────────────────────────
  double _col(BuildContext c, double avail, int desktopCols) {
    if (c.isMobile) return avail;
    final cols = c.isTablet ? (desktopCols > 2 ? 2 : desktopCols) : desktopCols;
    return (avail - (cols - 1) * 24) / cols;
  }

  // ── OVERVIEW ─────────────────────────────────────────────────────────────
  Widget _overview(BuildContext context, StatisticsState s, double avail) {
    final l10n = AppLocalizations.of(context)!;
    final k = s.kpis ?? const KpiSummary();
    final half = _col(context, avail, 2);

    // Build stacked-bar inputs from the monthly volume time series.
    final months = <DateTime>{for (final p in s.volumeByType) p.month}.toList()..sort();
    final xLabels = [for (final m in months) DateFormat('MMM').format(m)];
    final stacks = [
      for (final m in months) {for (final p in s.volumeByType.where((e) => e.month == m)) p.seriesKey: p.value},
    ];
    final presentTypes = <String>{for (final p in s.volumeByType) p.seriesKey}.toList();
    final seriesColors = {for (final t in presentTypes) t: AppColors.forRequestType(t)};

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        StatKpiTile(
          value: NumberFormat.decimalPattern().format(k.total),
          caption: l10n.statsTotalRequests,
          icon: Icons.receipt_long_rounded,
          accent: AppColors.cat1Blue,
        ),
        StatKpiTile(
          value: '${k.pending}',
          caption: l10n.statsPendingApproval,
          icon: Icons.pending_actions_rounded,
          accent: AppColors.statusPending,
        ),
        StatKpiTile(
          value: k.avgApprovalDays == null ? '—' : '${k.avgApprovalDays!.toStringAsFixed(1)}d',
          caption: l10n.statsAvgApprovalTime,
          icon: Icons.timer_outlined,
          accent: AppColors.cat2Aqua,
        ),
        StatKpiTile(
          value: k.approvalRate == null ? '—' : '${(k.approvalRate! * 100).toStringAsFixed(1)}%',
          caption: l10n.statsApprovalRate,
          icon: Icons.verified_outlined,
          accent: AppColors.statusApproved,
        ),
        StackedBarChartCard(
          title: l10n.statsVolumeByType,
          icon: Icons.stacked_bar_chart_rounded,
          xLabels: xLabels,
          stacks: stacks,
          seriesColors: seriesColors,
          seriesLabel: (k) => StatsLabels.requestType(context, k),
          width: half,
        ),
        DonutChartCard(
          title: l10n.statsStatusDistribution,
          icon: Icons.donut_large_rounded,
          width: half,
          slices: [
            for (final c in s.statusDistribution)
              (
                label: StatsLabels.status(context, c.label),
                value: c.count.toDouble(),
                color: AppColors.forStatus(c.label),
              ),
          ],
        ),
        HorizontalBarCard(
          title: l10n.statsRequestsByDepartment,
          icon: Icons.apartment_rounded,
          width: avail,
          maxBars: 20,
          data: [
            for (final c in s.byDepartment)
              (
                label: StatsLabels.department(context, c.label, c.altLabel),
                value: c.count.toDouble(),
                color: AppColors.cat1Blue,
              ),
          ],
        ),
      ],
    );
  }

  // ── APPROVAL FUNNEL ──────────────────────────────────────────────────────
  Widget _funnel(BuildContext context, StatisticsState s, double avail) {
    final l10n = AppLocalizations.of(context)!;
    final half = _col(context, avail, 2);

    final approvers = <String>{for (final h in s.pendingHeatmap) h.approver}.toList();
    final types = <String>{for (final h in s.pendingHeatmap) h.requestType}.toList();
    final heat = <String, Map<String, int>>{};
    for (final h in s.pendingHeatmap) {
      (heat[h.approver] ??= {})[h.requestType] = h.count;
    }

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        FunnelCard(
          title: l10n.statsApprovalFunnel,
          icon: Icons.filter_alt_outlined,
          width: half,
          stages: [for (final f in s.funnel) (label: StatsLabels.funnelStage(context, f.stage), count: f.count)],
        ),
        HorizontalBarCard(
          title: l10n.statsAvgTimePerStage,
          icon: Icons.timelapse_rounded,
          width: half,
          // Day averages are fractional — keep the decimal and say the unit.
          valueFormat: (v) => '${formatValue(v)}d',
          data: [
            for (final l in s.stageLatency)
              (label: StatsLabels.approver(context, l.stage), value: l.avgDays ?? 0, color: AppColors.cat3Yellow),
          ],
        ),
        HeatmapGrid(
          title: l10n.statsPendingByApprover,
          icon: Icons.grid_on_rounded,
          width: avail,
          rowKeys: approvers,
          colKeys: types,
          values: heat,
          rowLabel: (k) => StatsLabels.approver(context, k),
          colLabel: (k) => StatsLabels.requestType(context, k),
        ),
        AgingTable(title: l10n.statsOldestPending, rows: s.oldestPending, width: avail),
      ],
    );
  }

  // ── LEAVE & ATTENDANCE ───────────────────────────────────────────────────
  Widget _leave(BuildContext context, StatisticsState s, double avail) {
    final l10n = AppLocalizations.of(context)!;
    final half = _col(context, avail, 2);
    final months = s.leaveSeasonality.map((p) => p.month).toList()..sort();

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        DonutChartCard(
          title: l10n.statsLeaveTypeMix,
          icon: Icons.beach_access_rounded,
          width: half,
          slices: [
            for (int i = 0; i < s.leaveTypeMix.length; i++)
              (
                label: StatsLabels.leaveType(context, s.leaveTypeMix[i].leaveType),
                value: s.leaveTypeMix[i].count.toDouble(),
                color: AppColors.categoricalAt(i),
              ),
          ],
        ),
        LineChartCard(
          title: l10n.statsLeaveSeasonality,
          icon: Icons.show_chart_rounded,
          width: half,
          xLabels: [for (final m in months) DateFormat('MMM').format(m)],
          values: [for (final m in months) s.leaveSeasonality.firstWhere((p) => p.month == m).value],
          color: AppColors.cat1Blue,
        ),
        // Taken vs available on ONE shared scale, so "who is burning through
        // leave vs sitting on it" reads directly from the bar pair.
        PairedBarCard(
          title: l10n.statsTakenVsBalanceByDept,
          icon: Icons.account_balance_wallet_outlined,
          width: avail,
          seriesALabel: l10n.statsTakenThisYear,
          seriesBLabel: l10n.statsAvailableBalance,
          seriesAColor: AppColors.cat1Blue,
          seriesBColor: AppColors.cat2Aqua,
          data: [
            for (final d in s.leaveBalanceByDept)
              (label: StatsLabels.department(context, d.department, d.departmentAr), a: d.avgTaken, b: d.avgBalance),
          ],
        ),
      ],
    );
  }

  // ── FINANCIAL (ADVANCES) ─────────────────────────────────────────────────
  Widget _financial(BuildContext context, StatisticsState s, double avail) {
    final l10n = AppLocalizations.of(context)!;
    final a = s.advanceSummary ?? const AdvanceSummary();
    final money = NumberFormat.compactCurrency(symbol: '', decimalDigits: 1);
    final months = s.advanceByMonth.map((p) => p.month).toList()..sort();

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        StatKpiTile(
          value: money.format(a.totalAmount),
          caption: l10n.statsTotalAdvances,
          icon: Icons.payments_outlined,
          accent: AppColors.cat2Aqua,
        ),
        StatKpiTile(
          value: money.format(a.avgAmount),
          caption: l10n.statsAvgAdvance,
          icon: Icons.request_quote_outlined,
          accent: AppColors.cat1Blue,
        ),
        StatKpiTile(
          value: money.format(a.approvedAmount),
          caption: l10n.statsApprovedAmount,
          icon: Icons.check_circle_outline_rounded,
          accent: AppColors.statusApproved,
        ),
        StatKpiTile(
          value: a.settlementRate == null ? '—' : '${(a.settlementRate! * 100).toStringAsFixed(0)}%',
          caption: l10n.statsSettlementRate,
          icon: Icons.handshake_outlined,
          accent: AppColors.cat5Violet,
        ),
        LineChartCard(
          title: l10n.statsAdvancesDisbursed,
          icon: Icons.trending_up_rounded,
          width: avail,
          xLabels: [for (final m in months) DateFormat('MMM').format(m)],
          values: [for (final m in months) s.advanceByMonth.firstWhere((p) => p.month == m).value],
          color: AppColors.cat2Aqua,
        ),
      ],
    );
  }

  // ── DISCIPLINARY & COMPLIANCE ────────────────────────────────────────────
  Widget _disciplinary(BuildContext context, StatisticsState s, double avail) {
    final l10n = AppLocalizations.of(context)!;
    final half = _col(context, avail, 2);
    final o = s.daOutcomes ?? const DaOutcomes();

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        StatKpiTile(
          value: '${o.total}',
          caption: l10n.statsTotalCases,
          icon: Icons.gavel_rounded,
          accent: AppColors.cat6Red,
        ),
        StatKpiTile(
          value: '${o.escalatedToLegal}',
          caption: l10n.statsEscalatedToLegal,
          icon: Icons.balance_rounded,
          accent: AppColors.cat3Yellow,
        ),
        StatKpiTile(
          value: '${o.suspensions}',
          caption: l10n.statsSuspensions,
          icon: Icons.block_rounded,
          accent: AppColors.statusOnHold,
        ),
        StatKpiTile(
          value: '${o.terminations}',
          caption: l10n.statsTerminations,
          icon: Icons.person_off_outlined,
          accent: AppColors.statusDeclined,
        ),
        DonutChartCard(
          title: l10n.statsViolationCategories,
          icon: Icons.report_gmailerrorred_rounded,
          width: half,
          slices: [
            for (int i = 0; i < s.violationCategory.length; i++)
              (
                label: StatsLabels.violationCategory(context, s.violationCategory[i].label),
                value: s.violationCategory[i].count.toDouble(),
                color: AppColors.categoricalAt(i),
              ),
          ],
        ),
        HorizontalBarCard(
          title: l10n.statsActionTypes,
          icon: Icons.rule_rounded,
          width: half,
          data: [
            for (final c in s.daActionType)
              (label: StatsLabels.actionType(context, c.label), value: c.count.toDouble(), color: AppColors.cat6Red),
          ],
        ),
      ],
    );
  }

  // ── WORKFORCE / DEMOGRAPHICS ─────────────────────────────────────────────
  Widget _workforce(BuildContext context, StatisticsState s, double avail) {
    final l10n = AppLocalizations.of(context)!;
    final half = _col(context, avail, 2);

    // All three partition the same whole (total headcount), so each shows its
    // share of the workforce beside the raw count.
    final byDepartment = HorizontalBarCard(
      title: l10n.statsHeadcountByDepartment,
      icon: Icons.groups_rounded,
      width: half,
      maxBars: 20,
      showPercent: true,
      data: [
        for (final c in s.headcountByDepartment)
          (
            label: StatsLabels.department(context, c.label, c.altLabel),
            value: c.count.toDouble(),
            color: AppColors.cat1Blue,
          ),
      ],
    );

    final byLocation = DonutChartCard(
      title: l10n.statsHeadcountByLocation,
      icon: Icons.place_outlined,
      width: half,
      centerCaption: l10n.statsHeadcount,
      showCounts: true,
      slices: [
        for (int i = 0; i < s.headcountByLocation.length; i++)
          (
            label: s.headcountByLocation[i].label,
            value: s.headcountByLocation[i].count.toDouble(),
            color: AppColors.categoricalAt(i),
          ),
      ],
    );

    final tenure = HorizontalBarCard(
      title: l10n.statsTenureDistribution,
      icon: Icons.badge_outlined,
      width: half,
      showPercent: true,
      data: [
        for (final c in s.tenureBuckets)
          (label: StatsLabels.tenureBucket(context, c.label), value: c.count.toDouble(), color: AppColors.cat5Violet),
      ],
    );

    // Narrow screens: one card per row — a side-by-side split would be cramped.
    // (_col already returns the full width when isMobile, so these are full-bleed.)
    if (context.isMobile) {
      return Wrap(spacing: 24, runSpacing: 24, children: [byDepartment, byLocation, tenure]);
    }

    // Department (tall, 20 rows) on the left, the two shorter charts stacked on
    // the right. Halving its width stops the department bars from stretching
    // across the whole canvas, and fills what was dead space beside them.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        byDepartment,
        const SizedBox(width: 24),
        Column(mainAxisSize: MainAxisSize.min, children: [byLocation, const SizedBox(height: 24), tenure]),
      ],
    );
  }
}

/// Wraps a perspective with per-tab loading/error handling and the scrollable,
/// responsive card canvas.
class _Perspective extends StatelessWidget {
  final StatsPerspective perspective;
  final Widget Function(BuildContext, StatisticsState, double avail) builder;

  const _Perspective(this.perspective, {required this.builder});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<StatisticsBloc, StatisticsState>(
      builder: (context, s) {
        final status = s.statusOf(perspective);
        if (status == Status.loading || status == Status.initial) {
          return const Center(child: LoadingLogo());
        }
        if (status == Status.failure) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.statusDeclined, size: 40),
                const SizedBox(height: 8),
                Text(s.failure?.message ?? l10n.unknownError, style: const TextStyle(color: AppColors.inkSecondary)),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.read<StatisticsBloc>().add(StatsPerspectiveRefreshed(perspective)),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(l10n.statsRetry),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(builder: (context, c) => builder(context, s, c.maxWidth)),
        );
      },
    );
  }
}

/// Filter bar for the active tab: date-range preset, department, location and
/// request-type. Only the filters that actually take effect for [active] are
/// rendered (see `kApplicableFilters`) — a control is never shown that the tab's
/// RPCs would ignore. A hidden filter keeps its value; it simply isn't sent to
/// RPCs that don't accept it, so returning to a tab restores the selection.
///
/// A change invalidates caches and reloads the visible tab via [onChanged],
/// which the parent view fires with the currently-active perspective.
class _FilterBar extends StatelessWidget {
  final StatsPerspective active;
  final ValueChanged<StatsFilter> onChanged;
  const _FilterBar({required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filter = context.select<StatisticsBloc, StatsFilter>((b) => b.state.filter);
    final now = DateTime.now();
    final shown = kApplicableFilters[active]!;

    void apply(StatsFilter f) => onChanged(f);

    final ranges = <String, StatsFilter>{
      l10n.statsThisMonth: StatsFilter(dateFrom: DateTime(now.year, now.month, 1), dateTo: now),
      l10n.statsLast3Months: StatsFilter(dateFrom: DateTime(now.year, now.month - 2, 1), dateTo: now),
      l10n.statsThisYear: StatsFilter(dateFrom: DateTime(now.year, 1, 1), dateTo: now),
      l10n.statsLast12Months: StatsFilter(dateFrom: DateTime(now.year - 1, now.month, 1), dateTo: now),
    };
    // Which preset matches the current filter (by from-date), default This year.
    String currentRange = l10n.statsThisYear;
    ranges.forEach((k, v) {
      if (v.dateFrom.year == filter.dateFrom.year && v.dateFrom.month == filter.dateFrom.month) {
        currentRange = k;
      }
    });

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (shown.contains(StatsFilterKind.dateRange))
            _FilterDropdown<String>(
              icon: Icons.calendar_today_rounded,
              value: currentRange,
              items: [for (final k in ranges.keys) DropdownMenuItem(value: k, child: Text(k))],
              onChanged: (v) {
                if (v != null) {
                  apply(
                    ranges[v]!.copyWith(
                      department: filter.department,
                      location: filter.location,
                      requestType: filter.requestType,
                    ),
                  );
                }
              },
            ),
          if (shown.contains(StatsFilterKind.department))
            _FilterDropdown<String?>(
              icon: Icons.apartment_rounded,
              value: filter.department,
              hint: l10n.statsAllDepartments,
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.statsAllDepartments)),
                // Value stays the English name (that's what users.english_department
                // stores and what the RPC matches); only the display is localized.
                for (final d in Department.values)
                  DropdownMenuItem(value: d.getEnglishText(), child: Text(d.localizedLabel(context))),
              ],
              onChanged: (v) => apply(filter.copyWith(department: v, clearDepartment: v == null)),
            ),
          if (shown.contains(StatsFilterKind.location))
            _FilterDropdown<String?>(
              icon: Icons.place_outlined,
              value: filter.location,
              hint: l10n.statsAllLocations,
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.statsAllLocations)),
                for (final loc in kEmployeeLocations) DropdownMenuItem(value: loc, child: Text(loc)),
              ],
              onChanged: (v) => apply(filter.copyWith(location: v, clearLocation: v == null)),
            ),
          if (shown.contains(StatsFilterKind.requestType))
            _FilterDropdown<String?>(
              icon: Icons.category_outlined,
              value: filter.requestType,
              hint: l10n.statsAllTypes,
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.statsAllTypes)),
                for (final t in const [
                  'leave',
                  'business_trip',
                  'overtime',
                  'missing_punching',
                  'advance_on_salary',
                  'disciplinary_action',
                  'hr_letter',
                ])
                  DropdownMenuItem(value: t, child: Text(StatsLabels.requestType(context, t))),
              ],
              onChanged: (v) => apply(filter.copyWith(requestType: v, clearRequestType: v == null)),
            ),
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final IconData icon;
  final T value;
  final String? hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.pagePlane,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gridline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.inkMuted),
          const SizedBox(width: 8),
          DropdownButton<T>(
            value: value,
            hint: hint == null ? null : Text(hint!),
            underline: const SizedBox.shrink(),
            isDense: true,
            style: const TextStyle(fontSize: 13, color: AppColors.inkPrimary),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
