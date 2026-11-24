import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../../core/connectivity/server_status_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../sell/view/sell_messages.dart';
import '../bloc/offline_sync_cubit.dart';
import '../data/offline_models.dart';

/// The header's server pill (ADR-0015: the mode shows at all times). No
/// design exists for it: it follows the sell screen's printer badge.
class ServerBadge extends StatelessWidget {
  const ServerBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final status = context.watch<ServerStatusCubit>().state;
    final (text, background, foreground, dot) = switch (status) {
      ServerStatus.online =>
        (l10n.serverBadgeOnline, tokens.successBg, tokens.successText, tokens.successDot),
      ServerStatus.offline =>
        (l10n.serverBadgeOffline, tokens.warningBg, tokens.warningText, tokens.warningText),
      ServerStatus.unknown =>
        (l10n.serverBadgeChecking, tokens.inset, tokens.textSecondary, tokens.textSecondary),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('server-badge'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: ShapeDecoration(color: background, shape: const StadiumBorder()),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: foreground),
            ),
          ],
        ),
      ),
    );
  }
}

/// Under the sell flow's header: the offline mode and what it means, and the
/// queue of offline orders (waiting, uploading, refused). Hidden while
/// online with nothing queued and the pool fine.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final offline = context.select((ServerStatusCubit cubit) => cubit.isOffline);
    final sync = context.watch<OfflineSyncCubit>().state;
    final queue = sync.queue;
    final poolProblem = !offline && sync.poolFailure != null;
    if (!offline && queue.isEmpty && !poolProblem) return const SizedBox.shrink();

    final chips = <Widget>[
      if (offline) _Chip(text: l10n.offlineFreeCodes(sync.freeCodes)),
      if (sync.uploading)
        _Chip(text: l10n.offlineQueueUploading)
      else if (queue.pendingOrders > 0)
        _Chip(text: l10n.offlineQueuePending(queue.pendingOrders)),
      if (!sync.uploading && queue.pendingActions > 0)
        _Chip(
          key: const ValueKey('offline-actions'),
          text: l10n.offlineQueueActions(queue.pendingActions),
        ),
      if (queue.hasRefused)
        _Chip(
          key: const ValueKey('offline-refused'),
          text: l10n.offlineQueueRefused(queue.refused.length + queue.refusedActions.length),
          danger: true,
          onTap: () => showRefusedOrders(context, queue),
        ),
    ];

    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('offline-banner'),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: offline || poolProblem ? tokens.warningBg : tokens.surface,
          border: Border(
            bottom: BorderSide(color: offline || poolProblem ? tokens.warningBorder : tokens.border),
          ),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            if (offline)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 20, color: tokens.warningText),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: l10n.offlineBannerTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                        children: [
                          TextSpan(
                            text: '  ${l10n.offlineBannerBody}',
                            style: const TextStyle(fontWeight: FontWeight.w400),
                          ),
                        ],
                      ),
                      style: TextStyle(fontSize: 14, color: tokens.warningText),
                    ),
                  ),
                ],
              )
            else if (poolProblem)
              Text(
                l10n.offlinePoolUnavailable,
                style: TextStyle(fontSize: 14, color: tokens.warningText),
              ),
            if (chips.isNotEmpty) Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({super.key, required this.text, this.danger = false, this.onTap});

  final String text;
  final bool danger;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (background, foreground) =
        danger ? (tokens.dangerBg, tokens.dangerText) : (tokens.surface, tokens.text);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: ShapeDecoration(
        color: background,
        shape: StadiumBorder(side: BorderSide(color: tokens.border)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: foreground),
      ),
    );
    final onTap = this.onTap;
    if (onTap == null) return chip;
    // A 44 px target around the small pill.
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: SizedBox(height: AppSizes.touchTarget, child: Center(child: chip)),
      ),
    );
  }
}

/// The offline orders and logged actions the server refused, with why: the
/// cashier can't fix them; a supervisor clears them (ADR-0026).
Future<void> showRefusedOrders(BuildContext context, QueueStatus queue) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      final tokens = context.tokens;
      final locale = Localizations.localeOf(context).toLanguageTag();
      return AlertDialog(
        title: Text(l10n.offlineRefusedTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.offlineRefusedBody, style: TextStyle(color: tokens.textSecondary)),
                for (final row in [
                  for (final order in queue.refused)
                    l10n.offlineRefusedRow(
                      order.localNumber,
                      DateFormat.Hm(locale).format(order.soldAt),
                      offlineRefusalMessage(l10n, order.error),
                    ),
                  for (final action in queue.refusedActions)
                    l10n.offlineRefusedActionRow(
                      switch (action.kind) {
                        QueuedActionKind.reprint => l10n.actionReprint,
                        QueuedActionKind.leftUnprinted => l10n.ticketLeftUnprinted,
                      },
                      '${action.gateCode}',
                      DateFormat.Hm(locale).format(action.at),
                      offlineRefusalMessage(l10n, action.error),
                    ),
                ]) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: tokens.inset,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(row),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.close),
          ),
        ],
      );
    },
  );
}
