import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../actions_log/bloc/actions_log_cubit.dart';
import '../../actions_log/data/actions_log_repository.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../auth/data/staff.dart';
import '../../home/view/app_header.dart';
import '../../home/view/language_switch.dart';
import '../../shifts/bloc/shifts_cubit.dart';
import '../../shifts/data/shifts_repository.dart';

/// The admin area's pages, in the design's menu order.
enum AdminSection {
  dashboard(AppRoutes.admin),
  shifts(AppRoutes.adminShifts),
  reports(AppRoutes.adminReports),
  ticketTypes(AppRoutes.adminTicketTypes, adminOnly: true),
  actionsLog(AppRoutes.adminActions),
  gates(AppRoutes.adminGates, adminOnly: true),
  users(AppRoutes.adminUsers, adminOnly: true),
  settings(AppRoutes.adminSettings, adminOnly: true);

  const AdminSection(this.path, {this.adminOnly = false});

  final String path;

  /// Ticket types, gates, users and settings are the admin's (brief's role
  /// table); a supervisor doesn't see them in the menu.
  final bool adminOnly;

  bool visibleTo(StaffRole role) => !adminOnly || role == StaffRole.admin;

  String label(AppLocalizations l10n) => switch (this) {
    dashboard => l10n.navDashboard,
    shifts => l10n.navShifts,
    reports => l10n.navReports,
    ticketTypes => l10n.navTicketTypes,
    actionsLog => l10n.navActionsLog,
    gates => l10n.navGates,
    users => l10n.navUsers,
    settings => l10n.navSettings,
  };

  /// The section [path] belongs to, if any.
  static AdminSection? of(String path) {
    for (final section in values.reversed) {
      if (section == dashboard ? path == section.path : path.startsWith(section.path)) {
        return section;
      }
    }
    return null;
  }
}

/// The admin area (`Dashboard.dc.html`'s side menu): the dark menu on the
/// start side (right in Arabic), the page in the rest.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.path, required this.child});

  /// The side menu, for tests.
  static const menuKey = ValueKey('admin-menu');

  /// The current route path, to mark the menu item.
  final String path;
  final Widget child;

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    // The menu badges: kept while the shell stays, updated by their pages.
    providers: [
      BlocProvider(create: (context) => PendingShiftsCubit(context.read<ShiftsRepository>())..load()),
      BlocProvider(
        create: (context) => PendingReviewsCubit(context.read<ActionsLogRepository>())..load(),
      ),
    ],
    child: Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            key: AdminShell.menuKey,
            width: 240,
            child: _Menu(current: AdminSection.of(path)),
          ),
          Expanded(child: child),
        ],
      ),
    ),
  );
}

class _Menu extends StatelessWidget {
  const _Menu({required this.current});

  final AdminSection? current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final auth = context.watch<AuthCubit>().state;
    final staff = auth is AuthSignedIn ? auth.staff : null;
    final pendingShifts = context.watch<PendingShiftsCubit>().state;
    final pendingReviews = context.watch<PendingReviewsCubit>().state;
    int? badge(AdminSection section) => switch (section) {
      AdminSection.shifts => pendingShifts,
      AdminSection.actionsLog => pendingReviews,
      _ => null,
    };
    final sections = [
      for (final section in AdminSection.values)
        if (staff != null && section.visibleTo(staff.role)) section,
    ];

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: ColoredBox(
        color: tokens.menuBg,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 10, 18),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: tokens.primary,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(
                        Icons.confirmation_number_outlined,
                        size: 20,
                        color: tokens.surface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      l10n.adminMenuTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: tokens.surface,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    for (final section in sections)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: _MenuItem(
                          label: section.label(l10n),
                          active: section == current,
                          badge: (badge(section) ?? 0) > 0 ? badge(section) : null,
                          badgeKey: ValueKey(
                            section == AdminSection.shifts ? 'menu-badge' : 'menu-badge-${section.name}',
                          ),
                          onTap: () {
                            context.read<PendingShiftsCubit>().load();
                            context.read<PendingReviewsCubit>().load();
                            context.go(section.path);
                          },
                        ),
                      ),
                  ],
                ),
              ),
              // Not in the design: who is signed in, and the way to selling,
              // the language and sign out, which the admin pages had nowhere.
              if (staff != null) ...[
                Divider(color: tokens.menuActive, height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    l10n.staffWithRole(staff.fullName, roleName(l10n, staff.role)),
                    style: TextStyle(fontSize: 14, color: tokens.menuText),
                  ),
                ),
                const SizedBox(height: 10),
                _MenuItem(
                  label: l10n.shiftAreaTitle,
                  icon: Icons.point_of_sale_outlined,
                  active: false,
                  onTap: () => context.go(AppRoutes.shift),
                ),
                const SizedBox(height: 4),
                _MenuItem(
                  label: l10n.signOut,
                  icon: Icons.logout,
                  active: false,
                  onTap: () => context.read<AuthCubit>().signOut(),
                ),
                const SizedBox(height: 10),
                const Align(alignment: AlignmentDirectional.centerStart, child: LanguageSwitch()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
    this.badge,
    this.badgeKey,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  /// A count after the label: shifts to approve (`Shifts.dc.html`), actions
  /// to review (`ActionsLog.dc.html`).
  final int? badge;
  final Key? badgeKey;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = active ? tokens.surface : tokens.menuText;
    return Semantics(
      selected: active,
      button: true,
      child: Material(
        color: active ? tokens.menuActive : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          hoverColor: tokens.menuActive,
          onTap: onTap,
          child: Container(
            height: AppSizes.touchTarget,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: color),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: color,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (badge case final count?)
                  Container(
                    key: badgeKey,
                    constraints: const BoxConstraints(minWidth: 24),
                    height: 24,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.menuBadge,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tokens.menuBg,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
