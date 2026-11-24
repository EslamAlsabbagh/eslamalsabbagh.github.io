import 'package:flutter/material.dart';

import '../../../../core/format/arabic_count.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// The line under a search field (DESIGN_SPEC §4 "Search"): «٣ نتائج لـ "عقد"»,
/// or the error line when the search failed. Shared by «اليوم» and «العقود».
class SearchStatusLine extends StatelessWidget {
  const SearchStatusLine({super.key, required this.failed, required this.count, required this.term});

  final bool failed;

  /// The matches shown; at least 1 unless [failed].
  final int count;

  /// The term the count belongs to.
  final String term;

  /// Whether a line shows at all: a failure, or at least one match. Zero
  /// matches show an empty box in the view instead.
  static bool shows({required bool failed, required int? count}) => failed || (count != null && count > 0);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);

    if (failed) {
      return Row(
        key: const Key('search-error'),
        spacing: 6,
        children: [
          Icon(Icons.error_outline, size: 18, color: tokens.overdue),
          Expanded(
            child: Text(
              l10n.searchError,
              style: AppTextStyles.fieldLabel.copyWith(color: tokens.overdue),
            ),
          ),
        ],
      );
    }

    return Text(
      key: const Key('search-count'),
      arabicCount(
        count,
        one: l10n.searchResultOne(term),
        two: l10n.searchResultTwo(term),
        few: (count) => l10n.searchResultsFew(count, term),
        many: (count) => l10n.searchResultsMany(count, term),
      ),
      style: AppTextStyles.meta.copyWith(color: tokens.textMuted),
    );
  }
}
