import 'package:equatable/equatable.dart';

/// `ticket_types.validity_kind`.
enum TicketValidity { sameDay, hoursFromSale }

/// `ticket_types.sale_period` (ADR-0033): when a type is on sale.
enum SalePeriod {
  always('always'),
  offPeak('off_peak'),
  peak('peak');

  const SalePeriod(this.key);

  final String key;

  bool onSale({required bool peak}) => switch (this) {
        always => true,
        offPeak => !peak,
        SalePeriod.peak => peak,
      };

  /// A row without it (an offline copy from before peak times) is [always].
  static SalePeriod fromKey(String? key) => switch (key) {
        null || 'always' => always,
        'off_peak' => offPeak,
        'peak' => SalePeriod.peak,
        _ => throw FormatException('Unknown sale_period: $key'),
      };
}

/// A ticket type the cashier can sell (an active `ticket_types` row).
class TicketType extends Equatable {
  const TicketType({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.pricePiastres,
    required this.entriesAllowed,
    required this.validity,
    this.validityHours,
    this.salePeriod = SalePeriod.always,
  });

  final String id;
  final String nameAr;
  final String nameEn;

  /// Today's price, for the screen only: `sell_tickets` charges the server's.
  final int pricePiastres;
  final int entriesAllowed;
  final TicketValidity validity;

  /// Only for [TicketValidity.hoursFromSale].
  final int? validityHours;

  /// When it is on sale: the sell screen shows it only then.
  final SalePeriod salePeriod;

  String name(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;

  factory TicketType.fromRow(Map<String, dynamic> row) => TicketType(
        id: row['id'] as String,
        nameAr: row['name_ar'] as String,
        nameEn: row['name_en'] as String,
        pricePiastres: row['price_piastres'] as int,
        entriesAllowed: row['entries_allowed'] as int,
        validity: switch (row['validity_kind'] as String) {
          'same_day' => TicketValidity.sameDay,
          'hours_from_sale' => TicketValidity.hoursFromSale,
          final kind => throw FormatException('Unknown validity_kind: $kind'),
        },
        validityHours: row['validity_hours'] as int?,
        salePeriod: SalePeriod.fromKey(row['sale_period'] as String?),
      );

  /// What [fromRow] reads back: the copy kept for offline selling.
  Map<String, Object?> toRow() => {
        'id': id,
        'name_ar': nameAr,
        'name_en': nameEn,
        'price_piastres': pricePiastres,
        'entries_allowed': entriesAllowed,
        'validity_kind': switch (validity) {
          TicketValidity.sameDay => 'same_day',
          TicketValidity.hoursFromSale => 'hours_from_sale',
        },
        'validity_hours': validityHours,
        'sale_period': salePeriod.key,
      };

  @override
  List<Object?> get props =>
      [id, nameAr, nameEn, pricePiastres, entriesAllowed, validity, validityHours, salePeriod];
}

/// The open shift's counts for the sell screen footer (`my_shift_counts`).
/// Counts only, never money (ADR-0008).
class ShiftCounts extends Equatable {
  const ShiftCounts({
    required this.ordersCount,
    required this.ticketsCount,
    required this.awaitingPaymentCount,
    this.lastOrderNumber,
  });

  /// Paid orders, and their tickets that weren't refunded, as on the receipt.
  final int ordersCount;
  final int ticketsCount;
  final int awaitingPaymentCount;

  /// The shift's newest order in any status; null before the first sale.
  final int? lastOrderNumber;

  factory ShiftCounts.fromJson(Map<String, dynamic> json) => ShiftCounts(
        ordersCount: json['orders_count'] as int,
        ticketsCount: json['tickets_count'] as int,
        awaitingPaymentCount: json['awaiting_payment_count'] as int,
        lastOrderNumber: json['last_order_number'] as int?,
      );

  /// What [fromJson] reads back: the last counts read, shown while offline.
  Map<String, Object?> toJson() => {
        'orders_count': ordersCount,
        'tickets_count': ticketsCount,
        'awaiting_payment_count': awaitingPaymentCount,
        'last_order_number': lastOrderNumber,
      };

  /// These counts plus the offline orders the server doesn't have yet.
  ShiftCounts plusUnsynced(int orders, int tickets) => orders == 0 && tickets == 0
      ? this
      : ShiftCounts(
          ordersCount: ordersCount + orders,
          ticketsCount: ticketsCount + tickets,
          awaitingPaymentCount: awaitingPaymentCount,
          lastOrderNumber: lastOrderNumber,
        );

  @override
  List<Object?> get props => [ordersCount, ticketsCount, awaitingPaymentCount, lastOrderNumber];
}
