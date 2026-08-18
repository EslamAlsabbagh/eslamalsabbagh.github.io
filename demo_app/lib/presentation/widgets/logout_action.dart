import 'package:hrms_demo/core/services/auth_service.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:hrms_demo/presentation/widgets/sidebar_cubit.dart';
import 'package:hrms_demo/presentation/widgets/sidebar_navigation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Logs the user out and makes the login screen visible again.
///
/// This is the presentation half of what used to be `AuthService.logout`. The
/// credential-clearing half now lives in [AuthService] (core, injectable); what
/// remains here is inherently UI: reading blocs, resetting them, and collapsing
/// any pages pushed on top of `AuthGate`.
///
/// [context] may be null when logout is triggered from outside the tree (the
/// idle timeout in `main.dart`), in which case [navigatorKey] supplies one.
///
/// The ordering below is load-bearing and matches the original implementation:
/// every context-derived object is resolved **before** the first `await` so we
/// never touch a possibly-unmounted context across an async gap, and the bloc
/// reset happens **after** sign-out so the gate is already showing login and
/// won't re-dispatch a profile load for the session that just disappeared.
Future<void> logoutAndSurfaceLogin(BuildContext? context, {GlobalKey<NavigatorState>? navigatorKey}) async {
  final effectiveContext = context ?? navigatorKey?.currentContext;
  final bool hasContext = effectiveContext != null && effectiveContext.mounted;

  final navigator = hasContext ? Navigator.of(effectiveContext) : navigatorKey?.currentState;

  AuthService? authService;
  UserBloc? userBloc;
  SidebarNavigationCubit? sidebarNavigationCubit;
  SidebarCubit? sidebarCubit;
  if (hasContext) {
    try {
      authService = effectiveContext.read<AuthService>();
      userBloc = effectiveContext.read<UserBloc>();
      sidebarNavigationCubit = effectiveContext.read<SidebarNavigationCubit>();
      sidebarCubit = effectiveContext.read<SidebarCubit>();
    } catch (e) {
      debugPrint('Error reading dependencies for logout: $e');
    }
  }

  void resetAndSurfaceLogin() {
    // Reset state so a stale profile can't be shown to the next user.
    userBloc?.add(ResetUserState());
    sidebarNavigationCubit?.resetState();
    sidebarCubit?.reset();
    // AuthGate is the root route; popping to it reveals the login screen the
    // gate now renders. A no-op when nothing was pushed on top.
    navigator?.popUntil((route) => route.isFirst);
  }

  // signOutAndClearCredentials never throws, so the reset below always runs —
  // matching the old behaviour where the catch block still reset and popped.
  await authService?.signOutAndClearCredentials();
  resetAndSurfaceLogin();
}
