import 'package:flutter/material.dart';

import '../../../../core/format/app_formats.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/task_file.dart';

/// «كل الملفات» plus one chip per file, each with a count: open tasks, or on
/// «العقود» the contracts the list shows (DESIGN_SPEC §4 View 4).
/// Scrolls sideways when the chips don't fit.
class FileChips extends StatelessWidget {
  const FileChips({
    super.key,
    required this.files,
    required this.selectedFileId,
    required this.countFor,
    required this.onSelected,
  });

  final List<TaskFile> files;
  final String? selectedFileId;
  final int Function(String? fileId) countFor;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget chip(String? id, String label) => _FileChip(
          key: Key('file-chip-${id ?? 'all'}'),
          label: label,
          count: countFor(id),
          selected: selectedFileId == id,
          onTap: () => onSelected(id),
        );

    return Semantics(
      label: l10n.fileFilterLabel,
      container: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsetsDirectional.only(bottom: 4),
        child: Row(
          spacing: 8,
          children: [
            chip(null, l10n.allFiles),
            for (final file in files) chip(file.id, file.name),
          ],
        ),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({
    super.key,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final fg = selected ? tokens.surface : tokens.ink;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      side: BorderSide(color: selected ? tokens.ink : tokens.chipBorder),
    );

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? tokens.ink : tokens.surface,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.chipHeight),
            child: Padding(
              // 14 + the 1px border, which the Material shape doesn't lay out.
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 15),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  Text(label, style: AppTextStyles.body.copyWith(fontSize: 14, color: fg)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: selected ? tokens.surface.withValues(alpha: 0.18) : tokens.mutedFill,
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(horizontal: 7),
                      child: Text(
                        AppFormats.number(count),
                        style: AppTextStyles.badge.copyWith(
                          color: selected ? tokens.surface : tokens.onMutedFill,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
