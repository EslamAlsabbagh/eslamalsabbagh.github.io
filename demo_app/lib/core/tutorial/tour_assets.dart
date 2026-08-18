/// Bundled screen-recording clips for the Schedule guided tour.
///
/// **Desktop and mobile are different UIs, so they get different recordings.**
/// A desktop clip shows the week grid, inline toolbar dropdowns and the side
/// panel; the mobile equivalents are a day list, a filters bottom sheet and
/// dedicated Swaps / More tabs. Never play one platform's clip on the other.
///
/// Files live in `assets/tour/schedule/desktop/` and `assets/tour/schedule/mobile/`,
/// each declared (non-recursively) in `pubspec.yaml`. A missing clip is handled
/// gracefully — the player shows a "coming soon" placeholder (gif_help_dialog.dart).
///
/// Recording guidance (these ship inside the binary — keep them lean):
///   • one workflow per clip, 5–10s, no dead time, cursor/touch visible
///   • desktop: record at ≥1000dp, ~1000–1200px wide
///   • mobile: record at a phone width (<600dp)
///   • optimise to **≤1MB each** (gifski / `gifsicle -O3`)
class ScheduleTourAssets {
  ScheduleTourAssets._();

  static const _desktop = 'assets/tour/schedule/desktop';
  static const _mobile = 'assets/tour/schedule/mobile';

  // ── Desktop clips ─────────────────────────────────────────────────────────
  static const filters = '$_desktop/filters.gif';
  static const copyLastWeek = '$_desktop/copy_last_week.gif';
  static const publishWeek = '$_desktop/publish_week.gif';
  static const assignShift = '$_desktop/assign_shift.gif';
  static const multiSelect = '$_desktop/multi_select.gif';
  static const template = '$_desktop/template.gif';
  static const approveSwap = '$_desktop/approve_swap.gif';
  // Colleagues-mode workflows.
  static const requestSwap = '$_desktop/request_swap.gif';
  static const selfDraft = '$_desktop/self_draft.gif';

  // ── Mobile clips ──────────────────────────────────────────────────────────
  // A lean set covering the workflows whose mobile UI diverges most from
  // desktop and which are hardest to convey in text alone.
  /// Header chip → filters bottom sheet → department/location/scope → Apply.
  static const mobileFilters = '$_mobile/filters.gif';

  /// Weekly "Assign shifts…" → the 3-step bulk sheet (shift, days, employees).
  static const mobileBulkAssign = '$_mobile/bulk_assign.gif';

  /// More tab → Publish week tile → confirm dialog.
  static const mobilePublish = '$_mobile/publish_week.gif';

  /// Swaps tab → a "Pending action" card → Approve (team mode).
  static const mobileApproveSwap = '$_mobile/approve_swap.gif';

  /// Tap a colleague's row (or My Schedule → "Swap with") → request sheet.
  static const mobileRequestSwap = '$_mobile/request_swap.gif';

  /// Desktop clips — precached by the desktop help centre only.
  static const desktopAll = [
    filters,
    copyLastWeek,
    publishWeek,
    assignShift,
    multiSelect,
    template,
    approveSwap,
    requestSwap,
    selfDraft,
  ];

  /// Mobile clips — precached by the mobile help centre only.
  static const mobileAll = [
    mobileFilters,
    mobileBulkAssign,
    mobilePublish,
    mobileApproveSwap,
    mobileRequestSwap,
  ];
}
