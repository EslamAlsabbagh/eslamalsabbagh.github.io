import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'gif_help_dialog.dart';
import 'tour_assets.dart';
import 'tutorial_keys.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SINGLE SOURCE OF TRUTH for the guided tour.
//
// To add a step       → add a call to the list below.
// To reorder steps    → move the line.
// To change text      → edit app_en.arb / app_ar.arb.
// To add a new target → add a GlobalKey in tutorial_keys.dart, attach it to the
//                       widget, then add a _step() call here.
// ─────────────────────────────────────────────────────────────────────────────

List<TargetFocus> buildDashboardSteps(AppLocalizations l10n, BuildContext context) {
  final isRtl = Directionality.of(context) == TextDirection.rtl;
  final screenW = MediaQuery.of(context).size.width;
  final screenH = MediaQuery.of(context).size.height;
  const kSidebarW = 65.0;
  const kAppBarH = kToolbarHeight;

  // AppBar: explicit coordinates — bypasses key-based lookup entirely so
  // rootOverlay coordinate-space mismatch on web cannot affect the spotlight.
  final appBarContentPos = CustomTargetContentPosition(top: kAppBarH + 8, left: 0);

  // Sidebar: full-height strip using TargetPosition so the package's
  // edge-overflow math is bypassed entirely. Content is anchored with
  // ContentAlign.custom at the top of the content area beside the sidebar.
  final sidebarRect = Rect.fromLTWH(isRtl ? screenW - kSidebarW : 0, kAppBarH, kSidebarW, screenH - kAppBarH);
  // Safe tooltip position: just below the AppBar, on the content-area side.
  final sidebarContentPos = CustomTargetContentPosition(
    top: kAppBarH + 16,
    left: isRtl ? null : kSidebarW + 16,
    right: isRtl ? kSidebarW + 16 : null,
  );

  return [
    TargetFocus(
      identify: 'topBar',
      // Offset(0, 0.1) not Offset.zero: light_paint_rect.dart line 83 has
      // `if (target.offset == Offset.zero) return;` which skips painting entirely.
      // On Flutter web the AppBar is genuinely at (0,0), so we use a sub-pixel
      // offset that is visually identical but bypasses the guard.
      targetPosition: TargetPosition(Size(screenW, kAppBarH), const Offset(0, 0.1)),
      shape: ShapeLightFocus.RRect,
      radius: 0,
      contents: [
        TargetContent(
          align: ContentAlign.custom,
          customPosition: appBarContentPos,
          padding: EdgeInsets.zero,
          builder:
              (ctx, ctrl) => _card(
                l10n: l10n,
                title: l10n.tutTopBarTitle,
                body: l10n.tutTopBarBody,
                controller: ctrl,
                maxWidth: (screenW - 32).clamp(200.0, 320.0),
              ),
        ),
      ],
    ),
    // Sidebar uses explicit TargetPosition + custom content placement
    TargetFocus(
      identify: 'sidebar',
      targetPosition: TargetPosition(sidebarRect.size, sidebarRect.topLeft),
      shape: ShapeLightFocus.RRect,
      radius: 0,
      contents: [
        TargetContent(
          align: ContentAlign.custom,
          customPosition: sidebarContentPos,
          padding: EdgeInsets.zero,
          builder:
              (ctx, ctrl) => _card(
                l10n: l10n,
                title: l10n.tutSidebarTitle,
                body: l10n.tutSidebarBody,
                controller: ctrl,
                maxWidth: (screenW - kSidebarW - 48).clamp(200.0, 320.0),
              ),
        ),
      ],
    ),
    _step(
      id: 'pending',
      key: TutorialKeys.pendingCard,
      title: l10n.tutPendingTitle,
      body: l10n.tutPendingBody,
      context: context,
    ),
    _step(
      id: 'processing',
      key: TutorialKeys.processingCard,
      title: l10n.tutProcessingTitle,
      body: l10n.tutProcessingBody,
      context: context,
    ),
    _step(
      id: 'recent',
      key: TutorialKeys.recentCard,
      title: l10n.tutRecentTitle,
      body: l10n.tutRecentBody,
      context: context,
    ),
    _step(
      id: 'quickActions',
      key: TutorialKeys.quickActions,
      title: l10n.tutQuickActionsTitle,
      body: l10n.tutQuickActionsBody,
      context: context,
    ),
    _step(
      id: 'leaveBtn',
      key: TutorialKeys.leaveButton,
      title: l10n.tutLeaveButtonTitle,
      body: l10n.tutLeaveButtonBody,
      context: context,
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Request Leave page tour.
//
// Same describe-only pattern as the dashboard: each step spotlights a (closed)
// control and explains it in the card. The leave-type step intentionally carries
// a long, scrollable body covering every leave type's use-case and constraints —
// _TutCard's body is already a SingleChildScrollView, so it fits.
// ─────────────────────────────────────────────────────────────────────────────
List<TargetFocus> buildRequestLeaveSteps(AppLocalizations l10n, BuildContext context) {
  return [
    _step(
      id: 'leaveBalances',
      key: TutorialKeys.leaveBalances,
      title: l10n.tutLeaveBalancesTitle,
      body: l10n.tutLeaveBalancesBody,
      context: context,
    ),
    _step(
      id: 'leaveFromDate',
      key: TutorialKeys.leaveFromDate,
      title: l10n.tutLeaveFromDateTitle,
      body: l10n.tutLeaveFromDateBody,
      context: context,
    ),
    _step(
      id: 'leaveToDate',
      key: TutorialKeys.leaveToDate,
      title: l10n.tutLeaveToDateTitle,
      body: l10n.tutLeaveToDateBody,
      context: context,
    ),
    _step(
      id: 'leaveHours',
      key: TutorialKeys.leaveHours,
      title: l10n.tutLeaveHoursTitle,
      body: l10n.tutLeaveHoursBody,
      context: context,
    ),
    _step(
      id: 'leaveDayCount',
      key: TutorialKeys.leaveDayCount,
      title: l10n.tutLeaveDayCountTitle,
      body: l10n.tutLeaveDayCountBody,
      context: context,
    ),
    _step(
      id: 'leaveType',
      key: TutorialKeys.leaveTypeDropdown,
      title: l10n.tutLeaveTypeTitle,
      body: l10n.tutLeaveTypeBody,
      context: context,
    ),
    _step(
      id: 'leaveSubmit',
      key: TutorialKeys.leaveSubmit,
      title: l10n.tutLeaveSubmitTitle,
      body: l10n.tutLeaveSubmitBody,
      context: context,
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Employee Schedule page tour (desktop).
//
// Hybrid model: static sections (view toggle, tabs, KPIs, legend) get a
// spotlight card only. Interaction-heavy sections (filters, copy, publish,
// assign / multi-select / templates, swaps) also carry a `gifAsset` so the card
// shows a "Watch how ▶" button that plays a screen recording.
//
// The launcher (`_startScheduleTour`) ensures Week view first — the KPI strip,
// legend and side panel only exist there — and filters out any step whose target
// isn't currently in the tree (a past week hides some actions), exactly like the
// dashboard tour.
// ─────────────────────────────────────────────────────────────────────────────
List<TargetFocus> buildScheduleSteps(AppLocalizations l10n, BuildContext context, {required bool colleagues}) {
  // Shared head — present in both modes.
  final head = [
    _step(
      id: 'schViewMode',
      key: TutorialKeys.schViewMode,
      title: l10n.tutSchViewModeTitle,
      body: l10n.tutSchViewModeBody,
      context: context,
    ),
    _step(
      id: 'schTabs',
      key: TutorialKeys.schTabs,
      title: l10n.tutSchTabsTitle,
      body: l10n.tutSchTabsBody,
      context: context,
    ),
  ];

  // KPI strip + legend render in both modes, but Colleagues mode hides 3 of the
  // 5 KPI cards (schedule_kpi_strip.dart) and the draft/conflict legend markers
  // (schedule_legend.dart) — so the body text has to differ or it would name
  // things that aren't on screen.
  final overview = [
    _step(
      id: 'schKpi',
      key: TutorialKeys.schKpi,
      title: l10n.tutSchKpiTitle,
      body: colleagues ? l10n.tutSchKpiColleaguesBody : l10n.tutSchKpiBody,
      context: context,
    ),
    _step(
      id: 'schLegend',
      key: TutorialKeys.schLegend,
      title: l10n.tutSchLegendTitle,
      body: colleagues ? l10n.tutSchLegendColleaguesBody : l10n.tutSchLegendBody,
      context: context,
    ),
  ];

  if (colleagues) {
    return [
      ...head,
      // Toolbar in colleagues mode has no filters — just week navigation.
      _step(
        id: 'schWeekNav',
        key: TutorialKeys.schToolbar,
        title: l10n.tutSchWeekNavTitle,
        body: l10n.tutSchWeekNavBody,
        context: context,
      ),
      // Draft-hint chip + self "Copy last week".
      _step(
        id: 'schSelfActions',
        key: TutorialKeys.schSelfActions,
        title: l10n.tutSchSelfActionsTitle,
        body: l10n.tutSchSelfActionsBody,
        context: context,
      ),
      ...overview,
      // Grid, colleagues behaviour: draft your own shift, then request a swap.
      _step(
        id: 'schSelfDraft',
        key: TutorialKeys.schGrid,
        title: l10n.tutSchSelfDraftTitle,
        body: l10n.tutSchSelfDraftBody,
        context: context,
        gifAsset: ScheduleTourAssets.selfDraft,
      ),
      _step(
        id: 'schRequestSwap',
        key: TutorialKeys.schGrid,
        title: l10n.tutSchRequestSwapTitle,
        body: l10n.tutSchRequestSwapBody,
        context: context,
        gifAsset: ScheduleTourAssets.requestSwap,
      ),
      // Read-only pinned "Manager" comparison row.
      _step(
        id: 'schPinnedRow',
        key: TutorialKeys.schPinnedRow,
        title: l10n.tutSchPinnedRowTitle,
        body: l10n.tutSchPinnedRowBody,
        context: context,
      ),
    ];
  }

  // Team mode.
  return [
    ...head,
    _step(
      id: 'schToolbar',
      key: TutorialKeys.schToolbar,
      title: l10n.tutSchFiltersTitle,
      body: l10n.tutSchFiltersBody,
      context: context,
      gifAsset: ScheduleTourAssets.filters,
    ),
    _step(
      id: 'schCopy',
      key: TutorialKeys.schCopyLastWeek,
      title: l10n.tutSchCopyTitle,
      body: l10n.tutSchCopyBody,
      context: context,
      gifAsset: ScheduleTourAssets.copyLastWeek,
    ),
    _step(
      id: 'schPublish',
      key: TutorialKeys.schPublish,
      title: l10n.tutSchPublishTitle,
      body: l10n.tutSchPublishBody,
      context: context,
      gifAsset: ScheduleTourAssets.publishWeek,
    ),
    ...overview,
    // Grid: three consecutive steps focus the same area — assign, then
    // multi-select, then templates — each with its own recording.
    _step(
      id: 'schAssign',
      key: TutorialKeys.schGrid,
      title: l10n.tutSchAssignTitle,
      body: l10n.tutSchAssignBody,
      context: context,
      gifAsset: ScheduleTourAssets.assignShift,
    ),
    _step(
      id: 'schMultiSelect',
      key: TutorialKeys.schGrid,
      title: l10n.tutSchMultiSelectTitle,
      body: l10n.tutSchMultiSelectBody,
      context: context,
      gifAsset: ScheduleTourAssets.multiSelect,
    ),
    _step(
      id: 'schTemplate',
      key: TutorialKeys.schGrid,
      title: l10n.tutSchTemplateTitle,
      body: l10n.tutSchTemplateBody,
      context: context,
      gifAsset: ScheduleTourAssets.template,
    ),
    _step(
      id: 'schSidePanel',
      key: TutorialKeys.schSidePanel,
      title: l10n.tutSchSwapTitle,
      body: l10n.tutSchSwapBody,
      context: context,
      gifAsset: ScheduleTourAssets.approveSwap,
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Employee Schedule tour (mobile scaffold).
//
// Mobile is a different UI from desktop — a day list instead of a week grid, a
// filters bottom sheet instead of inline dropdowns, and dedicated Swaps / More
// tabs instead of a side panel and toolbar. So mobile steps use their own
// `tutSchMobile*` strings and their own recordings (`ScheduleTourAssets.mobile*`);
// only the Team/Colleagues toggle copy is genuinely shared with desktop.
//
// Some targets live inside tabs that aren't open yet. `TabBarView` builds only
// the active tab, so those steps carry a tab index and the launcher drives the
// TabController in `beforeFocus` before focusing them. Tab-gated steps must
// therefore be exempt from the launcher's mount filter — see [MobileTourPlan].
// ─────────────────────────────────────────────────────────────────────────────

/// Mobile tab indices (see `_MobileScheduleScaffoldState._viewTabs`).
class MobileTabs {
  MobileTabs._();
  static const weekly = 0;
  static const swaps = 4;
  static const more = 5; // managers only
}

/// A mobile tour: the spotlight targets plus, for each step that lives inside a
/// tab, the tab index that must be open before it can be focused.
///
/// Steps absent from [tabByStepId] are header targets that are always mounted.
class MobileTourPlan {
  final List<TargetFocus> targets;
  final Map<String, int> tabByStepId;

  const MobileTourPlan(this.targets, this.tabByStepId);
}

MobileTourPlan buildMobileScheduleSteps(
  AppLocalizations l10n,
  BuildContext context, {
  required bool colleagues,
  required bool isManager,
}) {
  final targets = <TargetFocus>[];
  final tabOf = <String, int>{};

  void add(TargetFocus step, {int? tab}) {
    targets.add(step);
    if (tab != null) tabOf[step.identify.toString()] = tab;
  }

  // ── Header (always mounted) ───────────────────────────────────────────────
  // Ordered to match the visual layout: the filter chip sits in header row 1,
  // the Team/Colleagues toggle in row 2 — spotlighting them the other way round
  // makes the highlight jump down and then back up.
  if (!colleagues) {
    // The filter chip is hidden in colleagues mode.
    add(_step(
      id: 'schMobileFilters',
      key: TutorialKeys.schMobileFilters,
      title: l10n.tutSchMobileFiltersTitle,
      body: l10n.tutSchMobileFiltersBody,
      context: context,
      gifAsset: ScheduleTourAssets.mobileFilters,
    ));
  }
  add(_step(
    id: 'schMobileViewMode',
    key: TutorialKeys.schMobileViewMode,
    // The segmented toggle is identical on both platforms — shared copy.
    title: l10n.tutSchViewModeTitle,
    body: l10n.tutSchViewModeBody,
    context: context,
  ));
  add(_step(
    id: 'schMobileTabs',
    key: TutorialKeys.schMobileTabs,
    title: l10n.tutSchMobileTabsTitle,
    body: l10n.tutSchMobileTabsBody,
    context: context,
  ));

  // ── Weekly tab ────────────────────────────────────────────────────────────
  add(
    _step(
      id: 'schMobileWeekNav',
      key: TutorialKeys.schMobileWeekNav,
      title: l10n.tutSchMobileWeekNavTitle,
      body: l10n.tutSchMobileWeekNavBody,
      context: context,
    ),
    tab: MobileTabs.weekly,
  );
  add(
    _step(
      id: 'schMobileStats',
      key: TutorialKeys.schMobileStats,
      title: l10n.tutSchMobileStatsTitle,
      body: l10n.tutSchMobileStatsBody,
      context: context,
    ),
    tab: MobileTabs.weekly,
  );
  add(
    _step(
      id: 'schMobileDayPicker',
      key: TutorialKeys.schMobileDayPicker,
      title: l10n.tutSchMobileDayPickerTitle,
      body: l10n.tutSchMobileDayPickerBody,
      context: context,
    ),
    tab: MobileTabs.weekly,
  );

  // Bottom action bar. Team → "Assign shifts…" (bulk sheet). Colleagues → the
  // self bar (copy last week + own-row bulk), which only mounts for solo users;
  // for a manager in colleagues mode the mount filter drops it.
  add(
    colleagues
        ? _step(
            id: 'schMobileSelfBar',
            key: TutorialKeys.schMobileBulkAssign,
            title: l10n.tutSchMobileSelfBarTitle,
            body: l10n.tutSchMobileSelfBarBody,
            context: context,
          )
        : _step(
            id: 'schMobileBulk',
            key: TutorialKeys.schMobileBulkAssign,
            title: l10n.tutSchMobileBulkTitle,
            body: l10n.tutSchMobileBulkBody,
            context: context,
            gifAsset: ScheduleTourAssets.mobileBulkAssign,
          ),
    tab: MobileTabs.weekly,
  );

  // ── Swaps tab (both modes, different content) ─────────────────────────────
  add(
    colleagues
        ? _step(
            id: 'schMobileSwapsPeer',
            key: TutorialKeys.schMobileSwapsTab,
            title: l10n.tutSchMobileSwapsPeerTitle,
            body: l10n.tutSchMobileSwapsPeerBody,
            context: context,
            gifAsset: ScheduleTourAssets.mobileRequestSwap,
          )
        : _step(
            id: 'schMobileSwaps',
            key: TutorialKeys.schMobileSwapsTab,
            title: l10n.tutSchMobileSwapsTitle,
            body: l10n.tutSchMobileSwapsBody,
            context: context,
            gifAsset: ScheduleTourAssets.mobileApproveSwap,
          ),
    tab: MobileTabs.swaps,
  );

  // ── More tab (managers, team mode only) ───────────────────────────────────
  // The tab isn't built for non-managers, and in colleagues mode its body is
  // replaced by a "not available" placeholder.
  if (isManager && !colleagues) {
    add(
      _step(
        id: 'schMobileMore',
        key: TutorialKeys.schMobileMoreTab,
        title: l10n.tutSchMobileMoreTitle,
        body: l10n.tutSchMobileMoreBody,
        context: context,
        gifAsset: ScheduleTourAssets.mobilePublish,
      ),
      tab: MobileTabs.more,
    );
  }

  return MobileTourPlan(targets, tabOf);
}

// Computes a ContentAlign.custom position that always keeps the card on screen.
//
// Algorithm:
//   1. Try placing the card below the target — use if it fits.
//   2. Otherwise try above — use if it fits.
//   3. Neither fits perfectly → pick whichever side has more space, clamped.
//
// Using ContentAlign.custom bypasses the package's haloHeight math entirely,
// so this function is the single place that controls tooltip placement for all
// _step()-based targets, including any future ones.
TargetContent _safeContent({
  required GlobalKey key,
  required BuildContext context,
  required Widget Function(BuildContext, TutorialCoachMarkController) builder,
}) {
  const kAppBarH = kToolbarHeight;
  const gap = 64.0;
  const estimatedCardH = 260.0; // matches maxHeight:280 with a small margin

  final screenH = MediaQuery.of(context).size.height;
  final box = key.currentContext?.findRenderObject() as RenderBox?;

  double top;

  if (box != null) {
    final dy = box.localToGlobal(Offset.zero).dy;
    final targetBottom = dy + box.size.height;
    final spaceBelow = screenH - targetBottom - gap;
    final spaceAbove = dy - kAppBarH - gap;

    if (spaceBelow >= estimatedCardH) {
      top = targetBottom + gap;
    } else if (spaceAbove >= estimatedCardH) {
      top = (dy - gap - estimatedCardH).clamp(kAppBarH, screenH - estimatedCardH);
    } else {
      // Neither side fits fully — pick the larger space and clamp
      top =
          spaceBelow >= spaceAbove
              ? (targetBottom + gap).clamp(kAppBarH, screenH - estimatedCardH)
              : (dy - gap - estimatedCardH).clamp(kAppBarH, screenH - estimatedCardH);
    }
  } else {
    top = kAppBarH + gap;
  }

  return TargetContent(
    align: ContentAlign.custom,
    customPosition: CustomTargetContentPosition(top: top, left: 0),
    padding: EdgeInsets.zero,
    builder: builder,
  );
}

TargetFocus _step({
  required String id,
  required GlobalKey key,
  required String title,
  required String body,
  required BuildContext context,
  // When set, the card shows a "Watch how ▶" button opening the GIF dialog.
  String? gifAsset,
}) {
  final l10n = AppLocalizations.of(context)!;
  final screenW = MediaQuery.of(context).size.width;
  final maxWidth = (screenW - 32).clamp(200.0, 320.0);

  return TargetFocus(
    identify: id,
    keyTarget: key,
    shape: ShapeLightFocus.RRect,
    radius: 12,
    contents: [
      _safeContent(
        key: key,
        context: context,
        builder: (ctx, ctrl) => _card(
          l10n: l10n,
          title: title,
          body: body,
          controller: ctrl,
          maxWidth: maxWidth,
          gifAsset: gifAsset,
        ),
      ),
    ],
  );
}

// ─── Shared card builder ───────────────────────────────────────────────────

Widget _card({
  required AppLocalizations l10n,
  required String title,
  required String body,
  required TutorialCoachMarkController controller,
  required double maxWidth,
  String? gifAsset,
}) {
  return UnconstrainedBox(
    constrainedAxis: Axis.vertical,
    child: SizedBox(
      width: maxWidth,
      child: _TutCard(title: title, body: body, controller: controller, l10n: l10n, gifAsset: gifAsset),
    ),
  );
}

// ─── Tooltip card widget ───────────────────────────────────────────────────

class _TutCard extends StatefulWidget {
  const _TutCard({
    required this.title,
    required this.body,
    required this.controller,
    required this.l10n,
    this.gifAsset,
  });

  final String title;
  final String body;
  final TutorialCoachMarkController controller;
  final AppLocalizations l10n;
  // When non-null, renders a "Watch how ▶" button that opens the GIF dialog.
  final String? gifAsset;

  @override
  State<_TutCard> createState() => _TutCardState();
}

class _TutCardState extends State<_TutCard> {
  // Owned here (not in build) so the same controller instance is shared between
  // the Scrollbar and its SingleChildScrollView across rebuilds — required by
  // Scrollbar(thumbVisibility: true).
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final l10n = widget.l10n;
    final controller = widget.controller;

    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1f2a37)),
          ),
          const SizedBox(height: 8),
          Flexible(
            // thumbVisibility keeps the scrollbar always shown for long bodies
            // (e.g. the leave-type card). It only paints when content overflows,
            // so short cards stay clean.
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _scrollController,
                // Keep text clear of the scrollbar thumb on the scrolled edge.
                padding: const EdgeInsetsDirectional.only(end: 12),
                child: Text(
                  widget.body,
                  textAlign: isRtl ? TextAlign.right : TextAlign.left,
                  style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF54657a)),
                ),
              ),
            ),
          ),
          if (widget.gifAsset != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => showGifHelp(
                  context,
                  title: widget.title,
                  body: widget.body,
                  gifAsset: widget.gifAsset!,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2D9CDB),
                  side: const BorderSide(color: Color(0xFF2D9CDB)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.play_circle_outline, size: 16),
                label: Text(l10n.tutWatchHow, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: controller.skip,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF9aa6b4),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(l10n.tutSkip, style: const TextStyle(fontSize: 14)),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: controller.previous,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3a4858),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(l10n.back, style: const TextStyle(fontSize: 14)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: controller.next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2D9CDB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(l10n.tutNext, style: const TextStyle(fontSize: 14)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
