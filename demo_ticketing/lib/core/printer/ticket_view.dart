import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../l10n/gen/app_localizations.dart';
import '../money.dart';
import 'printed_ticket.dart';
import 'qr_code.dart';

/// The printed ticket (`TicketPrint.dc.html`), black on white, in [l10n]'s
/// language (Arabic, as the design). Laid out at the design's [width] in
/// logical pixels; the printer gets it scaled to its paper (`PrintService`).
///
/// Differs from the design:
/// - the validity line says when the ticket ends ("… حتى 23:00"), since an
///   `hours_from_sale` ticket ends during the day;
/// - the validity box has a third line, the home gate (1.10a, ADR-0015),
///   which the design has no place for;
/// - the counter row shows the counter's name, as stored ("شباك 1 · …");
/// - a reprint has a last row, "طباعة: نسخة 2", since the action dialog says
///   the print count shows on the ticket (`Approval.dc.html`).
class TicketView extends StatelessWidget {
  const TicketView({super.key, required this.ticket, required this.l10n});

  final PrintedTicket ticket;
  final AppLocalizations l10n;

  static const width = 320.0;

  @override
  Widget build(BuildContext context) {
    final t = ticket;
    return Directionality(
      textDirection: l10n.localeName == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: ColoredBox(
        color: const Color(0xFFFFFFFF),
        child: SizedBox(
          width: width,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.venueName, style: _bold(20), textAlign: TextAlign.center),
                _gap,
                Text(l10n.ticketHeading, style: _plain(13)),
                _gap,
                const DashedLine(),
                _gap,
                Text(t.typeName, style: _bold(30).copyWith(height: 1.2), textAlign: TextAlign.center),
                _gap,
                Text(formatMoney(l10n, t.pricePiastres), style: _plain(16, FontWeight.w600)),
                _gap,
                QrCodeView(data: t.gateCode, size: 200),
                _gap,
                Text(
                  groupGateCode(t.gateCode),
                  textDirection: TextDirection.ltr,
                  style: _bold(22).copyWith(letterSpacing: 2),
                ),
                _gap,
                _ValidityBox(ticket: t, l10n: l10n),
                _gap,
                const DashedLine(),
                _gap,
                _DetailRow(
                  label: l10n.ticketOrderLabel,
                  // Offline (ADR-0015): the shift's local number, marked, since
                  // the server numbers the order only when it uploads.
                  value: t.offline
                      ? l10n.ticketOrderValueOffline('${t.orderNumber}', '${t.index}', '${t.count}')
                      : l10n.ticketOrderValue('${t.orderNumber}', '${t.index}', '${t.count}'),
                ),
                const SizedBox(height: 2),
                _DetailRow(label: l10n.ticketCounterLabel, value: '${t.counterName} · ${t.cashierName}'),
                const SizedBox(height: 2),
                _DetailRow(label: l10n.ticketTimeLabel, value: formatTicketTime(t.soldAt)),
                // A logged reprint (ADR-0009): the paper says which copy it is.
                if (t.printCount > 1) ...[
                  const SizedBox(height: 2),
                  _DetailRow(label: l10n.ticketCopyLabel, value: l10n.ticketCopyValue(t.printCount)),
                ],
                _gap,
                const DashedLine(),
                _gap,
                Text(l10n.ticketFooter, style: _plain(12), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The validity line: "valid on 28/10/2026 until 23:00" when the ticket ends
/// on the day it starts, else "valid until 29/10/2026 01:30". In this PC's
/// time zone, which is the venue's (6.3 syncs counter clocks).
String validityLine(AppLocalizations l10n, DateTime validFrom, DateTime validUntil) {
  final from = validFrom.toLocal();
  final until = validUntil.toLocal();
  final date = _date.format(until);
  final time = _time.format(until);
  final sameDay = from.year == until.year && from.month == until.month && from.day == until.day;
  return sameDay ? l10n.ticketValidOnDay(date, time) : l10n.ticketValidUntil(date, time);
}

/// "28/10/2026 14:32", Western digits in both languages.
String formatTicketTime(DateTime time) => '${_date.format(time.toLocal())} ${_time.format(time.toLocal())}';

/// A numeric code in groups of three from the end, as the design prints it
/// ("7314902" → "7 314 902"), so it is easy to read out and type. Anything
/// else (the test page's "TEST") is printed as it is.
String groupGateCode(String code) {
  if (!RegExp(r'^\d+$').hasMatch(code)) return code;
  final groups = <String>[];
  for (var end = code.length; end > 0; end -= 3) {
    groups.insert(0, code.substring(end - 3 < 0 ? 0 : end - 3, end));
  }
  return groups.join(' ');
}

final _date = DateFormat('dd/MM/yyyy');
final _time = DateFormat('HH:mm');

const _gap = SizedBox(height: 12);
const _black = Color(0xFF000000);

TextStyle _plain(double size, [FontWeight weight = FontWeight.w400]) =>
    TextStyle(fontSize: size, fontWeight: weight, color: _black);

TextStyle _bold(double size) => _plain(size, FontWeight.w700);

class _ValidityBox extends StatelessWidget {
  const _ValidityBox({required this.ticket, required this.l10n});

  final PrintedTicket ticket;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final entries = ticket.entriesLeft == 1
        ? l10n.ticketRuleSingleEntry
        : l10n.ticketRuleEntries(ticket.entriesLeft);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: _black, width: 2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          Text(validityLine(l10n, ticket.validFrom, ticket.validUntil),
              style: _bold(14), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(entries, style: _plain(13), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(l10n.ticketHomeGate(ticket.homeGateName),
              style: _bold(14), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _plain(12)),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: _plain(12), textAlign: TextAlign.end)),
      ],
    );
  }
}

/// The design's `border-top: 2px dashed`, as wide as its parent.
class DashedLine extends StatelessWidget {
  const DashedLine({super.key});

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 2, width: double.infinity, child: CustomPaint(painter: _DashPainter()));
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  static const _dash = 6.0;
  static const _space = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _black;
    for (var x = 0.0; x < size.width; x += _dash + _space) {
      final end = x + _dash > size.width ? size.width : x + _dash;
      canvas.drawRect(Rect.fromLTRB(x, 0, end, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter oldDelegate) => false;
}
