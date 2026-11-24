import 'package:flutter/material.dart';

import '../../core/format/app_formats.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/gen/app_localizations.dart';
import 'content_frame.dart';

/// Dark top bar: today's date above the app title, with «+ مهمة جديدة» (once
/// loaded) beside it, or «+ عقد جديد» on «العقود», on the start side; the
/// task counters, the notifications bell, the signed-in user's name,
/// «المستخدمون» for admins and a sign-out button on the end side. Wraps on
/// narrow screens.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.today,
    required this.displayName,
    required this.onSignOut,
    this.counters,
    this.onNewTask,
    this.onNewContract,
    this.notifications,
    this.onOpenUsers,
  }) : assert(onNewTask == null || onNewContract == null, 'one new-item button at a time');

  final DateTime today;
  final String displayName;
  final VoidCallback onSignOut;

  /// Usually `HeaderCounters`; null hides them (before the first load).
  final Widget? counters;

  /// Opens the new-task modal; null hides the button (before the first load).
  final VoidCallback? onNewTask;

  /// Opens the contract form, in the new-task button's place (on «العقود»,
  /// chosen 2026-11-15); null hides it.
  final VoidCallback? onNewContract;

  /// Usually `NotificationBell`; null hides it.
  final Widget? notifications;

  /// Opens the users page; null hides the button (not an admin, or already
  /// on that page).
  final VoidCallback? onOpenUsers;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    // «المستخدمون» and «تسجيل الخروج»: `bg` text, no fill, 44px target.
    // «+ مهمة جديدة» or «+ عقد جديد»: the canvas's button, `accentOnDark`
    // fill, ink text, a + icon.
    final (newKey, newLabel, onNew) = onNewContract != null
        ? ('header-new-contract', l10n.contractNew, onNewContract)
        : ('header-new-task', l10n.newTask, onNewTask);
    final buttonStyle = TextButton.styleFrom(
      foregroundColor: tokens.bg,
      textStyle: AppTextStyles.button,
      minimumSize: const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
    );

    return ColoredBox(
      color: tokens.ink,
      child: ContentFrame(
        top: 20,
        bottom: 18,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 8,
          children: [
            // The new-item button beside the title (moved there for the
            // bell, chosen 2026-10-19), bottoms aligned; under it on a phone.
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 20,
              runSpacing: 10,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppFormats.headerDate(today),
                      style: AppTextStyles.meta.copyWith(color: tokens.onDarkMuted),
                    ),
                    const SizedBox(height: 2),
                    Semantics(
                      header: true,
                      child: Text(
                        l10n.appTitle,
                        style: AppTextStyles.appTitle.copyWith(color: tokens.bg),
                      ),
                    ),
                  ],
                ),
                if (onNew != null)
                  FilledButton.icon(
                    key: Key(newKey),
                    onPressed: onNew,
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.accentOnDark,
                      foregroundColor: tokens.ink,
                      textStyle: AppTextStyles.button,
                      minimumSize: const Size(0, AppSpacing.touchTarget),
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(newLabel),
                  ),
              ],
            ),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 18,
              runSpacing: 8,
              children: [
                ?counters,
                ?notifications,
                // A Wrap, so a long name and an admin's two buttons go onto
                // a second line on a narrow phone instead of overflowing.
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      displayName,
                      style: AppTextStyles.meta.copyWith(color: tokens.onDarkMuted),
                    ),
                    const SizedBox(width: 4),
                    if (onOpenUsers != null)
                      TextButton(
                        key: const Key('header-users'),
                        onPressed: onOpenUsers,
                        style: buttonStyle,
                        child: Text(l10n.headerUsers),
                      ),
                    TextButton(
                      key: const Key('header-sign-out'),
                      onPressed: onSignOut,
                      style: buttonStyle,
                      child: Text(l10n.signOut),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
