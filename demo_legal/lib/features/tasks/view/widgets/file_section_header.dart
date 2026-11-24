import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import 'section_header.dart';

/// A file's section title (20px) and summary over a 2px ink line, as on
/// «المواضيع» and «العقود». [trailing] (the file's «تعديل») sits at the
/// line's `end`, bottom-aligned.
class FileSectionHeader extends StatelessWidget {
  const FileSectionHeader({super.key, required this.title, this.caption, this.trailing});

  final String title;
  final String? caption;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    final header = SectionHeader(title: title, titleStyle: AppTextStyles.fileGroupTitle, caption: caption);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: BorderDirectional(bottom: BorderSide(color: context.tokens.ink, width: 2)),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(bottom: trailing != null ? 2 : 8),
        child: trailing != null
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 12,
                children: [
                  Expanded(child: Padding(padding: const EdgeInsetsDirectional.only(bottom: 6), child: header)),
                  trailing,
                ],
              )
            : header,
      ),
    );
  }
}
