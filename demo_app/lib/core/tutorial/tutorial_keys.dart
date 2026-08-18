import 'package:flutter/widgets.dart';

/// Registry of GlobalKeys used to target widgets during the guided tour.
/// Attach each key to its widget via `key: TutorialKeys.xyz`.
/// Add new keys here when new tour targets are needed.
class TutorialKeys {
  TutorialKeys._();

  // Dashboard — Home page
  static final topBar         = GlobalKey(debugLabel: 'tut_topBar');
  static final sidebar        = GlobalKey(debugLabel: 'tut_sidebar');
  static final pendingCard    = GlobalKey(debugLabel: 'tut_pending');
  static final processingCard = GlobalKey(debugLabel: 'tut_processing');
  static final recentCard     = GlobalKey(debugLabel: 'tut_recent');
  static final quickActions   = GlobalKey(debugLabel: 'tut_quickActions');
  static final leaveButton    = GlobalKey(debugLabel: 'tut_leaveBtn');

  // Request Leave page
  static final leaveBalances     = GlobalKey(debugLabel: 'tut_leaveBalances');
  static final leaveFromDate     = GlobalKey(debugLabel: 'tut_leaveFromDate');
  static final leaveToDate       = GlobalKey(debugLabel: 'tut_leaveToDate');
  static final leaveHours        = GlobalKey(debugLabel: 'tut_leaveHours');
  static final leaveDayCount     = GlobalKey(debugLabel: 'tut_leaveDayCount');
  static final leaveTypeDropdown = GlobalKey(debugLabel: 'tut_leaveType');
  static final leaveSubmit       = GlobalKey(debugLabel: 'tut_leaveSubmit');

  // Employee Schedule page — desktop.
  // schGrid is intentionally reused by three consecutive steps (assign,
  // multi-select, template) — the tour focuses the same grid area each time.
  static final schViewMode     = GlobalKey(debugLabel: 'tut_schViewMode');
  static final schTabs         = GlobalKey(debugLabel: 'tut_schTabs');
  static final schToolbar      = GlobalKey(debugLabel: 'tut_schToolbar');
  static final schCopyLastWeek = GlobalKey(debugLabel: 'tut_schCopyLastWeek');
  static final schPublish      = GlobalKey(debugLabel: 'tut_schPublish');
  static final schKpi          = GlobalKey(debugLabel: 'tut_schKpi');
  static final schLegend       = GlobalKey(debugLabel: 'tut_schLegend');
  static final schGrid         = GlobalKey(debugLabel: 'tut_schGrid');
  static final schSidePanel    = GlobalKey(debugLabel: 'tut_schSidePanel');
  // Colleagues-mode-only targets.
  static final schSelfActions  = GlobalKey(debugLabel: 'tut_schSelfActions');
  static final schPinnedRow    = GlobalKey(debugLabel: 'tut_schPinnedRow');

  // Employee Schedule page — mobile scaffold.
  static final schMobileFilters   = GlobalKey(debugLabel: 'tut_schMobileFilters');
  static final schMobileTabs      = GlobalKey(debugLabel: 'tut_schMobileTabs');
  static final schMobileViewMode  = GlobalKey(debugLabel: 'tut_schMobileViewMode');
  static final schMobileWeekNav   = GlobalKey(debugLabel: 'tut_schMobileWeekNav');
  static final schMobileStats     = GlobalKey(debugLabel: 'tut_schMobileStats');
  static final schMobileDayPicker = GlobalKey(debugLabel: 'tut_schMobileDayPicker');
  static final schMobileBulkAssign = GlobalKey(debugLabel: 'tut_schMobileBulkAssign');
  // Tab-gated targets: keyed on each tab body's ROOT container, never on an
  // individual card/tile — those lists can be empty, which would leave the
  // spotlight with a null context after the tour switches tabs.
  static final schMobileSwapsTab = GlobalKey(debugLabel: 'tut_schMobileSwapsTab');
  static final schMobileMoreTab = GlobalKey(debugLabel: 'tut_schMobileMoreTab');
}
