// GENERATED SCAFFOLD - in-memory stand-in for StatisticsRepo.
//
// The demo build has no backend. Every member below returns a type-correct
// empty value unless it has been hand-written to read from DemoStore, so a
// screen that touches an unmodelled corner renders empty instead of crashing.

import 'package:hrms_demo/data/models/statistics/statistics_models.dart';
import 'package:hrms_demo/data/repos/statistics/statistics_repo.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeStatisticsRepo implements StatisticsRepo {
  FakeStatisticsRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  @override
  Future<KpiSummary> getKpis(int requestorCode, StatsFilter f) async => throw UnimplementedError('StatisticsRepo.getKpis is not part of the demo dataset.');

  @override
  Future<List<TimeSeriesPoint>> getVolumeByTypeMonth(int requestorCode, StatsFilter f) async => <TimeSeriesPoint>[];

  @override
  Future<List<CategoryCount>> getStatusDistribution(int requestorCode, StatsFilter f) async => <CategoryCount>[];

  @override
  Future<List<CategoryCount>> getByDepartment(int requestorCode, StatsFilter f) async => <CategoryCount>[];

  @override
  Future<List<FunnelStage>> getFunnel(int requestorCode, StatsFilter f) async => <FunnelStage>[];

  @override
  Future<List<StageLatency>> getStageLatency(int requestorCode, StatsFilter f) async => <StageLatency>[];

  @override
  Future<List<HeatCell>> getPendingHeatmap(int requestorCode, StatsFilter f) async => <HeatCell>[];

  @override
  Future<List<AgingRow>> getOldestPending(int requestorCode, StatsFilter f, {int limit = 10}) async => <AgingRow>[];

  @override
  Future<List<LeaveTypeMix>> getLeaveTypeMix(int requestorCode, StatsFilter f) async => <LeaveTypeMix>[];

  @override
  Future<List<TimeSeriesPoint>> getLeaveSeasonality(int requestorCode, StatsFilter f) async => <TimeSeriesPoint>[];

  @override
  Future<List<LeaveBalanceByDept>> getLeaveBalanceByDept(int requestorCode, StatsFilter f) async => <LeaveBalanceByDept>[];

  @override
  Future<AdvanceSummary> getAdvanceSummary(int requestorCode, StatsFilter f) async => throw UnimplementedError('StatisticsRepo.getAdvanceSummary is not part of the demo dataset.');

  @override
  Future<List<TimeSeriesPoint>> getAdvanceByMonth(int requestorCode, StatsFilter f) async => <TimeSeriesPoint>[];

  @override
  Future<List<CategoryCount>> getViolationCategory(int requestorCode, StatsFilter f) async => <CategoryCount>[];

  @override
  Future<List<CategoryCount>> getDaActionType(int requestorCode, StatsFilter f) async => <CategoryCount>[];

  @override
  Future<DaOutcomes> getDaOutcomes(int requestorCode, StatsFilter f) async => throw UnimplementedError('StatisticsRepo.getDaOutcomes is not part of the demo dataset.');

  @override
  Future<List<CategoryCount>> getHeadcountByDepartment(int requestorCode, StatsFilter f) async => <CategoryCount>[];

  @override
  Future<List<CategoryCount>> getHeadcountByLocation(int requestorCode, StatsFilter f) async => <CategoryCount>[];

  @override
  Future<List<CategoryCount>> getTenureBuckets(int requestorCode, StatsFilter f) async => <CategoryCount>[];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
