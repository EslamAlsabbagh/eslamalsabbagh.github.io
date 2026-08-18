import 'package:flutter/material.dart';

/// Wraps [Tooltip] and calls [Tooltip.dismissAllToolTips] on dispose to prevent
/// the overlay assertion error (_zOrderIndex != null) that occurs when a tooltip's
/// hide animation is still in flight as its parent widget is removed from the tree.
class SafeTooltip extends StatefulWidget {
  final String message;
  final Widget child;
  final TooltipTriggerMode? triggerMode;
  final bool? preferBelow;

  const SafeTooltip({super.key, required this.message, required this.child, this.triggerMode, this.preferBelow});

  @override
  State<SafeTooltip> createState() => _SafeTooltipState();
}

class _SafeTooltipState extends State<SafeTooltip> {
  @override
  void dispose() {
    Tooltip.dismissAllToolTips();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.message,
      triggerMode: widget.triggerMode,
      preferBelow: widget.preferBelow,
      child: widget.child,
    );
  }
}
