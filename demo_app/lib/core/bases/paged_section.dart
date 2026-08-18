import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:equatable/equatable.dart';

/// The page window a BLoC owns for one server-paginated card list, plus the
/// last page it fetched.
///
/// The table-based screens (leave, business trip, missing punch, overtime) do
/// not need this: `AsyncPaginatedDataTable2` keeps the window inside its own
/// `AsyncDataTableSource`, so their blocs carry no page state at all. The card
/// lists have no such component, so the window lives here instead — one field
/// on the state rather than six loose ones.
class PagedSection<T> extends Equatable {
  const PagedSection({
    this.items = const [],
    this.totalCount = 0,
    this.hasActionable = false,
    this.page = 0,
    this.pageSize = 10,
    this.isPageLoading = false,
    this.pageFailure,
  });

  /// The rows of the current page only.
  final List<T> items;

  /// Rows matching the query across ALL pages — deliberately not `items.length`.
  /// The paginator is sized from this, so it must stay correct even when
  /// [items] is empty because the window ran past the end.
  final int totalCount;

  /// Server-computed over the whole filtered set: does any row have an action
  /// available? Computed server-side so it cannot flicker as the user pages
  /// through rows that happen not to be actionable.
  final bool hasActionable;

  /// 0-based. Replaces the widgets' old `_currentPage`.
  final int page;

  /// Replaces the widgets' old `_itemsPerPage`.
  final int pageSize;

  /// A page fetch is in flight.
  ///
  /// Deliberately NOT the screen-level `Status.loading`: that branch blanks the
  /// whole page and remounts it on the way back, which loses scroll position
  /// and hides the per-row spinner of whatever mutation triggered the refetch.
  /// This flag is meant to disable the paginator chevrons and nothing else.
  final bool isPageLoading;

  /// Set when the last page fetch failed. Separate from the state's screen-level
  /// `failure` so a transient page error does not look like the screen died.
  final Failure? pageFailure;

  int get offset => page * pageSize;

  /// Never zero, so "page 1 of 1" reads correctly on an empty list.
  int get totalPages => totalCount == 0 ? 1 : (totalCount / pageSize).ceil();

  int get lastPageIndex => totalPages - 1;

  bool get isEmpty => items.isEmpty;

  /// Drops the current rows because the query they answer has changed.
  ///
  /// Use when the SCOPE or the FILTERS change — the rows on screen answer a
  /// different question, and leaving a Team row visible under the Processed tab
  /// is worse than showing nothing, not least because the card renders actions
  /// belonging to the scope it came from. This is the card-list equivalent of
  /// `AsyncDataTableSource.isStale` on the table screens, which hides rows
  /// whenever `_renderedQuery != _query`.
  ///
  /// Deliberately NOT used for a page turn or a post-mutation refresh: there the
  /// query is unchanged, the rows are still valid answers, and keeping them
  /// avoids the list collapsing and reflowing under the user.
  ///
  /// [isPageLoading] is set in the same step, so the empty state cannot flash
  /// between clearing the rows and the fetch that replaces them. [pageSize] is
  /// preserved because it belongs to the viewer, not to the query.
  PagedSection<T> resetForQuery() => PagedSection<T>(
    items: const [],
    totalCount: 0,
    hasActionable: false,
    page: 0,
    pageSize: pageSize,
    isPageLoading: true,
  );

  /// Applies a fetched page.
  ///
  /// Keeps [page] and [pageSize] — the caller owns the window, and the response
  /// carries no opinion about which page it answers.
  PagedSection<T> withResult(PagedResult<T> result) => copyWith(
    items: result.items,
    totalCount: result.totalCount,
    hasActionable: result.hasActionable,
    isPageLoading: false,
    clearPageFailure: true,
  );

  PagedSection<T> copyWith({
    List<T>? items,
    int? totalCount,
    bool? hasActionable,
    int? page,
    int? pageSize,
    bool? isPageLoading,
    Failure? pageFailure,
    bool clearPageFailure = false,
  }) {
    return PagedSection<T>(
      items: items ?? this.items,
      totalCount: totalCount ?? this.totalCount,
      hasActionable: hasActionable ?? this.hasActionable,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      isPageLoading: isPageLoading ?? this.isPageLoading,
      // `??` cannot express "set to null", and clearing the error on a
      // successful refetch is the common case — hence the explicit flag.
      pageFailure: clearPageFailure ? null : (pageFailure ?? this.pageFailure),
    );
  }

  @override
  List<Object?> get props => [items, totalCount, hasActionable, page, pageSize, isPageLoading, pageFailure];
}
