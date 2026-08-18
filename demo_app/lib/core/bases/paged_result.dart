/// One page of a server-paginated list, plus the aggregates that describe the
/// *whole* result set rather than just this page.
///
/// The distinction matters: with client-side paging the widget could ask the
/// in-memory list anything it liked (how many rows in total, does any row have
/// an action). Once only one page is in memory those answers have to come from
/// the server, so they travel with the page.
class PagedResult<T> {
  const PagedResult({required this.items, required this.totalCount, this.hasActionable = false});

  const PagedResult.empty() : items = const [], totalCount = 0, hasActionable = false;

  /// The rows for the requested `[offset, offset + limit)` window.
  final List<T> items;

  /// Rows matching the query across ALL pages — deliberately not
  /// `items.length`. `AsyncPaginatedDataTable2` needs this to size its
  /// paginator, and it must stay correct even when [items] is empty because the
  /// caller asked for a page past the end.
  final int totalCount;

  /// Server-computed flag over the whole filtered set: does any row have an
  /// action available? Computed server-side so it cannot flicker as the user
  /// pages through rows that happen not to be actionable.
  final bool hasActionable;

  bool get isEmpty => items.isEmpty;
}
