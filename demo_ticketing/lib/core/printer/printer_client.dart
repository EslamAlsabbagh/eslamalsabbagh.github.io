import 'dart:async';

import '../../demo/backend.dart';

/// A printer call that failed: nothing printed.
class PrinterException implements Exception {
  const PrinterException(this.message);

  final String message;

  @override
  String toString() => 'PrinterException($message)';
}

/// The thermal printer on the counter's LAN.
///
/// Production opens a TCP socket to the printer and sends ESC/POS bytes. A
/// browser can't open raw sockets, so the demo's printer is the "printer
/// tray" in the demo bar ([PrintService] hands it each page), and the bar's
/// jam switch makes it fail the way a real one does.
class PrinterClient {
  const PrinterClient({this.timeout = const Duration(seconds: 2)});

  final Duration timeout;

  Future<bool> isReachable(String host, int port) async => !DemoBackend.instance.printerJammed.value;

  Future<void> send(String host, int port, List<int> bytes) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (DemoBackend.instance.printerJammed.value) throw const PrinterException('paper jam');
  }
}
