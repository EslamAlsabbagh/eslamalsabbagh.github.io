import 'package:hrms_demo/core/constants/sizes.dart';
import 'package:flutter/material.dart';

/// Visual variants for [FormMessage].
enum FormMessageType { error, success, info }

/// A small, inline message banner intended to be shown inside a form (e.g.
/// directly below a submit button) instead of a transient snackbar.
///
/// It renders an icon + message inside a rounded, tinted container whose colors
/// are driven by [type]. Layout is direction-agnostic (uses [Row]), so it
/// mirrors correctly for RTL locales such as Arabic.
class FormMessage extends StatelessWidget {
  const FormMessage({super.key, required this.message, this.type = FormMessageType.error, this.width});

  final String message;
  final FormMessageType type;

  /// Defaults to align with the page's submit button width.
  final double? width;

  ({Color background, Color border, Color foreground, IconData icon}) get _style {
    switch (type) {
      case FormMessageType.success:
        return (
          background: Colors.green.shade50,
          border: Colors.green.shade200,
          foreground: Colors.green.shade800,
          icon: Icons.check_circle_outline,
        );
      case FormMessageType.info:
        return (
          background: Colors.blue.shade50,
          border: Colors.blue.shade200,
          foreground: Colors.blue.shade800,
          icon: Icons.info_outline,
        );
      case FormMessageType.error:
        return (
          background: Colors.red.shade50,
          border: Colors.red.shade200,
          foreground: Colors.red.shade800,
          icon: Icons.error_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;

    return Container(
      width: width ?? kMaxInputWidth + 16,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: style.background,
        border: Border.all(color: style.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, color: style.foreground, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: style.foreground)),
          ),
        ],
      ),
    );
  }
}
