import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// Section title (Readex 18 / 600, or [titleStyle]) with an optional muted
/// caption beside it.
/// On narrow screens the caption moves under the title as a whole, as the
/// canvas's flex-wrap does.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.caption, this.color, this.titleStyle});

  final String title;

  /// A file group's 20px title in the topics view.
  final TextStyle? titleStyle;
  final String? caption;

  /// Title color; ink by default.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final caption = this.caption;
    return Wrap(
      spacing: 10,
      // Bottom-aligned: both lines use the same line-height factor, so this
      // lands within a pixel of the canvas's baseline alignment.
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: (titleStyle ?? AppTextStyles.sectionTitle).copyWith(color: color ?? tokens.ink)),
        ),
        if (caption != null)
          Text(caption, style: AppTextStyles.meta.copyWith(color: tokens.textMuted)),
      ],
    );
  }
}
