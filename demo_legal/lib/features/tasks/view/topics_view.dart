import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/format/app_formats.dart';
import '../../../core/format/arabic_count.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/name_target.dart';
import '../bloc/tasks_bloc.dart';
import '../data/task_list_item.dart';
import 'task_drawer.dart';
import 'widgets/card_grid.dart';
import 'widgets/empty_section.dart';
import 'widgets/file_section_header.dart';
import 'widgets/name_dialog.dart';
import 'widgets/topic_card.dart';

/// View 2, «المواضيع»: a section per file (the selected chip's only), each
/// with a grid of topic cards. A compact row opens the task drawer.
///
/// Everyone adds, renames and deletes (when empty) topics here; RLS shows a
/// lawyer only their files, and lets them manage topics there. Managers and
/// admins also rename and delete files (spec §4 "Managing files and topics");
/// «+ ملف جديد» is on the chip row.
class TopicsView extends StatelessWidget {
  const TopicsView({super.key, this.clock = DateTime.now});

  /// "Now" for the drawer's update times; injectable for tests.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final groups = context.select((TasksBloc bloc) => bloc.state.topicGroups);
    final canManageFiles = context.select((AuthBloc bloc) => bloc.state.profile?.role.managesFiles ?? false);
    void open(TaskListItem task) => showTaskDrawer(context, task, clock: clock);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 32,
      children: [
        for (final group in groups)
          _FileSection(
            key: Key('topics-file-${group.file.id}'),
            group: group,
            onOpen: open,
            canManageFiles: canManageFiles,
          ),
      ],
    );
  }
}

/// The file's title and summary over a 2px ink line, then its cards.
class _FileSection extends StatelessWidget {
  const _FileSection({super.key, required this.group, required this.onOpen, required this.canManageFiles});

  final FileTopics group;
  final ValueChanged<TaskListItem> onOpen;

  /// Shows the file's «تعديل». The cards' pencils and the «+ موضوع جديد»
  /// card are for everyone.
  final bool canManageFiles;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final file = group.file;
    final addCard = _NewTopicCard(fileName: file.name, onTap: () => openNameDialog(context, NewTopic(file)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        FileSectionHeader(
          title: file.name,
          caption: _summary(l10n, group),
          trailing: canManageFiles
              ? _RenameFileButton(
                  fileName: file.name,
                  onPressed: () => openNameDialog(context, RenameFile(file, canDelete: group.topics.isEmpty)),
                )
              : null,
        ),
        if (group.topics.isEmpty)
          Text(l10n.fileNoTopics, style: AppTextStyles.meta.copyWith(color: tokens.textMuted)),
        CardGrid(
          minCardWidth: 320,
          gap: 12,
          trailing: addCard,
          children: [
            for (final summary in group.topics)
              TopicCard(
                key: Key('topic-${summary.topic.id}'),
                summary: summary,
                onOpen: onOpen,
                onRename: () => openNameDialog(
                  context,
                  RenameTopic(summary.topic, file, canDelete: summary.taskCount == 0),
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// «موضوعان · ٤ مهام مفتوحة · ٢ عاجلة»; the urgent part only when above 0.
  static String _summary(AppLocalizations l10n, FileTopics group) {
    final topics = group.topics.length;
    final open = group.openCount;
    final urgent = group.urgentCount;
    return [
      topics == 0
          ? l10n.topicCountZero
          : arabicCount(
              topics,
              one: l10n.topicCountOne,
              two: l10n.topicCountTwo,
              few: l10n.topicCountFew,
              many: l10n.topicCountMany,
            ),
      open == 0
          ? l10n.openTaskCountZero
          : arabicCount(
              open,
              one: l10n.openTaskCountOne,
              two: l10n.openTaskCountTwo,
              few: l10n.openTaskCountFew,
              many: l10n.openTaskCountMany,
            ),
      if (urgent > 0) l10n.urgentCountLabel(AppFormats.number(urgent)),
    ].join(' · ');
  }
}

/// «تعديل» at the end of a file's title row: a quiet pencil-and-word button
/// with a 44px target, like the drawer's. Screen readers hear the file name.
class _RenameFileButton extends StatelessWidget {
  const _RenameFileButton({required this.fileName, required this.onPressed});

  final String fileName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.editFileSemantics(fileName),
      excludeSemantics: true,
      onTap: onPressed,
      child: TextButton.icon(
        key: const Key('rename-file'),
        onPressed: onPressed,
        icon: const Icon(Icons.edit_outlined, size: 18),
        label: Text(l10n.editName),
        style: TextButton.styleFrom(
          foregroundColor: tokens.ink,
          textStyle: AppTextStyles.button,
          minimumSize: const Size(0, AppSpacing.touchTarget),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
        ),
      ),
    );
  }
}

/// «+ موضوع جديد»: a dashed `borderStrong` box with no fill at the end of a
/// file's grid, at least 88 high and as tall as its row.
class _NewTopicCard extends StatelessWidget {
  const _NewTopicCard({required this.fileName, required this.onTap});

  final String fileName;
  final VoidCallback onTap;

  static const double _minHeight = 88;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(AppRadii.card);
    return Semantics(
      container: true,
      button: true,
      label: l10n.newTopicSemantics(fileName),
      excludeSemantics: true,
      onTap: onTap,
      child: CustomPaint(
        painter: DashedBorderPainter(color: tokens.borderStrong, radius: AppRadii.card),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            key: const Key('new-topic'),
            borderRadius: radius,
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minHeight),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Icon(Icons.add, size: 18, color: tokens.textMuted),
                    Text(l10n.newTopicCard, style: AppTextStyles.button.copyWith(color: tokens.textMuted)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
