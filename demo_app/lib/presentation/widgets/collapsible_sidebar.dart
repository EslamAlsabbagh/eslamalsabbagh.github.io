// ignore_for_file: dead_code

import 'package:auto_size_text/auto_size_text.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/presentation/widgets/safe_tooltip.dart';
import 'package:hrms_demo/core/utils/navigation_helper.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/l10n/locale_cubit.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_state.dart';
import 'package:hrms_demo/presentation/dashboard/dashboard_refresh.dart';
import 'package:hrms_demo/presentation/profile/profile_page.dart';
import 'package:hrms_demo/presentation/employees/widgets/employees_content.dart';
import 'package:hrms_demo/presentation/statistics/statistics_page.dart';
import 'package:hrms_demo/presentation/request_businesstrip/widgets/request_businesstrip_page.dart';
import 'package:hrms_demo/presentation/request_leave/widgets/request_leave_page.dart';
import 'package:hrms_demo/presentation/request_missingpunching/widgets/request_missingpunching_page.dart';
import 'package:hrms_demo/presentation/user_businesstrip_requests/widgets/team_businesstrip_requests_page.dart';
import 'package:hrms_demo/presentation/user_businesstrip_requests/widgets/user_businesstrip_requests_page.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/bloc/user_disciplinary_action_requests_event.dart';
import 'package:hrms_demo/presentation/user_missingpunch-requests/widgets/team_missingpunch_requests_page.dart';
import 'package:hrms_demo/presentation/user_missingpunch-requests/widgets/user_missingpunch_requests_page.dart';
import 'package:hrms_demo/presentation/user_requests/widgets/team_requests_page.dart';
import 'package:hrms_demo/presentation/user_requests/widgets/user_requests_page.dart';
import 'package:hrms_demo/presentation/widgets/language_toggle_widget.dart';
import 'package:hrms_demo/presentation/widgets/org_chart_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:typewritertext/typewritertext.dart';
import 'sidebar_cubit.dart';
import 'sidebar_navigation_cubit.dart';
import 'package:hrms_demo/presentation/request_overtime/request_overtime_page.dart';
import 'package:hrms_demo/presentation/user_overtime_requests/user_overtime_requests_page.dart';
import 'package:hrms_demo/presentation/user_overtime_requests/team_overtime_requests_page.dart';
import 'package:hrms_demo/presentation/advance_on_salary/widgets/advance_on_salary_page.dart';
import 'package:hrms_demo/presentation/user_advance_on_salary_requests/widgets/user_advance_on_salary_requests_page.dart';
import 'package:hrms_demo/presentation/user_advance_on_salary_requests/widgets/team_advance_on_salary_requests_page.dart';
import 'package:hrms_demo/presentation/disciplinary_action/widgets/disciplinary_action_page.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/widgets/user_disciplinary_action_requests_page.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/widgets/team_disciplinary_action_requests_page.dart';
import 'package:hrms_demo/presentation/hr_tools/widgets/hr_tools_hub_page.dart';
import 'package:hrms_demo/presentation/settlement_review/widgets/settlement_review_page.dart';
import 'package:hrms_demo/presentation/hr_letter/widgets/hr_letter_page.dart';
import 'package:hrms_demo/presentation/user_hr_letter_requests/widgets/user_hr_letter_requests_page.dart';
import 'package:hrms_demo/presentation/user_hr_letter_requests/widgets/team_hr_letter_requests_page.dart';
import 'package:hrms_demo/presentation/employee_schedule/employee_schedule_page.dart';

class CollapsibleSidebar extends StatefulWidget {
  final String? title;
  final bool hideWhenCollapsed;
  final Key? sidebarStripKey;

  const CollapsibleSidebar({super.key, this.title, this.hideWhenCollapsed = false, this.sidebarStripKey});

  @override
  State<CollapsibleSidebar> createState() => _CollapsibleSidebarState();
}

class _CollapsibleSidebarState extends State<CollapsibleSidebar> with RouteAware {
  // Controllers for each expansion tile
  late ExpansibleController _leaveController;
  late ExpansibleController _overtimeController;
  late ExpansibleController _missingPunchingController;
  late ExpansibleController _businessTripController;
  late ExpansibleController _advanceOnSalaryController;
  late ExpansibleController _disciplinaryActionController;
  late ExpansibleController _hrLetterController;

  @override
  void initState() {
    super.initState();
    _leaveController = ExpansibleController();
    _overtimeController = ExpansibleController();
    _missingPunchingController = ExpansibleController();
    _businessTripController = ExpansibleController();
    _advanceOnSalaryController = ExpansibleController();
    _disciplinaryActionController = ExpansibleController();
    _hrLetterController = ExpansibleController();
  }

  /// Captured in didChangeDependencies rather than read in dispose():
  /// `context.read` is unsafe once the element is deactivating.
  RouteObserver<PageRoute>? _routeObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route changes
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      _routeObserver = context.read<RouteObserver<PageRoute>>();
      _routeObserver!.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    _leaveController.dispose();
    _overtimeController.dispose();
    _missingPunchingController.dispose();
    _businessTripController.dispose();
    _advanceOnSalaryController.dispose();
    _disciplinaryActionController.dispose();
    _hrLetterController.dispose();
    super.dispose();
  }

  // @override
  // void didPush() {
  //   // Route was pushed onto navigator and is now topmost route
  //   _syncSidebarWithCurrentRoute();
  // }

  @override
  void didPopNext() {
    // Covering route was popped off the navigator, this route is now topmost
    _syncSidebarWithCurrentRoute();
  }

  void _syncSidebarWithCurrentRoute({passedRouteName}) {
    final route = passedRouteName ?? ModalRoute.of(context);
    final routeName = route?.settings.name;

    // The cubit now handles route change detection
    context.read<SidebarNavigationCubit>().updateFromRoute(routeName);
    _updateExpansionControllers();
  }

  void _updateExpansionControllers() {
    final navState = context.read<SidebarNavigationCubit>().state;
    final expandedIndex = navState.expandedTileIndex;

    // Collapse all first
    _leaveController.collapse();
    _overtimeController.collapse();
    _missingPunchingController.collapse();
    _businessTripController.collapse();
    _advanceOnSalaryController.collapse();
    _disciplinaryActionController.collapse();
    _hrLetterController.collapse();

    // Then expand the correct one
    if (expandedIndex == 0) {
      _leaveController.expand();
    } else if (expandedIndex == 1) {
      _overtimeController.expand();
    } else if (expandedIndex == 2) {
      _missingPunchingController.expand();
    } else if (expandedIndex == 3) {
      _businessTripController.expand();
    } else if (expandedIndex == 4) {
      _advanceOnSalaryController.expand();
    } else if (expandedIndex == 5) {
      _disciplinaryActionController.expand();
    } else if (expandedIndex == 6) {
      _hrLetterController.expand();
    }
  }

  void _expandTile(int tileIndex) {
    final navigationCubit = context.read<SidebarNavigationCubit>();

    // Update cubit state - only update expanded tile, keep selected menu item
    navigationCubit.setExpandedTile(tileIndex);

    // Collapse all OTHER tiles (not the one being expanded)
    if (tileIndex != 0) _leaveController.collapse();
    if (tileIndex != 1) _overtimeController.collapse();
    if (tileIndex != 2) _missingPunchingController.collapse();
    if (tileIndex != 3) _businessTripController.collapse();
    if (tileIndex != 4) _advanceOnSalaryController.collapse();
    if (tileIndex != 5) _disciplinaryActionController.collapse();
    if (tileIndex != 6) _hrLetterController.collapse();
  }

  void _collapseAllExpansionTiles() {
    // Collapse all expansion tile controllers
    _leaveController.collapse();
    _overtimeController.collapse();
    _missingPunchingController.collapse();
    _businessTripController.collapse();
    _advanceOnSalaryController.collapse();
    _disciplinaryActionController.collapse();
    _hrLetterController.collapse();

    // Reset cubit state
    context.read<SidebarNavigationCubit>().setExpandedTile(null);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SidebarNavigationCubit, SidebarNavigationState>(
      builder: (context, navState) {
        final expandedTileIndex = navState.expandedTileIndex;
        final selectedMenuItem = navState.selectedMenuItem;

        return BlocBuilder<UserBloc, UserState>(
          builder: (context, userState) {
            final user = userState.user;
            if (user == null) return const SizedBox.shrink();

            final isHR = user.groups?.contains("hr") ?? false;
            final isFinance = user.groups?.contains("finance") ?? false;
            final isLegal = user.groups?.contains("legal") ?? false;
            final isDashboard = user.groups?.contains("dashboard") ?? false;
            final isCOO = user.englishTitle?.toUpperCase().trim() == 'COO';
            final isTopManagement = user.groups?.any((g) => g.toLowerCase() == 'top management') ?? false;
            final managedEmployeesCount = userState.managedEmployeesCount ?? 0;
            final hasAdvanceRequestsMadeForUser = userState.hasAdvanceRequestsMadeForUser ?? false;
            final hasDisciplinaryRequestsMadeForUser = userState.hasDisciplinaryRequestsMadeForUser ?? false;
            final requestAvailability = userState.requestAvailability;

            return BlocBuilder<SidebarCubit, bool>(
              builder: (context, isExpanded) {
                return Stack(
                  children: [
                    // Backdrop for small screens when expanded
                    if (context.screenWidth < 600 && isExpanded)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () {
                            final cubit = context.read<SidebarCubit?>();
                            cubit?.collapse();
                          },
                          child: Container(color: Colors.black.withOpacity(0.3)),
                        ),
                      ),
                    // Sidebar
                    Positioned(
                      left: Localizations.localeOf(context).languageCode == "ar" ? null : 0,
                      right: Localizations.localeOf(context).languageCode == "ar" ? 0 : null,
                      top: 0,
                      bottom: 0,
                      child: Stack(
                        children: [
                          // Visual layer: animates freely (both directions stay
                          // smooth) and holds the menu + the tutorial highlight key.
                          // It does NOT sense the mouse — see the sensor layer below.
                          AnimatedContainer(
                            key: widget.sidebarStripKey,
                            duration: Duration(milliseconds: 200),
                            clipBehavior: Clip.hardEdge,
                            // Fill the full height: the parent Stack lays this out
                            // with loose constraints, so without this it would only
                            // be as tall as the menu content.
                            height: double.infinity,
                            width: isExpanded ? 260 : (widget.hideWhenCollapsed ? 0 : 65),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(2, 0)),
                              ],
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (context.screenWidth < 600) ...[
                                    IconButton(
                                      icon: Icon(isExpanded ? Icons.chevron_left : Icons.chevron_right),
                                      onPressed: () {
                                        final cubit = context.read<SidebarCubit?>();
                                        cubit?.toggle();
                                      },
                                    ),
                                  ],

                                  _buildMenuItem(
                                    context,
                                    Icons.home_outlined,
                                    AppLocalizations.of(context)!.home,
                                    isExpanded,
                                    'home',
                                    selectedMenuItem,
                                    () {
                                      _collapseAllExpansionTiles();
                                      // Already on the dashboard → popUntil is a
                                      // no-op and didPopNext won't fire, so refresh
                                      // here. From another page, the dashboard's
                                      // didPopNext refreshes after the pop (don't
                                      // refresh here, to avoid a double fetch).
                                      if (!Navigator.of(context).canPop()) {
                                        refreshDashboardSummaries(context);
                                      }
                                      // Pop back to the AuthGate root dashboard
                                      // rather than pushing a second DashboardPage
                                      // (which collides on its static TutorialKeys).
                                      NavigationHelper.goHomeWithSidebarSync(context, routeName: '/home');
                                    },
                                  ),
                                  Material(
                                    color: expandedTileIndex == 0 ? Colors.grey.shade300 : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    child: ExpansionTile(
                                      maintainState: true,
                                      controller: _leaveController,
                                      initiallyExpanded: expandedTileIndex == 0,
                                      onExpansionChanged: (expanded) {
                                        if (expanded) {
                                          _expandTile(0);
                                        }
                                      },
                                      leading: SizedBox(width: 24, child: Icon(Icons.back_hand_outlined)),
                                      trailing:
                                          isExpanded ? null : Opacity(opacity: 0.0, child: Icon(Icons.arrow_drop_down)),
                                      title:
                                          isExpanded
                                              ? TypeWriterText.builder(
                                                AppLocalizations.of(context)!.leave,
                                                duration: Duration(milliseconds: 10),
                                                builder: (context, value) {
                                                  return AutoSizeText(value, maxLines: 1, minFontSize: 2);
                                                },
                                              )
                                              : Text(""),
                                      children: [
                                        _buildMenuItem(
                                          context,
                                          Icons.edit_outlined,
                                          AppLocalizations.of(context)!.newRequest,
                                          isExpanded,
                                          'leave_new_request',
                                          selectedMenuItem,
                                          () async {
                                            final bool? result = await NavigationHelper.pushWithSidebarSync(
                                              context,
                                              routeName: '/leave/new',
                                              page: RequestLeavePage(),
                                            );
                                            if (result == true) {}
                                          },
                                        ),
                                        if (requestAvailability?.hasLeaveRequests == true)
                                          _buildMenuItem(
                                            context,
                                            Icons.list_alt_outlined,
                                            AppLocalizations.of(context)!.myRequests,
                                            isExpanded,
                                            'leave_my_requests',
                                            selectedMenuItem,
                                            () async {
                                              final userBloc = context.read<UserBloc>();
                                              final userId = userBloc.state.user?.id;

                                              if (userId == null) {
                                                // handle null case, e.g., show error
                                                return;
                                              }

                                              await NavigationHelper.pushReplacementWithSidebarSync(
                                                context,
                                                routeName: '/leave/my',
                                                page: const UserRequestsPage(),
                                              );
                                            },
                                          ),
                                        if ((managedEmployeesCount > 0 || isHR) &&
                                            (requestAvailability?.hasTeamLeaveRequests == true ||
                                                requestAvailability?.hasProcessedLeaveRequests == true))
                                          _buildMenuItem(
                                            context,
                                            Icons.playlist_add_check_circle_outlined,
                                            AppLocalizations.of(context)!.teamRequests,
                                            isExpanded,
                                            'leave_team_requests',
                                            selectedMenuItem,
                                            () async {
                                              final userBloc = context.read<UserBloc>();
                                              final userId = userBloc.state.user?.id;

                                              if (userId == null) {
                                                // handle null case, e.g., show error
                                                return;
                                              }

                                              await NavigationHelper.pushReplacementWithSidebarSync(
                                                context,
                                                routeName: '/leave/team',
                                                page: TeamRequestsPage(),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                  ////////////////////////////////////////
                                  /// Overtime Section Hided for now
                                  if (false)
                                    Material(
                                      color: expandedTileIndex == 1 ? Colors.grey.shade300 : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                      child: ExpansionTile(
                                        maintainState: true,
                                        controller: _overtimeController,
                                        initiallyExpanded: expandedTileIndex == 1,
                                        onExpansionChanged: (expanded) {
                                          if (expanded) {
                                            _expandTile(1);
                                          }
                                        },
                                        leading: SizedBox(width: 24, child: Icon(Icons.add_alarm_outlined)),
                                        trailing:
                                            isExpanded
                                                ? null
                                                : Opacity(opacity: 0.0, child: Icon(Icons.arrow_drop_down)),
                                        title:
                                            isExpanded
                                                ? TypeWriterText.builder(
                                                  AppLocalizations.of(context)!.overtime,
                                                  duration: Duration(milliseconds: 10),
                                                  builder: (context, value) {
                                                    return AutoSizeText(value, maxLines: 1, minFontSize: 2);
                                                  },
                                                )
                                                : Text(""),
                                        children: [
                                          _buildMenuItem(
                                            context,
                                            Icons.edit_outlined,
                                            AppLocalizations.of(context)!.newRequest,
                                            isExpanded,
                                            'overtime_new_request',
                                            selectedMenuItem,
                                            () async {
                                              final bool? result = await NavigationHelper.pushWithSidebarSync(
                                                context,
                                                routeName: '/overtime/new',
                                                page: RequestOvertimePage(),
                                              );
                                              if (result == true) {}
                                            },
                                          ),
                                          if (requestAvailability?.hasOvertimeRequests == true)
                                            _buildMenuItem(
                                              context,
                                              Icons.list_alt_outlined,
                                              AppLocalizations.of(context)!.myRequests,
                                              isExpanded,
                                              'overtime_my_requests',
                                              selectedMenuItem,
                                              () async {
                                                final userBloc = context.read<UserBloc>();
                                                final userId = userBloc.state.user?.id;

                                                if (userId == null) {
                                                  // handle null case, e.g., show error
                                                  return;
                                                }

                                                await NavigationHelper.pushReplacementWithSidebarSync(
                                                  context,
                                                  routeName: '/overtime/my',
                                                  page: UserOvertimeRequestsPage(),
                                                );
                                              },
                                            ),
                                          if ((managedEmployeesCount > 0 || isHR) &&
                                              (requestAvailability?.hasTeamOvertimeRequests == true ||
                                                  requestAvailability?.hasProcessedOvertimeRequests == true))
                                            _buildMenuItem(
                                              context,
                                              Icons.playlist_add_check_circle_outlined,
                                              AppLocalizations.of(context)!.teamRequests,
                                              isExpanded,
                                              'overtime_team_requests',
                                              selectedMenuItem,
                                              () async {
                                                final userBloc = context.read<UserBloc>();
                                                final userId = userBloc.state.user?.id;

                                                if (userId == null) {
                                                  // handle null case, e.g., show error
                                                  return;
                                                }

                                                await NavigationHelper.pushReplacementWithSidebarSync(
                                                  context,
                                                  routeName: '/overtime/team',
                                                  page: TeamOvertimeRequestsPage(),
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  Material(
                                    color: expandedTileIndex == 2 ? Colors.grey.shade300 : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    child: ExpansionTile(
                                      maintainState: true,
                                      controller: _missingPunchingController,
                                      initiallyExpanded: expandedTileIndex == 2,
                                      onExpansionChanged: (expanded) {
                                        if (expanded) {
                                          _expandTile(2);
                                        }
                                      },
                                      leading: SizedBox(width: 24, child: Icon(Icons.fingerprint_outlined)),
                                      trailing:
                                          isExpanded ? null : Opacity(opacity: 0.0, child: Icon(Icons.arrow_drop_down)),
                                      title:
                                          isExpanded
                                              ? TypeWriterText.builder(
                                                AppLocalizations.of(context)!.missingPunching,
                                                duration: Duration(milliseconds: 10),
                                                builder: (context, value) {
                                                  return AutoSizeText(value, maxLines: 1, minFontSize: 2);
                                                },
                                              )
                                              : Text(""),
                                      children: [
                                        if (context.read<UserBloc>().state.user!.missingPunchBalance! > 0)
                                          _buildMenuItem(
                                            context,
                                            Icons.edit_outlined,
                                            AppLocalizations.of(context)!.newRequest,
                                            isExpanded,
                                            'missing_punch_new_request',
                                            selectedMenuItem,
                                            () async {
                                              final bool? result = await NavigationHelper.pushWithSidebarSync(
                                                context,
                                                routeName: '/missingpunch/new',
                                                page: RequestMissingpunchingPage(),
                                              );
                                              if (result == true) {}
                                            },
                                          ),
                                        if (requestAvailability?.hasMissingPunchRequests == true)
                                          _buildMenuItem(
                                            context,
                                            Icons.list_alt_outlined,
                                            AppLocalizations.of(context)!.myRequests,
                                            isExpanded,
                                            'missing_punch_my_requests',
                                            selectedMenuItem,
                                            () async {
                                              final userBloc = context.read<UserBloc>();
                                              final userId = userBloc.state.user?.id;

                                              if (userId == null) {
                                                // handle null case, e.g., show error
                                                return;
                                              }

                                              await NavigationHelper.pushReplacementWithSidebarSync(
                                                context,
                                                routeName: '/missingpunch/my',
                                                page: UserMissingpunchRequestsPage(),
                                              );
                                            },
                                          ),
                                        if ((managedEmployeesCount > 0 || isHR) &&
                                            (requestAvailability?.hasTeamMissingPunchRequests == true ||
                                                requestAvailability?.hasProcessedMissingPunchRequests == true))
                                          _buildMenuItem(
                                            context,
                                            Icons.playlist_add_check_circle_outlined,
                                            AppLocalizations.of(context)!.teamRequests,
                                            isExpanded,
                                            'missing_punch_team_requests',
                                            selectedMenuItem,
                                            () async {
                                              final userBloc = context.read<UserBloc>();
                                              final userId = userBloc.state.user?.id;

                                              if (userId == null) {
                                                // handle null case, e.g., show error
                                                return;
                                              }

                                              await NavigationHelper.pushReplacementWithSidebarSync(
                                                context,
                                                routeName: '/missingpunch/team',
                                                page: TeamMissingpunchRequestsPage(),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                  ////////////////////////////////////////
                                  /// Business Trip Section
                                  Material(
                                    color: expandedTileIndex == 3 ? Colors.grey.shade300 : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    child: ExpansionTile(
                                      maintainState: true,
                                      controller: _businessTripController,
                                      initiallyExpanded: expandedTileIndex == 3,
                                      onExpansionChanged: (expanded) {
                                        if (expanded) {
                                          _expandTile(3);
                                        }
                                      },
                                      leading: SizedBox(width: 24, child: Icon(Icons.mode_of_travel_outlined)),
                                      trailing:
                                          isExpanded ? null : Opacity(opacity: 0.0, child: Icon(Icons.arrow_drop_down)),
                                      title:
                                          isExpanded
                                              ? TypeWriterText.builder(
                                                AppLocalizations.of(context)!.businessTrip,
                                                duration: Duration(milliseconds: 10),
                                                builder: (context, value) {
                                                  return AutoSizeText(value, maxLines: 1, minFontSize: 2);
                                                },
                                              )
                                              : Text(""),
                                      children: [
                                        _buildMenuItem(
                                          context,
                                          Icons.edit_outlined,
                                          AppLocalizations.of(context)!.newRequest,
                                          isExpanded,
                                          'business_trip_new_request',
                                          selectedMenuItem,
                                          () async {
                                            final bool? result = await NavigationHelper.pushWithSidebarSync(
                                              context,
                                              routeName: '/businesstrip/new',
                                              page: RequestBusinesstripPage(),
                                            );
                                            if (result == true) {}
                                          },
                                        ),
                                        if (requestAvailability?.hasBusinessTripRequests == true)
                                          _buildMenuItem(
                                            context,
                                            Icons.list_alt_outlined,
                                            AppLocalizations.of(context)!.myRequests,
                                            isExpanded,
                                            'business_trip_my_requests',
                                            selectedMenuItem,
                                            () async {
                                              final userBloc = context.read<UserBloc>();
                                              final userId = userBloc.state.user?.id;

                                              if (userId == null) {
                                                // handle null case, e.g., show error
                                                return;
                                              }

                                              await NavigationHelper.pushReplacementWithSidebarSync(
                                                context,
                                                routeName: '/businesstrip/my',
                                                page: UserBusinesstripRequestsPage(),
                                              );
                                            },
                                          ),
                                        if ((managedEmployeesCount > 0 || isHR) &&
                                            (requestAvailability?.hasTeamBusinessTripRequests == true ||
                                                requestAvailability?.hasProcessedBusinessTripRequests == true))
                                          _buildMenuItem(
                                            context,
                                            Icons.playlist_add_check_circle_outlined,
                                            AppLocalizations.of(context)!.teamRequests,
                                            isExpanded,
                                            'business_trip_team_requests',
                                            selectedMenuItem,
                                            () async {
                                              final userBloc = context.read<UserBloc>();
                                              final userId = userBloc.state.user?.id;

                                              if (userId == null) {
                                                // handle null case, e.g., show error
                                                return;
                                              }

                                              await NavigationHelper.pushReplacementWithSidebarSync(
                                                context,
                                                routeName: '/businesstrip/team',
                                                page: TeamBusinesstripRequestsPage(),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (managedEmployeesCount > 0 || hasAdvanceRequestsMadeForUser || isHR || isFinance)
                                    Material(
                                      color: expandedTileIndex == 4 ? Colors.grey.shade300 : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                      child: ExpansionTile(
                                        maintainState: true,
                                        controller: _advanceOnSalaryController,
                                        initiallyExpanded: expandedTileIndex == 4,
                                        onExpansionChanged: (expanded) {
                                          if (expanded) {
                                            _expandTile(4);
                                          }
                                        },
                                        leading: SizedBox(
                                          width: 24,
                                          child: Icon(Icons.account_balance_wallet_outlined),
                                        ),
                                        trailing:
                                            isExpanded
                                                ? null
                                                : Opacity(opacity: 0.0, child: Icon(Icons.arrow_drop_down)),
                                        title:
                                            isExpanded
                                                ? TypeWriterText.builder(
                                                  AppLocalizations.of(context)!.advanceOnSalary,
                                                  duration: Duration(milliseconds: 10),
                                                  builder: (context, value) {
                                                    return AutoSizeText(value, maxLines: 1, minFontSize: 2);
                                                  },
                                                )
                                                : Text(""),
                                        children: [
                                          if (managedEmployeesCount > 0)
                                            _buildMenuItem(
                                              context,
                                              Icons.edit_outlined,
                                              AppLocalizations.of(context)!.newRequest,
                                              isExpanded,
                                              'advance_salary_new_request',
                                              selectedMenuItem,
                                              () async {
                                                final bool? result = await NavigationHelper.pushWithSidebarSync(
                                                  context,
                                                  routeName: '/advance/new',
                                                  page: AdvanceOnSalaryPage(),
                                                );
                                                if (result == true) {}
                                              },
                                            ),
                                          if (requestAvailability?.hasAdvanceRequests == true)
                                            _buildMenuItem(
                                              context,
                                              Icons.list_alt_outlined,
                                              AppLocalizations.of(context)!.myRequests,
                                              isExpanded,
                                              'advance_salary_my_requests',
                                              selectedMenuItem,
                                              () async {
                                                final userBloc = context.read<UserBloc>();
                                                final userId = userBloc.state.user?.id;

                                                if (userId == null) {
                                                  // handle null case, e.g., show error
                                                  return;
                                                }

                                                await NavigationHelper.pushReplacementWithSidebarSync(
                                                  context,
                                                  routeName: '/advance/my',
                                                  page: UserAdvanceOnSalaryRequestsPage(),
                                                );
                                              },
                                            ),
                                          if (((managedEmployeesCount > 0 || isHR) &&
                                                  (requestAvailability?.hasTeamAdvanceRequests == true ||
                                                      requestAvailability?.hasProcessedAdvanceRequests == true)) ||
                                              isFinance)
                                            _buildMenuItem(
                                              context,
                                              Icons.playlist_add_check_circle_outlined,
                                              AppLocalizations.of(context)!.teamRequests,
                                              isExpanded,
                                              'advance_salary_team_requests',
                                              selectedMenuItem,
                                              () async {
                                                final userBloc = context.read<UserBloc>();
                                                final userId = userBloc.state.user?.id;

                                                if (userId == null) {
                                                  // handle null case, e.g., show error
                                                  return;
                                                }

                                                await NavigationHelper.pushReplacementWithSidebarSync(
                                                  context,
                                                  routeName: '/advance/team',
                                                  page: TeamAdvanceOnSalaryRequestsPage(),
                                                );
                                              },
                                            ),
                                          if (isFinance)
                                            _buildMenuItem(
                                              context,
                                              Icons.rate_review_outlined,
                                              AppLocalizations.of(context)!.settlementReview,
                                              isExpanded,
                                              'advance_salary_settlement_review',
                                              selectedMenuItem,
                                              () async {
                                                await NavigationHelper.pushReplacementWithSidebarSync(
                                                  context,
                                                  routeName: '/advance/settlement_review',
                                                  page: SettlementReviewPage(),
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                    ),
                                  if (managedEmployeesCount > 0 ||
                                      hasDisciplinaryRequestsMadeForUser ||
                                      isHR ||
                                      isTopManagement)
                                    Material(
                                      color: expandedTileIndex == 5 ? Colors.grey.shade300 : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                      child: ExpansionTile(
                                        maintainState: true,
                                        controller: _disciplinaryActionController,
                                        initiallyExpanded: expandedTileIndex == 5,
                                        onExpansionChanged: (expanded) {
                                          if (expanded) {
                                            _expandTile(5);
                                          }
                                        },
                                        leading: SizedBox(width: 24, child: Icon(Icons.gavel_outlined)),
                                        trailing:
                                            isExpanded
                                                ? null
                                                : Opacity(opacity: 0.0, child: Icon(Icons.arrow_drop_down)),
                                        title:
                                            isExpanded
                                                ? TypeWriterText.builder(
                                                  AppLocalizations.of(context)!.disciplinaryAction,
                                                  duration: Duration(milliseconds: 10),
                                                  builder: (context, value) {
                                                    return AutoSizeText(value, maxLines: 1, minFontSize: 2);
                                                  },
                                                )
                                                : Text(""),
                                        children: [
                                          if (managedEmployeesCount > 0)
                                            _buildMenuItem(
                                              context,
                                              Icons.edit_outlined,
                                              AppLocalizations.of(context)!.newRequest,
                                              isExpanded,
                                              'disciplinary_new_request',
                                              selectedMenuItem,
                                              () async {
                                                final bool? result = await Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    settings: const RouteSettings(name: '/disciplinary/new'),
                                                    builder: (_) => DisciplinaryActionPage(),
                                                  ),
                                                );
                                                if (result == true) {}
                                              },
                                            ),
                                          if (requestAvailability?.hasDisciplinaryRequests == true)
                                            _buildMenuItem(
                                              context,
                                              Icons.list_alt_outlined,
                                              AppLocalizations.of(context)!.myRequests,
                                              isExpanded,
                                              'disciplinary_my_requests',
                                              selectedMenuItem,
                                              () async {
                                                final userBloc = context.read<UserBloc>();
                                                final userId = userBloc.state.user?.id;

                                                if (userId == null) {
                                                  // handle null case, e.g., show error
                                                  return;
                                                }

                                                await NavigationHelper.pushReplacementWithSidebarSync(
                                                  context,
                                                  routeName: '/disciplinary/my',
                                                  page: UserDisciplinaryActionRequestsPage(
                                                    sourceType: RequestSourceType.myRequests,
                                                  ),
                                                );
                                              },
                                            ),
                                          if ((managedEmployeesCount > 0 ||
                                                  isHR ||
                                                  isFinance ||
                                                  isLegal ||
                                                  isTopManagement) &&
                                              (requestAvailability?.hasTeamDisciplinaryRequests == true ||
                                                  requestAvailability?.hasProcessedDisciplinaryRequests == true ||
                                                  isTopManagement))
                                            _buildMenuItem(
                                              context,
                                              Icons.playlist_add_check_circle_outlined,
                                              AppLocalizations.of(context)!.teamRequests,
                                              isExpanded,
                                              'disciplinary_team_requests',
                                              selectedMenuItem,
                                              () async {
                                                final userBloc = context.read<UserBloc>();
                                                final userId = userBloc.state.user?.id;

                                                if (userId == null) {
                                                  // handle null case, e.g., show error
                                                  return;
                                                }

                                                await NavigationHelper.pushReplacementWithSidebarSync(
                                                  context,
                                                  routeName: '/disciplinary/team',
                                                  page: TeamDisciplinaryActionRequestsPage(),
                                                );
                                              },
                                            ),
                                        ],
                                      ),
                                    ),

                                  ////////////////////////////////////////
                                  /// HR Letter Section
                                  Material(
                                    color: expandedTileIndex == 6 ? Colors.grey.shade300 : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
                                    child: ExpansionTile(
                                      maintainState: true,
                                      controller: _hrLetterController,
                                      initiallyExpanded: expandedTileIndex == 6,
                                      onExpansionChanged: (expanded) {
                                        if (expanded) {
                                          _expandTile(6);
                                        }
                                      },
                                      leading: SizedBox(width: 24, child: Icon(Icons.article_outlined)),
                                      trailing:
                                          isExpanded ? null : Opacity(opacity: 0.0, child: Icon(Icons.arrow_drop_down)),
                                      title:
                                          isExpanded
                                              ? TypeWriterText.builder(
                                                AppLocalizations.of(context)!.hrLetter,
                                                duration: Duration(milliseconds: 10),
                                                builder: (context, value) {
                                                  return AutoSizeText(value, maxLines: 1, minFontSize: 2);
                                                },
                                              )
                                              : Text(""),
                                      children: [
                                        _buildMenuItem(
                                          context,
                                          Icons.edit_outlined,
                                          AppLocalizations.of(context)!.newRequest,
                                          isExpanded,
                                          'hr_letter_new_request',
                                          selectedMenuItem,
                                          () async {
                                            final bool? result = await NavigationHelper.pushWithSidebarSync(
                                              context,
                                              routeName: '/hr-letter/new',
                                              page: HrLetterPage(),
                                            );
                                            if (result == true) {}
                                          },
                                        ),
                                        if (requestAvailability?.hasHrLetterRequests == true)
                                          _buildMenuItem(
                                            context,
                                            Icons.list_alt_outlined,
                                            AppLocalizations.of(context)!.myRequests,
                                            isExpanded,
                                            'hr_letter_my_requests',
                                            selectedMenuItem,
                                            () async {
                                              await NavigationHelper.pushReplacementWithSidebarSync(
                                                context,
                                                routeName: '/hr-letter/my',
                                                page: const UserHrLetterRequestsPage(),
                                              );
                                            },
                                          ),
                                        if (isHR &&
                                            (requestAvailability?.hasTeamHrLetterRequests == true ||
                                                requestAvailability?.hasProcessedHrLetterRequests == true))
                                          _buildMenuItem(
                                            context,
                                            Icons.playlist_add_check_circle_outlined,
                                            AppLocalizations.of(context)!.teamRequests,
                                            isExpanded,
                                            'hr_letter_team_requests',
                                            selectedMenuItem,
                                            () async {
                                              await NavigationHelper.pushReplacementWithSidebarSync(
                                                context,
                                                routeName: '/hr-letter/team',
                                                page: const TeamHrLetterRequestsPage(),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),

                                  //if (managedEmployeesCount > 0 || isHR || isTopManagement || isCOO)
                                  _buildMenuItem(
                                    context,
                                    Icons.calendar_month_outlined,
                                    AppLocalizations.of(context)!.schedule,
                                    isExpanded,
                                    'schedule',
                                    selectedMenuItem,
                                    () {
                                      _collapseAllExpansionTiles();
                                      NavigationHelper.pushReplacementWithSidebarSync(
                                        context,
                                        routeName: '/schedule',
                                        page: const EmployeeSchedulePage(),
                                      );
                                    },
                                  ),

                                  if (isHR || isTopManagement || isCOO)
                                    _buildMenuItem(
                                      context,
                                      Icons.groups_outlined,
                                      AppLocalizations.of(context)!.employees,
                                      isExpanded,
                                      'employees',
                                      selectedMenuItem,
                                      () {
                                        _collapseAllExpansionTiles();
                                        NavigationHelper.pushReplacementWithSidebarSync(
                                          context,
                                          routeName: '/employees',
                                          page: const EmployeesPage(),
                                        );
                                      },
                                    ),

                                  if (isHR)
                                    _buildMenuItem(
                                      context,
                                      Icons.admin_panel_settings_outlined,
                                      AppLocalizations.of(context)!.hrTools,
                                      isExpanded,
                                      'hr_tools',
                                      selectedMenuItem,
                                      () {
                                        _collapseAllExpansionTiles();
                                        NavigationHelper.pushReplacementWithSidebarSync(
                                          context,
                                          routeName: '/hr/tools',
                                          page: const HrToolsHubPage(),
                                        );
                                      },
                                    ),

                                  if (isHR || isTopManagement || isCOO)
                                    _buildMenuItem(
                                      context,
                                      Icons.account_tree_outlined,
                                      AppLocalizations.of(context)!.orgChart,
                                      isExpanded,
                                      'org_chart',
                                      selectedMenuItem,
                                      () {
                                        _collapseAllExpansionTiles();
                                        NavigationHelper.pushReplacementWithSidebarSync(
                                          context,
                                          routeName: '/orgchart',
                                          page: const OrgChartWeb(),
                                        );
                                      },
                                    ),

                                  if (isDashboard)
                                    _buildMenuItem(
                                      context,
                                      Icons.insights_outlined,
                                      AppLocalizations.of(context)!.statistics,
                                      isExpanded,
                                      'statistics',
                                      selectedMenuItem,
                                      () {
                                        _collapseAllExpansionTiles();
                                        NavigationHelper.pushReplacementWithSidebarSync(
                                          context,
                                          routeName: '/statistics',
                                          page: const StatisticsPage(),
                                        );
                                      },
                                    ),

                                  /// //////////////////////////////////////
                                  // Divider before Profile
                                  // if (isExpanded)
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16.0 : 10, vertical: 8.0),
                                    child: Divider(thickness: 1, height: 1),
                                  ),

                                  // Profile menu item
                                  _buildMenuItem(
                                    context,
                                    Icons.account_circle_outlined,
                                    AppLocalizations.of(context)!.profile,
                                    isExpanded,
                                    'profile',
                                    selectedMenuItem,
                                    () async {
                                      _collapseAllExpansionTiles();
                                      await NavigationHelper.pushReplacementWithSidebarSync(
                                        context,
                                        routeName: '/profile',
                                        page: const ProfilePage(),
                                      );
                                    },
                                  ),

                                  /// //////////////////////////////////////
                                  if (isExpanded)
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: LanguageToggleWidget(
                                        width: double.infinity,
                                        onTap: () {
                                          // Freeze sidebar navigation state before changing locale
                                          context.read<SidebarNavigationCubit>().freezeState();
                                          context.read<LocaleCubit>().toggleLocale();
                                          final cubit = context.read<SidebarCubit?>();
                                          cubit?.toggle();
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // Sensor layer: invisible, with an INSTANT width (no
                          // AnimatedContainer) so the hover boundary teleports between 65
                          // and 260 instead of sweeping across a parked pointer — the
                          // sweep was what produced the expand/collapse loop. opaque:false
                          // lets taps and the menu's own hover/tooltips pass through to the
                          // visual layer beneath it.
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: Localizations.localeOf(context).languageCode == "ar" ? null : 0,
                            right: Localizations.localeOf(context).languageCode == "ar" ? 0 : null,
                            width: isExpanded ? 260 : (widget.hideWhenCollapsed ? 0 : 65),
                            child: MouseRegion(
                              opaque: false,
                              onEnter: (_) => context.read<SidebarCubit?>()?.expand(),
                              onExit: (_) => context.read<SidebarCubit?>()?.collapse(),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String label,
    bool isExpanded,
    String menuItemId,
    String? selectedMenuItem,
    Function onTap,
  ) {
    final bool isSelected = selectedMenuItem == menuItemId;

    return SafeTooltip(
      message: isExpanded ? '' : label,
      child: Container(
        //margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.shade100 : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            dense: true,
            leading: SizedBox(width: 24, child: Icon(icon)),
            title:
                isExpanded
                    ? TypeWriterText.builder(
                      label,
                      duration: Duration(milliseconds: 10),
                      builder: (context, value) {
                        return AutoSizeText(value, maxLines: 1, minFontSize: 16);
                      },
                    )
                    : null,
            onTap: () {
              context.read<SidebarNavigationCubit>().setSelectedMenuItem(menuItemId);
              onTap();
            },
          ),
        ),
      ),
    );
  }
}
