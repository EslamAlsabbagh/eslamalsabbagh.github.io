import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/clock.dart';
import '../../../core/connectivity/server_status_cubit.dart';
import '../../../core/printer/print_service.dart';
import '../../../core/printer/printer_status.dart';
import '../../../core/printer/printer_target.dart';
import '../../offline/data/offline_store.dart';
import '../../shift/bloc/shift_cubit.dart';
import '../../shift/data/open_shift.dart';
import '../../shift/data/shift_repository.dart';
import '../data/sell_draft.dart';
import '../data/sell_repository.dart';
import '../data/sold_order.dart';
import '../data/ticket_type.dart';

class SellState extends Equatable {
  const SellState({
    this.loading = true,
    this.loadFailure,
    this.types = const [],
    this.settings,
    this.counter,
    this.quantities = const {},
    this.method = PaymentMethod.cash,
    this.counts,
    this.printer = PrinterStatus.checking,
    this.peak = false,
    this.periodNotices = 0,
  });

  final bool loading;

  /// The ticket types or the counter couldn't be read.
  final SellFailureKind? loadFailure;
  final List<TicketType> types;

  /// Set once loaded.
  final SellSettings? settings;

  /// This PC's counter: its name and printer. Null when it doesn't exist.
  final CounterInfo? counter;

  /// Ticket type id → quantity in the current order; only quantities above 0.
  final Map<String, int> quantities;
  final PaymentMethod method;

  /// Null until loaded, or when they couldn't be: the footer shows "—" and
  /// selling goes on.
  final ShiftCounts? counts;
  final PrinterStatus printer;

  /// Peak time now, by the settings' schedule and this PC's clock
  /// (ADR-0033). Decides which types are on sale; the server checks again.
  final bool peak;

  /// Goes up each time peak started or ended with a type in the order that
  /// isn't on sale any more (it was taken out): the screen says so.
  final int periodNotices;

  /// The types on sale now, in the admin's order.
  List<TicketType> get visibleTypes =>
      [for (final type in types) if (type.salePeriod.onSale(peak: peak)) type];

  /// Null when the counter has no printer address.
  PrinterTarget? get printerTarget {
    final counter = this.counter;
    final host = counter?.printerHost;
    if (counter == null || host == null) return null;
    return PrinterTarget(host: host, port: counter.printerPort, paperWidthMm: counter.paperWidthMm);
  }

  int quantityOf(TicketType type) => quantities[type.id] ?? 0;

  /// The current order, in the types' order.
  List<OrderLine> get lines => [
        for (final type in types)
          if (quantityOf(type) > 0) OrderLine(type, quantityOf(type)),
      ];

  bool get isEmpty => lines.isEmpty;
  int get ticketCount => lines.fold(0, (sum, line) => sum + line.quantity);

  /// This order's total at the prices shown. Not a shift total (ADR-0008).
  int get totalPiastres => lines.fold(0, (sum, line) => sum + line.subtotalPiastres);

  /// Null while the order is empty.
  SellDraft? get draft => isEmpty ? null : SellDraft(lines: lines, method: method);

  SellState copyWith({
    bool? loading,
    Object? loadFailure = _keep,
    List<TicketType>? types,
    SellSettings? settings,
    CounterInfo? counter,
    Map<String, int>? quantities,
    PaymentMethod? method,
    Object? counts = _keep,
    PrinterStatus? printer,
    bool? peak,
    int? periodNotices,
  }) =>
      SellState(
        loading: loading ?? this.loading,
        loadFailure: loadFailure == _keep ? this.loadFailure : loadFailure as SellFailureKind?,
        types: types ?? this.types,
        settings: settings ?? this.settings,
        counter: counter ?? this.counter,
        quantities: quantities ?? this.quantities,
        method: method ?? this.method,
        counts: counts == _keep ? this.counts : counts as ShiftCounts?,
        printer: printer ?? this.printer,
        peak: peak ?? this.peak,
        periodNotices: periodNotices ?? this.periodNotices,
      );

  /// Marks a nullable field [copyWith] leaves as it is.
  static const _keep = Object();

  @override
  List<Object?> get props => [
        loading,
        loadFailure,
        types,
        settings,
        counter,
        quantities,
        method,
        counts,
        printer,
        peak,
        periodNotices,
      ];
}

/// The sell screen (`Main.dc.html`): the ticket types, the order being put
/// together, the payment method, the shift's counts and the printer badge.
/// Selling the order is `CheckoutCubit`'s.
class SellCubit extends Cubit<SellState> {
  SellCubit({
    required this._repository,
    required this._shiftRepository,
    required this._printer,
    required this._shift,
    required this._counterId,
    required this._store,
    required this._status,
    this._clock = const Clock(),
    this._boundaryTimerFactory = Timer.new,
  }) : super(const SellState());

  final SellRepository _repository;

  /// For the counter's printer address.
  final ShiftRepository _shiftRepository;
  final PrintService _printer;
  final ShiftCubit _shift;
  final String? _counterId;

  /// The copy of the types, settings, counter and counts that selling uses
  /// while the server is out of reach (ADR-0015).
  final OfflineStore _store;
  final ServerStatusCubit _status;
  final Clock _clock;

  /// Makes the timer for the next peak boundary; tests pass one they fire
  /// by hand.
  final Timer Function(Duration delay, void Function() callback) _boundaryTimerFactory;

  static const _typesKey = 'ticket_types';
  static const _settingsKey = 'sell_settings';
  static String _counterKey(String id) => 'counter:$id';
  static String _countsKey(String shiftId) => 'shift_counts:$shiftId';

  String? get _shiftId => switch (_shift.state) {
        ShiftOpen(:final shift) => shift.id,
        _ => null,
      };

  /// Offline, or started from the shift's copy with the server not confirmed
  /// yet (ADR-0026): don't wait on a call that will time out.
  bool get _useCopy => switch (_shift.state) {
        ShiftOpen(fromCopy: true) => true,
        _ => _status.isOffline,
      };

  /// Reads the types, the settings and the counter from the server and keeps
  /// a copy; while offline, or when the server doesn't answer, uses the copy.
  Future<void> load() async {
    emit(const SellState());
    if (_useCopy) {
      if (!_loadCached(SellFailureKind.serverUnreachable)) return;
    } else {
      try {
        final types = await _repository.ticketTypes();
        final settings = await _repository.sellSettings();
        final counterId = _counterId;
        final counter = counterId == null ? null : await _shiftRepository.counter(counterId);
        if (isClosed) return;
        _saveCopy(types, settings, counter);
        emit(state.copyWith(loading: false, types: types, settings: settings, counter: counter));
      } on SellFailure catch (e) {
        if (isClosed || !_fallBack(e.kind)) return;
      } on ShiftFailure catch (e) {
        final kind = e.kind == ShiftFailureKind.serverUnreachable
            ? SellFailureKind.serverUnreachable
            : SellFailureKind.unexpected;
        if (isClosed || !_fallBack(kind)) return;
      }
    }
    if (state.settings case final settings?) _status.configure(settings.healthCheckSeconds);
    _checkPeak(notice: false);
    _peakTimer?.cancel();
    _peakTimer = Timer.periodic(peakCheckEvery, (_) => _checkPeak());
    // Each answered health check re-reads the peak settings, so a supervisor's
    // switch reaches this counter within offline_health_check_seconds.
    _answers ??= _status.answers.listen((_) => unawaited(refreshPeakSettings()));
    await Future.wait([refreshCounts(), checkPrinter()]);
    if (state.settings case final settings? when !isClosed) _watchPrinter(settings.healthCheckSeconds);
  }

  /// The server confirmed a shift started from its copy: the copy of the types,
  /// settings and counter may be from earlier, so read them again. The order
  /// being put together stays, for the types still on sale. A failure keeps
  /// what is on screen.
  Future<void> refreshFromServer() async {
    if (_useCopy) return;
    try {
      final types = await _repository.ticketTypes();
      final settings = await _repository.sellSettings();
      final counterId = _counterId;
      final counter = counterId == null ? null : await _shiftRepository.counter(counterId);
      if (isClosed) return;
      _saveCopy(types, settings, counter);
      final ids = {for (final type in types) type.id};
      emit(state.copyWith(
        loading: false,
        loadFailure: null,
        types: types,
        settings: settings,
        counter: counter,
        quantities: {
          for (final MapEntry(:key, :value) in state.quantities.entries)
            if (ids.contains(key)) key: value,
        },
      ));
      _status.configure(settings.healthCheckSeconds);
      _watchPrinter(settings.healthCheckSeconds);
      _checkPeak();
    } on SellFailure {
      return;
    } on ShiftFailure {
      return;
    }
    await Future.wait([refreshCounts(), checkPrinter()]);
  }

  /// A failed load: the copy when the server is out of reach, else the
  /// failure. True when selling can go on.
  bool _fallBack(SellFailureKind kind) {
    if (kind != SellFailureKind.serverUnreachable) {
      emit(state.copyWith(loading: false, loadFailure: kind));
      return false;
    }
    _status.reportUnreachable();
    return _loadCached(kind);
  }

  /// The copy from the last load; [failure] when there is none.
  bool _loadCached(SellFailureKind failure) {
    try {
      final types = _store.readCache(_typesKey) as List?;
      final settings = _store.readCache(_settingsKey) as Map<String, dynamic>?;
      final counterId = _counterId;
      final counter = counterId == null
          ? null
          : _store.readCache(_counterKey(counterId)) as Map<String, dynamic>?;
      if (types == null || settings == null) {
        emit(state.copyWith(loading: false, loadFailure: failure));
        return false;
      }
      emit(state.copyWith(
        loading: false,
        types: [for (final row in types.cast<Map<String, dynamic>>()) TicketType.fromRow(row)],
        settings: SellSettings.fromRow(settings),
        counter: counter == null ? null : CounterInfo.fromRow(counter),
      ));
      return true;
    } on Object {
      // A copy from an older app version that doesn't parse: as if none.
      emit(state.copyWith(loading: false, loadFailure: failure));
      return false;
    }
  }

  void _saveCopy(List<TicketType> types, SellSettings settings, CounterInfo? counter) {
    final now = _clock.now();
    _store.writeCache(_typesKey, [for (final type in types) type.toRow()], now: now);
    _store.writeCache(_settingsKey, settings.toRow(), now: now);
    if (counter != null) _store.writeCache(_counterKey(counter.id), counter.toRow(), now: now);
  }

  /// A safety net under the timer set for the next boundary: a PC clock
  /// moved by hand, or a timer that fired early, is caught within this.
  static const peakCheckEvery = Duration(seconds: 30);

  /// After a boundary, so the check lands on the new side of it.
  static const _boundaryMargin = Duration(milliseconds: 200);

  Timer? _peakTimer;

  /// Fires at the next moment peak may start or end ([PeakSchedule.nextChangeAfter]),
  /// so the screen switches at 16:00:00, not up to [peakCheckEvery] later.
  Timer? _boundaryTimer;
  StreamSubscription<void>? _answers;
  bool _readingSettings = false;

  /// When [_boundaryTimer] is due; for tests.
  @visibleForTesting
  DateTime? nextPeakCheckAt;

  void _scheduleBoundary() {
    _boundaryTimer?.cancel();
    final settings = state.settings;
    if (settings == null || isClosed) return;
    final now = _clock.now();
    final at = settings.peak.nextChangeAfter(now, day: settings.venueDay);
    nextPeakCheckAt = at;
    _boundaryTimer = _boundaryTimerFactory(at.difference(now) + _boundaryMargin, _checkPeak);
  }

  /// Re-reads the settings and applies a changed peak schedule or switch.
  /// Online only; a failure keeps what is on screen.
  @visibleForTesting
  Future<void> refreshPeakSettings() async {
    if (_useCopy || _readingSettings || state.settings == null) return;
    _readingSettings = true;
    try {
      final settings = await _repository.sellSettings();
      if (isClosed || settings == state.settings) return;
      _store.writeCache(_settingsKey, settings.toRow(), now: _clock.now());
      emit(state.copyWith(settings: settings));
      _checkPeak();
    } on SellFailure {
      return;
    } finally {
      _readingSettings = false;
    }
  }

  /// Peak now, by the schedule and this PC's clock; takes the types that
  /// aren't on sale any more out of the order, and says so ([notice]).
  void _checkPeak({bool notice = true}) {
    if (isClosed) return;
    _scheduleBoundary();
    final settings = state.settings;
    final peak =
        settings != null && settings.peak.isPeakAt(_clock.now(), day: settings.venueDay);
    final onSale = {
      for (final type in state.types)
        if (type.salePeriod.onSale(peak: peak)) type.id,
    };
    final quantities = {
      for (final MapEntry(:key, :value) in state.quantities.entries)
        if (onSale.contains(key)) key: value,
    };
    final dropped = quantities.length != state.quantities.length;
    if (peak == state.peak && !dropped) return;
    emit(state.copyWith(
      peak: peak,
      quantities: quantities,
      periodNotices: dropped && notice ? state.periodNotices + 1 : null,
    ));
  }

  /// [_checkPeak] now, as the timer does.
  @visibleForTesting
  void checkPeak() => _checkPeak();

  Timer? _printerTimer;
  StreamSubscription<PrintOutcome>? _outcomes;
  bool _rechecking = false;

  /// Keeps the badge current: a quiet re-check every [seconds], and every
  /// print's outcome as it happens (ADR-0022's one connection per job means
  /// a failed print is the printer not answering).
  void _watchPrinter(int seconds) {
    _printerTimer?.cancel();
    _printerTimer = Timer.periodic(Duration(seconds: seconds), (_) => _recheckPrinter());
    _outcomes ??= _printer.outcomes.listen((outcome) {
      if (isClosed || outcome.target != state.printerTarget) return;
      emit(state.copyWith(
        printer: outcome.printed ? PrinterStatus.reachable : PrinterStatus.unreachable,
      ));
    });
  }

  /// Like [checkPrinter] without "checking…", so the badge doesn't flicker.
  /// Skipped while a job is being sent: the printer is busy with it, and the
  /// job's outcome updates the badge anyway.
  Future<void> _recheckPrinter() async {
    final target = state.printerTarget;
    if (target == null || _rechecking || _printer.busy || state.printer == PrinterStatus.checking) {
      return;
    }
    _rechecking = true;
    try {
      final reachable = await _printer.isReachable(target);
      if (isClosed || _printer.busy || target != state.printerTarget) return;
      emit(state.copyWith(
        printer: reachable ? PrinterStatus.reachable : PrinterStatus.unreachable,
      ));
    } finally {
      _rechecking = false;
    }
  }

  @override
  Future<void> close() async {
    _printerTimer?.cancel();
    _peakTimer?.cancel();
    _boundaryTimer?.cancel();
    await _answers?.cancel();
    await _outcomes?.cancel();
    return super.close();
  }

  /// Reads the types and the settings again and keeps the order's quantities
  /// of the types still on sale: after `ticket_type_unavailable` (an admin
  /// switched one off) or `ticket_type_not_now`, and after each order, so a
  /// new price, order or peak switch shows (4.5). A failure keeps them as
  /// they are.
  Future<void> reloadTypes() async {
    if (_status.isOffline) return;
    try {
      final types = await _repository.ticketTypes();
      final settings = await _repository.sellSettings();
      if (isClosed) return;
      final now = _clock.now();
      _store.writeCache(_typesKey, [for (final type in types) type.toRow()], now: now);
      _store.writeCache(_settingsKey, settings.toRow(), now: now);
      final ids = {for (final type in types) type.id};
      emit(state.copyWith(
        types: types,
        settings: settings,
        quantities: {
          for (final MapEntry(:key, :value) in state.quantities.entries)
            if (ids.contains(key)) key: value,
        },
      ));
      _checkPeak();
    } on SellFailure {
      return;
    }
  }

  void increment(TicketType type) => _setQuantity(type, state.quantityOf(type) + 1);

  void decrement(TicketType type) => _setQuantity(type, state.quantityOf(type) - 1);

  /// At 0 or below, the type leaves the order: never a negative quantity.
  void _setQuantity(TicketType type, int quantity) {
    final quantities = {...state.quantities};
    if (quantity > 0) {
      quantities[type.id] = quantity;
    } else {
      quantities.remove(type.id);
    }
    emit(state.copyWith(quantities: quantities));
  }

  /// Empties the order; the payment method stays, as in the design.
  void clear() => emit(state.copyWith(quantities: const {}));

  void pickMethod(PaymentMethod method) => emit(state.copyWith(method: method));

  /// The server's counts plus the offline orders it doesn't have yet. While
  /// offline, the last counts read stand in for the server's.
  Future<void> refreshCounts() async {
    final shiftId = _shiftId;
    ShiftCounts? withQueue(ShiftCounts? counts) {
      if (counts == null || shiftId == null) return counts;
      final queue = _store.queueStatus(shiftId);
      return counts.plusUnsynced(queue.unsyncedOrders, queue.unsyncedTickets);
    }

    ShiftCounts? cached() {
      final json = shiftId == null ? null : _store.readCache(_countsKey(shiftId));
      return json is Map<String, dynamic> ? ShiftCounts.fromJson(json) : null;
    }

    if (_useCopy) return emit(state.copyWith(counts: withQueue(cached())));
    try {
      final counts = await _repository.myShiftCounts();
      if (isClosed) return;
      if (shiftId != null) _store.writeCache(_countsKey(shiftId), counts.toJson(), now: _clock.now());
      emit(state.copyWith(counts: withQueue(counts)));
    } on SellFailure catch (e) {
      if (isClosed) return;
      if (e.kind == SellFailureKind.noOpenShift) {
        // Closed meanwhile: reloading it lets the router leave selling.
        await _shift.load();
      } else if (e.kind == SellFailureKind.serverUnreachable) {
        _status.reportUnreachable();
        emit(state.copyWith(counts: withQueue(cached())));
      } else {
        emit(state.copyWith(counts: null));
      }
    }
  }

  Future<void> checkPrinter() async {
    final target = state.printerTarget;
    if (target == null) return emit(state.copyWith(printer: PrinterStatus.notSet));
    emit(state.copyWith(printer: PrinterStatus.checking));
    final reachable = await _printer.isReachable(target);
    if (isClosed) return;
    emit(state.copyWith(printer: reachable ? PrinterStatus.reachable : PrinterStatus.unreachable));
  }
}
