import 'package:flutter/material.dart';

import '../../../../core/format/text_direction.dart';

/// Saved text (an update, a title) read in its own direction. English text
/// also takes the full width, so it starts at the left even where its column
/// lines children up at the start; Arabic text is a plain [Text].
class StoredText extends StatelessWidget {
  const StoredText(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final direction = textDirectionOf(text);
    final child = Text(text, textDirection: direction, style: style);
    return direction == TextDirection.rtl ? child : SizedBox(width: double.infinity, child: child);
  }
}

/// A task title with an optional [flag] before it (spec §4 "Task row").
///
/// An Arabic title keeps the flag inline, so wrapped lines run under it. An
/// English title reads left to right in the space beside the flag, which stays
/// at the row's start like every other row's; it is centered on the first line.
class FlaggedTitle extends StatelessWidget {
  const FlaggedTitle({super.key, required this.title, required this.style, this.flag});

  final String title;
  final TextStyle style;
  final Widget? flag;

  /// Between the flag and the title.
  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final flag = this.flag;
    if (textDirectionOf(title) == TextDirection.rtl) {
      return Text.rich(
        TextSpan(
          children: [
            if (flag != null)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(padding: const EdgeInsetsDirectional.only(end: _gap), child: flag),
              ),
            TextSpan(text: title),
          ],
        ),
        style: style,
      );
    }
    final text = Text(title, textDirection: TextDirection.ltr, style: style);
    if (flag == null) return SizedBox(width: double.infinity, child: text);
    final lineHeight = MediaQuery.textScalerOf(context).scale(style.fontSize ?? 14) * (style.height ?? 1);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: _gap,
      children: [
        SizedBox(height: lineHeight, child: Center(child: flag)),
        Expanded(child: text),
      ],
    );
  }
}
