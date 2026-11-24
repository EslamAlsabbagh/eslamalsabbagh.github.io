import 'package:flutter/widgets.dart';

import '../../l10n/gen/app_localizations.dart';
import 'printed_ticket.dart';
import 'printer_target.dart';
import 'ticket_view.dart';

/// What the open-shift test page shows besides the printer itself.
class TestPageInfo {
  const TestPageInfo({
    required this.venueName,
    required this.counterName,
    required this.cashierName,
    required this.homeGateName,
    required this.now,
  });

  final String venueName;
  final String counterName;
  final String cashierName;

  /// Null when the counter has none yet (the sample prints "—").
  final String? homeGateName;
  final DateTime now;
}

/// The open-shift test page: the printer's details, a line of Arabic and one
/// of Latin letters with digits, then a sample ticket in the real layout, so
/// shaping, the QR and the paper width can be checked before selling
/// (ADR-0010). The sample's code is "TEST": gate codes are digits, so no gate
/// can ever accept it.
class TestPageView extends StatelessWidget {
  const TestPageView({super.key, required this.info, required this.target, required this.l10n});

  final TestPageInfo info;
  final PrinterTarget target;
  final AppLocalizations l10n;

  static const sampleCode = 'TEST';

  @override
  Widget build(BuildContext context) {
    final latin = lookupAppLocalizations(const Locale('en'));
    const black = Color(0xFF000000);
    const line = TextStyle(fontSize: 13, color: black);
    return Directionality(
      textDirection: l10n.localeName == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: SizedBox(
          width: TicketView.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  children: [
                    Text(l10n.testPageTitle,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: black)),
                    Text(latin.testPageTitle.toUpperCase(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: black)),
                    const SizedBox(height: 8),
                    Text('${info.counterName} · ${formatTicketTime(info.now)}', style: line),
                    Text(l10n.printerLabel('${target.host}:${target.port}'), style: line),
                    Text(l10n.testPagePaper('${target.paperWidthMm}'), style: line),
                    const SizedBox(height: 8),
                    Text(l10n.testPageSample, style: line),
                    Text(latin.testPageSample, style: line, textDirection: TextDirection.ltr),
                    const SizedBox(height: 12),
                    const DashedLine(),
                    const SizedBox(height: 12),
                    Text(l10n.testPageNotATicket,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: black)),
                  ],
                ),
              ),
              TicketView(
                l10n: l10n,
                ticket: PrintedTicket(
                  venueName: info.venueName,
                  typeName: l10n.testPageSampleType,
                  pricePiastres: 0,
                  gateCode: sampleCode,
                  validFrom: info.now,
                  validUntil: info.now,
                  entriesLeft: 1,
                  orderNumber: 0,
                  index: 1,
                  count: 1,
                  counterName: info.counterName,
                  cashierName: info.cashierName,
                  soldAt: info.now,
                  homeGateName: info.homeGateName ?? '—',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
