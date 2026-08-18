import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.isLoading = false,
    this.color,
    this.padding,
    this.margin,
  });

  final String label;
  final VoidCallback? onPressed;
  final double? width;
  final bool isLoading;
  final Color? color;
  final EdgeInsets? padding;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const CircularProgressIndicator()
        : InkWell(
          onTap: onPressed,
          child: Container(
            width: width ?? context.maxInputWidth,
            padding: padding ?? EdgeInsets.all(12),
            margin: margin,
            decoration: BoxDecoration(
              color: color ?? Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),

            child: Center(child: Text(label, style: TextStyle(color: Colors.white))),
          ),
        );
  }
}
