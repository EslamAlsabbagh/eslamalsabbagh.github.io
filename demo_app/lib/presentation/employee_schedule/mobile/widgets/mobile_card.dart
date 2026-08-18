import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_tokens.dart';
import 'package:flutter/material.dart';

/// A white rounded card matching the mobile design surface.
class MobileCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final BorderRadiusGeometry? borderRadius;
  final Color? color;

  const MobileCard({super.key, required this.child, this.padding, this.onTap, this.borderRadius, this.color});

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? MT.br12;
    return Material(
      color: color ?? MT.bgCard,
      borderRadius: br,
      child: InkWell(
        borderRadius: br is BorderRadius ? br : null,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: MT.hair2), borderRadius: br),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
