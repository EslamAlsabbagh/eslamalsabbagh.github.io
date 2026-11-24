import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';

/// A warning or error in place of a screen's content, with an optional retry
/// (or another action, named by [actionLabel]).
class MessageBox extends StatelessWidget {
  const MessageBox.warning({super.key, required this.message, this.onRetry, this.actionLabel})
      : danger = false;

  const MessageBox.danger({super.key, required this.message, this.onRetry, this.actionLabel})
      : danger = true;

  final String message;
  final VoidCallback? onRetry;

  /// Defaults to "Try again".
  final String? actionLabel;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final background = danger ? tokens.dangerBg : tokens.warningBg;
    final foreground = danger ? tokens.dangerText : tokens.warningText;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: danger ? null : Border.all(color: tokens.warningBorder),
        ),
        child: Row(
          children: [
            Expanded(child: Text(message, style: TextStyle(fontSize: 15, color: foreground))),
            if (onRetry != null) ...[
              const SizedBox(width: 12),
              OutlinedButton(onPressed: onRetry, child: Text(actionLabel ?? l10n.retry)),
            ],
          ],
        ),
      ),
    );
  }
}
