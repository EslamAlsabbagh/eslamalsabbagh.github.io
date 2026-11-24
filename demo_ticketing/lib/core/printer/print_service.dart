import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../demo/printer_tray.dart';
import '../../l10n/gen/app_localizations.dart';
import 'printed_ticket.dart';
import 'printer_client.dart';
import 'printer_target.dart';
import 'raster.dart';
import 'shift_receipt.dart';
import 'test_page.dart';
import 'ticket_view.dart';
import 'widget_image.dart';

/// Turns a widget into the printer's bytes. A seam for widget tests, whose
/// fake async can't wait for a real render.
typedef RasterRenderer = Future<List<int>> Function(Widget page, PrinterTarget target);

/// How a job sent to [target] ended: the printer took it, or it didn't.
class PrintOutcome {
  const PrintOutcome(this.target, {required this.printed});

  final PrinterTarget target;
  final bool printed;
}

/// Prints tickets, the shift receipt and the test page on the counter's printer: each page is a
/// widget, rendered to an image as wide as the paper, cut to black and
/// white, and sent as a raster (ADR-0010).
///
/// One page is one connection and one cut, so a failed ticket can be shown
/// and printed again on its own.
class PrintService {
  /// [render] is kept for the production signature; the demo prints to the tray.
  // ignore: avoid_unused_constructor_parameters
  PrintService(this._client, {RasterRenderer? render});

  final PrinterClient _client;

  /// Tickets print in Arabic, as the design (agreed in 2.4).
  static const ticketLocale = Locale('ar');

  AppLocalizations get _l10n => lookupAppLocalizations(ticketLocale);

  Future<bool> isReachable(PrinterTarget target) => _client.isReachable(target.host, target.port);

  /// Every job's outcome, so a status badge follows real prints (tickets,
  /// reprints, the shift receipt, the test page) without asking each screen.
  Stream<PrintOutcome> get outcomes => _outcomes.stream;
  final _outcomes = StreamController<PrintOutcome>.broadcast();

  /// A job is being sent. A reachability check meanwhile would open a second
  /// connection to a printer busy with ours, so background checks skip it.
  bool get busy => _sending > 0;
  int _sending = 0;

  /// Throws [PrinterException].
  Future<void> printTicket(PrinterTarget target, PrintedTicket ticket) =>
      _print(target, TicketView(ticket: ticket, l10n: _l10n));

  /// The close shift receipt, in Arabic like tickets. Throws [PrinterException].
  Future<void> printShiftReceipt(PrinterTarget target, ShiftReceipt receipt) =>
      _print(target, ShiftReceiptView(receipt: receipt, l10n: _l10n));

  /// Throws [PrinterException].
  Future<void> printTestPage(PrinterTarget target, TestPageInfo info) =>
      _print(target, TestPageView(info: info, target: target, l10n: _l10n));

  /// Demo build: the page itself goes to the on-screen printer tray, rather
  /// than being rasterised to ESC/POS bytes for a socket (ADR-0022).
  Future<void> _print(PrinterTarget target, Widget page) async {
    _sending++;
    try {
      await _client.send(target.host, target.port, const []);
      PrinterTray.instance.add(page);
      _outcomes.add(PrintOutcome(target, printed: true));
    } on PrinterException {
      _outcomes.add(PrintOutcome(target, printed: false));
      rethrow;
    } finally {
      _sending--;
    }
  }

  Future<void> dispose() => _outcomes.close();

  /// The real renderer: [page] at the design's width, scaled to the paper's
  /// dots, so one layout serves 80 and 58 mm paper.
  static Future<List<int>> renderRaster(Widget page, PrinterTarget target) async {
    final image = await renderWidgetImage(
      page,
      logicalWidth: TicketView.width,
      pixelRatio: target.dotsWide / TicketView.width,
    );
    try {
      return rasterJobBytes(await toMonoBitmap(image));
    } finally {
      image.dispose();
    }
  }
}
