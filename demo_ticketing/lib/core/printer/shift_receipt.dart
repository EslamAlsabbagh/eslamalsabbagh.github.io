import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';
import '../money.dart';
import 'ticket_view.dart';

/// One ticket type's line on the receipt.
class ReceiptTypeCount extends Equatable {
  const ReceiptTypeCount({required this.nameAr, required this.nameEn, required this.count});

  final String nameAr;
  final String nameEn;
  final int count;

  String name(String localeName) => localeName == 'ar' ? nameAr : nameEn;

  @override
  List<Object?> get props => [nameAr, nameEn, count];
}

/// The printed shift receipt (`ShiftReceipt.dc.html`): what `close_shift`
/// returns, plus the venue name. Counts and the counted cash only, never
/// expected cash or the difference (ADR-0008).
class ShiftReceipt extends Equatable {
  const ShiftReceipt({
    required this.venueName,
    required this.shiftNumber,
    required this.counterName,
    required this.cashierName,
    required this.openedAt,
    required this.closedAt,
    required this.ticketsByType,
    required this.ticketsTotal,
    required this.ordersCount,
    required this.countedCashPiastres,
    required this.tipsCount,
    required this.tipsTotalPiastres,
    required this.tipsAddedAtCloseCount,
    required this.reprints,
    required this.reactivations,
    required this.voidRefunds,
    required this.cancelledOrders,
    required this.leftUnprinted,
  });

  final String venueName;
  final int shiftNumber;
  final String counterName;
  final String cashierName;
  final DateTime openedAt;
  final DateTime closedAt;
  final List<ReceiptTypeCount> ticketsByType;
  final int ticketsTotal;
  final int ordersCount;
  final int countedCashPiastres;
  final int tipsCount;
  final int tipsTotalPiastres;
  final int tipsAddedAtCloseCount;
  final int reprints;
  final int reactivations;
  final int voidRefunds;
  final int cancelledOrders;
  final int leftUnprinted;

  /// `close_shift`'s result. Times are local, as the receipt prints them.
  factory ShiftReceipt.fromCloseShift(Map<String, dynamic> json, {required String venueName}) {
    final tips = json['tips'] as Map<String, dynamic>;
    final actions = json['actions'] as Map<String, dynamic>;
    return ShiftReceipt(
      venueName: venueName,
      shiftNumber: json['shift_number'] as int,
      counterName: json['counter_name'] as String,
      cashierName: json['cashier_name'] as String,
      openedAt: DateTime.parse(json['opened_at'] as String).toLocal(),
      closedAt: DateTime.parse(json['closed_at'] as String).toLocal(),
      ticketsByType: [
        for (final row in (json['tickets_by_type'] as List).cast<Map<String, dynamic>>())
          ReceiptTypeCount(
            nameAr: row['name_ar'] as String,
            nameEn: row['name_en'] as String,
            count: row['count'] as int,
          ),
      ],
      ticketsTotal: json['tickets_total'] as int,
      ordersCount: json['orders_count'] as int,
      countedCashPiastres: json['counted_cash_piastres'] as int,
      tipsCount: tips['count'] as int,
      tipsTotalPiastres: tips['total_piastres'] as int,
      tipsAddedAtCloseCount: tips['added_at_close_count'] as int,
      reprints: actions['reprint'] as int,
      reactivations: actions['reactivate'] as int,
      voidRefunds: actions['void_refund'] as int,
      cancelledOrders: actions['cancel_order'] as int,
      leftUnprinted: actions['left_unprinted'] as int,
    );
  }

  @override
  List<Object?> get props => [
        venueName,
        shiftNumber,
        counterName,
        cashierName,
        openedAt,
        closedAt,
        ticketsByType,
        ticketsTotal,
        ordersCount,
        countedCashPiastres,
        tipsCount,
        tipsTotalPiastres,
        tipsAddedAtCloseCount,
        reprints,
        reactivations,
        voidRefunds,
        cancelledOrders,
        leftUnprinted,
      ];
}

/// The shift receipt as printed (`ShiftReceipt.dc.html`), black on white, at
/// the ticket's width, in [l10n]'s language (Arabic, as tickets).
///
/// Differs from the design: two more action lines, cancelled orders and
/// tickets left unprinted (ADR-0024), so every action of the shift is on
/// paper.
class ShiftReceiptView extends StatelessWidget {
  const ShiftReceiptView({super.key, required this.receipt, required this.l10n});

  final ShiftReceipt receipt;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final r = receipt;
    return Directionality(
      textDirection: l10n.localeName == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: SizedBox(
          width: TicketView.width,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: DefaultTextStyle.merge(
              style: _plain(13),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(r.venueName, style: _bold(18), textAlign: TextAlign.center),
                  const SizedBox(height: 2),
                  Text(l10n.receiptTitle, style: _bold(15), textAlign: TextAlign.center),
                  _gap,
                  const DashedLine(),
                  _gap,
                  _Row(l10n.receiptShift, l10n.receiptShiftValue(r.shiftNumber, r.counterName)),
                  _Row(l10n.receiptCashier, r.cashierName),
                  _Row(l10n.receiptFrom, formatTicketTime(r.openedAt)),
                  _Row(l10n.receiptTo, formatTicketTime(r.closedAt)),
                  _gap,
                  const DashedLine(),
                  _gap,
                  Text(l10n.receiptTicketsSold, style: _bold(13)),
                  const SizedBox(height: 4),
                  for (final type in r.ticketsByType)
                    _Row(type.name(l10n.localeName), '${type.count}'),
                  _Row(l10n.receiptTicketsTotal(r.ordersCount), '${r.ticketsTotal}', bold: true),
                  _gap,
                  const DashedLine(),
                  _gap,
                  Text(l10n.receiptStatement, style: _bold(13)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: _black, width: 2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DefaultTextStyle.merge(
                      style: _bold(15),
                      child: _Row(l10n.receiptCounted, formatMoney(l10n, r.countedCashPiastres)),
                    ),
                  ),
                  const SizedBox(height: 3),
                  _Row(l10n.receiptTips(r.tipsCount), formatMoney(l10n, r.tipsTotalPiastres)),
                  _Row(l10n.receiptTipsAtClose, '${r.tipsAddedAtCloseCount}'),
                  const SizedBox(height: 8),
                  _Row(l10n.receiptReprints, '${r.reprints}'),
                  _Row(l10n.receiptReactivations, '${r.reactivations}'),
                  _Row(l10n.receiptRefunds, '${r.voidRefunds}'),
                  _Row(l10n.receiptCancelledOrders, '${r.cancelledOrders}'),
                  _Row(l10n.receiptLeftUnprinted, '${r.leftUnprinted}'),
                  _gap,
                  const DashedLine(),
                  _gap,
                  Text(l10n.receiptFooter, textAlign: TextAlign.center),
                  const SizedBox(height: 36),
                  Row(
                    children: [
                      Expanded(child: _Signature(l10n.receiptCashierSignature)),
                      const SizedBox(width: 16),
                      Expanded(child: _Signature(l10n.receiptSupervisorSignature)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _gap = SizedBox(height: 10);
const _black = Color(0xFF000000);

TextStyle _plain(double size, [FontWeight weight = FontWeight.w400]) =>
    TextStyle(fontSize: size, fontWeight: weight, color: _black);

TextStyle _bold(double size) => _plain(size, FontWeight.w700);

/// Label at the start, value at the end, as the design's
/// `justify-content: space-between` rows.
class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(value, textAlign: TextAlign.end),
        ],
      ),
    );
    return bold ? DefaultTextStyle.merge(style: _bold(13), child: row) : row;
  }
}

class _Signature extends StatelessWidget {
  const _Signature(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(height: 1, color: _black),
          const SizedBox(height: 4),
          Text(label),
        ],
      );
}
