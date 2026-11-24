import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A 2 px (or [strokeWidth]) dashed, rounded border: the design's
/// `border: … dashed` boxes (the sell screen's empty order, close shift's
/// forgotten-tip box).
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({required this.color, this.strokeWidth = 2, this.radius = 12});

  final Color color;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final border = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(strokeWidth / 2),
          Radius.circular(radius),
        ),
      );
    for (final metric in border.computeMetrics()) {
      for (var start = 0.0; start < metric.length; start += 10) {
        canvas.drawPath(metric.extractPath(start, math.min(start + 6, metric.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.radius != radius;
}
