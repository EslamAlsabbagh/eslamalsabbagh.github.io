import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/clock.dart';
import '../../../core/money.dart';
import '../../../core/printer/print_service.dart';
import '../../../core/printer/printer_client.dart';
import '../../../core/printer/printer_status.dart';
import '../../../core/printer/printer_target.dart';
import '../../../core/printer/shift_receipt.dart';
import '../../offline/data/offline_models.dart';
import '../../sell/data/sell_repository.dart';
import '../data/close_shift.dart';
import '../data/shift_repository.dart';
import 'shift_cubit.dart';

/// Counting, waiting for `close_shift`, or closed with its receipt.
enum CloseStage { counting, closing, closed }

class CloseShiftState extends Equatable {
  const CloseShiftState({
    required this.now,
    this.loading = true,
    this.loadFailure,
    this.settings,
    this.tips = const [],
    this.awaitingPayment,
    this.checkingAwaiting = false,
    this.counts = const {},
    this.tipPiastres,
    this.tipTyped = false,
    this.addingTip = false,
    this.tipFailure,
    this.stage = CloseStage.counting,
    this.closeFailure,
    this.receipt,
    this.receiptPrint = PrinterStatus.printing,
    this.queue = const QueueStatus(),
  });

  /// When the screen loaded: the header's "to" until the shift is closed.
  final DateTime now;
  final bool loading;
  final ShiftFailureKind? loadFailure;
  final CloseShiftSettings? settings;
  final List<ShiftTip> tips;

  /// Orders of the shift still awaiting payment (`my_shift_counts`); null when
  /// they couldn't be read, and then the server's check decides.
  final int? awaitingPayment;
  final bool checkingAwaiting;

  /// Count per denomination (piastres). A denomination not in it is 0.
  final Map<int, int> counts;

  /// The forgotten tip to add: a quick amount, or what is typed ([tipTyped]);
  /// null when nothing is picked or the typed text isn't an amount.
  final int? tipPiastres;
  final bool tipTyped;
  final bool addingTip;
  final ShiftFailureKind? tipFailure;

  final CloseStage stage;
  final ShiftFailureKind? closeFailure;

  /// Set once `close_shift` has answered.
  final ShiftReceipt? receipt;

  /// The receipt's print: [PrinterStatus.printing], `printed`, `printFailed`
  /// or `notSet` (no printer for the counter).
  final PrinterStatus receiptPrint;

  /// The shift's offline orders not on the server yet (ADR-0015): the shift
  /// can't close until they upload, and the server can't check them.
  final QueueStatus queue;

  int countOf(int denomination) => counts[denomination] ?? 0;

  int get countedPiastres => counts.entries.fold(0, (sum, entry) => sum + entry.key * entry.value);

  int get tipsTotalPiastres => tips.fold(0, (sum, tip) => sum + tip.amountPiastres);

  /// Off in settings, or the server said so on an add.
  bool get tipsEnabled =>
      (settings?.tipsEnabled ?? false) && tipFailure != ShiftFailureKind.tipsDisabled;

  bool get canAddTip =>
      tipsEnabled && (tipPiastres ?? 0) > 0 && !addingTip && stage == CloseStage.counting;

  bool get blockedByAwaiting => (awaitingPayment ?? 0) > 0;

  bool get blockedByQueue => !queue.isEmpty;

  bool get canClose =>
      !loading &&
      loadFailure == null &&
      stage == CloseStage.counting &&
      !blockedByAwaiting &&
      !blockedByQueue &&
      !checkingAwaiting &&
      !addingTip &&
      closeFailure != ShiftFailureKind.noOpenShift;

  CloseShiftState copyWith({
    bool? loading,
    Object? loadFailure = _keep,
    CloseShiftSettings? settings,
    List<ShiftTip>? tips,
    Object? awaitingPayment = _keep,
    bool? checkingAwaiting,
    Map<int, int>? counts,
    Object? tipPiastres = _keep,
    bool? tipTyped,
    bool? addingTip,
    Object? tipFailure = _keep,
    CloseStage? stage,
    Object? closeFailure = _keep,
    ShiftReceipt? receipt,
    PrinterStatus? receiptPrint,
    QueueStatus? queue,
  }) =>
      CloseShiftState(
        now: now,
        loading: loading ?? this.loading,
        loadFailure: loadFailure == _keep ? this.loadFailure : loadFailure as ShiftFailureKind?,
        settings: settings ?? this.settings,
        tips: tips ?? this.tips,
        awaitingPayment: awaitingPayment == _keep ? this.awaitingPayment : awaitingPayment as int?,
        checkingAwaiting: checkingAwaiting ?? this.checkingAwaiting,
        counts: counts ?? this.counts,
        tipPiastres: tipPiastres == _keep ? this.tipPiastres : tipPiastres as int?,
        tipTyped: tipTyped ?? this.tipTyped,
        addingTip: addingTip ?? this.addingTip,
        tipFailure: tipFailure == _keep ? this.tipFailure : tipFailure as ShiftFailureKind?,
        stage: stage ?? this.stage,
        closeFailure: closeFailure == _keep ? this.closeFailure : closeFailure as ShiftFailureKind?,
        receipt: receipt ?? this.receipt,
        receiptPrint: receiptPrint ?? this.receiptPrint,
        queue: queue ?? this.queue,
      );

  /// Marks a nullable field [copyWith] leaves as it is.
  static const _keep = Object();

  @override
  List<Object?> get props => [
        now,
        loading,
        loadFailure,
        settings,
        tips,
        awaitingPayment,
        checkingAwaiting,
        counts,
        tipPiastres,
        tipTyped,
        addingTip,
        tipFailure,
        stage,
        closeFailure,
        receipt,
        receiptPrint,
        queue,
      ];
}

/// The close shift screen (`CloseShift.dc.html`): the blind count by
/// denomination, the shift's tips and a forgotten one, then `close_shift`
/// and its printed receipt (ADR-0008). Nothing here knows expected cash.
///
/// The receipt is printed from this screen only: once it's left, the
/// cashier can't read the closed shift again (ADR-0014), so a failed print
/// is retried here with no second server call.
class CloseShiftCubit extends Cubit<CloseShiftState> {
  CloseShiftCubit({
    required this._repository,
    required this._sellRepository,
    required this._printer,
    required this._shift,
    required this._target,
    required this._clock,
  }) : super(CloseShiftState(now: _clock.now()));

  final ShiftRepository _repository;

  /// For the orders still awaiting payment (`my_shift_counts`).
  final SellRepository _sellRepository;
  final PrintService _printer;
  final ShiftCubit _shift;

  /// This counter's printer; null when none is set.
  final PrinterTarget? _target;
  final Clock _clock;

  /// Highest count a field takes: 99,999 notes.
  static const maxCount = 99999;

  Future<void> load() async {
    emit(CloseShiftState(now: _clock.now(), queue: state.queue));
    try {
      final settings = await _repository.closeShiftSettings();
      final tips = await _repository.myShiftTips();
      final awaiting = await _awaiting();
      if (isClosed) return;
      emit(
        state.copyWith(loading: false, settings: settings, tips: tips, awaitingPayment: awaiting),
      );
    } on ShiftFailure catch (e) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, loadFailure: e.kind));
      // Closed meanwhile (elsewhere): reloading it lets the router leave.
      if (e.kind == ShiftFailureKind.noOpenShift) await _shift.load();
    }
  }

  /// Null when the counts can't be read: the close itself still checks.
  Future<int?> _awaiting() async {
    try {
      return (await _sellRepository.myShiftCounts()).awaitingPaymentCount;
    } on SellFailure {
      return null;
    }
  }

  /// The offline queue as `OfflineSyncCubit` sees it; the page passes each
  /// change on.
  void setQueue(QueueStatus queue) {
    if (isClosed || state.stage != CloseStage.counting) return;
    emit(state.copyWith(queue: queue));
  }

  /// "Check again" on the awaiting-payment message.
  Future<void> checkAwaiting() async {
    if (state.checkingAwaiting) return;
    emit(state.copyWith(checkingAwaiting: true));
    final awaiting = await _awaiting();
    if (isClosed) return;
    emit(
      state.copyWith(
        checkingAwaiting: false,
        awaitingPayment: awaiting,
        closeFailure: state.closeFailure == ShiftFailureKind.ordersAwaitingPayment
            ? null
            : state.closeFailure,
      ),
    );
  }

  void setCount(int denomination, int count) {
    if (state.stage != CloseStage.counting) return;
    final clamped = count.clamp(0, maxCount);
    if (clamped == state.countOf(denomination)) return;
    emit(state.copyWith(counts: {...state.counts, denomination: clamped}, closeFailure: null));
  }

  void increment(int denomination) => setCount(denomination, state.countOf(denomination) + 1);

  void decrement(int denomination) => setCount(denomination, state.countOf(denomination) - 1);

  /// A quick tip amount; it replaces anything typed.
  void pickTip(int piastres) =>
      emit(state.copyWith(tipPiastres: piastres, tipTyped: false, tipFailure: null));

  /// The typed tip, in pounds. Empty falls back to nothing picked.
  void typeTip(String text) {
    if (text.trim().isEmpty) {
      return emit(state.copyWith(tipPiastres: null, tipTyped: false, tipFailure: null));
    }
    emit(state.copyWith(tipPiastres: parsePiastres(text), tipTyped: true, tipFailure: null));
  }

  /// `add_tip` with the picked or typed amount. Tips can't be removed.
  Future<void> addTip() async {
    final amount = state.tipPiastres;
    if (!state.canAddTip || amount == null) return;
    emit(state.copyWith(addingTip: true, tipFailure: null));
    try {
      final tip = await _repository.addTip(amount);
      if (isClosed) return;
      emit(
        state.copyWith(
          addingTip: false,
          tips: [...state.tips, tip],
          tipPiastres: null,
          tipTyped: false,
        ),
      );
    } on ShiftFailure catch (e) {
      if (isClosed) return;
      emit(state.copyWith(addingTip: false, tipFailure: e.kind));
    }
  }

  /// `close_shift` with the count, then the receipt's print.
  Future<void> closeShift() async {
    final settings = state.settings;
    if (!state.canClose || settings == null) return;
    emit(state.copyWith(stage: CloseStage.closing, closeFailure: null));
    try {
      final receipt = await _repository.closeShift(state.counts, venueName: settings.venueName);
      _shift.forgetCopy();
      if (isClosed) return;
      emit(state.copyWith(stage: CloseStage.closed, receipt: receipt));
    } on ShiftFailure catch (e) {
      if (isClosed) return;
      if (e.kind == ShiftFailureKind.ordersAwaitingPayment) {
        // The counts were stale or unreadable: show the message, with the
        // number when it can be read.
        final awaiting = await _awaiting();
        if (isClosed) return;
        emit(
          state.copyWith(
            stage: CloseStage.counting,
            awaitingPayment: (awaiting ?? 0) > 0 ? awaiting : 1,
          ),
        );
      } else {
        emit(state.copyWith(stage: CloseStage.counting, closeFailure: e.kind));
      }
      return;
    }
    await printReceipt();
  }

  /// Prints the receipt, or again after a failure: no server call.
  Future<void> printReceipt() async {
    final receipt = state.receipt;
    if (receipt == null || _printing) return;
    final target = _target;
    if (target == null) return emit(state.copyWith(receiptPrint: PrinterStatus.notSet));
    _printing = true;
    emit(state.copyWith(receiptPrint: PrinterStatus.printing));
    try {
      await _printer.printShiftReceipt(target, receipt);
      if (!isClosed) emit(state.copyWith(receiptPrint: PrinterStatus.printed));
    } on PrinterException {
      if (!isClosed) emit(state.copyWith(receiptPrint: PrinterStatus.printFailed));
    } finally {
      _printing = false;
    }
  }

  /// A print in progress: a double tap on Retry doesn't print twice.
  bool _printing = false;
}
