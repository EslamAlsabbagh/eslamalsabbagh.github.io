import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/statistics/statistics_models.dart';
import 'package:hrms_demo/data/repos/statistics/statistics_repo.dart';

/// The six analytical lenses. Each maps to one tab and one lazy-loaded bundle
/// of RPC results.
enum StatsPerspective { overview, funnel, leave, financial, disciplinary, workforce }

/// The filter dimensions the bar can offer.
enum StatsFilterKind { dateRange, department, location, requestType }

/// Which filters actually take effect per perspective — the filter bar renders
/// only these, so a control is never shown that the tab's RPCs would ignore.
///
/// Two dimensions are deliberately absent in places:
///  • `requestType` — only where a tab spans multiple request types. Leave,
///    Financial and Disciplinary are already scoped to one type, and Workforce
///    isn't request-based at all.
///  • `dateRange` — absent on Workforce: headcount/tenure is a *current snapshot*
///    of `users`, not a date-ranged aggregate.
///
/// Keep in sync with the `_params(...)` flags in `statistics_repo_impl.dart` and
/// the RPC signatures — a filter shown here must be a parameter the RPC declares.
const Map<StatsPerspective, Set<StatsFilterKind>> kApplicableFilters = {
  StatsPerspective.overview: {
    StatsFilterKind.dateRange,
    StatsFilterKind.department,
    StatsFilterKind.location,
    StatsFilterKind.requestType,
  },
  StatsPerspective.funnel: {
    StatsFilterKind.dateRange,
    StatsFilterKind.department,
    StatsFilterKind.location,
    StatsFilterKind.requestType,
  },
  StatsPerspective.leave: {StatsFilterKind.dateRange, StatsFilterKind.department, StatsFilterKind.location},
  StatsPerspective.financial: {StatsFilterKind.dateRange, StatsFilterKind.department, StatsFilterKind.location},
  StatsPerspective.disciplinary: {StatsFilterKind.dateRange, StatsFilterKind.department, StatsFilterKind.location},
  StatsPerspective.workforce: {StatsFilterKind.department, StatsFilterKind.location},
};

/// Data + load-status for the whole dashboard. Per-perspective [Status] lets a
/// tab show its own spinner/error while others stay cached. A filter change
/// resets all statuses to [Status.initial] and the visible tab reloads.
class StatisticsState {
  final StatsFilter filter;
  final Map<StatsPerspective, Status> statuses;
  final Failure? failure;

  // Overview
  final KpiSummary? kpis;
  final List<TimeSeriesPoint> volumeByType;
  final List<CategoryCount> statusDistribution;
  final List<CategoryCount> byDepartment;

  // Funnel
  final List<FunnelStage> funnel;
  final List<StageLatency> stageLatency;
  final List<HeatCell> pendingHeatmap;
  final List<AgingRow> oldestPending;

  // Leave
  final List<LeaveTypeMix> leaveTypeMix;
  final List<TimeSeriesPoint> leaveSeasonality;
  final List<LeaveBalanceByDept> leaveBalanceByDept;

  // Financial
  final AdvanceSummary? advanceSummary;
  final List<TimeSeriesPoint> advanceByMonth;

  // Disciplinary
  final List<CategoryCount> violationCategory;
  final List<CategoryCount> daActionType;
  final DaOutcomes? daOutcomes;

  // Workforce
  final List<CategoryCount> headcountByDepartment;
  final List<CategoryCount> headcountByLocation;
  final List<CategoryCount> tenureBuckets;

  const StatisticsState({
    required this.filter,
    this.statuses = const {},
    this.failure,
    this.kpis,
    this.volumeByType = const [],
    this.statusDistribution = const [],
    this.byDepartment = const [],
    this.funnel = const [],
    this.stageLatency = const [],
    this.pendingHeatmap = const [],
    this.oldestPending = const [],
    this.leaveTypeMix = const [],
    this.leaveSeasonality = const [],
    this.leaveBalanceByDept = const [],
    this.advanceSummary,
    this.advanceByMonth = const [],
    this.violationCategory = const [],
    this.daActionType = const [],
    this.daOutcomes,
    this.headcountByDepartment = const [],
    this.headcountByLocation = const [],
    this.tenureBuckets = const [],
  });

  Status statusOf(StatsPerspective p) => statuses[p] ?? Status.initial;

  StatisticsState withStatus(StatsPerspective p, Status s) {
    final next = Map<StatsPerspective, Status>.from(statuses);
    next[p] = s;
    return copyWith(statuses: next);
  }

  StatisticsState copyWith({
    StatsFilter? filter,
    Map<StatsPerspective, Status>? statuses,
    Failure? failure,
    KpiSummary? kpis,
    List<TimeSeriesPoint>? volumeByType,
    List<CategoryCount>? statusDistribution,
    List<CategoryCount>? byDepartment,
    List<FunnelStage>? funnel,
    List<StageLatency>? stageLatency,
    List<HeatCell>? pendingHeatmap,
    List<AgingRow>? oldestPending,
    List<LeaveTypeMix>? leaveTypeMix,
    List<TimeSeriesPoint>? leaveSeasonality,
    List<LeaveBalanceByDept>? leaveBalanceByDept,
    AdvanceSummary? advanceSummary,
    List<TimeSeriesPoint>? advanceByMonth,
    List<CategoryCount>? violationCategory,
    List<CategoryCount>? daActionType,
    DaOutcomes? daOutcomes,
    List<CategoryCount>? headcountByDepartment,
    List<CategoryCount>? headcountByLocation,
    List<CategoryCount>? tenureBuckets,
  }) {
    return StatisticsState(
      filter: filter ?? this.filter,
      statuses: statuses ?? this.statuses,
      failure: failure ?? this.failure,
      kpis: kpis ?? this.kpis,
      volumeByType: volumeByType ?? this.volumeByType,
      statusDistribution: statusDistribution ?? this.statusDistribution,
      byDepartment: byDepartment ?? this.byDepartment,
      funnel: funnel ?? this.funnel,
      stageLatency: stageLatency ?? this.stageLatency,
      pendingHeatmap: pendingHeatmap ?? this.pendingHeatmap,
      oldestPending: oldestPending ?? this.oldestPending,
      leaveTypeMix: leaveTypeMix ?? this.leaveTypeMix,
      leaveSeasonality: leaveSeasonality ?? this.leaveSeasonality,
      leaveBalanceByDept: leaveBalanceByDept ?? this.leaveBalanceByDept,
      advanceSummary: advanceSummary ?? this.advanceSummary,
      advanceByMonth: advanceByMonth ?? this.advanceByMonth,
      violationCategory: violationCategory ?? this.violationCategory,
      daActionType: daActionType ?? this.daActionType,
      daOutcomes: daOutcomes ?? this.daOutcomes,
      headcountByDepartment: headcountByDepartment ?? this.headcountByDepartment,
      headcountByLocation: headcountByLocation ?? this.headcountByLocation,
      tenureBuckets: tenureBuckets ?? this.tenureBuckets,
    );
  }
}
