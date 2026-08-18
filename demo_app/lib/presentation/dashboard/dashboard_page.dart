import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/tutorial/tutorial_keys.dart';
import 'package:hrms_demo/core/tutorial/tutorial_steps.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/navigation_helper.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_action_request_repo.dart';
import 'package:hrms_demo/data/repos/investigation_request/investigation_request_repo.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_request_repo.dart';
import 'package:hrms_demo/data/repos/schedule/schedule_repo.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/repos/leave_cancellation_request/leave_cancellation_request_repo.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_request_repo.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo.dart';
import 'package:hrms_demo/data/repos/businesstrip_cancellation_request/businesstrip_cancellation_request_repo.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunching_request_repo.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_state.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/pending_requests_summary_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/pending_requests_summary_event.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/pending_requests_summary_state.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/my_requests_summary_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/my_requests_summary_event.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/my_requests_summary_state.dart';
import 'package:hrms_demo/presentation/dashboard/widgets/pending_requests_summary_widget.dart';
import 'package:hrms_demo/presentation/dashboard/widgets/my_in_process_requests_widget.dart';
import 'package:hrms_demo/presentation/dashboard/widgets/my_recently_processed_requests_widget.dart';
import 'package:hrms_demo/presentation/request_leave/widgets/request_leave_page.dart';
import 'package:hrms_demo/presentation/request_businesstrip/widgets/request_businesstrip_page.dart';
import 'package:hrms_demo/presentation/request_missingpunching/widgets/request_missingpunching_page.dart';
import 'package:hrms_demo/presentation/advance_on_salary/widgets/advance_on_salary_page.dart';
import 'package:hrms_demo/presentation/disciplinary_action/widgets/disciplinary_action_page.dart';
import 'package:hrms_demo/presentation/hr_letter/widgets/hr_letter_page.dart';
import 'package:hrms_demo/presentation/widgets/loading_logo.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/dashboard_refresh.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PendingRequestsSummaryBloc>(
          create:
              (context) => PendingRequestsSummaryBloc(
                leaveRequestsRepo: context.read<LeaveRequestsRepo>(),
                leaveCancellationRequestsRepo: context.read<LeaveCancellationRequestsRepo>(),
                overtimeRequestsRepo: context.read<OvertimeRequestRepo>(),
                businessTripRequestsRepo: context.read<BusinesstripRequestsRepo>(),
                businesstripCancellationRequestsRepo: context.read<BusinesstripCancellationRequestsRepo>(),
                missingPunchRequestsRepo: context.read<MissingpunchingRequestsRepo>(),
                advanceOnSalaryRequestsRepo: context.read<AdvanceOnSalaryRequestsRepo>(),
                disciplinaryActionRequestsRepo: context.read<DisciplinaryActionRequestRepo>(),
                investigationRequestsRepo: context.read<InvestigationRequestRepo>(),
                hrLetterRequestsRepo: context.read<HrLetterRequestRepo>(),
                scheduleRepo: context.read<ScheduleRepo>(),
              ),
        ),
        BlocProvider<MyRequestsSummaryBloc>(
          create:
              (context) => MyRequestsSummaryBloc(
                leaveRequestsRepo: context.read<LeaveRequestsRepo>(),
                overtimeRequestsRepo: context.read<OvertimeRequestRepo>(),
                businessTripRequestsRepo: context.read<BusinesstripRequestsRepo>(),
                missingPunchRequestsRepo: context.read<MissingpunchingRequestsRepo>(),
                advanceOnSalaryRequestsRepo: context.read<AdvanceOnSalaryRequestsRepo>(),
                disciplinaryActionRequestsRepo: context.read<DisciplinaryActionRequestRepo>(),
                investigationRequestsRepo: context.read<InvestigationRequestRepo>(),
                hrLetterRequestsRepo: context.read<HrLetterRequestRepo>(),
                scheduleRepo: context.read<ScheduleRepo>(),
              ),
        ),
      ],
      child: const _DashboardContent(),
    );
  }
}

class _DashboardContent extends StatefulWidget {
  const _DashboardContent();

  @override
  State<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<_DashboardContent> with RouteAware {
  bool? _isQuickAccessExpanded;
  bool _hasLoadedSummaries = false;
  String? _expandedWidget; // 'pending', 'inProcess', 'recentlyProcessed', or null
  bool _hasSetInitialExpansion = false;

  /// Captured in didChangeDependencies rather than read in dispose():
  /// `context.read` is unsafe once the element is deactivating.
  RouteObserver<PageRoute>? _routeObserver;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the gate root route so we can refresh on return (Home/back).
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      _routeObserver = context.read<RouteObserver<PageRoute>>();
      _routeObserver!.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // A covering route was popped and the dashboard is visible again (Home pops
    // to here via popUntil, or a pushed page was popped). Re-fetch the summary
    // data so it reflects changes made elsewhere.
    refreshDashboardSummaries(context);
  }

  void _startTutorial(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx)!;
    // Defer to after the current frame — guarantees all RenderObjects are laid
    // out and no widget tree is mid-build when the overlay inserts itself.
    Future.delayed(Duration.zero, () {
      if (!ctx.mounted) return;
      // Filter out steps whose keyTarget widget isn't currently in the tree
      // (e.g. pending/processing/recent cards are conditionally rendered).
      final steps =
          buildDashboardSteps(l10n, ctx).where((step) {
            if (step.keyTarget == null) return true; // targetPosition steps always valid
            return step.keyTarget!.currentContext != null;
          }).toList();
      TutorialCoachMark(
        targets: steps,
        colorShadow: Colors.black87,
        paddingFocus: 4,
        opacityShadow: 0.8,
        hideSkip: true,
        beforeFocus: (target) async {
          final targetCtx = target.keyTarget?.currentContext;
          if (targetCtx == null) return;
          await Scrollable.ensureVisible(
            targetCtx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.3, // show target in upper third so tooltip has room below
          );
        },
      ).show(context: ctx, rootOverlay: true);
    });
  }

  String? _getExpandedWidget(PendingRequestsSummaryState pending, MyRequestsSummaryState my) {
    // If user has manually toggled, use that value (even if null for all collapsed)
    if (_hasSetInitialExpansion) {
      return _expandedWidget;
    }

    // Auto-expand first widget with data on initial load
    if (pending.summary.hasAnyRequests) {
      return 'pending';
    } else if (my.summary.hasInProcessRequests) {
      return 'inProcess';
    } else if (my.summary.hasRecentlyProcessedRequests) {
      return 'recentlyProcessed';
    }
    return null;
  }

  void _handleToggle(String widgetId, String? currentExpandedWidget) {
    _hasSetInitialExpansion = true; // Mark that user has interacted
    setState(() {
      if (currentExpandedWidget == widgetId) {
        _expandedWidget = null; // collapse if already expanded
      } else {
        _expandedWidget = widgetId; // expand this, collapse others
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        // AuthGate only mounts DashboardPage once the profile is loaded
        // (Status.success with a non-null user). Loading / failure / logged-out
        // states are owned by AuthGate, so this page never navigates to login —
        // that redirect was half of the recursive loop. A defensive spinner is
        // shown for any unexpected transient state instead of a Navigator call.
        final user = userState.user;
        if (user == null) {
          return const Center(child: LoadingLogo());
        }

        // Load summaries once user is available
        final userId = user.id ?? 0;
        if (!_hasLoadedSummaries && userId != 0) {
          _hasLoadedSummaries = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.read<PendingRequestsSummaryBloc>().add(LoadPendingRequestsSummary(userId, userGroups: user.groups));
            context.read<MyRequestsSummaryBloc>().add(LoadMyRequestsSummary(userId));
          });
        }

        // Get user properties for visibility logic
        //final isHR = user.groups?.contains("hr") ?? false;
        //final isFinance = user.groups?.contains("finance") ?? false;
        final managedEmployeesCount = userState.managedEmployeesCount ?? 0;
        //final hasAdvanceRequestsMadeForUser = userState.hasAdvanceRequestsMadeForUser ?? false;
        //final hasDisciplinaryRequestsMadeForUser = userState.hasDisciplinaryRequestsMadeForUser ?? false;

        return BlocBuilder<PendingRequestsSummaryBloc, PendingRequestsSummaryState>(
          builder: (context, pendingRequestsState) {
            // Set initial expanded state based on pending requests
            // If there are no pending requests, expand by default
            if (context.screenWidth > 700) {
              _isQuickAccessExpanded = true;
            } else if (_isQuickAccessExpanded == null && pendingRequestsState.status == Status.success) {
              _isQuickAccessExpanded = !pendingRequestsState.summary.hasAnyRequests;
            }

            return MainLayout(
              title: AppLocalizations.of(context)!.home,
              appBarKey: TutorialKeys.topBar,
              sidebarStripKey: TutorialKeys.sidebar,
              extraActions: [
                Builder(
                  builder:
                      (ctx) => IconButton(
                        icon: const Icon(Icons.help_outline, color: Colors.white),
                        tooltip: AppLocalizations.of(ctx)!.tutHelpTooltip,
                        onPressed: () => _startTutorial(ctx),
                      ),
                ),
              ],
              child: SingleChildScrollView(
                child: SizedBox(
                  width: context.screenWidth - 65,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Wrap(
                      spacing: 24,
                      runSpacing: 24,
                      crossAxisAlignment: WrapCrossAlignment.start,
                      alignment: WrapAlignment.start,
                      children: [
                        // Quick Access Section
                        _QuickAccessSection(
                          key: TutorialKeys.quickActions,
                          showLessMoreButton: pendingRequestsState.summary.hasAnyRequests,
                          isExpanded: _isQuickAccessExpanded ?? false,
                          onToggleExpanded: () {
                            setState(() {
                              _isQuickAccessExpanded = !(_isQuickAccessExpanded ?? false);
                            });
                          },
                          showAdvance: managedEmployeesCount > 0,
                          showDisciplinary: managedEmployeesCount > 0,
                        ),
                        // Summary Widgets Section - accordion layout
                        BlocBuilder<MyRequestsSummaryBloc, MyRequestsSummaryState>(
                          builder: (context, myRequestsState) {
                            final isLoading =
                                pendingRequestsState.status == Status.loading ||
                                myRequestsState.status == Status.loading;

                            if (isLoading) {
                              return const SizedBox(
                                height: 200,
                                width: 280,
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }

                            final hasAnyData =
                                pendingRequestsState.summary.hasAnyRequests ||
                                myRequestsState.summary.hasInProcessRequests ||
                                myRequestsState.summary.hasRecentlyProcessedRequests;

                            if (!hasAnyData &&
                                pendingRequestsState.status == Status.success &&
                                myRequestsState.status == Status.success) {
                              return const _NoUpdatesWidget();
                            }

                            // Compute which widget should be expanded
                            final expandedWidget = _getExpandedWidget(pendingRequestsState, myRequestsState);

                            // Return widgets in a Column for accordion layout
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (pendingRequestsState.summary.hasAnyRequests)
                                  _ExpandableSummaryContainer(
                                    key: TutorialKeys.pendingCard,
                                    title: AppLocalizations.of(context)!.pendingRequests,
                                    totalCount: pendingRequestsState.summary.totalRequests,
                                    themeColor: Theme.of(context).primaryColor,
                                    icon: Icons.notifications_active,
                                    isExpanded: expandedWidget == 'pending',
                                    onToggle: () => _handleToggle('pending', expandedWidget),
                                    child: const PendingRequestsSummaryWidget(embedded: true),
                                  ),
                                if (pendingRequestsState.summary.hasAnyRequests &&
                                    (myRequestsState.summary.hasInProcessRequests ||
                                        myRequestsState.summary.hasRecentlyProcessedRequests))
                                  const SizedBox(height: 12),
                                if (myRequestsState.summary.hasInProcessRequests)
                                  _ExpandableSummaryContainer(
                                    key: TutorialKeys.processingCard,
                                    title: AppLocalizations.of(context)!.myInProcessRequests,
                                    totalCount: myRequestsState.summary.totalInProcess,
                                    themeColor: Colors.cyan[700]!,
                                    icon: Icons.hourglass_empty,
                                    isExpanded: expandedWidget == 'inProcess',
                                    onToggle: () => _handleToggle('inProcess', expandedWidget),
                                    child: const MyInProcessRequestsWidget(embedded: true),
                                  ),
                                if (myRequestsState.summary.hasInProcessRequests &&
                                    myRequestsState.summary.hasRecentlyProcessedRequests)
                                  const SizedBox(height: 12),
                                if (myRequestsState.summary.hasRecentlyProcessedRequests)
                                  _ExpandableSummaryContainer(
                                    key: TutorialKeys.recentCard,
                                    title: AppLocalizations.of(context)!.myRecentlyProcessedRequests,
                                    totalCount: myRequestsState.summary.totalRecentlyProcessed,
                                    themeColor: Colors.green[700]!,
                                    icon: Icons.check_circle_outline,
                                    isExpanded: expandedWidget == 'recentlyProcessed',
                                    onToggle: () => _handleToggle('recentlyProcessed', expandedWidget),
                                    child: const MyRecentlyProcessedRequestsWidget(embedded: true),
                                  ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _QuickAccessSection extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final bool showAdvance;
  final bool showDisciplinary;
  final bool showLessMoreButton;

  const _QuickAccessSection({
    super.key,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.showAdvance,
    required this.showDisciplinary,
    required this.showLessMoreButton,
  });

  @override
  Widget build(BuildContext context) {
    // Define separate "leave request" label
    final leaveRequestLabel =
        Localizations.localeOf(context).languageCode == 'ar'
            ? "${AppLocalizations.of(context)!.request}\n${AppLocalizations.of(context)!.leave}"
            : "${AppLocalizations.of(context)!.leave}\n${AppLocalizations.of(context)!.request}";
    final quickAccessItems = [
      _QuickAccessItem(
        key: TutorialKeys.leaveButton,
        icon: Icons.back_hand_outlined,
        label: context.screenWidth < 600 ? leaveRequestLabel : AppLocalizations.of(context)!.leaveRequest,
        color: Colors.blue,
        onTap: () async {
          await NavigationHelper.pushWithSidebarSync(context, routeName: '/leave/new', page: RequestLeavePage());
        },
      ),
      _QuickAccessItem(
        icon: Icons.mode_of_travel_outlined,
        label: AppLocalizations.of(context)!.businessTripRequest,
        color: Colors.green,
        onTap: () async {
          await NavigationHelper.pushWithSidebarSync(
            context,
            routeName: '/businesstrip/new',
            page: RequestBusinesstripPage(),
          );
        },
      ),
    ];

    // Add expandable items
    final expandableItems = <Widget>[
      _QuickAccessItem(
        icon: Icons.fingerprint_outlined,
        label: AppLocalizations.of(context)!.missingPunchRequest,
        color: Colors.purple,
        onTap: () async {
          await NavigationHelper.pushWithSidebarSync(
            context,
            routeName: '/missingpunch/new',
            page: RequestMissingpunchingPage(),
          );
        },
      ),
      if (showAdvance)
        _QuickAccessItem(
          icon: Icons.account_balance_wallet_outlined,
          label: AppLocalizations.of(context)!.advanceOnSalaryRequest,
          color: Colors.teal,
          onTap: () async {
            await NavigationHelper.pushWithSidebarSync(context, routeName: '/advance/new', page: AdvanceOnSalaryPage());
          },
        ),
      if (showDisciplinary)
        _QuickAccessItem(
          icon: Icons.gavel_outlined,
          label: AppLocalizations.of(context)!.disciplinaryActionRequest,
          color: Colors.red,
          onTap: () async {
            await NavigationHelper.pushWithSidebarSync(
              context,
              routeName: '/disciplinary/new',
              page: DisciplinaryActionPage(),
            );
          },
        ),
      _QuickAccessItem(
        icon: Icons.article_outlined,
        label: AppLocalizations.of(context)!.hrLetterRequest,
        color: Colors.indigo,
        onTap: () async {
          await NavigationHelper.pushWithSidebarSync(context, routeName: '/hr-letter/new', page: HrLetterPage());
        },
      ),
    ];

    return SizedBox(
      width: context.screenWidth > 600 ? 296 : 248,
      child: Column(
        crossAxisAlignment: context.screenWidth > 345 ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          // Initial visible items
          Wrap(
            spacing: context.screenWidth > 600 ? 16 : 8,
            runSpacing: context.screenWidth > 600 ? 16 : 8,
            children: quickAccessItems,
          ),
          // Expandable items
          if (isExpanded) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.topLeft,
              child: Wrap(
                spacing: context.screenWidth > 600 ? 16 : 8,
                runSpacing: context.screenWidth > 600 ? 16 : 8,
                children: expandableItems,
              ),
            ),
          ],
          // Expand/Collapse button
          if (expandableItems.isNotEmpty && context.screenWidth < 700 && showLessMoreButton) ...[
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: onToggleExpanded,
                icon: Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                label: Text(
                  isExpanded ? AppLocalizations.of(context)!.showLess : AppLocalizations.of(context)!.showMore,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAccessItem({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.screenWidth > 600 ? 140 : 120,
      height: context.screenWidth > 600 ? 140 : 120,
      child: Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: color, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(context.screenWidth > 600 ? 16.0 : 8.0),
            child: Column(
              mainAxisAlignment: context.screenWidth > 600 ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(icon, size: context.screenWidth > 600 ? 48 : 28, color: color),
                SizedBox(height: context.screenWidth > 600 ? 12 : 12),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoUpdatesWidget extends StatelessWidget {
  const _NoUpdatesWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, color: Colors.grey[500], size: 48),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noNewUpdates,
            style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ExpandableSummaryContainer extends StatelessWidget {
  final String title;
  final int totalCount;
  final Color themeColor;
  final IconData icon;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;

  const _ExpandableSummaryContainer({
    super.key,
    required this.title,
    required this.totalCount,
    required this.themeColor,
    required this.icon,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Clickable header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onToggle,
              borderRadius:
                  isExpanded ? const BorderRadius.vertical(top: Radius.circular(12)) : BorderRadius.circular(12),
              child: Padding(
                padding: EdgeInsets.all(context.screenWidth > 600 ? 16 : 12),
                child: Row(
                  children: [
                    Icon(icon, color: themeColor, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: themeColor, borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        totalCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down, color: themeColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Expandable content
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: child,
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
