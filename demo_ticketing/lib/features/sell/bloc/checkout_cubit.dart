import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/clock.dart';
import '../../../core/printer/print_service.dart';
import '../../../core/printer/printed_ticket.dart';
import '../../../core/printer/printer_client.dart';
import '../../../core/printer/printer_target.dart';
import '../../../core/uuid.dart';
import '../../../core/venue_day.dart';
import '../../offline/data/offline_models.dart';
import '../../offline/data/offline_store.dart';
import '../../tickets/data/ticket_lookup.dart';
import '../data/sell_draft.dart';
import '../data/sell_repository.dart';
import '../data/sold_order.dart';
import '../data/ticket_type.dart';

/// Where the order is: being put together on the sell screen ([idle]),
/// being created ([selling]), printed and awaiting payment ([payment]), or
/// paid and shown for review ([confirmed]).
enum CheckoutStage { idle, selling, payment, confirmed }

/// One ticket's print job on the review: [refunded] was void-refunded from
/// the review instead (no print needed), [left] never printed and the
/// cashier left the order, logged (ADR-0024).
enum TicketPrintStatus { waiting, printing, printed, failed, refunded, left }

/// How the tip was chosen: a quick amount, typed, or "the customer left the
/// change", which follows the amount received.
enum TipKind { none, quick, typed, change }

/// What the sale needs from the sell screen and the signed-in cashier.
class CheckoutSetup extends Equatable {
  const CheckoutSetup({
    required this.venueName,
    required this.tipsEnabled,
    required this.counterName,
    required this.cashierName,
    required this.printer,
  });

  final String venueName;
  final bool tipsEnabled;
  final String counterName;
  final String cashierName;

  /// Null when the counter has no printer: every ticket fails to print.
  final PrinterTarget? printer;

  @override
  List<Object?> get props => [venueName, tipsEnabled, counterName, cashierName, printer];
}

/// What an offline sale needs (ADR-0015): the open shift and its counter,
/// whose pool the codes come from, and the settings the server would check.
class OfflineSaleSetup extends Equatable {
  const OfflineSaleSetup({
    required this.shiftId,
    required this.counterId,
    required this.venueDay,
    required this.poolSize,
  });

  final String shiftId;
  final String counterId;

  /// The venue day and its closing (ADR-0038): when same-day tickets end.
  final VenueDay venueDay;

  /// `offline_pool_size`; 0 turns offline selling off.
  final int poolSize;

  @override
  List<Object?> get props => [shiftId, counterId, venueDay, poolSize];
}

/// A paid order as the review screen shows it, kept for "Last order".
class ConfirmedOrder extends Equatable {
  const ConfirmedOrder({required this.order, required this.prints, required this.payment});

  final SoldOrder order;
  final List<TicketPrintStatus> prints;
  final PaymentResult payment;

  @override
  List<Object?> get props => [order, prints, payment];
}

class CheckoutState extends Equatable {
  const CheckoutState({
    this.stage = CheckoutStage.idle,
    this.tipsEnabled = false,
    this.order,
    this.prints = const [],
    this.method = PaymentMethod.cash,
    this.receivedPiastres,
    this.tipKind = TipKind.none,
    this.tipAmountPiastres = 0,
    this.payment,
    this.submitting = false,
    this.failure,
    this.cancelledNumber,
    this.last,
  });

  final CheckoutStage stage;
  final bool tipsEnabled;

  /// From [CheckoutStage.payment] on.
  final SoldOrder? order;

  /// One per ticket of [order], in its order.
  final List<TicketPrintStatus> prints;
  final PaymentMethod method;

  /// Cash only; null while nothing is typed.
  final int? receivedPiastres;
  final TipKind tipKind;

  /// The quick or typed tip.
  final int tipAmountPiastres;

  /// Set on [CheckoutStage.confirmed].
  final PaymentResult? payment;

  /// A `sell_tickets`, `confirm_payment` or `cancel_order` call is running.
  final bool submitting;

  /// The last call failed. On [CheckoutStage.idle], the sale or the cancel;
  /// on [CheckoutStage.confirmed], leaving with unprinted tickets.
  final SellFailureKind? failure;

  /// The order just cancelled, for the sell screen's notice.
  final int? cancelledNumber;

  /// The last paid order in this app session.
  final ConfirmedOrder? last;

  int get totalPiastres => order?.totalPiastres ?? 0;

  /// Tips go with cash only (ADR-0016).
  bool get tipAllowed => tipsEnabled && method == PaymentMethod.cash;

  int get tipPiastres => !tipAllowed
      ? 0
      : switch (tipKind) {
          TipKind.none => 0,
          TipKind.quick || TipKind.typed => tipAmountPiastres,
          TipKind.change => math.max(0, (receivedPiastres ?? 0) - totalPiastres),
        };

  /// `paid − total − tip`; negative while the cash is short, null while
  /// nothing is typed. Always 0 for card and wallet.
  int? get changePiastres {
    if (method != PaymentMethod.cash) return 0;
    final received = receivedPiastres;
    return received == null ? null : received - totalPiastres - tipPiastres;
  }

  bool get isShort => (changePiastres ?? -1) < 0;

  bool get canConfirm => stage == CheckoutStage.payment && !submitting && !isShort;

  int get printedCount => prints.where((print) => print == TicketPrintStatus.printed).length;

  int get failedCount => prints.where((print) => print == TicketPrintStatus.failed).length;

  /// Void-refunded from the review.
  int get refundedCount => prints.where((print) => print == TicketPrintStatus.refunded).length;

  /// Left unprinted, logged (ADR-0024).
  int get leftCount => prints.where((print) => print == TicketPrintStatus.left).length;

  /// A ticket is still waiting or printing.
  bool get printing => prints.any(
      (print) => print == TicketPrintStatus.waiting || print == TicketPrintStatus.printing);

  CheckoutState copyWith({
    CheckoutStage? stage,
    List<TicketPrintStatus>? prints,
    PaymentMethod? method,
    Object? receivedPiastres = _keep,
    TipKind? tipKind,
    int? tipAmountPiastres,
    PaymentResult? payment,
    bool? submitting,
    Object? failure = _keep,
  }) =>
      CheckoutState(
        stage: stage ?? this.stage,
        tipsEnabled: tipsEnabled,
        order: order,
        prints: prints ?? this.prints,
        method: method ?? this.method,
        receivedPiastres: receivedPiastres == _keep ? this.receivedPiastres : receivedPiastres as int?,
        tipKind: tipKind ?? this.tipKind,
        tipAmountPiastres: tipAmountPiastres ?? this.tipAmountPiastres,
        payment: payment ?? this.payment,
        submitting: submitting ?? this.submitting,
        failure: failure == _keep ? this.failure : failure as SellFailureKind?,
        cancelledNumber: cancelledNumber,
        last: last,
      );

  /// Marks a nullable field [copyWith] leaves as it is.
  static const _keep = Object();

  @override
  List<Object?> get props => [
        stage,
        tipsEnabled,
        order,
        prints,
        method,
        receivedPiastres,
        tipKind,
        tipAmountPiastres,
        payment,
        submitting,
        failure,
        cancelledNumber,
        last,
      ];
}

/// One order from "Print tickets and charge" to the review, print first
/// (ADR-0007): `sell_tickets` creates it awaiting payment, its pending tickets
/// print while the cashier collects, then `confirm_payment` activates them,
/// or `cancel_order` voids them.
///
/// Every money rule is the server's; the figures here only drive the screen.
///
/// While the server is out of reach the order is charged first instead
/// (ADR-0015, [startOffline]): nothing is stored or printed until the
/// cashier confirms the payment; then the order is stored paid, with codes
/// from the counter's pool, and its tickets print, active.
class CheckoutCubit extends Cubit<CheckoutState> {
  CheckoutCubit({
    required this._repository,
    required this._printer,
    required this._store,
    this._clock = const Clock(),
  }) : super(const CheckoutState());

  final SellRepository _repository;
  final PrintService _printer;
  final OfflineStore _store;
  final Clock _clock;
  CheckoutSetup? _setup;

  /// Set by [startOffline] until the order is confirmed or dropped.
  SellDraft? _offlineDraft;
  OfflineSaleSetup? _offline;

  /// Starts an offline sale of [draft]: the payment screen, with nothing
  /// stored or printed yet. Refused, as the server would refuse the upload,
  /// when offline selling is off, the pool is short, or a same-day ticket
  /// is past closing.
  void startOffline(SellDraft draft, CheckoutSetup setup, OfflineSaleSetup offline) {
    if (state.stage != CheckoutStage.idle) return;
    final now = _clock.now();
    final count = draft.lines.fold(0, (sum, line) => sum + line.quantity);
    final failure = _offlineRefusal(draft, offline, now, count);
    if (failure != null) return emit(CheckoutState(failure: failure, last: state.last));
    _setup = setup;
    _offlineDraft = draft;
    _offline = offline;
    final clientId = uuidV4();
    emit(CheckoutState(
      stage: CheckoutStage.payment,
      tipsEnabled: setup.tipsEnabled,
      order: SoldOrder(
        id: clientId,
        number: _store.nextLocalNumber(offline.shiftId),
        totalPiastres: draft.lines.fold(0, (sum, line) => sum + line.subtotalPiastres),
        createdAt: now,
        // Codes come from the pool on confirm; until then only the lines show.
        tickets: [
          for (final spec in _specs(draft, offline, now))
            SoldTicket(
              id: '',
              gateCode: '',
              ticketTypeId: spec.ticketTypeId,
              nameAr: spec.nameAr,
              nameEn: spec.nameEn,
              pricePiastres: spec.pricePiastres,
              entriesLeft: spec.entriesLeft,
              validFrom: now,
              validUntil: spec.validUntil,
              homeGateName: '',
            ),
        ],
        offline: true,
      ),
      method: draft.method,
      last: state.last,
    ));
  }

  /// Why [draft] can't be sold offline at [at], or null.
  SellFailureKind? _offlineRefusal(SellDraft draft, OfflineSaleSetup offline, DateTime at, int count) {
    if (offline.poolSize <= 0) return SellFailureKind.offlineDisabled;
    final sameDay = draft.lines.any((line) => line.type.validity == TicketValidity.sameDay);
    // As the upload would refuse it; and at closing the day's codes expire too.
    // Closing of the venue day [at] is on: 02:00 is the night after.
    if (sameDay && !at.isBefore(offline.venueDay.closingFor(at))) {
      return SellFailureKind.afterClosingTime;
    }
    final expiry = _store.nextExpiry(offline.counterId, at);
    if (expiry == null || _store.freeCodes(offline.counterId, at) < count) {
      return SellFailureKind.offlinePoolEmpty;
    }
    // A pool code expires at closing: another time means the PC's time zone
    // isn't the venue's, so "today's closing" can't be trusted.
    if (sameDay && !offline.venueDay.closing.matches(expiry)) {
      return SellFailureKind.offlineZoneMismatch;
    }
    return null;
  }

  /// One spec per ticket, valid as `sync_offline_orders` will make it: until
  /// the closing of the sale's venue day, or for the type's hours.
  static List<OfflineTicketSpec> _specs(SellDraft draft, OfflineSaleSetup offline, DateTime soldAt) => [
        for (final line in draft.lines)
          for (var i = 0; i < line.quantity; i++)
            OfflineTicketSpec(
              ticketTypeId: line.type.id,
              nameAr: line.type.nameAr,
              nameEn: line.type.nameEn,
              pricePiastres: line.type.pricePiastres,
              entriesLeft: line.type.entriesAllowed,
              validUntil: switch (line.type.validity) {
                TicketValidity.sameDay => offline.venueDay.closingFor(soldAt),
                TicketValidity.hoursFromSale =>
                  soldAt.add(Duration(hours: line.type.validityHours ?? 0)),
              },
            ),
      ];

  /// Confirm on an offline order: stored paid with its codes, then printed.
  Future<void> _confirmOffline(SoldOrder draftOrder) async {
    final draft = _offlineDraft;
    final offline = _offline;
    if (draft == null || offline == null) return;
    final soldAt = _clock.now();
    final count = draftOrder.tickets.length;
    final refusal = _offlineRefusal(draft, offline, soldAt, count);
    if (refusal != null) return emit(state.copyWith(failure: refusal));
    final cash = state.method == PaymentMethod.cash;
    final SoldOrder order;
    try {
      order = _store.recordSale(
        clientId: draftOrder.id,
        shiftId: offline.shiftId,
        counterId: offline.counterId,
        soldAt: soldAt,
        paymentMethod: state.method.name,
        amountReceivedPiastres: cash ? state.receivedPiastres : null,
        tipPiastres: state.tipPiastres,
        tickets: _specs(draft, offline, soldAt),
      );
    } on OfflineSaleException {
      return emit(state.copyWith(failure: SellFailureKind.offlinePoolEmpty));
    }
    _offlineDraft = null;
    _offline = null;
    final payment = PaymentResult(
      method: state.method,
      totalPiastres: order.totalPiastres,
      tipPiastres: state.tipPiastres,
      amountReceivedPiastres: cash ? state.receivedPiastres! : order.totalPiastres,
      changePiastres: state.changePiastres!,
    );
    emit(CheckoutState(
      stage: CheckoutStage.confirmed,
      tipsEnabled: state.tipsEnabled,
      order: order,
      prints: List.filled(order.tickets.length, TicketPrintStatus.waiting),
      method: state.method,
      receivedPiastres: state.receivedPiastres,
      tipKind: state.tipKind,
      tipAmountPiastres: state.tipAmountPiastres,
      payment: payment,
      last: state.last,
    ));
    await _print([for (var i = 0; i < order.tickets.length; i++) i]);
  }

  /// Sells [draft]. The payment screen shows as soon as the order exists,
  /// and the tickets print one by one behind it.
  Future<void> start(SellDraft draft, CheckoutSetup setup) async {
    if (state.stage != CheckoutStage.idle) return;
    _setup = setup;
    emit(CheckoutState(
      stage: CheckoutStage.selling,
      tipsEnabled: setup.tipsEnabled,
      method: draft.method,
      submitting: true,
      last: state.last,
    ));
    final SoldOrder order;
    try {
      order = await _repository.sellTickets(draft);
    } on SellFailure catch (e) {
      if (!isClosed) emit(CheckoutState(failure: e.kind, last: state.last));
      return;
    }
    if (isClosed) return;
    emit(CheckoutState(
      stage: CheckoutStage.payment,
      tipsEnabled: setup.tipsEnabled,
      order: order,
      prints: List.filled(order.tickets.length, TicketPrintStatus.waiting),
      method: draft.method,
      last: state.last,
    ));
    await _print([for (var i = 0; i < order.tickets.length; i++) i]);
  }

  /// Prints ticket [index] again after it failed. The copy was never on
  /// paper and `print_count` is already 1 from the sale, so this is not a
  /// reprint: nothing is called or logged (agreed in 2.5).
  Future<void> retry(int index) async {
    if (state.printing || state.prints.elementAtOrNull(index) != TicketPrintStatus.failed) return;
    await _print([index]);
  }

  Future<void> retryFailed() async {
    if (state.printing) return;
    await _print([
      for (final (index, print) in state.prints.indexed)
        if (print == TicketPrintStatus.failed) index,
    ]);
  }

  /// Stops when the order leaves the screen (cancelled): its tickets are
  /// voided, so the rest aren't worth the paper.
  Future<void> _print(List<int> indexes) async {
    final order = state.order;
    final setup = _setup;
    if (order == null || setup == null) return;
    bool current() => !isClosed && identical(state.order, order);
    for (final index in indexes) {
      if (!current()) return;
      _setPrint(index, TicketPrintStatus.printing);
      var printed = false;
      final target = setup.printer;
      if (target != null) {
        try {
          await _printer.printTicket(target, _ticket(order, index, setup));
          printed = true;
        } on PrinterException {
          printed = false;
        }
      }
      if (!current()) return;
      _setPrint(index, printed ? TicketPrintStatus.printed : TicketPrintStatus.failed);
    }
  }

  void _setPrint(int index, TicketPrintStatus status) {
    final prints = [...state.prints];
    prints[index] = status;
    emit(state.copyWith(prints: prints));
  }

  static PrintedTicket _ticket(SoldOrder order, int index, CheckoutSetup setup) {
    final ticket = order.tickets[index];
    return PrintedTicket(
      venueName: setup.venueName,
      typeName: ticket.name(PrintService.ticketLocale.languageCode),
      pricePiastres: ticket.pricePiastres,
      gateCode: ticket.gateCode,
      validFrom: ticket.validFrom,
      validUntil: ticket.validUntil,
      entriesLeft: ticket.entriesLeft,
      orderNumber: order.number,
      offline: order.offline,
      index: index + 1,
      count: order.tickets.length,
      counterName: setup.counterName,
      cashierName: setup.cashierName,
      soldAt: order.createdAt,
      homeGateName: ticket.homeGateName,
    );
  }

  /// The customer may change their mind after the tickets printed. A tip
  /// goes with cash only, so a new method starts without one.
  void pickMethod(PaymentMethod method) {
    if (state.stage != CheckoutStage.payment || method == state.method) return;
    emit(state.copyWith(method: method, tipKind: TipKind.none, tipAmountPiastres: 0));
  }

  /// [piastres] null: nothing typed.
  void setReceived(int? piastres) {
    if (state.stage != CheckoutStage.payment) return;
    emit(state.copyWith(receivedPiastres: piastres));
  }

  /// A quick tip; 0 is "none".
  void pickTip(int piastres) {
    if (!state.tipAllowed) return;
    emit(state.copyWith(
      tipKind: piastres > 0 ? TipKind.quick : TipKind.none,
      tipAmountPiastres: piastres,
    ));
  }

  /// A typed tip; null or 0 is "none".
  void typeTip(int? piastres) {
    if (!state.tipAllowed) return;
    final amount = piastres ?? 0;
    emit(state.copyWith(
      tipKind: amount > 0 ? TipKind.typed : TipKind.none,
      tipAmountPiastres: amount,
    ));
  }

  /// "The customer left the change": everything above the total.
  void tipTheChange() {
    if (!state.tipAllowed) return;
    emit(state.copyWith(tipKind: TipKind.change, tipAmountPiastres: 0));
  }

  Future<void> confirm() async {
    final order = state.order;
    if (!state.canConfirm || order == null) return;
    if (order.offline) return _confirmOffline(order);
    final cash = state.method == PaymentMethod.cash;
    // What the server will answer, for when its answer was lost (below).
    final expected = PaymentResult(
      method: state.method,
      totalPiastres: state.totalPiastres,
      tipPiastres: state.tipPiastres,
      amountReceivedPiastres: cash ? state.receivedPiastres! : state.totalPiastres,
      changePiastres: state.changePiastres!,
    );
    emit(state.copyWith(submitting: true, failure: null));
    PaymentResult payment;
    try {
      payment = await _repository.confirmPayment(
        order.id,
        state.method,
        amountReceivedPiastres: cash ? state.receivedPiastres : null,
        tipPiastres: state.tipPiastres,
      );
    } on SellFailure catch (e) {
      if (isClosed) return;
      // A confirm whose answer never arrived, tried again: it went through.
      if (e.kind != SellFailureKind.orderAlreadyPaid) {
        return emit(state.copyWith(submitting: false, failure: e.kind));
      }
      payment = expected;
    }
    if (isClosed) return;
    emit(state.copyWith(stage: CheckoutStage.confirmed, payment: payment, submitting: false));
  }

  /// The customer didn't pay: the order is cancelled and its printed
  /// tickets voided. The sell screen then starts the next order from 0, with
  /// a notice to take the tickets back.
  Future<void> cancel(CancelReason reason, {String? reasonText}) async {
    final order = state.order;
    if (state.stage != CheckoutStage.payment || state.submitting || order == null) return;
    // Offline nothing is stored before the confirm: there is nothing to
    // cancel (the payment screen offers Back instead).
    if (order.offline) return abandon();
    emit(state.copyWith(submitting: true, failure: null));
    try {
      await _repository.cancelOrder(order.id, reason, reasonText: reasonText);
    } on SellFailure catch (e) {
      if (isClosed) return;
      // The unpaid-order job got there first: the same outcome.
      if (e.kind != SellFailureKind.orderCancelled) {
        return emit(state.copyWith(submitting: false, failure: e.kind));
      }
    }
    if (isClosed) return;
    emit(CheckoutState(cancelledNumber: order.number, last: state.last));
  }

  /// Back to selling after the order was cancelled or lost on the server
  /// (`order_cancelled`, `order_not_found`), or left unconfirmed while the
  /// server is out of reach (ADR-0039: the unpaid-order job cancels it). The
  /// sell screen starts those from 0; only an offline order keeps its draft.
  void abandon() {
    if (state.stage != CheckoutStage.payment) return;
    _offlineDraft = null;
    _offline = null;
    emit(CheckoutState(last: state.last));
  }

  /// A ticket of the review was void-refunded (the action dialog): it needs
  /// no print any more.
  void markRefunded(int index) {
    if (state.stage != CheckoutStage.confirmed) return;
    if (state.prints.elementAtOrNull(index) == null) return;
    _setPrint(index, TicketPrintStatus.refunded);
  }

  /// A reprint logged in the offline queue (ADR-0026): the server can't be
  /// asked, or doesn't have this order yet. What the copy prints comes from the
  /// order on screen, and its number from the first print plus the reprints
  /// logged here. Uploaded later, always flagged for a supervisor.
  ReprintedTicket queueReprint(
    int index,
    ActionReason reason, {
    String? reasonText,
    required String shiftId,
  }) {
    final order = state.order!;
    final ticket = order.tickets[index];
    final code = int.parse(ticket.gateCode);
    _store.recordActions([
      QueuedAction(
        clientId: uuidV4(),
        shiftId: shiftId,
        kind: QueuedActionKind.reprint,
        orderId: order.id,
        gateCode: code,
        at: _clock.now(),
        reason: reason.key,
        reasonText: reasonText,
      ),
    ]);
    return ReprintedTicket(
      gateCode: ticket.gateCode,
      nameAr: ticket.nameAr,
      nameEn: ticket.nameEn,
      pricePiastres: ticket.pricePiastres,
      entriesLeft: ticket.entriesLeft,
      validFrom: ticket.validFrom,
      validUntil: ticket.validUntil,
      printCount: 1 + _store.queuedReprints(order.id, code),
      orderNumber: order.number,
      homeGateName: ticket.homeGateName,
      soldAt: order.createdAt,
      counterName: _setup?.counterName ?? '',
      soldByName: _setup?.cashierName ?? '',
      index: index + 1,
      count: order.tickets.length,
      offline: order.offline,
    );
  }

  /// "Leave anyway" on the review: the failed tickets are logged as left
  /// unprinted (ADR-0024), then the order is done. Their code is on no paper
  /// and the cashier can't read orders, so nothing could print them later.
  ///
  /// With [queueInShift] they are logged in the offline queue rather than on
  /// the server (ADR-0026): while offline, or for an offline order.
  Future<void> leaveUnprinted(
    LeaveReason reason, {
    String? reasonText,
    String? queueInShift,
  }) async {
    final order = state.order;
    if (state.stage != CheckoutStage.confirmed || state.printing || state.submitting) return;
    if (order == null || state.failedCount == 0) return;
    final failed = [
      for (final (index, print) in state.prints.indexed)
        if (print == TicketPrintStatus.failed) index,
    ];
    if (queueInShift != null) {
      final now = _clock.now();
      _store.recordActions([
        for (final index in failed)
          QueuedAction(
            clientId: uuidV4(),
            shiftId: queueInShift,
            kind: QueuedActionKind.leftUnprinted,
            orderId: order.id,
            gateCode: int.parse(order.tickets[index].gateCode),
            at: now,
            reason: reason.key,
            reasonText: reasonText,
          ),
      ]);
      return _leftUnprinted(failed);
    }
    emit(state.copyWith(submitting: true, failure: null));
    try {
      await _repository.leaveUnprinted(
        order.id,
        [for (final index in failed) order.tickets[index].id],
        reason,
        reasonText: reasonText,
      );
    } on SellFailure catch (e) {
      if (!isClosed) emit(state.copyWith(submitting: false, failure: e.kind));
      return;
    }
    if (isClosed) return;
    _leftUnprinted(failed);
  }

  void _leftUnprinted(List<int> indexes) {
    final prints = [...state.prints];
    for (final index in indexes) {
      prints[index] = TicketPrintStatus.left;
    }
    emit(state.copyWith(prints: prints, submitting: false));
    finish();
  }

  /// "New order" on the review: once every ticket has had its print, and
  /// none is left failed (the review asks first: retry, or [leaveUnprinted]).
  void finish() {
    final order = state.order;
    final payment = state.payment;
    if (state.stage != CheckoutStage.confirmed || state.printing || state.submitting) return;
    if (state.failedCount > 0 || order == null || payment == null) return;
    emit(CheckoutState(
      last: ConfirmedOrder(order: order, prints: state.prints, payment: payment),
    ));
  }

  /// "Last order" on the sell screen: the review of the last paid order.
  void showLast() {
    final last = state.last;
    if (state.stage != CheckoutStage.idle || last == null) return;
    emit(CheckoutState(
      stage: CheckoutStage.confirmed,
      order: last.order,
      prints: last.prints,
      method: last.payment.method,
      payment: last.payment,
      last: last,
    ));
  }

  /// Clears the sell screen's notice (a failed sale, a cancelled order).
  void dismiss() {
    if (state.stage != CheckoutStage.idle) return;
    emit(CheckoutState(last: state.last));
  }
}
