import 'package:flutter/widgets.dart';

import '../../core/theme/app_dimens.dart';

/// Centers [child] at the design's max content width with side padding.
class ContentFrame extends StatelessWidget {
  const ContentFrame({
    super.key,
    required this.child,
    this.top = 0,
    this.bottom = 0,
  });

  final Widget child;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpacing.contentMaxWidth),
        child: Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            AppSpacing.sidePadding,
            top,
            AppSpacing.sidePadding,
            bottom,
          ),
          // Fill the column so start-aligned content sits on the start edge.
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}
