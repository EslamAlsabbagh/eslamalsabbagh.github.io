import 'package:equatable/equatable.dart';

import 'ticket_type.dart';

/// `orders.payment_method`; the enum names are the database values.
enum PaymentMethod { cash, card, wallet }

/// One ticket type in the current order.
class OrderLine extends Equatable {
  const OrderLine(this.type, this.quantity);

  final TicketType type;
  final int quantity;

  int get subtotalPiastres => type.pricePiastres * quantity;

  @override
  List<Object?> get props => [type, quantity];
}

/// The order the cashier has put together, ready to sell (task 2.5).
class SellDraft extends Equatable {
  const SellDraft({required this.lines, required this.method});

  final List<OrderLine> lines;

  /// Chosen on the sell screen; `confirm_payment` takes it.
  final PaymentMethod method;

  /// `sell_tickets`' `p_items`.
  List<Map<String, Object>> get items => [
        for (final line in lines) {'ticket_type_id': line.type.id, 'quantity': line.quantity},
      ];

  @override
  List<Object?> get props => [lines, method];
}
