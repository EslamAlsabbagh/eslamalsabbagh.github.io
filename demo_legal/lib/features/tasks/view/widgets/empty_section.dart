import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// Empty state of a section: centered muted text in a dashed box.
class EmptySection extends StatelessWidget {
  const EmptySection(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return CustomPaint(
      painter: DashedBorderPainter(color: tokens.borderStrong, radius: AppRadii.row),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: tokens.textMuted),
          ),
        ),
      ),
    );
  }
}

/// 1px dashed rounded border; Flutter has no dashed `BorderSide`. Also
/// draws the «المواضيع» view's «+ موضوع جديد» card.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 4;
  static const double _gap = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final outline = Path()
      ..addRRect(RRect.fromRectAndRadius(
        (Offset.zero & size).deflate(0.5),
        Radius.circular(radius),
      ));
    for (final PathMetric metric in outline.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += _dash + _gap) {
        canvas.drawPath(metric.extractPath(d, d + _dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
