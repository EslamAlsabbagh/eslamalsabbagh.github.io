import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/utils/request_month_utils.dart';
import 'package:hrms_demo/data/models/overtime_request_model.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_request_repo.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_requests_query.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/user_overtime_requests/bloc/user_overtime_requests_bloc.dart';
import 'package:hrms_demo/presentation/user_overtime_requests/bloc/user_overtime_requests_state.dart';
import 'package:hrms_demo/core/utils/search_filter_utils.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/app_text_field.dart';
import 'package:hrms_demo/presentation/widgets/request_filters_mixin.dart';
import 'package:hrms_demo/presentation/widgets/request_filters_widget.dart';
import 'package:hrms_demo/presentation/widgets/row_approve_decline_actions.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/presentation/user_overtime_requests/bloc/user_overtime_requests_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class UserOvertimeRequestsContent extends StatefulWidget {
  final RequestSourceType? sourceType;
  const UserOvertimeRequestsContent({super.key, this.sourceType = RequestSourceType.myRequests});

  @override
  State<UserOvertimeRequestsContent> createState() => _UserOvertimeRequestsContentState();
}

class _UserOvertimeRequestsContentState extends State<UserOvertimeRequestsContent> with RequestFiltersMixin {
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  late _OvertimeRequestsDataSource _dataSource;

  // Track previous state to avoid unnecessary data source recreation
  List<OvertimeRequestModel>? _previousRequests;

  // ── Server-paged state (unused when the flag is off) ──────────────────────
  final PaginatorController _paginator = PaginatorController();
  _OvertimeRequestsAsyncSource? _asyncDataSource;
  OvertimeRequestsQuery? _query;

  /// Last mutation token seen from the bloc, so a rebuild triggered by
  /// something else does not re-fetch.
  int _lastRefreshToken = 0;

  RequestSourceType get _effectiveSourceType =>
      showProcessedRequests && widget.sourceType == RequestSourceType.teamRequests
          ? RequestSourceType.processedRequests
          : widget.sourceType ?? RequestSourceType.myRequests;

  OvertimeRequestsQuery _buildQuery() => OvertimeRequestsQuery(
    scope: _effectiveSourceType.scope,
    search: searchQuery,
    status: statusFilter,
    month: selectedMonth,
    sortKey: _query?.sortKey ?? OvertimeRequestSortKey.createdAt,
    sortAscending: _query?.sortAscending ?? false,
    locale: Localizations.localeOf(context).languageCode,
  );

  /// Re-issues the query and sends the table back to page 1.
  ///
  /// Going back to page 1 is not cosmetic: after a filter change the row at
  /// offset 200 is a different row, so staying put would show an arbitrary
  /// slice of the new result set.
  void _applyQuery(OvertimeRequestsQuery next) {
    final source = _asyncDataSource;
    if (source == null) {
      // The table is not built yet — the scope is showing its empty state. Keep
      // the query anyway so the source is created with it rather than with a
      // stale scope once rows appear.
      _query = next;
      return;
    }
    if (!source.setQuery(next)) return; // value-equal, nothing to fetch
    _query = next;

    if (_paginator.isAttached && _paginator.currentRowIndex != 0) {
      _paginator.goToFirstPage(); // itself triggers the fetch
    } else {
      source.refreshDatasource();
    }
  }

  @override
  void onFiltersChanged() {
    if (!FeatureFlags.serverPagedOvertimeRequests) return;
    _applyQuery(_buildQuery());
  }

  @override
  void dispose() {
    _paginator.dispose();
    super.dispose();
  }

  /// Column sort. Server-paged sorts must go through the query — sorting the
  /// rows currently in memory would only order the visible page, so paging past
  /// it would reveal unsorted rows.
  void _sortColumn(OvertimeRequestSortKey key, int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
    _applyQuery(_buildQuery().copyWith(sortKey: key, sortAscending: ascending));
  }

  void _sort<T>(Comparable<T> Function(OvertimeRequestModel d) getField, int columnIndex, bool ascending) {
    _dataSource.sort<T>(getField, ascending);
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  /// Dispatches a column sort to whichever paging mode is active.
  ///
  /// [serverKey] is passed by the column that was built, rather than looked up
  /// by index: the column set changes with the tab, so an index resolved at tap
  /// time could name a different column than the one the user clicked.
  void _onSort<T>(
    OvertimeRequestSortKey serverKey,
    Comparable<T> Function(OvertimeRequestModel d) legacyGetField,
    int columnIndex,
    bool ascending,
  ) {
    if (FeatureFlags.serverPagedOvertimeRequests) {
      _sortColumn(serverKey, columnIndex, ascending);
    } else {
      _sort<T>(legacyGetField, columnIndex, ascending);
    }
  }

  /// Records the user's page-size choice. Deliberately NOT wrapped in setState.
  ///
  /// `AsyncPaginatedDataTable2` invokes `onRowsPerPageChanged` from inside its
  /// own `build()`, so calling `setState` here throws "setState() called during
  /// build". Nothing needs repainting anyway: the table owns the live page size,
  /// and this field only seeds the next freshly-built table.
  void _onRowsPerPageChanged(int? value) => _rowsPerPage = value ?? _rowsPerPage;

  void _refreshRequests() {
    final userCode = context.read<UserBloc>().state.user?.id ?? 0;
    context.read<UserOvertimeRequestsBloc>().add(loadOvertimeRequestsEvent(userCode, _effectiveSourceType));
  }

  List<OvertimeRequestModel> _filterRequests(List<OvertimeRequestModel> requests) {
    return requests.where((request) {
      // Apply search filter
      if (searchQuery.isNotEmpty) {
        final userName =
            Localizations.localeOf(context).languageCode == 'ar' ? request.userArabicName : request.userEnglishName;
        final userCodeStr = request.userId.toString();
        if (!SearchFilterUtils.matchesSearch(name: userName, userCode: userCodeStr, query: searchQuery)) {
          return false;
        }
      }

      // Apply status filter
      if (statusFilter != 'all') {
        if (request.status?.toLowerCase() != statusFilter.toLowerCase()) {
          return false;
        }
      }

      // Apply month filter
      if (selectedMonth != null && request.date != null) {
        if (request.date!.year != selectedMonth!.year || request.date!.month != selectedMonth!.month) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildRequestDetailsContent(OvertimeRequestModel request, BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05, minWidth: 195),
                child: Row(
                  children: [
                    Text("${AppLocalizations.of(context)!.id}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(request.userId.toString()),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
                child: Row(
                  children: [
                    Text("${AppLocalizations.of(context)!.requestID}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(request.id.toString()),
                  ],
                ),
              ),
            ],
          ),
          if (widget.sourceType == RequestSourceType.teamRequests)
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
              child: Row(
                children: [
                  Text("${AppLocalizations.of(context)!.name}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    Localizations.localeOf(context).languageCode == "ar"
                        ? request.userArabicName!
                        : request.userEnglishName!,
                  ),
                ],
              ),
            ),
          if (widget.sourceType == RequestSourceType.teamRequests)
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
              child: Row(
                children: [
                  Text("${AppLocalizations.of(context)!.title}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    Localizations.localeOf(context).languageCode == "ar"
                        ? (request.userTitle ?? '')
                        : (request.userEnglishTitle ?? request.userTitle ?? ''),
                  ),
                ],
              ),
            ),
          if (widget.sourceType == RequestSourceType.teamRequests)
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
              child: Row(
                children: [
                  Text("${AppLocalizations.of(context)!.department}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    Localizations.localeOf(context).languageCode == "ar"
                        ? (request.userDepartment ?? '')
                        : (request.userEnglishDepartment ?? request.userDepartment ?? ''),
                  ),
                ],
              ),
            ),
          if (widget.sourceType == RequestSourceType.teamRequests)
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
              child: Row(
                children: [
                  Text("${AppLocalizations.of(context)!.hireDate}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(request.userHireDate ?? ''),
                ],
              ),
            ),
          Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05, minWidth: 195),
                child: Row(
                  children: [
                    Text("${AppLocalizations.of(context)!.date}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(DateFormat('yyyy-MM-dd').format(request.date!)),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
                child: Row(
                  children: [
                    Text("${AppLocalizations.of(context)!.createdAt}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(DateFormat('yyyy-MM-dd hh:mm a').format(request.tzCreatedAt)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05, minWidth: 195),
                child: Row(
                  children: [
                    Text("${AppLocalizations.of(context)!.timeFrom}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(request.timeFrom != null ? DateFormat('HH:mm').format(request.timeFrom!) : ''),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
                child: Row(
                  children: [
                    Text("${AppLocalizations.of(context)!.reason}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(request.getLocalizedOvertimeType(context)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05, minWidth: 195),
                child: Row(
                  children: [
                    Text("${AppLocalizations.of(context)!.timeTo}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(request.timeTo != null ? DateFormat('HH:mm').format(request.timeTo!) : ''),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
                child: Row(
                  children: [
                    Text(
                      "${AppLocalizations.of(context)!.reasonDetails}: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(request.reason!),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05, minWidth: 195),
                child: Row(
                  children: [
                    Text(
                      "${AppLocalizations.of(context)!.numOfHours}: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(request.numberOfHours.toString()),
                  ],
                ),
              ),
              if (request.status == 'pending')
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
                  child: Row(
                    children: [
                      Text(
                        "${AppLocalizations.of(context)!.approver}: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(request.getLocalizedApproverName(context)),
                    ],
                  ),
                ),
            ],
          ),
          Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05, minWidth: 195),
                child: Row(
                  children: [
                    Text("${AppLocalizations.of(context)!.status}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(request.getLocalizedStatus(context)),
                  ],
                ),
              ),
            ],
          ),
          // Approval History Section
          if (request.n1ApprovalDate != null) ...[
            Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.05,
                    minWidth: 195,
                    maxWidth: 500,
                  ),
                  child: Wrap(
                    children: [
                      Text(() {
                        final bool isDeclinedByN1 =
                            request.status?.toLowerCase() == 'declined' &&
                            request.currentApprover?.toLowerCase() == 'n1';
                        return isDeclinedByN1
                            ? "${AppLocalizations.of(context)!.declinedByN1}: "
                            : "${AppLocalizations.of(context)!.approvedByN1}: ";
                      }(), style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? "${request.n1ArabicName ?? 'N+1'} ${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(request.n1ApprovalDate!)}"
                            : "${request.n1EnglishName ?? 'N+1'} ${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(request.n1ApprovalDate!)}",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (request.n2ApprovalDate != null) ...[
            Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.05,
                    minWidth: 195,
                    maxWidth: 500,
                  ),
                  child: Wrap(
                    children: [
                      Text(() {
                        final bool isDeclinedByN2 =
                            request.status?.toLowerCase() == 'declined' &&
                            request.currentApprover?.toLowerCase() == 'n2';
                        return isDeclinedByN2
                            ? "${AppLocalizations.of(context)!.declinedByN2}: "
                            : "${AppLocalizations.of(context)!.approvedByN2}: ";
                      }(), style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? "${request.n2ArabicName ?? 'N+2'} ${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(request.n2ApprovalDate!)}"
                            : "${request.n2EnglishName ?? 'N+2'} ${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(request.n2ApprovalDate!)}",
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (request.hrApprovalDate != null) ...[
            Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05, minWidth: 195),
                  child: Row(
                    children: [
                      Text(() {
                        final bool isDeclinedByHR =
                            request.status?.toLowerCase() == 'declined' &&
                            request.currentApprover?.toLowerCase() == 'hr';
                        return isDeclinedByHR
                            ? "${AppLocalizations.of(context)!.declinedByHR}: "
                            : "${AppLocalizations.of(context)!.approvedByHR}: ";
                      }(), style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(() {
                        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                        String approverName;
                        if (request.hrEnglishName != null || request.hrArabicName != null) {
                          approverName =
                              isArabic
                                  ? (request.hrArabicName ?? request.hrEnglishName ?? '')
                                  : (request.hrEnglishName ?? request.hrArabicName ?? '');
                        } else {
                          approverName = '';
                        }
                        if (approverName.isNotEmpty) {
                          return "$approverName ${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(request.hrApprovalDate!)}";
                        } else {
                          return "${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(request.hrApprovalDate!)}";
                        }
                      }()),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (request.status == 'declined' && request.declineReason != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${AppLocalizations.of(context)!.declineReason}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 400),
                  child: Text(request.declineReason!, maxLines: 5),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showApprovalConfirmationDialog(OvertimeRequestModel request) {
    showDialog(
      context: context,
      builder: (childContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.approve),
          content: _buildRequestDetailsContent(request, context),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  onPressed: () => Navigator.pop(childContext),
                  label: AppLocalizations.of(context)!.cancel,
                  color: Colors.red,
                  width: kIsWeb ? 120 : context.screenWidth * 0.25,
                ),
                const SizedBox(width: 16),
                AppButton(
                  onPressed: () {
                    context.read<UserOvertimeRequestsBloc>().add(
                      ApproveOvertimeRequest(
                        request.id!,
                        request.currentApprover!,
                        context.read<UserBloc>().state.user?.id ?? 0,
                      ),
                    );
                    Navigator.pop(childContext);
                  },
                  label: AppLocalizations.of(context)!.approve,
                  color: Colors.green,
                  width: kIsWeb ? 120 : context.screenWidth * 0.25,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showCancelConfirmationDialog(BuildContext context, OvertimeRequestModel request) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.confirmCancelRequest),
          content: Text(AppLocalizations.of(dialogContext)!.cancelRequestMessage),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  label: AppLocalizations.of(dialogContext)!.cancel,
                  color: Colors.grey,
                  width: kIsWeb ? 120 : context.screenWidth * 0.25,
                ),
                const SizedBox(width: 16),
                AppButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.read<UserOvertimeRequestsBloc>().add(CancelOvertimeRequest(request.id!));
                  },
                  label: AppLocalizations.of(dialogContext)!.cancelRequest,
                  color: Colors.red.shade600,
                  width: kIsWeb ? 150 : context.screenWidth * 0.3,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionableVsProcessedSegmentButtons() {
    return Container(
      alignment: Localizations.localeOf(context).languageCode == 'ar' ? Alignment.topRight : Alignment.topLeft,
      margin: const EdgeInsets.all(16),
      child: Wrap(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(AppLocalizations.of(context)!.viewRequests, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment<String>(
                value: 'actionable',
                label: Text(AppLocalizations.of(context)!.actionable),
                icon: Icon(Icons.pending_actions),
              ),
              ButtonSegment<String>(
                value: 'processed',
                label: Text(AppLocalizations.of(context)!.processed),
                icon: Icon(Icons.check_circle_outline),
              ),
            ],
            selected: {showProcessedRequests ? 'processed' : 'actionable'},
            onSelectionChanged: (Set<String> selection) {
              switchProcessedTab(selection.first == 'processed');
              _refreshRequests();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserOvertimeRequestsBloc, UserOvertimeRequestsState>(
      listener: (context, state) {
        if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.failure?.message ?? '')));
        }

        // Handle cancel success/failure feedback
        if (state.cancelStatus == Status.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestCancelledSuccessfully)));
          context.read<UserOvertimeRequestsBloc>().add(const ResetCancelStatus());
        } else if (state.cancelStatus == Status.failure && state.operationFailure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.operationFailure?.message ?? AppLocalizations.of(context)!.errorCancellingRequest),
            ),
          );
          context.read<UserOvertimeRequestsBloc>().add(const ResetCancelStatus());
        }
      },
      builder: (context, state) {
        // NOTE: deliberately no unconditional `if (status == loading) return
        // Scaffold(...)`. That returned a bare Scaffold rather than MainLayout,
        // so the AppBar, sidebar, tab switcher and filter bar all vanished on
        // page entry, on the Actionable/Processed switch, and on every
        // approve/decline. The paged table shows its own spinner inside its box
        // (see `loading:` in _buildTable) and a row shows one on the tapped
        // button, so a screen-level loader has nothing left to do. Do not
        // re-add it.
        if (!FeatureFlags.serverPagedOvertimeRequests && state.status == Status.loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Server-paged: this describes the WHOLE scope, so it comes from the
        // bloc rather than from whatever rows happen to be on this page.
        final availableMonths =
            FeatureFlags.serverPagedOvertimeRequests
                ? state.availableMonths.toSet()
                : RequestMonthUtils.calculateAvailableMonths(state.requests.map((r) => r.date).toList());

        // Gated on the UNFILTERED existence check. Using the page's total here
        // would hide the table and its filter bar the moment a filter matched
        // nothing, leaving the user with no way to clear it.
        //
        // `?? true` handles the third state: the probe has not answered yet.
        // Assuming rows exist is what lets the shell and the table paint on the
        // first frame — the table then shows its own in-box spinner, and its
        // `empty:` widget covers a genuinely empty scope until the probe lands.
        // Defaulting the other way would flash "no requests found" on every
        // entry and every tab switch.
        //
        // `|| tableShowingRows` is a backstop, not the mechanism: the probe
        // derives from the same RPC as the list (see
        // OvertimeRequestRepoImpl.hasAnyRequests), so the two should never
        // disagree. The table is holding the evidence, so a populated one always
        // wins over a probe that says otherwise.
        final tableShowingRows =
            _asyncDataSource != null && !_asyncDataSource!.isStale && _asyncDataSource!.rowCount > 0;
        final hasRequests =
            FeatureFlags.serverPagedOvertimeRequests
                ? ((state.hasAnyRequests ?? true) || tableShowingRows)
                : state.requests.isNotEmpty;

        if (!hasRequests) {
          return MainLayout(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    if (widget.sourceType == RequestSourceType.teamRequests) ...[
                      _buildActionableVsProcessedSegmentButtons(),
                    ],
                    Center(
                      child: RequestFiltersWidget(
                        searchQuery: searchQuery,
                        statusFilter: statusFilter,
                        selectedMonth: selectedMonth,
                        onSearchChanged: updateSearchQuery,
                        onStatusChanged: updateStatusFilter,
                        onMonthChanged: (month) {
                          updateSelectedMonth(month);
                        },
                        showSearch: widget.sourceType == RequestSourceType.teamRequests,
                        showStatus: widget.sourceType != RequestSourceType.teamRequests || showProcessedRequests,
                        availableMonths: availableMonths,
                      ),
                    ),
                    SizedBox(
                      height: context.screenHeight * 0.8,
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!.noOvertimeRequestsFound,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (FeatureFlags.serverPagedOvertimeRequests) {
          // Built once and kept: recreating it would discard the fetched page
          // and re-issue the request on every rebuild.
          _asyncDataSource ??= _OvertimeRequestsAsyncSource(
            repo: context.read<OvertimeRequestRepo>(),
            query: _query ??= _buildQuery(),
            rowSourceFactory:
                (pageRows, query) => _makeDataSource(
                  requests: pageRows,
                  // Always show the Actions column outside the processed tab.
                  // Deriving it per page would let the column list and the cell
                  // list disagree mid-frame, which is a hard crash
                  // (columns.length != cells.length), not a cosmetic glitch.
                  //
                  // Read from the QUERY this page was fetched for, not from the
                  // live `showProcessedRequests`. The two differ for the length
                  // of a tab switch, and taking the live value would emit cells
                  // for the tab the user just left. Paired with
                  // _OvertimeRequestsAsyncSource.isStale — which withholds these
                  // rows until the query catches up — it guarantees the cells
                  // and the header always describe the same tab.
                  shouldShowActionColumn: query.scope != OvertimeRequestScope.processed,
                ),
          );

          // A mutation happened: re-fetch the page the user is looking at,
          // rather than resetting them to page 1.
          if (state.refreshToken != _lastRefreshToken) {
            _lastRefreshToken = state.refreshToken;
            WidgetsBinding.instance.addPostFrameCallback((_) => _asyncDataSource?.refreshDatasource());
          }

          // Switching language changes which name column the server searches
          // and sorts on, so the query has to follow. Deferred to after the
          // frame because _applyQuery can fetch and notify listeners.
          final locale = Localizations.localeOf(context).languageCode;
          if (_query != null && _query!.locale != locale) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _applyQuery(_buildQuery().copyWith(locale: locale));
            });
          }
        } else {
          // Apply filters to requests
          final filteredRequests = _filterRequests(state.requests);

          // Calculate if action column should be shown based on filtered data
          final shouldShowActionColumn =
              !showProcessedRequests &&
              ((widget.sourceType == RequestSourceType.teamRequests &&
                      filteredRequests.any((request) => request.isPending)) ||
                  filteredRequests.any(
                    (req) =>
                        req.isActionable ||
                        (req.cancelled == true &&
                            (widget.sourceType == RequestSourceType.teamRequests && req.removedN1 != true)),
                  ));

          // Only recreate data source if the actual data has changed or filters changed
          final dataChanged = _previousRequests != state.requests || hasFiltersChanged;

          if (dataChanged || _previousRequests == null) {
            _dataSource = _makeDataSource(
              requests: filteredRequests,
              shouldShowActionColumn: shouldShowActionColumn,
              isLoading: state.status == Status.loading,
            );

            // Update previous state tracker
            _previousRequests = state.requests;

            // Apply default sorting by createdAt (newest first) if no sort is active
            if (_sortColumnIndex == null) {
              _dataSource.sort<DateTime>(
                (d) => d.createdAt ?? DateTime(1900),
                false, // descending order
              );
            }
          }
        }

        return MainLayout(
          title:
              widget.sourceType == RequestSourceType.teamRequests
                  ? AppLocalizations.of(context)!.teamRequests
                  : AppLocalizations.of(context)!.myRequests,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (widget.sourceType == RequestSourceType.teamRequests) ...[
                  _buildActionableVsProcessedSegmentButtons(),
                ],
                Center(
                  child: RequestFiltersWidget(
                    searchQuery: searchQuery,
                    statusFilter: statusFilter,
                    selectedMonth: selectedMonth,
                    onSearchChanged: updateSearchQuery,
                    onStatusChanged: updateStatusFilter,
                    onMonthChanged: (month) {
                      updateSelectedMonth(month);
                    },
                    showSearch: widget.sourceType == RequestSourceType.teamRequests,
                    showStatus: widget.sourceType != RequestSourceType.teamRequests || showProcessedRequests,
                    availableMonths: availableMonths,
                  ),
                ),
                SizedBox(
                  height: context.screenHeight * 0.8,
                  width: context.screenWidth > 1000 ? context.screenWidth * 0.9 : 1450,
                  child: _buildTable(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the row source. Shared by both paging modes so the cell layout,
  /// dialogs and action buttons live in exactly one place.
  ///
  /// On the paged path [requests] is one already-ordered page. Nothing re-sorts
  /// it: this source only reorders when `sort()` is called, and the paged path
  /// routes sorts through the query instead — so the server's ORDER BY survives.
  _OvertimeRequestsDataSource _makeDataSource({
    required List<OvertimeRequestModel> requests,
    required bool shouldShowActionColumn,
    bool isLoading = false,
  }) {
    return _OvertimeRequestsDataSource(
      requests,
      isLoading: isLoading,
      context: context,
      sourceType: widget.sourceType,
      parentState: this,
      shouldShowActionColumn: shouldShowActionColumn,
      onApproved: (request, {bool fromDetails = false}) {
        if (fromDetails) {
          // Direct approval from details dialog
          context.read<UserOvertimeRequestsBloc>().add(
            ApproveOvertimeRequest(request.id!, request.currentApprover!, context.read<UserBloc>().state.user?.id ?? 0),
          );
        } else {
          // Show confirmation dialog for table row button
          _showApprovalConfirmationDialog(request);
        }
      },
      onDeclined: (request, {bool fromDetails = false}) {
        final TextEditingController reasonController = TextEditingController();
        final formKey = GlobalKey<FormState>();

        showDialog(
          context: context,
          builder: (childContext) {
            void onFieldSubmitted() {
              if (formKey.currentState!.validate()) {
                final reason = reasonController.text.trim();
                context.read<UserOvertimeRequestsBloc>().add(
                  DeclineOvertimeRequest(
                    request.id!,
                    request.currentApprover!,
                    context.read<UserBloc>().state.user?.id ?? 0,
                    reason,
                  ),
                );
                Navigator.pop(childContext);
                if (fromDetails) {
                  Navigator.pop(context); // Close the details dialog
                }
              }
            }

            return BlocProvider.value(
              value: context.read<UserOvertimeRequestsBloc>(),
              child: AlertDialog(
                title: Text(AppLocalizations.of(context)!.declineReason),
                content: Form(
                  key: formKey,
                  child: AppTextField(
                    controller: reasonController,
                    label: AppLocalizations.of(context)!.reason,
                    onFieldSubmitted: (_) => onFieldSubmitted(),
                    isReasonField: true,
                  ),
                ),
                actions: [
                  AppButton(
                    onPressed: () => Navigator.pop(childContext), // Cancel
                    label: AppLocalizations.of(context)!.cancel,
                    color: Colors.red,
                    width: kIsWeb ? 250 : context.screenWidth * 0.3,
                  ),
                  AppButton(
                    width: kIsWeb ? 250 : context.screenWidth * 0.3,
                    onPressed: onFieldSubmitted,
                    label: AppLocalizations.of(context)!.submit,
                  ),
                ],
              ),
            );
          },
        );
      },
      onCancel: (request) {
        _showCancelConfirmationDialog(context, request);
      },
      onRemove: (request) {
        if (widget.sourceType == RequestSourceType.teamRequests) {
          context.read<UserOvertimeRequestsBloc>().add(RemoveOvertimeRequestForN1(request.id!));
        } else {
          context.read<UserOvertimeRequestsBloc>().add(RemoveOvertimeRequest(request.id!));
        }
      },
    );
  }

  /// The column list.
  ///
  /// Its length MUST match the number of cells every row emits, which is why the
  /// Action column is gated on the effective source type on the paged path
  /// rather than on anything derived from the rows in hand — the row source is
  /// built with the matching `shouldShowActionColumn`, and a `DataRow` whose
  /// cell count differs from the column count is a hard assertion failure.
  ///
  /// NOTE on the two "reason" columns: the narrow one renders
  /// `getLocalizedOvertimeType` and the wide one renders `reason`, but BOTH used
  /// to sort on `d.reason`. Naming a server sort key per column forces that out
  /// into the open — each now sorts on the column it actually displays.
  List<DataColumn2> _buildColumns(BuildContext context) {
    final showActionColumn =
        FeatureFlags.serverPagedOvertimeRequests
            ? _effectiveSourceType != RequestSourceType.processedRequests
            : _dataSource.shouldShowActionColumn;

    return [
      if (widget.sourceType == RequestSourceType.teamRequests)
        DataColumn2(
          size: ColumnSize.S,
          label: Center(child: Text(AppLocalizations.of(context)!.id, style: TextStyle(fontWeight: FontWeight.bold))),
          onSort: (i, asc) => _onSort<String>(OvertimeRequestSortKey.userId, (d) => d.userId.toString(), i, asc),
        ),
      if (widget.sourceType == RequestSourceType.teamRequests)
        DataColumn2(
          size: ColumnSize.L,
          label: Center(child: Text(AppLocalizations.of(context)!.name, style: TextStyle(fontWeight: FontWeight.bold))),
          onSort:
              (i, asc) => _onSort<String>(
                OvertimeRequestSortKey.employeeName,
                (d) => Localizations.localeOf(context).languageCode == 'ar' ? d.userArabicName! : d.userEnglishName!,
                i,
                asc,
              ),
        ),
      DataColumn2(
        size: ColumnSize.S,
        label: Center(
          child: Text(AppLocalizations.of(context)!.createdAt, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        onSort: (i, asc) => _onSort<DateTime>(OvertimeRequestSortKey.createdAt, (d) => d.createdAt!, i, asc),
      ),
      DataColumn2(
        size: ColumnSize.S,
        label: Center(child: Text(AppLocalizations.of(context)!.date, style: TextStyle(fontWeight: FontWeight.bold))),
        onSort: (i, asc) => _onSort<DateTime>(OvertimeRequestSortKey.date, (d) => d.date!, i, asc),
      ),
      DataColumn2(
        size: ColumnSize.S,
        label: Center(
          child: Text(AppLocalizations.of(context)!.timeFrom, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        onSort: (i, asc) => _onSort<DateTime>(OvertimeRequestSortKey.timeFrom, (d) => d.timeFrom!, i, asc),
      ),
      DataColumn2(
        size: ColumnSize.S,
        label: Center(child: Text(AppLocalizations.of(context)!.timeTo, style: TextStyle(fontWeight: FontWeight.bold))),
        onSort: (i, asc) => _onSort<DateTime>(OvertimeRequestSortKey.timeTo, (d) => d.timeTo!, i, asc),
      ),
      // Renders getLocalizedOvertimeType — see the NOTE above.
      DataColumn2(
        size: ColumnSize.S,
        label: Center(child: Text(AppLocalizations.of(context)!.reason, style: TextStyle(fontWeight: FontWeight.bold))),
        onSort:
            (i, asc) => _onSort<String>(OvertimeRequestSortKey.overtimeType, (d) => d.overtimeType ?? '', i, asc),
      ),
      DataColumn2(
        size: ColumnSize.L,
        label: Center(
          child: Text(AppLocalizations.of(context)!.reasonDetails, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        onSort: (i, asc) => _onSort<String>(OvertimeRequestSortKey.reason, (d) => d.reason!, i, asc),
      ),
      DataColumn2(
        size: ColumnSize.S,
        label: Center(child: Text(AppLocalizations.of(context)!.status, style: TextStyle(fontWeight: FontWeight.bold))),
        onSort: (i, asc) => _onSort<String>(OvertimeRequestSortKey.status, (d) => d.status!, i, asc),
      ),
      DataColumn2(
        size: ColumnSize.S,
        label: Center(
          child: Text(AppLocalizations.of(context)!.approver, style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        onSort:
            (i, asc) => _onSort<String>(OvertimeRequestSortKey.currentApprover, (d) => d.currentApprover!, i, asc),
      ),
      if (showActionColumn)
        DataColumn2(
          size: ColumnSize.L,
          label: Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppLocalizations.of(context)!.action,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 40),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _buildTable(BuildContext context) {
    final minWidth = context.screenWidth > 1000 ? context.screenWidth * 0.9 : 1450.0;
    final columns = _buildColumns(context);

    if (!FeatureFlags.serverPagedOvertimeRequests) {
      return PaginatedDataTable2(
        key: tableKey, // Reset pagination when filters change
        minWidth: minWidth,
        smRatio: .3,
        lmRatio: 0.8,
        columnSpacing: 0,
        horizontalMargin: 2,
        showCheckboxColumn: false,
        columns: columns,
        source: _dataSource,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        rowsPerPage: _rowsPerPage,
        onRowsPerPageChanged: (value) {
          setState(() {
            _rowsPerPage = value ?? _rowsPerPage;
          });
        },
      );
    }

    return AsyncPaginatedDataTable2(
      // Deliberately NO `key: tableKey`. A changing key destroys the table's
      // state, detaches the PaginatorController and causes a duplicate fetch.
      // Page resets are explicit instead, via _applyQuery.
      controller: _paginator,
      minWidth: minWidth,
      smRatio: .3,
      lmRatio: 0.8,
      columnSpacing: 0,
      horizontalMargin: 2,
      showCheckboxColumn: false,
      columns: columns,
      source: _asyncDataSource!,
      sortColumnIndex: _sortColumnIndex,
      sortAscending: _sortAscending,
      rowsPerPage: _rowsPerPage,
      onRowsPerPageChanged: _onRowsPerPageChanged,
      // Deleting the last row of the last page shrinks the result set, so the
      // page the paginator is on can stop existing.
      pageSyncApproach: PageSyncApproach.goToLast,
      loading: const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
      empty: ListenableBuilder(
        listenable: _asyncDataSource!,
        builder: (context, _) {
          // While the rows in hand belong to a superseded query, showing "none
          // found" would claim an answer the server has not given yet.
          if (_asyncDataSource!.isStale) return const SizedBox.shrink();
          return Center(
            child: Text(
              AppLocalizations.of(context)!.noOvertimeRequestsFound,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.grey),
            ),
          );
        },
      ),
      errorBuilder: (error) => _buildTableError(error),
    );
  }

  Widget _buildTableError(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 12),
            Text(error?.toString() ?? '', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            AppButton(
              width: kIsWeb ? 200 : context.screenWidth * 0.4,
              onPressed: () => _asyncDataSource?.refreshDatasource(),
              label: AppLocalizations.of(context)!.retry,
            ),
          ],
        ),
      ),
    );
  }
}

class _OvertimeRequestsDataSource extends DataTableSource {
  final List<OvertimeRequestModel> _requests;
  final bool isLoading;
  final BuildContext context;
  final RequestSourceType? sourceType;
  final Function(OvertimeRequestModel, {bool fromDetails})? onApproved;
  final _UserOvertimeRequestsContentState parentState;
  final Function(OvertimeRequestModel request, {bool fromDetails})? onDeclined;
  final Function(OvertimeRequestModel request)? onCancel;
  final Function(OvertimeRequestModel)? onRemove;
  final bool shouldShowActionColumn;

  _OvertimeRequestsDataSource(
    this._requests, {
    this.isLoading = false,
    required this.context,
    this.sourceType,
    this.onApproved,
    this.onDeclined,
    this.onCancel,
    this.onRemove,
    required this.parentState,
    required this.shouldShowActionColumn,
  });

  bool get hasActionableRequests => _requests.any(
    (request) =>
        request.isActionable ||
        (request.cancelled == true &&
            (parentState.widget.sourceType == RequestSourceType.myRequests
                ? request.removed != true
                : request.removedN1 != true)),
  );

  void sort<T>(Comparable<T> Function(OvertimeRequestModel d) getField, bool ascending) {
    _requests.sort((a, b) {
      final aValue = getField(a);
      final bValue = getField(b);
      return ascending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
    });
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    if (index >= _requests.length) return null;
    final request = _requests[index];
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final timeFormatter = DateFormat('HH:mm');
    final userName =
        Localizations.localeOf(context).languageCode == "ar"
            ? request.userArabicName ?? ''
            : request.userEnglishName ?? '';
    return DataRow(
      onSelectChanged: (value) {
        if (value == true) {
          _showRequestDetailsDialog(request, context);
        }
      },
      cells: [
        if (sourceType == RequestSourceType.teamRequests) DataCell(Center(child: Text(request.userId.toString()))),
        if (sourceType == RequestSourceType.teamRequests)
          DataCell(Center(child: Text(userName.length > 15 ? '${userName.substring(0, 15)}...' : userName))),
        DataCell(
          Center(
            child: Text(
              '${DateFormat('yyyy-MM-dd').format(request.tzCreatedAt)}\n${DateFormat('hh:mm a').format(request.tzCreatedAt)}',
              style: TextStyle(fontSize: context.screenWidth > 1400 ? 14 : 12),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              dateFormatter.format(request.date!),
              style: TextStyle(fontSize: context.screenWidth > 1400 ? 14 : 12),
            ),
          ),
        ),
        DataCell(Center(child: Text(request.timeFrom != null ? timeFormatter.format(request.timeFrom!) : ''))),
        DataCell(Center(child: Text(request.timeTo != null ? timeFormatter.format(request.timeTo!) : ''))),
        DataCell(Center(child: Text(request.getLocalizedOvertimeType(context)))),
        DataCell(
          Center(child: Text(request.reason!.length > 20 ? '${request.reason!.substring(0, 20)}...' : request.reason!)),
        ),
        DataCell(Center(child: Text(request.getLocalizedStatus(context)))),
        DataCell(Center(child: Text(request.getLocalizedApproverName(context)))),
        // Exactly one cell whenever the Action column exists. The old code chose
        // between three branches, the middle one gated on a whole-list
        // `_requests.any(...)` scan — meaningless once only a page is in memory,
        // and redundant even before that: if no row satisfies that predicate,
        // no row satisfies the per-row conditions below either.
        if (shouldShowActionColumn)
          (sourceType == RequestSourceType.teamRequests && request.isPending)
              ? DataCell(
                Center(
                  child: RowApproveDeclineActions<UserOvertimeRequestsBloc, UserOvertimeRequestsState>(
                    isProcessing: (state) => state.processingRequestId == request.id,
                    onApprove: () => onApproved?.call(request),
                    onDecline: () => onDeclined?.call(request),
                    legacyIsLoading: isLoading,
                  ),
                ),
              )
              : DataCell(
                Center(
                  child:
                      request.isActionable && sourceType == RequestSourceType.myRequests
                          ? BlocBuilder<UserOvertimeRequestsBloc, UserOvertimeRequestsState>(
                            builder: (context, state) {
                              final isCancelling =
                                  state.cancelStatus == Status.loading && state.processingRequestId == request.id;

                              return AppButton(
                                width: 168,
                                padding: const EdgeInsets.all(4),
                                margin: EdgeInsets.all(4),
                                isLoading: isCancelling,
                                onPressed: isCancelling ? null : () => onCancel?.call(request),
                                label:
                                    isCancelling
                                        ? AppLocalizations.of(context)!.cancelling
                                        : AppLocalizations.of(context)!.cancelRequest,
                                color: Colors.red.shade600,
                              );
                            },
                          )
                          : (request.cancelled == true &&
                              sourceType == RequestSourceType.teamRequests &&
                              request.removedN1 != true)
                          ? AppButton(
                            width: 168,
                            padding: const EdgeInsets.all(4),
                            margin: EdgeInsets.all(4),
                            onPressed: () => _showRemoveConfirmationDialog(request),
                            label: AppLocalizations.of(context)!.remove,
                            color: Colors.grey.shade600,
                          )
                          : null,
                ),
              ),
      ],
    );
  }

  @override
  int get rowCount => _requests.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;

  void _showRemoveConfirmationDialog(OvertimeRequestModel request) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.confirmRemoveRequest),
          content: Text(AppLocalizations.of(dialogContext)!.removeRequestMessage),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  label: AppLocalizations.of(dialogContext)!.cancel,
                  color: Colors.grey,
                  width: kIsWeb ? 120 : context.screenWidth * 0.25,
                ),
                const SizedBox(width: 16),
                AppButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    onRemove?.call(request);
                  },
                  label: AppLocalizations.of(dialogContext)!.remove,
                  color: Colors.grey.shade600,
                  width: kIsWeb ? 120 : context.screenWidth * 0.25,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showCancelConfirmationDialogFromDetails(OvertimeRequestModel request, BuildContext detailsDialogContext) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.confirmCancelRequest),
          content: Text(AppLocalizations.of(dialogContext)!.cancelRequestMessage),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  label: AppLocalizations.of(dialogContext)!.cancel,
                  color: Colors.grey,
                  width: kIsWeb ? 120 : context.screenWidth * 0.25,
                ),
                const SizedBox(width: 16),
                AppButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Close confirmation dialog
                    Navigator.of(detailsDialogContext).pop(); // Close details dialog
                    context.read<UserOvertimeRequestsBloc>().add(CancelOvertimeRequest(request.id!));
                  },
                  label: AppLocalizations.of(dialogContext)!.cancelRequest,
                  color: Colors.red.shade600,
                  width: kIsWeb ? 150 : context.screenWidth * 0.3,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showRequestDetailsDialog(OvertimeRequestModel request, BuildContext context) {
    showDialog(
      context: context,
      builder: (childContext2) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: context.screenWidth < 600 ? context.screenWidth * 0.95 : 600,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Theme.of(context).primaryColor, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context)!.requestDetails,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(childContext2), icon: const Icon(Icons.close)),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: parentState._buildRequestDetailsContent(request, context),
                  ),
                ),
                // Actions
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          onPressed: () => Navigator.pop(childContext2),
                          label: AppLocalizations.of(context)!.close,
                          color: Colors.blue,
                        ),
                      ),
                      if (sourceType == RequestSourceType.myRequests && request.isActionable) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppButton(
                            onPressed: () {
                              _showCancelConfirmationDialogFromDetails(request, childContext2);
                            },
                            label: AppLocalizations.of(context)!.cancelRequest,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                      if (sourceType == RequestSourceType.teamRequests &&
                          !parentState.showProcessedRequests &&
                          request.isPending) ...[
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppButton(
                            onPressed: () {
                              onApproved?.call(request, fromDetails: true);
                              Navigator.pop(childContext2);
                            },
                            label: AppLocalizations.of(context)!.approve,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AppButton(
                            onPressed: () {
                              onDeclined?.call(request, fromDetails: true);
                            },
                            label: AppLocalizations.of(context)!.decline,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Fetches one page at a time from `list_user_overtime_requests`.
///
/// Row *rendering* is not duplicated here: [getRows] builds a throwaway
/// [_OvertimeRequestsDataSource] over the page it just fetched and calls its
/// `getRow`, so all the cell layout, detail dialogs and action buttons stay in
/// exactly one place. That source only reorders when `sort()` is called, and the
/// paged path routes sorts through the query instead, so the server's ORDER BY
/// survives.
class _OvertimeRequestsAsyncSource extends AsyncDataTableSource {
  _OvertimeRequestsAsyncSource({
    required this.repo,
    required OvertimeRequestsQuery query,
    required this.rowSourceFactory,
  }) : _query = query;

  final OvertimeRequestRepo repo;

  /// Builds a sync source over a single, already-ordered page. Supplied by the
  /// widget so the row builders keep their `BuildContext` and action callbacks.
  ///
  /// Takes the query the page was fetched FOR, so the cells it emits are decided
  /// by that query rather than by whatever the widget's tab state happens to be
  /// when the fetch resolves. See [isStale].
  final _OvertimeRequestsDataSource Function(List<OvertimeRequestModel> pageRows, OvertimeRequestsQuery query)
  rowSourceFactory;

  OvertimeRequestsQuery _query;
  OvertimeRequestsQuery get query => _query;

  /// The query the rows currently in the base class's cache were built for.
  ///
  /// `AsyncDataTableSource` keeps `_rows` across a reload — `AsyncPaginatedDataTable2`
  /// renders the full table underneath its `loading:` overlay rather than
  /// clearing it — so after a query change the cache still holds the PREVIOUS
  /// query's rows for the length of the round trip.
  OvertimeRequestsQuery? _renderedQuery;

  /// Whether the cached rows belong to a query that has since been replaced.
  ///
  /// Two things go wrong if such rows are rendered:
  ///   * the Actionable→Processed switch drops the Action column immediately,
  ///     while the cached rows still carry its cell — and a DataRow with more
  ///     cells than there are columns is a hard assertion, which surfaces as a
  ///     red error box, not a glitch;
  ///   * the user sees the old tab's rows under the spinner before the real
  ///     ones arrive.
  ///
  /// The screen used to be blanked by a page-level spinner during this window,
  /// which hid both. It no longer is, so the staleness has to be handled here.
  bool get isStale => _renderedQuery != _query;

  bool _hasActionable = false;

  /// Whether ANY row in the whole filtered set has an action available —
  /// computed server-side, so it does not flicker when a page happens to hold
  /// only non-actionable rows. Advisory: the Action column's visibility is
  /// decided by the scope, not by this.
  bool get hasActionable => _hasActionable;

  /// Swaps in a new query. Returns whether it actually differs, so the caller
  /// can skip a redundant fetch on rebuilds that changed nothing.
  bool setQuery(OvertimeRequestsQuery next) {
    if (_query == next) return false;
    _query = next;
    return true;
  }

  // Hiding stale rows here rather than clearing the cache, because the cache is
  // private to the base class. These two are the only ways the table reads it.
  //
  // Note this deliberately does NOT hide rows during a mutation refresh: the
  // query is unchanged there, so the user keeps seeing their page under the
  // spinner instead of it emptying and refilling.

  @override
  DataRow? getRow(int index) => isStale ? null : super.getRow(index);

  @override
  int get rowCount => isStale ? 0 : super.rowCount;

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    // Captured before the await: _query can be replaced mid-flight by another
    // filter change, and this page belongs to the query it was issued for.
    final query = _query;
    final page = await repo.getOvertimeRequestsPage(query, offset: startIndex, limit: count);
    _hasActionable = page.hasActionable;

    final rowSource = rowSourceFactory(page.items, query);

    // Set only once the rows exist, and to the query THIS fetch was for. If a
    // newer query arrived while this one was in flight, isStale stays true and
    // the table keeps showing nothing until that newer fetch lands.
    _renderedQuery = query;

    return AsyncRowsResponse(
      // The TOTAL across all pages, not page.items.length — this is what sizes
      // the paginator.
      page.totalCount,
      [for (var i = 0; i < page.items.length; i++) rowSource.getRow(i)!],
    );
  }
}
