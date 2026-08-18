import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/request_month_utils.dart';
import 'package:hrms_demo/data/models/businesstrip_cancellation_request_model.dart';
import 'package:hrms_demo/data/models/businesstrip_request_model.dart';
import 'package:hrms_demo/data/models/businesstrip_request_row.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_requests_query.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/user_businesstrip_requests/bloc/user_businesstrip_requests_bloc.dart';
import 'package:hrms_demo/presentation/user_businesstrip_requests/bloc/user_businesstrip_requests_state.dart';
import 'package:hrms_demo/presentation/user_businesstrip_requests/bloc/user_businesstrip_requests_event.dart';
import 'package:hrms_demo/core/utils/search_filter_utils.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/app_text_field.dart';
import 'package:hrms_demo/presentation/widgets/request_filters_mixin.dart';
import 'package:hrms_demo/presentation/widgets/request_filters_widget.dart';
import 'package:hrms_demo/presentation/widgets/row_approve_decline_actions.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:hrms_demo/services/pdf/business_trip_pdf_generation_service.dart';
import 'package:hrms_demo/services/pdf/web_pdf_download.dart'
    if (dart.library.html) 'package:hrms_demo/services/pdf/web_pdf_download_web.dart'
    if (dart.library.io) 'package:hrms_demo/services/pdf/web_pdf_download_io.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

class UserBusinesstripRequestsContent extends StatefulWidget {
  final RequestSourceType? sourceType;
  const UserBusinesstripRequestsContent({super.key, this.sourceType});

  @override
  State<UserBusinesstripRequestsContent> createState() => _UserBusinesstripRequestsContentState();
}

class _UserBusinesstripRequestsContentState extends State<UserBusinesstripRequestsContent> with RequestFiltersMixin {
  int _rowsPerPage = PaginatedDataTable.defaultRowsPerPage;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  late _BusinesstripRequestsDataSource _dataSource;

  // Track previous state to avoid unnecessary data source recreation
  List<BusinesstripRequestModel>? _previousRequests;
  List<BusinesstripCancellationRequestModel>? _previousCancellationRequests;

  // ── Server-paged state (unused when the flag is off) ──────────────────────
  final PaginatorController _paginator = PaginatorController();
  _BusinesstripRequestsAsyncSource? _asyncDataSource;
  BusinesstripRequestsQuery? _query;

  /// Last mutation token seen from the bloc, so a rebuild triggered by
  /// something else does not re-fetch.
  int _lastRefreshToken = 0;

  RequestSourceType get _effectiveSourceType =>
      showProcessedRequests && widget.sourceType == RequestSourceType.teamRequests
          ? RequestSourceType.processedRequests
          : widget.sourceType ?? RequestSourceType.myRequests;

  BusinesstripRequestsQuery _buildQuery() => BusinesstripRequestsQuery(
    scope: _effectiveSourceType.scope,
    search: searchQuery,
    status: statusFilter,
    month: selectedMonth,
    sortKey: _query?.sortKey ?? BusinesstripRequestSortKey.createdAt,
    sortAscending: _query?.sortAscending ?? false,
    locale: Localizations.localeOf(context).languageCode,
  );

  /// Re-issues the query and sends the table back to page 1.
  ///
  /// Going back to page 1 is not cosmetic: after a filter change the row at
  /// offset 200 is a different row, so staying put would show an arbitrary
  /// slice of the new result set.
  void _applyQuery(BusinesstripRequestsQuery next) {
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
    if (!FeatureFlags.serverPagedBusinesstripRequests) return;
    _applyQuery(_buildQuery());
  }

  /// Column sort. Server-paged sorts must go through the query — sorting the
  /// rows currently in memory would only order the visible page, so paging past
  /// it would reveal unsorted rows.
  void _sortColumn(BusinesstripRequestSortKey key, int columnIndex, bool ascending) {
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
  /// [serverKey] is passed by the column that was built, rather than looked up
  /// by index: the column set changes with the tab, so an index resolved at tap
  /// time could name a different column than the one the user clicked.
  void _onSort<T>(
    BusinesstripRequestSortKey serverKey,
    Comparable<T> Function(dynamic d) legacyGetField,
    int columnIndex,
    bool ascending,
  ) {
    if (FeatureFlags.serverPagedBusinesstripRequests) {
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

  /// Whether the table can contain cancellation rows, and therefore whether the
  /// Request Type column exists.
  ///
  /// THE single source for this. It is handed to the data source as
  /// `hasOriginalCancellationRequests` and read where the column is built, so
  /// the header and the cells cannot disagree. On the paged path it is always
  /// true: the server unions cancellation rows into every scope, so any page may
  /// contain one, and deriving it per page would drop the cell on a page that
  /// happened to hold none — a row with fewer cells than columns is a hard
  /// assertion failure, not a layout glitch.
  bool _hasCancellationRows(UserBusinesstripRequestsState state) =>
      FeatureFlags.serverPagedBusinesstripRequests || state.cancellationRequests.isNotEmpty;

  @override
  void dispose() {
    _paginator.dispose();
    super.dispose();
  }

  void _refreshRequests() {
    final userCode = context.read<UserBloc>().state.user?.id ?? 0;
    context.read<UserBusinesstripRequestsBloc>().add(
      loadBusinesstripRequestsEvent(userCode, _effectiveSourceType),
    );
  }

  bool get _isHRUser {
    final groups = context.read<UserBloc>().state.user?.groups;
    return groups != null && groups.contains('hr');
  }

  Future<void> _downloadPDF(BuildContext context, BusinesstripRequestModel request) async {
    final service = BusinessTripPDFGenerationService();
    final locale = Localizations.localeOf(context).languageCode;
    try {
      if (kIsWeb) {
        final bytes = await service.buildPDFDocument(request, locale);
        final fileName = 'Business_Trip_Request_${request.id}.pdf';
        downloadPdfWeb(bytes, fileName);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.pdfDownloadedSuccessfully('Downloads/$fileName')),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        final filePath = await service.generateBusinessTripPDF(request, locale);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.pdfDownloadedSuccessfully(filePath)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToDownloadPdf(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printPDF(BuildContext context, BusinesstripRequestModel request) async {
    final service = BusinessTripPDFGenerationService();
    final locale = Localizations.localeOf(context).languageCode;
    try {
      final bytes = await service.buildPDFDocument(request, locale);
      await Printing.layoutPdf(onLayout: (_) async => bytes, name: 'Business_Trip_Request_${request.id}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to print PDF: $e'), backgroundColor: Colors.red));
      }
    }
  }

  List<BusinesstripRequestModel> _filterRequests(List<BusinesstripRequestModel> requests) {
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
      if (selectedMonth != null && request.dateFrom != null) {
        if (request.dateFrom!.year != selectedMonth!.year || request.dateFrom!.month != selectedMonth!.month) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  List<BusinesstripCancellationRequestModel> _filterCancellationRequests(
    List<BusinesstripCancellationRequestModel> requests,
  ) {
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
      if (selectedMonth != null && request.originalTripFrom != null) {
        if (request.originalTripFrom!.year != selectedMonth!.year ||
            request.originalTripFrom!.month != selectedMonth!.month) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Formats a fee amount for display, dropping a trailing ".0".
  String _formatFeeAmount(double amount) {
    return amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toString();
  }

  Widget _buildRequestDetailsContent(BusinesstripRequestModel request, BuildContext context) {
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
          // Same-day missing-punch overlap warning, shown to approvers (n1/n2/hr).
          // Paged path reads the server-computed per-row flag; legacy path reads
          // the whole-list scan in the bloc. See _conflictRowColor.
          if (request.hasMissingPunchConflict ||
              (request.id != null &&
                  context.read<UserBusinesstripRequestsBloc>().state.conflictingRequestIds.contains(request.id)))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red[700]),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      AppLocalizations.of(context)!.sameDayMissingPunchWarning,
                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
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
                    Text("${AppLocalizations.of(context)!.numOfDays}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(request.numberOfDays.toString()),
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
                    Text("${AppLocalizations.of(context)!.location}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(request.getLocalizedLocation(context)),
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
          // Transportation-fee eligibility note (e.g. North Square)
          if (request.deservesTransportationFees)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.blue),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.of(context)!.transportationFeesEligible,
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          // Employee-requested transportation fee amount (read-only display).
          if (request.transportationFeeRequested)
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05, minWidth: 195),
              child: Row(
                children: [
                  Text(
                    "${AppLocalizations.of(context)!.transportationFeeAmount}: ",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    request.transportationFeeAmount != null
                        ? '${_formatFeeAmount(request.transportationFeeAmount!)} ${AppLocalizations.of(context)!.egp}'
                        : '-',
                  ),
                ],
              ),
            ),
          // Show hour fields if they exist
          if (request.numberOfHours != null || request.amPm != null)
            Row(
              children: [
                if (request.numberOfHours != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05, minWidth: 195),
                    child: Row(
                      children: [
                        Text(
                          "${AppLocalizations.of(context)!.numberOfHours}: ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(request.numberOfHours.toString()),
                      ],
                    ),
                  ),
                if (request.amPm != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.05),
                    child: Row(
                      children: [
                        Text(
                          "${request.amPm == 'AM' ? AppLocalizations.of(context)!.morning : AppLocalizations.of(context)!.evening}: ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          request.amPm == 'AM'
                              ? AppLocalizations.of(context)!.morning
                              : AppLocalizations.of(context)!.evening,
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

  Widget _buildCancellationRequestDetailsContent(BusinesstripCancellationRequestModel request, BuildContext context) {
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
                    Text("${AppLocalizations.of(context)!.requestId}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(request.originalBusinesstripRequestId.toString()),
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
                    Text(
                      request.originalTripFrom != null
                          ? DateFormat('yyyy-MM-dd').format(request.originalTripFrom!)
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
                      request.originalTripTo != null ? DateFormat('yyyy-MM-dd').format(request.originalTripTo!) : '',
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
                    Text("${AppLocalizations.of(context)!.location}: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(request.getLocalizedOriginalLocation(context)),
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
    );
  }

  void _showCancellationApprovalConfirmationDialog(BusinesstripCancellationRequestModel request) {
    showDialog(
      context: context,
      builder: (childContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.approve),
          content: _buildCancellationRequestDetailsContent(request, context),
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
                    context.read<UserBusinesstripRequestsBloc>().add(
                      ApproveBusinesstripCancellationRequest(
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

  void _showApprovalConfirmationDialog(BusinesstripRequestModel request, {bool fromDetails = false}) {
    // Approvers can edit the requested transportation fee amount before approving
    // (only when the employee actually requested a fee).
    final bool canEditFee = request.transportationFeeRequested;
    final TextEditingController feeAmountController = TextEditingController(
      text: request.transportationFeeAmount != null ? _formatFeeAmount(request.transportationFeeAmount!) : '',
    );

    showDialog(
      context: context,
      builder: (childContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.approve),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRequestDetailsContent(request, context),
                if (canEditFee) ...[
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context)!.editTransportationFeeAmount,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  AppTextField(
                    autofocus: false,
                    controller: feeAmountController,
                    label: AppLocalizations.of(context)!.transportationFeeAmount,
                    hint: AppLocalizations.of(context)!.egp,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                  ),
                ],
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
                  color: Colors.red,
                  width: kIsWeb ? 120 : context.screenWidth * 0.25,
                ),
                const SizedBox(width: 16),
                AppButton(
                  onPressed: () {
                    // Validate the edited amount when a fee was requested.
                    double? feeAmount;
                    if (canEditFee) {
                      feeAmount = double.tryParse(feeAmountController.text.trim());
                      if (feeAmount == null || feeAmount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(AppLocalizations.of(context)!.transportationFeeAmountRequired)),
                        );
                        return;
                      }
                    }
                    context.read<UserBusinesstripRequestsBloc>().add(
                      ApproveBusinesstripRequest(
                        request.id!,
                        request.currentApprover!,
                        context.read<UserBloc>().state.user?.id ?? 0,
                        locale: Localizations.localeOf(context).languageCode,
                        transportationFeeAmount: feeAmount,
                      ),
                    );
                    Navigator.pop(childContext);
                    // If this was launched from the details dialog, close that too
                    // (mirrors the decline-reason flow).
                    if (fromDetails) {
                      Navigator.pop(context);
                    }
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

  void _showCancelConfirmationDialog(BuildContext context, BusinesstripRequestModel request) {
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
                    context.read<UserBusinesstripRequestsBloc>().add(CancelBusinesstripRequest(request.id!));
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

  /// Builds the row-rendering source.
  ///
  /// Shared by both paging modes: the legacy path passes the full filtered
  /// lists, the paged path passes a single server-ordered page via
  /// [preOrderedRows]. Keeping one factory means the action callbacks and every
  /// cell builder exist once.
  _BusinesstripRequestsDataSource _makeDataSource({
    required List<BusinesstripRequestModel> requests,
    required List<BusinesstripCancellationRequestModel> cancellations,
    required bool hasOriginalCancellationRequests,
    required bool shouldShowActionColumn,
    List<Map<String, dynamic>>? preOrderedRows,
    Set<int> conflictingRequestIds = const {},
    bool isLoading = false,
  }) {
    return _BusinesstripRequestsDataSource(
      requests,
      cancellationRequests: cancellations,
      hasOriginalCancellationRequests: hasOriginalCancellationRequests,
      shouldShowActionColumn: shouldShowActionColumn,
      isLoading: isLoading,
      context: context,
      sourceType: widget.sourceType,
      parentState: this,
      conflictingRequestIds: conflictingRequestIds,
      preOrderedRows: preOrderedRows,
      onApproved: (request, {bool fromDetails = false}) {
        if (fromDetails && !request.transportationFeeRequested) {
          // Direct approval from details dialog (no fee to edit).
          context.read<UserBusinesstripRequestsBloc>().add(
            ApproveBusinesstripRequest(
              request.id!,
              request.currentApprover!,
              context.read<UserBloc>().state.user?.id ?? 0,
              locale: Localizations.localeOf(context).languageCode,
            ),
          );
        } else {
          // Show confirmation dialog (table row button, or when a fee was
          // requested so the approver can edit the amount before approving).
          // When it came from the details dialog, that dialog is closed too
          // on approve (mirrors the decline-reason flow).
          _showApprovalConfirmationDialog(request, fromDetails: fromDetails);
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
                context.read<UserBusinesstripRequestsBloc>().add(
                  DeclineBusinesstripRequest(
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
              value: context.read<UserBusinesstripRequestsBloc>(),
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
          context.read<UserBusinesstripRequestsBloc>().add(RemoveBusinesstripRequestForN1(request.id!));
        } else {
          context.read<UserBusinesstripRequestsBloc>().add(RemoveBusinesstripRequest(request.id!));
        }
      },

    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserBusinesstripRequestsBloc, UserBusinesstripRequestsState>(
      listener: (context, state) {
        if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.failure?.message ?? '')));
        }

        if (state.cancelStatus == Status.success) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestCancelledSuccessfully)));
          context.read<UserBusinesstripRequestsBloc>().add(const ResetCancelStatus());
        } else if (state.cancelStatus == Status.failure && state.operationFailure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.operationFailure?.message ?? AppLocalizations.of(context)!.errorCancellingRequest),
            ),
          );
          context.read<UserBusinesstripRequestsBloc>().add(const ResetCancelStatus());
        }

        // Handle cancellation request status
        if (state.cancellationRequestStatus == Status.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.cancellationRequestSubmittedSuccessfully)),
          );
          context.read<UserBusinesstripRequestsBloc>().add(const ResetCancelStatus());
        } else if (state.cancellationRequestStatus == Status.failure && state.operationFailure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.operationFailure?.message ?? AppLocalizations.of(context)!.errorSubmittingCancellationRequest,
              ),
            ),
          );
          context.read<UserBusinesstripRequestsBloc>().add(const ResetCancelStatus());
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
        if (!FeatureFlags.serverPagedBusinesstripRequests && state.status == Status.loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Server-paged: this describes the WHOLE scope, so it comes from the
        // bloc rather than from whatever rows happen to be on this page.
        final availableMonths =
            FeatureFlags.serverPagedBusinesstripRequests
                ? state.availableMonths.toSet()
                : RequestMonthUtils.calculateAvailableMonthsFromMultiple([
                  state.requests.map((r) => r.dateFrom).toList(),
                  state.cancellationRequests.map((r) => r.originalTripFrom).toList(),
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
        // `|| tableShowingRows` is a backstop, not the mechanism: the probe
        // derives from the same RPC as the list (see
        // BusinesstripRequestRepoImpl.hasAnyRequests), so the two should never
        // disagree. The table is holding the evidence, so a populated one always
        // wins over a probe that says otherwise.
        final tableShowingRows =
            _asyncDataSource != null && !_asyncDataSource!.isStale && _asyncDataSource!.rowCount > 0;
        final hasRequests =
            FeatureFlags.serverPagedBusinesstripRequests
                ? ((state.hasAnyRequests ?? true) || tableShowingRows)
                : widget.sourceType == RequestSourceType.teamRequests
                ? (state.requests.isNotEmpty || state.cancellationRequests.isNotEmpty)
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
                          AppLocalizations.of(context)!.noBusinessTripRequestsFound,
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

        if (FeatureFlags.serverPagedBusinesstripRequests) {
          // Built once and kept: recreating it would discard the fetched page
          // and re-issue the request on every rebuild.
          _asyncDataSource ??= _BusinesstripRequestsAsyncSource(
            repo: context.read<BusinesstripRequestsRepo>(),
            query: _query ??= _buildQuery(),
            rowSourceFactory:
                (pageRows, hasActionable, query) => _makeDataSource(
                  requests: const [],
                  cancellations: const [],
                  // MUST be a constant, not derived from this page — see
                  // _hasCancellationRows.
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
                  // _BusinesstripRequestsAsyncSource.isStale — which withholds
                  // these rows until the query catches up — it guarantees the
                  // cells and the header always describe the same tab.
                  shouldShowActionColumn: query.scope != BusinesstripRequestScope.processed,
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
        } else {
          // Apply filters to requests
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

          // Only recreate data source if the actual data has changed or filters changed
          final dataChanged =
              _previousRequests != state.requests ||
              _previousCancellationRequests != state.cancellationRequests ||
              hasFiltersChanged;

          if (dataChanged || _previousRequests == null) {
            _dataSource = _makeDataSource(
              requests: filteredRequests,
              cancellations: filteredCancellationRequests,
              hasOriginalCancellationRequests: _hasCancellationRows(state),
              shouldShowActionColumn: shouldShowActionColumn,
              isLoading: state.status == Status.loading,
              conflictingRequestIds: state.conflictingRequestIds,
            );

            // Update previous state trackers
            _previousRequests = state.requests;
            _previousCancellationRequests = state.cancellationRequests;

            // Apply default sorting by createdAt (newest first) if no sort is active
            if (_sortColumnIndex == null) {
              _dataSource.sort<DateTime>(
                (d) =>
                    (d is BusinesstripRequestModel || d is BusinesstripCancellationRequestModel)
                        ? (d.createdAt ?? DateTime(1900))
                        : DateTime(1900),
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
                  width: context.screenWidth > 1000 ? context.screenWidth * 0.9 : 1300,
                  height: context.screenHeight * 0.8,
                  child: _buildTable(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// The column list.
  ///
  /// Its length MUST match the number of cells every row emits. Two rules keep
  /// that true on the paged path:
  ///   * the Request Type column is gated on [_hasCancellationRows], the same
  ///     value handed to the data source as `hasOriginalCancellationRequests`,
  ///     never on whether this page happens to hold a cancellation row;
  ///   * the Action column is gated on the effective source type, matching the
  ///     `shouldShowActionColumn` the row source was built with.
  List<DataColumn2> _buildColumns(BuildContext context, UserBusinesstripRequestsState state) {
    final showActionColumn =
        FeatureFlags.serverPagedBusinesstripRequests
            ? _effectiveSourceType != RequestSourceType.processedRequests
            : _dataSource.shouldShowActionColumn;
    final hasCancellationRows = _hasCancellationRows(state);
    return [
      if (widget.sourceType == RequestSourceType.teamRequests)
        DataColumn2(
          size: ColumnSize.S,
          label: Center(
            child: Text(
              AppLocalizations.of(context)!.id,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          onSort:
              (i, asc) => _onSort<String>(
                BusinesstripRequestSortKey.userId,
                (d) =>
                    (d is BusinesstripRequestModel || d is BusinesstripCancellationRequestModel)
                        ? d.userId.toString()
                        : '',
                i,
                asc,
              ),
        ),
      if (widget.sourceType == RequestSourceType.teamRequests)
        DataColumn2(
          size: ColumnSize.L,
          label: Center(
            child: Text(
              AppLocalizations.of(context)!.name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          onSort:
              (i, asc) => _onSort<String>(
                BusinesstripRequestSortKey.employeeName,
                (d) {
                  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                  if (d is BusinesstripRequestModel) {
                    return isArabic ? (d.userArabicName ?? '') : (d.userEnglishName ?? '');
                  } else if (d is BusinesstripCancellationRequestModel) {
                    return isArabic ? (d.userArabicName ?? '') : (d.userEnglishName ?? '');
                  }
                  return '';
                },
                i,
                asc,
              ),
        ),
      if (widget.sourceType == RequestSourceType.teamRequests ||
          (widget.sourceType == RequestSourceType.myRequests && hasCancellationRows))
        DataColumn2(
          size: ColumnSize.S,
          label: Center(
            child: Text(
              AppLocalizations.of(context)!.requestType,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ),
      DataColumn2(
        size: ColumnSize.S,
        label: Center(
          child: Text(
            AppLocalizations.of(context)!.createdAt,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        onSort:
            (i, asc) => _onSort<DateTime>(
                BusinesstripRequestSortKey.createdAt,
              (d) =>
                  (d is BusinesstripRequestModel || d is BusinesstripCancellationRequestModel)
                      ? (d.createdAt ?? DateTime(1900))
                      : DateTime(1900),
              i,
              asc,
            ),
      ),
      DataColumn2(
        size: ColumnSize.S,
        label: Center(
          child: Text(
            AppLocalizations.of(context)!.dateFrom,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        onSort:
            (i, asc) => _onSort<DateTime>(
                BusinesstripRequestSortKey.dateFrom,
              (d) {
                if (d is BusinesstripRequestModel) {
                  return d.dateFrom ?? DateTime(1900);
                } else if (d is BusinesstripCancellationRequestModel) {
                  return d.originalTripFrom ?? DateTime(1900);
                }
                return DateTime(1900);
              },
              i,
              asc,
            ),
      ),
      DataColumn2(
        size: ColumnSize.S,
        label: Center(
          child: Text(
            AppLocalizations.of(context)!.dateTo,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        onSort:
            (i, asc) => _onSort<DateTime>(
                BusinesstripRequestSortKey.dateTo,
              (d) {
                if (d is BusinesstripRequestModel) {
                  return d.dateTo ?? DateTime(1900);
                } else if (d is BusinesstripCancellationRequestModel) {
                  return d.originalTripTo ?? DateTime(1900);
                }
                return DateTime(1900);
              },
              i,
              asc,
            ),
      ),
      DataColumn2(
        size: ColumnSize.S,
        label: Center(
          child: Text(
            AppLocalizations.of(context)!.days,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        onSort:
            (i, asc) => _onSort<num>(
                BusinesstripRequestSortKey.numberOfDays,
              (d) {
                if (d is BusinesstripRequestModel) {
                  return d.numberOfDays ?? 0;
                } else if (d is BusinesstripCancellationRequestModel) {
                  return d.originalNumberOfDays ?? 0;
                }
                return 0;
              },
              i,
              asc,
            ),
      ),
      DataColumn2(
        size: ColumnSize.S,
        label: Center(
          child: Text(
            AppLocalizations.of(context)!.hours,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        onSort:
            (i, asc) => _onSort<num>(
                BusinesstripRequestSortKey.numberOfHours,
              (d) {
                if (d is BusinesstripRequestModel) {
                  return d.numberOfHours ?? 0;
                } else if (d is BusinesstripCancellationRequestModel) {
                  return d.originalNumberOfHours ?? 0;
                }
                return 0;
              },
              i,
              asc,
            ),
      ),
      DataColumn2(
        size: ColumnSize.S,
        label: Center(
          child: Text(
            "${AppLocalizations.of(context)!.am} / ${AppLocalizations.of(context)!.pm}",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        onSort:
            (i, asc) => _onSort<String>(
                BusinesstripRequestSortKey.amPm,
              (d) {
                if (d is BusinesstripRequestModel) {
                  return d.amPm ?? '';
                } else if (d is BusinesstripCancellationRequestModel) {
                  return d.originalAmPm ?? '';
                }
                return '';
              },
              i,
              asc,
            ),
      ),

      DataColumn2(
        size: ColumnSize.S,
        label: Center(
          child: Text(
            AppLocalizations.of(context)!.location,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        onSort:
            (i, asc) => _onSort<String>(
                BusinesstripRequestSortKey.location,
              (d) {
                if (d is BusinesstripRequestModel) {
                  return d.location ?? '';
                } else if (d is BusinesstripCancellationRequestModel) {
                  return d.originalLocation ?? '';
                }
                return '';
              },
              i,
              asc,
            ),
      ),
      DataColumn2(
        size: ColumnSize.S,
        label: Center(
          child: Text(
            AppLocalizations.of(context)!.status,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        onSort:
            (i, asc) => _onSort<String>(
                BusinesstripRequestSortKey.status,
              (d) =>
                  (d is BusinesstripRequestModel || d is BusinesstripCancellationRequestModel)
                      ? (d.status ?? '')
                      : '',
              i,
              asc,
            ),
      ),
      DataColumn2(
        size: ColumnSize.S,
        label: Center(
          child: Text(
            AppLocalizations.of(context)!.approver,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        onSort:
            (i, asc) => _onSort<String>(
                BusinesstripRequestSortKey.currentApprover,
              (d) =>
                  (d is BusinesstripRequestModel || d is BusinesstripCancellationRequestModel)
                      ? (d.currentApprover ?? '')
                      : '',
              i,
              asc,
            ),
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
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                SizedBox(width: 40),
              ],
            ),
          ),
        ),
    ];
  }

  Widget _buildTable(BuildContext context, UserBusinesstripRequestsState state) {
    final minWidth = context.screenWidth > 1000 ? context.screenWidth * 0.8 : 1300.0;
    final columns = _buildColumns(context, state);

    if (!FeatureFlags.serverPagedBusinesstripRequests) {
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
      // reports 0 on purpose (see _BusinesstripRequestsAsyncSource.isStale).
      // Without this, switching tabs would flash "no business trip requests
      // found" behind the spinner for the length of the round trip, and a
      // stale-time capture would then leave the message suppressed on a tab
      // that really is empty.
      empty: ListenableBuilder(
        listenable: _asyncDataSource!,
        builder: (context, _) {
          if (_asyncDataSource!.isStale) return const SizedBox.shrink();
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                AppLocalizations.of(context)!.noBusinessTripRequestsFound,
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
}

class _BusinesstripRequestsDataSource extends DataTableSource {
  final List<BusinesstripRequestModel> _requests;
  final List<BusinesstripCancellationRequestModel> cancellationRequests;
  final bool hasOriginalCancellationRequests;
  final bool isLoading;
  final BuildContext context;
  final RequestSourceType? sourceType;
  final Function(BusinesstripRequestModel, {bool fromDetails})? onApproved;
  final Function(BusinesstripRequestModel request, {bool fromDetails})? onDeclined;
  final Function(BusinesstripRequestModel request)? onCancel;
  final Function(BusinesstripRequestModel)? onRemove;
  final _UserBusinesstripRequestsContentState parentState;
  final bool shouldShowActionColumn;

  /// Ids of business-trip requests overlapping a same-user missing-punch day;
  /// their rows are tinted red. LEGACY path only — on the paged path the flag
  /// rides on each row as `BusinesstripRequestModel.hasMissingPunchConflict`.
  final Set<int> conflictingRequestIds;

  /// One server-ordered page, in the same `{'type','data','createdAt'}` shape
  /// [_mixedRequests] would otherwise build. When set, this source renders
  /// exactly these rows in exactly this order and does not sort — the server's
  /// ORDER BY is the only correct order, since re-sorting would only reorder the
  /// page rather than the whole result set.
  final List<Map<String, dynamic>>? preOrderedRows;

  Comparable Function(dynamic)? _sortFieldGetter;
  bool _sortAscending = true;

  _BusinesstripRequestsDataSource(
    this._requests, {
    this.cancellationRequests = const [],
    required this.hasOriginalCancellationRequests,
    this.isLoading = false,
    required this.context,
    this.sourceType,
    this.onApproved,
    this.onDeclined,
    this.onCancel,
    this.onRemove,
    required this.parentState,
    required this.shouldShowActionColumn,
    this.conflictingRequestIds = const {},
    this.preOrderedRows,
  });

  /// Row background for a request: light red when it overlaps a same-user
  /// missing-punch request, otherwise the table default.
  WidgetStateProperty<Color?>? _conflictRowColor(BusinesstripRequestModel request) {
    // Two sources, one per paging mode. On the paged path the server decides per
    // row (`has_missing_punch_conflict`); the whole-list scan behind
    // conflictingRequestIds cannot see rows that are not in memory, so it is
    // empty there. Checking both keeps one call site for both modes.
    final conflicts =
        request.hasMissingPunchConflict || (request.id != null && conflictingRequestIds.contains(request.id));
    if (conflicts) {
      return WidgetStateProperty.resolveWith<Color?>((states) => Colors.red[50]);
    }
    return null;
  }

  bool get hasActionableRequests => _requests.any(
    (request) =>
        request.isActionable ||
        (request.cancelled == true &&
            (parentState.widget.sourceType == RequestSourceType.myRequests
                ? request.removed != true
                : request.removedN1 != true)),
  );

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
    // Server-paged: the page is already merged, filtered and ordered by
    // `list_user_businesstrip_requests`. Returning it untouched is what keeps
    // the server's ORDER BY intact — the sort below would only reorder the
    // rows that happen to be on this page.
    final preOrdered = preOrderedRows;
    if (preOrdered != null) return preOrdered;

    // Always create mixed list for both team requests and user requests if we have cancellation requests
    if (cancellationRequests.isEmpty) {
      return _requests;
    }

    final mixed = <Map<String, dynamic>>[];

    // Add regular business trip requests
    for (final request in _requests) {
      mixed.add({'type': 'businesstrip_request', 'data': request, 'createdAt': request.tzCreatedAt});
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

      if (type == 'businesstrip_request') {
        final request = item['data'] as BusinesstripRequestModel;
        return _buildBusinesstripRequestRow(request, index);
      } else {
        final cancelRequest = item['data'] as BusinesstripCancellationRequestModel;
        return _buildCancellationRequestRow(cancelRequest, index);
      }
    }

    // Handle regular requests when no cancellation requests exist
    final request = _requests[index];
    final dateFormatter = DateFormat('yyyy-MM-dd');
    final userName =
        Localizations.localeOf(context).languageCode == "ar"
            ? request.userArabicName ?? ''
            : request.userEnglishName ?? '';
    return DataRow(
      color: _conflictRowColor(request),
      onSelectChanged: (value) {
        if (value == true) {
          _showRequestDetailsDialog(request, context);
        }
      },
      cells: [
        if (sourceType == RequestSourceType.teamRequests)
          DataCell(Center(child: Text(request.userId.toString(), style: TextStyle(fontSize: 12)))),
        if (sourceType == RequestSourceType.teamRequests)
          DataCell(
            Center(
              child: Text(
                userName.length > 15 ? '${userName.substring(0, 15)}...' : userName,
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        if (sourceType == RequestSourceType.teamRequests ||
            (sourceType == RequestSourceType.myRequests && hasOriginalCancellationRequests))
          DataCell(
            Center(child: Text(AppLocalizations.of(context)!.businessTripRequest, style: TextStyle(fontSize: 12))),
          ),
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
        DataCell(Center(child: Text(request.numberOfDays.toString(), style: TextStyle(fontSize: 12)))),
        DataCell(Center(child: Text(request.numberOfHours?.toString() ?? '-', style: TextStyle(fontSize: 12)))),
        DataCell(
          Center(
            child: Text(
              request.amPm != null
                  ? (request.amPm == 'AM'
                      ? AppLocalizations.of(context)!.morning
                      : AppLocalizations.of(context)!.evening)
                  : '-',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
        DataCell(Center(child: Text(request.getLocalizedLocation(context), style: TextStyle(fontSize: 12)))),
        DataCell(Center(child: Text(request.getLocalizedStatus(context), style: TextStyle(fontSize: 12)))),
        DataCell(Center(child: Text(request.getLocalizedApproverName(context), style: TextStyle(fontSize: 12)))),
        if (shouldShowActionColumn)
          (sourceType == RequestSourceType.teamRequests && request.isPending)
              ? DataCell(
                Center(
                  child:
                      request.isPending
                          ? RowApproveDeclineActions<UserBusinesstripRequestsBloc, UserBusinesstripRequestsState>(
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
                                        ? onCancel?.call(request)
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

  @override
  int get rowCount => _mixedRequests.length;

  @override
  bool get isRowCountApproximate => false;

  @override
  int get selectedRowCount => 0;

  void _showCancellationRequestDialog(BusinesstripRequestModel request) {
    final TextEditingController reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        void onFieldSubmitted() {
          if (formKey.currentState!.validate()) {
            final reason = reasonController.text.trim();
            context.read<UserBusinesstripRequestsBloc>().add(RequestBusinesstripCancellation(request.id!, reason));
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

  void _showRemoveConfirmationDialog(BusinesstripRequestModel request) {
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

  void _showCancelConfirmationDialogFromDetails(BusinesstripRequestModel request, BuildContext detailsDialogContext) {
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
                    context.read<UserBusinesstripRequestsBloc>().add(CancelBusinesstripRequest(request.id!));
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

  void _showRequestDetailsDialog(BusinesstripRequestModel request, BuildContext context) {
    bool isDownloading = false;
    bool isPrinting = false;

    showDialog(
      context: context,
      builder: (childContext2) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: context.screenWidth < 600 ? context.screenWidth * 0.95 : 600,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        children: [
                          Icon(Icons.business_center, color: Theme.of(context).primaryColor, size: 24),
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
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            AppButton(
                              width: 120,
                              onPressed: () => Navigator.pop(childContext2),
                              label: AppLocalizations.of(context)!.close,
                              color: Colors.blue,
                            ),
                            if (sourceType == RequestSourceType.myRequests &&
                                (request.canBeCancelledDirectly || request.canRequestCancellation)) ...[
                              const SizedBox(width: 12),
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
                              const SizedBox(width: 12),
                              AppButton(
                                width: 120,
                                onPressed: () {
                                  onApproved?.call(request, fromDetails: true);
                                  // When a fee was requested, onApproved opens the
                                  // approval-confirmation dialog over this one, so keep
                                  // the details dialog open behind it. Otherwise the
                                  // approval is dispatched directly and we close here.
                                  if (!request.transportationFeeRequested) {
                                    Navigator.pop(childContext2);
                                  }
                                },
                                label: AppLocalizations.of(context)!.approve,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              AppButton(
                                width: 120,
                                onPressed: () {
                                  onDeclined?.call(request, fromDetails: true);
                                },
                                label: AppLocalizations.of(context)!.decline,
                                color: Colors.redAccent,
                              ),
                            ],
                            if (parentState._isHRUser && request.status == 'approved' && request.cancelled != true) ...[
                              const SizedBox(width: 12),
                              AppButton(
                                width: 140,
                                isLoading: isDownloading,
                                onPressed:
                                    isDownloading || isPrinting
                                        ? null
                                        : () async {
                                          setDialogState(() => isDownloading = true);
                                          await parentState._downloadPDF(context, request);
                                          setDialogState(() => isDownloading = false);
                                        },
                                label: AppLocalizations.of(context)!.downloadPdf,
                                color: Colors.blue[600],
                              ),
                              const SizedBox(width: 12),
                              AppButton(
                                width: 120,
                                isLoading: isPrinting,
                                onPressed:
                                    isDownloading || isPrinting
                                        ? null
                                        : () async {
                                          setDialogState(() => isPrinting = true);
                                          await parentState._printPDF(context, request);
                                          setDialogState(() => isPrinting = false);
                                        },
                                label: AppLocalizations.of(context)!.printPdf,
                                color: Colors.green[600],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCancellationRequestDialogFromDetails(BusinesstripRequestModel request, BuildContext detailsDialogContext) {
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
            context.read<UserBusinesstripRequestsBloc>().add(RequestBusinesstripCancellation(request.id!, reason));
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

  DataRow _buildBusinesstripRequestRow(BusinesstripRequestModel request, int index) {
    final dateFormatter = DateFormat('yyyy-MM-dd');
    return DataRow(
      // Red tint when the trip overlaps a same-user missing punch; otherwise normal.
      color: _conflictRowColor(request) ?? WidgetStateProperty.all(Colors.transparent),
      onSelectChanged: (value) {
        if (value == true) {
          _showRequestDetailsDialog(request, context);
        }
      },
      cells: [
        if (sourceType == RequestSourceType.teamRequests)
          DataCell(Center(child: Text(request.userId.toString(), style: TextStyle(fontSize: 12)))),
        if (sourceType == RequestSourceType.teamRequests)
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
        if (sourceType == RequestSourceType.teamRequests ||
            (sourceType == RequestSourceType.myRequests && hasOriginalCancellationRequests))
          DataCell(
            Center(
              child: Text(
                textAlign: TextAlign.center,
                AppLocalizations.of(context)!.businessTripRequest,
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
        DataCell(Center(child: Text(request.numberOfDays?.toString() ?? '', style: TextStyle(fontSize: 12)))),
        DataCell(Center(child: Text(request.numberOfHours?.toString() ?? '-', style: TextStyle(fontSize: 12)))),
        DataCell(
          Center(
            child: Text(
              request.amPm != null
                  ? (request.amPm == 'AM'
                      ? AppLocalizations.of(context)!.morning
                      : AppLocalizations.of(context)!.evening)
                  : '-',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
        DataCell(Center(child: Text(request.getLocalizedLocation(context), style: TextStyle(fontSize: 12)))),
        DataCell(Center(child: Text(request.getLocalizedStatus(context), style: TextStyle(fontSize: 12)))),
        DataCell(Center(child: Text(request.getLocalizedApproverName(context), style: TextStyle(fontSize: 12)))),
        if (shouldShowActionColumn)
          (sourceType == RequestSourceType.teamRequests && request.isPending)
              ? DataCell(
                Center(
                  child:
                      request.isPending
                          ? RowApproveDeclineActions<UserBusinesstripRequestsBloc, UserBusinesstripRequestsState>(
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
                                        ? onCancel?.call(request)
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

  DataRow _buildCancellationRequestRow(BusinesstripCancellationRequestModel request, int index) {
    final dateFormatter = DateFormat('yyyy-MM-dd');
    return DataRow(
      color: WidgetStateProperty.all(Colors.orange.shade100), // Orange color for cancellation requests
      onSelectChanged: (value) {
        if (value == true) {
          _showCancellationRequestDetailsDialog(request, context);
        }
      },
      cells: [
        if (sourceType == RequestSourceType.teamRequests)
          DataCell(Center(child: Text(request.userId.toString(), style: TextStyle(fontSize: 12)))),
        if (sourceType == RequestSourceType.teamRequests)
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
        if (sourceType == RequestSourceType.teamRequests ||
            (sourceType == RequestSourceType.myRequests && hasOriginalCancellationRequests))
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
              request.originalTripFrom != null ? dateFormatter.format(request.originalTripFrom!) : '',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ), // Date From
        DataCell(
          Center(
            child: Text(
              request.originalTripTo != null ? dateFormatter.format(request.originalTripTo!) : '',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ), // Date To
        DataCell(
          Center(child: Text(request.originalNumberOfDays?.toString() ?? '', style: TextStyle(fontSize: 12))),
        ), // Number of Days
        DataCell(
          Center(child: Text(request.originalNumberOfHours?.toString() ?? '-', style: TextStyle(fontSize: 12))),
        ), // Number of Hours
        DataCell(
          Center(
            child: Text(
              request.originalAmPm != null
                  ? (request.originalAmPm == 'AM'
                      ? AppLocalizations.of(context)!.morning
                      : AppLocalizations.of(context)!.evening)
                  : '-',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ), // AM/PM
        DataCell(
          Center(child: Text(request.getLocalizedOriginalLocation(context), style: TextStyle(fontSize: 12))),
        ), // Location
        DataCell(Center(child: Text(request.getLocalizedStatus(context), style: TextStyle(fontSize: 12)))), // Status
        DataCell(Center(child: Text(request.getLocalizedApproverName(context), style: TextStyle(fontSize: 12)))),
        if (shouldShowActionColumn)
          (sourceType == RequestSourceType.teamRequests && request.isPending)
              ? DataCell(
                Center(
                  child:
                      request.isPending
                          ? RowApproveDeclineActions<UserBusinesstripRequestsBloc, UserBusinesstripRequestsState>(
                            // The cancellation's own id — that is what
                            // Approve/DeclineBusinesstripCancellationRequest carry.
                            // Different id space from the trip rows above.
                            isProcessing:
                                (state) =>
                                    request.id != null && state.processingCancellationRequestId == request.id,
                            legacyIsLoading: isLoading,
                            onApprove: () => _approveCancellationRequest(request),
                            onDecline: () => _declineCancellationRequest(request),
                          )
                          : null,
                ),
              )
              : DataCell(Container()),
      ],
    );
  }

  void _approveCancellationRequest(BusinesstripCancellationRequestModel request) {
    parentState._showCancellationApprovalConfirmationDialog(request);
  }

  void _declineCancellationRequest(BusinesstripCancellationRequestModel request) {
    final TextEditingController reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (childContext) {
        void onFieldSubmitted() {
          if (formKey.currentState!.validate()) {
            final reason = reasonController.text.trim();
            context.read<UserBusinesstripRequestsBloc>().add(
              DeclineBusinesstripCancellationRequest(
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
                              AppLocalizations.of(context)!.businessTripCancellationRequest,
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

  void _showCancellationRequestDetailsDialog(BusinesstripCancellationRequestModel request, BuildContext context) {
    final dateFormatter = DateFormat('yyyy-MM-dd');
    showDialog(
      context: context,
      builder: (BuildContext childContext2) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SingleChildScrollView(
            child: Container(
              width: context.screenWidth < 600 ? context.screenWidth * 0.95 : 600,
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
                              AppLocalizations.of(context)!.businessTripCancellationRequest,
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
                      child: SizedBox(
                        width: 500,
                        child: Column(
                          children: [
                            _buildDetailRow(
                              AppLocalizations.of(context)!.requestId,
                              request.originalBusinesstripRequestId.toString(),
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
                              AppLocalizations.of(context)!.location,
                              request.getLocalizedOriginalLocation(context),
                            ),
                            _buildDetailRow(
                              AppLocalizations.of(context)!.dateFrom,
                              request.originalTripFrom != null ? dateFormatter.format(request.originalTripFrom!) : '',
                            ),
                            _buildDetailRow(
                              AppLocalizations.of(context)!.dateTo,
                              request.originalTripTo != null ? dateFormatter.format(request.originalTripTo!) : '',
                            ),
                            _buildDetailRow(
                              AppLocalizations.of(context)!.numberOfDays,
                              request.originalNumberOfDays?.toString() ?? '',
                            ),
                            _buildDetailRow(AppLocalizations.of(context)!.reason, request.reason),
                            _buildDetailRow(AppLocalizations.of(context)!.status, request.getLocalizedStatus(context)),
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
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 500,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 24.0),
                          child: Row(
                            children: [
                              AppButton(
                                width: 120,
                                onPressed: () => Navigator.pop(childContext2),
                                label: AppLocalizations.of(context)!.close,
                                color: Colors.blue,
                              ),
                              if (request.isPending &&
                                  !parentState.showProcessedRequests &&
                                  sourceType == RequestSourceType.teamRequests) ...[
                                const SizedBox(width: 16),
                                AppButton(
                                  width: 120,
                                  onPressed: () {
                                    Navigator.of(childContext2).pop();

                                    context.read<UserBusinesstripRequestsBloc>().add(
                                      ApproveBusinesstripCancellationRequest(
                                        request.id!,
                                        request.currentApprover!,
                                        context.read<UserBloc>().state.user?.id ?? 0,
                                      ),
                                    );
                                  },
                                  label: AppLocalizations.of(context)!.approve,
                                  color: Colors.green.shade600,
                                ),
                                const SizedBox(width: 16),
                                AppButton(
                                  width: 120,
                                  onPressed: () {
                                    Navigator.of(childContext2).pop();
                                    _declineCancellationRequest(request);
                                  },
                                  label: AppLocalizations.of(context)!.decline,
                                  color: Colors.red.shade600,
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
}

/// Fetches one page at a time from `list_user_businesstrip_requests`.
///
/// Row *rendering* is not duplicated here: [getRows] builds a throwaway
/// [_BusinesstripRequestsDataSource] over the page it just fetched and calls its
/// `getRow`, so all ~1000 lines of cell layout, detail dialogs and action
/// buttons stay in exactly one place. The `preOrderedRows` constructor argument
/// is what stops that source from re-sorting the page and undoing the server's
/// ORDER BY.
class _BusinesstripRequestsAsyncSource extends AsyncDataTableSource {
  _BusinesstripRequestsAsyncSource({
    required this.repo,
    required BusinesstripRequestsQuery query,
    required this.rowSourceFactory,
  }) : _query = query;

  final BusinesstripRequestsRepo repo;

  /// Builds a sync source over a single, already-ordered page. Supplied by the
  /// widget so the row builders keep their `BuildContext` and action callbacks.
  ///
  /// Takes the query the page was fetched FOR, so the cells it emits are decided
  /// by that query rather than by whatever the widget's tab state happens to be
  /// when the fetch resolves. See [isStale].
  final _BusinesstripRequestsDataSource Function(
    List<Map<String, dynamic>> pageRows,
    bool hasActionable,
    BusinesstripRequestsQuery query,
  )
  rowSourceFactory;

  BusinesstripRequestsQuery _query;
  BusinesstripRequestsQuery get query => _query;

  /// The query the rows currently in the base class's cache were built for.
  ///
  /// `AsyncDataTableSource` keeps `_rows` across a reload — `AsyncPaginatedDataTable2`
  /// renders the full table underneath its `loading:` overlay rather than
  /// clearing it — so after a query change the cache still holds the PREVIOUS
  /// query's rows for the length of the round trip.
  BusinesstripRequestsQuery? _renderedQuery;

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
  /// only non-actionable rows.
  bool get hasActionable => _hasActionable;

  /// Swaps in a new query. Returns whether it actually differs, so the caller
  /// can skip a redundant fetch on rebuilds that changed nothing.
  bool setQuery(BusinesstripRequestsQuery next) {
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
    final page = await repo.getBusinesstripRequestsPage(query, offset: startIndex, limit: count);
    _hasActionable = page.hasActionable;

    // Same {'type','data','createdAt'} shape the client-side merge produced, so
    // _BusinesstripRequestsDataSource.getRow needs no special case for paged
    // data.
    final pageRows =
        page.items.map((row) {
          return switch (row) {
            BusinesstripTripRow(:final request) => {
              'type': 'businesstrip_request',
              'data': request,
              'createdAt': request.createdAt,
            },
            BusinesstripCancellationRow(:final request) => {
              'type': 'cancellation_request',
              'data': request,
              'createdAt': request.createdAt,
            },
          };
        }).toList();

    final rowSource = rowSourceFactory(pageRows, page.hasActionable, query);

    // Set only once the rows exist, and to the query THIS fetch was for. If a
    // newer query arrived while this one was in flight, isStale stays true and
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
