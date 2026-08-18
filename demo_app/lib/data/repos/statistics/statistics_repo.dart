import 'package:hrms_demo/data/models/statistics/statistics_models.dart';

/// A dashboard filter selection. Passed to every repo call; the repo translates
/// it into the shared `p_date_from / p_date_to / p_department / p_location /
/// p_request_type` RPC parameters. Null department/location/requestType mean "all".
///
/// Not every perspective honours every field — see `kApplicableFilters` in
/// `statistics_state.dart` for the per-tab matrix, which is what the filter bar
/// renders from.
class StatsFilter {
  final DateTime dateFrom;
  final DateTime dateTo;

  /// English department name (matches users.english_department), or null for all.
  final String? department;

  /// Employee site (matches users."Location / Site" — see [kEmployeeLocations]),
  /// or null for all.
  final String? location;

  /// requestType value (e.g. 'leave'), or null for all.
  final String? requestType;

  const StatsFilter({
    required this.dateFrom,
    required this.dateTo,
    this.department,
    this.location,
    this.requestType,
  });

  StatsFilter copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? department,
    String? location,
    String? requestType,
    bool clearDepartment = false,
    bool clearLocation = false,
    bool clearRequestType = false,
  }) {
    return StatsFilter(
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      department: clearDepartment ? null : (department ?? this.department),
      location: clearLocation ? null : (location ?? this.location),
      requestType: clearRequestType ? null : (requestType ?? this.requestType),
    );
  }

  // location participates in equality: StatisticsBloc caches per filter, so
  // omitting it would serve stale charts when only the location changed.
  @override
  bool operator ==(Object other) =>
      other is StatsFilter &&
      other.dateFrom == dateFrom &&
      other.dateTo == dateTo &&
      other.department == department &&
      other.location == location &&
      other.requestType == requestType;

  @override
  int get hashCode => Object.hash(dateFrom, dateTo, department, location, requestType);
}

/// Read-only aggregation gateway for the Statistics dashboard. Every method is a
/// single Supabase RPC that returns already-grouped data — the app never
/// aggregates raw rows client-side.
abstract class StatisticsRepo {
  // Overview
  Future<KpiSummary> getKpis(int requestorCode, StatsFilter f);
  Future<List<TimeSeriesPoint>> getVolumeByTypeMonth(int requestorCode, StatsFilter f);
  Future<List<CategoryCount>> getStatusDistribution(int requestorCode, StatsFilter f);
  Future<List<CategoryCount>> getByDepartment(int requestorCode, StatsFilter f);

  // Approval funnel
  Future<List<FunnelStage>> getFunnel(int requestorCode, StatsFilter f);
  Future<List<StageLatency>> getStageLatency(int requestorCode, StatsFilter f);
  Future<List<HeatCell>> getPendingHeatmap(int requestorCode, StatsFilter f);
  Future<List<AgingRow>> getOldestPending(int requestorCode, StatsFilter f, {int limit = 10});

  // Leave & attendance
  Future<List<LeaveTypeMix>> getLeaveTypeMix(int requestorCode, StatsFilter f);
  Future<List<TimeSeriesPoint>> getLeaveSeasonality(int requestorCode, StatsFilter f);
  Future<List<LeaveBalanceByDept>> getLeaveBalanceByDept(int requestorCode, StatsFilter f);

  // Financial (advances)
  Future<AdvanceSummary> getAdvanceSummary(int requestorCode, StatsFilter f);
  Future<List<TimeSeriesPoint>> getAdvanceByMonth(int requestorCode, StatsFilter f);

  // Disciplinary
  Future<List<CategoryCount>> getViolationCategory(int requestorCode, StatsFilter f);
  Future<List<CategoryCount>> getDaActionType(int requestorCode, StatsFilter f);
  Future<DaOutcomes> getDaOutcomes(int requestorCode, StatsFilter f);

  // Workforce / demographics — a current snapshot of `users`, so these honour
  // department/location but NOT the date range.
  Future<List<CategoryCount>> getHeadcountByDepartment(int requestorCode, StatsFilter f);
  Future<List<CategoryCount>> getHeadcountByLocation(int requestorCode, StatsFilter f);
  Future<List<CategoryCount>> getTenureBuckets(int requestorCode, StatsFilter f);
}
