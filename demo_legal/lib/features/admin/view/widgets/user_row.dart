import 'package:flutter/material.dart';

import '../../../../core/format/arabic_count.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../l10n/user_role_l10n.dart';
import '../../../tasks/view/widgets/person_avatar.dart';
import '../../data/managed_user.dart';

/// One account on the users page: avatar, name and email at the start; the
/// role pill, «معطّل» and (for a lawyer) the file count at the end. The whole
/// row is one button that opens the user modal. A deactivated account is
/// faded but still opens, so it can be reactivated.
class UserRow extends StatelessWidget {
  const UserRow({super.key, required this.user, required this.onTap});

  final ManagedUser user;
  final VoidCallback onTap;

  /// Below this inner width the pills move under the name.
  static const double _wideMinWidth = 560;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.row),
      side: BorderSide(color: user.isActive ? tokens.border : tokens.doneRowBorder),
    );

    return Semantics(
      container: true,
      button: true,
      child: Material(
        color: user.isActive ? tokens.surface : tokens.doneRowBg,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Padding(
            // The 1px border takes no layout space, as on the task rows.
            padding: const EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.rowPaddingH + 1, vertical: 12 + 1),
            child: Opacity(
              opacity: user.isActive ? 1 : 0.7,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final identity = _Identity(user: user);
                  final details = _Details(user: user);
                  if (constraints.maxWidth < _wideMinWidth) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 10,
                      children: [identity, details],
                    );
                  }
                  return Row(
                    spacing: 18,
                    children: [
                      Expanded(child: identity),
                      details,
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  const _Identity({required this.user});

  final ManagedUser user;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final email = user.email;
    return Row(
      spacing: 12,
      children: [
        PersonAvatar(userId: user.id, name: user.displayName, size: 36, letterSize: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.displayName, style: AppTextStyles.taskTitle.copyWith(color: tokens.ink)),
              if (email != null)
                // An address reads left to right; it still lines up with the
                // name at the start.
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    email,
                    textDirection: TextDirection.ltr,
                    style: AppTextStyles.meta.copyWith(color: tokens.textMuted),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.user});

  final ManagedUser user;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final files = user.fileIds.length;

    return Wrap(
      spacing: 10,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _Pill(label: user.role.label(l10n), bg: tokens.mutedFill, fg: tokens.onMutedFill),
        if (!user.isActive)
          _Pill(key: const Key('user-inactive'), label: l10n.userInactive, bg: tokens.segmentBg, fg: tokens.textSoft),
        if (user.role.needsFiles)
          Text(
            files == 0
                ? l10n.userFileCountZero
                : arabicCount(
                    files,
                    one: l10n.userFileCountOne,
                    two: l10n.userFileCountTwo,
                    few: l10n.userFileCountFew,
                    many: l10n.userFileCountMany,
                  ),
            key: const Key('user-file-count'),
            style: AppTextStyles.meta.copyWith(color: tokens.textMuted),
          ),
      ],
    );
  }
}

/// 13 / 600 on a pill, like the status pill.
class _Pill extends StatelessWidget {
  const _Pill({super.key, required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadii.pill)),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 10, vertical: 2),
        child: Text(label, style: AppTextStyles.fieldLabel.copyWith(color: fg)),
      ),
    );
  }
}
