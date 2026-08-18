import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The chevron + numbered-window paginator for the server-paged card lists.
///
/// Replaces three byte-identical `_buildPaginationControls` / `_buildPageNumbers`
/// pairs that lived in the HR-letter, advance-on-salary and disciplinary content
/// widgets. The visuals are unchanged; two behaviours are not, and both are
/// forced by server paging:
///
///  * [totalPages] derives from the server's total row count, not from the
///    length of the list in memory — which is now one page.
///  * every control is disabled while [isLoading], because a second tap during
///    an in-flight fetch would queue a page the user never sees settle.
class PagedRequestsPaginationControls extends StatelessWidget {
  const PagedRequestsPaginationControls({
    super.key,
    required this.page,
    required this.totalCount,
    required this.pageSize,
    required this.onPageChanged,
    this.isLoading = false,
  });

  /// 0-based.
  final int page;

  /// Rows across ALL pages, from the server.
  final int totalCount;

  final int pageSize;

  /// Receives a 0-based page index.
  final ValueChanged<int> onPageChanged;

  final bool isLoading;

  /// Never zero, so "page 1 of 1" reads correctly on an empty list.
  int get totalPages => totalCount == 0 ? 1 : (totalCount / pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(l10n.pageOfPages(page + 1, totalPages), style: const TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            IconButton(
              onPressed: (!isLoading && page > 0) ? () => onPageChanged(page - 1) : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: l10n.previousPage,
            ),
            ..._buildPageNumbers(context),
            IconButton(
              onPressed: (!isLoading && page < totalPages - 1) ? () => onPageChanged(page + 1) : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: l10n.nextPage,
            ),
          ],
        ),
      ),
    );
  }

  /// A window of ±2 pages around the current one.
  List<Widget> _buildPageNumbers(BuildContext context) {
    final pages = <Widget>[];
    final start = (page - 2).clamp(0, totalPages - 1);
    final end = (page + 2).clamp(0, totalPages - 1);

    for (var i = start; i <= end; i++) {
      pages.add(
        TextButton(
          onPressed: isLoading ? null : () => onPageChanged(i),
          style: TextButton.styleFrom(
            backgroundColor: i == page ? Theme.of(context).primaryColor : null,
            foregroundColor: i == page ? Colors.white : Theme.of(context).primaryColor,
          ),
          child: Text('${i + 1}'),
        ),
      );
    }
    return pages;
  }
}
