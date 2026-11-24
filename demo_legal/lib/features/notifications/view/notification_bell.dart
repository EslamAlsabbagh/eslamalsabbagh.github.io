import 'package:flutter/material.dart';

import '../../../core/format/app_formats.dart';
import '../../../core/format/arabic_count.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The header's bell (spec §4 "Notifications"): an outlined bell in `bg` on
/// the dark header, with the unread count in an `urgent` badge at its top end
/// («٩+» above nine, none at zero). One button for screen readers, read as
/// «الإشعارات: ٣ إشعارات غير مقروءة».
class NotificationBell extends StatelessWidget {
  const NotificationBell({super.key, required this.unreadCount, required this.onPressed});

  final int unreadCount;

  /// Gets the bell's rect on screen, so the panel can open under it.
  final ValueChanged<Rect> onPressed;

  /// The most the badge spells out.
  static const int badgeMax = 9;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    void press() {
      final box = context.findRenderObject()! as RenderBox;
      onPressed(box.localToGlobal(Offset.zero) & box.size);
    }

    return Semantics(
      button: true,
      label: unreadCount == 0 ? l10n.notificationsTitle : l10n.notificationsBellUnread(unreadPhrase(l10n, unreadCount)),
      excludeSemantics: true,
      onTap: press,
      child: Tooltip(
        message: l10n.notificationsTitle,
        excludeFromSemantics: true,
        child: InkWell(
          key: const Key('header-notifications'),
          onTap: press,
          borderRadius: BorderRadius.circular(AppRadii.button),
          child: SizedBox.square(
            dimension: AppSpacing.touchTarget,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_none_outlined, size: 24, color: tokens.bg),
                if (unreadCount > 0)
                  PositionedDirectional(
                    top: 4,
                    end: 2,
                    child: _Badge(
                      text: unreadCount > badgeMax
                          ? l10n.notificationsBadgeMore(AppFormats.number(badgeMax))
                          : AppFormats.number(unreadCount),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// «إشعار واحد غير مقروء» / «إشعاران غير مقروءين» / «٣ إشعارات غير مقروءة»
  /// / «١١ إشعارًا غير مقروء» (spec §1's plural rule).
  static String unreadPhrase(AppLocalizations l10n, int count) => arabicCount(
        count,
        one: l10n.notificationsUnreadOne,
        two: l10n.notificationsUnreadTwo,
        few: l10n.notificationsUnreadFew,
        many: l10n.notificationsUnreadMany,
      );
}

/// A pill at least as wide as it is high, white Readex 12/600 on `urgent`.
class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      key: const Key('notifications-badge'),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tokens.urgent,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        // A ring in the header's color keeps the badge apart from the glyph.
        border: Border.all(color: tokens.ink, width: 1.5),
      ),
      child: Text(
        text,
        style: AppTextStyles.badge.copyWith(fontFamily: AppFonts.display, height: 1.2, color: tokens.surface),
      ),
    );
  }
}
