import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/relative_time.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../tasks/bloc/tasks_bloc.dart';
import '../../tasks/data/task_list_item.dart';
import '../../tasks/view/task_drawer.dart';
import '../../tasks/view/widgets/activity_history.dart';
import '../../tasks/view/widgets/form_error_line.dart';
import '../../tasks/view/widgets/stored_text.dart';
import '../bloc/notifications_bloc.dart';
import '../data/app_notification.dart';

/// Opens the bell's panel (spec §4 "Notifications") under [anchor], the
/// bell's rect. Opening it marks nothing read.
///
/// Tapping a row marks it read, closes the panel and opens the task's drawer
/// over the shell. The task comes from the shell's list, so a task the viewer
/// can no longer see shows «لم تعد هذه المهمة متاحة» and opens nothing.
Future<void> openNotificationsPanel(
  BuildContext context, {
  required Rect anchor,
  required DateTime Function() clock,
}) {
  final notificationsBloc = context.read<NotificationsBloc>();
  final tasksBloc = context.read<TasksBloc>();

  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: AppLocalizations.of(context).drawerClose,
    // A menu, not a modal: the page stays as it is around it.
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 150),
    pageBuilder: (dialogContext, _, _) => MultiBlocProvider(
      providers: [
        BlocProvider.value(value: notificationsBloc),
        BlocProvider.value(value: tasksBloc),
      ],
      child: _PanelPlacement(
        anchor: anchor,
        child: NotificationsPanel(
          now: clock(),
          onOpenTask: (task) {
            Navigator.of(dialogContext).pop();
            // The shell's context: the drawer reads its blocs and repositories.
            if (context.mounted) showTaskDrawer(context, task, clock: clock);
          },
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

/// Under the bell. When wide, a 380 panel whose `end` edge lines up with the
/// bell's, kept inside the page. On a phone, the page's width minus the side
/// gutters.
class _PanelPlacement extends StatelessWidget {
  const _PanelPlacement({required this.anchor, required this.child});

  final Rect anchor;
  final Widget child;

  static const double _width = 380;
  static const double _maxHeight = 560;
  static const double _gap = 8;
  static const double _margin = 16;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final top = anchor.bottom + _gap;
    final room = math.max(size.height - top - _margin, 160.0);

    if (size.width < AppSpacing.mobileBreakpoint) {
      return Stack(children: [
        PositionedDirectional(
          top: top,
          start: AppSpacing.sidePadding,
          end: AppSpacing.sidePadding,
          child: ConstrainedBox(constraints: BoxConstraints(maxHeight: room), child: child),
        ),
      ]);
    }

    final width = math.min(_width, size.width - 2 * _margin);
    // Distance from the page's end edge to the bell's end edge.
    final bellEnd = rtl ? anchor.left : size.width - anchor.right;
    final end = bellEnd.clamp(_margin, size.width - _margin - width);
    return Stack(children: [
      PositionedDirectional(
        top: top,
        end: end,
        width: width,
        child: ConstrainedBox(constraints: BoxConstraints(maxHeight: math.min(_maxHeight, room)), child: child),
      ),
    ]);
  }
}

/// The panel: «الإشعارات» and «تعليم الكل كمقروء», then the newest
/// notifications. Needs the shell's [NotificationsBloc] and [TasksBloc].
class NotificationsPanel extends StatelessWidget {
  const NotificationsPanel({super.key, required this.now, required this.onOpenTask});

  /// "Now" for the relative times.
  final DateTime now;
  final ValueChanged<TaskListItem> onOpenTask;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final state = context.watch<NotificationsBloc>().state;
    final tasks = context.select((TasksBloc bloc) => bloc.state.tasks);
    final byId = {for (final task in tasks) task.id: task};

    return Material(
      key: const Key('notifications-panel'),
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: tokens.border),
      ),
      shadowColor: tokens.drawerShadow,
      elevation: 12,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 6, 6, 6),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(l10n.notificationsTitle, style: AppTextStyles.cardTitle.copyWith(color: tokens.ink)),
                  ),
                ),
                TextButton(
                  key: const Key('notifications-mark-all'),
                  onPressed: state.unreadCount == 0 || state.markingAll
                      ? null
                      : () => context.read<NotificationsBloc>().add(const NotificationsAllReadRequested()),
                  style: TextButton.styleFrom(
                    foregroundColor: tokens.accent,
                    textStyle: AppTextStyles.button,
                    minimumSize: const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
                  ),
                  child: Text(l10n.notificationsMarkAllRead),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: tokens.divider),
          Flexible(child: _Body(state: state, byId: byId, now: now, onOpenTask: onOpenTask)),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.byId, required this.now, required this.onOpenTask});

  final NotificationsState state;
  final Map<String, TaskListItem> byId;
  final DateTime now;
  final ValueChanged<TaskListItem> onOpenTask;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final items = state.items;

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: switch (state.status) {
          NotificationsStatus.loading => Center(
              child: SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: tokens.accent),
              ),
            ),
          NotificationsStatus.failure => Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                FormErrorLine(l10n.notificationsLoadError),
                TextButton(
                  key: const Key('notifications-retry'),
                  onPressed: () => context.read<NotificationsBloc>().add(const NotificationsLoadRequested()),
                  style: TextButton.styleFrom(
                    foregroundColor: tokens.accent,
                    textStyle: AppTextStyles.button,
                    minimumSize: const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
                  ),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          NotificationsStatus.success => Text(
              l10n.notificationsEmpty,
              textAlign: TextAlign.center,
              style: AppTextStyles.meta.copyWith(color: tokens.textMuted),
            ),
        },
      );
    }

    return ListView.separated(
      key: const Key('notifications-list'),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: items.length,
      separatorBuilder: (_, _) => Divider(height: 1, thickness: 1, color: tokens.dividerSubtle),
      itemBuilder: (context, index) {
        final item = items[index];
        final task = byId[item.taskId];
        return NotificationRow(
          item: item,
          task: task,
          now: now,
          onTap: () {
            if (!item.isRead) context.read<NotificationsBloc>().add(NotificationReadRequested(item.id));
            if (task != null) onOpenTask(task);
          },
        );
      },
    );
  }
}

/// One notification, one button: an `accent` dot while unread, then the
/// actor's name and what happened, the task's title in its own direction, and
/// «ملف / موضوع · منذ ساعة». Read rows are softer.
class NotificationRow extends StatelessWidget {
  const NotificationRow({super.key, required this.item, required this.task, required this.now, required this.onTap});

  final AppNotification item;

  /// Null when the viewer can no longer see the task.
  final TaskListItem? task;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final ink = item.isRead ? tokens.textSoft : tokens.ink;
    final time = RelativeTime.format(l10n, item.createdAt, now: now);
    final task = this.task;

    return Semantics(
      container: true,
      button: true,
      child: InkWell(
        key: ValueKey('notification-${item.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              SizedBox(
                width: 8,
                child: item.isRead
                    ? null
                    : Padding(
                        padding: const EdgeInsetsDirectional.only(top: 7),
                        child: Semantics(
                          label: l10n.notificationUnread,
                          child: DecoratedBox(
                            key: ValueKey('notification-${item.id}-unread'),
                            decoration: BoxDecoration(color: tokens.accent, shape: BoxShape.circle),
                            child: const SizedBox.square(dimension: 8),
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: notificationActor(l10n, item), style: const TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: ' ${notificationSentence(l10n, item)}'),
                      ]),
                      style: AppTextStyles.meta.copyWith(height: 1.6, color: ink),
                    ),
                    if (task != null)
                      StoredText(task.title, style: AppTextStyles.button.copyWith(color: ink))
                    else
                      Text(l10n.notificationTaskGone, style: AppTextStyles.meta.copyWith(color: tokens.textMuted)),
                    Text(
                      task == null ? time : '${task.fileName} / ${task.topicName} · $time',
                      style: AppTextStyles.badge.copyWith(fontWeight: FontWeight.w400, color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Who did it, named like the drawer's history: «النظام» with no user,
/// «موظف سابق» when RLS hides their profile.
String notificationActor(AppLocalizations l10n, AppNotification item) =>
    item.actorId == null ? l10n.activitySystem : item.actorName ?? l10n.formerEmployee;

/// What happened, after the actor's name. A change is worded like its line in
/// the drawer's history («غيّر الحالة من جارية إلى مكتملة»). The verb is
/// masculine for everyone, as there.
String notificationSentence(AppLocalizations l10n, AppNotification item) => switch (item.type) {
      NotificationType.assigned => l10n.notificationAssigned,
      NotificationType.updatePosted => l10n.notificationUpdatePosted,
      NotificationType.taskChanged => switch (item.activity) {
          final activity? => activityChange(l10n, activity),
          null => l10n.notificationChanged,
        },
    };
