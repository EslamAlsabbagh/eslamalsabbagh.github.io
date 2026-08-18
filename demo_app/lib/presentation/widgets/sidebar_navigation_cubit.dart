import 'package:flutter_bloc/flutter_bloc.dart';

/// State class for sidebar navigation
class SidebarNavigationState {
  final int? expandedTileIndex;
  final String? selectedMenuItem;

  const SidebarNavigationState({this.expandedTileIndex, this.selectedMenuItem});

  SidebarNavigationState copyWith({
    int? expandedTileIndex,
    String? selectedMenuItem,
    bool clearExpandedTile = false,
    bool clearSelectedMenuItem = false,
  }) {
    return SidebarNavigationState(
      expandedTileIndex: clearExpandedTile ? null : (expandedTileIndex ?? this.expandedTileIndex),
      selectedMenuItem: clearSelectedMenuItem ? null : (selectedMenuItem ?? this.selectedMenuItem),
    );
  }
}

/// Cubit for managing sidebar navigation state
class SidebarNavigationCubit extends Cubit<SidebarNavigationState> {
  SidebarNavigationCubit() : super(const SidebarNavigationState());

  // Track the last synced route to avoid redundant updates
  String? _lastSyncedRoute;

  // Get the current route that sidebar is synced to
  String? get currentRoute => _lastSyncedRoute;

  // Freeze state during language changes to prevent unwanted route syncing
  bool _freezeState = false;

  /// Freeze the sidebar state (used during language changes)
  void freezeState() {
    _freezeState = true;
  }

  /// Unfreeze the sidebar state
  void unfreezeState() {
    _freezeState = false;
  }

  /// Set which expansion tile is currently expanded
  void setExpandedTile(int? index) {
    emit(state.copyWith(expandedTileIndex: index, clearExpandedTile: index == null));
  }

  /// Set which menu item is currently selected
  void setSelectedMenuItem(String? menuItem) {
    emit(state.copyWith(selectedMenuItem: menuItem, clearSelectedMenuItem: menuItem == null));
  }

  /// Reset all state
  void resetState() {
    _lastSyncedRoute = null; // Reset last synced route
    _freezeState = false; // Unfreeze state
    emit(const SidebarNavigationState());
  }

  /// Update sidebar state based on current route name
  void updateFromRoute(String? routeName) {
    if (routeName == null) return;

    // If state is frozen (during language change), ignore all route sync attempts
    // Don't update _lastSyncedRoute as ModalRoute.of(context) returns wrong route during rebuilds
    if (_freezeState) {
      unfreezeState();
      return;
    }

    // Only update if route has actually changed
    if (routeName == _lastSyncedRoute) {
      return;
    }
    _lastSyncedRoute = routeName;

    // Map route names to menu items and expansion tiles
    final menuMapping = <String, Map<String, dynamic>>{
      // AuthGate root route ('/') IS the dashboard/home. Mapping it ensures that
      // when `popUntil(isFirst)` uncovers the gate root last, its didPopNext
      // resets the sidebar to Home (collapsing any tile a popped intermediate
      // route left expanded) instead of leaving a stale selection.
      '/': {'menuItem': 'home', 'tile': null},
      '/home': {'menuItem': 'home', 'tile': null},
      '/profile': {'menuItem': 'profile', 'tile': null},
      '/dashboard': {'menuItem': 'home', 'tile': null}, // Keep for backward compatibility
      '/employees': {'menuItem': 'employees', 'tile': null},
      '/hr/tools': {'menuItem': 'hr_tools', 'tile': null},
      // HR Tools hub sub-pages keep the same tile highlighted.
      '/hr/bulk-requests': {'menuItem': 'hr_tools', 'tile': null},
      '/hr/org-structure': {'menuItem': 'hr_tools', 'tile': null},
      '/orgchart': {'menuItem': 'org_chart', 'tile': null},

      // Leave routes
      '/leave/new': {'menuItem': 'leave_new_request', 'tile': 0},
      '/leave/my': {'menuItem': 'leave_my_requests', 'tile': 0},
      '/leave/team': {'menuItem': 'leave_team_requests', 'tile': 0},

      // Overtime routes
      '/overtime/new': {'menuItem': 'overtime_new_request', 'tile': 1},
      '/overtime/my': {'menuItem': 'overtime_my_requests', 'tile': 1},
      '/overtime/team': {'menuItem': 'overtime_team_requests', 'tile': 1},

      // Missing punch routes
      '/missingpunch/new': {'menuItem': 'missing_punch_new_request', 'tile': 2},
      '/missingpunch/my': {'menuItem': 'missing_punch_my_requests', 'tile': 2},
      '/missingpunch/team': {'menuItem': 'missing_punch_team_requests', 'tile': 2},

      // Business trip routes
      '/businesstrip/new': {'menuItem': 'business_trip_new_request', 'tile': 3},
      '/businesstrip/my': {'menuItem': 'business_trip_my_requests', 'tile': 3},
      '/businesstrip/team': {'menuItem': 'business_trip_team_requests', 'tile': 3},

      // Advance on salary routes
      '/advance/new': {'menuItem': 'advance_salary_new_request', 'tile': 4},
      '/advance/my': {'menuItem': 'advance_salary_my_requests', 'tile': 4},
      '/advance/team': {'menuItem': 'advance_salary_team_requests', 'tile': 4},
      '/advance/settlement_review': {'menuItem': 'advance_salary_settlement_review', 'tile': 4},

      // Disciplinary routes
      '/disciplinary/new': {'menuItem': 'disciplinary_new_request', 'tile': 5},
      '/disciplinary/my': {'menuItem': 'disciplinary_my_requests', 'tile': 5},
      '/disciplinary/team': {'menuItem': 'disciplinary_team_requests', 'tile': 5},

      // HR Letter routes
      '/hr-letter/new': {'menuItem': 'hr_letter_new_request', 'tile': 6},
      '/hr-letter/my': {'menuItem': 'hr_letter_my_requests', 'tile': 6},
      '/hr-letter/team': {'menuItem': 'hr_letter_team_requests', 'tile': 6},

      // Schedule
      '/schedule': {'menuItem': 'schedule', 'tile': null},
    };

    final mapping = menuMapping[routeName];
    if (mapping != null) {
      emit(
        SidebarNavigationState(
          selectedMenuItem: mapping['menuItem'] as String?,
          expandedTileIndex: mapping['tile'] as int?,
        ),
      );
    }
  }
}
