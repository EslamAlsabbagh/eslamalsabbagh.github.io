import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/connectivity/server_status_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../auth/data/staff.dart';
import '../../offline/view/offline_banner.dart';
import 'language_switch.dart';

/// The cashier screens' header: title and subtitle at the start; [badges],
/// who is logged in and the header buttons at the end.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.badges = const [],
    this.canLeave = true,
    this.onBack,
  });

  final String title;
  final String subtitle;

  /// Status pills before the name (the sell screen's printer), after the
  /// server's, which every screen shows.
  final List<Widget> badges;

  /// False hides Admin and sign out: the payment screen, where an order
  /// must be confirmed or cancelled first. Also hidden while offline.
  final bool canLeave;

  /// Shows a back arrow before the title (the ticket lookup).
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final auth = context.watch<AuthCubit>().state;
    final staff = auth is AuthSignedIn ? auth.staff : null;
    // Offline (ADR-0015) there is no way out of selling: signing back in and
    // the admin pages need the server.
    final offline = context.select((ServerStatusCubit cubit) => cubit.isOffline);
    final canLeave = this.canLeave && !offline;
    final badges = [const ServerBadge(), ...this.badges];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onBack case final onBack?) ...[
                // The design's 44 px square, bordered; the arrow follows the
                // text direction.
                SizedBox.square(
                  dimension: AppSizes.touchTarget,
                  child: OutlinedButton(
                    onPressed: onBack,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Icon(Icons.arrow_back, size: 20, semanticLabel: l10n.back),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: TextStyle(fontSize: 13, color: tokens.textSecondary)),
                ],
              ),
            ],
          ),
          // The badges, then who is logged in and the buttons: on a narrow
          // window the second group goes under the first.
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final badge in badges) ...[badge, const SizedBox(width: 8)],
                  Container(
                    width: 1,
                    height: 28,
                    margin: const EdgeInsetsDirectional.only(end: 12),
                    color: tokens.border,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (staff != null) ...[
                    Text(
                      l10n.staffWithRole(staff.fullName, roleName(l10n, staff.role)),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    // Supervisors and admins can sell, and go back to admin.
                    if (staff.role.seesAdmin && canLeave) ...[
                      OutlinedButton(
                        onPressed: () => context.go(AppRoutes.admin),
                        child: Text(l10n.adminAreaTitle),
                      ),
                      const SizedBox(width: 12),
                    ],
                  ],
                  const LanguageSwitch(),
                  if (canLeave) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: () => context.read<AuthCubit>().signOut(),
                      child: Text(l10n.signOut),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A role as the screens name it.
String roleName(AppLocalizations l10n, StaffRole role) => switch (role) {
      StaffRole.cashier => l10n.roleCashier,
      StaffRole.supervisor => l10n.roleSupervisor,
      StaffRole.admin => l10n.roleAdmin,
    };
