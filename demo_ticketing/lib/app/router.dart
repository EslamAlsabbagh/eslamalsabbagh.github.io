import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../core/printer/printer_target.dart';
import '../features/actions_log/view/actions_log_page.dart';
import '../features/admin/view/admin_shell.dart';
import '../features/auth/bloc/auth_cubit.dart';
import '../features/auth/data/staff.dart';
import '../features/auth/view/login_page.dart';
import '../features/dashboard/view/dashboard_page.dart';
import '../features/home/view/not_found_page.dart';
import '../features/home/view/splash_page.dart';
import '../features/reports/view/reports_page.dart';
import '../features/sell/view/sell_page.dart';
import '../features/shift/bloc/shift_cubit.dart';
import '../features/shift/view/close_shift_page.dart';
import '../features/shift/view/open_shift_page.dart';
import '../features/settings/view/settings_page.dart';
import '../features/shifts/view/shifts_page.dart';
import '../features/gates/view/gates_page.dart';
import '../features/ticket_types/view/ticket_types_page.dart';
import '../features/tickets/bloc/ticket_action_cubit.dart';
import '../features/tickets/view/ticket_lookup_page.dart';
import '../features/users/view/users_page.dart';

/// Route paths, so screens never spell them out.
abstract final class AppRoutes {
  /// Startup, while a saved session is checked. Every signed-in visit is
  /// redirected on to the role's landing page.
  static const home = '/';
  static const login = '/login';

  /// Open shift (task 2.2): where the cashier flow starts.
  static const shift = '/shift';

  /// Selling (task 2.3), once a shift is open at this counter.
  static const sell = '/sell';

  /// Ticket lookup (task 2.6), pushed over selling so the order in progress
  /// stays. Its `extra` is the `TicketPrintSetup` for a reprint's copy.
  static const ticket = '/sell/ticket';

  /// Close shift (task 2.7), pushed over selling so Back returns to the
  /// order in progress. Its `extra` is the counter's `PrinterTarget`, or null
  /// when none is set.
  static const closeShift = '/sell/close';

  /// Admin area (task 4.1): the live dashboard, inside the side-menu shell.
  /// Supervisors and admins only.
  static const admin = '/admin';
  static const adminShifts = '/admin/shifts';
  static const adminReports = '/admin/reports';
  static const adminActions = '/admin/actions';

  /// The actions log of one shift.
  static String actionsOfShift(String shiftId) =>
      Uri(path: adminActions, queryParameters: {'shift': shiftId}).toString();

  /// Admins only (brief's role table).
  static const adminTicketTypes = '/admin/ticket-types';
  static const adminGates = '/admin/gates';
  static const adminUsers = '/admin/users';
  static const adminSettings = '/admin/settings';

  static const adminOnly = [adminTicketTypes, adminGates, adminUsers, adminSettings];
}

/// Where the router sends [path] for this auth and shift state; null to stay.
///
/// Hides pages a role doesn't use, and keeps selling behind an open shift at
/// this counter. It isn't security: RLS and the Postgres functions enforce
/// roles and shifts (ADR-0011).
String? authRedirect(AuthState auth, String path, {ShiftState shift = const ShiftUnknown()}) {
  switch (auth) {
    case AuthUnknown():
      return path == AppRoutes.home ? null : AppRoutes.home;
    case AuthSignedOut() || AuthSigningIn():
      return path == AppRoutes.login ? null : AppRoutes.login;
    case AuthSignedIn(:final staff):
      final landing = staff.role.seesAdmin ? AppRoutes.admin : AppRoutes.shift;
      if (path == AppRoutes.home || path == AppRoutes.login) return landing;
      if (!staff.role.seesAdmin && path.startsWith(AppRoutes.admin)) return AppRoutes.shift;
      if (staff.role != StaffRole.admin &&
          AppRoutes.adminOnly.any((page) => path == page || path.startsWith('$page/'))) {
        return AppRoutes.admin;
      }
      final openHere = shift is ShiftOpen && shift.atThisCounter;
      if (path == AppRoutes.shift && openHere) return AppRoutes.sell;
      if (path.startsWith(AppRoutes.sell) && !openHere) return AppRoutes.shift;
      return null;
  }
}

/// Re-runs the redirect on every auth or shift change.
class RouterRefresh extends ChangeNotifier {
  RouterRefresh(List<Stream<Object?>> streams) {
    _subscriptions = [for (final stream in streams) stream.listen((_) => notifyListeners())];
  }

  late final List<StreamSubscription<Object?>> _subscriptions;

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}

GoRouter buildRouter({
  required AuthCubit auth,
  required ShiftCubit shift,
  required Listenable refresh,
}) =>
    GoRouter(
      initialLocation: AppRoutes.home,
      refreshListenable: refresh,
      redirect: (context, state) => authRedirect(auth.state, state.uri.path, shift: shift.state),
      routes: [
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const SplashPage(),
        ),
        GoRoute(
          path: AppRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: AppRoutes.shift,
          builder: (context, state) => const OpenShiftPage(),
        ),
        GoRoute(
          path: AppRoutes.sell,
          builder: (context, state) => const SellPage(),
          routes: [
            GoRoute(
              path: 'ticket',
              builder: (context, state) => TicketLookupPage(
                setup: state.extra as TicketPrintSetup? ??
                    const TicketPrintSetup(venueName: '', printer: null),
              ),
            ),
            GoRoute(
              path: 'close',
              builder: (context, state) => CloseShiftPage(printer: state.extra as PrinterTarget?),
            ),
          ],
        ),
        ShellRoute(
          builder: (context, state, child) => AdminShell(path: state.uri.path, child: child),
          routes: [
            GoRoute(
              path: AppRoutes.admin,
              builder: (context, state) => const DashboardPage(),
            ),
            GoRoute(
              path: AppRoutes.adminShifts,
              builder: (context, state) => const ShiftsPage(),
            ),
            GoRoute(
              path: AppRoutes.adminActions,
              // `?shift=<id>`: one shift's actions (the Shifts page's link).
              builder: (context, state) =>
                  ActionsLogPage(shiftId: state.uri.queryParameters['shift']),
            ),
            GoRoute(
              path: AppRoutes.adminReports,
              builder: (context, state) => const ReportsPage(),
            ),
            GoRoute(
              path: AppRoutes.adminTicketTypes,
              builder: (context, state) => const TicketTypesPage(),
            ),
            GoRoute(
              path: AppRoutes.adminGates,
              builder: (context, state) => const GatesPage(),
            ),
            GoRoute(
              path: AppRoutes.adminUsers,
              builder: (context, state) => const UsersPage(),
            ),
            GoRoute(
              path: AppRoutes.adminSettings,
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => const NotFoundPage(),
    );
