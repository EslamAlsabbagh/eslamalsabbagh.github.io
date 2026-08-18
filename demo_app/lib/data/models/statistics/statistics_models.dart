// Immutable DTOs for the Statistics dashboard. Each maps 1:1 onto the rows
// returned by a `stats_*` Supabase RPC (see the 20260714120000_statistics_
// dashboard.sql migration). Kept deliberately thin — no business logic, just
// typed transport from RPC JSON to chart widgets.

double _toDouble(dynamic v) => v == null ? 0.0 : (v as num).toDouble();
double? _toDoubleN(dynamic v) => v == null ? null : (v as num).toDouble();
int _toInt(dynamic v) => v == null ? 0 : (v as num).toInt();

/// stats_kpis → the four executive headline numbers.
class KpiSummary {
  final int total;
  final int pending;
  final double? avgApprovalDays; // null when nothing has been finalized yet
  final double? approvalRate; // 0..1, null when no approved/declined decisions

  const KpiSummary({
    this.total = 0,
    this.pending = 0,
    this.avgApprovalDays,
    this.approvalRate,
  });

  factory KpiSummary.fromJson(Map<String, dynamic> j) => KpiSummary(
        total: _toInt(j['total']),
        pending: _toInt(j['pending']),
        avgApprovalDays: _toDoubleN(j['avg_approval_days']),
        approvalRate: _toDoubleN(j['approval_rate']),
      );
}

/// Generic "label → count (+ optional magnitude)" row. Reused for status
/// distribution, by-department, violation category, action type, headcount, etc.
class CategoryCount {
  final String label;
  final int count;
  final double? value; // optional secondary magnitude (e.g. total days/amount)

  /// The label in the other language, when the DB stores both (departments carry
  /// an Arabic name next to english_department). Null for categories whose
  /// translation comes from an l10n key instead.
  final String? altLabel;

  const CategoryCount(this.label, this.count, {this.value, this.altLabel});

  factory CategoryCount.from(String label, dynamic count, {dynamic value, String? altLabel}) =>
      CategoryCount(label, _toInt(count), value: _toDoubleN(value), altLabel: altLabel);
}

/// One point in a monthly time series, tagged by series key (e.g. request type).
class TimeSeriesPoint {
  final DateTime month;
  final String seriesKey;
  final double value;

  const TimeSeriesPoint(this.month, this.seriesKey, this.value);
}

/// stats_funnel → an ordered approval-funnel stage.
class FunnelStage {
  final String stage; // submitted | n1 | n2 | hr | finalized
  final int count;
  const FunnelStage(this.stage, this.count);

  factory FunnelStage.fromJson(Map<String, dynamic> j) =>
      FunnelStage(j['stage'] as String, _toInt(j['cnt']));
}

/// stats_stage_latency → average dwell time (days) at a stage.
class StageLatency {
  final String stage; // n1 | n2 | hr
  final double? avgDays;
  const StageLatency(this.stage, this.avgDays);

  factory StageLatency.fromJson(Map<String, dynamic> j) =>
      StageLatency(j['stage'] as String, _toDoubleN(j['avg_days']));
}

/// stats_pending_heatmap → a single approver×type live-pending cell.
class HeatCell {
  final String approver;
  final String requestType;
  final int count;
  const HeatCell(this.approver, this.requestType, this.count);

  factory HeatCell.fromJson(Map<String, dynamic> j) => HeatCell(
        j['current_approver'] as String? ?? 'none',
        j['request_type'] as String? ?? 'unknown',
        _toInt(j['cnt']),
      );
}

/// stats_oldest_pending → one aging row for the bottleneck table.
class AgingRow {
  final String requestType;
  final String approver;
  final String? department;
  final String? departmentAr;
  final int? employeeCode;
  final int ageDays;
  final DateTime? createdAt;

  const AgingRow({
    required this.requestType,
    required this.approver,
    required this.ageDays,
    this.department,
    this.departmentAr,
    this.employeeCode,
    this.createdAt,
  });

  factory AgingRow.fromJson(Map<String, dynamic> j) => AgingRow(
        requestType: j['request_type'] as String? ?? 'unknown',
        approver: j['current_approver'] as String? ?? 'none',
        department: j['department_en'] as String?,
        departmentAr: j['department_ar'] as String?,
        employeeCode: j['employee_code'] == null ? null : _toInt(j['employee_code']),
        ageDays: _toInt(j['age_days']),
        createdAt: j['created_at'] == null ? null : DateTime.tryParse(j['created_at'].toString()),
      );
}

/// stats_leave_type_mix → per-leave-type count and total days.
class LeaveTypeMix {
  final String leaveType;
  final int count;
  final double totalDays;
  const LeaveTypeMix(this.leaveType, this.count, this.totalDays);

  factory LeaveTypeMix.fromJson(Map<String, dynamic> j) => LeaveTypeMix(
        j['leave_type'] as String? ?? 'Unknown',
        _toInt(j['cnt']),
        _toDouble(j['total_days']),
      );
}

/// stats_leave_balance_by_dept → per-department leave balance rollup.
class LeaveBalanceByDept {
  final String department;
  final String? departmentAr;
  final double avgBalance;
  final double avgTaken;
  final double avgCarryForward;
  final int headcount;

  const LeaveBalanceByDept({
    required this.department,
    required this.avgBalance,
    required this.avgTaken,
    required this.avgCarryForward,
    required this.headcount,
    this.departmentAr,
  });

  factory LeaveBalanceByDept.fromJson(Map<String, dynamic> j) => LeaveBalanceByDept(
        department: j['department_en'] as String? ?? 'Unknown',
        departmentAr: j['department_ar'] as String?,
        avgBalance: _toDouble(j['avg_balance']),
        avgTaken: _toDouble(j['avg_taken']),
        avgCarryForward: _toDouble(j['avg_carry_forward']),
        headcount: _toInt(j['headcount']),
      );
}

/// stats_advance_summary → financial KPIs for the advances perspective.
class AdvanceSummary {
  final int totalRequests;
  final double totalAmount;
  final double avgAmount;
  final double approvedAmount;
  final double? settlementRate; // 0..1

  const AdvanceSummary({
    this.totalRequests = 0,
    this.totalAmount = 0,
    this.avgAmount = 0,
    this.approvedAmount = 0,
    this.settlementRate,
  });

  factory AdvanceSummary.fromJson(Map<String, dynamic> j) => AdvanceSummary(
        totalRequests: _toInt(j['total_requests']),
        totalAmount: _toDouble(j['total_amount']),
        avgAmount: _toDouble(j['avg_amount']),
        approvedAmount: _toDouble(j['approved_amount']),
        settlementRate: _toDoubleN(j['settlement_rate']),
      );
}

/// stats_da_outcomes → disciplinary outcome counters.
class DaOutcomes {
  final int total;
  final int escalatedToLegal;
  final int suspensions;
  final int terminations;

  const DaOutcomes({
    this.total = 0,
    this.escalatedToLegal = 0,
    this.suspensions = 0,
    this.terminations = 0,
  });

  factory DaOutcomes.fromJson(Map<String, dynamic> j) => DaOutcomes(
        total: _toInt(j['total']),
        escalatedToLegal: _toInt(j['escalated_to_legal']),
        suspensions: _toInt(j['suspensions']),
        terminations: _toInt(j['terminations']),
      );
}
