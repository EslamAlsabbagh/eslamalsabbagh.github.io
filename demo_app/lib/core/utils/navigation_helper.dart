import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/widgets/sidebar_navigation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Navigation helper that syncs sidebar state before navigating
/// This prevents ModalRoute.of(context) from returning incorrect routes during rebuilds
class NavigationHelper {
  static bool _isPublishing(BuildContext context) {
    try {
      return context.read<ScheduleBloc>().state.publishState ==
          PublishState.publishing;
    } catch (_) {
      return false;
    }
  }

  static void _showPublishingSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:
          Text(AppLocalizations.of(context)!.schedulePublishingPleaseWait),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  /// Navigate with pushReplacement and sync sidebar.
  ///
  /// AuthGate renders the dashboard at the navigator's ROOT route, and that
  /// dashboard owns unique static GlobalKeys (`TutorialKeys`). To guarantee
  /// exactly one DashboardPage is ever alive, the root must never be replaced:
  /// when we're on it (`!canPop`), push the target on top so the gate's
  /// dashboard stays underneath. Off the root, replace the current page so
  /// sibling↔sibling navigation just swaps the single page above the gate
  /// (no stack growth, still one dashboard).
  static Future<T?> pushReplacementWithSidebarSync<T extends Object?>(
    BuildContext context, {
    required String routeName,
    required Widget page,
  }) {
    if (_isPublishing(context)) {
      _showPublishingSnackbar(context);
      return Future.value(null);
    }
    // Update sidebar FIRST before navigation
    context.read<SidebarNavigationCubit>().updateFromRoute(routeName);

    final navigator = Navigator.of(context);
    final route = MaterialPageRoute<T>(
      settings: RouteSettings(name: routeName),
      builder: (_) => page,
    );
    // On the gate root: push to preserve the root dashboard. Otherwise replace.
    if (!navigator.canPop()) {
      return navigator.push<T>(route);
    }
    return navigator.pushReplacement<T, void>(route);
  }

  /// Return to the AuthGate root (the single dashboard) by popping everything
  /// pushed on top of it. The sidebar "Home" item uses this instead of pushing
  /// a new DashboardPage, which would duplicate the gate's dashboard and collide
  /// on its static `TutorialKeys`. A no-op when already at the root.
  static void goHomeWithSidebarSync(
    BuildContext context, {
    String routeName = '/home',
  }) {
    if (_isPublishing(context)) {
      _showPublishingSnackbar(context);
      return;
    }
    context.read<SidebarNavigationCubit>().updateFromRoute(routeName);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// Navigate with push and sync sidebar
  static Future<T?> pushWithSidebarSync<T extends Object?>(
    BuildContext context, {
    required String routeName,
    required Widget page,
  }) {
    if (_isPublishing(context)) {
      _showPublishingSnackbar(context);
      return Future.value(null);
    }
    // Update sidebar FIRST before navigation
    context.read<SidebarNavigationCubit>().updateFromRoute(routeName);

    // Then navigate
    return Navigator.of(context).push<T>(
      MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (_) => page,
      ),
    );
  }

  /// Navigate with pushAndRemoveUntil and sync sidebar
  static Future<T?> pushAndRemoveUntilWithSidebarSync<T extends Object?>(
    BuildContext context, {
    required String routeName,
    required Widget page,
    bool Function(Route<dynamic>)? predicate,
  }) {
    if (_isPublishing(context)) {
      _showPublishingSnackbar(context);
      return Future.value(null);
    }
    // Update sidebar FIRST before navigation
    context.read<SidebarNavigationCubit>().updateFromRoute(routeName);

    // Then navigate
    return Navigator.of(context).pushAndRemoveUntil<T>(
      MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (_) => page,
      ),
      predicate ?? (route) => false,
    );
  }
}
