import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/clock.dart';
import '../../../core/printer/print_service.dart';
import '../../../core/printer/printer_client.dart';
import '../../../core/printer/printer_status.dart';
import '../../../core/printer/printer_target.dart';
import '../../../core/printer/test_page.dart';
import '../data/open_shift.dart';
import '../data/shift_repository.dart';
import 'shift_cubit.dart';

/// Why a shift can't be opened on this PC at all. Each has one message.
enum OpenShiftBlock { noCounterConfigured, counterUnavailable, counterNoHomeGate }

class OpenShiftState extends Equatable {
  const OpenShiftState({
    required this.today,
    this.loading = true,
    this.loadFailure,
    this.block,
    this.counter,
    this.quickAmountsPiastres = const [],
    this.venueName = '',
    this.lastClosedAt,
    this.printer = PrinterStatus.checking,
    this.submitting = false,
    this.failure,
  });

  /// When the screen loaded: the header date, and "today" / "yesterday" in
  /// the banner.
  final DateTime today;
  final bool loading;

  /// The counter or settings couldn't be read.
  final ShiftFailureKind? loadFailure;
  final OpenShiftBlock? block;
  final CounterInfo? counter;
  final List<int> quickAmountsPiastres;

  /// For the test page's sample ticket.
  final String venueName;

  /// When this counter's last shift closed; null hides the banner.
  final DateTime? lastClosedAt;
  final PrinterStatus printer;
  final bool submitting;

  /// The last `open_shift` call failed.
  final ShiftFailureKind? failure;

  bool get canOpen => !loading && loadFailure == null && block == null && !submitting;

  OpenShiftState copyWith({
    bool? loading,
    Object? loadFailure = _keep,
    Object? block = _keep,
    CounterInfo? counter,
    List<int>? quickAmountsPiastres,
    String? venueName,
    DateTime? lastClosedAt,
    PrinterStatus? printer,
    bool? submitting,
    Object? failure = _keep,
  }) =>
      OpenShiftState(
        today: today,
        loading: loading ?? this.loading,
        loadFailure: loadFailure == _keep ? this.loadFailure : loadFailure as ShiftFailureKind?,
        block: block == _keep ? this.block : block as OpenShiftBlock?,
        counter: counter ?? this.counter,
        quickAmountsPiastres: quickAmountsPiastres ?? this.quickAmountsPiastres,
        venueName: venueName ?? this.venueName,
        lastClosedAt: lastClosedAt ?? this.lastClosedAt,
        printer: printer ?? this.printer,
        submitting: submitting ?? this.submitting,
        failure: failure == _keep ? this.failure : failure as ShiftFailureKind?,
      );

  /// Marks a nullable field [copyWith] leaves as it is.
  static const _keep = Object();

  @override
  List<Object?> get props => [
        today,
        loading,
        loadFailure,
        block,
        counter,
        quickAmountsPiastres,
        venueName,
        lastClosedAt,
        printer,
        submitting,
        failure,
      ];
}

/// The open shift screen (`OpenShift.dc.html`): this PC's counter, the quick
/// float amounts, the last-closed banner, the printer check and test print,
/// and `open_shift`. A shift it opens goes to [ShiftCubit], and the router
/// moves on to selling.
class OpenShiftCubit extends Cubit<OpenShiftState> {
  OpenShiftCubit({
    required this._repository,
    required this._printer,
    required this._shift,
    required this._counterId,
    required this._cashierName,
    required this._clock,
  }) : super(OpenShiftState(today: _clock.now()));

  final ShiftRepository _repository;
  final PrintService _printer;
  final ShiftCubit _shift;
  final String? _counterId;

  /// The signed-in staff member, on the test page's sample ticket.
  final String _cashierName;
  final Clock _clock;

  Future<void> load() async {
    emit(OpenShiftState(today: _clock.now()));
    final counterId = _counterId;
    if (counterId == null) {
      return emit(state.copyWith(loading: false, block: OpenShiftBlock.noCounterConfigured));
    }
    try {
      final counter = await _repository.counter(counterId);
      final settings = await _repository.openShiftSettings();
      final lastClosedAt = await _lastClosedAt(counterId);
      if (isClosed) return;
      final block = switch (counter) {
        null || CounterInfo(active: false) => OpenShiftBlock.counterUnavailable,
        CounterInfo(hasHomeGate: false) => OpenShiftBlock.counterNoHomeGate,
        _ => null,
      };
      emit(state.copyWith(
        loading: false,
        block: block,
        counter: counter,
        quickAmountsPiastres: settings.quickAmountsPiastres,
        venueName: settings.venueName,
        lastClosedAt: lastClosedAt,
      ));
    } on ShiftFailure catch (e) {
      if (!isClosed) emit(state.copyWith(loading: false, loadFailure: e.kind));
      return;
    }
    if (state.block == null) await checkPrinter();
  }

  /// Only for the banner: if it can't be read, the banner stays hidden.
  Future<DateTime?> _lastClosedAt(String counterId) async {
    try {
      return await _repository.lastClosedAt(counterId);
    } on ShiftFailure {
      return null;
    }
  }

  Future<void> checkPrinter() async {
    final counter = state.counter;
    if (counter == null) return;
    final target = _target(counter);
    if (target == null) return emit(state.copyWith(printer: PrinterStatus.notSet));
    emit(state.copyWith(printer: PrinterStatus.checking));
    final reachable = await _printer.isReachable(target);
    if (isClosed) return;
    emit(state.copyWith(printer: reachable ? PrinterStatus.reachable : PrinterStatus.unreachable));
  }

  /// Tried even when the check said unreachable: the printer may be back.
  Future<void> testPrint() async {
    final counter = state.counter;
    final target = counter == null ? null : _target(counter);
    if (counter == null || target == null || state.printer == PrinterStatus.printing) return;
    emit(state.copyWith(printer: PrinterStatus.printing));
    final info = TestPageInfo(
      venueName: state.venueName,
      counterName: counter.name,
      cashierName: _cashierName,
      homeGateName: counter.homeGateName,
      now: _clock.now(),
    );
    try {
      await _printer.printTestPage(target, info);
      if (!isClosed) emit(state.copyWith(printer: PrinterStatus.printed));
    } on PrinterException {
      if (!isClosed) emit(state.copyWith(printer: PrinterStatus.printFailed));
    }
  }

  /// Null when the counter has no printer address.
  static PrinterTarget? _target(CounterInfo counter) {
    final host = counter.printerHost;
    if (host == null) return null;
    return PrinterTarget(host: host, port: counter.printerPort, paperWidthMm: counter.paperWidthMm);
  }

  /// Opens the shift with [openingCashPiastres] (null: nothing typed).
  Future<void> submit(int? openingCashPiastres) async {
    final counterId = _counterId;
    if (!state.canOpen || counterId == null) return;
    if (openingCashPiastres == null || openingCashPiastres < 0) {
      return emit(state.copyWith(failure: ShiftFailureKind.invalidOpeningCash));
    }
    emit(state.copyWith(submitting: true, failure: null));
    try {
      final shift = await _repository.openShift(counterId, openingCashPiastres);
      // The router leaves this screen now, so nothing more is emitted.
      _shift.opened(shift);
    } on ShiftFailure catch (e) {
      if (isClosed) return;
      switch (e.kind) {
        case ShiftFailureKind.counterNoHomeGate:
          emit(state.copyWith(submitting: false, block: OpenShiftBlock.counterNoHomeGate));
        case ShiftFailureKind.counterUnavailable:
          emit(state.copyWith(submitting: false, block: OpenShiftBlock.counterUnavailable));
        case ShiftFailureKind.shiftAlreadyOpen:
          // Opened meanwhile (on another PC, or a double click): reload it,
          // and the router or this screen takes it from there.
          emit(state.copyWith(submitting: false));
          await _shift.load();
        default:
          emit(state.copyWith(submitting: false, failure: e.kind));
      }
    }
  }
}
