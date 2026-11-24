import 'package:flutter/material.dart';

import '../../../../core/domain/task_status.dart';
import '../../../../core/format/app_formats.dart';
import '../../../../core/format/relative_time.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../l10n/task_status_l10n.dart';
import '../../data/task_activity_entry.dart';
import 'expand_toggle.dart';
import 'stored_text.dart';

/// «سجل التغييرات» at the end of the drawer (spec §4 "Task drawer" →
/// "Activity history"; not in the canvas): a toggle like «المكتملة», closed by
/// default, over the history newest first. Each line is the actor's name and
/// what they changed, then the relative time.
class ActivityHistory extends StatefulWidget {
  const ActivityHistory({super.key, required this.entries, required this.now});

  final List<TaskActivityEntry> entries;
  final DateTime now;

  @override
  State<ActivityHistory> createState() => _ActivityHistoryState();
}

class _ActivityHistoryState extends State<ActivityHistory> {
  // Kept across saves: the drawer rebuilds this widget, not a new one.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entries = widget.entries;
    // Every task logs `created`, so this only happens while nothing is readable.
    if (entries.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: _Toggle(
            expanded: _expanded,
            count: entries.length,
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
        ),
        if (_expanded)
          for (final entry in entries) _ActivityRow(entry: entry, now: widget.now),
      ],
    );
  }
}

/// «عرض / إخفاء سجل التغييرات (n)».
class _Toggle extends StatelessWidget {
  const _Toggle({required this.expanded, required this.count, required this.onPressed});

  final bool expanded;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final countText = AppFormats.number(count);
    return ExpandToggle(
      buttonKey: const Key('activity-toggle'),
      expanded: expanded,
      label: expanded ? l10n.hideActivity(countText) : l10n.showActivity(countText),
      onPressed: onPressed,
    );
  }
}

/// A dot, the actor's name and the change, the time under it, then a
/// separator like the update list's. One semantics node, so it is read as one
/// line. A title change lists the old title (struck through) and the new one
/// under the sentence, each reading in its own direction.
class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry, required this.now});

  final TaskActivityEntry entry;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final style = AppTextStyles.meta.copyWith(height: 1.6, color: tokens.ink);
    final titles = entry.action == TaskActivityAction.titleChanged
        ? ('${entry.oldValue ?? ''}', '${entry.newValue ?? ''}')
        : null;
    return Semantics(
      container: true,
      child: Row(
        key: ValueKey('activity-${entry.id}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(top: 8),
            child: DecoratedBox(
              decoration: BoxDecoration(color: tokens.borderStrong, shape: BoxShape.circle),
              child: const SizedBox.square(dimension: 6),
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: tokens.dividerSubtle))),
              child: Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 10 + 1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: activityActor(l10n, entry), style: const TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: ' ${activityChange(l10n, entry)}'),
                      ]),
                      style: style,
                    ),
                    if (titles case (final before, final after)) ...[
                      Semantics(
                        label: l10n.activityOldTitle(before),
                        excludeSemantics: true,
                        child: StoredText(
                          before,
                          key: ValueKey('activity-${entry.id}-old'),
                          style: style.copyWith(color: tokens.textMuted, decoration: TextDecoration.lineThrough),
                        ),
                      ),
                      Semantics(
                        label: l10n.activityNewTitle(after),
                        excludeSemantics: true,
                        child: StoredText(after, key: ValueKey('activity-${entry.id}-new'), style: style),
                      ),
                    ],
                    Text(
                      RelativeTime.format(l10n, entry.createdAt, now: now),
                      style: AppTextStyles.badge.copyWith(fontWeight: FontWeight.w400, color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Who made the change: «النظام» for a change with no user, «موظف سابق» when
/// RLS hides their profile.
String activityActor(AppLocalizations l10n, TaskActivityEntry entry) =>
    entry.actorId == null ? l10n.activitySystem : entry.actorName ?? l10n.formerEmployee;

/// What changed, to follow the actor's name. The verb is masculine for
/// everyone (chosen 2026-10-18: profiles store no gender).
///
/// Names sit in the Arabic sentence as they are, like file and topic names in
/// «ملف / موضوع»: the bidi rules already order an English name. Bidi isolate
/// marks would pull in fallback fonts, since the bundled fonts have no glyphs
/// for them. Titles, which can be long English text, go on their own lines
/// (see [_ActivityRow]); the description's text isn't shown at all.
String activityChange(AppLocalizations l10n, TaskActivityEntry entry) => switch (entry.action) {
      TaskActivityAction.created => l10n.activityCreated,
      TaskActivityAction.statusChanged =>
        l10n.activityStatus(_status(l10n, entry.oldValue), _status(l10n, entry.newValue)),
      TaskActivityAction.assigneeChanged => l10n.activityAssignee(
          entry.oldName ?? l10n.formerEmployee,
          entry.newName ?? l10n.formerEmployee,
        ),
      TaskActivityAction.dueDateChanged => l10n.activityDueDate(_date(entry.oldValue), _date(entry.newValue)),
      TaskActivityAction.urgencyChanged => entry.newValue == true ? l10n.activityUrgentOn : l10n.activityUrgentOff,
      TaskActivityAction.titleChanged => l10n.activityTitle,
      TaskActivityAction.descriptionChanged => l10n.activityDescription,
      TaskActivityAction.topicChanged => l10n.activityTopic(entry.newName ?? l10n.activityOtherTopic),
      // No screen changes the link, so the contract isn't named (ADR-0013).
      TaskActivityAction.contractChanged =>
        entry.newValue == null ? l10n.activityContractUnlinked : l10n.activityContractLinked,
    };

String _status(AppLocalizations l10n, Object? value) =>
    TaskStatus.values.asNameMap()[value]?.label(l10n) ?? '${value ?? ''}';

/// A `yyyy-MM-dd` value as «١٣ أكتوبر ٢٠٢٦».
String _date(Object? value) {
  final date = DateTime.tryParse('${value ?? ''}');
  return date == null ? '${value ?? ''}' : AppFormats.fullDate(date);
}
