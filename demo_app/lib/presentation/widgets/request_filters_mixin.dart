import 'dart:async';

import 'package:flutter/material.dart';

/// Mixin that provides common filter state variables and management
/// for request pages (leave, overtime, business trip, missing punch, etc.)
///
/// Usage:
/// ```dart
/// class MyRequestsContent extends StatefulWidget {
///   // ...
/// }
///
/// class _MyRequestsContentState extends State<MyRequestsContent>
///     with RequestFiltersMixin<MyRequestsContent> {
///   // ...
/// }
/// ```
///
/// Pages that filter server-side additionally override [onFiltersChanged] to
/// re-issue their query. Pages that filter client-side ignore it and keep
/// working off the `setState` alone, which is why the hook defaults to a no-op.
mixin RequestFiltersMixin<T extends StatefulWidget> on State<T> {
  /// Current search query
  String get searchQuery => _searchQuery;
  String _searchQuery = '';

  /// Current status filter ('all', 'pending', 'approved', etc.)
  String get statusFilter => _statusFilter;
  String _statusFilter = 'all';

  /// Currently selected month (null means all months)
  DateTime? get selectedMonth => _selectedMonth;
  DateTime? _selectedMonth;

  /// Whether to show processed requests instead of actionable requests
  bool get showProcessedRequests => _showProcessedRequests;
  bool _showProcessedRequests = false;

  /// Track previous filter state to detect changes
  String _previousSearchQuery = '';
  String _previousStatusFilter = 'all';
  DateTime? _previousSelectedMonth;

  /// Counter to track filter changes for table key
  int _filterChangeCounter = 0;

  /// Gets a unique key for the data table based on filter changes
  /// This key changes whenever filters are updated, forcing the table to reset to page 1
  Key get tableKey => ValueKey('table_$_filterChangeCounter');

  /// Check if filters have changed since last check
  bool get hasFiltersChanged {
    final changed =
        _previousSearchQuery != _searchQuery ||
        _previousStatusFilter != _statusFilter ||
        _previousSelectedMonth != _selectedMonth;

    if (changed) {
      _previousSearchQuery = _searchQuery;
      _previousStatusFilter = _statusFilter;
      _previousSelectedMonth = _selectedMonth;
    }

    return changed;
  }

  /// Called after any filter changes. Default is a no-op — override it on
  /// pages that filter server-side to re-issue the query.
  ///
  /// For [updateSearchQuery] this fires after [searchDebounce] rather than on
  /// every keystroke; the other filters are discrete choices, so they fire
  /// immediately.
  void onFiltersChanged() {}

  /// How long to wait after the last keystroke before [onFiltersChanged] fires.
  Duration get searchDebounce => const Duration(milliseconds: 350);

  Timer? _searchDebounceTimer;

  /// Updates the search query and triggers a rebuild
  void updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query;
      _filterChangeCounter++; // Increment to reset table pagination
    });
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(searchDebounce, () {
      if (mounted) onFiltersChanged();
    });
  }

  /// Updates the status filter and triggers a rebuild
  void updateStatusFilter(String status) {
    setState(() {
      _statusFilter = status;
      _filterChangeCounter++; // Increment to reset table pagination
    });
    onFiltersChanged();
  }

  /// Updates the selected month and triggers a rebuild
  void updateSelectedMonth(DateTime? month) {
    setState(() {
      _selectedMonth = month;
      _filterChangeCounter++; // Increment to reset table pagination
    });
    onFiltersChanged();
  }

  /// Toggles between processed and actionable requests.
  ///
  /// Notifies, because for server-filtered pages this switches which list is
  /// being queried, not just how it is displayed.
  void toggleProcessedRequests(bool showProcessed) {
    setState(() {
      _showProcessedRequests = showProcessed;
    });
    onFiltersChanged();
  }

  /// Switches between the Actionable and Processed tabs.
  ///
  /// Prefer this over calling [resetFilters] and [toggleProcessedRequests]
  /// yourself: [resetFilters] also clears [showProcessedRequests], so the two
  /// only work in one order, and getting it backwards makes the tab snap
  /// straight back to Actionable. Doing it here means no call site can.
  ///
  /// Fires [onFiltersChanged] exactly once, for the tab being switched TO.
  void switchProcessedTab(bool showProcessed) {
    resetFilters(notify: false);
    toggleProcessedRequests(showProcessed);
  }

  /// Resets all filters to their default values.
  ///
  /// Note this also clears [showProcessedRequests] — see [switchProcessedTab].
  ///
  /// Pass `notify: false` when another call is about to fire
  /// [onFiltersChanged] anyway — it suppresses a redundant fetch against the
  /// tab being navigated away from.
  void resetFilters({bool notify = true}) {
    // Cancel first: a debounce still in flight would otherwise fire moments
    // later with the pre-reset query and undo this.
    _searchDebounceTimer?.cancel();
    setState(() {
      _searchQuery = '';
      _statusFilter = 'all';
      _selectedMonth = null;
      _showProcessedRequests = false;
      _filterChangeCounter++; // Increment to reset table pagination
    });
    if (notify) onFiltersChanged();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  /// Helper method to check if any filters are active
  bool get hasActiveFilters => _searchQuery.isNotEmpty || _statusFilter != 'all' || _selectedMonth != null;
}
