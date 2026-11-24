import 'package:equatable/equatable.dart';

import '../../../core/venue_day.dart';
import 'peak_schedule.dart';
import 'sell_draft.dart';

/// One ticket of a [SoldOrder], as `sell_tickets` returns it: everything the
/// printer needs, since the cashier can't read the tickets table (ADR-0014).
class SoldTicket extends Equatable {
  const SoldTicket({
    required this.id,
    required this.gateCode,
    required this.ticketTypeId,
    required this.nameAr,
    required this.nameEn,
    required this.pricePiastres,
    required this.entriesLeft,
    required this.validFrom,
    required this.validUntil,
    required this.homeGateName,
  });

  final String id;
  final String gateCode;
  final String ticketTypeId;
  final String nameAr;
  final String nameEn;
  final int pricePiastres;
  final int entriesLeft;
  final DateTime validFrom;
  final DateTime validUntil;
  final String homeGateName;

  String name(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  factory SoldTicket.fromJson(Map<String, dynamic> json) => SoldTicket(
        id: json['id'] as String,
        // A bigint, which PostgREST sends as a number.
        gateCode: '${json['gate_code']}',
        ticketTypeId: json['ticket_type_id'] as String,
        nameAr: json['name_ar'] as String,
        nameEn: json['name_en'] as String,
        pricePiastres: json['price_piastres'] as int,
        entriesLeft: json['entries_left'] as int,
        validFrom: DateTime.parse(json['valid_from'] as String).toLocal(),
        validUntil: DateTime.parse(json['valid_until'] as String).toLocal(),
        homeGateName: json['home_gate_name'] as String,
      );

  @override
  List<Object?> get props => [
        id,
        gateCode,
        ticketTypeId,
        nameAr,
        nameEn,
        pricePiastres,
        entriesLeft,
        validFrom,
        validUntil,
        homeGateName,
      ];
}

/// An order `sell_tickets` created: awaiting payment, its tickets pending
/// until `confirm_payment` (ADR-0007).
///
/// Or, [offline], one sold from the counter's local store while the server
/// was out of reach (ADR-0015): paid at once, [id] is its `client_id` and
/// [number] the shift's local sequence, until the upload gives it a server
/// number.
class SoldOrder extends Equatable {
  const SoldOrder({
    required this.id,
    required this.number,
    required this.totalPiastres,
    required this.createdAt,
    required this.tickets,
    this.offline = false,
  });

  final String id;
  final int number;

  /// The server's total, at the server's prices; offline, at the prices the
  /// counter last read.
  final int totalPiastres;
  final DateTime createdAt;

  /// In the server's order: by type, then code. Offline, in the sell
  /// screen's type order.
  final List<SoldTicket> tickets;
  final bool offline;

  /// One line per ticket type, in the tickets' order, for the order summary.
  List<SoldLine> get lines {
    final lines = <String, SoldLine>{};
    for (final ticket in tickets) {
      final line = lines[ticket.ticketTypeId];
      lines[ticket.ticketTypeId] = line == null
          ? SoldLine(ticket, 1, ticket.pricePiastres)
          : SoldLine(line.ticket, line.quantity + 1, line.subtotalPiastres + ticket.pricePiastres);
    }
    return [...lines.values];
  }

  factory SoldOrder.fromJson(Map<String, dynamic> json) => SoldOrder(
        id: json['order_id'] as String,
        number: json['order_number'] as int,
        totalPiastres: json['total_piastres'] as int,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        tickets: [
          for (final ticket in json['tickets'] as List)
            SoldTicket.fromJson(ticket as Map<String, dynamic>),
        ],
      );

  @override
  List<Object?> get props => [id, number, totalPiastres, createdAt, tickets, offline];
}

/// A type in a [SoldOrder]: its first ticket (for the name), how many, and
/// what they cost together.
class SoldLine extends Equatable {
  const SoldLine(this.ticket, this.quantity, this.subtotalPiastres);

  final SoldTicket ticket;
  final int quantity;
  final int subtotalPiastres;

  @override
  List<Object?> get props => [ticket, quantity, subtotalPiastres];
}

/// What `confirm_payment` returns: this one order's figures, which the
/// payment screen already showed. No totals across orders (ADR-0008).
class PaymentResult extends Equatable {
  const PaymentResult({
    required this.method,
    required this.totalPiastres,
    required this.tipPiastres,
    required this.amountReceivedPiastres,
    required this.changePiastres,
  });

  final PaymentMethod method;
  final int totalPiastres;
  final int tipPiastres;
  final int amountReceivedPiastres;
  final int changePiastres;

  factory PaymentResult.fromJson(Map<String, dynamic> json) => PaymentResult(
        method: PaymentMethod.values.byName(json['payment_method'] as String),
        totalPiastres: json['total_piastres'] as int,
        tipPiastres: json['tip_piastres'] as int,
        amountReceivedPiastres: json['amount_received_piastres'] as int,
        changePiastres: json['change_piastres'] as int,
      );

  @override
  List<Object?> get props =>
      [method, totalPiastres, tipPiastres, amountReceivedPiastres, changePiastres];
}

/// `cancel_order`'s reasons (`action_reason`); `other` needs typed text.
enum CancelReason {
  customerDidNotPay('customer_did_not_pay'),
  other('other');

  const CancelReason(this.key);

  /// The database value.
  final String key;
}

/// Why the cashier left a paid order with tickets that never printed
/// (`leave_unprinted_tickets`, ADR-0024); `other` needs typed text.
enum LeaveReason {
  printedAfterAll('printed_after_all'),
  customerLeft('customer_left'),
  other('other');

  const LeaveReason(this.key);

  /// The database value.
  final String key;
}

/// The `settings` the sell flow reads. Cached on the counter for offline
/// selling (ADR-0015).
class SellSettings extends Equatable {
  const SellSettings({
    required this.venueName,
    required this.tipsEnabled,
    required this.tipQuickAmountsPiastres,
    required this.receivedQuickAmountsPiastres,
    required this.healthCheckSeconds,
    this.dayStart = VenueTime.midnight,
    this.closingTime = const VenueTime(23, 0),
    this.offlinePoolSize = 200,
    this.peak = PeakSchedule.none,
  });

  /// Printed on each ticket.
  final String venueName;
  final bool tipsEnabled;
  final List<int> tipQuickAmountsPiastres;

  /// The payment screen offers those above the order's total.
  final List<int> receivedQuickAmountsPiastres;

  /// How often the printer badge and the server are checked in the
  /// background: `offline_health_check_seconds`.
  final int healthCheckSeconds;

  /// `venue_day_starts_at` (ADR-0038). An offline copy from before it has
  /// none: days then run from midnight, as they did.
  final VenueTime dayStart;

  /// `closing_time`: a same-day ticket sold offline is valid until then,
  /// and can't be sold at or after it (as `sync_offline_orders`).
  final VenueTime closingTime;

  /// The venue day the sell flow and the peak times follow.
  VenueDay get venueDay => VenueDay(start: dayStart, closing: closingTime);

  /// `offline_pool_size`; 0 turns offline selling off.
  final int offlinePoolSize;

  /// Peak times (ADR-0033): which types the sell screen shows now.
  final PeakSchedule peak;

  /// The columns [fromRow] reads.
  static const columns = 'venue_name, tips_enabled, tip_quick_amounts_piastres, '
      'received_quick_amounts_piastres, offline_health_check_seconds, venue_day_starts_at, '
      'closing_time, '
      'offline_pool_size, ${PeakSchedule.columns}';

  factory SellSettings.fromRow(Map<String, dynamic> row) => SellSettings(
        venueName: row['venue_name'] as String,
        tipsEnabled: row['tips_enabled'] as bool,
        tipQuickAmountsPiastres: (row['tip_quick_amounts_piastres'] as List).cast<int>(),
        receivedQuickAmountsPiastres: (row['received_quick_amounts_piastres'] as List).cast<int>(),
        healthCheckSeconds: row['offline_health_check_seconds'] as int,
        dayStart: switch (row['venue_day_starts_at']) {
          final String start => VenueTime.parse(start),
          _ => VenueTime.midnight,
        },
        closingTime: VenueTime.parse(row['closing_time'] as String),
        offlinePoolSize: row['offline_pool_size'] as int,
        peak: PeakSchedule.fromRow(row),
      );

  /// What [fromRow] reads back: the copy kept for offline selling.
  Map<String, Object?> toRow() => {
        'venue_name': venueName,
        'tips_enabled': tipsEnabled,
        'tip_quick_amounts_piastres': tipQuickAmountsPiastres,
        'received_quick_amounts_piastres': receivedQuickAmountsPiastres,
        'offline_health_check_seconds': healthCheckSeconds,
        'venue_day_starts_at': '$dayStart',
        'closing_time': '$closingTime',
        'offline_pool_size': offlinePoolSize,
        ...peak.toRow(),
      };

  @override
  List<Object?> get props => [
        venueName,
        tipsEnabled,
        tipQuickAmountsPiastres,
        receivedQuickAmountsPiastres,
        healthCheckSeconds,
        dayStart,
        closingTime,
        offlinePoolSize,
        peak,
      ];
}
