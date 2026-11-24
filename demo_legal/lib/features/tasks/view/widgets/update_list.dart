import 'package:flutter/material.dart';

import '../../../../core/format/relative_time.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/task_update_entry.dart';
import 'person_avatar.dart';
import 'stored_text.dart';

/// «التحديثات», newest first: avatar, name, relative time, text, then a
/// separator. Each text reads in its own direction, so an English note runs
/// left to right. Updates are never edited or deleted (ADR-0003).
class UpdateList extends StatelessWidget {
  const UpdateList({super.key, required this.updates, required this.now});

  final List<TaskUpdateEntry> updates;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);

    if (updates.isEmpty) {
      return Text(l10n.drawerNoUpdates, style: AppTextStyles.meta.copyWith(color: tokens.textMuted));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        for (final update in updates)
          Row(
            key: ValueKey('update-${update.id}'),
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              PersonAvatar(userId: update.authorId, name: update.authorName, size: 30),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: tokens.dividerSubtle)),
                  ),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 12 + 1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 2,
                      children: [
                        Wrap(
                          spacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            Text(
                              update.authorName ?? l10n.formerEmployee,
                              style: AppTextStyles.button.copyWith(color: tokens.ink),
                            ),
                            Text(
                              RelativeTime.format(l10n, update.createdAt, now: now),
                              style: AppTextStyles.badge.copyWith(
                                fontWeight: FontWeight.w400,
                                color: tokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                        StoredText(
                          update.body,
                          style: AppTextStyles.body.copyWith(fontSize: 14, height: 1.7, color: tokens.ink),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
