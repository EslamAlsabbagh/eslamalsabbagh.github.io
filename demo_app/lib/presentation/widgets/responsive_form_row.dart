import 'package:flutter/material.dart';

/// A responsive row widget that automatically switches between Row and Column
/// based on screen width.
///
/// On small screens (< 600px), children are stacked vertically in a Column.
/// On larger screens, children are displayed horizontally in a Row.
class ResponsiveFormRow extends StatelessWidget {
  /// The widgets to display
  final List<Widget> children;

  /// The breakpoint width in pixels. Defaults to 600.
  final double breakpoint;

  /// Spacing between children on mobile (vertical). Defaults to 16.
  final double mobileSpacing;

  /// Spacing between children on desktop (horizontal). Defaults to 0.
  final double desktopSpacing;

  /// Main axis alignment for desktop Row. Defaults to center.
  final MainAxisAlignment mainAxisAlignment;

  const ResponsiveFormRow({
    super.key,
    required this.children,
    this.breakpoint = 600,
    this.mobileSpacing = 16,
    this.desktopSpacing = 0,
    this.mainAxisAlignment = MainAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < breakpoint;

        if (isSmallScreen) {
          // Mobile: Stack vertically with spacing
          return Column(children: _addSpacing(children, mobileSpacing, isVertical: true));
        }

        // Desktop: Display horizontally
        return Row(
          mainAxisAlignment: mainAxisAlignment,
          children: desktopSpacing > 0 ? _addSpacing(children, desktopSpacing, isVertical: false) : children,
        );
      },
    );
  }

  /// Adds spacing between children
  List<Widget> _addSpacing(List<Widget> children, double spacing, {required bool isVertical}) {
    if (children.isEmpty) return children;

    final result = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(isVertical ? SizedBox(height: spacing) : SizedBox(width: spacing));
      }
    }
    return result;
  }
}
