import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import 'close_icon_button.dart';

/// Opens a drawer: it slides in from the `end` side (the physical left in
/// RTL) over the scrim, and the scrim, Esc and the close button dismiss it.
/// The task drawer and the contract drawer (spec §4).
///
/// The route sits above the shell, so [builder] must hand in any bloc it
/// needs from the shell explicitly.
Future<T?> showSideDrawer<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: AppLocalizations.of(context).drawerClose,
    barrierColor: context.tokens.scrim,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => builder(context),
    transitionBuilder: (context, animation, _, child) {
      // From off-screen on the end side: negative x is the physical left.
      final fromEnd = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
      return SlideTransition(
        position: Tween(begin: Offset(fromEnd, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

/// A drawer's panel: at most 520 wide (full width on a phone), full
/// height, `surface` with the drawer shadow, at the `end` side. A sticky top
/// bar holds [title] («ملف / موضوع») and the ×; [child] scrolls under it
/// with 20 padding.
///
/// The × goes through `maybePop`, like the scrim and Esc, so a `PopScope`
/// around the panel can ask before unsaved text is lost.
class DrawerFrame extends StatelessWidget {
  const DrawerFrame({super.key, required this.panelKey, required this.title, required this.child});

  final Key panelKey;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final width = math.min(AppSpacing.drawerMaxWidth, MediaQuery.sizeOf(context).width);
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Container(
        key: panelKey,
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: tokens.surface,
          boxShadow: [BoxShadow(color: tokens.drawerShadow, blurRadius: 40)],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tokens.divider))),
                child: Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    spacing: 12,
                    children: [
                      Expanded(
                        child: Text(title, style: AppTextStyles.meta.copyWith(color: tokens.textMuted)),
                      ),
                      CloseIconButton(
                        buttonKey: const Key('drawer-close'),
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.all(AppSpacing.drawerPadding),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
