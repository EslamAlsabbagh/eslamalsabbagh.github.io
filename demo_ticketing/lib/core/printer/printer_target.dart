import 'package:equatable/equatable.dart';

/// Where a print job goes: the counter's printer (`counters` row).
class PrinterTarget extends Equatable {
  const PrinterTarget({required this.host, required this.port, required this.paperWidthMm});

  final String host;
  final int port;

  /// 58 or 80 (`counters.paper_width_mm`).
  final int paperWidthMm;

  /// Printable dots per line at 203 dpi, the usual for Xprinter models: 72 mm
  /// on 80 mm paper, 48 mm on 58 mm paper. Not confirmed until the model is
  /// known (HARDWARE.md §4).
  int get dotsWide => paperWidthMm == 58 ? 384 : 576;

  @override
  List<Object?> get props => [host, port, paperWidthMm];
}
