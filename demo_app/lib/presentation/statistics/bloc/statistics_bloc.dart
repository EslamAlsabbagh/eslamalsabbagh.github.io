import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/statistics/statistics_models.dart';
import 'package:hrms_demo/data/repos/statistics/statistics_repo.dart';
import 'package:hrms_demo/presentation/statistics/bloc/statistics_event.dart';
import 'package:hrms_demo/presentation/statistics/bloc/statistics_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Orchestrates the Statistics dashboard. Each perspective loads lazily on first
/// view and is cached until the filter changes; a filter change clears every
/// perspective's status and reloads only the tab currently on screen, so
/// switching tabs afterwards refetches on demand.
class StatisticsBloc extends Bloc<StatisticsEvent, StatisticsState> {
  final StatisticsRepo repo;
  final int requestorCode;

  StatisticsBloc({required this.repo, required this.requestorCode, required StatsFilter initialFilter})
    : super(StatisticsState(filter: initialFilter)) {
    on<StatsPerspectiveOpened>(_onOpened);
    on<StatsPerspectiveRefreshed>(_onRefreshed);
    on<StatsFilterChanged>(_onFilterChanged);
  }

  Future<void> _onOpened(StatsPerspectiveOpened e, Emitter<StatisticsState> emit) async {
    // Lazy: skip if already loaded or in flight for the current filter.
    final s = state.statusOf(e.perspective);
    if (s == Status.success || s == Status.loading) return;
    await _load(e.perspective, emit);
  }

  Future<void> _onRefreshed(StatsPerspectiveRefreshed e, Emitter<StatisticsState> emit) async {
    await _load(e.perspective, emit);
  }

  Future<void> _onFilterChanged(StatsFilterChanged e, Emitter<StatisticsState> emit) async {
    // Invalidate every perspective; the visible one reloads immediately, the
    // rest lazily when reopened.
    emit(state.copyWith(filter: e.filter, statuses: const {}));
    await _load(e.active, emit);
  }

  Future<void> _load(StatsPerspective p, Emitter<StatisticsState> emit) async {
    emit(state.withStatus(p, Status.loading));
    final f = state.filter;
    try {
      switch (p) {
        case StatsPerspective.overview:
          final r = await Future.wait([
            repo.getKpis(requestorCode, f),
            repo.getVolumeByTypeMonth(requestorCode, f),
            repo.getStatusDistribution(requestorCode, f),
            repo.getByDepartment(requestorCode, f),
          ]);
          emit(
            state
                .copyWith(
                  kpis: r[0] as KpiSummary,
                  volumeByType: r[1] as List<TimeSeriesPoint>,
                  statusDistribution: r[2] as List<CategoryCount>,
                  byDepartment: r[3] as List<CategoryCount>,
                )
                .withStatus(p, Status.success),
          );
          break;
        case StatsPerspective.funnel:
          final r = await Future.wait([
            repo.getFunnel(requestorCode, f),
            repo.getStageLatency(requestorCode, f),
            repo.getPendingHeatmap(requestorCode, f),
            repo.getOldestPending(requestorCode, f),
          ]);
          emit(
            state
                .copyWith(
                  funnel: r[0] as List<FunnelStage>,
                  stageLatency: r[1] as List<StageLatency>,
                  pendingHeatmap: r[2] as List<HeatCell>,
                  oldestPending: r[3] as List<AgingRow>,
                )
                .withStatus(p, Status.success),
          );
          break;
        case StatsPerspective.leave:
          final r = await Future.wait([
            repo.getLeaveTypeMix(requestorCode, f),
            repo.getLeaveSeasonality(requestorCode, f),
            repo.getLeaveBalanceByDept(requestorCode, f),
          ]);
          emit(
            state
                .copyWith(
                  leaveTypeMix: r[0] as List<LeaveTypeMix>,
                  leaveSeasonality: r[1] as List<TimeSeriesPoint>,
                  leaveBalanceByDept: r[2] as List<LeaveBalanceByDept>,
                )
                .withStatus(p, Status.success),
          );
          break;
        case StatsPerspective.financial:
          final r = await Future.wait([
            repo.getAdvanceSummary(requestorCode, f),
            repo.getAdvanceByMonth(requestorCode, f),
          ]);
          emit(
            state
                .copyWith(advanceSummary: r[0] as AdvanceSummary, advanceByMonth: r[1] as List<TimeSeriesPoint>)
                .withStatus(p, Status.success),
          );
          break;
        case StatsPerspective.disciplinary:
          final r = await Future.wait([
            repo.getViolationCategory(requestorCode, f),
            repo.getDaActionType(requestorCode, f),
            repo.getDaOutcomes(requestorCode, f),
          ]);
          emit(
            state
                .copyWith(
                  violationCategory: r[0] as List<CategoryCount>,
                  daActionType: r[1] as List<CategoryCount>,
                  daOutcomes: r[2] as DaOutcomes,
                )
                .withStatus(p, Status.success),
          );
          break;
        case StatsPerspective.workforce:
          final r = await Future.wait([
            repo.getHeadcountByDepartment(requestorCode, f),
            repo.getHeadcountByLocation(requestorCode, f),
            repo.getTenureBuckets(requestorCode, f),
          ]);
          emit(
            state
                .copyWith(headcountByDepartment: r[0], headcountByLocation: r[1], tenureBuckets: r[2])
                .withStatus(p, Status.success),
          );
          break;
      }
    } catch (e) {
      emit(state.copyWith(failure: Failure(e.toString())).withStatus(p, Status.failure));
    }
  }
}
