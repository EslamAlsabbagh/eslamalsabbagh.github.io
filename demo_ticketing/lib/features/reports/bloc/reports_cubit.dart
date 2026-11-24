import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/reports_repository.dart';
import '../data/sales_report_models.dart';

class ReportsState extends Equatable {
  const ReportsState({
    this.period = ReportPeriod.today,
    this.from,
    this.to,
    this.group = ReportGroup.type,
    this.report,
    this.failure,
    this.loading = false,
  });

  final ReportPeriod period;

  /// The picked dates, with [ReportPeriod.range].
  final DateTime? from;
  final DateTime? to;

  /// Picks the table's rows from [report]; no server call.
  final ReportGroup group;

  /// The last answer for this period; kept when a later refresh fails.
  final SalesReport? report;

  /// Why the last load failed; null after a good one.
  final ReportsFailureKind? failure;

  /// A load is in flight. A long range can take several seconds.
  final bool loading;

  ReportsState copyWith({
    ReportPeriod? period,
    DateTime? Function()? from,
    DateTime? Function()? to,
    ReportGroup? group,
    SalesReport? Function()? report,
    ReportsFailureKind? Function()? failure,
    bool? loading,
  }) => ReportsState(
    period: period ?? this.period,
    from: from != null ? from() : this.from,
    to: to != null ? to() : this.to,
    group: group ?? this.group,
    report: report != null ? report() : this.report,
    failure: failure != null ? failure() : this.failure,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [period, from, to, group, report, failure, loading];
}

/// The Reports page (4.4). No Realtime and no poll, like the Shifts and
/// Actions log pages: it reads on entry, on a period change and on Refresh.
class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit(this._repository) : super(const ReportsState());

  final ReportsRepository _repository;

  // Answers to an older request are dropped.
  int _request = 0;

  Future<void> start() => refresh();

  /// A named period; [ReportPeriod.range] goes through [setRange].
  Future<void> setPeriod(ReportPeriod period) async {
    if (period == ReportPeriod.range || period == state.period) return;
    emit(
      state.copyWith(
        period: period,
        from: () => null,
        to: () => null,
        report: () => null,
        failure: () => null,
      ),
    );
    await refresh();
  }

  /// Venue dates, both included.
  Future<void> setRange(DateTime from, DateTime to) async {
    if (state.period == ReportPeriod.range && from == state.from && to == state.to) return;
    emit(
      state.copyWith(
        period: ReportPeriod.range,
        from: () => from,
        to: () => to,
        report: () => null,
        failure: () => null,
      ),
    );
    await refresh();
  }

  void setGroup(ReportGroup group) => emit(state.copyWith(group: group));

  Future<void> refresh() async {
    final request = ++_request;
    emit(state.copyWith(loading: true));
    try {
      final report = await _repository.load(period: state.period, from: state.from, to: state.to);
      if (isClosed || request != _request) return;
      emit(state.copyWith(report: () => report, failure: () => null, loading: false));
    } on ReportsFailure catch (e) {
      if (isClosed || request != _request) return;
      emit(state.copyWith(failure: () => e.kind, loading: false));
    }
  }
}
