import 'package:equatable/equatable.dart';

/// What one printed ticket shows (`TicketPrint.dc.html`). Built from what
/// `sell_tickets` returns plus the venue, the counter and the cashier, or
/// from what `reprint_ticket` returns (the sale's counter and cashier) plus
/// the venue, since the cashier can't read the tickets table (ADR-0014).
class PrintedTicket extends Equatable {
  const PrintedTicket({
    required this.venueName,
    required this.typeName,
    required this.pricePiastres,
    required this.gateCode,
    required this.validFrom,
    required this.validUntil,
    required this.entriesLeft,
    required this.orderNumber,
    required this.index,
    required this.count,
    required this.counterName,
    required this.cashierName,
    required this.soldAt,
    required this.homeGateName,
    this.printCount = 1,
    this.offline = false,
  });

  final String venueName;

  /// In the ticket's language (Arabic, as the design).
  final String typeName;
  final int pricePiastres;

  /// What the QR holds and the gate reads (ADR-0005).
  final String gateCode;
  final DateTime validFrom;
  final DateTime validUntil;
  final int entriesLeft;
  final int orderNumber;

  /// This ticket's place in its order, from 1: "1 of 4".
  final int index;
  final int count;
  final String counterName;
  final String cashierName;
  final DateTime soldAt;

  /// The gate that still opens for it while the server or switch is down
  /// (ADR-0015).
  final String homeGateName;

  /// Which print this is: 1 at the sale, then one more per logged reprint
  /// (`reprint_ticket`). A copy says so on the paper (`Approval.dc.html`).
  final int printCount;

  /// Sold while the server was out of reach (ADR-0015): [orderNumber] is
  /// the shift's local number, and the paper says so.
  final bool offline;

  @override
  List<Object?> get props => [
        venueName,
        typeName,
        pricePiastres,
        gateCode,
        validFrom,
        validUntil,
        entriesLeft,
        orderNumber,
        index,
        count,
        counterName,
        cashierName,
        soldAt,
        homeGateName,
        printCount,
        offline,
      ];
}
