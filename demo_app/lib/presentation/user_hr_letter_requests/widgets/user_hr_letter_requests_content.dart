import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/request_month_utils.dart';
import 'package:hrms_demo/data/models/hr_letter_request_model.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_requests_query.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/user_hr_letter_requests/bloc/user_hr_letter_requests_bloc.dart';
import 'package:hrms_demo/presentation/user_hr_letter_requests/bloc/user_hr_letter_requests_event.dart';
import 'package:hrms_demo/presentation/user_hr_letter_requests/bloc/user_hr_letter_requests_state.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:hrms_demo/presentation/widgets/paged_requests_pagination_controls.dart';
import 'package:hrms_demo/presentation/widgets/request_filters_mixin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class UserHrLetterRequestsContent extends StatefulWidget {
  final HrLetterRequestSourceType sourceType;

  const UserHrLetterRequestsContent({super.key, required this.sourceType});

  @override
  State<UserHrLetterRequestsContent> createState() => _UserHrLetterRequestsContentState();
}

class _UserHrLetterRequestsContentState extends State<UserHrLetterRequestsContent>
    with RequestFiltersMixin<UserHrLetterRequestsContent> {
  /// LEGACY page index. On the paged path the window lives in the bloc's
  /// `PagedSection`, because only the server knows how many pages there are.
  int _currentPage = 0;

  /// Page size. Shared by both paths — the paged one forwards it to the bloc.
  int _itemsPerPage = 10;

  // Sorting
  String _sortBy = 'createdAt';
  bool _sortAscending = false;

  bool get _isTeamRequests => widget.sourceType == HrLetterRequestSourceType.teamRequests;

  // ── Server-paged query plumbing ────────────────────────────────────────────

  /// The tab the user is on, as the server understands it. My-requests has no
  /// tabs; the team page toggles between the HR queue and the processed list.
  HrLetterRequestScope get _effectiveScope {
    if (!_isTeamRequests) return HrLetterRequestScope.my;
    return showProcessedRequests ? HrLetterRequestScope.processed : HrLetterRequestScope.team;
  }

  HrLetterRequestsQuery _buildQuery() => HrLetterRequestsQuery(
    scope: _effectiveScope,
    search: searchQuery,
    status: statusFilter,
    month: selectedMonth,
    sortKey: _sortBy == 'status' ? HrLetterRequestSortKey.status : HrLetterRequestSortKey.createdAt,
    sortAscending: _sortAscending,
    // Carried for symmetry with the other list RPCs. HR-letter search matches
    // both name columns regardless of locale, so there is deliberately no
    // post-frame re-query when the app language changes — it would refetch
    // without changing a single row.
    locale: Localizations.localeOf(context).languageCode,
  );

  /// Re-issues the query. The bloc drops it if nothing actually changed and
  /// resets to page 1 if it did.
  void _applyQuery() {
    if (!FeatureFlags.serverPagedHrLetterRequests) return;
    context.read<UserHrLetterRequestsBloc>().add(HrLetterQueryChanged(_buildQuery()));
  }

  /// Fires after every filter change made through [RequestFiltersMixin] —
  /// debounced for search, immediate for the discrete filters.
  @override
  void onFiltersChanged() => _applyQuery();

  // ── Legacy client-side filtering (flag off) ────────────────────────────────

  List<HrLetterRequestModel> get _filteredAndSorted {
    final bloc = context.read<UserHrLetterRequestsBloc>();
    List<HrLetterRequestModel> filtered = List.from(bloc.state.requests);

    // Tab filter — only applies to team requests; my requests shows all statuses
    if (_isTeamRequests) {
      if (!showProcessedRequests) {
        // Only show actionable and not self-created requests
        final userCode = context.read<UserBloc>().state.user?.id ?? 0;
        filtered = filtered.where((r) => r.isActionable && r.employeeCode != userCode).toList();
      } else {
        filtered = filtered.where((r) => r.isCompleted || r.isDeclined || r.isCancelled).toList();
      }
    }

    // Search
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      filtered =
          filtered.where((r) {
            return (r.employeeEnglishName?.toLowerCase().contains(q) ?? false) ||
                (r.employeeArabicName?.toLowerCase().contains(q) ?? false) ||
                ((r.employeeCode ?? 0) - 10000000).toString().contains(q) ||
                (r.nationalId?.toLowerCase().contains(q) ?? false) ||
                (r.letterPurpose?.toLowerCase().contains(q) ?? false);
          }).toList();
    }

    // Status filter
    if (statusFilter != 'all') {
      filtered = filtered.where((r) => r.status == statusFilter).toList();
    }

    // Month filter
    if (selectedMonth != null) {
      filtered =
          filtered.where((r) {
            return r.createdAt != null &&
                r.createdAt!.year == selectedMonth!.year &&
                r.createdAt!.month == selectedMonth!.month;
          }).toList();
    }

    // Sort
    filtered.sort((a, b) {
      int result = 0;
      switch (_sortBy) {
        case 'createdAt':
          result = (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());
          break;
        case 'status':
          result = (a.status ?? '').compareTo(b.status ?? '');
          break;
        default:
          result = (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());
      }
      return _sortAscending ? result : -result;
    });

    return filtered;
  }

  List<HrLetterRequestModel> get _paginated {
    final all = _filteredAndSorted;
    final start = _currentPage * _itemsPerPage;
    if (start >= all.length) return [];
    final end = (start + _itemsPerPage).clamp(0, all.length);
    return all.sublist(start, end);
  }

  int get _totalPages {
    final count = _filteredAndSorted.length;
    return (count / _itemsPerPage).ceil();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: BlocListener<UserHrLetterRequestsBloc, UserHrLetterRequestsState>(
        listener: (context, state) {
          if (state.acknowledgeStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestAcknowledgedSuccessfully)));
            context.read<UserHrLetterRequestsBloc>().add(const ResetAcknowledgeHrLetterStatus());
          } else if (state.acknowledgeStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(
                    context,
                  )!.failedToAcknowledgeHrLetterRequest(state.operationFailure?.message ?? ''),
                ),
              ),
            );
            context.read<UserHrLetterRequestsBloc>().add(const ResetAcknowledgeHrLetterStatus());
          }

          if (state.completeStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestCompletedSuccessfully)));
            context.read<UserHrLetterRequestsBloc>().add(const ResetCompleteHrLetterStatus());
          } else if (state.completeStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.failedToCompleteRequest(state.operationFailure?.message ?? ''),
                ),
              ),
            );
            context.read<UserHrLetterRequestsBloc>().add(const ResetCompleteHrLetterStatus());
          }

          if (state.declineStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestDeclinedSuccessfully)));
            context.read<UserHrLetterRequestsBloc>().add(const ResetDeclineHrLetterStatus());
          } else if (state.declineStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.failedToDeclineHrLetterRequest(state.operationFailure?.message ?? ''),
                ),
              ),
            );
            context.read<UserHrLetterRequestsBloc>().add(const ResetDeclineHrLetterStatus());
          }

          if (state.cancelStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestCancelledSuccessfully)));
            context.read<UserHrLetterRequestsBloc>().add(const ResetCancelHrLetterStatus());
          } else if (state.cancelStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.failedToCancelHrLetterRequest(state.operationFailure?.message ?? ''),
                ),
              ),
            );
            context.read<UserHrLetterRequestsBloc>().add(const ResetCancelHrLetterStatus());
          }
        },
        child: SingleChildScrollView(
          child: BlocBuilder<UserHrLetterRequestsBloc, UserHrLetterRequestsState>(
            builder: (context, state) {
              // On the paged path the months come from the server: deriving
              // them from the rows in memory would offer only the months that
              // happen to appear on the current page.
              final availableMonths =
                  FeatureFlags.serverPagedHrLetterRequests
                      ? state.availableMonths.toSet()
                      : RequestMonthUtils.calculateAvailableMonths(state.requests.map((r) => r.createdAt).toList());
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: context.screenWidth > 1168 ? context.screenWidth * 0.95 : 1105,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 16),
                        _buildTabsAndFilters(context, state, availableMonths),
                        const SizedBox(height: 16),
                        if (state.status == Status.loading)
                          const Center(child: CircularProgressIndicator())
                        else if (state.status == Status.failure)
                          Center(
                            child: Text(
                              state.failure?.message ?? 'Error loading requests',
                              style: TextStyle(color: Colors.red[600]),
                            ),
                          )
                        else
                          _buildRequestList(context, state),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Icon(Icons.article_outlined, color: Theme.of(context).primaryColor, size: 24),
        const SizedBox(width: 12),
        Text(
          _isTeamRequests ? l10n.teamHrLetterRequests : l10n.myHrLetterRequests,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
        ),
      ],
    );
  }

  Widget _buildTabsAndFilters(BuildContext context, UserHrLetterRequestsState state, Set<DateTime> availableMonths) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Tabs — only shown for team requests
            if (_isTeamRequests) ...[
              Row(
                children: [
                  Text(l10n.viewRequests, style: const TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 16),
                  SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: false,
                        label: Text(l10n.actionable),
                        icon: const Icon(Icons.pending_actions),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text(l10n.processed),
                        icon: const Icon(Icons.check_circle_outline),
                      ),
                    ],
                    selected: {showProcessedRequests},
                    onSelectionChanged: (Set<bool> selection) {
                      // switchProcessedTab resets the filters and toggles the
                      // tab in the one order that works, then fires
                      // onFiltersChanged exactly once — for the tab being
                      // switched TO. On the paged path that re-reads the scope
                      // (months, empty-state probe) and its first page.
                      _currentPage = 0;
                      switchProcessedTab(selection.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Filters row
            Row(
              children: [
                // Search
                if (_isTeamRequests)
                  Expanded(
                    flex: 3,
                    child: TextField(
                      // Debounced by the mixin (350 ms), so typing does not
                      // issue one server query per keystroke.
                      onChanged: (v) {
                        _currentPage = 0;
                        updateSearchQuery(v);
                      },
                      decoration: InputDecoration(
                        hintText: l10n.searchByNameOrNationalId,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ),
                if (_isTeamRequests) const SizedBox(width: 16),
                // Status dropdown
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: statusFilter,
                    decoration: InputDecoration(
                      labelText: l10n.status,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(l10n.allStatus)),
                      DropdownMenuItem(value: 'pending', child: Text(l10n.pending)),
                      DropdownMenuItem(value: 'acknowledged', child: Text(l10n.acknowledged)),
                      DropdownMenuItem(value: 'completed', child: Text(l10n.completed)),
                      DropdownMenuItem(value: 'declined', child: Text(l10n.declined)),
                      DropdownMenuItem(value: 'cancelled', child: Text(l10n.cancelled)),
                    ],
                    onChanged: (v) {
                      _currentPage = 0;
                      updateStatusFilter(v ?? 'all');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Month picker
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () async {
                      final picked = await _showMonthYearPicker(context, availableMonths);
                      if (picked != null) {
                        _currentPage = 0;
                        updateSelectedMonth(picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l10n.month,
                        suffixIcon:
                            selectedMonth != null
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _currentPage = 0;
                                    updateSelectedMonth(null);
                                  },
                                )
                                : const Icon(Icons.calendar_month),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        selectedMonth != null ? DateFormat('MMM yyyy').format(selectedMonth!) : l10n.selectMonth,
                        style: TextStyle(
                          color:
                              selectedMonth != null
                                  ? Theme.of(context).textTheme.bodyLarge?.color
                                  : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Items per page
                SizedBox(
                  width: 120,
                  child: DropdownButtonFormField<int>(
                    value: _itemsPerPage,
                    decoration: InputDecoration(
                      labelText: l10n.perPage,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5')),
                      DropdownMenuItem(value: 10, child: Text('10')),
                      DropdownMenuItem(value: 25, child: Text('25')),
                      DropdownMenuItem(value: 50, child: Text('50')),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _itemsPerPage = v ?? 10;
                        _currentPage = 0;
                      });
                      if (FeatureFlags.serverPagedHrLetterRequests) {
                        context.read<UserHrLetterRequestsBloc>().add(HrLetterPageSizeChanged(_itemsPerPage));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Sort controls
                Row(
                  children: [
                    Text(l10n.sortBy, style: const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: _sortBy,
                      items: [
                        DropdownMenuItem(value: 'createdAt', child: Text(l10n.dateCreated)),
                        DropdownMenuItem(value: 'status', child: Text(l10n.status)),
                      ],
                      onChanged: (v) {
                        setState(() => _sortBy = v ?? 'createdAt');
                        // Sorting is a property of the whole result set, not of
                        // the page in memory, so it has to go back to the server.
                        _applyQuery();
                      },
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                      tooltip: _sortAscending ? l10n.ascending : l10n.descending,
                      onPressed: () {
                        setState(() => _sortAscending = !_sortAscending);
                        _applyQuery();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: l10n.refresh,
                      onPressed: () {
                        final bloc = context.read<UserHrLetterRequestsBloc>();
                        if (FeatureFlags.serverPagedHrLetterRequests) {
                          // Re-reads the page the user is on. Re-dispatching the
                          // load event instead would send them back to the
                          // Actionable tab and page 1.
                          bloc.add(const RefreshHrLetterPage());
                        } else {
                          final userCode = context.read<UserBloc>().state.user?.id ?? 0;
                          bloc.add(LoadHrLetterRequests(userCode, widget.sourceType));
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<DateTime?> _showMonthYearPicker(BuildContext context, Set<DateTime> availableMonths) async {
    final now = DateTime.now();
    final availableYears = availableMonths.map((d) => d.year).toSet();
    final selectedYear =
        selectedMonth?.year ?? (availableYears.isNotEmpty ? availableYears.reduce((a, b) => a > b ? a : b) : now.year);
    final selectedMonthValue = selectedMonth?.month;

    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext dialogContext) {
        int tempYear = selectedYear;
        int? tempMonth = selectedMonthValue;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final hasPreviousYear = availableYears.contains(tempYear - 1);
            final hasNextYear = availableYears.contains(tempYear + 1);

            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.selectMonth),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Year navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: hasPreviousYear ? () => setDialogState(() => tempYear--) : null,
                        icon: Icon(Icons.chevron_left, color: hasPreviousYear ? null : Colors.grey.shade400),
                      ),
                      Text(tempYear.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: hasNextYear ? () => setDialogState(() => tempYear++) : null,
                        icon: Icon(Icons.chevron_right, color: hasNextYear ? null : Colors.grey.shade400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Month grid
                  SizedBox(
                    width: 250,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(12, (index) {
                        final month = index + 1;
                        final isSelected = month == tempMonth;
                        final isAvailable = availableMonths.contains(DateTime(tempYear, month, 1));
                        final monthName = _getLocalizedMonthName(context, month);

                        return SizedBox(
                          width: 70,
                          height: 35,
                          child: Material(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: isAvailable ? () => setDialogState(() => tempMonth = month) : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        isSelected
                                            ? Theme.of(context).primaryColor
                                            : isAvailable
                                            ? Colors.grey.shade300
                                            : Colors.grey.shade200,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    monthName,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : isAvailable
                                              ? null
                                              : Colors.grey.shade400,
                                      fontWeight: isSelected ? FontWeight.bold : null,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed:
                      tempMonth != null ? () => Navigator.of(dialogContext).pop(DateTime(tempYear, tempMonth!)) : null,
                  child: Text(AppLocalizations.of(context)!.select),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _getLocalizedMonthName(BuildContext context, int month) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (isArabic) {
      const arabicMonths = [
        'يناير',
        'فبراير',
        'مارس',
        'أبريل',
        'مايو',
        'يونيو',
        'يوليو',
        'أغسطس',
        'سبتمبر',
        'أكتوبر',
        'نوفمبر',
        'ديسمبر',
      ];
      return arabicMonths[month - 1];
    }
    const englishMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return englishMonths[month - 1];
  }

  Widget _buildRequestList(BuildContext context, UserHrLetterRequestsState state) {
    if (FeatureFlags.serverPagedHrLetterRequests) return _buildPagedRequestList(context, state);

    final filtered = _filteredAndSorted;
    final paginated = _paginated;
    final l10n = AppLocalizations.of(context)!;

    if (filtered.isEmpty) return _buildEmptyState(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                l10n.showingRequestsOfTotal(paginated.length, filtered.length),
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        ...paginated.map((r) => _buildRequestCard(context, r, state)),
        if (_totalPages > 1) ...[const SizedBox(height: 16), _buildPaginationControls(context)],
      ],
    );
  }

  /// The server-paged list.
  ///
  /// Note what is NOT here: a full-height spinner while a page is in flight.
  /// The cards of the previous page stay on screen and only the paginator is
  /// disabled, so the list does not collapse and reflow on every page turn —
  /// and the card whose mutation triggered the refresh keeps its own spinner.
  Widget _buildPagedRequestList(BuildContext context, UserHrLetterRequestsState state) {
    final l10n = AppLocalizations.of(context)!;
    final paged = state.paged;

    if (paged.pageFailure != null && paged.items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(paged.pageFailure?.message ?? 'Error loading requests', style: TextStyle(color: Colors.red[600])),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => context.read<UserHrLetterRequestsBloc>().add(const RefreshHrLetterPage()),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.refresh),
              ),
            ],
          ),
        ),
      );
    }

    if (paged.items.isEmpty) {
      // While the first page is still loading there is nothing to say yet —
      // claiming "no requests found" and then filling the list reads as a bug.
      if (paged.isPageLoading) {
        return const Center(
          child: Padding(padding: EdgeInsets.symmetric(vertical: 48), child: CircularProgressIndicator()),
        );
      }
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                // The total is the server's, across all pages — not the length
                // of the list in memory, which is one page.
                l10n.showingRequestsOfTotal(paged.items.length, paged.totalCount),
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
              if (paged.isPageLoading) ...[
                const SizedBox(width: 12),
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ],
          ),
        ),
        ...paged.items.map((r) => _buildRequestCard(context, r, state)),
        if (paged.totalPages > 1) ...[
          const SizedBox(height: 16),
          PagedRequestsPaginationControls(
            page: paged.page,
            totalCount: paged.totalCount,
            pageSize: paged.pageSize,
            isLoading: paged.isPageLoading,
            onPageChanged: (page) => context.read<UserHrLetterRequestsBloc>().add(HrLetterPageChanged(page)),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(l10n.noHrLetterRequestsFound, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, HrLetterRequestModel request, UserHrLetterRequestsState state) {
    final isProcessing = state.processingRequestId == request.id;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final employeeName = request.getLocalizedEmployeeName(isArabic);
    final displayCode = request.employeeCode ?? 0;
    final l10n = AppLocalizations.of(context)!;
    final maxDetailsLength = context.screenWidth < 1168 ? 15 : 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: InkWell(
        onTap: () => _showRequestDetails(context, request, state, isProcessing),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.employee,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$employeeName ($displayCode)',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.nationalId,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.nationalId ?? '-',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(context, request),
                ],
              ),
              const Divider(),
              // Details + action buttons in one row
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        l10n.letterPurpose,
                        request.getLocalizedLetterPurpose(context),
                        Icons.description_outlined,
                      ),
                    ),
                    Expanded(
                      child: _buildDetailItem(
                        l10n.createdAt,
                        request.createdAt != null ? DateFormat('MMM dd, yyyy').format(request.createdAt!) : '-',
                        Icons.calendar_today_outlined,
                      ),
                    ),
                    if (request.isEmbassy && request.travelFromDate != null)
                      Expanded(
                        child: _buildDetailItem(
                          l10n.travelFromDate,
                          DateFormat('dd/MM/yyyy').format(request.travelFromDate!),
                          Icons.flight_takeoff_outlined,
                        ),
                      ),
                    if (request.isEmbassy && request.travelToDate != null)
                      Expanded(
                        child: _buildDetailItem(
                          l10n.travelToDate,
                          DateFormat('dd/MM/yyyy').format(request.travelToDate!),
                          Icons.flight_land_outlined,
                        ),
                      ),
                    if (request.details != null && request.details!.isNotEmpty)
                      Expanded(
                        flex: 2,
                        child: _buildDetailItem(
                          l10n.hrLetterDetails,
                          request.details!.length > maxDetailsLength
                              ? '${request.details!.substring(0, maxDetailsLength)}...'
                              : request.details!,
                          Icons.notes_outlined,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(left: 24),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: _buildActionButtons(context, request, state, isProcessing),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, HrLetterRequestModel request) {
    final color = _statusColor(request.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        request.getLocalizedStatus(context),
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'acknowledged':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor),
                softWrap: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    HrLetterRequestModel request,
    UserHrLetterRequestsState state,
    bool isProcessing,
  ) {
    final l10n = AppLocalizations.of(context)!;

    final buttons = <Widget>[];

    if (_isTeamRequests) {
      if (request.isPending) {
        buttons.add(
          _actionButton(
            label:
                isProcessing && state.acknowledgeStatus == Status.loading
                    ? l10n.acknowledging
                    : l10n.acknowledgeHrLetterRequest,
            color: Colors.blue,
            isLoading: isProcessing && state.acknowledgeStatus == Status.loading,
            onPressed: isProcessing ? null : () => _showAcknowledgeConfirmDialog(context, request),
          ),
        );
      }
      if (request.isAcknowledged) {
        buttons.add(
          _actionButton(
            label: isProcessing && state.completeStatus == Status.loading ? l10n.completing : l10n.completeRequest,
            color: Colors.green,
            isLoading: isProcessing && state.completeStatus == Status.loading,
            onPressed: isProcessing ? null : () => _showCompleteConfirmDialog(context, request),
          ),
        );
      }
      if (request.isPending || request.isAcknowledged) {
        buttons.add(
          _actionButton(
            label: isProcessing && state.declineStatus == Status.loading ? l10n.declining : l10n.decline,
            color: Colors.red,
            isLoading: isProcessing && state.declineStatus == Status.loading,
            onPressed: isProcessing ? null : () => _showDeclineDialog(context, request),
          ),
        );
      }
    } else {
      // My Requests: employee can cancel pending only
      if (request.isPending) {
        buttons.add(
          _actionButton(
            label: isProcessing && state.cancelStatus == Status.loading ? l10n.cancellingRequest : l10n.cancelRequest,
            color: Colors.red,
            isLoading: isProcessing && state.cancelStatus == Status.loading,
            onPressed: isProcessing ? null : () => _showCancelConfirmDialog(context, request),
          ),
        );
      }
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: buttons.expand((b) => [b, const SizedBox(width: 8)]).toList()..removeLast(),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required bool isLoading,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child:
          isLoading
              ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
              : Text(label),
    );
  }

  void _showDeclineDialog(BuildContext context, HrLetterRequestModel request, {bool fromDetails = false}) {
    final formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final userCode = context.read<UserBloc>().state.user?.id ?? 0;

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<UserHrLetterRequestsBloc>(),
            child: Builder(
              builder: (childContext) {
                void onSubmit() {
                  if (formKey.currentState!.validate()) {
                    context.read<UserHrLetterRequestsBloc>().add(
                      DeclineHrLetterRequest(request.id!, userCode, reasonController.text.trim()),
                    );
                    Navigator.pop(childContext);
                    if (fromDetails) Navigator.pop(context);
                  }
                }

                return AlertDialog(
                  title: Text(l10n.declineRequest),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l10n.provideDeclinereason),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: reasonController,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.pleaseEnterDeclineReason;
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => onSubmit(),
                          decoration: InputDecoration(
                            hintText: l10n.enterDeclineReason,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(childContext).pop(),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      onPressed: onSubmit,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      child: Text(l10n.decline),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  void _showAcknowledgeConfirmDialog(BuildContext context, HrLetterRequestModel request) {
    final l10n = AppLocalizations.of(context)!;
    final userCode = context.read<UserBloc>().state.user?.id ?? 0;

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<UserHrLetterRequestsBloc>(),
            child: Builder(
              builder:
                  (childContext) => AlertDialog(
                    title: Text(l10n.confirmAcknowledgeHrLetter),
                    content: Text(l10n.confirmAcknowledgeHrLetterMessage),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(childContext).pop(),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
                        child: Text(l10n.cancel),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.read<UserHrLetterRequestsBloc>().add(
                            AcknowledgeHrLetterRequest(request.id!, userCode),
                          );
                          Navigator.of(childContext).pop();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        child: Text(l10n.acknowledgeHrLetterRequest),
                      ),
                    ],
                  ),
            ),
          ),
    );
  }

  void _showCompleteConfirmDialog(BuildContext context, HrLetterRequestModel request) {
    final l10n = AppLocalizations.of(context)!;
    final userCode = context.read<UserBloc>().state.user?.id ?? 0;

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<UserHrLetterRequestsBloc>(),
            child: Builder(
              builder:
                  (childContext) => AlertDialog(
                    title: Text(l10n.confirmCompleteHrLetter),
                    content: Text(l10n.confirmCompleteHrLetterMessage),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(childContext).pop(),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
                        child: Text(l10n.cancel),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.read<UserHrLetterRequestsBloc>().add(CompleteHrLetterRequest(request.id!, userCode));
                          Navigator.of(childContext).pop();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: Text(l10n.completeRequest),
                      ),
                    ],
                  ),
            ),
          ),
    );
  }

  void _showCancelConfirmDialog(BuildContext context, HrLetterRequestModel request) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<UserHrLetterRequestsBloc>(),
            child: Builder(
              builder:
                  (childContext) => AlertDialog(
                    title: Text(l10n.cancelRequest),
                    content: Text(l10n.confirmCancelRequest),
                    actions: [
                      ElevatedButton(
                        onPressed: () => Navigator.of(childContext).pop(),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                        child: Text(l10n.back),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          context.read<UserHrLetterRequestsBloc>().add(CancelHrLetterRequest(request.id!));
                          Navigator.of(childContext).pop();
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: Text(l10n.cancelRequest),
                      ),
                    ],
                  ),
            ),
          ),
    );
  }

  void _showRequestDetails(
    BuildContext context,
    HrLetterRequestModel request,
    UserHrLetterRequestsState state,
    bool isProcessing,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<UserHrLetterRequestsBloc>(),
            child: Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: context.screenWidth < 600 ? context.screenWidth * 0.95 : 600,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Fixed header
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Icon(Icons.article_outlined, color: Theme.of(context).primaryColor, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.hrLetterRequest,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(dialogContext).pop()),
                        ],
                      ),
                    ),
                    const Divider(),

                    // Scrollable content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (request.id != null) _dialogDetailRow(l10n.requestId, '#${request.id}'),
                            // Employee info container — team requests only
                            if (_isTeamRequests) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.employee,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    _dialogDetailRow(
                                      l10n.name,
                                      '${request.getLocalizedEmployeeName(isArabic)} (${request.employeeCode})',
                                    ),
                                    _dialogDetailRow(
                                      l10n.title,
                                      isArabic
                                          ? (request.employeeTitle ?? '-')
                                          : (request.employeeEnglishTitle ?? request.employeeTitle ?? '-'),
                                    ),
                                    _dialogDetailRow(
                                      l10n.department,
                                      isArabic
                                          ? (request.employeeDepartment ?? '-')
                                          : (request.employeeEnglishDepartment ?? request.employeeDepartment ?? '-'),
                                    ),
                                    _dialogDetailRow(l10n.hireDate, request.employeeHireDate ?? '-'),
                                    _dialogDetailRow(l10n.nationalId, request.nationalId ?? '-'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (request.createdAt != null)
                              _dialogDetailRow(
                                l10n.createdAt,
                                DateFormat('MMM dd, yyyy – h:mm a').format(request.createdAt!),
                              ),
                            _dialogDetailRow(l10n.letterPurpose, request.getLocalizedLetterPurpose(dialogContext)),
                            if (request.isEmbassy && request.travelFromDate != null)
                              _dialogDetailRow(
                                l10n.travelFromDate,
                                DateFormat('dd/MM/yyyy').format(request.travelFromDate!),
                              ),
                            if (request.isEmbassy && request.travelToDate != null)
                              _dialogDetailRow(
                                l10n.travelToDate,
                                DateFormat('dd/MM/yyyy').format(request.travelToDate!),
                              ),
                            if (request.details != null && request.details!.isNotEmpty)
                              _dialogDetailRow(l10n.hrLetterDetails, request.details!),
                            _dialogDetailRow(l10n.status, request.getLocalizedStatus(dialogContext)),
                            if (request.hrHandlerCode != null)
                              _dialogDetailRow(
                                request.isAcknowledged
                                    ? l10n.acknowledgedBy
                                    : request.isCompleted
                                    ? l10n.completedBy
                                    : request.isDeclined
                                    ? l10n.declinedBy
                                    : l10n.approvedByHR,
                                request.getLocalizedHrHandlerName(isArabic),
                              ),
                            if (request.declineReason != null)
                              _dialogDetailRow(l10n.declineReason, request.declineReason!),
                          ],
                        ),
                      ),
                    ),

                    // Fixed action buttons footer
                    if (_hasDialogActions(request))
                      Row(
                        children: [Expanded(child: _buildDialogActionButtons(context, request, state, isProcessing))],
                      ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  bool _hasDialogActions(HrLetterRequestModel request) {
    if (_isTeamRequests) return request.isPending || request.isAcknowledged;
    return request.isPending;
  }

  Widget _buildDialogActionButtons(
    BuildContext context,
    HrLetterRequestModel request,
    UserHrLetterRequestsState state,
    bool isProcessing,
  ) {
    final userCode = context.read<UserBloc>().state.user?.id ?? 0;
    final l10n = AppLocalizations.of(context)!;

    final buttons = <Widget>[];

    if (_isTeamRequests) {
      if (request.isPending) {
        buttons.add(
          _actionButton(
            label:
                isProcessing && state.acknowledgeStatus == Status.loading
                    ? l10n.acknowledging
                    : l10n.acknowledgeHrLetterRequest,
            color: Colors.blue,
            isLoading: isProcessing && state.acknowledgeStatus == Status.loading,
            onPressed:
                isProcessing
                    ? null
                    : () {
                      context.read<UserHrLetterRequestsBloc>().add(AcknowledgeHrLetterRequest(request.id!, userCode));
                      Navigator.of(context).pop();
                    },
          ),
        );
      }
      if (request.isAcknowledged) {
        buttons.add(
          _actionButton(
            label: isProcessing && state.completeStatus == Status.loading ? l10n.completing : l10n.completeRequest,
            color: Colors.green,
            isLoading: isProcessing && state.completeStatus == Status.loading,
            onPressed:
                isProcessing
                    ? null
                    : () {
                      context.read<UserHrLetterRequestsBloc>().add(CompleteHrLetterRequest(request.id!, userCode));
                      Navigator.of(context).pop();
                    },
          ),
        );
      }
      if (request.isPending || request.isAcknowledged) {
        buttons.add(
          _actionButton(
            label: isProcessing && state.declineStatus == Status.loading ? l10n.declining : l10n.decline,
            color: Colors.red,
            isLoading: isProcessing && state.declineStatus == Status.loading,
            onPressed:
                isProcessing
                    ? null
                    : () {
                      _showDeclineDialog(context, request, fromDetails: true);
                    },
          ),
        );
      }
    } else {
      if (request.isPending) {
        buttons.add(
          _actionButton(
            label: isProcessing && state.cancelStatus == Status.loading ? l10n.cancellingRequest : l10n.cancelRequest,
            color: Colors.red,
            isLoading: isProcessing && state.cancelStatus == Status.loading,
            onPressed:
                isProcessing
                    ? null
                    : () {
                      Navigator.of(context).pop();
                      _showCancelConfirmDialog(context, request);
                    },
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey[400]!)),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buttons.expand((b) => [b, const SizedBox(width: 8)]).toList()..removeLast(),
        ),
      ),
    );
  }

  Widget _dialogDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w500, color: valueColor))),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(l10n.pageOfPages(_currentPage + 1, _totalPages), style: const TextStyle(fontWeight: FontWeight.w500)),
            const Spacer(),
            IconButton(
              onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: l10n.previousPage,
            ),
            ..._buildPageNumbers(),
            IconButton(
              onPressed: _currentPage < _totalPages - 1 ? () => setState(() => _currentPage++) : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: l10n.nextPage,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    List<Widget> pages = [];
    int start = (_currentPage - 2).clamp(0, _totalPages - 1);
    int end = (_currentPage + 2).clamp(0, _totalPages - 1);

    for (int i = start; i <= end; i++) {
      pages.add(
        TextButton(
          onPressed: () => setState(() => _currentPage = i),
          style: TextButton.styleFrom(
            backgroundColor: i == _currentPage ? Theme.of(context).primaryColor : null,
            foregroundColor: i == _currentPage ? Colors.white : Theme.of(context).primaryColor,
          ),
          child: Text('${i + 1}'),
        ),
      );
    }
    return pages;
  }
}
