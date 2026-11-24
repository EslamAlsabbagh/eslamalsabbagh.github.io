import 'package:equatable/equatable.dart';

import '../../../core/printer/printed_ticket.dart';
import '../../sell/data/sell_draft.dart';
import '../../sell/data/sold_order.dart';
import 'ticket_failure.dart';

/// A ticket's status as `lookup_ticket` reports it. An active ticket past its
/// window is already `expired` there, before the job marks it (1.13).
enum TicketStatus { pending, active, used, voided, expired }

/// The three cashier actions on a ticket, without approval (ADR-0009).
enum TicketAction {
  reprint('reprint'),
  reactivate('reactivate'),
  voidRefund('void_refund');

  const TicketAction(this.key);

  /// The database value (`ticket_action_type`).
  final String key;
}

/// The reasons each action takes (`check_action_reason`); `other` needs text.
enum ActionReason {
  scannedNotPassed('scanned_not_passed', TicketAction.reactivate),
  gateDidNotOpen('gate_did_not_open', TicketAction.reactivate),
  printFailed('print_failed', TicketAction.reprint),
  ticketLost('ticket_lost', TicketAction.reprint),
  customerChangedMind('customer_changed_mind', TicketAction.voidRefund),
  wrongTicketType('wrong_ticket_type', TicketAction.voidRefund),
  other('other', null);

  const ActionReason(this.key, this.action);

  /// The database value (`action_reason`).
  final String key;

  /// Null: any action.
  final TicketAction? action;

  /// In the design's order: the action's own two, then "other".
  static List<ActionReason> forAction(TicketAction action) =>
      [for (final reason in values) if (reason.action == action) reason, other];

  static ActionReason? fromKey(String? key) {
    for (final reason in values) {
      if (reason.key == key) return reason;
    }
    return null;
  }
}

/// Whether the caller can still do an action, as `ticket_action_block` says.
class ActionAllowance extends Equatable {
  const ActionAllowance({required this.allowed, this.blockedBy, this.until});

  final bool allowed;

  /// Why not, when not allowed.
  final TicketFailureKind? blockedBy;

  /// Reactivate only: when the window closes.
  final DateTime? until;

  factory ActionAllowance.fromJson(Map<String, dynamic> json) => ActionAllowance(
        allowed: json['allowed'] as bool,
        blockedBy: switch (json['blocked_by']) {
          final String key => TicketFailureKind.fromKey(key),
          _ => null,
        },
        until: switch (json['until']) {
          final String until => DateTime.parse(until).toLocal(),
          _ => null,
        },
      );

  @override
  List<Object?> get props => [allowed, blockedBy, until];
}

/// One scan of the ticket at a gate.
class TicketScan extends Equatable {
  const TicketScan({
    required this.gateName,
    required this.accepted,
    required this.reason,
    required this.scannedAt,
  });

  final String gateName;
  final bool accepted;

  /// `scan_reject_reason` of a rejected scan.
  final String? reason;
  final DateTime scannedAt;

  factory TicketScan.fromJson(Map<String, dynamic> json) => TicketScan(
        gateName: json['gate_name'] as String,
        accepted: json['result'] == 'accepted',
        reason: json['reason'] as String?,
        scannedAt: DateTime.parse(json['scanned_at'] as String).toLocal(),
      );

  @override
  List<Object?> get props => [gateName, accepted, reason, scannedAt];
}

/// One logged action on the ticket (or its order's cancel). No flags, review
/// fields or amounts: the lookup leaves them out.
class TicketActionEntry extends Equatable {
  const TicketActionEntry({
    required this.action,
    required this.actorName,
    required this.counterName,
    required this.reasonCode,
    required this.reasonText,
    required this.createdAt,
  });

  /// `ticket_action_type`, e.g. `void_refund`, `cancel_order`, `left_unprinted`.
  final String action;
  final String? actorName;
  final String? counterName;
  final String? reasonCode;
  final String? reasonText;
  final DateTime createdAt;

  factory TicketActionEntry.fromJson(Map<String, dynamic> json) => TicketActionEntry(
        action: json['action'] as String,
        actorName: json['actor_name'] as String?,
        counterName: json['counter_name'] as String?,
        reasonCode: json['reason_code'] as String?,
        reasonText: json['reason_text'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );

  @override
  List<Object?> get props => [action, actorName, counterName, reasonCode, reasonText, createdAt];
}

/// What `lookup_ticket` returns: the ticket, its sale, its scans and actions,
/// and which actions the caller can still do. The ticket's own price and its
/// order's method, never an order total (ADR-0008, ADR-0014).
class TicketLookup extends Equatable {
  const TicketLookup({
    required this.ticketId,
    required this.gateCode,
    required this.status,
    required this.nameAr,
    required this.nameEn,
    required this.pricePiastres,
    required this.entriesAllowed,
    required this.entriesLeft,
    required this.validFrom,
    required this.validUntil,
    required this.printCount,
    required this.reactivationCount,
    required this.soldAt,
    required this.homeGateName,
    required this.orderNumber,
    required this.paymentMethod,
    required this.soldByName,
    required this.counterName,
    this.scans = const [],
    this.actions = const [],
    required this.allowed,
  });

  final String ticketId;
  final String gateCode;
  final TicketStatus status;
  final String nameAr;
  final String nameEn;
  final int pricePiastres;
  final int entriesAllowed;
  final int entriesLeft;
  final DateTime validFrom;
  final DateTime validUntil;
  final int printCount;
  final int reactivationCount;
  final DateTime soldAt;

  /// Null for tickets sold before 1.10a.
  final String? homeGateName;
  final int orderNumber;

  /// Null while the order awaits payment, or after it was cancelled unpaid.
  final PaymentMethod? paymentMethod;
  final String soldByName;
  final String counterName;

  /// Oldest first.
  final List<TicketScan> scans;

  /// Oldest first.
  final List<TicketActionEntry> actions;
  final Map<TicketAction, ActionAllowance> allowed;

  String name(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  ActionAllowance allowance(TicketAction action) =>
      allowed[action] ?? const ActionAllowance(allowed: false);

  bool can(TicketAction action) => allowance(action).allowed;

  /// A ticket of an order on this counter's screen, for the action dialog when
  /// the server can't be asked (ADR-0026): only a reprint can go in the queue.
  factory TicketLookup.queued({
    required SoldOrder order,
    required SoldTicket ticket,
    required PaymentMethod? paymentMethod,
    required String soldByName,
    required String counterName,
    required int printCount,
  }) =>
      TicketLookup(
        ticketId: ticket.id,
        gateCode: ticket.gateCode,
        status: TicketStatus.active,
        nameAr: ticket.nameAr,
        nameEn: ticket.nameEn,
        pricePiastres: ticket.pricePiastres,
        entriesAllowed: ticket.entriesLeft,
        entriesLeft: ticket.entriesLeft,
        validFrom: ticket.validFrom,
        validUntil: ticket.validUntil,
        printCount: printCount,
        reactivationCount: 0,
        soldAt: order.createdAt,
        homeGateName: ticket.homeGateName,
        orderNumber: order.number,
        paymentMethod: paymentMethod,
        soldByName: soldByName,
        counterName: counterName,
        allowed: const {
          TicketAction.reprint: ActionAllowance(allowed: true),
          TicketAction.reactivate:
              ActionAllowance(allowed: false, blockedBy: TicketFailureKind.needsServer),
          TicketAction.voidRefund:
              ActionAllowance(allowed: false, blockedBy: TicketFailureKind.needsServer),
        },
      );

  /// The void that made it voided: a refund, or its order's cancel.
  TicketActionEntry? get voidAction {
    for (final entry in actions.reversed) {
      if (entry.action == 'void_refund' || entry.action == 'cancel_order') return entry;
    }
    return null;
  }

  factory TicketLookup.fromJson(Map<String, dynamic> json) {
    final allowed = json['actions_allowed'] as Map<String, dynamic>;
    return TicketLookup(
      ticketId: json['ticket_id'] as String,
      gateCode: '${json['gate_code']}',
      status: TicketStatus.values.byName(json['status'] as String),
      nameAr: json['name_ar'] as String,
      nameEn: json['name_en'] as String,
      pricePiastres: json['price_piastres'] as int,
      entriesAllowed: json['entries_allowed'] as int,
      entriesLeft: json['entries_left'] as int,
      validFrom: DateTime.parse(json['valid_from'] as String).toLocal(),
      validUntil: DateTime.parse(json['valid_until'] as String).toLocal(),
      printCount: json['print_count'] as int,
      reactivationCount: json['reactivation_count'] as int,
      soldAt: DateTime.parse(json['created_at'] as String).toLocal(),
      homeGateName: json['home_gate_name'] as String?,
      orderNumber: json['order_number'] as int,
      paymentMethod: switch (json['payment_method']) {
        final String method => PaymentMethod.values.byName(method),
        _ => null,
      },
      soldByName: json['sold_by_name'] as String,
      counterName: json['counter_name'] as String,
      scans: [
        for (final scan in json['scans'] as List) TicketScan.fromJson(scan as Map<String, dynamic>),
      ],
      actions: [
        for (final action in json['actions'] as List)
          TicketActionEntry.fromJson(action as Map<String, dynamic>),
      ],
      allowed: {
        for (final action in TicketAction.values)
          if (allowed[action.key] case final Map<String, dynamic> entry)
            action: ActionAllowance.fromJson(entry),
      },
    );
  }

  @override
  List<Object?> get props => [
        ticketId,
        gateCode,
        status,
        nameAr,
        nameEn,
        pricePiastres,
        entriesAllowed,
        entriesLeft,
        validFrom,
        validUntil,
        printCount,
        reactivationCount,
        soldAt,
        homeGateName,
        orderNumber,
        paymentMethod,
        soldByName,
        counterName,
        scans,
        actions,
        allowed,
      ];
}

/// What `reprint_ticket` returns: everything the copy prints, including the
/// sale's counter, cashier, time and the ticket's place in its order.
class ReprintedTicket extends Equatable {
  const ReprintedTicket({
    required this.gateCode,
    required this.nameAr,
    required this.nameEn,
    required this.pricePiastres,
    required this.entriesLeft,
    required this.validFrom,
    required this.validUntil,
    required this.printCount,
    required this.orderNumber,
    required this.homeGateName,
    required this.soldAt,
    required this.counterName,
    required this.soldByName,
    required this.index,
    required this.count,
    this.offline = false,
  });

  final String gateCode;
  final String nameAr;
  final String nameEn;
  final int pricePiastres;
  final int entriesLeft;
  final DateTime validFrom;
  final DateTime validUntil;
  final int printCount;
  final int orderNumber;
  final String homeGateName;
  final DateTime soldAt;
  final String counterName;
  final String soldByName;
  final int index;
  final int count;

  /// A copy of an offline order, logged in the queue: its number is the local
  /// one (ADR-0015).
  final bool offline;

  factory ReprintedTicket.fromJson(Map<String, dynamic> json) => ReprintedTicket(
        gateCode: '${json['gate_code']}',
        nameAr: json['name_ar'] as String,
        nameEn: json['name_en'] as String,
        pricePiastres: json['price_piastres'] as int,
        entriesLeft: json['entries_left'] as int,
        validFrom: DateTime.parse(json['valid_from'] as String).toLocal(),
        validUntil: DateTime.parse(json['valid_until'] as String).toLocal(),
        printCount: json['print_count'] as int,
        orderNumber: json['order_number'] as int,
        // Tickets sold before 1.10a have none.
        homeGateName: json['home_gate_name'] as String? ?? '',
        soldAt: DateTime.parse(json['sold_at'] as String).toLocal(),
        counterName: json['counter_name'] as String,
        soldByName: json['sold_by_name'] as String,
        index: json['ticket_index'] as int,
        count: json['ticket_count'] as int,
      );

  /// The copy, as the first print plus its print number.
  PrintedTicket printed({required String venueName, required String languageCode}) => PrintedTicket(
        venueName: venueName,
        typeName: languageCode == 'ar' ? nameAr : nameEn,
        pricePiastres: pricePiastres,
        gateCode: gateCode,
        validFrom: validFrom,
        validUntil: validUntil,
        entriesLeft: entriesLeft,
        orderNumber: orderNumber,
        offline: offline,
        index: index,
        count: count,
        counterName: counterName,
        cashierName: soldByName,
        soldAt: soldAt,
        homeGateName: homeGateName,
        printCount: printCount,
      );

  @override
  List<Object?> get props => [
        gateCode,
        nameAr,
        nameEn,
        pricePiastres,
        entriesLeft,
        validFrom,
        validUntil,
        printCount,
        orderNumber,
        homeGateName,
        soldAt,
        counterName,
        soldByName,
        index,
        count,
        offline,
      ];
}

/// What `void_refund_ticket` returns: the amount to hand back, and how.
class RefundResult extends Equatable {
  const RefundResult({required this.amountPiastres, required this.method});

  final int amountPiastres;
  final PaymentMethod? method;

  factory RefundResult.fromJson(Map<String, dynamic> json) => RefundResult(
        amountPiastres: json['amount_piastres'] as int,
        method: switch (json['payment_method']) {
          final String method => PaymentMethod.values.byName(method),
          _ => null,
        },
      );

  @override
  List<Object?> get props => [amountPiastres, method];
}

/// The settings the action dialog's limit texts show.
class TicketActionSettings extends Equatable {
  const TicketActionSettings({
    required this.reactivationWindowMin,
    required this.reactivationMax,
    required this.refundBeforeScanOnly,
    required this.refundSameShiftOnly,
  });

  /// For a dialog that can only reprint: no limit text uses these.
  static const reprintOnly = TicketActionSettings(
    reactivationWindowMin: 0,
    reactivationMax: 0,
    refundBeforeScanOnly: false,
    refundSameShiftOnly: false,
  );

  final int reactivationWindowMin;
  final int reactivationMax;
  final bool refundBeforeScanOnly;
  final bool refundSameShiftOnly;

  factory TicketActionSettings.fromRow(Map<String, dynamic> row) => TicketActionSettings(
        reactivationWindowMin: row['reactivation_window_min'] as int,
        reactivationMax: row['reactivation_max'] as int,
        refundBeforeScanOnly: row['refund_before_scan_only'] as bool,
        refundSameShiftOnly: row['refund_same_shift_only'] as bool,
      );

  @override
  List<Object?> get props =>
      [reactivationWindowMin, reactivationMax, refundBeforeScanOnly, refundSameShiftOnly];
}
