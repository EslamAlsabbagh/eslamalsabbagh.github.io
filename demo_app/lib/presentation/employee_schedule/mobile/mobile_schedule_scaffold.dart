import 'dart:async';

import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/tutorial/gif_help_dialog.dart';
import 'package:hrms_demo/core/tutorial/tutorial_keys.dart';
import 'package:hrms_demo/core/tutorial/tutorial_steps.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_event.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_tokens.dart';
import 'package:hrms_demo/presentation/widgets/collapsible_sidebar.dart';
import 'package:hrms_demo/presentation/widgets/sidebar_cubit.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/views/live_now_mobile_view.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/views/monthly_mobile_view.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/views/my_schedule_mobile_view.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/sheets/filters_sheet.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/views/more_mobile_view.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/views/swaps_mobile_view.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/views/weekly_mobile_view.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Root mobile scaffold for the schedule feature.
/// Shown when viewport width < 600 dp.
///
/// Tabs 0–4 map 1:1 to [ScheduleView] and sync bidirectionally with
/// [ScheduleBloc]. Tab 5 (Swaps) is mobile-only and does not change
/// [ScheduleView].
class MobileScheduleScaffold extends StatefulWidget {
  final bool isManager;
  const MobileScheduleScaffold({super.key, this.isManager = true});

  @override
  State<MobileScheduleScaffold> createState() => _MobileScheduleScaffoldState();
}

class _MobileScheduleScaffoldState extends State<MobileScheduleScaffold> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  // Index 5 = Swaps (mobile-only, no ScheduleView mapping)
  static const _viewTabs = [ScheduleView.week, ScheduleView.month, ScheduleView.live, ScheduleView.self];

  bool _programmaticChange = false;
  Timer? _transitionTimer;
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: widget.isManager ? 6 : 5, vsync: this);
    _tabs.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabs.indexIsChanging) return;
    if (_programmaticChange) {
      _programmaticChange = false;
      return;
    }
    final bloc = context.read<ScheduleBloc>();
    if (bloc.state.publishState == PublishState.publishing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.schedulePublishingPleaseWait),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      _programmaticChange = true;
      final safeIdx = _viewTabs.indexOf(bloc.state.view);
      if (safeIdx >= 0) _tabs.animateTo(safeIdx);
      return;
    }
    final idx = _tabs.index;
    if (idx < _viewTabs.length) {
      final view = _viewTabs[idx];
      _transitionTimer?.cancel();
      context.read<ScheduleBloc>().add(ChangeView(view));
      _transitionTimer = Timer(const Duration(milliseconds: 300), () {
        // no-op: mobile views don't use a transitioning skeleton
      });
    }
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Tab-sync listener (existing).
        BlocListener<ScheduleBloc, ScheduleState>(
          listenWhen: (prev, curr) => prev.view != curr.view,
          listener: (context, state) {
            final idx = _viewTabs.indexOf(state.view);
            if (idx != -1 && _tabs.index != idx) {
              _programmaticChange = true;
              _tabs.animateTo(idx);
            }
          },
        ),
        // Redirect away from More tab when switching to colleagues mode.
        // NOTE: this used to test `index == 6`, which can never be true (the
        // controller has 6 tabs, so the max index is 5) — the redirect never
        // fired and a manager on More was stranded on the "not available"
        // placeholder. More is index 5.
        BlocListener<ScheduleBloc, ScheduleState>(
          listenWhen:
              (prev, curr) =>
                  prev.viewMode != curr.viewMode &&
                  curr.viewMode == ScheduleViewMode.colleagues &&
                  _tabs.index == MobileTabs.more,
          listener: (context, state) {
            _programmaticChange = true;
            _tabs.animateTo(0);
          },
        ),
        // Non-blocking mutation-error SnackBar.
        BlocListener<ScheduleBloc, ScheduleState>(
          listenWhen:
              (prev, curr) => curr.failure != null && curr.failure != prev.failure && curr.status != Status.failure,
          listener: (context, state) {
            final detail = state.failure?.message;
            // Always echo to the console so DevTools captures the full
            // PostgrestException (code/message/details/hint) even if the
            // snackbar is dismissed before it can be read.
            debugPrint('[ScheduleBloc] mutation failure: $detail');
            final friendly = AppLocalizations.of(context)!.scheduleAnErrorOccurred;
            final text = (kDebugMode && detail != null && detail.isNotEmpty) ? '$friendly\n$detail' : friendly;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(text),
                backgroundColor: Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
                duration: kDebugMode ? const Duration(seconds: 10) : const Duration(seconds: 4),
              ),
            );
          },
        ),
      ],
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: MT.bgPage,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                _MobileHeader(onFilterTap: _openFilters, onHelpTap: _openHelp),
                // ── Tabs ──────────────────────────────────────────────────
                _buildTabBar(l10n),
                // ── Body ──────────────────────────────────────────────────
                Expanded(child: _buildBody(l10n)),
              ],
            ),
            const CollapsibleSidebar(hideWhenCollapsed: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      buildWhen:
          (prev, curr) =>
              prev.swapRequests != curr.swapRequests ||
              prev.incomingSwapRequests != curr.incomingSwapRequests ||
              prev.viewMode != curr.viewMode ||
              prev.allTeam != curr.allTeam,
      builder: (context, state) {
        final swapBadge =
            state.viewMode == ScheduleViewMode.team
                ? state.swapRequests
                    .where((r) => r.status == 'pending' && state.allTeam.any((u) => u.id == r.requesterId))
                    .length
                : state.incomingSwapRequests.length;
        return Container(
          key: TutorialKeys.schMobileTabs,
          color: MT.bgCard,
          child: TabBar(
            controller: _tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: MT.brand,
            unselectedLabelColor: MT.text3,
            indicatorColor: MT.brand,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            tabs: [
              Tab(text: l10n.scheduleTabWeekly),
              Tab(text: l10n.scheduleTabMonthly),
              Tab(text: l10n.scheduleTabOnShiftNow),
              Tab(text: l10n.scheduleTabMySchedule),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.scheduleTabSwaps),
                    if (swapBadge > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(color: MT.brand, borderRadius: BorderRadius.circular(10)),
                        child: Text(
                          '$swapBadge',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.isManager)
                Tab(
                  child: Text(
                    l10n.mobileMoreTab,
                    style: TextStyle(
                      color: state.viewMode == ScheduleViewMode.colleagues ? MT.text3.withValues(alpha: 0.35) : null,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      buildWhen: (prev, curr) => prev.viewMode != curr.viewMode,
      builder: (context, state) {
        return TabBarView(
          controller: _tabs,
          children: [
            WeeklyMobileView(selectedDay: _selectedDay, onDaySelected: (d) => setState(() => _selectedDay = d)),
            const MonthlyMobileView(),
            const LiveNowMobileView(),
            const MyScheduleMobileView(),
            const SwapsMobileView(),
            if (widget.isManager)
              state.viewMode == ScheduleViewMode.colleagues
                  ? Center(
                    child: Text(
                      l10n.scheduleNotAvailableInColleaguesMode,
                      style: const TextStyle(color: MT.text3, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  )
                  : const MoreMobileView(),
          ],
        );
      },
    );
  }

  void _openFilters() => showFiltersSheet(context);

  void _openHelp() => showScheduleHelpMenu(
    context,
    mobile: true,
    isSelfOnly: context.read<ScheduleBloc>().state.isSelfOnly,
    onStartTour: (mode) => _startMobileTour(context, tourMode: mode),
  );

  /// Mobile spotlight tour for a given [tourMode]: the header, the Weekly tab,
  /// then the Swaps and More tabs — the tour drives the TabController itself so
  /// those bodies exist when their steps are focused.
  void _startMobileTour(BuildContext ctx, {HelpTourMode tourMode = HelpTourMode.current}) {
    final l10n = AppLocalizations.of(ctx)!;
    final bloc = ctx.read<ScheduleBloc>();
    if (bloc.state.publishState == PublishState.publishing) return;
    // Start on Weekly so the first batch of targets is mounted.
    if (_tabs.index != MobileTabs.weekly) _tabs.animateTo(MobileTabs.weekly);

    final ScheduleViewMode targetMode = switch (tourMode) {
      HelpTourMode.team => ScheduleViewMode.team,
      HelpTourMode.colleagues => ScheduleViewMode.colleagues,
      HelpTourMode.current => bloc.state.viewMode,
    };
    if (!bloc.state.isSelfOnly && bloc.state.viewMode != targetMode) {
      bloc.add(ChangeViewMode(targetMode));
    }
    final colleagues = bloc.state.isSelfOnly || targetMode == ScheduleViewMode.colleagues;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!ctx.mounted) return;
      final plan = buildMobileScheduleSteps(l10n, ctx, colleagues: colleagues, isManager: widget.isManager);
      // Mount filter, tab-aware: a step whose tab isn't open yet is NOT dropped —
      // beforeFocus will switch to that tab and mount it. Only steps for the tab
      // we're already on (or header steps) are checked for a live context.
      final steps =
          plan.targets.where((s) {
            if (s.keyTarget == null) return true;
            final tab = plan.tabByStepId[s.identify.toString()];
            if (tab != null && tab != _tabs.index) return true;
            return s.keyTarget!.currentContext != null;
          }).toList();
      if (steps.isEmpty) return;
      TutorialCoachMark(
        targets: steps,
        colorShadow: Colors.black87,
        paddingFocus: 4,
        opacityShadow: 0.8,
        hideSkip: true,
        beforeFocus: (target) async {
          final tab = plan.tabByStepId[target.identify.toString()];
          if (tab == null || _tabs.index == tab) return;
          // Safe without touching _programmaticChange: _onTabChanged only
          // dispatches ChangeView for indices < _viewTabs.length (4), so moving
          // to Swaps (4) / More (5) is inert.
          _tabs.animateTo(tab);
          // Tab animation (~300ms) + build + layout of the new tab body.
          await Future.delayed(const Duration(milliseconds: 450));
        },
      ).show(context: ctx, rootOverlay: true);
    });
  }
}

// ── Header ─────────────────────────────────────────────────────────────────

class _MobileHeader extends StatelessWidget {
  final VoidCallback onFilterTap;
  final VoidCallback onHelpTap;

  const _MobileHeader({required this.onFilterTap, required this.onHelpTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      buildWhen:
          (prev, curr) =>
              prev.publishState != curr.publishState ||
              prev.schedule != curr.schedule ||
              prev.viewMode != curr.viewMode ||
              prev.view != curr.view,
      builder: (context, state) {
        final filteredIds = state.filteredTeam.map((e) => e.id).whereType<int>().toSet();
        final filteredShifts =
            state.schedule.values.where((s) => !s.isLeave && filteredIds.contains(s.employeeId)).toList();
        final isPublished = filteredShifts.isNotEmpty && filteredShifts.every((s) => s.isPublished);
        final isDraft = filteredShifts.any((s) => !s.isPublished);

        return Container(
          color: MT.bgCard,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Pinned — always visible for navigation
                  GestureDetector(
                    onTap: () => context.read<SidebarCubit>().toggle(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: MT.hair2, borderRadius: MT.br12),
                      child: const Icon(Icons.menu, size: 18, color: MT.text2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Scrollable — title + status pill + filter chip
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Text(
                            l10n.schedulePageTitle,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: MT.brand),
                          ),
                          const SizedBox(width: 8),
                          if (state.viewMode != ScheduleViewMode.colleagues) ...[
                            if (isPublished)
                              _StatusPill(
                                label: l10n.scheduleStatusPublished,
                                color: const Color(0xFF43A047),
                                bg: const Color(0xFFE8F5E9),
                              )
                            else if (isDraft)
                              _StatusPill(
                                label: l10n.scheduleStatusDraft,
                                color: const Color(0xFFF59E0B),
                                bg: const Color(0xFFFEF3C7),
                              ),
                          ],
                          const SizedBox(width: 12),
                          // Filter chip — hidden in colleagues mode
                          if (state.viewMode != ScheduleViewMode.colleagues)
                            GestureDetector(
                              key: TutorialKeys.schMobileFilters,
                              onTap: onFilterTap,
                              child: BlocBuilder<ScheduleBloc, ScheduleState>(
                                buildWhen: (prev, curr) => prev.filters != curr.filters,
                                builder: (context, state) {
                                  final hasFilter =
                                      state.filters.department != null ||
                                      state.filters.location != null ||
                                      state.filters.teamScope != TeamScope.direct;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: hasFilter ? MT.brandBg : MT.hair2,
                                      borderRadius: MT.br24,
                                      border: Border.all(color: hasFilter ? MT.brand.withValues(alpha: 0.4) : MT.hair),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.tune_rounded, size: 14, color: hasFilter ? MT.brand : MT.text3),
                                        const SizedBox(width: 4),
                                        Text(
                                          hasFilter ? _filterLabel(context, state.filters, l10n) : l10n.mobileAllTeams,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: hasFilter ? MT.brand : MT.text3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Help entry point — opens the schedule help centre.
                  GestureDetector(
                    onTap: onHelpTap,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(color: MT.hair2, borderRadius: MT.br12),
                      child: const Icon(Icons.help_outline, size: 18, color: MT.text2),
                    ),
                  ),
                ],
              ),
              if (!state.isSelfOnly) ...[
                const SizedBox(height: 8),
                SegmentedButton<ScheduleViewMode>(
                  key: TutorialKeys.schMobileViewMode,
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: MT.brandBg,
                    selectedForegroundColor: MT.brand,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(borderRadius: MT.br8),
                    side: BorderSide(color: MT.hair, width: 1),
                  ),
                  segments: [
                    ButtonSegment(
                      value: ScheduleViewMode.team,
                      label: Text(l10n.scheduleTeamView),
                      icon: const Icon(Icons.groups_outlined),
                    ),
                    ButtonSegment(
                      value: ScheduleViewMode.colleagues,
                      label: Text(l10n.scheduleColleaguesView),
                      icon: const Icon(Icons.people_outline),
                    ),
                  ],
                  selected: {state.viewMode},
                  onSelectionChanged: (s) {
                    if (context.read<ScheduleBloc>().state.publishState == PublishState.publishing) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.schedulePublishingPleaseWait),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                    context.read<ScheduleBloc>().add(ChangeViewMode(s.first));
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _filterLabel(BuildContext context, ScheduleFilters f, AppLocalizations l10n) {
    final parts = <String>[];
    if (f.department != null) parts.add(f.department!);
    if (f.location != null) parts.add(f.location!);
    if (f.teamScope == TeamScope.all) parts.add(l10n.mobileTeamScopeAll);
    if (f.teamScope == TeamScope.indirect) parts.add(l10n.mobileTeamScopeIndirect);
    return parts.isEmpty ? l10n.mobileFilters : parts.join(' · ');
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _StatusPill({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}
