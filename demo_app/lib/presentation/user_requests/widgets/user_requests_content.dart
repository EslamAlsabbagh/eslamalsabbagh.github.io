import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/core/constants/leave_type.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/request_month_utils.dart';
import 'package:hrms_demo/core/utils/search_filter_utils.dart';
import 'package:hrms_demo/data/models/leave_cancellation_request_model.dart';
import 'package:hrms_demo/data/models/leave_request_model.dart';
import 'package:hrms_demo/data/models/user_request_row.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_requests_query.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/user_requests/bloc/user_requests_bloc.dart';
import 'package:hrms_demo/presentation/user_requests/bloc/user_requests_event.dart';
import 'package:hrms_demo/presentation/user_requests/bloc/user_requests_state.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/app_text_field.dart';
import 'package:hrms_demo/presentation/widgets/request_filters_mixin.dart';
import 'package:hrms_demo/presentation/widgets/row_approve_decline_actions.dart';
import 'package:hrms_demo/presentation/widgets/request_filters_widget.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

// ── Column / cell visibility ────────────────────────────────────────────────
// Defined once and called from THREE places: _buildColumns, and the cell lists
// of both _buildLeaveRequestRow and _buildCancellationRequestRow. They must
// agree exactly — a row with fewer cells than the header has columns is a hard
// DataTable assertion ("All rows must have the same number of cells"), not a
// layout glitch.
//
// They exist because that is precisely what went wrong: the cancellation row
// gated its Request Type cell on `cancellationRequests.isNotEmpty` while the
// leave row used `hasOriginalCancellationRequests`. The two agreed on the
// client-paged path and disagreed on the server-paged one, so the table crashed
// only on pages that happened to contain a cancellation request.

bool _showIdColumn(RequestSourceType? sourceType) => sourceType == RequestSourceType.teamRequests;

bool _showNameColumn(RequestSourceType? sourceType) => sourceType == RequestSourceType.teamRequests;

/// [hasCancellationRows] must be the SAME value the data source was built with
/// (`hasOriginalCancellationRequests`); do not re-derive it per page.
bool _showRequestTypeColumn(RequestSourceType? sourceType, bool hasCancellationRows) =>
    sourceType == RequestSourceType.teamRequests || (sourceType == RequestSourceType.myRequests && hasCancellationRows);

class UserRequestsContent extends StatefulWidget {
  final RequestSourceType? sourceType;
  const UserRequestsContent({super.key, this.sourceType});

  @override
  State<UserRequestsContent> createState() => _UserRequestsContentState();
}

class _UserRequestsContentState extends State<UserRequestsContent> with RequestFiltersMixin<UserRequestsContent> {
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  late _LeaveRequestsDataSource _dataSource;

  // Track previous state to avoid unnecessary data source recreation
  List<LeaveRequestModel>? _previousRequests;
  List<LeaveCancellationRequestModel>? _previousCancellationRequests;
  String _previousSearchQuery = '';
  String _previousStatusFilter = 'all';
  DateTime? _previousSelectedMonth;

  // ── Server-paged state (unused when the flag is off) ──────────────────────
  final PaginatorController _paginator = PaginatorController();
  _LeaveRequestsAsyncSource? _asyncDataSource;
  LeaveRequestsQuery? _query;

  /// Last mutation token seen from the bloc, so a rebuild triggered by
  /// something else does not re-fetch.
  int _lastRefreshToken = 0;

  /// Server sort key per column index, filled while the columns are built so
  /// the two lists cannot drift. Columns without a key are unsortable.
  final List<LeaveRequestSortKey?> _sortKeys = [];

  RequestSourceType get _effectiveSourceType =>
      showProcessedRequests && widget.sourceType == RequestSourceType.teamRequests
          ? RequestSourceType.processedRequests
          : widget.sourceType ?? RequestSourceType.myRequests;

  LeaveRequestsQuery _buildQuery() => LeaveRequestsQuery(
    scope: _effectiveSourceType.scope,
    search: searchQuery,
    status: statusFilter,
    month: selectedMonth,
    sortKey: _query?.sortKey ?? LeaveRequestSortKey.createdAt,
    sortAscending: _query?.sortAscending ?? false,
    locale: Localizations.localeOf(context).languageCode,
  );

  /// Re-issues the query and sends the table back to page 1.
  ///
  /// Going back to page 1 is not cosmetic: after a filter change the row at
  /// offset 200 is a different row, so staying put would show an arbitrary
  /// slice of the new result set.
  void _applyQuery(LeaveRequestsQuery next) {
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
    if (!FeatureFlags.serverPagedLeaveRequests) return;
    _applyQuery(_buildQuery());
  }

  /// Column sort. Server-paged sorts must go through the query — sorting the
  /// rows currently in memory would only order the visible page, so paging past
  /// it would reveal unsorted rows.
  void _sortColumn(LeaveRequestSortKey key, int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
    _applyQuery(_buildQuery().copyWith(sortKey: key, sortAscending: ascending));
  }

  void _sort<T>(Comparable<T> Function(dynamic d) getField, int columnIndex, bool ascending) {
    _dataSource.sort<T>(getField, ascending);
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
    });
  }

  /// Dispatches a column sort to whichever paging mode is active.
  ///
  /// [serverKey] is the key captured when the column was built, rather than a
  /// lookup by index: the column set changes with the tab, so an index resolved
  /// at tap time could name a different column than the one the user clicked.
  void _onSort<T>(
    LeaveRequestSortKey serverKey,
    Comparable<T> Function(dynamic d) legacyGetField,
    int columnIndex,
    bool ascending,
  ) {
    if (FeatureFlags.serverPagedLeaveRequests) {
      _sortColumn(serverKey, columnIndex, ascending);
    } else {
      _sort<T>(legacyGetField, columnIndex, ascending);
    }
  }

  void _refreshRequests() {
    final userCode = context.read<UserBloc>().state.user?.id ?? 0;
    context.read<UserRequestsBloc>().add(loadRequestsEvent(userCode, _effectiveSourceType));
  }

  @override
  void dispose() {
    _paginator.dispose();
    super.dispose();
  }

  /// Filters leave requests based on search query, status filter, and month
  List<LeaveRequestModel> _filterRequests(List<LeaveRequestModel> requests) {
    return requests.where((request) {
      // Apply search filter (search by name and user code)
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
      if (selectedMonth != null && request.dateFrom != null) {
        if (request.dateFrom!.year != selectedMonth!.year || request.dateFrom!.month != selectedMonth!.month) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Filters cancellation requests based on search query, status filter, and month
  List<LeaveCancellationRequestModel> _filterCancellationRequests(
    List<LeaveCancellationRequestModel> cancellationRequests,
  ) {
    return cancellationRequests.where((request) {
      // Apply search filter (search by name and user code)
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
      if (selectedMonth != null && request.originalLeaveFrom != null) {
        if (request.originalLeaveFrom!.year != selectedMonth!.year ||
            request.originalLeaveFrom!.month != selectedMonth!.month) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  Widget _buildRequestDetailsContent(LeaveRequestModel request, BuildContext context) {
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
                    Text("${AppLocalizations.of(context)!.dateFrom}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(DateFormat('yyyy-MM-dd').format(request.dateFrom!)),
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
                    Text("${AppLocalizations.of(context)!.dateTo}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(DateFormat('yyyy-MM-dd').format(request.dateTo!)),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
                child: Row(
                  children: [
                    Text("${AppLocalizations.of(context)!.leaveType}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(request.getLocalizedLeaveType(context)),
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
                      request.numberOfDays! >= 1
                          ? "${AppLocalizations.of(context)!.numberOfDays}: "
                          : "${AppLocalizations.of(context)!.numOfHours}: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      request.numberOfDays! >= 1
                          ? request.numberOfDays.toString()
                          : '${request.numberOfDays! * (request.userShiftHours ?? 8)} ${AppLocalizations.of(context)!.hoursLabel}',
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
                child: Row(
                  children: [
                    Text(
                      "${AppLocalizations.of(context)!.leaveBalance}: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      request.userLeaveBalance != null
                          ? "${request.userLeaveBalance.toString()} ${AppLocalizations.of(context)!.days}"
                          : AppLocalizations.of(context)!.notAvailable,
                    ),
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
                      "${AppLocalizations.of(context)!.overTimeBalance}: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      request.userOvertimeBalance != null
                          ? (request.userOvertimeBalance! > 1
                              ? "${request.userOvertimeBalance!.toStringAsFixed(2)} ${AppLocalizations.of(context)!.days}"
                              : "${(request.userOvertimeBalance! * (request.userShiftHours ?? 8)).toStringAsFixed(2)} ${AppLocalizations.of(context)!.hoursLabel}")
                          : AppLocalizations.of(context)!.notAvailable,
                    ),
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
          if (request.leaveType == LeaveType.sick.label) ...[
            const SizedBox(height: 16),
            Text("${AppLocalizations.of(context)!.sickNotes}:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (request.attachments != null && request.attachments!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    request.attachments!.map((link) {
                      return MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            launchUrl(Uri.parse(link));
                          },
                          child: Text(
                            "${AppLocalizations.of(context)!.sickNote} ${request.attachments!.indexOf(link) + 1}",
                            style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                          ),
                        ),
                      );
                    }).toList(),
              )
            else
              Text(AppLocalizations.of(context)!.noSickAvail),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildCancellationRequestDetailsContent(LeaveCancellationRequestModel request, BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 550,
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
                      Text(
                        "${AppLocalizations.of(context)!.requestId}: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(request.originalLeaveRequestId.toString()),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
                  child: Row(
                    children: [
                      Text(
                        "${AppLocalizations.of(context)!.createdAt}: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${DateFormat('yyyy-MM-dd').format(request.tzCreatedAt)}${DateFormat('hh:mm a').format(request.tzCreatedAt)}',
                      ),
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
                    Text("${AppLocalizations.of(context)!.requestor}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      Localizations.localeOf(context).languageCode == "ar"
                          ? request.userArabicName ?? ''
                          : request.userEnglishName ?? '',
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05, minWidth: 195),
                  child: Row(
                    children: [
                      Text(
                        "${AppLocalizations.of(context)!.dateFrom}: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        request.originalLeaveFrom != null
                            ? DateFormat('yyyy-MM-dd').format(request.originalLeaveFrom!)
                            : '',
                      ),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
                  child: Row(
                    children: [
                      Text("${AppLocalizations.of(context)!.dateTo}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        request.originalLeaveTo != null
                            ? DateFormat('yyyy-MM-dd').format(request.originalLeaveTo!)
                            : '',
                      ),
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
                        "${AppLocalizations.of(context)!.leaveType}: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(request.getLocalizedOriginalLeaveType(context)),
                    ],
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
                  child: Row(
                    children: [
                      Text(
                        "${AppLocalizations.of(context)!.numberOfDays}: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(request.originalNumberOfDays?.toString() ?? ''),
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
                    constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05, minWidth: 195),
                    child: Row(
                      children: [
                        Text(() {
                          final bool isDeclinedByN1 =
                              request.status?.toLowerCase() == 'declined' &&
                              request.currentApprover?.toLowerCase() == 'n1';
                          return isDeclinedByN1
                              ? "${AppLocalizations.of(context)!.declinedByN1}: "
                              : "${AppLocalizations.of(context)!.approvedByN1}: ";
                        }(), style: TextStyle(fontWeight: FontWeight.bold)),
                        Flexible(
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? "${request.n1ArabicName ?? 'N+1'} ${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(request.n1ApprovalDate!)}"
                                : "${request.n1EnglishName ?? 'N+1'} ${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(request.n1ApprovalDate!)}",
                          ),
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
                    constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05, minWidth: 195),
                    child: Row(
                      children: [
                        Text(() {
                          final bool isDeclinedByN2 =
                              request.status?.toLowerCase() == 'declined' &&
                              request.currentApprover?.toLowerCase() == 'n2';
                          return isDeclinedByN2
                              ? "${AppLocalizations.of(context)!.declinedByN2}: "
                              : "${AppLocalizations.of(context)!.approvedByN2}: ";
                        }(), style: TextStyle(fontWeight: FontWeight.bold)),
                        Flexible(
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? "${request.n2ArabicName ?? 'N+2'} ${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(request.n2ApprovalDate!)}"
                                : "${request.n2EnglishName ?? 'N+2'} ${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(request.n2ApprovalDate!)}",
                          ),
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
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${AppLocalizations.of(context)!.reason}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ConstrainedBox(constraints: BoxConstraints(maxWidth: 400), child: Text(request.reason, maxLines: 3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancellationApprovalConfirmationDialog(LeaveCancellationRequestModel request) {
    showDialog(
      context: context,
      builder: (childContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.approve),
          content: _buildCancellationRequestDetailsContent(request, context),
          actions: [
            Align(
              alignment: Alignment.center,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 260,
                  child: Row(
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
                          context.read<UserRequestsBloc>().add(
                            ApproveCancellationRequest(
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
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showApprovalConfirmationDialog(LeaveRequestModel request) {
    showDialog(
      context: context,
      builder: (childContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.approve),
          content: _buildRequestDetailsContent(request, context),
          actions: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
                      context.read<UserRequestsBloc>().add(
                        ApproveRequest(
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
              // Clears the filters and switches tab in the one order that
              // works, and re-queries once for the tab being switched TO.
              switchProcessedTab(selection.first == 'processed');
              // Reloads the scope-wide facts: months and the empty-state gate
              // both differ between Actionable and Processed.
              _refreshRequests();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserRequestsBloc, UserRequestsState>(
      listener: (context, state) {
        if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.failure?.message ?? '')));
        }

        if (state.cancelStatus == Status.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestCancelledSuccessfully)));
          context.read<UserRequestsBloc>().add(ResetCancelStatus());
        } else if (state.cancelStatus == Status.failure && state.operationFailure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.operationFailure?.message ?? AppLocalizations.of(context)!.errorCancellingRequest),
            ),
          );
          context.read<UserRequestsBloc>().add(ResetCancelStatus());
        }

        // Handle cancellation request status
        if (state.cancellationRequestStatus == Status.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.cancellationRequestSubmittedSuccessfully)),
          );
          context.read<UserRequestsBloc>().add(ResetCancelStatus());
        } else if (state.cancellationRequestStatus == Status.failure && state.operationFailure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.operationFailure?.message ?? AppLocalizations.of(context)!.errorSubmittingCancellationRequest,
              ),
            ),
          );
          context.read<UserRequestsBloc>().add(ResetCancelStatus());
        }
      },
      builder: (context, state) {
        // NOTE: deliberately no `if (status == loading) return Scaffold(...)`.
        // That returned a bare Scaffold rather than MainLayout, so the AppBar,
        // sidebar, tab switcher and filter bar all vanished on page entry, on
        // the Actionable/Processed switch, and on every approve/decline. The
        // paged table shows its own spinner inside its box (see `loading:` in
        // _buildTable) and a row shows one on the tapped button, so a
        // screen-level loader has nothing left to do. Do not re-add it.

        // Server-paged: these two describe the WHOLE scope, so they come from
        // the bloc rather than from whatever rows happen to be on this page.
        final availableMonths =
            FeatureFlags.serverPagedLeaveRequests
                ? state.availableMonths.toSet()
                : RequestMonthUtils.calculateAvailableMonthsFromMultiple([
                  state.requests.map((r) => r.dateFrom).toList(),
                  state.cancellationRequests.map((r) => r.originalLeaveFrom).toList(),
                ]);

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
        // `|| tableShowingRows` is a backstop, not the mechanism: the probe now
        // derives from the same RPC as the list (see
        // LeaveRequestsRepoImpl.hasAnyRequests), so the two should never
        // disagree. When they did, this screen painted the rows and then threw
        // them away for the empty state. The table is holding the evidence, so
        // a populated one always wins over a probe that says otherwise.
        final tableShowingRows =
            _asyncDataSource != null && !_asyncDataSource!.isStale && _asyncDataSource!.rowCount > 0;
        final hasRequests =
            FeatureFlags.serverPagedLeaveRequests
                ? ((state.hasAnyRequests ?? true) || tableShowingRows)
                : widget.sourceType == RequestSourceType.teamRequests
                ? (state.requests.isNotEmpty || state.cancellationRequests.isNotEmpty)
                : state.requests.isNotEmpty;

        if (!hasRequests) {
          return MainLayout(
            child: LayoutBuilder(
              builder:
                  (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                                // Only show search in Team Requests, not in My Requests
                                showSearch: widget.sourceType == RequestSourceType.teamRequests,
                                // Hide status filter in Actionable mode (all are pending)
                                showStatus:
                                    widget.sourceType != RequestSourceType.teamRequests || showProcessedRequests,
                                availableMonths: availableMonths,
                              ),
                            ),
                            SizedBox(
                              height: context.screenHeight * 0.8,
                              child: Center(
                                child: Text(
                                  AppLocalizations.of(context)!.noLeaveRequestsFound,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.grey),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            ),
          );
        }

        if (FeatureFlags.serverPagedLeaveRequests) {
          // Built once and kept: recreating it would discard the fetched page
          // and re-issue the request on every rebuild.
          _asyncDataSource ??= _LeaveRequestsAsyncSource(
            repo: context.read<LeaveRequestsRepo>(),
            query: _query ??= _buildQuery(),
            rowSourceFactory:
                (pageRows, hasActionable, query) => _makeDataSource(
                  requests: const [],
                  cancellations: const [],
                  // MUST be a constant, not derived from this page. The
                  // Request Type column is always present on the paged path
                  // (see _buildColumns), and this flag decides whether the
                  // matching CELL is emitted. Deriving it per page would drop
                  // the cell on any page that happened to contain no
                  // cancellation rows, and a row with fewer cells than columns
                  // is a hard assertion failure, not a layout glitch.
                  hasOriginalCancellationRequests: true,
                  // Always show the Actions column outside the processed tab.
                  // Deriving it per page would let the column list and the cell
                  // list disagree mid-frame, which is a hard crash
                  // (columns.length != cells.length), not a cosmetic glitch.
                  //
                  // Read from the QUERY this page was fetched for, not from the
                  // live `showProcessedRequests`. The two differ for the length
                  // of a tab switch, and taking the live value would emit cells
                  // for the tab the user just left. Paired with
                  // _LeaveRequestsAsyncSource._isStale — which withholds these
                  // rows until the query catches up — it guarantees the cells
                  // and _buildColumns' header always describe the same tab.
                  shouldShowActionColumn: query.scope != LeaveRequestScope.processed,
                  preOrderedRows: pageRows,
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
        } else if (_shouldRebuildLegacySource(state)) {
          // Apply client-side filtering to both requests and cancellation requests
          final filteredRequests = _filterRequests(state.requests);
          final filteredCancellationRequests = _filterCancellationRequests(state.cancellationRequests);

          // Calculate if action column should be shown based on filtered data
          final shouldShowActionColumn =
              !showProcessedRequests &&
              ((widget.sourceType == RequestSourceType.teamRequests &&
                      (filteredRequests.any((request) => request.isPending) ||
                          filteredCancellationRequests.any((request) => request.isPending))) ||
                  filteredRequests.any(
                    (req) =>
                        req.canBeCancelledDirectly ||
                        req.canRequestCancellation ||
                        (req.cancelled == true &&
                            (widget.sourceType == RequestSourceType.teamRequests && req.removedN1 != true)),
                  ));

          _dataSource = _makeDataSource(
            requests: filteredRequests,
            cancellations: filteredCancellationRequests,
            hasOriginalCancellationRequests: _hasCancellationRows(state),
            shouldShowActionColumn: shouldShowActionColumn,
            isLoading: state.status == Status.loading,
          );

          // Apply default sorting by createdAt (newest first) if no sort is active
          if (_sortColumnIndex == null) {
            _dataSource.sort<DateTime>(
              (d) =>
                  (d is LeaveRequestModel || d is LeaveCancellationRequestModel)
                      ? (d.createdAt ?? DateTime(1900))
                      : DateTime(1900),
              false, // false = descending (newest first)
            );
          }

          // Update previous state trackers
          _previousRequests = state.requests;
          _previousCancellationRequests = state.cancellationRequests;
          _previousSearchQuery = searchQuery;
          _previousStatusFilter = statusFilter;
          _previousSelectedMonth = selectedMonth;
        }

        return _buildScaffold(context, state, availableMonths);
      },
    );
  }

  /// Whether the table can contain cancellation rows, and therefore whether the
  /// Request Type column exists.
  ///
  /// THE single source for this. It is handed to the data source as
  /// `hasOriginalCancellationRequests` and read by `_buildColumns`, so the
  /// header and the cells cannot disagree. On the paged path it is always true:
  /// the server unions cancellation rows into every scope, so any page may
  /// contain one.
  bool _hasCancellationRows(UserRequestsState state) =>
      FeatureFlags.serverPagedLeaveRequests || state.cancellationRequests.isNotEmpty;

  /// Legacy path only: avoid rebuilding the in-memory source when nothing that
  /// feeds it has changed.
  bool _shouldRebuildLegacySource(UserRequestsState state) {
    final dataChanged =
        _previousRequests != state.requests || _previousCancellationRequests != state.cancellationRequests;
    final filtersChanged =
        _previousSearchQuery != searchQuery ||
        _previousStatusFilter != statusFilter ||
        _previousSelectedMonth != selectedMonth;
    return dataChanged || filtersChanged || _previousRequests == null;
  }

  /// Builds the row-rendering source.
  ///
  /// Shared by both paging modes: the legacy path passes the full filtered
  /// lists, the paged path passes a single server-ordered page via
  /// [preOrderedRows]. Keeping one factory means the action callbacks and every
  /// cell builder exist once.
  _LeaveRequestsDataSource _makeDataSource({
    required List<LeaveRequestModel> requests,
    required List<LeaveCancellationRequestModel> cancellations,
    required bool hasOriginalCancellationRequests,
    required bool shouldShowActionColumn,
    List<Map<String, dynamic>>? preOrderedRows,
    bool isLoading = false,
  }) {
    return _LeaveRequestsDataSource(
      requests,
      sourceType: widget.sourceType,
      isLoading: isLoading,
      parentState: this,
      cancellationRequests: cancellations,
      hasOriginalCancellationRequests: hasOriginalCancellationRequests,
      shouldShowActionColumn: shouldShowActionColumn,
      preOrderedRows: preOrderedRows,
      onDeclined: (request, {bool fromDetails = false}) {
        final TextEditingController reasonController = TextEditingController();
        final formKey = GlobalKey<FormState>();

        showDialog(
          context: context,
          builder: (childContext) {
            void onFieldSubmitted() {
              if (formKey.currentState!.validate()) {
                final reason = reasonController.text.trim();
                context.read<UserRequestsBloc>().add(
                  DeclineRequest(
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
              value: context.read<UserRequestsBloc>(),
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
      onApproved: (request, {bool fromDetails = false}) {
        if (fromDetails) {
          // Direct approval from details dialog
          context.read<UserRequestsBloc>().add(
            ApproveRequest(request.id!, request.currentApprover!, context.read<UserBloc>().state.user?.id ?? 0),
          );
        } else {
          // Show confirmation dialog for table row button
          _showApprovalConfirmationDialog(request);
        }
      },
      onCancel: (request) {
        context.read<UserRequestsBloc>().add(CancelRequest(request.id!));
      },
      onRemove: (request) {
        if (widget.sourceType == RequestSourceType.teamRequests) {
          context.read<UserRequestsBloc>().add(RemoveRequestForN1(request.id!));
        } else {
          context.read<UserRequestsBloc>().add(RemoveRequest(request.id!));
        }
      },
      context: context,
    );
  }

  /// Builds one column and records its server sort key at the same index.
  ///
  /// Registration happens here rather than in a parallel list because three
  /// columns are conditional on [UserRequestsContent.sourceType]; a separate
  /// list of keys would silently misalign whenever one of them is absent, and
  /// the table would then sort by the wrong field.
  DataColumn2 _col({
    required String label,
    ColumnSize size = ColumnSize.S,
    LeaveRequestSortKey? sortKey,
    Comparable Function(dynamic d)? legacySortField,
    Widget? customLabel,
  }) {
    final index = _sortKeys.length;
    _sortKeys.add(sortKey);

    final key = sortKey;
    final legacy = legacySortField;
    return DataColumn2(
      size: size,
      label:
          customLabel ?? Center(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
      onSort: (key != null && legacy != null) ? (i, asc) => _onSort(key, legacy, index, asc) : null,
    );
  }

  List<DataColumn2> _buildColumns(BuildContext context, UserRequestsState state) {
    // Cleared per build: the column set changes with the tab, and stale keys
    // would outlive the columns they described.
    _sortKeys.clear();
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    // Must equal what _makeDataSource is given as hasOriginalCancellationRequests.
    final hasCancellationRows = _hasCancellationRows(state);

    return [
      if (_showIdColumn(widget.sourceType))
        _col(
          label: l10n.id,
          sortKey: LeaveRequestSortKey.userId,
          legacySortField:
              (d) => (d is LeaveRequestModel || d is LeaveCancellationRequestModel) ? d.userId.toString() : '',
        ),
      if (_showNameColumn(widget.sourceType))
        _col(
          label: l10n.name,
          size: ColumnSize.L,
          sortKey: LeaveRequestSortKey.employeeName,
          legacySortField: (d) {
            if (d is LeaveRequestModel || d is LeaveCancellationRequestModel) {
              return isArabic ? (d.userArabicName ?? '') : (d.userEnglishName ?? '');
            }
            return '';
          },
        ),
      // Request Type has never been sortable.
      if (_showRequestTypeColumn(widget.sourceType, hasCancellationRows)) _col(label: l10n.requestType),
      _col(
        label: l10n.createdAt,
        sortKey: LeaveRequestSortKey.createdAt,
        legacySortField:
            (d) =>
                (d is LeaveRequestModel || d is LeaveCancellationRequestModel)
                    ? (d.createdAt ?? DateTime(1900))
                    : DateTime(1900),
      ),
      _col(
        label: l10n.dateFrom,
        sortKey: LeaveRequestSortKey.dateFrom,
        legacySortField: (d) {
          if (d is LeaveRequestModel) return d.dateFrom ?? DateTime(1900);
          if (d is LeaveCancellationRequestModel) return d.originalLeaveFrom ?? DateTime(1900);
          return DateTime(1900);
        },
      ),
      _col(
        label: l10n.dateTo,
        sortKey: LeaveRequestSortKey.dateTo,
        legacySortField: (d) {
          if (d is LeaveRequestModel) return d.dateTo ?? DateTime(1900);
          if (d is LeaveCancellationRequestModel) return d.originalLeaveTo ?? DateTime(1900);
          return DateTime(1900);
        },
      ),
      _col(
        label: l10n.leaveType,
        sortKey: LeaveRequestSortKey.leaveType,
        legacySortField: (d) {
          if (d is LeaveRequestModel) return d.leaveType;
          if (d is LeaveCancellationRequestModel) return d.originalLeaveType ?? '';
          return '';
        },
      ),
      _col(
        label: l10n.numberOfDays,
        sortKey: LeaveRequestSortKey.numOfDays,
        legacySortField: (d) {
          if (d is LeaveRequestModel) return d.numberOfDays ?? 0;
          if (d is LeaveCancellationRequestModel) return d.originalNumberOfDays ?? 0;
          return 0;
        },
      ),
      _col(
        label: l10n.status,
        sortKey: LeaveRequestSortKey.status,
        legacySortField: (d) => (d is LeaveRequestModel || d is LeaveCancellationRequestModel) ? (d.status ?? '') : '',
      ),
      _col(
        label: l10n.approver,
        sortKey: LeaveRequestSortKey.currentApprover,
        legacySortField:
            (d) => (d is LeaveRequestModel || d is LeaveCancellationRequestModel) ? (d.currentApprover ?? '') : '',
      ),
      if (FeatureFlags.serverPagedLeaveRequests ? !showProcessedRequests : _dataSource.shouldShowActionColumn)
        _col(
          label: l10n.action,
          size: ColumnSize.L,
          customLabel: Align(
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.action,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),
        ),
    ];
  }

  /// Records the user's page-size choice. Deliberately NOT wrapped in setState.
  ///
  /// `AsyncPaginatedDataTable2` invokes `onRowsPerPageChanged` from inside its
  /// own `build()` — it defers the resize until the fetch resolves, then calls
  /// `super._setRowsPerPage(...)` while building
  /// (async_paginated_data_table_2.dart:504), and that runs this callback inside
  /// a `setState`. Calling `setState` here therefore throws
  /// "setState() called during build".
  ///
  /// Nothing needs repainting anyway: the table owns the live page size, and
  /// `PaginatedDataTable2State.didUpdateWidget` never re-reads the `rowsPerPage`
  /// prop. This field only seeds the next freshly-built table (after a tab
  /// switch, say), so a plain assignment is both sufficient and safe.
  void _onRowsPerPageChanged(int? value) => _rowsPerPage = value ?? _rowsPerPage;

  Widget _buildTable(BuildContext context, UserRequestsState state) {
    final minWidth = context.screenWidth > 1000 ? context.screenWidth * 0.8 : 1300.0;
    final columns = _buildColumns(context, state);

    if (!FeatureFlags.serverPagedLeaveRequests) {
      return PaginatedDataTable2(
        key: tableKey, // Reset pagination when filters change
        minWidth: minWidth,
        smRatio: .4,
        lmRatio: 0.8,
        columnSpacing: 0,
        horizontalMargin: 2,
        showCheckboxColumn: false,
        columns: columns,
        source: _dataSource,
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        rowsPerPage: _rowsPerPage,
        onRowsPerPageChanged: _onRowsPerPageChanged,
      );
    }

    return AsyncPaginatedDataTable2(
      // Deliberately NO `key: tableKey`. A changing key destroys the table's
      // state, detaches the PaginatorController and causes a duplicate fetch.
      // Page resets are explicit instead, via _applyQuery.
      controller: _paginator,
      minWidth: minWidth,
      smRatio: .4,
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
      // Deleting the last row on the last page would otherwise strand the user
      // on a blank page.
      pageSyncApproach: PageSyncApproach.goToLast,
      loading: const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())),
      // Rebuilt from the source's own notifications rather than captured once:
      // the table renders `empty` whenever rowCount is 0, and a stale source
      // reports 0 on purpose (see _LeaveRequestsAsyncSource.isStale). Without
      // this, switching tabs would flash "no leave requests found" behind the
      // spinner for the length of the round trip, and a stale-time capture
      // would then leave the message suppressed on a tab that really is empty.
      empty: ListenableBuilder(
        listenable: _asyncDataSource!,
        builder: (context, _) {
          if (_asyncDataSource!.isStale) return const SizedBox.shrink();
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppLocalizations.of(context)!.noLeaveRequestsFound,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
              ),
            ),
          );
        },
      ),
      // Without this, an auth failure from the RPC renders as a bare default.
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

  Widget _buildScaffold(BuildContext context, UserRequestsState state, Set<DateTime> availableMonths) {
    return MainLayout(
      title:
          widget.sourceType == RequestSourceType.teamRequests
              ? AppLocalizations.of(context)!.teamRequests
              : AppLocalizations.of(context)!.myRequests,
      child: LayoutBuilder(
        builder:
            (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                        // Only show search in Team Requests, not in My Requests
                        showSearch: widget.sourceType == RequestSourceType.teamRequests,
                        // Hide status filter in Actionable mode (all are pending)
                        showStatus: widget.sourceType != RequestSourceType.teamRequests || showProcessedRequests,
                        availableMonths: availableMonths,
                      ),
                    ),
                    SizedBox(
                      width: context.screenWidth > 1000 ? context.screenWidth * 0.9 : 1300,
                      height: context.screenHeight * 0.8,
                      child: _buildTable(context, state),
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }
}

class _LeaveRequestsDataSource extends DataTableSource {
  final List<LeaveRequestModel> _requests;
  final List<LeaveCancellationRequestModel> cancellationRequests;
  final RequestSourceType? sourceType;
  final bool isLoading;
  final Function(LeaveRequestModel, {bool fromDetails})? onApproved;
  final Function(LeaveRequestModel request, {bool fromDetails})? onDeclined;
  final Function(LeaveRequestModel)? onCancel;
  final Function(LeaveRequestModel)? onRemove;
  final BuildContext context;
  final _UserRequestsContentState parentState;
  final bool hasOriginalCancellationRequests;
  final bool shouldShowActionColumn;

  /// One page of rows already merged and ordered by the server.
  ///
  /// When set, [_mixedRequests] returns it untouched: re-sorting here would
  /// undo the server's ORDER BY and scramble the page boundaries. Entries use
  /// the same `{'type', 'data', 'createdAt'}` shape the client-side merge
  /// produces, so [getRow] and every row builder work unchanged.
  ///
  /// Setting this also sidesteps the fact that [_mixedRequests] re-merges and
  /// re-sorts on *every* getRow call.
  final List<Map<String, dynamic>>? preOrderedRows;

  Comparable Function(dynamic)? _sortFieldGetter;
  bool _sortAscending = true;

  _LeaveRequestsDataSource(
    this._requests, {
    this.cancellationRequests = const [],
    this.sourceType = RequestSourceType.myRequests,
    this.isLoading = false,
    this.onApproved,
    this.onDeclined,
    this.onCancel,
    this.onRemove,
    required this.context,
    required this.parentState,
    required this.hasOriginalCancellationRequests,
    required this.shouldShowActionColumn,
    this.preOrderedRows,
  });

  void sort<T>(Comparable<T> Function(dynamic d) getField, bool ascending) {
    _sortFieldGetter = getField;
    _sortAscending = ascending;

    // Also sort the _requests list directly for when there are no cancellation requests
    _requests.sort((a, b) {
      try {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
      } catch (e) {
        return 0;
      }
    });

    notifyListeners();
  }

  // Create a mixed list of both regular requests and cancellation requests for both team and user views
  List<dynamic> get _mixedRequests {
    // Server-paged: the page is already merged, filtered and ordered.
    final preOrdered = preOrderedRows;
    if (preOrdered != null) return preOrdered;

    // Always create mixed list for both team requests and user requests if we have cancellation requests
    if (cancellationRequests.isEmpty) {
      return _requests;
    }

    final mixed = <Map<String, dynamic>>[];

    // Add regular leave requests
    for (final request in _requests) {
      mixed.add({'type': 'leave_request', 'data': request, 'createdAt': request.tzCreatedAt});
    }

    // Add cancellation requests
    for (final cancelRequest in cancellationRequests) {
      mixed.add({'type': 'cancellation_request', 'data': cancelRequest, 'createdAt': cancelRequest.tzCreatedAt});
    }

    // Apply sorting if a sort field is set
    if (_sortFieldGetter != null) {
      mixed.sort((a, b) {
        Comparable? aValue;
        Comparable? bValue;

        try {
          final aData = a['data'];
          aValue = _sortFieldGetter!(aData);
        } catch (e) {
          aValue = null;
        }

        try {
          final bData = b['data'];
          bValue = _sortFieldGetter!(bData);
        } catch (e) {
          bValue = null;
        }

        // Handle null values - put them at the end
        if (aValue == null && bValue == null) return 0;
        if (aValue == null) return _sortAscending ? 1 : -1;
        if (bValue == null) return _sortAscending ? -1 : 1;

        return _sortAscending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
      });
    } else {
      // Default sort by creation date (newest first)
      mixed.sort((a, b) => (b['createdAt'] as DateTime).compareTo(a['createdAt'] as DateTime));
    }

    return mixed;
  }

  @override
  DataRow? getRow(int index) {
    final mixedRequests = _mixedRequests;
    if (index >= mixedRequests.length) return null;

    // Handle mixed requests for both team and user views when we have cancellation requests
    if (mixedRequests.isNotEmpty && mixedRequests[0] is Map<String, dynamic>) {
      final item = mixedRequests[index] as Map<String, dynamic>;
      final type = item['type'] as String;

      if (type == 'leave_request') {
        final request = item['data'] as LeaveRequestModel;
        return _buildLeaveRequestRow(request, index);
      } else {
        final cancelRequest = item['data'] as LeaveCancellationRequestModel;
        return _buildCancellationRequestRow(cancelRequest, index);
      }
    }

    // Handle regular requests when no cancellation requests exist
    final request = _requests[index];
    final dateFormatter = DateFormat('yyyy-MM-dd');
    return DataRow(
      onSelectChanged: (value) {
        if (value == true) {
          _showRequestDetailsDialog(request, context);
        }
      },
      cells: [
        if (_showIdColumn(sourceType))
          DataCell(Center(child: Text(request.userId.toString(), style: TextStyle(fontSize: 12)))),
        if (_showNameColumn(sourceType))
          DataCell(
            Center(
              child: Text(
                Localizations.localeOf(context).languageCode == "ar"
                    ? request.userArabicName!
                    : request.userEnglishName!,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        if (_showRequestTypeColumn(sourceType, hasOriginalCancellationRequests))
          DataCell(Center(child: Text(AppLocalizations.of(context)!.leaveRequest, style: TextStyle(fontSize: 12)))),
        DataCell(
          Center(
            child: Text(
              '${DateFormat('yyyy-MM-dd').format(request.tzCreatedAt)}\n${DateFormat('hh:mm a').format(request.tzCreatedAt)}',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
        DataCell(Center(child: Text(dateFormatter.format(request.dateFrom!), style: TextStyle(fontSize: 12)))),
        DataCell(Center(child: Text(dateFormatter.format(request.dateTo!), style: TextStyle(fontSize: 12)))),
        DataCell(Center(child: Text(request.getLocalizedLeaveType(context), style: TextStyle(fontSize: 12)))),
        DataCell(
          Center(
            child: Text(
              request.numberOfDays! >= 1
                  ? request.numberOfDays.toString()
                  : '${request.numberOfDays! * (request.userShiftHours ?? 8)} ${AppLocalizations.of(context)!.hoursLabel}',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
        DataCell(Center(child: Text(request.getLocalizedStatus(context), style: TextStyle(fontSize: 12)))),
        DataCell(Center(child: Text(request.getLocalizedApproverName(context), style: TextStyle(fontSize: 12)))),
        if (shouldShowActionColumn)
          (sourceType == RequestSourceType.teamRequests && request.isPending)
              ? DataCell(
                Center(
                  child:
                      request.isPending
                          ? RowApproveDeclineActions<UserRequestsBloc, UserRequestsState>(
                            isProcessing: (state) => request.id != null && state.processingRequestId == request.id,
                            legacyIsLoading: isLoading,
                            onApprove: () => onApproved?.call(request),
                            onDecline: () => onDeclined?.call(request),
                          )
                          : null,
                ),
              )
              // No whole-list gate here. This used to be
              // `_requests.any((req) => req.canBeCancelledDirectly || ...)`,
              // which is meaningless on the server-paged path: rows arrive via
              // preOrderedRows, so _requests is empty, the gate was always
              // false, and the Cancel / Request Cancellation button disappeared
              // from rows that should have had it. The per-row ternary below
              // already decides what to render, and yields a null child when
              // this row has no action — visually identical to the
              // DataCell(Container()) the gate used to fall through to, so
              // dropping it changes nothing for the client-paged path either.
              : DataCell(
                Center(
                  child:
                      (request.canBeCancelledDirectly || request.canRequestCancellation) &&
                              sourceType == RequestSourceType.myRequests
                          ? AppButton(
                            width: 168,
                            padding: const EdgeInsets.all(4),
                            margin: EdgeInsets.all(4),
                            onPressed:
                                () =>
                                    request.canBeCancelledDirectly
                                        ? _showCancelConfirmationDialog(request)
                                        : _showCancellationRequestDialog(request),
                            label:
                                request.canBeCancelledDirectly
                                    ? AppLocalizations.of(context)!.cancel
                                    : AppLocalizations.of(context)!.requestCancellation,
                            color: Colors.red.shade600,
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

  void _showCancelConfirmationDialog(LeaveRequestModel request) {
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
                    onCancel?.call(request);
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

  void _showCancelConfirmationDialogFromDetails(LeaveRequestModel request, BuildContext detailsDialogContext) {
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
                    onCancel?.call(request);
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

  void _showRemoveConfirmationDialog(LeaveRequestModel request) {
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

  void _showRequestDetailsDialog(LeaveRequestModel request, BuildContext context) {
    showDialog(
      context: context,
      builder: (childContext2) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: context.screenWidth < 600 ? context.screenWidth * 0.95 : 500,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Icon(Icons.description, color: Theme.of(context).primaryColor, size: 24),
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 450,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          AppButton(
                            width: 120,
                            onPressed: () => Navigator.pop(childContext2),
                            label: AppLocalizations.of(context)!.close,
                            color: Colors.blue,
                          ),
                          if (sourceType == RequestSourceType.myRequests &&
                              (request.canBeCancelledDirectly || request.canRequestCancellation)) ...[
                            const SizedBox(width: 16),
                            AppButton(
                              width: 168,
                              onPressed: () {
                                if (request.canBeCancelledDirectly) {
                                  _showCancelConfirmationDialogFromDetails(request, childContext2);
                                } else {
                                  _showCancellationRequestDialogFromDetails(request, childContext2);
                                }
                              },
                              label:
                                  request.canBeCancelledDirectly
                                      ? AppLocalizations.of(context)!.cancelRequest
                                      : AppLocalizations.of(context)!.requestCancellation,
                              color: Colors.red.shade600,
                            ),
                          ],
                          if (sourceType == RequestSourceType.teamRequests &&
                              !parentState.showProcessedRequests &&
                              request.isPending) ...[
                            const SizedBox(width: 16),
                            AppButton(
                              width: 120,
                              onPressed: () {
                                onApproved?.call(request, fromDetails: true);
                                Navigator.pop(childContext2);
                              },
                              label: AppLocalizations.of(context)!.approve,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 16),
                            AppButton(
                              width: 120,
                              onPressed: () {
                                onDeclined?.call(request, fromDetails: true);
                              },
                              label: AppLocalizations.of(context)!.decline,
                              color: Colors.redAccent,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  DataRow _buildLeaveRequestRow(LeaveRequestModel request, int index) {
    final dateFormatter = DateFormat('yyyy-MM-dd');
    return DataRow(
      color: WidgetStateProperty.all(Colors.transparent), // Normal color for leave requests
      onSelectChanged: (value) {
        if (value == true) {
          _showRequestDetailsDialog(request, context);
        }
      },
      cells: [
        if (_showIdColumn(sourceType))
          DataCell(Center(child: Text(request.userId.toString(), style: TextStyle(fontSize: 12)))),
        if (_showNameColumn(sourceType))
          DataCell(
            Center(
              child: Text(
                Localizations.localeOf(context).languageCode == "ar"
                    ? request.userArabicName!
                    : request.userEnglishName!,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        if (_showRequestTypeColumn(sourceType, hasOriginalCancellationRequests))
          DataCell(Center(child: Text(AppLocalizations.of(context)!.leaveRequest, style: TextStyle(fontSize: 12)))),
        DataCell(
          Center(
            child: Text(
              request.createdAt != null
                  ? '${DateFormat('yyyy-MM-dd').format(request.tzCreatedAt)}\n${DateFormat('hh:mm a').format(request.tzCreatedAt)}'
                  : '',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              request.dateFrom != null ? dateFormatter.format(request.dateFrom!) : '',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
        DataCell(
          Center(
            child: Text(
              request.dateTo != null ? dateFormatter.format(request.dateTo!) : '',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
        DataCell(Center(child: Text(request.getLocalizedLeaveType(context), style: TextStyle(fontSize: 12)))),
        DataCell(
          Center(
            child: Text(
              request.numberOfDays != null && request.numberOfDays! >= 1
                  ? request.numberOfDays.toString()
                  : request.numberOfDays != null
                  ? '${request.numberOfDays! * (request.userShiftHours ?? 8)} ${AppLocalizations.of(context)!.hoursLabel}'
                  : '',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
        DataCell(Center(child: Text(request.getLocalizedStatus(context), style: TextStyle(fontSize: 12)))),
        DataCell(Center(child: Text(request.getLocalizedApproverName(context), style: TextStyle(fontSize: 12)))),
        if (shouldShowActionColumn)
          (sourceType == RequestSourceType.teamRequests && request.isPending)
              ? DataCell(
                Center(
                  child:
                      request.isPending
                          ? RowApproveDeclineActions<UserRequestsBloc, UserRequestsState>(
                            isProcessing: (state) => request.id != null && state.processingRequestId == request.id,
                            legacyIsLoading: isLoading,
                            onApprove: () => onApproved?.call(request),
                            onDecline: () => onDeclined?.call(request),
                          )
                          : null,
                ),
              )
              // No whole-list gate here. This used to be
              // `_requests.any((req) => req.canBeCancelledDirectly || ...)`,
              // which is meaningless on the server-paged path: rows arrive via
              // preOrderedRows, so _requests is empty, the gate was always
              // false, and the Cancel / Request Cancellation button disappeared
              // from rows that should have had it. The per-row ternary below
              // already decides what to render, and yields a null child when
              // this row has no action — visually identical to the
              // DataCell(Container()) the gate used to fall through to, so
              // dropping it changes nothing for the client-paged path either.
              : DataCell(
                Center(
                  child:
                      (request.canBeCancelledDirectly || request.canRequestCancellation) &&
                              sourceType == RequestSourceType.myRequests
                          ? AppButton(
                            width: 168,
                            padding: const EdgeInsets.all(4),
                            margin: EdgeInsets.all(4),
                            onPressed:
                                () =>
                                    request.canBeCancelledDirectly
                                        ? _showCancelConfirmationDialog(request)
                                        : _showCancellationRequestDialog(request),
                            label:
                                request.canBeCancelledDirectly
                                    ? AppLocalizations.of(context)!.cancel
                                    : AppLocalizations.of(context)!.requestCancellation,
                            color: Colors.red.shade600,
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

  DataRow _buildCancellationRequestRow(LeaveCancellationRequestModel request, int index) {
    final dateFormatter = DateFormat('yyyy-MM-dd');
    return DataRow(
      color: WidgetStateProperty.all(Colors.orange.shade100), // Orange color for cancellation requests
      onSelectChanged: (value) {
        if (value == true) {
          _showCancellationRequestDetailsDialog(request, context);
        }
      },
      cells: [
        if (_showIdColumn(sourceType))
          DataCell(Center(child: Text(request.userId.toString(), style: TextStyle(fontSize: 12)))),
        if (_showNameColumn(sourceType))
          DataCell(
            Center(
              child: Text(
                Localizations.localeOf(context).languageCode == "ar"
                    ? request.userArabicName ?? ''
                    : request.userEnglishName ?? '',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        // MUST match _buildLeaveRequestRow's Request Type condition exactly, and
        // the Request Type column in _buildColumns. This used to read
        // `cancellationRequests.isNotEmpty`, which is empty on the server-paged
        // path (rows arrive via preOrderedRows), so a page containing a
        // cancellation request emitted one cell fewer than it had columns —
        // "All rows must have the same number of cells".
        if (_showRequestTypeColumn(sourceType, hasOriginalCancellationRequests))
          DataCell(
            Center(
              child: Text(
                textAlign: TextAlign.center,
                AppLocalizations.of(context)!.requestCancellation,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        DataCell(
          Center(
            child: Text(
              request.createdAt != null
                  ? '${DateFormat('yyyy-MM-dd').format(request.tzCreatedAt)}\n${DateFormat('hh:mm a').format(request.tzCreatedAt)}'
                  : '',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ), // Created At
        DataCell(
          Center(
            child: Text(
              request.originalLeaveFrom != null ? dateFormatter.format(request.originalLeaveFrom!) : '',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ), // Date From
        DataCell(
          Center(
            child: Text(
              request.originalLeaveTo != null ? dateFormatter.format(request.originalLeaveTo!) : '',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ), // Date To
        DataCell(
          Center(child: Text(request.getLocalizedOriginalLeaveType(context), style: TextStyle(fontSize: 12))),
        ), // Leave Type
        DataCell(
          Center(child: Text(request.originalNumberOfDays?.toString() ?? '', style: TextStyle(fontSize: 12))),
        ), // Number of Days
        DataCell(Center(child: Text(request.getLocalizedStatus(context), style: TextStyle(fontSize: 12)))), // Status
        DataCell(Center(child: Text(request.getLocalizedApproverName(context), style: TextStyle(fontSize: 12)))),
        // Exactly one cell whenever the column exists. The approve/decline pair
        // is decided by this row alone, so it lives in the cell's child rather
        // than in a ternary that picks between two different DataCells.
        if (shouldShowActionColumn)
          DataCell(
            Center(
              child:
                  (sourceType == RequestSourceType.teamRequests && request.isPending)
                      ? RowApproveDeclineActions<UserRequestsBloc, UserRequestsState>(
                        // The cancellation's own id — that is what
                        // Approve/DeclineCancellationRequest carry. Different id
                        // space from the leave rows above.
                        isProcessing:
                            (state) => request.id != null && state.processingCancellationRequestId == request.id,
                        legacyIsLoading: isLoading,
                        onApprove: () => _approveCancellationRequest(request),
                        onDecline: () => _declineCancellationRequest(request),
                      )
                      : null,
            ),
          ),
      ],
    );
  }

  void _approveCancellationRequest(LeaveCancellationRequestModel request) {
    parentState._showCancellationApprovalConfirmationDialog(request);
  }

  void _declineCancellationRequest(LeaveCancellationRequestModel request) {
    final TextEditingController reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (childContext) {
        void onFieldSubmitted() {
          if (formKey.currentState!.validate()) {
            final reason = reasonController.text.trim();
            context.read<UserRequestsBloc>().add(
              DeclineCancellationRequest(
                request.id!,
                request.currentApprover!,
                context.read<UserBloc>().state.user?.id ?? 0,
                reason,
              ),
            );
            Navigator.pop(childContext);
          }
        }

        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.declineRequest),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Add cancellation request context
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.leaveCancellationRequest,
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "${AppLocalizations.of(context)!.requestor}: ${Localizations.localeOf(context).languageCode == "ar" ? request.userArabicName ?? '' : request.userEnglishName ?? ''}",
                              style: TextStyle(fontSize: 13),
                            ),
                            Text(
                              "${AppLocalizations.of(context)!.reason}: ${request.reason}",
                              style: TextStyle(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.provideDeclinereason),
                SizedBox(height: 16),
                AppTextField(
                  controller: reasonController,
                  label: AppLocalizations.of(context)!.reason,
                  onFieldSubmitted: (_) => onFieldSubmitted(),
                  isReasonField: true,
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  onPressed: () => Navigator.pop(childContext),
                  label: AppLocalizations.of(context)!.cancel,
                  color: Colors.grey,
                  width: kIsWeb ? 120 : context.screenWidth * 0.25,
                ),
                const SizedBox(width: 16),
                AppButton(
                  onPressed: onFieldSubmitted,
                  label: AppLocalizations.of(context)!.decline,
                  color: Colors.red,
                  width: kIsWeb ? 120 : context.screenWidth * 0.25,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showCancellationRequestDetailsDialog(LeaveCancellationRequestModel request, BuildContext context) {
    final dateFormatter = DateFormat('yyyy-MM-dd');
    showDialog(
      context: context,
      builder: (BuildContext childContext2) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            child: Container(
              width: context.screenWidth < 600 ? context.screenWidth * 0.95 : 500,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),

              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      child: Row(
                        children: [
                          Icon(Icons.description, color: Theme.of(context).primaryColor, size: 24),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.leaveCancellationRequest,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: context.screenWidth < 600 ? 16 : 20,
                              ),
                            ),
                          ),
                          IconButton(onPressed: () => Navigator.pop(childContext2), icon: const Icon(Icons.close)),
                        ],
                      ),
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Padding(
                        padding: context.screenWidth > 600 ? const EdgeInsets.only(left: 24.0) : EdgeInsets.zero,
                        child: SizedBox(
                          width: 400,
                          child: Column(
                            children: [
                              _buildDetailRow(
                                AppLocalizations.of(context)!.requestId,
                                request.originalLeaveRequestId.toString(),
                              ),
                              if (sourceType == RequestSourceType.teamRequests)
                                _buildDetailRow(
                                  AppLocalizations.of(context)!.requestor,
                                  Localizations.localeOf(context).languageCode == "ar"
                                      ? request.userArabicName ?? ''
                                      : request.userEnglishName ?? '',
                                ),
                              if (sourceType == RequestSourceType.teamRequests)
                                _buildDetailRow(
                                  AppLocalizations.of(context)!.title,
                                  Localizations.localeOf(context).languageCode == "ar"
                                      ? (request.userTitle ?? '')
                                      : (request.userEnglishTitle ?? request.userTitle ?? ''),
                                ),
                              if (sourceType == RequestSourceType.teamRequests)
                                _buildDetailRow(
                                  AppLocalizations.of(context)!.department,
                                  Localizations.localeOf(context).languageCode == "ar"
                                      ? (request.userDepartment ?? '')
                                      : (request.userEnglishDepartment ?? request.userDepartment ?? ''),
                                ),
                              if (sourceType == RequestSourceType.teamRequests)
                                _buildDetailRow(AppLocalizations.of(context)!.hireDate, request.userHireDate ?? ''),
                              _buildDetailRow(
                                AppLocalizations.of(context)!.createdAt,
                                request.createdAt != null
                                    ? DateFormat('yyyy-MM-dd hh:mm a').format(request.tzCreatedAt)
                                    : '',
                              ),
                              _buildDetailRow(
                                AppLocalizations.of(context)!.leaveType,
                                request.getLocalizedOriginalLeaveType(context),
                              ),
                              _buildDetailRow(
                                AppLocalizations.of(context)!.dateFrom,
                                request.originalLeaveFrom != null
                                    ? dateFormatter.format(request.originalLeaveFrom!)
                                    : '',
                              ),
                              _buildDetailRow(
                                AppLocalizations.of(context)!.dateTo,
                                request.originalLeaveTo != null ? dateFormatter.format(request.originalLeaveTo!) : '',
                              ),
                              _buildDetailRow(
                                AppLocalizations.of(context)!.numberOfDays,
                                request.originalNumberOfDays?.toString() ?? '',
                              ),
                              _buildDetailRow(AppLocalizations.of(context)!.reason, request.reason),
                              _buildDetailRow(
                                AppLocalizations.of(context)!.status,
                                request.getLocalizedStatus(context),
                              ),
                              if (request.status == 'pending')
                                _buildDetailRow(
                                  AppLocalizations.of(context)!.currentApprover,
                                  request.getLocalizedApproverName(context),
                                ),
                              // Approval History
                              if (request.n1ApprovalDate != null)
                                _buildDetailRow(
                                  AppLocalizations.of(context)!.approvedByN1,
                                  Localizations.localeOf(context).languageCode == 'ar'
                                      ? "${request.n1ArabicName ?? 'N+1'} ${AppLocalizations.of(context)!.on} ${dateFormatter.format(request.n1ApprovalDate!)}"
                                      : "${request.n1EnglishName ?? 'N+1'} ${AppLocalizations.of(context)!.on} ${dateFormatter.format(request.n1ApprovalDate!)}",
                                ),
                              if (request.n2ApprovalDate != null)
                                _buildDetailRow(
                                  AppLocalizations.of(context)!.approvedByN2,
                                  Localizations.localeOf(context).languageCode == 'ar'
                                      ? "${request.n2ArabicName ?? 'N+2'} ${AppLocalizations.of(context)!.on} ${dateFormatter.format(request.n2ApprovalDate!)}"
                                      : "${request.n2EnglishName ?? 'N+2'} ${AppLocalizations.of(context)!.on} ${dateFormatter.format(request.n2ApprovalDate!)}",
                                ),
                              if (request.hrApprovalDate != null)
                                _buildDetailRow(
                                  () {
                                    final bool isDeclinedByHR =
                                        request.status?.toLowerCase() == 'declined' &&
                                        request.currentApprover?.toLowerCase() == 'hr';
                                    return isDeclinedByHR
                                        ? AppLocalizations.of(context)!.declinedByHR
                                        : AppLocalizations.of(context)!.approvedByHR;
                                  }(),
                                  () {
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
                                      return "$approverName ${AppLocalizations.of(context)!.on} ${dateFormatter.format(request.hrApprovalDate!)}";
                                    } else {
                                      return "${AppLocalizations.of(context)!.on} ${dateFormatter.format(request.hrApprovalDate!)}";
                                    }
                                  }(),
                                ),
                              if (request.declineReason != null && request.declineReason!.isNotEmpty)
                                _buildDetailRow(AppLocalizations.of(context)!.declineReason, request.declineReason!),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 24.0, left: context.screenWidth > 600 ? 24.0 : 0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: 400,
                          child: Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  width: 120,
                                  onPressed: () => Navigator.pop(childContext2),
                                  label: AppLocalizations.of(context)!.close,
                                  color: Colors.blue,
                                ),
                              ),
                              if (request.isPending &&
                                  !parentState.showProcessedRequests &&
                                  sourceType == RequestSourceType.teamRequests) ...[
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppButton(
                                    width: 120,
                                    onPressed: () {
                                      Navigator.of(childContext2).pop();
                                      context.read<UserRequestsBloc>().add(
                                        ApproveCancellationRequest(
                                          request.id!,
                                          request.currentApprover!,
                                          context.read<UserBloc>().state.user?.id ?? 0,
                                        ),
                                      );
                                    },
                                    label: AppLocalizations.of(context)!.approve,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AppButton(
                                    width: 120,
                                    onPressed: () {
                                      Navigator.of(childContext2).pop();
                                      _declineCancellationRequest(request);
                                    },
                                    label: AppLocalizations.of(context)!.decline,
                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  int get rowCount => _mixedRequests.length;

  @override
  bool get isRowCountApproximate => false;

  void _showCancellationRequestDialog(LeaveRequestModel request) {
    final TextEditingController reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        void onFieldSubmitted() {
          if (formKey.currentState!.validate()) {
            final reason = reasonController.text.trim();
            context.read<UserRequestsBloc>().add(RequestCancellation(request.id!, reason));
            Navigator.pop(dialogContext);
          }
        }

        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.requestCancellation),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context)!.cancellationRequestMessage),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: reasonController,
                        label: AppLocalizations.of(context)!.reason,
                        onFieldSubmitted: (_) => onFieldSubmitted(),
                        isReasonField: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  label: AppLocalizations.of(context)!.cancel,
                  color: Colors.grey,
                  width: kIsWeb ? 120 : context.screenWidth * 0.25,
                ),
                const SizedBox(width: 16),
                AppButton(
                  onPressed: onFieldSubmitted,
                  label: AppLocalizations.of(context)!.submit,
                  color: Colors.red,
                  width: kIsWeb ? 150 : context.screenWidth * 0.3,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  void _showCancellationRequestDialogFromDetails(LeaveRequestModel request, BuildContext detailsDialogContext) {
    final TextEditingController reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        void onFieldSubmitted() {
          if (formKey.currentState!.validate()) {
            final reason = reasonController.text.trim();
            Navigator.of(dialogContext).pop(); // Close reason dialog
            Navigator.of(detailsDialogContext).pop(); // Close details dialog
            context.read<UserRequestsBloc>().add(RequestCancellation(request.id!, reason));
          }
        }

        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.requestCancellation),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(AppLocalizations.of(context)!.cancellationRequestMessage),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: reasonController,
                          label: AppLocalizations.of(context)!.reason,
                          onFieldSubmitted: (_) => onFieldSubmitted(),
                          isReasonField: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  label: AppLocalizations.of(context)!.cancel,
                  color: Colors.grey,
                  width: kIsWeb ? 120 : context.screenWidth * 0.25,
                ),
                const SizedBox(width: 16),
                AppButton(
                  onPressed: onFieldSubmitted,
                  label: AppLocalizations.of(context)!.submit,
                  color: Colors.red,
                  width: kIsWeb ? 150 : context.screenWidth * 0.3,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  int get selectedRowCount => 0;
}

/// Fetches one page at a time from `list_user_leave_requests`.
///
/// Row *rendering* is not duplicated here: [getRows] builds a throwaway
/// [_LeaveRequestsDataSource] over the page it just fetched and calls its
/// `getRow`, so all ~1000 lines of cell layout, detail dialogs and action
/// buttons stay in exactly one place. The `preOrderedRows` constructor argument
/// is what stops that source from re-sorting the page and undoing the server's
/// ORDER BY.
class _LeaveRequestsAsyncSource extends AsyncDataTableSource {
  _LeaveRequestsAsyncSource({required this.repo, required LeaveRequestsQuery query, required this.rowSourceFactory})
    : _query = query;

  final LeaveRequestsRepo repo;

  /// Builds a sync source over a single, already-ordered page. Supplied by the
  /// widget so the row builders keep their `BuildContext` and action callbacks.
  ///
  /// Takes the query the page was fetched FOR, so the cells it emits are decided
  /// by that query rather than by whatever the widget's tab state happens to be
  /// when the fetch resolves. See [_isStale].
  final _LeaveRequestsDataSource Function(
    List<Map<String, dynamic>> pageRows,
    bool hasActionable,
    LeaveRequestsQuery query,
  )
  rowSourceFactory;

  LeaveRequestsQuery _query;
  LeaveRequestsQuery get query => _query;

  /// The query the rows currently in the base class's cache were built for.
  ///
  /// `AsyncDataTableSource` keeps `_rows` across a reload — `AsyncPaginatedDataTable2`
  /// renders the full table underneath its `loading:` overlay rather than
  /// clearing it — so after a query change the cache still holds the PREVIOUS
  /// query's rows for the length of the round trip.
  LeaveRequestsQuery? _renderedQuery;

  /// Whether the cached rows belong to a query that has since been replaced.
  ///
  /// Two things go wrong if such rows are rendered:
  ///   * the Actionable→Processed switch drops the Action column immediately,
  ///     while the cached rows still carry its cell — and a DataRow with more
  ///     cells than there are columns is a hard assertion, which surfaces as a
  ///     red error box, not a glitch;
  ///   * the user sees the old tab's rows (cancellation rows, typically) under
  ///     the spinner before the real ones arrive.
  ///
  /// The screen used to be blanked by a page-level spinner during this window,
  /// which hid both. It no longer is, so the staleness has to be handled here.
  bool get isStale => _renderedQuery != _query;

  bool _hasActionable = false;

  /// Whether ANY row in the whole filtered set has an action available —
  /// computed server-side, so it does not flicker when a page happens to hold
  /// only non-actionable rows.
  bool get hasActionable => _hasActionable;

  /// Swaps in a new query. Returns whether it actually differs, so the caller
  /// can skip a redundant fetch on rebuilds that changed nothing.
  bool setQuery(LeaveRequestsQuery next) {
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
    final page = await repo.getLeaveRequestsPage(query, offset: startIndex, limit: count);
    _hasActionable = page.hasActionable;

    // Same {'type','data','createdAt'} shape the client-side merge produced, so
    // _LeaveRequestsDataSource.getRow needs no special case for paged data.
    final pageRows =
        page.items.map((row) {
          return switch (row) {
            LeaveRequestRow(:final request) => {
              'type': 'leave_request',
              'data': request,
              'createdAt': request.createdAt,
            },
            LeaveCancellationRow(:final request) => {
              'type': 'cancellation_request',
              'data': request,
              'createdAt': request.createdAt,
            },
          };
        }).toList();

    final rowSource = rowSourceFactory(pageRows, page.hasActionable, query);

    // Set only once the rows exist, and to the query THIS fetch was for. If a
    // newer query arrived while this one was in flight, _isStale stays true and
    // the table keeps showing nothing until that newer fetch lands.
    _renderedQuery = query;

    return AsyncRowsResponse(
      // The TOTAL across all pages, not pageRows.length — this is what sizes
      // the paginator.
      page.totalCount,
      [for (var i = 0; i < pageRows.length; i++) rowSource.getRow(i)!],
    );
  }
}
