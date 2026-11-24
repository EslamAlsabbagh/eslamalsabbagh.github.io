import 'package:equatable/equatable.dart';

/// The `settings` the close shift screen reads.
class CloseShiftSettings extends Equatable {
  const CloseShiftSettings({
    required this.venueName,
    required this.tipsEnabled,
    required this.tipQuickAmountsPiastres,
    required this.unpaidOrderTimeoutMin,
    required this.denominationsPiastres,
  });

  /// For the printed receipt.
  final String venueName;
  final bool tipsEnabled;
  final List<int> tipQuickAmountsPiastres;

  /// How long the unpaid-order job waits before cancelling (ADR-0016), for
  /// the message about an order still awaiting payment.
  final int unpaidOrderTimeoutMin;

  /// The notes and coins to count, in the order shown (2.7).
  final List<int> denominationsPiastres;

  factory CloseShiftSettings.fromRow(Map<String, dynamic> row) => CloseShiftSettings(
        venueName: row['venue_name'] as String,
        tipsEnabled: row['tips_enabled'] as bool,
        tipQuickAmountsPiastres: (row['tip_quick_amounts_piastres'] as List).cast<int>(),
        unpaidOrderTimeoutMin: row['unpaid_order_timeout_min'] as int,
        denominationsPiastres: (row['cash_denominations_piastres'] as List).cast<int>(),
      );

  @override
  List<Object?> get props => [
        venueName,
        tipsEnabled,
        tipQuickAmountsPiastres,
        unpaidOrderTimeoutMin,
        denominationsPiastres,
      ];
}

/// A tip of the open shift (`my_shift_tips`). Only amounts the cashier
/// entered, so nothing here adds up to expected cash (ADR-0008).
class ShiftTip extends Equatable {
  const ShiftTip({
    required this.id,
    required this.orderNumber,
    required this.amountPiastres,
    required this.createdAt,
  });

  final String id;

  /// Null for a tip added without an order (`added_at_close`).
  final int? orderNumber;
  final int amountPiastres;
  final DateTime createdAt;

  factory ShiftTip.fromJson(Map<String, dynamic> json) => ShiftTip(
        id: json['tip_id'] as String,
        orderNumber: json['order_number'] as int?,
        amountPiastres: json['amount_piastres'] as int,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );

  @override
  List<Object?> get props => [id, orderNumber, amountPiastres, createdAt];
}
