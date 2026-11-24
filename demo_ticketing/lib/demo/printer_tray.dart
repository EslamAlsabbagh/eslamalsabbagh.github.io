import 'package:flutter/widgets.dart';

/// What the demo's "printer" has printed: each ticket or shift receipt as the
/// widget production rasterises for the thermal printer, newest first.
class PrinterTray extends ChangeNotifier {
  PrinterTray._();

  static final PrinterTray instance = PrinterTray._();

  final List<(Widget page, DateTime at)> pages = [];

  /// Printed since the tray was last opened.
  int unseen = 0;

  void add(Widget page) {
    pages.insert(0, (page, DateTime.now()));
    if (pages.length > 30) pages.removeLast();
    unseen++;
    notifyListeners();
  }

  void markSeen() {
    if (unseen == 0) return;
    unseen = 0;
    notifyListeners();
  }

  void clear() {
    pages.clear();
    unseen = 0;
    notifyListeners();
  }
}
