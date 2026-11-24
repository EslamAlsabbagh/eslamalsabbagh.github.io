import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';

/// Round avatar with the first letter of the name, in the user's palette
/// colors. With no name (profile hidden), a muted person icon.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({super.key, required this.userId, required this.name, this.size = 28, this.letterSize = 13});

  final String userId;
  final String? name;
  final double size;

  /// 13 in rows, 18 on a person card's 44px avatar (spec §4 View 3).
  final double letterSize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final name = this.name;
    final colors = tokens.avatarFor(userId);
    final hasName = name != null && name.isNotEmpty;

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: hasName ? colors.bg : tokens.mutedFill,
          shape: BoxShape.circle,
        ),
        child: hasName
            ? Text(
                name.characters.first,
                style: AppTextStyles.meta.copyWith(
                  fontSize: letterSize,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: colors.fg,
                ),
              )
            : Icon(Icons.person_outline, size: size * 0.6, color: tokens.textMuted),
      ),
    );
  }
}
