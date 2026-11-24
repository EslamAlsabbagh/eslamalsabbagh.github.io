import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The canvas's `repeat(auto-fit, minmax(min(<minCardWidth>, 100%), 1fr))`:
/// as many equal columns as fit at [minCardWidth] (never more than there are
/// cards). With [stretch], the cards in a row match heights like CSS grid's
/// default; without it they keep their own heights, top-aligned
/// (`align-items: start`).
///
/// [trailing] (the «+ موضوع جديد» card) takes the next free cell but isn't
/// counted in the columns, so the cards keep the canvas layout.
class CardGrid extends StatelessWidget {
  const CardGrid({
    super.key,
    required this.children,
    required this.minCardWidth,
    required this.gap,
    this.stretch = true,
    this.trailing,
  });

  final List<Widget> children;
  final double minCardWidth;
  final double gap;
  final bool stretch;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fit = ((constraints.maxWidth + gap) / (minCardWidth + gap)).floor();
        // No cards: the trailing card alone, full width.
        final int mostColumns = math.max(1, children.length);
        final columns = fit.clamp(1, mostColumns);
        final cells = [...children, ?trailing];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: [
            for (var start = 0; start < cells.length; start += columns)
              _row([
                for (var i = start; i < start + columns; i++)
                  Expanded(child: i < cells.length ? cells[i] : const SizedBox.shrink()),
              ]),
          ],
        );
      },
    );
  }

  Widget _row(List<Widget> cells) {
    if (!stretch) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: gap, children: cells);
    }
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: gap, children: cells),
    );
  }
}
