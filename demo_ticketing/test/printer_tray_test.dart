import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ticketing_demo/core/printer/shift_receipt.dart';
import 'package:ticketing_demo/core/printer/ticket_view.dart';
import 'package:ticketing_demo/core/theme/app_theme.dart';
import 'package:ticketing_demo/demo/backend.dart';
import 'package:ticketing_demo/features/auth/data/auth_repository.dart';
import 'package:ticketing_demo/features/sell/data/sell_draft.dart';
import 'package:ticketing_demo/features/sell/data/sell_repository.dart';
import 'package:ticketing_demo/features/shift/data/shift_repository.dart';
import 'package:ticketing_demo/features/tickets/data/ticket_lookup.dart';
import 'package:ticketing_demo/features/tickets/data/ticket_repository.dart';
import 'package:ticketing_demo/l10n/gen/app_localizations.dart';

/// The demo's printer tray shows each printed page the way production lays
/// it out for the thermal printer: 320 wide, as tall as it needs.
void main() {
  // Made outside the test's fake clock: its unpaid-order job is a periodic timer.
  final b = DemoBackend.instance;

  testWidgets('a ticket and a shift receipt lay out in the tray', (tester) async {
    b.reset();
    final (ticket, receipt) = await tester.runAsync(() async {
      await AuthRepository(b).signIn('mona', DemoBackend.password);
      await ShiftRepository(b).openShift(demoCounterId, 0);
      final sell = SellRepository(b);
      final adult = (await sell.ticketTypes()).firstWhere((t) => t.nameEn == 'Adult');
      final order = await sell.sellTickets(SellDraft(lines: [OrderLine(adult, 1)], method: PaymentMethod.card));
      await sell.confirmPayment(order.id, PaymentMethod.card);
      final reprint = await TicketRepository(b).reprint(order.tickets.single.id, ActionReason.ticketLost);
      final receipt = await ShiftRepository(b).closeShift({}, venueName: 'Riverside Gardens');
      return (reprint.printed(venueName: 'Riverside Gardens', languageCode: 'ar'), receipt);
    }) as (dynamic, ShiftReceipt);

    final l10n = lookupAppLocalizations(const Locale('ar'));
    Widget tray(Widget page) => MaterialApp(
          home: Scaffold(
            body: ListView(children: [
              Center(
                child: SizedBox(
                  width: TicketView.width,
                  child: DefaultTextStyle(
                    style: const TextStyle(fontFamily: AppSizes.fontFamily, color: Colors.black, fontSize: 14),
                    child: page,
                  ),
                ),
              ),
            ]),
          ),
        );

    await tester.pumpWidget(tray(TicketView(ticket: ticket, l10n: l10n)));
    expect(tester.takeException(), isNull);
    expect(find.byType(TicketView), findsOneWidget);

    await tester.pumpWidget(tray(ShiftReceiptView(receipt: receipt, l10n: l10n)));
    expect(tester.takeException(), isNull);
  });
}
