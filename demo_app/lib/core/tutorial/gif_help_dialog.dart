import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/tutorial/tour_assets.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

// Shared design tokens — kept identical to _TutCard (tutorial_steps.dart) so the
// GIF dialog and the spotlight cards read as one system.
const Color _kInk = Color(0xFF1f2a37);
const Color _kBody = Color(0xFF54657a);
const Color _kAccent = Color(0xFF2D9CDB);
const Color _kMuted = Color(0xFF9aa6b4);

/// Who a how-to is for. Team topics are hidden from users with no team, who
/// cannot perform them (publish, approve swaps, filter a team …).
enum TopicAudience { team, colleagues }

/// One how-to entry in the Schedule help centre: an icon, a localized title and
/// body, and the bundled clip that demonstrates it.
class GifHelpTopic {
  final IconData icon;
  final String title;
  final String body;
  final String gifAsset;
  final TopicAudience audience;

  const GifHelpTopic({
    required this.icon,
    required this.title,
    required this.body,
    required this.gifAsset,
    required this.audience,
  });
}

/// The interaction-heavy Schedule workflows, each backed by a screen recording.
///
/// The list is **platform-specific**: mobile is a different UI (filters sheet,
/// bulk-assign sheet, Swaps/More tabs) so it gets its own, leaner set of clips
/// and its own wording. Showing desktop recordings to a phone user would
/// demonstrate controls that don't exist there.
List<GifHelpTopic> scheduleHelpTopics(AppLocalizations l10n, {required bool mobile}) {
  if (mobile) {
    return [
      GifHelpTopic(
        icon: Icons.filter_alt_outlined,
        title: l10n.tutSchMobileFiltersTitle,
        body: l10n.tutSchMobileFiltersBody,
        gifAsset: ScheduleTourAssets.mobileFilters,
        audience: TopicAudience.team,
      ),
      GifHelpTopic(
        icon: Icons.select_all,
        title: l10n.tutSchMobileBulkTitle,
        body: l10n.tutSchMobileBulkBody,
        gifAsset: ScheduleTourAssets.mobileBulkAssign,
        audience: TopicAudience.team,
      ),
      GifHelpTopic(
        icon: Icons.send_outlined,
        title: l10n.tutSchMobileMoreTitle,
        body: l10n.tutSchMobileMoreBody,
        gifAsset: ScheduleTourAssets.mobilePublish,
        audience: TopicAudience.team,
      ),
      GifHelpTopic(
        icon: Icons.swap_horiz,
        title: l10n.tutSchMobileSwapsTitle,
        body: l10n.tutSchMobileSwapsBody,
        gifAsset: ScheduleTourAssets.mobileApproveSwap,
        audience: TopicAudience.team,
      ),
      GifHelpTopic(
        icon: Icons.published_with_changes,
        title: l10n.tutSchRequestSwapTitle,
        body: l10n.tutSchRequestSwapBody,
        gifAsset: ScheduleTourAssets.mobileRequestSwap,
        audience: TopicAudience.colleagues,
      ),
    ];
  }

  return [
    GifHelpTopic(
      icon: Icons.filter_alt_outlined,
      title: l10n.tutSchFiltersTitle,
      body: l10n.tutSchFiltersBody,
      gifAsset: ScheduleTourAssets.filters,
      audience: TopicAudience.team,
    ),
    GifHelpTopic(
      icon: Icons.add_box_outlined,
      title: l10n.tutSchAssignTitle,
      body: l10n.tutSchAssignBody,
      gifAsset: ScheduleTourAssets.assignShift,
      audience: TopicAudience.team,
    ),
    GifHelpTopic(
      icon: Icons.select_all,
      title: l10n.tutSchMultiSelectTitle,
      body: l10n.tutSchMultiSelectBody,
      gifAsset: ScheduleTourAssets.multiSelect,
      audience: TopicAudience.team,
    ),
    GifHelpTopic(
      icon: Icons.bookmark_add_outlined,
      title: l10n.tutSchTemplateTitle,
      body: l10n.tutSchTemplateBody,
      gifAsset: ScheduleTourAssets.template,
      audience: TopicAudience.team,
    ),
    GifHelpTopic(
      icon: Icons.copy_outlined,
      title: l10n.tutSchCopyTitle,
      body: l10n.tutSchCopyBody,
      gifAsset: ScheduleTourAssets.copyLastWeek,
      audience: TopicAudience.team,
    ),
    GifHelpTopic(
      icon: Icons.send_outlined,
      title: l10n.tutSchPublishTitle,
      body: l10n.tutSchPublishBody,
      gifAsset: ScheduleTourAssets.publishWeek,
      audience: TopicAudience.team,
    ),
    GifHelpTopic(
      icon: Icons.swap_horiz,
      title: l10n.tutSchSwapTitle,
      body: l10n.tutSchSwapBody,
      gifAsset: ScheduleTourAssets.approveSwap,
      audience: TopicAudience.team,
    ),
    GifHelpTopic(
      icon: Icons.edit_calendar_outlined,
      title: l10n.tutSchSelfDraftTitle,
      body: l10n.tutSchSelfDraftBody,
      gifAsset: ScheduleTourAssets.selfDraft,
      audience: TopicAudience.colleagues,
    ),
    GifHelpTopic(
      icon: Icons.published_with_changes,
      title: l10n.tutSchRequestSwapTitle,
      body: l10n.tutSchRequestSwapBody,
      gifAsset: ScheduleTourAssets.requestSwap,
      audience: TopicAudience.colleagues,
    ),
  ];
}

/// Which tour to launch from the help centre.
enum HelpTourMode { current, team, colleagues }

/// Plays a bundled screen-recording [gifAsset] with a [title] and explanatory
/// [body]. Used for interaction-heavy tour steps and the help centre.
///
/// Inserted as an [OverlayEntry] on the ROOT overlay — the same overlay the
/// tutorial_coach_mark spotlight uses. A plain `showDialog` pushes onto the
/// Navigator, which sits *below* the coach-mark entry, so the clip would render
/// beneath the highlighter. Adding our entry after the spotlight's keeps it on
/// top.
void showGifHelp(BuildContext context, {required String title, required String body, required String gifAsset}) {
  // Warm the frames so the first loop is smooth. Best-effort — ignore failures
  // (a missing asset is handled by the player's errorBuilder).
  precacheImage(AssetImage(gifAsset), context).catchError((_) {});
  final overlay = Overlay.of(context, rootOverlay: true);
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder:
        (_) => _GifHelpOverlay(
          title: title,
          body: body,
          gifAsset: gifAsset,
          onDismiss: () {
            if (entry.mounted) entry.remove();
          },
        ),
  );
  overlay.insert(entry);
}

/// Opens the Schedule help centre: a primary "Start guided tour" action plus a
/// browsable list of GIF how-tos.
///
/// [onStartTour] receives the chosen [HelpTourMode] (current / team / colleagues).
/// [mobile] picks the platform's clip set — the two UIs are different, so a phone
/// must never be shown desktop recordings.
/// [isSelfOnly] hides the manager-only topics and the explicit Team/Colleagues
/// tour buttons from users who have no team.
Future<void> showScheduleHelpMenu(
  BuildContext context, {
  required void Function(HelpTourMode mode) onStartTour,
  required bool mobile,
  bool isSelfOnly = false,
}) {
  final l10n = AppLocalizations.of(context)!;
  // Precache only this platform's clips so the first one opens instantly —
  // decoding the other platform's set would be pure waste.
  for (final a in mobile ? ScheduleTourAssets.mobileAll : ScheduleTourAssets.desktopAll) {
    precacheImage(AssetImage(a), context).catchError((_) {});
  }
  return showDialog<void>(
    context: context,
    builder: (_) => _HelpMenuDialog(l10n: l10n, onStartTour: onStartTour, mobile: mobile, isSelfOnly: isSelfOnly),
  );
}

// ── Help-centre menu dialog ──────────────────────────────────────────────────

class _HelpMenuDialog extends StatelessWidget {
  final AppLocalizations l10n;
  final void Function(HelpTourMode mode) onStartTour;
  final bool mobile;
  final bool isSelfOnly;

  const _HelpMenuDialog({
    required this.l10n,
    required this.onStartTour,
    required this.mobile,
    required this.isSelfOnly,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final all = scheduleHelpTopics(l10n, mobile: mobile);
    // A user with no team can't publish, approve swaps or filter a team, so the
    // whole Team group is dropped for them.
    final teamTopics = isSelfOnly ? const <GifHelpTopic>[] : all.where((t) => t.audience == TopicAudience.team).toList();
    final peerTopics = all.where((t) => t.audience == TopicAudience.colleagues).toList();
    final showModeTours = !isSelfOnly;
    final screenW = MediaQuery.of(context).size.width;
    final maxWidth = (screenW - 48).clamp(280.0, 960.0);
    // Two side-by-side buttons ellipsize on a narrow phone — stack them instead.
    final stackModeButtons = maxWidth < 420;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: context.screenHeight * 0.9),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.help_outline, color: _kAccent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.tutHelpCenterTitle,
                      textAlign: isRtl ? TextAlign.right : TextAlign.left,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _kInk),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20, color: _kMuted),
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Primary: start the spotlight tour for the current mode.
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onStartTour(HelpTourMode.current);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: Text(l10n.tutStartTour, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
              // Explicit per-mode tours (managers with a team).
              if (showModeTours) ...[
                const SizedBox(height: 8),
                if (stackModeButtons)
                  Column(
                    children: [
                      SizedBox(width: double.infinity, child: _teamTourButton(context)),
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: _peerTourButton(context)),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(child: _teamTourButton(context)),
                      const SizedBox(width: 8),
                      Expanded(child: _peerTourButton(context)),
                    ],
                  ),
              ],
              const SizedBox(height: 14),
              Text(
                l10n.tutBrowseClips,
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _kMuted, letterSpacing: 0.3),
              ),
              const SizedBox(height: 8),
              // Grouped by audience so it's obvious which workflows belong to
              // managing a team vs running your own schedule.
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (teamTopics.isNotEmpty) ...[
                      _GroupHeading(label: l10n.tutTopicsTeam, isRtl: isRtl),
                      for (final t in teamTopics) ...[_topicRow(context, t), const SizedBox(height: 6)],
                      const SizedBox(height: 6),
                    ],
                    if (peerTopics.isNotEmpty) ...[
                      _GroupHeading(label: l10n.tutTopicsColleagues, isRtl: isRtl),
                      for (final t in peerTopics) ...[_topicRow(context, t), const SizedBox(height: 6)],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamTourButton(BuildContext context) => _ModeTourButton(
        icon: Icons.groups_outlined,
        label: l10n.tutTeamTour,
        onTap: () {
          Navigator.of(context).pop();
          onStartTour(HelpTourMode.team);
        },
      );

  Widget _peerTourButton(BuildContext context) => _ModeTourButton(
        icon: Icons.people_outline,
        label: l10n.tutColleaguesTour,
        onTap: () {
          Navigator.of(context).pop();
          onStartTour(HelpTourMode.colleagues);
        },
      );

  Widget _topicRow(BuildContext context, GifHelpTopic t) => _TopicRow(
        topic: t,
        onTap: () => showGifHelp(context, title: t.title, body: t.body, gifAsset: t.gifAsset),
      );
}

/// Small section label separating the Team and Colleagues how-to groups.
class _GroupHeading extends StatelessWidget {
  final String label;
  final bool isRtl;

  const _GroupHeading({required this.label, required this.isRtl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        textAlign: isRtl ? TextAlign.right : TextAlign.left,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _kAccent, letterSpacing: 0.4),
      ),
    );
  }
}

/// Secondary button for the explicit Team / Colleagues tour entries.
class _ModeTourButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ModeTourButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kAccent,
        side: const BorderSide(color: _kAccent),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TopicRow extends StatelessWidget {
  final GifHelpTopic topic;
  final VoidCallback onTap;

  const _TopicRow({required this.topic, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F9FC),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(topic.icon, size: 20, color: _kAccent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  topic.title,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: _kInk),
                ),
              ),
              const Icon(Icons.play_arrow_rounded, size: 20, color: _kMuted),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Single-clip player (root-overlay layer) ──────────────────────────────────
//
// Rendered by an OverlayEntry on the root overlay so it always sits above the
// coach-mark spotlight. Provides its own barrier + fade since it isn't a route.

class _GifHelpOverlay extends StatefulWidget {
  final String title;
  final String body;
  final String gifAsset;
  final VoidCallback onDismiss;

  const _GifHelpOverlay({required this.title, required this.body, required this.gifAsset, required this.onDismiss});

  @override
  State<_GifHelpOverlay> createState() => _GifHelpOverlayState();
}

class _GifHelpOverlayState extends State<_GifHelpOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180))
    ..forward();
  late final Animation<double> _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
  bool _closing = false;

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await _ctrl.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Dialog / media sizing constants — kept together so width and height stay
  // in sync (the bug was setting one without the other).
  static const double _hPad = 20; // left/right padding inside the card
  static const double _maxDialogW = 960;
  static const double _mediaAspect = 16 / 10; // width : height
  static const double _mediaMinH = 140;
  static const double _mediaMaxH = 560;
  // Vertical space the card needs besides the media: title row, gaps, a few
  // lines of body, and the card padding. Used to budget the media height so the
  // whole card fits within the screen.
  static const double _chromeH = 220;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final size = MediaQuery.of(context).size;

    // 1) Card width: capped, with a screen margin.
    final dialogW = (size.width - 48).clamp(280.0, _maxDialogW);
    // 2) Media height fits BOTH the width (via aspect) AND the leftover screen
    //    height — whichever is smaller — so the card can never overflow.
    final innerW = dialogW - _hPad * 2;
    final heightBudget = (size.height * 0.9 - _chromeH).clamp(_mediaMinH, _mediaMaxH);
    final aspectH = innerW / _mediaAspect;
    final mediaH = aspectH < heightBudget ? aspectH : heightBudget;

    return FadeTransition(
      opacity: _fade,
      child: Stack(
        children: [
          // Dim barrier — tap outside to dismiss.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: ColoredBox(color: Colors.black.withValues(alpha: 0.55)),
            ),
          ),
          Center(
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {}, // absorb taps so they don't reach the barrier
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: dialogW, maxHeight: size.height * 0.9),
                  child: Container(
                    width: dialogW,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(_hPad, 16, _hPad, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.title,
                                textAlign: isRtl ? TextAlign.right : TextAlign.left,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _kInk),
                              ),
                            ),
                            IconButton(
                              onPressed: _close,
                              icon: const Icon(Icons.close, size: 20, color: _kMuted),
                              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // The recording. Fixed height (computed above) so it can't
                        // fight the body for space; BoxFit.contain letterboxes any
                        // aspect. gaplessPlayback keeps the loop seamless; a missing
                        // asset falls back to a neutral placeholder.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: double.infinity,
                            height: mediaH,
                            child: ColoredBox(
                              color: const Color(0xFF0F172A),
                              child: Image.asset(
                                widget.gifAsset,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                                // Smoother resampling when the clip is scaled.
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (context, _, _) => _ClipPlaceholder(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Body takes the remaining height and scrolls if long, so
                        // the card total never exceeds maxHeight.
                        Flexible(
                          child: SingleChildScrollView(
                            child: Text(
                              widget.body,
                              textAlign: isRtl ? TextAlign.right : TextAlign.left,
                              style: const TextStyle(fontSize: 14, height: 1.6, color: _kBody),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown inside the player when a clip hasn't been recorded/bundled yet.
class _ClipPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.movie_outlined, size: 40, color: Colors.white38),
          const SizedBox(height: 10),
          Text(
            l10n.tutClipComingSoon,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
