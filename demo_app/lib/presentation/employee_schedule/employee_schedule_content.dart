import 'dart:async';

import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/tutorial/gif_help_dialog.dart';
import 'package:hrms_demo/core/tutorial/tutorial_keys.dart';
import 'package:hrms_demo/core/tutorial/tutorial_steps.dart';
import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_event.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_tokens.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/daily_timeline_view.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/live_board_view.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/monthly_calendar_view.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_constants.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_kpi_strip.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_legend.dart';
import 'package:hrms_demo/presentation/employee_schedule/employee_schedule_page.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_side_panel.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/schedule_toolbar.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/self_view.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/presentation/employee_schedule/mobile/mobile_schedule_scaffold.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/shift_modal.dart';
import 'package:hrms_demo/presentation/employee_schedule/widgets/week_grid_view.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class EmployeeScheduleContent extends StatefulWidget {
  final ScheduleHighlight? highlight;

  const EmployeeScheduleContent({super.key, this.highlight});

  @override
  State<EmployeeScheduleContent> createState() => _EmployeeScheduleContentState();
}

class _EmployeeScheduleContentState extends State<EmployeeScheduleContent> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  ScheduleView? _transitioningToView;
  Timer? _transitionTimer;
  bool _programmaticTabChange = false;
  bool _highlightTriggered = false;
  bool _triggerHighlight = false;

  ScheduleView get _highlightTargetView =>
      widget.highlight == ScheduleHighlight.selfSwapRows ? ScheduleView.self : ScheduleView.week;

  static const _tabViews = [ScheduleView.week, ScheduleView.day, ScheduleView.month, ScheduleView.self];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        if (_programmaticTabChange) {
          _programmaticTabChange = false;
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
          _programmaticTabChange = true;
          final safeIdx = _tabViews.indexOf(bloc.state.view);
          if (safeIdx >= 0) _tabs.animateTo(safeIdx);
          return;
        }
        final newView = _tabViews[_tabs.index];
        _transitionTimer?.cancel();
        setState(() => _transitioningToView = newView);
        context.read<ScheduleBloc>().add(ChangeView(newView));
        _transitionTimer = Timer(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _transitioningToView = null);
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<UserBloc>().state.user;
      if (user?.id != null) {
        context.read<ScheduleBloc>().add(LoadSchedule(managerId: user!.id!, weekStart: SC.weekStartOf(DateTime.now())));
      }
      if (widget.highlight == ScheduleHighlight.selfSwapRows) {
        context.read<ScheduleBloc>().add(const ChangeView(ScheduleView.self));
      }
    });
  }

  @override
  void dispose() {
    _transitionTimer?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScheduleBloc, ScheduleState>(
      listenWhen: (prev, curr) => prev.view != curr.view,
      listener: (context, state) {
        final idx = _tabViews.indexOf(state.view);
        if (idx != -1 && _tabs.index != idx) {
          _programmaticTabChange = true;
          _tabs.animateTo(idx);
        }
      },
      builder: (context, state) {
        final user = context.read<UserBloc>().state.user;
        final isWeek = state.view == ScheduleView.week;

        // Trigger the flash-border highlight once the target view has loaded.
        if (!_highlightTriggered &&
            widget.highlight != null &&
            state.status == Status.success &&
            state.view == _highlightTargetView) {
          _highlightTriggered = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) setState(() => _triggerHighlight = true);
            });
          });
        }

        final l10n = AppLocalizations.of(context)!;

        if ((state.status == Status.loading || state.status == Status.initial) && state.allTeam.isEmpty) {
          return Scaffold(
            backgroundColor: SC.bgPage,
            body: MainLayout(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.scheduleLoading,
                      style: const TextStyle(fontSize: 18, color: SC.muted, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
            ),
          );
        }

        if (state.status == Status.failure) {
          return Scaffold(
            backgroundColor: SC.bgPage,
            body: MainLayout(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off_outlined, size: 52, color: SC.muted),
                    const SizedBox(height: 16),
                    Text(
                      l10n.scheduleUnableToLoad,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: SC.ink),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.scheduleCheckConnection, style: const TextStyle(fontSize: 13, color: SC.muted)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SC.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: () {
                        if (user?.id != null) {
                          context.read<ScheduleBloc>().add(
                            LoadSchedule(managerId: user!.id!, weekStart: SC.weekStartOf(DateTime.now())),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 16),
                      label: Text(
                        l10n.scheduleRetry,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, outerConstraints) {
            if (outerConstraints.maxWidth < 600) {
              return MobileScheduleScaffold(isManager: !state.isSelfOnly);
            }
            if (state.view == ScheduleView.live) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<ScheduleBloc>().add(const ChangeView(ScheduleView.week));
              });
            }
            return _buildDesktopScaffold(context, state, user, isWeek);
          },
        );
      },
    );
  }

  Widget _buildDesktopScaffold(BuildContext context, ScheduleState state, UserModel? user, bool isWeek) {
    return Scaffold(
      backgroundColor: SC.bgPage,
      body: MainLayout(
        // No appBarKey/sidebarStripKey here: those TutorialKeys belong to the
        // Dashboard route (which stays mounted), and reusing a GlobalKey on two
        // live routes throws. The schedule tour has no top-bar/sidebar steps.
        extraActions: [
          Builder(
            builder:
                (ctx) => IconButton(
                  icon: const Icon(Icons.help_outline, color: Colors.white),
                  tooltip: AppLocalizations.of(ctx)!.tutHelpTooltip,
                  onPressed:
                      () => showScheduleHelpMenu(
                        ctx,
                        // This scaffold only builds at >=600dp, so it is always desktop.
                        mobile: false,
                        isSelfOnly: ctx.read<ScheduleBloc>().state.isSelfOnly,
                        onStartTour: (mode) => _startScheduleTour(ctx, tourMode: mode),
                      ),
                ),
          ),
        ],
        child: LayoutBuilder(
          builder: (context, constraints) {
            final effectiveWidth = constraints.maxWidth < 1000 ? 1000.0 : constraints.maxWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: effectiveWidth,
                child: SingleChildScrollView(
                  primary: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Page header ─────────────────────────────────────
                            _PageHeader(state: state),
                            // ── View tabs ────────────────────────────────────────
                            _ViewTabs(controller: _tabs),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // ── Toolbar (week/day/month views only) ──────────────
                      if (state.view != ScheduleView.live && state.view != ScheduleView.self)
                        Padding(
                          key: TutorialKeys.schToolbar,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: ScheduleToolbar(
                            onCopyLastWeek: () => _confirmCopyLastWeek(context, state),
                            onPublish: () => _confirmPublish(context, state),
                            onNewShift: state.isPastWeek ? null : () => showShiftModal(context, keys: []),
                            hideManagerActions: state.viewMode == ScheduleViewMode.colleagues,
                          ),
                        ),
                      // ── KPI strip (week view only) ────────────────────────
                      if (state.view == ScheduleView.week && state.status == Status.success)
                        Padding(
                          key: TutorialKeys.schKpi,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: ScheduleKpiStrip(state: state),
                        ),
                      // ── Legend (week view only) ───────────────────────────
                      if (state.view == ScheduleView.week && state.status == Status.success)
                        Padding(
                          key: TutorialKeys.schLegend,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: ScheduleLegend(state: state),
                        ),
                      // ── Main body ────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                        child: _buildBody(context, state, user?.id, isWeek, _transitioningToView),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmCopyLastWeek(BuildContext context, ScheduleState state) async {
    final bloc = context.read<ScheduleBloc>();
    // Distinct employees actually being copied (not the whole team size).
    int employeeCount;
    try {
      employeeCount = await bloc.lastWeekCopyEmployeeCount();
    } catch (_) {
      // Fall back to the targeted-row estimate if the count query fails.
      employeeCount = state.viewMode == ScheduleViewMode.colleagues ? 1 : state.filteredTeam.length + 1;
    }
    if (!context.mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _CopyLastWeekDialog(state: state, employeeCount: employeeCount),
    );
    if (confirmed == true && context.mounted) {
      bloc.add(const CopyLastWeek());
    }
  }

  Future<void> _confirmPublish(BuildContext context, ScheduleState state) async {
    final confirmed = await showDialog<bool>(context: context, builder: (_) => _PublishDialog(state: state));
    if (confirmed == true && context.mounted) {
      context.read<ScheduleBloc>().add(const PublishWeek());
    }
  }

  /// Launches the desktop spotlight tour for a given [tourMode]. Ensures Week
  /// view first (KPI strip, legend and grid only exist there). Unlike before it
  /// does NOT force Team — it runs the current mode, or the mode explicitly
  /// chosen from the help centre (Team / Colleagues).
  void _startScheduleTour(BuildContext ctx, {HelpTourMode tourMode = HelpTourMode.current}) {
    final l10n = AppLocalizations.of(ctx)!;
    final bloc = ctx.read<ScheduleBloc>();
    if (bloc.state.publishState == PublishState.publishing) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(l10n.schedulePublishingPleaseWait),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    if (bloc.state.view != ScheduleView.week) bloc.add(const ChangeView(ScheduleView.week));

    // Resolve the effective mode: an explicit choice switches modes first;
    // otherwise keep the mode the user is already in. Self-only users have no
    // Team mode, so they're always treated as colleagues.
    final ScheduleViewMode targetMode = switch (tourMode) {
      HelpTourMode.team => ScheduleViewMode.team,
      HelpTourMode.colleagues => ScheduleViewMode.colleagues,
      HelpTourMode.current => bloc.state.viewMode,
    };
    if (!bloc.state.isSelfOnly && bloc.state.viewMode != targetMode) {
      bloc.add(ChangeViewMode(targetMode));
    }
    final colleagues = bloc.state.isSelfOnly || targetMode == ScheduleViewMode.colleagues;

    // Wait for the view/mode switch + layout so target render boxes exist.
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!ctx.mounted) return;
      // Drop steps whose target isn't in the tree (past week hides some actions,
      // self-only users have no toggle) — same guard as the dashboard tour.
      final steps =
          buildScheduleSteps(l10n, ctx, colleagues: colleagues).where((s) {
            if (s.keyTarget == null) return true;
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
          final tctx = target.keyTarget?.currentContext;
          if (tctx == null) return;
          await Scrollable.ensureVisible(
            tctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.3,
          );
        },
      ).show(context: ctx, rootOverlay: true);
    });
  }

  Widget _skeletonFor(ScheduleView view) {
    switch (view) {
      case ScheduleView.week:
        return const _WeekSkeleton();
      case ScheduleView.day:
        return const _DaySkeleton();
      case ScheduleView.month:
        return const _MonthSkeletonFull();
      case ScheduleView.live:
        return const _LiveSkeleton();
      case ScheduleView.self:
        return const _SelfSkeleton();
    }
  }

  Widget _buildBody(BuildContext context, ScheduleState state, int? userId, bool isWeek, [ScheduleView? skeleton]) {
    if (skeleton != null) return _skeletonFor(skeleton);
    if (state.status == Status.loading && state.view != ScheduleView.month) {
      return _skeletonFor(state.view);
    }
    if (state.publishState == PublishState.publishing && state.view == ScheduleView.week) {
      return const _WeekSkeleton();
    }

    if (state.status == Status.failure) {
      return Center(
        child: Text(
          state.failure?.message ?? AppLocalizations.of(context)!.scheduleAnErrorOccurred,
          style: const TextStyle(color: SC.rose),
        ),
      );
    }

    Widget view;
    switch (state.view) {
      case ScheduleView.week:
        view = KeyedSubtree(
          key: TutorialKeys.schGrid,
          child: WeekGridView(
            onNewShift: state.isPastWeek ? null : () => showShiftModal(context, keys: []),
            onAssignCell: state.isPastWeek ? null : (key) => showShiftModal(context, keys: [key]),
            onBulkAssign: state.isPastWeek ? null : (keys) => showShiftModal(context, keys: keys),
            onEditShift:
                state.isPastWeek
                    ? null
                    : (shift) {
                      final effectiveShift = shift.isLeave ? state.leaveBackups[shift.key] : shift;
                      showShiftModal(
                        context,
                        keys: [shift.key],
                        existing: effectiveShift,
                        // Own-row edits (pinned self row / colleagues self row) aren't in
                        // allTeam — fall back to selfUser.
                        employee:
                            state.allTeam.where((u) => u.id == shift.employeeId).firstOrNull ??
                            (shift.employeeId == state.managerId ? state.selfUser : null),
                      );
                    },
          ),
        );
      case ScheduleView.day:
        view = DailyTimeline(state: state);
      case ScheduleView.month:
        view = MonthlyCalendarView(state: state);
      case ScheduleView.live:
        view = LiveBoardView(state: state);
      case ScheduleView.self:
        view = SelfView(state: state, currentUserId: userId ?? 0);
    }

    if (isWeek) {
      if (state.viewMode == ScheduleViewMode.colleagues) return view;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: view),
          KeyedSubtree(
            key: TutorialKeys.schSidePanel,
            child: ScheduleSidePanel(
              highlightSwaps: _triggerHighlight && widget.highlight == ScheduleHighlight.managerSwapPanel,
            ),
          ),
        ],
      );
    }

    return view;
  }
}

// ── Page header ───────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  final ScheduleState state;
  const _PageHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final filteredIds = state.filteredTeam.map((e) => e.id).whereType<int>().toSet();
    final filteredShifts =
        state.schedule.values.where((s) => !s.isLeave && filteredIds.contains(s.employeeId)).toList();
    final isPublished = filteredShifts.isNotEmpty && filteredShifts.every((s) => s.isPublished);
    final isDraft = filteredShifts.any((s) => !s.isPublished);

    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Segment centered on full row width
          if (!state.isSelfOnly)
            SegmentedButton<ScheduleViewMode>(
              key: TutorialKeys.schViewMode,
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
          // Title + pill pinned to the left
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.schedulePageTitle,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: SC.blue),
                ),
                const SizedBox(width: 10),
                _StatusPill(isPublished: isPublished, isDraft: isDraft),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isPublished;
  final bool isDraft;

  const _StatusPill({required this.isPublished, required this.isDraft});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (isPublished) {
      return _Pill(label: l10n.scheduleStatusPublished, color: SC.green, bg: SC.green50);
    }
    if (isDraft) {
      return _Pill(label: l10n.scheduleStatusDraft, color: SC.amber, bg: SC.amber50);
    }
    return const SizedBox.shrink();
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const _Pill({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

// ── View tabs ─────────────────────────────────────────────────────────────

class _ViewTabs extends StatelessWidget {
  final TabController controller;
  const _ViewTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: TutorialKeys.schTabs,
      color: Colors.white,
      child: TabBar(
        controller: controller,
        isScrollable: false,
        labelColor: SC.blue,
        tabAlignment: TabAlignment.fill,
        unselectedLabelColor: SC.muted,
        indicatorColor: SC.blue,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13),

        tabs: [
          Tab(text: AppLocalizations.of(context)!.scheduleTabWeekly),
          Tab(text: AppLocalizations.of(context)!.scheduleTabDaily),
          Tab(text: AppLocalizations.of(context)!.scheduleTabMonthly),
          Tab(text: AppLocalizations.of(context)!.scheduleTabMySchedule),
        ],
      ),
    );
  }
}

// ── Confirmation dialogs ───────────────────────────────────────────────────

class _CopyLastWeekDialog extends StatelessWidget {
  final ScheduleState state;
  // Distinct employees actually being copied (resolved by the caller), not the
  // whole team size.
  final int employeeCount;
  const _CopyLastWeekDialog({required this.state, required this.employeeCount});

  @override
  Widget build(BuildContext context) {
    final lastWeekMonday = DateTime(state.weekStart.year, state.weekStart.month, state.weekStart.day - 7);
    // Colleagues mode copies MY OWN row only; team mode copies the filtered
    // team PLUS my own pinned row, so the shift count includes my own row in
    // team mode.
    final selfMode = state.viewMode == ScheduleViewMode.colleagues;
    // Count my own shifts only when they can actually be copied (room to paste).
    final selfShifts = state.canSelfCopyLastWeek ? state.selfLastWeekShiftCount : 0;
    final shiftCount = selfMode ? selfShifts : state.lastWeekShiftCount + selfShifts;

    final l10n = AppLocalizations.of(context)!;
    return _ConfirmDialog(
      icon: Icons.copy_outlined,
      iconColor: SC.blue,
      title: l10n.scheduleCopyDialogTitle,
      rows: [
        _DialogRow(label: l10n.scheduleCopyFrom, value: SC.localizedWeekLabel(l10n, lastWeekMonday)),
        _DialogRow(label: l10n.scheduleCopyTo, value: SC.localizedWeekLabel(l10n, state.weekStart)),
        _DialogRow(label: l10n.scheduleCopyShiftsToCopy, value: '$shiftCount'),
        _DialogRow(label: l10n.scheduleCopyEmployeesToCopy, value: l10n.scheduleCopyEmployees(employeeCount)),
      ],
      note: l10n.scheduleCopyNote,
      confirmLabel: l10n.scheduleCopyButton,
      confirmColor: SC.blue,
    );
  }
}

class _PublishDialog extends StatelessWidget {
  final ScheduleState state;
  const _PublishDialog({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredIds = state.filteredTeam.map((e) => e.id).whereType<int>().toSet();
    final entries = state.schedule.values.where((s) => filteredIds.contains(s.employeeId)).toList();

    // Real shifts only — off types and leave-only days excluded. A shift on a day with an
    // approved leave overlay stays here (it's still a real shift record being published).
    final shiftCount = entries.where((s) => !s.isLeave && !s.isOffType).length;

    // Draft / affected counts keep their existing basis: all publishable (non-leave-only) entries.
    final publishable = entries.where((s) => !s.isLeave);
    final draftShifts = publishable.where((s) => !s.isPublished).length;
    final employeesAffected = publishable.where((s) => !s.isPublished).map((s) => s.employeeId).toSet().length;

    // All approved-leave days for the team (leave-only + leave-overlaid) — counted in both
    // the Shifts row (for overlays) and here.
    final leaves = state.leaveKeys.keys.where((k) => filteredIds.contains(int.parse(k.split('-').first))).length;

    final rows = <_DialogRow>[_DialogRow(label: l10n.schedulePublishTotalShifts, value: '$shiftCount')];
    void addOff(String note, String label) {
      final count = entries.where((s) => s.note == note).length;
      if (count > 0) rows.add(_DialogRow(label: label, value: '$count'));
    }

    addOff(ScheduleModel.kNoteOff, l10n.scheduleOffTypeDayOff);
    addOff(ScheduleModel.kNotePlannedLeave, l10n.scheduleOffTypePlannedLeave);
    addOff(ScheduleModel.kNoteUnplannedLeave, l10n.scheduleOffTypeUnplannedLeave);
    addOff(ScheduleModel.kNoteHoliday, l10n.scheduleOffTypeHoliday);
    if (leaves > 0) rows.add(_DialogRow(label: l10n.scheduleLegendLeave, value: '$leaves'));
    rows.addAll([
      _DialogRow(label: l10n.schedulePublishToBePublished, value: '$draftShifts'),
      _DialogRow(label: l10n.schedulePublishEmployeesNotified, value: '$employeesAffected'),
      _DialogRow(label: l10n.schedulePublishWeekLabel, value: SC.localizedWeekLabel(l10n, state.weekStart)),
    ]);

    return _ConfirmDialog(
      icon: Icons.send_outlined,
      iconColor: SC.blue,
      title: l10n.schedulePublishDialogTitle,
      rows: rows,
      note: l10n.schedulePublishNote,
      confirmLabel: l10n.schedulePublishButton,
      confirmColor: SC.blue,
    );
  }
}

// ── Skeleton loading ──────────────────────────────────────────────────────

/// Drives a single pulsing opacity shared by all boxes in one skeleton view.
class _ShimmerProvider extends StatefulWidget {
  final Widget Function(double opacity) builder;
  const _ShimmerProvider({required this.builder});
  @override
  State<_ShimmerProvider> createState() => _ShimmerProviderState();
}

class _ShimmerProviderState extends State<_ShimmerProvider> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.45, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: _opacity, builder: (_, __) => widget.builder(_opacity.value));
}

Widget _sBox(double w, double h, double opacity, {double radius = 6}) => Container(
  width: w,
  height: h,
  decoration: BoxDecoration(
    color: Color(0xFFD1D5DB).withValues(alpha: opacity),
    borderRadius: BorderRadius.circular(radius),
  ),
);

class _WeekSkeleton extends StatelessWidget {
  const _WeekSkeleton();

  // true = show a shift block in that cell, false = empty
  static const _hasCells = [
    [true, true, true, true, true, false, true],
    [true, false, false, true, true, false, true],
    [true, false, true, true, true, true, true],
    [true, true, false, false, true, true, false],
    [true, true, true, true, true, true, true],
  ];

  @override
  Widget build(BuildContext context) => _ShimmerProvider(builder: _build);

  Widget _build(double o) {
    const empColW = 200.0;
    const sidePanelW = 215.0;
    const rowH = 82.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── KPI strip ───────────────────────────────────────────────
        Row(
          children: [
            for (int i = 0; i < 5; i++) ...[
              Expanded(
                child: Container(
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: SC.lineColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _sBox(30, 30, o * 0.6, radius: 8),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _sBox(28, 15, o),
                          const SizedBox(height: 4),
                          _sBox(88, 9, o * 0.65),
                          const SizedBox(height: 3),
                          _sBox(64, 8, o * 0.5),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (i < 4) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 10),
        // ── Legend row ──────────────────────────────────────────────
        Container(
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: SC.lineColor),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              for (int i = 0; i < 5; i++) ...[
                _sBox(28, 9, o * 0.7, radius: 2),
                const SizedBox(width: 5),
                _sBox(65, 9, o * 0.5),
                if (i < 4) const SizedBox(width: 14),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        // ── Main area: grid + side panel ────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day column headers
                  Row(
                    children: [
                      SizedBox(
                        width: empColW,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _sBox(90, 11, o * 0.5),
                        ),
                      ),
                      for (int d = 0; d < 7; d++)
                        Expanded(
                          child: Column(
                            children: [
                              _sBox(26, 9, o * 0.5),
                              const SizedBox(height: 3),
                              _sBox(22, 16, o * 0.85),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const SizedBox(width: 4),
                                  Expanded(child: _sBox(double.infinity, 3, o * 0.7, radius: 2)),
                                  const SizedBox(width: 2),
                                  Expanded(child: _sBox(double.infinity, 3, o * 0.5, radius: 2)),
                                  const SizedBox(width: 4),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Employee rows
                  for (int i = 0; i < _hasCells.length; i++)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Employee info column
                        Container(
                          width: empColW,
                          height: rowH,
                          decoration: BoxDecoration(
                            border: Border(
                              right: BorderSide(color: SC.lineColor, width: 0.5),
                              bottom: BorderSide(color: SC.lineColor, width: 0.5),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sBox(36, 36, o * 0.85, radius: 18),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sBox(100, 11, o),
                                  const SizedBox(height: 4),
                                  _sBox(65, 9, o * 0.5),
                                  const SizedBox(height: 3),
                                  _sBox(55, 9, o * 0.5),
                                  const SizedBox(height: 3),
                                  _sBox(75, 9, o * 0.5),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 7 day cells
                        for (int d = 0; d < 7; d++)
                          Expanded(
                            child: Container(
                              height: rowH,
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: SC.lineColor, width: 0.5),
                                  bottom: BorderSide(color: SC.lineColor, width: 0.5),
                                ),
                              ),
                              padding: const EdgeInsets.all(5),
                              child:
                                  _hasCells[i][d]
                                      ? Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xFFD1D5DB).withValues(alpha: o * 0.8),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _sBox(68, 9, o * 0.95),
                                            const SizedBox(height: 4),
                                            _sBox(44, 8, o * 0.6),
                                          ],
                                        ),
                                      )
                                      : const SizedBox(),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Side panel ─────────────────────────────────────────
            SizedBox(
              width: sidePanelW,
              child: Column(
                children: [
                  for (final label in [90.0, 65.0, 55.0]) ...[
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: SC.lineColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sBox(label, 12, o * 0.85),
                          const SizedBox(height: 10),
                          _sBox(double.infinity, 9, o * 0.45),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DaySkeleton extends StatelessWidget {
  const _DaySkeleton();

  // shift block specs: (startFraction, widthFraction) along the timeline
  static const _shifts = [
    (0.67, 0.22), // row 0 — late shift
    (0.67, 0.22), // row 1
    (0.33, 0.40), // row 2 — mid shift
    (0.67, 0.22), // row 3
    (0.67, 0.22), // row 4
    (0.33, 0.40), // row 5
    (0.33, 0.40), // row 6
    (0.0, 0.0), // row 7 — no shift (empty)
  ];

  @override
  Widget build(BuildContext context) => _ShimmerProvider(builder: _build);

  Widget _build(double o) {
    const empColW = 290.0;
    const rowH = 56.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Day column headers ──────────────────────────────────────
        Row(
          children: [
            const SizedBox(width: empColW),
            for (int d = 0; d < 7; d++) ...[
              Expanded(
                child: Column(
                  children: [
                    _sBox(28, 10, o * 0.5),
                    const SizedBox(height: 4),
                    _sBox(22, 16, o * (d == 1 ? 0.9 : 0.65)),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        // ── Employee count header ───────────────────────────────────
        Container(
          height: 36,
          color: Color(0xFFD1D5DB).withValues(alpha: o * 0.35),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.centerLeft,
          child: _sBox(110, 11, o * 0.5),
        ),
        const SizedBox(height: 1),
        // ── Employee rows ───────────────────────────────────────────
        for (int i = 0; i < _shifts.length; i++) ...[
          Container(
            height: rowH,
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: SC.lineColor, width: 0.5))),
            child: Row(
              children: [
                // Left: avatar + name + dept
                SizedBox(
                  width: empColW,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      children: [
                        _sBox(34, 34, o * 0.7, radius: 17),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [_sBox(130, 11, o * 0.8), const SizedBox(height: 5), _sBox(90, 9, o * 0.5)],
                        ),
                      ],
                    ),
                  ),
                ),
                // Right: timeline with shift block
                Expanded(
                  child: LayoutBuilder(
                    builder: (_, constraints) {
                      final w = constraints.maxWidth;
                      final spec = _shifts[i];
                      if (spec.$2 == 0.0) return const SizedBox();
                      return Stack(
                        children: [
                          Positioned(
                            left: w * spec.$1,
                            width: w * spec.$2,
                            top: 8,
                            height: rowH - 16,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFFD1D5DB).withValues(alpha: o * 0.85),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [_sBox(80, 9, o * 0.7), const SizedBox(height: 4), _sBox(40, 8, o * 0.5)],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MonthSkeletonFull extends StatelessWidget {
  const _MonthSkeletonFull();
  @override
  Widget build(BuildContext context) => _ShimmerProvider(
    builder:
        (o) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _sBox(26, 26, o),
                  const SizedBox(width: 8),
                  _sBox(140, 18, o),
                  const SizedBox(width: 8),
                  _sBox(26, 26, o),
                ],
              ),
            ),
            // Weekday row
            Row(
              children: [
                for (int i = 0; i < 7; i++) ...[Expanded(child: Center(child: _sBox(28, 12, o * 0.5)))],
              ],
            ),
            const SizedBox(height: 6),
            // 5 × 7 grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 7,
              childAspectRatio: 1.1,
              children: List.generate(
                35,
                (i) => Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFD1D5DB).withValues(alpha: i % 7 == 0 || i % 7 == 6 ? o * 0.6 : o * 0.8),
                    border: Border.all(color: SC.lineColor2, width: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
  );
}

class _LiveSkeleton extends StatelessWidget {
  const _LiveSkeleton();

  @override
  Widget build(BuildContext context) => _ShimmerProvider(builder: _build);

  Widget _build(double o) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Status pill row ─────────────────────────────────────────
        Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              Container(
                height: 36,
                width: 130,
                decoration: BoxDecoration(
                  color: Color(0xFFD1D5DB).withValues(alpha: o * 0.7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SC.lineColor),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [_sBox(10, 10, o, radius: 5), const SizedBox(width: 6), _sBox(70, 10, o * 0.8)]),
              ),
              if (i < 3) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // ── Employee card grid (6 columns) ──────────────────────────
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.55,
          ),
          itemCount: 18,
          itemBuilder:
              (_, i) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SC.lineColor),
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + name + dept
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sBox(34, 34, o * 0.9, radius: 17),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [_sBox(double.infinity, 11, o), const SizedBox(height: 4), _sBox(80, 9, o * 0.6)],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Status badge
                    _sBox(58, 20, o * 0.7, radius: 4),
                    const Spacer(),
                    // Shift type + time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [_sBox(52, 9, o * 0.6), _sBox(72, 9, o * 0.6)],
                    ),
                    const SizedBox(height: 6),
                    // Progress bar
                    _sBox(double.infinity, 4, o * 0.8, radius: 2),
                  ],
                ),
              ),
        ),
      ],
    );
  }
}

class _SelfSkeleton extends StatelessWidget {
  const _SelfSkeleton();

  @override
  Widget build(BuildContext context) => _ShimmerProvider(builder: _build);

  Widget _build(double o) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // // ── Left panel ──────────────────────────────────────────────
        // Container(
        //   width: 280,
        //   padding: const EdgeInsets.all(16),
        //   decoration: BoxDecoration(
        //     color: Colors.white,
        //     border: Border.all(color: SC.lineColor),
        //     borderRadius: BorderRadius.circular(10),
        //   ),
        //   child: Column(
        //     children: [
        //       // Avatar
        //       _sBox(72, 72, o, radius: 36),
        //       const SizedBox(height: 12),
        //       // Name
        //       _sBox(160, 14, o),
        //       const SizedBox(height: 6),
        //       // Department
        //       _sBox(110, 11, o * 0.6),
        //       const SizedBox(height: 16),
        //       // Clock In / Clock Out buttons
        //       Row(children: [
        //         Expanded(child: _sBox(double.infinity, 36, o * 0.5)),
        //         const SizedBox(width: 8),
        //         Expanded(child: _sBox(double.infinity, 36, o * 0.5)),
        //       ]),
        //       const SizedBox(height: 16),
        //       // 2×2 stat cards
        //       for (int row = 0; row < 2; row++) ...[
        //         Row(children: [
        //           Expanded(
        //             child: Container(
        //               height: 64,
        //               decoration: BoxDecoration(
        //                 color: Color(0xFFD1D5DB).withValues(alpha: o * 0.6),
        //                 borderRadius: BorderRadius.circular(8),
        //                 border: Border.all(color: SC.lineColor),
        //               ),
        //             ),
        //           ),
        //           const SizedBox(width: 8),
        //           Expanded(
        //             child: Container(
        //               height: 64,
        //               decoration: BoxDecoration(
        //                 color: Color(0xFFD1D5DB).withValues(alpha: o * 0.6),
        //                 borderRadius: BorderRadius.circular(8),
        //                 border: Border.all(color: SC.lineColor),
        //               ),
        //             ),
        //           ),
        //         ]),
        //         if (row == 0) const SizedBox(height: 8),
        //       ],
        //       const SizedBox(height: 20),
        //       // Quick Actions header
        //       Align(alignment: Alignment.centerLeft, child: _sBox(110, 12, o * 0.7)),
        //       const SizedBox(height: 10),
        //       // 4 action rows
        //       for (int i = 0; i < 4; i++) ...[
        //         Container(
        //           height: 40,
        //           decoration: BoxDecoration(
        //             color: Color(0xFFD1D5DB).withValues(alpha: o * 0.4),
        //             borderRadius: BorderRadius.circular(6),
        //             border: Border.all(color: SC.lineColor),
        //           ),
        //         ),
        //         const SizedBox(height: 6),
        //       ],
        //     ],
        //   ),
        // ),
        // const SizedBox(width: 16),
        // ── Right panel ─────────────────────────────────────────────
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: SC.lineColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Upcoming shifts" header
                _sBox(200, 14, o * 0.8),
                const SizedBox(height: 16),
                // Day rows
                for (int i = 0; i < 8; i++) ...[
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Color(0xFFD1D5DB).withValues(alpha: i == 0 ? o * 0.35 : o * 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        // Date column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [_sBox(28, 9, o * 0.5), const SizedBox(height: 4), _sBox(18, 13, o * 0.7)],
                        ),
                        const SizedBox(width: 16),
                        // Shift name + time
                        if (i % 4 != 0) ...[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [_sBox(80, 11, o * 0.8), const SizedBox(height: 4), _sBox(90, 9, o * 0.5)],
                          ),
                          const Spacer(),
                          _sBox(100, 28, o * 0.4),
                        ] else ...[
                          _sBox(55, 11, o * 0.4),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Shared dialog shell ────────────────────────────────────────────────────

class _DialogRow {
  final String label;
  final String value;
  const _DialogRow({required this.label, required this.value});
}

class _ConfirmDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<_DialogRow> rows;
  final String note;
  final String confirmLabel;
  final Color confirmColor;

  const _ConfirmDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.rows,
    required this.note,
    required this.confirmLabel,
    required this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: SC.blue50, borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: SC.ink),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: SC.bgPage,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: SC.lineColor),
                ),
                child: Column(
                  children:
                      rows
                          .map(
                            (r) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(r.label, style: const TextStyle(fontSize: 12.5, color: SC.muted)),
                                  Text(
                                    r.value,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: SC.ink),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
              const SizedBox(height: 12),
              Text(note, style: const TextStyle(fontSize: 11.5, color: SC.muted2)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: SC.muted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text(confirmLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
