import 'package:flutter/widgets.dart';
import 'package:qr/qr.dart';

/// The modules of [data]'s QR code: `[row][column]`, true = dark. Error
/// correction M, the smallest version that fits (a 7-digit gate code fits
/// version 1, 21 × 21).
List<List<bool>> qrModules(String data) {
  final image = QrImage(QrCode(payload: QrPayload.fromString(data)));
  return [
    for (var row = 0; row < image.moduleCount; row++)
      [for (var col = 0; col < image.moduleCount; col++) image.isDark(row, col)],
  ];
}

/// [data] as a square QR code, [size] logical pixels including a 4-module
/// white quiet zone, black on white.
///
/// Each module is a whole number of device pixels (from the media query's
/// pixel ratio), aligned to the pixel grid, so no module blurs or changes
/// width when the printed image is cut to black and white. The code is
/// centred in [size], with up to one module's width of extra margin.
class QrCodeView extends StatelessWidget {
  const QrCodeView({super.key, required this.data, required this.size});

  final String data;
  final double size;

  static const quietZoneModules = 4;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _QrPainter(
          qrModules(data),
          MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.modules, this.pixelRatio);

  final List<List<bool>> modules;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFFFFFF));
    final count = modules.length;
    final side = size.shortestSide * pixelRatio;
    final module = (side / (count + 2 * QrCodeView.quietZoneModules)).floorToDouble();
    if (module < 1) return;

    // Where this box starts on the pixel grid (the canvas is translated to
    // the box), so the code's corner can be put on a whole pixel.
    final transform = canvas.getTransform();
    final originX = transform[12] * pixelRatio;
    final originY = transform[13] * pixelRatio;
    final start = (side - module * count) / 2;
    final left = (originX + start).roundToDouble() - originX;
    final top = (originY + start).roundToDouble() - originY;

    final black = Paint()
      ..color = const Color(0xFF000000)
      ..isAntiAlias = false;
    for (var row = 0; row < count; row++) {
      for (var col = 0; col < count; col++) {
        if (!modules[row][col]) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            (left + col * module) / pixelRatio,
            (top + row * module) / pixelRatio,
            module / pixelRatio,
            module / pixelRatio,
          ),
          black,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter oldDelegate) =>
      oldDelegate.pixelRatio != pixelRatio || oldDelegate.modules != modules;
}
