import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/constants/violation_category.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/request_month_utils.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_requests_query.dart';
import 'package:hrms_demo/presentation/widgets/paged_requests_pagination_controls.dart';
import 'package:hrms_demo/presentation/widgets/request_filters_mixin.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'package:hrms_demo/data/models/request_item_wrapper.dart';
import 'package:hrms_demo/data/models/investigation_request_model.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_state.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/bloc/user_disciplinary_action_requests_bloc.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/bloc/user_disciplinary_action_requests_state.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/bloc/user_disciplinary_action_requests_event.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/widgets/disciplinary_action_detail_content.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/widgets/investigation_detail_content.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/widgets/investigation_workflow_dialog.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:hrms_demo/services/pdf/disciplinary_pdf_storage_service.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

enum ActiveSectionType { none, edit }

class UserDisciplinaryActionRequestsContent extends StatefulWidget {
  final RequestSourceType? sourceType;
  const UserDisciplinaryActionRequestsContent({super.key, this.sourceType});

  @override
  State<UserDisciplinaryActionRequestsContent> createState() => _UserDisciplinaryActionRequestsContentState();
}

class _UserDisciplinaryActionRequestsContentState extends State<UserDisciplinaryActionRequestsContent>
    with RequestFiltersMixin<UserDisciplinaryActionRequestsContent> {
  /// LEGACY page index. On the paged path the window lives in the bloc's
  /// `PagedSection`, because only the server knows how many pages there are.
  int _currentPage = 0;

  /// Page size. Shared by both paths — the paged one forwards it to the bloc.
  int _itemsPerPage = 10;

  // Sorting
  String _sortBy = 'createdAt';
  bool _sortAscending = false;

  /// 'actionable' | 'processedDisciplinary' | 'processedInvestigations'.
  ///
  /// Not [RequestFiltersMixin.showProcessedRequests]: that is a two-state
  /// toggle and this screen has three tabs. The mixin is used here for its
  /// debounced search and its filter reset, not for its tab state.
  String _activeTab = 'actionable';

  // ── Server-paged query plumbing ────────────────────────────────────────────

  /// The tab the user is on, as the server understands it.
  ///
  /// The two processed tabs are now SEPARATE server scopes. They used to be one
  /// `processedRequests` fetch filtered by entity type in Dart, which silently
  /// shrank every processed page.
  DisciplinaryRequestScope get _effectiveScope {
    if (widget.sourceType != RequestSourceType.teamRequests) {
      return (widget.sourceType ?? RequestSourceType.myRequests).defaultScope;
    }
    return switch (_activeTab) {
      'processedDisciplinary' => DisciplinaryRequestScope.processedDisciplinary,
      'processedInvestigations' => DisciplinaryRequestScope.processedInvestigations,
      _ => DisciplinaryRequestScope.team,
    };
  }

  DisciplinaryRequestSortKey get _serverSortKey => switch (_sortBy) {
    'status' => DisciplinaryRequestSortKey.status,
    'violationDate' => DisciplinaryRequestSortKey.violationDate,
    'actionType' => DisciplinaryRequestSortKey.actionType,
    _ => DisciplinaryRequestSortKey.createdAt,
  };

  DisciplinaryRequestsQuery _buildQuery() => DisciplinaryRequestsQuery(
    scope: _effectiveScope,
    search: searchQuery,
    status: statusFilter,
    month: selectedMonth,
    sortKey: _serverSortKey,
    sortAscending: _sortAscending,
    locale: Localizations.localeOf(context).languageCode,
  );

  /// Re-issues the query. The bloc drops it if nothing actually changed and
  /// resets to page 1 if it did.
  void _applyQuery() {
    if (!FeatureFlags.serverPagedDisciplinaryRequests) return;
    context.read<UserDisciplinaryActionRequestsBloc>().add(DisciplinaryQueryChanged(_buildQuery()));
  }

  /// Fires after every filter change made through [RequestFiltersMixin] —
  /// debounced for search, immediate for the discrete filters.
  @override
  void onFiltersChanged() => _applyQuery();

  // ── Legacy client-side paging (flag off) ───────────────────────────────────

  List<RequestItem> get _paginatedRequests {
    final filteredRequests = _filteredAndSortedRequests;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredRequests.length);
    return filteredRequests.sublist(startIndex, endIndex);
  }

  int get _totalPages {
    final filteredRequests = _filteredAndSortedRequests;
    return (filteredRequests.length / _itemsPerPage).ceil();
  }

  /// Loads the tab the user is on from scratch — scope facts and first page.
  void _refreshRequests() {
    final userBloc = context.read<UserBloc>();
    final currentUser = userBloc.state.user;
    if (currentUser?.id == null) return;
    final bloc = context.read<UserDisciplinaryActionRequestsBloc>();

    if (FeatureFlags.serverPagedDisciplinaryRequests) {
      // One expression instead of the branch below: the scope already knows
      // which of the three tabs is active, including which processed one.
      bloc.add(InitDisciplinaryRequests(currentUser!.id!, _effectiveScope));
      return;
    }

    if (_activeTab == 'processedDisciplinary' || _activeTab == 'processedInvestigations') {
      bloc.add(LoadUserDisciplinaryActionRequests(currentUser!.id!, RequestSourceType.processedRequests));
    } else {
      bloc.add(LoadUserDisciplinaryActionRequests(currentUser!.id!, widget.sourceType ?? RequestSourceType.myRequests));
    }
  }

  List<RequestItem> get _filteredAndSortedRequests {
    List<RequestItem> filtered = List.from(context.read<UserDisciplinaryActionRequestsBloc>().state.requests);

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((item) => _matchesSearchQuery(item, searchQuery)).toList();
    }

    // Apply status filter
    if (statusFilter != 'all') {
      filtered =
          filtered.where((item) {
            if (statusFilter == 'cancelled') {
              return item.isCancelled;
            } else {
              return item.status?.toLowerCase() == statusFilter && !item.isCancelled;
            }
          }).toList();
    }

    // Apply month filter
    if (selectedMonth != null) {
      filtered =
          filtered.where((item) {
            final createdAt = item.createdAt;
            return createdAt != null &&
                createdAt.year == selectedMonth!.year &&
                createdAt.month == selectedMonth!.month;
          }).toList();
    }

    // Apply tab-specific filtering (for team requests)
    if (widget.sourceType == RequestSourceType.teamRequests) {
      if (_activeTab == 'actionable') {
        filtered = filtered.where((item) => item.isActionable).toList();
      } else if (_activeTab == 'processedDisciplinary') {
        filtered = filtered.where((item) => item.isDisciplinaryAction).toList();
      } else if (_activeTab == 'processedInvestigations') {
        filtered = filtered.where((item) => item.isInvestigation).toList();
      }
    }

    // Apply sorting — relevance first when a search query is active
    filtered.sort((a, b) {
      if (searchQuery.isNotEmpty) {
        final scoreA = _requestMatchScore(a, searchQuery);
        final scoreB = _requestMatchScore(b, searchQuery);
        if (scoreA != scoreB) return scoreA.compareTo(scoreB);
      }
      int result = 0;
      switch (_sortBy) {
        case 'createdAt':
          result = (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());
          break;
        case 'status':
          result = (a.status ?? '').compareTo(b.status ?? '');
          break;
        case 'violationDate':
          result = (a.violationDate ?? DateTime.now()).compareTo(b.violationDate ?? DateTime.now());
          break;
        case 'actionType':
          // Only sort by action type for disciplinary actions
          if (a.isDisciplinaryAction && b.isDisciplinaryAction) {
            result = (a.disciplinaryAction!.actionType?.value ?? '').compareTo(
              b.disciplinaryAction!.actionType?.value ?? '',
            );
          } else {
            // Investigations come first when sorting by action type
            result = a.isInvestigation ? -1 : 1;
          }
          break;
        default:
          result = (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());
      }

      return _sortAscending ? result : -result;
    });

    return filtered;
  }

  String _shortCode(int? code) => code != null ? (code - 10000000).toString() : '';

  bool _codeMatches(int? code, String query) {
    if (code == null) return false;
    final isNumeric = int.tryParse(query) != null;
    if (isNumeric) return _shortCode(code).startsWith(query);
    return false;
  }

  bool _matchesSearchQuery(RequestItem requestItem, String query) {
    final queryLower = query.toLowerCase();

    if (requestItem.isInvestigation) {
      final inv = requestItem.investigation!;
      final matchesDescription = inv.incidentDescription?.toLowerCase().contains(queryLower) ?? false;
      final matchesCode = inv.employeeCodes.any((code) => _codeMatches(code, query));
      final matchesName =
          inv.employeeInfoMap?.values.any(
            (info) =>
                (info.englishName?.toLowerCase().contains(queryLower) ?? false) ||
                (info.arabicName?.toLowerCase().contains(queryLower) ?? false),
          ) ??
          false;
      return matchesDescription || matchesCode || matchesName;
    } else {
      final request = requestItem.disciplinaryAction!;
      return (request.employeeEnglishName?.toLowerCase().contains(queryLower) ?? false) ||
          (request.employeeArabicName?.toLowerCase().contains(queryLower) ?? false) ||
          _codeMatches(request.employeeCode, query) ||
          (request.incidentDescription?.toLowerCase().contains(queryLower) ?? false) ||
          (request.actionType?.value.toLowerCase().contains(queryLower) ?? false);
    }
  }

  int _requestMatchScore(RequestItem item, String query) {
    final queryLower = query.toLowerCase();
    final isNumeric = int.tryParse(query) != null;

    bool exactCode(int? code) => isNumeric && _shortCode(code) == query;
    bool prefixCode(int? code) => isNumeric && _shortCode(code).startsWith(query);
    bool nameStartsWith(String? name) => name?.toLowerCase().startsWith(queryLower) ?? false;

    if (item.isDisciplinaryAction) {
      final da = item.disciplinaryAction!;
      if (exactCode(da.employeeCode)) return 0;
      if (prefixCode(da.employeeCode)) return 1;
      if (nameStartsWith(da.employeeEnglishName) || nameStartsWith(da.employeeArabicName)) return 2;
    } else {
      final inv = item.investigation!;
      if (inv.employeeCodes.any((c) => exactCode(c))) return 0;
      if (inv.employeeCodes.any((c) => prefixCode(c))) return 1;
      final nameMatch =
          inv.employeeInfoMap?.values.any(
            (info) => nameStartsWith(info.englishName) || nameStartsWith(info.arabicName),
          ) ??
          false;
      if (nameMatch) return 2;
    }
    return 3;
  }

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    final userBloc = context.read<UserBloc>();
    final currentUser = userBloc.state.user;
    if (currentUser?.id != null) {
      // The factory picks Init vs the legacy load, so this screen and the two
      // entry pages cannot drift apart on which event populates the list.
      context.read<UserDisciplinaryActionRequestsBloc>().add(
        loadDisciplinaryRequestsEvent(currentUser!.id!, widget.sourceType ?? RequestSourceType.myRequests),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: BlocListener<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
        listener: (context, state) {
          // Note: Employee names are now pre-populated in investigation models
          // No need to fetch separately

          // Handle operation feedback
          if (state.approveStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestApprovedSuccessfully)));
            // Reset approve status
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetApproveStatus());
          } else if (state.approveStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.failedToApproveRequest(
                    state.operationFailure?.message ?? AppLocalizations.of(context)!.unknownError,
                  ),
                ),
              ),
            );
            // Reset approve status
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetApproveStatus());
          }

          // Handle acknowledgment operation feedback
          if (state.acknowledgmentStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestAcknowledgedSuccessfully)));
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetAcknowledgmentStatus());
          } else if (state.acknowledgmentStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.failure?.message ?? AppLocalizations.of(context)!.errorOccurred)),
            );
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetAcknowledgmentStatus());
          }

          // Handle decline operation feedback
          if (state.declineStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestDeclinedSuccessfully)));
            // Reset decline status
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetDeclineStatus());
          } else if (state.declineStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.failedToDeclineRequest(
                    state.operationFailure?.message ?? AppLocalizations.of(context)!.unknownError,
                  ),
                ),
              ),
            );
            // Reset decline status
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetDeclineStatus());
          }

          // Handle on-hold operation feedback
          if (state.onHoldStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestPutOnHoldSuccessfully)));
            // Reset on-hold status
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetOnHoldStatus());
          } else if (state.onHoldStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.failedToPutOnHoldRequest(
                    state.operationFailure?.message ?? AppLocalizations.of(context)!.unknownError,
                  ),
                ),
              ),
            );
            // Reset on-hold status
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetOnHoldStatus());
          }

          // Handle cancel operation feedback
          if (state.cancelStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestCancelledSuccessfully)));
            // Reset cancel status
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetCancelStatus());
          } else if (state.cancelStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.failedToCancelRequest(
                    state.operationFailure?.message ?? AppLocalizations.of(context)!.unknownError,
                  ),
                ),
              ),
            );
            // Reset cancel status
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetCancelStatus());
          }

          // Handle investigation operation feedback
          if (state.investigationStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.sentToHrInvestigationSuccessfully)));
            // Reset investigation status
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetInvestigationStatus());
          } else if (state.investigationStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.failedToSendToHrInvestigation(
                    state.operationFailure?.message ?? AppLocalizations.of(context)!.unknownError,
                  ),
                ),
              ),
            );
            // Reset investigation status
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetInvestigationStatus());
          }

          // Handle convert to investigation feedback
          if (state.convertToInvestigationStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.daConvertedToInvestigation)));
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetInvestigationDecisionStatus());
          } else if (state.convertToInvestigationStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.operationFailure?.message ?? AppLocalizations.of(context)!.errorOccurred)),
            );
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetInvestigationDecisionStatus());
          }

          // Handle HR final decision feedback (reset stale status to prevent cascading pops)
          if (state.hrFinalDecisionStatus == Status.success) {
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetHRFinalDecisionStatus());
          } else if (state.hrFinalDecisionStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.operationFailure?.message ?? AppLocalizations.of(context)!.errorOccurred)),
            );
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetHRFinalDecisionStatus());
          }

          // Handle escalate to legal feedback (reset stale status to prevent cascading pops)
          if (state.escalateToLegalStatus == Status.success) {
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetEscalateToLegalStatus());
          } else if (state.escalateToLegalStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.operationFailure?.message ?? AppLocalizations.of(context)!.errorOccurred)),
            );
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetEscalateToLegalStatus());
          }

          // Handle legal upload feedback (reset stale status to prevent cascading pops)
          if (state.legalUploadStatus == Status.success) {
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetLegalUploadStatus());
          } else if (state.legalUploadStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.operationFailure?.message ?? AppLocalizations.of(context)!.errorOccurred)),
            );
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetLegalUploadStatus());
          }

          // Handle legal acknowledge feedback (reset stale status to prevent cascading pops)
          // Note: Success message is now shown inline in the dialog via _showSuccessMessage
          if (state.legalAcknowledgeStatus == Status.success) {
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetLegalAcknowledgeStatus());
          } else if (state.legalAcknowledgeStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.operationFailure?.message ?? AppLocalizations.of(context)!.errorOccurred)),
            );
            context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetLegalAcknowledgeStatus());
          }
        },
        child: BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
          builder: (context, state) {
            // On the paged path the months come from the server, across BOTH
            // tables: deriving them from the rows in memory would offer only
            // the months that happen to appear on the current page.
            final availableMonths =
                FeatureFlags.serverPagedDisciplinaryRequests
                    ? state.availableMonths.toSet()
                    : RequestMonthUtils.calculateAvailableMonths(state.requests.map((r) => r.createdAt).toList());

            return Align(
              alignment: Alignment.topLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: context.screenWidth > 1168 ? context.screenWidth * 0.95 : 1105,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          const SizedBox(height: 16),
                          _buildFiltersAndControls(context, availableMonths),
                          const SizedBox(height: 16),
                          _buildRequestsList(context, state),
                          if (FeatureFlags.serverPagedDisciplinaryRequests) ...[
                            if (state.paged.totalPages > 1) ...[
                              const SizedBox(height: 16),
                              PagedRequestsPaginationControls(
                                page: state.paged.page,
                                totalCount: state.paged.totalCount,
                                pageSize: state.paged.pageSize,
                                isLoading: state.paged.isPageLoading,
                                onPageChanged:
                                    (page) => context.read<UserDisciplinaryActionRequestsBloc>().add(
                                      DisciplinaryPageChanged(page),
                                    ),
                              ),
                            ],
                          ] else if (_totalPages > 1) ...[
                            const SizedBox(height: 16),
                            _buildPaginationControls(context),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    String title;
    switch (widget.sourceType) {
      case RequestSourceType.myRequests:
        title = AppLocalizations.of(context)!.myDisciplinaryActionRequests;
        break;
      case RequestSourceType.teamRequests:
        title = AppLocalizations.of(context)!.teamDisciplinaryActionRequests;
        break;
      case RequestSourceType.processedRequests:
        title = AppLocalizations.of(context)!.processedDisciplinaryActionRequests;
        break;
      default:
        title = AppLocalizations.of(context)!.disciplinaryActionRequests;
    }

    return Row(
      children: [
        Icon(Icons.gavel_outlined, color: Theme.of(context).primaryColor, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
        ),
      ],
    );
  }

  Widget _buildFiltersAndControls(BuildContext context, Set<DateTime> availableMonths) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Toggle for team requests
            if (widget.sourceType == RequestSourceType.teamRequests) ...[
              Row(
                children: [
                  Text(AppLocalizations.of(context)!.viewRequests, style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(width: 16),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment<String>(
                        value: 'actionable',
                        label: Text(AppLocalizations.of(context)!.actionable),
                        icon: Icon(Icons.pending_actions),
                      ),
                      ButtonSegment<String>(
                        value: 'processedDisciplinary',
                        label: Text(AppLocalizations.of(context)!.processedDisciplinary),
                        icon: Icon(Icons.check_circle_outline),
                      ),
                      ButtonSegment<String>(
                        value: 'processedInvestigations',
                        label: Text(AppLocalizations.of(context)!.processedInvestigations),
                        icon: Icon(Icons.manage_search),
                      ),
                    ],
                    selected: {_activeTab},
                    onSelectionChanged: (Set<String> selection) {
                      setState(() {
                        _activeTab = selection.first;
                        _currentPage = 0;
                      });
                      // Clears search/status/month. `notify: false` because
                      // _refreshRequests re-loads the scope from scratch, which
                      // would otherwise be preceded by a query fetch against
                      // the tab being navigated away from.
                      resetFilters(notify: false);
                      _refreshRequests();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Search and Status Filter Row
            Row(
              children: [
                // Search Field
                Expanded(
                  flex: 3,
                  child: TextField(
                    // Debounced by the mixin (350 ms), so typing does not issue
                    // one server query per keystroke.
                    onChanged: (value) {
                      _currentPage = 0; // Reset to first page
                      updateSearchQuery(value);
                    },
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.searchByNameOrCode,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Status Filter
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: statusFilter,
                    onChanged: (value) {
                      _currentPage = 0;
                      updateStatusFilter(value ?? 'all');
                    },
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.status,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(AppLocalizations.of(context)!.allStatus)),
                      DropdownMenuItem(value: 'pending', child: Text(AppLocalizations.of(context)!.pending)),
                      DropdownMenuItem(value: 'approved', child: Text(AppLocalizations.of(context)!.approved)),
                      DropdownMenuItem(value: 'declined', child: Text(AppLocalizations.of(context)!.declined)),
                      DropdownMenuItem(value: 'on_hold', child: Text(AppLocalizations.of(context)!.onHold)),
                      DropdownMenuItem(value: 'cancelled', child: Text(AppLocalizations.of(context)!.cancelled)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Month Filter
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: () async {
                      final selectedDate = await _showMonthYearPicker(context, availableMonths);
                      if (selectedDate != null) {
                        _currentPage = 0;
                        updateSelectedMonth(selectedDate);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.month,
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
                        selectedMonth != null
                            ? DateFormat('MMM yyyy').format(selectedMonth!)
                            : AppLocalizations.of(context)!.selectMonth,
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
                    onChanged: (value) {
                      setState(() {
                        _itemsPerPage = value ?? 10;
                        _currentPage = 0;
                      });
                      if (FeatureFlags.serverPagedDisciplinaryRequests) {
                        context.read<UserDisciplinaryActionRequestsBloc>().add(
                          DisciplinaryPageSizeChanged(_itemsPerPage),
                        );
                      }
                    },
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.perPage,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5')),
                      DropdownMenuItem(value: 10, child: Text('10')),
                      DropdownMenuItem(value: 25, child: Text('25')),
                      DropdownMenuItem(value: 50, child: Text('50')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Sort Controls Row
                Row(
                  children: [
                    Text(AppLocalizations.of(context)!.sortBy, style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),

                    DropdownButton<String>(
                      value: _sortBy,
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value ?? 'createdAt';
                        });
                        // Sorting is a property of the whole result set, not of
                        // the page in memory, so it has to go back to the server.
                        _applyQuery();
                      },
                      items: [
                        DropdownMenuItem(value: 'createdAt', child: Text(AppLocalizations.of(context)!.dateCreated)),
                        DropdownMenuItem(value: 'actionType', child: Text(AppLocalizations.of(context)!.actionType)),
                        DropdownMenuItem(value: 'status', child: Text(AppLocalizations.of(context)!.status)),
                        DropdownMenuItem(
                          value: 'violationDate',
                          child: Text(AppLocalizations.of(context)!.violationDate),
                        ),
                      ],
                    ),

                    const SizedBox(width: 12),

                    IconButton(
                      onPressed: () {
                        setState(() {
                          _sortAscending = !_sortAscending;
                        });
                        _applyQuery();
                      },
                      icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                      tooltip:
                          _sortAscending
                              ? AppLocalizations.of(context)!.ascending
                              : AppLocalizations.of(context)!.descending,
                    ),

                    // Refresh Button
                    IconButton(
                      onPressed: _refreshRequests,
                      icon: const Icon(Icons.refresh),
                      tooltip: AppLocalizations.of(context)!.refresh,
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
    final currentYear = DateTime.now().year;
    //final currentMonth = DateTime.now().month;
    final selectedYear = selectedMonth?.year ?? currentYear;
    final selectedMonthValue = selectedMonth?.month;

    // Calculate available years from availableMonths
    final availableYears = availableMonths.map((date) => date.year).toSet();

    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        int tempYear = selectedYear;
        int? tempMonth = selectedMonthValue;

        return StatefulBuilder(
          builder: (context, setState) {
            // Check if previous/next years have data
            final hasPreviousYear = availableYears.contains(tempYear - 1);
            final hasNextYear = availableYears.contains(tempYear + 1);

            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.selectMonth),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Year selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed:
                            hasPreviousYear
                                ? () {
                                  setState(() {
                                    tempYear--;
                                  });
                                }
                                : null,
                        icon: Icon(Icons.chevron_left, color: hasPreviousYear ? null : Colors.grey.shade400),
                      ),
                      Text(tempYear.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed:
                            hasNextYear
                                ? () {
                                  setState(() {
                                    tempYear++;
                                  });
                                }
                                : null,
                        icon: Icon(Icons.chevron_right, color: hasNextYear ? null : Colors.grey.shade400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Month selection grid
                  SizedBox(
                    width: 250,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(12, (index) {
                        final month = index + 1;
                        final isSelected = month == tempMonth;
                        final monthName = _getLocalizedMonthName(context, month);

                        // Check if this month has data
                        final monthDate = DateTime(tempYear, month, 1);
                        final isAvailable = availableMonths.contains(monthDate);

                        return SizedBox(
                          width: 70,
                          height: 35,
                          child: Material(
                            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap:
                                  isAvailable
                                      ? () {
                                        setState(() {
                                          tempMonth = month;
                                        });
                                      }
                                      : null,
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed:
                      tempMonth != null
                          ? () {
                            Navigator.of(context).pop(tempMonth != null ? DateTime(tempYear, tempMonth!) : null);
                          }
                          : null,
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
    } else {
      return DateFormat('MMM').format(DateTime(2024, month));
    }
  }

  Widget _buildRequestsList(BuildContext context, UserDisciplinaryActionRequestsState state) {
    if (FeatureFlags.serverPagedDisciplinaryRequests) return _buildPagedRequestsList(context, state);

    if (state.status == Status.loading) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
    }

    if (state.status == Status.failure) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(
                  context,
                )!.errorLoadingRequests(state.failure?.message ?? AppLocalizations.of(context)!.unknownError),
                style: TextStyle(color: Colors.red[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final userCode = context.read<UserBloc>().state.user?.id ?? 0;
                  context.read<UserDisciplinaryActionRequestsBloc>().add(
                    loadDisciplinaryRequestsEvent(userCode, widget.sourceType ?? RequestSourceType.myRequests),
                  );
                },
                child: Text(AppLocalizations.of(context)!.retry),
              ),
            ],
          ),
        ),
      );
    }

    final paginatedRequests = _paginatedRequests;
    final filteredRequests = _filteredAndSortedRequests;

    if (filteredRequests.isEmpty) return _buildEmptyState(context);

    return Column(
      children: [
        // Results info
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(
                AppLocalizations.of(context)!.showingRequestsOfTotal(paginatedRequests.length, filteredRequests.length),
                style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),

        // Request cards
        ...paginatedRequests.map((requestItem) => _buildRequestCard(context, requestItem, state)),
      ],
    );
  }

  /// The server-paged list.
  ///
  /// The rows arrive already interleaved and ordered across both tables, so
  /// there is nothing to merge here — the old `_filteredAndSortedRequests`
  /// pipeline collapses to a straight render.
  ///
  /// No full-height spinner while a page is in flight: the previous page's
  /// cards stay on screen and only the paginator is disabled, so the list does
  /// not collapse and reflow on every page turn.
  Widget _buildPagedRequestsList(BuildContext context, UserDisciplinaryActionRequestsState state) {
    final l10n = AppLocalizations.of(context)!;
    final paged = state.paged;

    if (state.status == Status.failure && paged.items.isEmpty) {
      return _buildPageError(context, state.failure?.message);
    }
    if (paged.pageFailure != null && paged.items.isEmpty) {
      return _buildPageError(context, paged.pageFailure?.message);
    }

    if (paged.items.isEmpty) {
      // While the first page is still loading there is nothing to say yet —
      // claiming "no requests found" and then filling the list reads as a bug.
      if (paged.isPageLoading) {
        return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
      }
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Text(
                // The total is the server's, across all pages and both tables.
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
        ...paged.items.map((requestItem) => _buildRequestCard(context, requestItem, state)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noRequestsFound,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (hasActiveFilters) ...[
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.tryAdjustingSearchFilters, style: TextStyle(color: Colors.grey[500])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPageError(BuildContext context, String? message) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              l10n.errorLoadingRequests(message ?? l10n.unknownError),
              style: TextStyle(color: Colors.red[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.read<UserDisciplinaryActionRequestsBloc>().add(const RefreshDisciplinaryPage()),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDeductDays(BuildContext context, double days) {
    final l10n = AppLocalizations.of(context)!;
    if (days == 0.25) return l10n.quarterDay;
    if (days == 0.5) return l10n.halfDay;
    if (days == 1.0) return '1 ${l10n.day}';
    return '${days.toInt()} ${l10n.days}';
  }

  String _getViolationDisplayName(BuildContext context, String? violationCategory, String? violation) {
    if (violationCategory == null || violation == null) {
      return '';
    }

    // For "Other" category, return the custom text directly
    if (violationCategory == 'other') {
      return violation;
    }

    // For predefined categories, find the violation and return localized name
    final violationData = ViolationData.findViolationByKey(violation);
    return violationData?.getLocalizedName(context) ?? violation;
  }

  String _getLocalizedCategoryName(BuildContext context, String? categoryValue) {
    if (categoryValue == null) return '';
    final category = ViolationCategory.fromString(categoryValue);
    return category.getLocalizedName(context);
  }

  Widget _buildRequestCard(BuildContext context, RequestItem requestItem, UserDisciplinaryActionRequestsState state) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final userCode = context.read<UserBloc>().state.user?.id ?? 0;

    // Determine if red styling should be applied
    final shouldUseRedStyling = requestItem.shouldUseRedStyling(userCode);
    final isEmployeeViewing =
        !requestItem.isInvestigation && (userCode == requestItem.disciplinaryAction?.employeeCode);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      // RED STYLING for investigations and HR Investigation disciplinary actions
      color: shouldUseRedStyling && !isEmployeeViewing ? Colors.red[50] : null,
      shape:
          shouldUseRedStyling && !isEmployeeViewing
              ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.red[700]!, width: 2),
              )
              : null,
      child: InkWell(
        onTap: () => _showRequestDetails(context, requestItem),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Requestor section
                  _buildRequestorSection(context, requestItem, isArabic),

                  const SizedBox(width: 16),

                  // Employee section - DIFFERENT for investigations
                  _buildEmployeeSection(context, requestItem, isArabic),

                  const SizedBox(width: 16),

                  // Action Type / Request Type section
                  _buildActionTypeSection(context, requestItem, isArabic),

                  // Investigation Link Badge (if created from investigation)
                  if (requestItem.isDisciplinaryAction &&
                      requestItem.disciplinaryAction!.createdFromInvestigation == true) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red[300]!, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.link, size: 12, color: Colors.red[700]),
                          const SizedBox(width: 4),
                          Text(
                            AppLocalizations.of(context)!.fromInvestigation,
                            style: TextStyle(fontSize: 10, color: Colors.red[700], fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),
                  // Status Badge - works for both disciplinary actions and investigations
                  if (requestItem.status != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColorForRequestItem(requestItem).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getStatusColorForRequestItem(requestItem)),
                      ),
                      child: Text(
                        _getLocalizedStatusForRequestItem(context, requestItem),
                        style: TextStyle(
                          color: _getStatusColorForRequestItem(requestItem),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              Divider(),
              // Main Content Row
              Row(
                children: [
                  // Created At Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.createdAt,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          requestItem.createdAt != null
                              ? DateFormat('MMM dd, yyyy  hh:mm a').format(requestItem.tzCreatedAt)
                              : 'N/A',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // Violation Date Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.violationDate,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          requestItem.violationDate != null
                              ? DateFormat('MMM dd, yyyy').format(requestItem.violationDate!)
                              : 'N/A',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // Deduct Days Section (for written warnings with deduction) - only for disciplinary actions
                  if (requestItem.isDisciplinaryAction &&
                      (requestItem.disciplinaryAction?.hasDeductionDays ?? false)) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.deductDays,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[300]!),
                            ),
                            child: Text(
                              _formatDeductDays(context, requestItem.disciplinaryAction!.deductionDays),
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Suspension Days Section (for written warnings with suspension) - only for disciplinary actions
                  if (requestItem.isDisciplinaryAction &&
                      (requestItem.disciplinaryAction?.hasSuspensionDays ?? false)) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.suspensionDays,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red[300]!),
                            ),
                            child: Text(
                              '${requestItem.disciplinaryAction!.suspensionDays} ${requestItem.disciplinaryAction!.suspensionDays == 1 ? AppLocalizations.of(context)!.day : AppLocalizations.of(context)!.days}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Violation Category & Violation Sections
                  if (requestItem.violationCategory != null && requestItem.violation != null) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.violationCategory,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getLocalizedCategoryName(context, requestItem.violationCategory),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (requestItem.violation != null) ...[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.violation,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              () {
                                final displayName = _getViolationDisplayName(
                                  context,
                                  requestItem.violationCategory,
                                  requestItem.violation,
                                );
                                return displayName.length > 40 ? '${displayName.substring(0, 40)}...' : displayName;
                              }(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  // Incident Description - show when no violation
                  if ((requestItem.violation == null) &&
                      requestItem.incidentDescription != null &&
                      requestItem.incidentDescription!.isNotEmpty) ...[
                    Expanded(
                      flex: 2,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.incidentDescription,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              requestItem.incidentDescription!.length > 40
                                  ? '${requestItem.incidentDescription!.substring(0, 40)}...'
                                  : requestItem.incidentDescription!,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Current Approver Section - works for both types
                  if ((requestItem.status == 'pending' || requestItem.status == 'on_hold') &&
                      ((requestItem.isDisciplinaryAction && requestItem.disciplinaryAction?.currentApprover != null) ||
                          (requestItem.isInvestigation && requestItem.investigation?.currentApprover != null)))
                    Expanded(
                      child: Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.currentApprover,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            if (requestItem.isDisciplinaryAction) ...[
                              if (isEmployeeViewing &&
                                  requestItem.disciplinaryAction?.currentApprover?.toLowerCase() == 'legal')
                                Text(
                                  AppLocalizations.of(context)!.hrDepartment,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                )
                              else
                                Text(
                                  requestItem.disciplinaryAction!.getLocalizedApproverName(context),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                            ] else if (requestItem.isInvestigation) ...[
                              Text(
                                _getLocalizedApproverNameForInvestigation(
                                  context,
                                  requestItem.investigation!.currentApprover ?? '',
                                ),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                  // Action Buttons (for team requests) - ONLY for disciplinary actions
                  if (widget.sourceType == RequestSourceType.teamRequests &&
                      requestItem.isActionable &&
                      requestItem.isDisciplinaryAction &&
                      _activeTab == 'actionable') ...[
                    const SizedBox(width: 24),
                    SizedBox(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: _buildActionButtons(context, requestItem.disciplinaryAction!),
                      ),
                    ),
                  ],

                  // Employee acknowledgment buttons (when user IS the employee) - ONLY for disciplinary actions
                  if ((widget.sourceType ?? RequestSourceType.myRequests) == RequestSourceType.myRequests &&
                      _activeTab == 'actionable' &&
                      requestItem.isActionable &&
                      requestItem.isDisciplinaryAction &&
                      userCode == requestItem.disciplinaryAction?.employeeCode &&
                      requestItem.disciplinaryAction?.currentApprover?.toLowerCase() == 'employee') ...[
                    const SizedBox(width: 24),
                    SizedBox(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: _buildActionButtons(context, requestItem.disciplinaryAction!),
                      ),
                    ),
                  ],

                  // Cancel button for user's own requests (only show for actionable requests) - ONLY for disciplinary actions
                  if ((widget.sourceType ?? RequestSourceType.myRequests) == RequestSourceType.myRequests &&
                      _activeTab == 'actionable' &&
                      requestItem.isActionable &&
                      requestItem.isDisciplinaryAction &&
                      userCode == requestItem.disciplinaryAction?.requestorCode &&
                      requestItem.disciplinaryAction?.currentApprover?.toLowerCase() == 'employee') ...[
                    const SizedBox(width: 24),
                    BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
                      builder: (context, state) {
                        final isCancelling =
                            state.cancelStatus == Status.loading && state.processingRequestId == requestItem.id;

                        return Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: ElevatedButton.icon(
                            onPressed:
                                isCancelling
                                    ? null
                                    : () => _showCancelConfirmationDialog(context, requestItem.disciplinaryAction!),
                            icon:
                                isCancelling
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                    : const Icon(Icons.cancel, size: 16),
                            label: Text(
                              isCancelling
                                  ? AppLocalizations.of(context)!.cancelling
                                  : AppLocalizations.of(context)!.cancelRequest,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, DisciplinaryActionRequestModel request) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
        builder: (context, state) {
          final isApproving = state.approveStatus == Status.loading && state.processingRequestId == request.id;
          final isDeclining = state.declineStatus == Status.loading && state.processingRequestId == request.id;
          final isPuttingOnHold = state.onHoldStatus == Status.loading && state.processingRequestId == request.id;
          final isInvestigating =
              state.investigationStatus == Status.loading && state.processingRequestId == request.id;
          final isConverting =
              state.convertToInvestigationStatus == Status.loading && state.processingRequestId == request.id;
          final isEscalatingToLegal =
              state.escalateToLegalStatus == Status.loading && state.processingRequestId == request.id;
          final isLegalUploading = state.legalUploadStatus == Status.loading && state.processingRequestId == request.id;
          final isHRFinalDecision =
              state.hrFinalDecisionStatus == Status.loading && state.processingRequestId == request.id;
          final isProcessing =
              isApproving ||
              isDeclining ||
              isPuttingOnHold ||
              isInvestigating ||
              isConverting ||
              isEscalatingToLegal ||
              isLegalUploading ||
              isHRFinalDecision;

          // Check if current user is the employee and needs to acknowledge
          final userBloc = context.read<UserBloc>();
          final currentUser = userBloc.state.user;
          final _isEmployeeAcknowledgment =
              request.currentApprover?.toLowerCase() == 'employee' && request.employeeCode == currentUser?.id;

          // Employee acknowledgment UI
          if (_isEmployeeAcknowledgment) {
            final isBaseLoading =
                state.acknowledgmentStatus == Status.loading && state.processingRequestId == request.id;
            final isConfirmAcknowledging = isBaseLoading && state.acknowledgmentActionType == 'confirm';
            final isRemarkAcknowledging = isBaseLoading && state.acknowledgmentActionType == 'acknowledge_with_remark';

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Confirm Button
                _buildActionIconButton(
                  context: context,
                  icon: Icons.check,
                  iconColor: Colors.green[600]!,
                  tooltip: AppLocalizations.of(context)!.confirm,
                  isLoading: isConfirmAcknowledging,
                  isDisabled: isRemarkAcknowledging,
                  onPressed: () => _showConfirmAcknowledgmentDialog(context, request),
                ),
                // Acknowledge with Remark Button
                _buildActionIconButton(
                  context: context,
                  icon: Icons.comment,
                  iconColor: Colors.blue[600]!,
                  tooltip: AppLocalizations.of(context)!.acknowledgeWithRemark,
                  isLoading: isRemarkAcknowledging,
                  isDisabled: isConfirmAcknowledging,
                  onPressed: () => _showAcknowledgeWithRemarkDialog(context, request),
                ),
              ],
            );
          }

          // Regular approval UI for N+2/HR
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Approve Button
              _buildActionIconButton(
                context: context,
                icon: Icons.check,
                iconColor: Colors.green[600]!,
                tooltip: AppLocalizations.of(context)!.approve,
                isLoading: isApproving,
                isDisabled: isProcessing && !isApproving,
                onPressed: () => _showApproveDialog(context, request),
              ),
              // Decline Button (always shown)
              _buildActionIconButton(
                context: context,
                icon: Icons.close,
                iconColor: Colors.red[600]!,
                tooltip: AppLocalizations.of(context)!.decline,
                isLoading: isDeclining,
                isDisabled: isProcessing && !isDeclining,
                onPressed: () => _showDeclineDialog(context, request),
              ),
              // Convert to Investigation Button (N+2 or HR + pending only)
              if ((request.currentApprover?.toLowerCase() == 'n2' || request.currentApprover?.toLowerCase() == 'hr') &&
                  request.status?.toLowerCase() == 'pending')
                _buildActionIconButton(
                  context: context,
                  icon: Icons.transform,
                  iconColor: Colors.orange[600]!,
                  tooltip: AppLocalizations.of(context)!.convertToInvestigation,
                  isLoading: isConverting,
                  isDisabled: isProcessing && !isConverting,
                  onPressed: () => _showConvertToInvestigationConfirmationDialog(context, request),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showConfirmAcknowledgmentDialog(BuildContext context, DisciplinaryActionRequestModel request) async {
    final userBloc = context.read<UserBloc>();
    final currentUser = userBloc.state.user;

    if (currentUser?.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(dialogContext)!.confirmAcknowledgment,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(dialogContext)!.confirmAcknowledgmentMessage),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_forward, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(dialogContext)!.acknowledgmentWillMoveRequestToApprovalWorkflow,
                            style: TextStyle(color: Colors.blue[700], fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(AppLocalizations.of(dialogContext)!.cancel),
              ),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                icon: const Icon(Icons.check, size: 18),
                label: Text(AppLocalizations.of(dialogContext)!.confirm),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      _handleConfirmAcknowledgment(context, request);
    }
  }

  void _handleConfirmAcknowledgment(BuildContext context, DisciplinaryActionRequestModel request) {
    final userBloc = context.read<UserBloc>();
    final currentUser = userBloc.state.user;

    if (currentUser?.id == null) return;

    context.read<UserDisciplinaryActionRequestsBloc>().add(
      AcknowledgeRequest(
        requestId: request.id!,
        employeeCode: currentUser!.id!,
        acknowledgmentType: 'confirm',
        remark: null,
      ),
    );
  }

  Future<void> _showAcknowledgeWithRemarkDialog(BuildContext context, DisciplinaryActionRequestModel request) async {
    final remarkController = TextEditingController();
    String? remarkError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => StatefulBuilder(
            builder:
                (context, setState) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.acknowledgeWithRemark),
                  content: SizedBox(
                    width: 400,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.pleaseProvideYourRemarkOnThisAction),
                          const SizedBox(height: 16),
                          TextField(
                            controller: remarkController,
                            maxLines: 4,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.yourRemark,
                              hintText: AppLocalizations.of(context)!.enterYourRemark,
                              border: const OutlineInputBorder(),
                              errorText: remarkError,
                            ),
                            onChanged: (value) {
                              if (remarkError != null) {
                                setState(() => remarkError = null);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (remarkController.text.trim().isEmpty) {
                          setState(() {
                            remarkError = AppLocalizations.of(context)!.pleaseProvideARemark;
                          });
                          return;
                        }
                        Navigator.of(dialogContext).pop(true);
                      },
                      child: Text(AppLocalizations.of(context)!.acknowledge),
                    ),
                  ],
                ),
          ),
    );

    if (confirmed == true && context.mounted) {
      final userBloc = context.read<UserBloc>();
      final currentUser = userBloc.state.user;

      if (currentUser?.id == null) return;

      context.read<UserDisciplinaryActionRequestsBloc>().add(
        AcknowledgeRequest(
          requestId: request.id!,
          employeeCode: currentUser!.id!,
          acknowledgmentType: 'acknowledge_with_remark',
          remark: remarkController.text.trim(),
        ),
      );
    }

    remarkController.dispose();
  }

  Widget _buildActionIconButton({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String tooltip,
    required bool isLoading,
    required VoidCallback? onPressed,
    bool isDisabled = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: isLoading || isDisabled ? null : onPressed,
          icon:
              isLoading
                  ? SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    ),
                  )
                  : Icon(icon, color: isDisabled ? Colors.grey : iconColor),
          iconSize: 25,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: const EdgeInsets.all(4),
          splashRadius: 18,
        ),
      ),
    );
  }

  Widget _buildPaginationControls(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(
              AppLocalizations.of(context)!.pageOfPages(_currentPage + 1, _totalPages),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),

            const Spacer(),

            // Previous button
            IconButton(
              onPressed:
                  _currentPage > 0
                      ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                      : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: AppLocalizations.of(context)!.previousPage,
            ),

            // Page numbers (show a few around current page)
            ..._buildPageNumbers(),

            // Next button
            IconButton(
              onPressed:
                  _currentPage < _totalPages - 1
                      ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                      : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: AppLocalizations.of(context)!.nextPage,
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
          onPressed: () {
            setState(() {
              _currentPage = i;
            });
          },
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

  /// Get status color for RequestItem (works for both disciplinary actions and investigations)
  Color _getStatusColorForRequestItem(RequestItem requestItem) {
    if (requestItem.isCancelled) {
      return Colors.grey;
    }
    switch (requestItem.status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'on_hold':
        return Colors.amber;
      case 'closed':
        return Colors.grey[700]!;
      case 'converted_to_investigation':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Get localized status text for RequestItem (works for both types)
  String _getLocalizedStatusForRequestItem(BuildContext context, RequestItem requestItem) {
    if (requestItem.isDisciplinaryAction) {
      return requestItem.disciplinaryAction!.getLocalizedStatus(context);
    } else {
      // For investigations, use generic status translation
      final status = requestItem.status?.toLowerCase() ?? '';
      final l10n = AppLocalizations.of(context)!;
      switch (status) {
        case 'pending':
          return l10n.pending;
        case 'approved':
          return l10n.approved;
        case 'declined':
          return l10n.declined;
        case 'closed':
          return l10n.closedAtHR;
        default:
          return requestItem.status ?? '';
      }
    }
  }

  /// Get localized approver name for investigations
  String _getLocalizedApproverNameForInvestigation(BuildContext context, String approver) {
    final l10n = AppLocalizations.of(context)!;
    switch (approver.toLowerCase()) {
      case 'hr':
        return l10n.hrDepartment;
      case 'legal':
        return l10n.legalDepartment;
      case 'top_management':
        return l10n.topManagement;
      default:
        return approver;
    }
  }

  /// Builds requestor section - shows requestor name and code
  Widget _buildRequestorSection(BuildContext context, RequestItem requestItem, bool isArabic) {
    // Get requestor name based on type using model helper methods
    final requestorName =
        requestItem.isInvestigation
            ? requestItem.investigation!.getRequestorName(isArabic)
            : requestItem.disciplinaryAction!.getRequestorName(isArabic);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.requestor,
            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            '$requestorName (${requestItem.requestorCode})',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Builds employee section - shows count for investigations, name for disciplinary actions
  Widget _buildEmployeeSection(BuildContext context, RequestItem requestItem, bool isArabic) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            requestItem.isInvestigation
                ? AppLocalizations.of(context)!.employees
                : AppLocalizations.of(context)!.employee,
            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (requestItem.isInvestigation) Icon(Icons.people, size: 18, color: Colors.blue[700]),
              if (requestItem.isInvestigation) const SizedBox(width: 4),
              Flexible(
                child: Text(
                  requestItem.getEmployeeDisplay(context, isArabic),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds action type section - shows "Investigation" for investigations
  Widget _buildActionTypeSection(BuildContext context, RequestItem requestItem, bool isArabic) {
    if (requestItem.isInvestigation) {
      return Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.requestType,
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)!.investigation,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      // Existing disciplinary action type display
      return Expanded(
        flex: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.actionType,
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              requestItem.disciplinaryAction!.getLocalizedActionType(context),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
  }

  void _showRequestDetails(BuildContext context, RequestItem requestItem) {
    if (requestItem.isInvestigation) {
      _showInvestigationDetails(context, requestItem.investigation!);
    } else {
      _showDisciplinaryActionDetails(context, requestItem.disciplinaryAction!);
    }
  }

  void _showInvestigationDetails(BuildContext context, InvestigationRequestModel investigation) {
    final bloc = context.read<UserDisciplinaryActionRequestsBloc>();
    final userBloc = context.read<UserBloc>();
    final userCode = userBloc.state.user?.id;
    final isEmployeeSubject =
        userCode != null && investigation.employeeCodes.contains(userCode) && investigation.requestorCode != userCode;

    // Passive observer: viewer is N+1/N+2 of the investigated employee but NOT the requestor.
    // This overrides group membership — even HR/legal/TM group members are restricted.
    // viewerIsPassiveObserver is stamped at fetch time by getProcessedInvestigations.
    final isOnProcessedTab = _activeTab == 'processedDisciplinary' || _activeTab == 'processedInvestigations';
    final isPassiveObserver = isOnProcessedTab && investigation.viewerIsPassiveObserver == true;

    // Show comprehensive investigation workflow dialog with smooth animations
    showDialog(
      context: context,
      builder:
          (dialogContext) => MultiBlocProvider(
            providers: [BlocProvider.value(value: bloc), BlocProvider.value(value: userBloc)],
            child: InvestigationWorkflowDialog(
              investigation: investigation,
              showActionButtons: widget.sourceType == RequestSourceType.teamRequests && _activeTab == 'actionable',
              isEmployeeSubject: isEmployeeSubject,
              isPassiveObserver: isPassiveObserver,
            ),
          ),
    );
  }

  void _showDisciplinaryActionDetails(BuildContext context, DisciplinaryActionRequestModel request) {
    final bloc = context.read<UserDisciplinaryActionRequestsBloc>();
    final userBloc = context.read<UserBloc>();
    final currentUser = userBloc.state.user;

    showDialog(
      context: context,
      builder:
          (dialogContext) => MultiBlocProvider(
            providers: [BlocProvider.value(value: bloc), BlocProvider.value(value: userBloc)],
            child: _DisciplinaryRequestDetailsDialog(
              request: request,
              sourceType:
                  (_activeTab == 'processedDisciplinary' || _activeTab == 'processedInvestigations')
                      ? RequestSourceType.processedRequests
                      : widget.sourceType,
              onApprove:
                  widget.sourceType == RequestSourceType.teamRequests &&
                          _activeTab == 'actionable' &&
                          (request.status == 'pending' || request.status == 'on_hold') &&
                          request.currentApprover?.toLowerCase() != 'legal'
                      ? () => _showApproveDialog(context, request)
                      : null,
              onDecline:
                  widget.sourceType == RequestSourceType.teamRequests &&
                          _activeTab == 'actionable' &&
                          (request.status == 'pending' || request.status == 'on_hold') &&
                          request.currentApprover?.toLowerCase() != 'legal'
                      ? () => _showDeclineDialog(context, request)
                      : null,
              onPutOnHold: null,
              onCancel:
                  (widget.sourceType ?? RequestSourceType.myRequests) == RequestSourceType.myRequests &&
                          _activeTab == 'actionable' &&
                          request.isActionable &&
                          request.requestorCode == context.read<UserBloc>().state.user?.id
                      ? () => _showCancelConfirmationFromDetails(context, request)
                      : null,
              onSendToHrInvestigation: null,
              onConfirmAcknowledgment:
                  (widget.sourceType ?? RequestSourceType.myRequests) == RequestSourceType.myRequests &&
                          _activeTab == 'actionable' &&
                          request.isActionable &&
                          request.currentApprover?.toLowerCase() == 'employee' &&
                          request.employeeCode == currentUser?.id
                      ? () => _showConfirmAcknowledgmentDialog(context, request)
                      : null,
              onAcknowledgeWithRemark:
                  (widget.sourceType ?? RequestSourceType.myRequests) == RequestSourceType.myRequests &&
                          _activeTab == 'actionable' &&
                          request.isActionable &&
                          request.currentApprover?.toLowerCase() == 'employee' &&
                          request.employeeCode == currentUser?.id
                      ? () => _showAcknowledgeWithRemarkDialog(context, request)
                      : null,
              onEscalateToLegal: null,
              onLegalAcknowledge: null,
              onLegalUpload: null,
              onHRApproveFinal: null,
              onHRDeclineFinal: null,
              onHRSuspend: null,
              onHRTerminate: null,
              onConvertToInvestigation:
                  widget.sourceType == RequestSourceType.teamRequests &&
                          _activeTab == 'actionable' &&
                          request.status == 'pending' &&
                          (request.currentApprover?.toLowerCase() == 'n2' ||
                              (currentUser?.groups?.contains('hr') ?? false))
                      ? () => _showConvertToInvestigationConfirmationDialog(context, request)
                      : null,
            ),
          ),
    );
  }

  void _approveRequest(
    BuildContext context,
    DisciplinaryActionRequestModel request,
    String reason, {
    Uint8List? pdfBytes,
    String? pdfFileName,
  }) {
    final bloc = context.read<UserDisciplinaryActionRequestsBloc>();
    final userBloc = context.read<UserBloc>();
    final currentUser = userBloc.state.user;

    if (currentUser?.id != null) {
      bloc.add(
        ApproveDisciplinaryActionRequest(
          request.id!,
          request.currentApprover!,
          currentUser!.id!,
          reason,
          pdfBytes: pdfBytes,
          pdfFileName: pdfFileName,
        ),
      );
    }
  }

  void _showApproveDialog(BuildContext context, DisciplinaryActionRequestModel request) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final bloc = context.read<UserDisciplinaryActionRequestsBloc>();
    final userBloc = context.read<UserBloc>();

    // PDF upload state
    Uint8List? selectedPdfBytes;
    String? selectedPdfFileName;
    String? pdfUploadError;

    showDialog(
      context: context,
      builder:
          (dialogContext) => MultiBlocProvider(
            providers: [BlocProvider.value(value: bloc), BlocProvider.value(value: userBloc)],
            child: StatefulBuilder(
              builder: (context, setState) {
                return BlocListener<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
                  listener: (context, state) {
                    if (state.approveStatus == Status.success) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      width: 400,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!.approve,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                            ],
                          ),
                          const Divider(),
                          Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context)!.pleaseEnterApprovalReason),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: reasonController,
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return AppLocalizations.of(context)!.pleaseEnterReason;
                                    }
                                    if (value.trim().length < 25) {
                                      return AppLocalizations.of(context)!.reasonMinimum25;
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    hintText: AppLocalizations.of(context)!.enterReason,
                                    labelText: AppLocalizations.of(context)!.approvalReason,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // PDF Upload Section (only for HR users)
                          BlocBuilder<UserBloc, UserState>(
                            builder: (context, userState) {
                              final isHrUser = userState.user?.groups?.contains('hr') ?? false;
                              if (!isHrUser) return const SizedBox.shrink();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(Icons.attach_file, color: Colors.blue, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.of(context)!.uploadInvestigationPdfOptional,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final result = await FilePicker.pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: ['pdf'],
                                          withData: true,
                                        );
                                        if (result != null && result.files.isNotEmpty) {
                                          final file = result.files.first;
                                          if (file.bytes != null) {
                                            if (DisciplinaryPDFStorageService.validatePDF(file.bytes!, file.name)) {
                                              setState(() {
                                                selectedPdfBytes = file.bytes;
                                                selectedPdfFileName = file.name;
                                                pdfUploadError = null; // Clear any previous error
                                              });
                                            } else {
                                              // Set error state for invalid PDF
                                              setState(() {
                                                selectedPdfBytes = null;
                                                selectedPdfFileName = null;
                                                pdfUploadError = AppLocalizations.of(context)!.invalidFilePdfUnder10mb;
                                              });
                                            }
                                          }
                                        }
                                      } catch (e) {
                                        // Handle file picker error
                                        setState(() {
                                          selectedPdfBytes = null;
                                          selectedPdfFileName = null;
                                          pdfUploadError = AppLocalizations.of(
                                            context,
                                          )!.errorSelectingFile(e.toString());
                                        });
                                      }
                                    },
                                    icon: Icon(selectedPdfBytes != null ? Icons.check_circle : Icons.upload_file),
                                    label: Text(
                                      selectedPdfBytes != null
                                          ? AppLocalizations.of(context)!.fileSelected
                                          : AppLocalizations.of(context)!.choosePdfFile,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: selectedPdfBytes != null ? Colors.green : Colors.blue,
                                      side: BorderSide(color: selectedPdfBytes != null ? Colors.green : Colors.blue),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context)!.pdfFilesOnlyMax10mb,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  // Error message display
                                  if (pdfUploadError != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        border: Border.all(color: Colors.red[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              pdfUploadError!,
                                              style: TextStyle(
                                                color: Colors.red[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => setState(() => pdfUploadError = null),
                                            icon: Icon(Icons.close, color: Colors.red, size: 16),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (selectedPdfBytes != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        border: Border.all(color: Colors.green[200]!),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.picture_as_pdf, color: Colors.green),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              selectedPdfFileName ?? '',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed:
                                                () => setState(() {
                                                  selectedPdfBytes = null;
                                                  selectedPdfFileName = null;
                                                  pdfUploadError = null; // Clear error when removing file
                                                }),
                                            icon: const Icon(Icons.close, size: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text(AppLocalizations.of(context)!.cancel),
                              ),
                              const SizedBox(width: 8),
                              BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
                                builder: (context, state) {
                                  final isApproving =
                                      state.approveStatus == Status.loading && state.processingRequestId == request.id;

                                  return ElevatedButton.icon(
                                    onPressed:
                                        isApproving
                                            ? null
                                            : () {
                                              if (formKey.currentState!.validate()) {
                                                _approveRequest(
                                                  context,
                                                  request,
                                                  reasonController.text.trim(),
                                                  pdfBytes: selectedPdfBytes,
                                                  pdfFileName: selectedPdfFileName,
                                                );
                                              }
                                            },
                                    icon:
                                        isApproving
                                            ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                            : const Icon(Icons.check, size: 18),
                                    label: Text(
                                      isApproving
                                          ? AppLocalizations.of(context)!.approving
                                          : AppLocalizations.of(context)!.approve,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green[600],
                                      foregroundColor: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }

  void _showDeclineDialog(BuildContext context, DisciplinaryActionRequestModel request) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final bloc = context.read<UserDisciplinaryActionRequestsBloc>();
    final userBloc = context.read<UserBloc>();

    // PDF upload state
    Uint8List? selectedPdfBytes;
    String? selectedPdfFileName;
    String? pdfUploadError;

    showDialog(
      context: context,
      builder:
          (dialogContext) => MultiBlocProvider(
            providers: [BlocProvider.value(value: bloc), BlocProvider.value(value: userBloc)],
            child: StatefulBuilder(
              builder: (context, setState) {
                return BlocListener<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
                  listener: (context, state) {
                    if (state.declineStatus == Status.success) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: Dialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Container(
                      width: 400,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(context)!.declineRequest,
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                            ],
                          ),
                          const Divider(),
                          Form(
                            key: formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppLocalizations.of(context)!.pleaseEnterDeclineReason),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: reasonController,
                                  maxLines: 3,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return AppLocalizations.of(context)!.pleaseEnterReason;
                                    }
                                    if (value.trim().length < 25) {
                                      return AppLocalizations.of(context)!.reasonMinimum25;
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    hintText: AppLocalizations.of(context)!.enterReason,
                                    labelText: AppLocalizations.of(context)!.declineReason,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // PDF Upload Section (only for HR users)
                          BlocBuilder<UserBloc, UserState>(
                            builder: (context, userState) {
                              final isHrUser = userState.user?.groups?.contains('hr') ?? false;
                              if (!isHrUser) return const SizedBox.shrink();

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Icon(Icons.attach_file, color: Colors.blue, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        AppLocalizations.of(context)!.uploadInvestigationPdfOptional,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final result = await FilePicker.pickFiles(
                                          type: FileType.custom,
                                          allowedExtensions: ['pdf'],
                                          withData: true,
                                        );
                                        if (result != null && result.files.isNotEmpty) {
                                          final file = result.files.first;
                                          if (file.bytes != null) {
                                            if (DisciplinaryPDFStorageService.validatePDF(file.bytes!, file.name)) {
                                              setState(() {
                                                selectedPdfBytes = file.bytes;
                                                selectedPdfFileName = file.name;
                                                pdfUploadError = null; // Clear any previous error
                                              });
                                            } else {
                                              // Set error state for invalid PDF
                                              setState(() {
                                                selectedPdfBytes = null;
                                                selectedPdfFileName = null;
                                                pdfUploadError = AppLocalizations.of(context)!.invalidFilePdfUnder10mb;
                                              });
                                            }
                                          }
                                        }
                                      } catch (e) {
                                        // Handle file picker error
                                        setState(() {
                                          selectedPdfBytes = null;
                                          selectedPdfFileName = null;
                                          pdfUploadError = AppLocalizations.of(
                                            context,
                                          )!.errorSelectingFile(e.toString());
                                        });
                                      }
                                    },
                                    icon: Icon(selectedPdfBytes != null ? Icons.check_circle : Icons.upload_file),
                                    label: Text(
                                      selectedPdfBytes != null
                                          ? AppLocalizations.of(context)!.fileSelected
                                          : AppLocalizations.of(context)!.choosePdfFile,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: selectedPdfBytes != null ? Colors.green : Colors.blue,
                                      side: BorderSide(color: selectedPdfBytes != null ? Colors.green : Colors.blue),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context)!.pdfFilesOnlyMax10mb,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                  // Error message display
                                  if (pdfUploadError != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        border: Border.all(color: Colors.red[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              pdfUploadError!,
                                              style: TextStyle(
                                                color: Colors.red[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () => setState(() => pdfUploadError = null),
                                            icon: Icon(Icons.close, color: Colors.red, size: 16),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (selectedPdfBytes != null) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        border: Border.all(color: Colors.green[200]!),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.picture_as_pdf, color: Colors.green),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              selectedPdfFileName ?? '',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed:
                                                () => setState(() {
                                                  selectedPdfBytes = null;
                                                  selectedPdfFileName = null;
                                                  pdfUploadError = null; // Clear error when removing file
                                                }),
                                            icon: const Icon(Icons.close, size: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text(AppLocalizations.of(context)!.cancel),
                              ),
                              const SizedBox(width: 8),
                              BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
                                builder: (context, state) {
                                  final isDeclining =
                                      state.declineStatus == Status.loading && state.processingRequestId == request.id;

                                  return ElevatedButton.icon(
                                    onPressed:
                                        isDeclining
                                            ? null
                                            : () {
                                              if (formKey.currentState!.validate()) {
                                                final currentUser = userBloc.state.user;
                                                if (currentUser?.id != null) {
                                                  bloc.add(
                                                    DeclineDisciplinaryActionRequest(
                                                      request.id!,
                                                      request.currentApprover!,
                                                      currentUser!.id!,
                                                      reasonController.text.trim(),
                                                      pdfBytes: selectedPdfBytes,
                                                      pdfFileName: selectedPdfFileName,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                    icon:
                                        isDeclining
                                            ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                            : const Icon(Icons.close, size: 18),
                                    label: Text(
                                      isDeclining
                                          ? AppLocalizations.of(context)!.declining
                                          : AppLocalizations.of(context)!.decline,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[600],
                                      foregroundColor: Colors.white,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }

  void _showConvertToInvestigationConfirmationDialog(BuildContext context, DisciplinaryActionRequestModel request) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final bloc = context.read<UserDisciplinaryActionRequestsBloc>();
    final userBloc = context.read<UserBloc>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => MultiBlocProvider(
            providers: [BlocProvider.value(value: bloc), BlocProvider.value(value: userBloc)],
            child: BlocListener<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
              listener: (context, state) {
                if (state.convertToInvestigationStatus == Status.success ||
                    state.convertToInvestigationStatus == Status.failure) {
                  Navigator.pop(dialogContext);
                }
              },
              child: BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
                builder: (context, state) {
                  final isConverting = state.convertToInvestigationStatus == Status.loading;

                  return AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.transform, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(dialogContext)!.convertToInvestigation,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    content: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(dialogContext)!.convertToInvestigationDescription,
                            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange[300]!, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(dialogContext)!.whatHappensNext,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildConversionInfoPoint(
                                  AppLocalizations.of(dialogContext)!.investigationRequestWillBeCreated,
                                ),
                                _buildConversionInfoPoint(AppLocalizations.of(dialogContext)!.originalDaWillBeLinked),
                                _buildConversionInfoPoint(
                                  AppLocalizations.of(dialogContext)!.investigationFollowsFormalProcess,
                                ),
                                _buildConversionInfoPoint(AppLocalizations.of(dialogContext)!.hrLegalTopManagement),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(dialogContext)!.pleaseEnterInvestigationReason,
                            style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: reasonController,
                            maxLines: 3,
                            enabled: !isConverting,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppLocalizations.of(dialogContext)!.pleaseEnterReason;
                              }
                              if (value.trim().length < 25) {
                                return AppLocalizations.of(dialogContext)!.reasonMinimum25;
                              }
                              return null;
                            },
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              hintText: AppLocalizations.of(dialogContext)!.enterReason,
                              labelText: AppLocalizations.of(dialogContext)!.investigationReason,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(dialogContext)!.convertToInvestigationConfirmation,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey[900]),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: isConverting ? null : () => Navigator.pop(dialogContext),
                        child: Text(AppLocalizations.of(dialogContext)!.cancel),
                      ),
                      ElevatedButton.icon(
                        icon:
                            isConverting
                                ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                : const Icon(Icons.transform, size: 18),
                        label: Text(AppLocalizations.of(dialogContext)!.convertToInvestigation),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                        ),
                        onPressed:
                            isConverting
                                ? null
                                : () {
                                  if (formKey.currentState!.validate()) {
                                    context.read<UserDisciplinaryActionRequestsBloc>().add(
                                      ConvertDisciplinaryActionToInvestigation(
                                        disciplinaryActionId: request.id!,
                                        convertedBy: context.read<UserBloc>().state.user!.id!,
                                        reason: reasonController.text.trim(),
                                      ),
                                    );
                                  }
                                },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
    );
  }

  Widget _buildConversionInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('•  ', style: TextStyle(color: Colors.orange[700], fontSize: 16)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _showCancelConfirmationDialog(BuildContext context, DisciplinaryActionRequestModel request) {
    // Capture the bloc reference before showing the dialog
    final bloc = context.read<UserDisciplinaryActionRequestsBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.confirmCancelRequest),
          content: Text(AppLocalizations.of(dialogContext)!.cancelRequestMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(dialogContext)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                bloc.add(CancelDisciplinaryActionRequest(request.id!));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
              child: Text(AppLocalizations.of(dialogContext)!.cancelRequest),
            ),
          ],
        );
      },
    );
  }

  void _showCancelConfirmationFromDetails(BuildContext context, DisciplinaryActionRequestModel request) {
    // Capture the bloc reference before showing the dialog
    final bloc = context.read<UserDisciplinaryActionRequestsBloc>();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(dialogContext)!.confirmCancelRequest),
          content: Text(AppLocalizations.of(dialogContext)!.cancelRequestMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(dialogContext)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close confirmation dialog
                Navigator.of(context).pop(); // Close details dialog
                bloc.add(CancelDisciplinaryActionRequest(request.id!));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
              child: Text(AppLocalizations.of(dialogContext)!.cancelRequest),
            ),
          ],
        );
      },
    );
  }
}

class _DisciplinaryRequestDetailsDialog extends StatefulWidget {
  final DisciplinaryActionRequestModel request;
  final RequestSourceType? sourceType;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;
  final VoidCallback? onPutOnHold;
  final VoidCallback? onCancel;
  final VoidCallback? onSendToHrInvestigation;
  final VoidCallback? onConfirmAcknowledgment;
  final VoidCallback? onAcknowledgeWithRemark;
  // New callbacks
  final VoidCallback? onEscalateToLegal;
  final VoidCallback? onLegalAcknowledge;
  final VoidCallback? onLegalUpload;
  final VoidCallback? onHRApproveFinal;
  final VoidCallback? onHRDeclineFinal;
  final VoidCallback? onHRSuspend;
  final VoidCallback? onHRTerminate;
  final VoidCallback? onConvertToInvestigation;

  const _DisciplinaryRequestDetailsDialog({
    required this.request,
    this.sourceType,
    this.onApprove,
    this.onDecline,
    this.onPutOnHold,
    this.onCancel,
    this.onSendToHrInvestigation,
    this.onConfirmAcknowledgment,
    this.onAcknowledgeWithRemark,
    this.onEscalateToLegal,
    this.onLegalAcknowledge,
    this.onLegalUpload,
    this.onHRApproveFinal,
    this.onHRDeclineFinal,
    this.onHRSuspend,
    this.onHRTerminate,
    this.onConvertToInvestigation,
  });

  @override
  State<_DisciplinaryRequestDetailsDialog> createState() => _DisciplinaryRequestDetailsDialogState();
}

class _DisciplinaryRequestDetailsDialogState extends State<_DisciplinaryRequestDetailsDialog> {
  late DisciplinaryActionRequestModel _currentRequest;
  late UserDisciplinaryActionRequestsBloc _bloc;

  // Edit-related state variables
  ActiveSectionType _activeSection = ActiveSectionType.none;
  double? _selectedDeductDays;
  late TextEditingController _suspensionDaysController;

  // Validation state
  String? _deductDaysError;
  String? _suspensionDaysError;

  // View management for unified dialog (DA ↔ Investigation)
  int _currentView = 0; // 0 = DA Details, 1 = Investigation Details
  bool _forwardNavigation = true;
  InvestigationRequestModel? _investigation;
  bool _isLoadingInvestigation = false;
  int? _resolvedInvestigationId; // null until set from model or fetched via BLoC

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc = context.read<UserDisciplinaryActionRequestsBloc>();
  }

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
    _initializeEditControllers();
    // Initialize from model (already populated for createdFromInvestigation case)
    _resolvedInvestigationId = _currentRequest.investigationId;
    // If converted_to_investigation but ID is missing, resolve it via BLoC
    if (_currentRequest.investigationId == null &&
        _currentRequest.status?.toLowerCase() == 'converted_to_investigation') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<UserDisciplinaryActionRequestsBloc>().add(
            FetchInvestigationByDisciplinaryActionId(_currentRequest.id!),
          );
        }
      });
    }
  }

  void _initializeEditControllers() {
    _selectedDeductDays = _currentRequest.writtenWarningOptions?.deductDays;
    _suspensionDaysController = TextEditingController(
      text: _currentRequest.writtenWarningOptions?.suspensionDays?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _bloc.add(const ResetAttachmentUrls());
    _bloc.add(const ResetLinkedInvestigationId());
    _suspensionDaysController.dispose();
    super.dispose();
  }

  // Role identification getters
  bool get _isEmployee {
    return context.read<UserBloc>().state.user?.id == _currentRequest.employeeCode;
  }

  bool get _isN2User {
    return context.read<UserBloc>().state.user?.id == _currentRequest.n2Code;
  }

  bool get _isHrUser {
    final userBloc = context.read<UserBloc>();
    return userBloc.state.user?.groups?.contains('hr') ?? false;
  }

  // True if the current viewer is one of the investigated employees
  bool get _isInvestigationSubject {
    final userId = context.read<UserBloc>().state.user?.id;
    if (userId == null || _investigation == null) return false;
    return _investigation!.employeeCodes.contains(userId);
  }

  // True if the viewer can see full investigation details in the processed-requests view.
  // N+1/N+2 of the investigated employee who is NOT the requestor is restricted —
  // this overrides group membership (HR, legal, TM group members are also restricted
  // if they have a hierarchical relationship to the investigated employee).
  // The viewerIsPassiveObserver flag is stamped at fetch time by the repo.
  // True when the viewer is a passive observer (N+1/N+2 of investigated employee, not requestor).
  // This is set at fetch time by the repo. Only applies in processed-requests context.
  bool get _isPassiveInvestigationObserver {
    if (widget.sourceType != RequestSourceType.processedRequests) return false;
    return _investigation?.viewerIsPassiveObserver == true;
  }

  bool get _canViewInvestigationContent {
    if (widget.sourceType != RequestSourceType.processedRequests) return true;
    if (_isInvestigationSubject) return false;
    if (_isPassiveInvestigationObserver) return false;

    final userId = context.read<UserBloc>().state.user?.id;
    if (userId == null || _investigation == null) return false;

    // Requestor always sees full details
    if (userId == _investigation!.requestorCode) return true;

    // Named approvers on this specific request see full details
    if (userId == _investigation!.hrCode) return true;
    if (userId == _investigation!.legalCode) return true;
    if (userId == _investigation!.topManagementCode) return true;

    // HR/legal/TM group members see full details unless caught by the passive observer check above
    final groups = context.read<UserBloc>().state.user?.groups ?? [];
    if (groups.contains('hr')) return true;
    if (groups.contains('legal')) return true;
    if (groups.contains('top management')) return true;

    return false;
  }

  bool get _isN1NotRequestor {
    // N+1 viewing a request they didn't create (not employee, not requestor, not N+2, not HR)
    final userId = context.read<UserBloc>().state.user?.id;
    return userId != _currentRequest.employeeCode &&
        userId != _currentRequest.requestorCode &&
        userId != _currentRequest.n2Code &&
        !_isHrUser;
  }

  // Visibility getters
  bool get _canViewIncidentDescription {
    // Visible to: Requestor, N+2, HR, Legal
    // Hidden from: Employee, N+1 (if not requestor)
    if (_isEmployee && _currentRequest.actionType == DisciplinaryActionType.hrInvestigation) return false;
    if (_isN1NotRequestor && _currentRequest.actionType == DisciplinaryActionType.hrInvestigation) return false;
    return true;
  }

  bool get _canViewInvestigationDetails {
    // Visible to: Requestor, N+2, HR, Legal
    // Hidden from: Employee, N+1 (if not requestor)
    if (_isEmployee) return false;
    if (_isN1NotRequestor && _currentRequest.actionType == DisciplinaryActionType.hrInvestigation) return false;
    return true;
  }

  bool get _canViewLegalEscalation {
    // Visible to: Requestor, N+2, HR, Legal
    // Hidden from: Employee, N+1 (if not requestor)
    if (_isEmployee) return false;
    if (_isN1NotRequestor && _currentRequest.actionType == DisciplinaryActionType.hrInvestigation) return false;
    return true;
  }

  bool get _canViewAttachments {
    // Visible to: Requestor, N+2, HR, Legal
    // Hidden from: Employee, N+1 (if not requestor)
    if (_isEmployee) return false;
    if (_isN1NotRequestor && _currentRequest.actionType == DisciplinaryActionType.hrInvestigation) return false;
    return true;
  }

  // Permission getters
  bool get _canEditDeductDays =>
      (_isN2User || _isHrUser) &&
      _currentRequest.currentApprover?.toLowerCase() == (_isN2User ? 'n2' : 'hr') &&
      (_currentRequest.status?.toLowerCase() == 'pending' || _currentRequest.status?.toLowerCase() == 'on_hold') &&
      _currentRequest.isWrittenWarning &&
      _currentRequest.hasDeductionDays;

  bool get _canEditSuspensionDays =>
      _isHrUser &&
      _currentRequest.currentApprover?.toLowerCase() == 'hr' &&
      (_currentRequest.status?.toLowerCase() == 'pending' || _currentRequest.status?.toLowerCase() == 'on_hold') &&
      _currentRequest.isWrittenWarning;

  bool get _canShowEditButton => _canEditDeductDays || _canEditSuspensionDays;

  Widget _buildEditSection() {
    return Container(
      width: 550,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.editWrittenWarning,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),

          // Deduct Days Input (N+2 and HR)
          if (_canEditDeductDays) ...[
            Text(
              AppLocalizations.of(context)!.editDeductDays,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField2<double>(
              valueListenable: ValueNotifier(_selectedDeductDays),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: Text(
                AppLocalizations.of(context)!.selectDeductDays,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              items: [
                DropdownItem(value: 0.25, child: Text(AppLocalizations.of(context)!.quarterDay)),
                DropdownItem(value: 0.5, child: Text(AppLocalizations.of(context)!.halfDay)),
                DropdownItem(value: 1.0, child: Text('1 ${AppLocalizations.of(context)!.day}')),
                DropdownItem(value: 2.0, child: Text('2 ${AppLocalizations.of(context)!.days}')),
                DropdownItem(value: 3.0, child: Text('3 ${AppLocalizations.of(context)!.days}')),
                DropdownItem(value: 4.0, child: Text('4 ${AppLocalizations.of(context)!.days}')),
                DropdownItem(value: 5.0, child: Text('5 ${AppLocalizations.of(context)!.days}')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDeductDays = value;
                });
              },
              dropdownStyleData: DropdownStyleData(decoration: BoxDecoration(borderRadius: BorderRadius.circular(8))),
            ),
            const SizedBox(height: 16),
          ],

          // Suspension Days Input (HR only)
          if (_canEditSuspensionDays) ...[
            Text(
              AppLocalizations.of(context)!.editSuspensionDays,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _suspensionDaysController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _suspensionDaysError != null ? Colors.red : Colors.grey.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _suspensionDaysError != null ? Colors.red : Colors.grey.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: _suspensionDaysError != null ? Colors.red : Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                hintText: AppLocalizations.of(context)!.suspensionDaysHint,
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
                suffixText: AppLocalizations.of(context)!.days,
                errorText: _suspensionDaysError,
                errorStyle: const TextStyle(fontSize: 12, color: Colors.red),
              ),
              onChanged: _validateSuspensionDays,
            ),
          ],
        ],
      ),
    );
  }

  String _getDisplayName(BuildContext context, String? englishName, String? arabicName) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? (arabicName ?? englishName ?? '') : (englishName ?? arabicName ?? '');
  }

  Widget _buildInvestigationLinkSection(BuildContext context) {
    if (_currentRequest.createdFromInvestigation != true &&
        _currentRequest.status?.toLowerCase() != 'converted_to_investigation') {
      return const SizedBox.shrink();
    }
    // Use _resolvedInvestigationId (set from model or fetched asynchronously via BLoC)
    final investigationId = _resolvedInvestigationId ?? 0;
    final isResolvingId =
        _resolvedInvestigationId == null && _currentRequest.status?.toLowerCase() == 'converted_to_investigation';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      width: 550,
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(Icons.link, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentRequest.createdFromInvestigation == true
                      ? AppLocalizations.of(context)!.createdFromInvestigation
                      : AppLocalizations.of(context)!.convertedToInvestigation,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[900], fontSize: 13),
                ),
                const SizedBox(height: 2),
                isResolvingId
                    ? SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.red[700]),
                    )
                    : Text(
                      AppLocalizations.of(context)!.investigationNumber(investigationId.toString()),
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
              ],
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.search, size: 16),
            label: Text(AppLocalizations.of(context)!.viewButton, style: const TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
            ),
            // Disable while resolving to prevent fetching investigation #0
            onPressed: isResolvingId ? null : () => _openInvestigationDialog(context, investigationId),
          ),
        ],
      ),
    );
  }

  void _navigateToInvestigation() {
    setState(() {
      _forwardNavigation = true;
      _currentView = 1;
    });
  }

  void _navigateBackToDA() {
    setState(() {
      _forwardNavigation = false;
      _currentView = 0;
    });
  }

  Future<void> _openInvestigationDialog(BuildContext context, investigationId) async {
    setState(() => _isLoadingInvestigation = true);
    final approverCode = context.read<UserBloc>().state.user?.id;
    context.read<UserDisciplinaryActionRequestsBloc>().add(
      FetchInvestigationById(investigationId, approverCode: approverCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n2LocalizedName = _getDisplayName(context, _currentRequest.n2EnglishName, _currentRequest.n2ArabicName);
    return MultiBlocListener(
      listeners: [
        BlocListener<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
          listener: (context, state) {
            // Handle edit operation feedback (separate if — does NOT pop the dialog)
            if (state.editStatus == Status.success) {
              final updatedRequestItem = state.requests.firstWhere(
                (requestItem) => requestItem.id == _currentRequest.id,
                orElse: () => RequestItem.fromDisciplinary(_currentRequest),
              );

              setState(() {
                _currentRequest = updatedRequestItem.disciplinaryAction!;
                _activeSection = ActiveSectionType.none;
                _deductDaysError = null;
                _suspensionDaysError = null;
              });

              context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetEditStatus());
            } else if (state.editStatus == Status.failure) {
              context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetEditStatus());
            }

            // Handle fetched investigation — switch to investigation view within the same dialog
            if (state.fetchedInvestigationStatus == Status.success && state.fetchedInvestigation != null) {
              context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetFetchedInvestigation());
              setState(() {
                _investigation = state.fetchedInvestigation!;
                _isLoadingInvestigation = false;
              });
              _navigateToInvestigation();
            } else if (state.fetchedInvestigationStatus == Status.failure) {
              context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetFetchedInvestigation());
              setState(() => _isLoadingInvestigation = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    AppLocalizations.of(
                      context,
                    )!.failedToLoadInvestigation(state.operationFailure?.message ?? 'Unknown error'),
                  ),
                ),
              );
            }

            // Resolve investigation ID for 'converted_to_investigation' case
            if (state.linkedInvestigationIdStatus == Status.success && state.linkedInvestigationId != null) {
              context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetLinkedInvestigationId());
              setState(() => _resolvedInvestigationId = state.linkedInvestigationId);
            } else if (state.linkedInvestigationIdStatus == Status.failure) {
              context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetLinkedInvestigationId());
              // View button stays disabled (isResolvingId remains true); no snackbar needed
            }

            // All handlers below pop the dialog — use else-if to prevent cascading pops
            // from stale success values causing blank white page
            if (state.approveStatus == Status.success) {
              final updatedRequestItem = state.requests.firstWhere(
                (requestItem) => requestItem.id == _currentRequest.id,
                orElse: () => RequestItem.fromDisciplinary(_currentRequest),
              );
              setState(() {
                _currentRequest = updatedRequestItem.disciplinaryAction!;
              });
              Navigator.of(context).pop();
            } else if (state.declineStatus == Status.success) {
              final updatedRequestItem = state.requests.firstWhere(
                (requestItem) => requestItem.id == _currentRequest.id,
                orElse: () => RequestItem.fromDisciplinary(_currentRequest),
              );
              setState(() {
                _currentRequest = updatedRequestItem.disciplinaryAction!;
              });
              Navigator.of(context).pop();
            } else if (state.onHoldStatus == Status.success) {
              final updatedRequestItem = state.requests.firstWhere(
                (requestItem) => requestItem.id == _currentRequest.id,
                orElse: () => RequestItem.fromDisciplinary(_currentRequest),
              );
              setState(() {
                _currentRequest = updatedRequestItem.disciplinaryAction!;
              });
              Navigator.of(context).pop();
            } else if (state.investigationStatus == Status.success) {
              final updatedRequestItem = state.requests.firstWhere(
                (requestItem) => requestItem.id == _currentRequest.id,
                orElse: () => RequestItem.fromDisciplinary(_currentRequest),
              );
              setState(() {
                _currentRequest = updatedRequestItem.disciplinaryAction!;
              });
              Navigator.of(context).pop();
            } else if (state.acknowledgmentStatus == Status.success &&
                _currentRequest.currentApprover?.toLowerCase() == 'employee') {
              Navigator.of(context).pop();
            } else if (state.hrFinalDecisionStatus == Status.success) {
              final updatedRequestItem = state.requests.firstWhere(
                (requestItem) => requestItem.id == _currentRequest.id,
                orElse: () => RequestItem.fromDisciplinary(_currentRequest),
              );
              setState(() {
                _currentRequest = updatedRequestItem.disciplinaryAction!;
              });
              Navigator.of(context).pop();
            } else if (state.escalateToLegalStatus == Status.success) {
              final updatedRequestItem = state.requests.firstWhere(
                (requestItem) => requestItem.id == _currentRequest.id,
                orElse: () => RequestItem.fromDisciplinary(_currentRequest),
              );
              setState(() {
                _currentRequest = updatedRequestItem.disciplinaryAction!;
              });
              Navigator.of(context).pop();
            } else if (state.legalUploadStatus == Status.success) {
              final updatedRequestItem = state.requests.firstWhere(
                (requestItem) => requestItem.id == _currentRequest.id,
                orElse: () => RequestItem.fromDisciplinary(_currentRequest),
              );
              setState(() {
                _currentRequest = updatedRequestItem.disciplinaryAction!;
              });
              Navigator.of(context).pop();
            } else if (state.legalAcknowledgeStatus == Status.success) {
              final updatedRequestItem = state.requests.firstWhere(
                (requestItem) => requestItem.id == _currentRequest.id,
                orElse: () => RequestItem.fromDisciplinary(_currentRequest),
              );
              setState(() {
                _currentRequest = updatedRequestItem.disciplinaryAction!;
              });
              Navigator.of(context).pop();
            } else if (state.cancelStatus == Status.success) {
              final updatedRequestItem = state.requests.firstWhere(
                (requestItem) => requestItem.id == _currentRequest.id,
                orElse: () => RequestItem.fromDisciplinary(_currentRequest),
              );
              setState(() {
                _currentRequest = updatedRequestItem.disciplinaryAction!;
              });
              Navigator.of(context).pop();
            } else if (state.convertToInvestigationStatus == Status.success) {
              Navigator.of(context).pop();
            }
          },
        ),
        BlocListener<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
          listenWhen: (previous, current) => previous.pdfOpenStatus != current.pdfOpenStatus,
          listener: (context, state) async {
            if (state.pdfOpenStatus == Status.success && state.pdfSignedUrl != null) {
              final uri = Uri.parse(state.pdfSignedUrl!);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (context.mounted) {
                context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetPdfOpenStatus());
              }
            } else if (state.pdfOpenStatus == Status.failure) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.operationFailure?.message ?? 'Failed to open attachment')));
                context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetPdfOpenStatus());
              }
            }
          },
        ),
      ],
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: context.screenWidth < 600 ? context.screenWidth * 0.95 : 600,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed Header — responds to current view
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    if (_currentView == 1) ...[
                      IconButton(
                        onPressed: _navigateBackToDA,
                        icon: const Icon(Icons.arrow_back),
                        tooltip: AppLocalizations.of(context)!.requestDetails,
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.search, color: Theme.of(context).primaryColor, size: 24),
                    ] else
                      Icon(Icons.gavel, color: Theme.of(context).primaryColor, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _currentView == 1
                            ? AppLocalizations.of(context)!.investigationDetails
                            : AppLocalizations.of(context)!.requestDetails,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_isLoadingInvestigation)
                      const Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                  ],
                ),
              ),

              const Divider(),

              // AnimatedSwitcher for DA ↔ Investigation views
              Flexible(
                child: ClipRect(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchOutCurve: const Threshold(0.0),
                    switchInCurve: const Interval(0.1, 1.0, curve: Curves.easeInOut),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      final childKey = child.key as ValueKey<int>;
                      final childView = childKey.value;
                      final isEntering = childView == _currentView;

                      if (!isEntering) {
                        return const SizedBox.shrink();
                      }

                      final slideDirection = _forwardNavigation ? 1.0 : -1.0;
                      final offset = Tween<Offset>(
                        begin: Offset(slideDirection, 0.0),
                        end: Offset.zero,
                      ).animate(animation);

                      return SlideTransition(position: offset, child: child);
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(_currentView),
                      child:
                          _currentView == 1 && _investigation != null
                              ? _buildInvestigationView()
                              : _buildDADetailsView(context, n2LocalizedName),
                    ),
                  ),
                ),
              ),

              // Fixed Action Buttons at bottom (DA view only)
              if (_currentView == 0 &&
                  (widget.request.status == 'pending' || widget.request.status == 'on_hold') &&
                  (widget.onApprove != null ||
                      widget.onDecline != null ||
                      widget.onPutOnHold != null ||
                      widget.onCancel != null ||
                      widget.onSendToHrInvestigation != null ||
                      widget.onConfirmAcknowledgment != null ||
                      widget.onAcknowledgeWithRemark != null ||
                      widget.onLegalAcknowledge != null ||
                      widget.onLegalUpload != null ||
                      widget.onEscalateToLegal != null ||
                      widget.onHRApproveFinal != null ||
                      widget.onHRDeclineFinal != null ||
                      widget.onHRSuspend != null ||
                      widget.onHRTerminate != null ||
                      widget.onConvertToInvestigation != null ||
                      _canShowEditButton))
                Row(children: [Expanded(child: _buildFixedActionButtons(context))]),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the DA details scrollable content (view 0)
  Widget _buildDADetailsView(BuildContext context, String n2LocalizedName) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Edit Section (dialog-specific, stays here)
            if (_activeSection == ActiveSectionType.edit) ...[
              Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: _buildEditSection()),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
            ],

            // Investigation Link Section (dialog-specific, stays here)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _buildInvestigationLinkSection(context),
            ),

            // Reuse the shared detail content widget
            DisciplinaryActionDetailContent(
              request: _currentRequest,
              showIncidentDescription: _canViewIncidentDescription,
              showAttachments: _canViewAttachments,
              showInvestigationDetails: _canViewInvestigationDetails,
              showLegalEscalation: _canViewLegalEscalation,
              isEmployeeView: _isEmployee,
              showDetailedUserInfo: widget.sourceType == RequestSourceType.teamRequests,
              currentApproverOverride:
                  _isEmployee && _currentRequest.currentApprover?.toLowerCase() == 'legal'
                      ? AppLocalizations.of(context)!.hrDepartment
                      : null,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the Investigation details view (view 1)
  /// Three-level visibility: employee subject → all hidden;
  /// passive observer (N+1/N+2) → employees + decisions only; normal → full.
  Widget _buildInvestigationView() {
    final hideAll = _isInvestigationSubject || (!_canViewInvestigationContent && !_isPassiveInvestigationObserver);
    final restricted = _isPassiveInvestigationObserver;
    return InvestigationDetailContent(
      investigation: _investigation!,
      showActionButtons: false,
      showIncidentDescription: !hideAll && !restricted,
      showRequestorAttachments: !hideAll && !restricted,
      showDecisionHistory: !hideAll,
      showDecisionDetails: !hideAll && !restricted,
      showLinkedDisciplinaryActions: !hideAll && !restricted,
      showEmployeesList: !hideAll,
      showCurrentApprover: !hideAll && !restricted,
    );
  }

  Widget _buildFixedActionButtons(BuildContext context) {
    // Check if any edit section is active
    final hasActiveSection = _activeSection != ActiveSectionType.none;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
      ),
      child: hasActiveSection ? _buildSectionActionButtons(context) : _buildNormalActionButtons(context),
    );
  }

  Widget _buildNormalActionButtons(BuildContext context) {
    final userCode = context.read<UserBloc>().state.user?.id ?? 0;
    final isHRfinalStage =
        widget.onHRApproveFinal != null ||
        widget.onHRDeclineFinal != null ||
        widget.onHRSuspend != null ||
        widget.onHRTerminate != null;
    return Wrap(
      runSpacing: 8,
      children: [
        // Edit button (for N+2 and HR)
        if (_canEditDeductDays || _canEditSuspensionDays) ...[
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _activeSection = ActiveSectionType.edit;
                // Clear validation errors when entering edit mode
                _deductDaysError = null;
                _suspensionDaysError = null;
              });
            },
            icon: const Icon(Icons.edit, size: 18),
            label: Text(AppLocalizations.of(context)!.edit),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], foregroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
        ],

        // Employee Acknowledgment Buttons
        if (widget.onConfirmAcknowledgment != null) ...[
          BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
            builder: (context, state) {
              final isBaseLoading =
                  state.acknowledgmentStatus == Status.loading && state.processingRequestId == widget.request.id;
              final isConfirmAcknowledging = isBaseLoading && state.acknowledgmentActionType == 'confirm';
              final isRemarkAcknowledging =
                  isBaseLoading && state.acknowledgmentActionType == 'acknowledge_with_remark';

              return ElevatedButton.icon(
                onPressed: (isConfirmAcknowledging || isRemarkAcknowledging) ? null : widget.onConfirmAcknowledgment,
                icon:
                    isConfirmAcknowledging
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                        : const Icon(Icons.check, size: 18),
                label: Text(
                  isConfirmAcknowledging
                      ? AppLocalizations.of(context)!.acknowledging
                      : AppLocalizations.of(context)!.confirm,
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white),
              );
            },
          ),
          const SizedBox(width: 8),
        ],

        if (widget.onAcknowledgeWithRemark != null) ...[
          BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
            builder: (context, state) {
              final isBaseLoading =
                  state.acknowledgmentStatus == Status.loading && state.processingRequestId == widget.request.id;
              final isConfirmAcknowledging = isBaseLoading && state.acknowledgmentActionType == 'confirm';
              final isRemarkAcknowledging =
                  isBaseLoading && state.acknowledgmentActionType == 'acknowledge_with_remark';

              return ElevatedButton.icon(
                onPressed: (isConfirmAcknowledging || isRemarkAcknowledging) ? null : widget.onAcknowledgeWithRemark,
                icon:
                    isRemarkAcknowledging
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                        : const Icon(Icons.comment, size: 18),
                label: Text(
                  isRemarkAcknowledging
                      ? AppLocalizations.of(context)!.acknowledging
                      : AppLocalizations.of(context)!.acknowledgeWithRemark,
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], foregroundColor: Colors.white),
              );
            },
          ),
          const SizedBox(width: 8),
        ],

        // Decline button
        if (widget.onDecline != null && !isHRfinalStage) ...[
          BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
            builder: (context, state) {
              final isDeclining =
                  state.declineStatus == Status.loading && state.processingRequestId == widget.request.id;

              return ElevatedButton.icon(
                onPressed: isDeclining ? null : widget.onDecline,
                icon:
                    isDeclining
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                        : const Icon(Icons.close, size: 18),
                label: Text(
                  isDeclining ? AppLocalizations.of(context)!.declining : AppLocalizations.of(context)!.decline,
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
              );
            },
          ),
          const SizedBox(width: 8),
        ],

        // Approve button
        if (widget.onApprove != null && !isHRfinalStage) ...[
          BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
            builder: (context, state) {
              final isApproving =
                  state.approveStatus == Status.loading && state.processingRequestId == widget.request.id;

              return ElevatedButton.icon(
                onPressed: isApproving ? null : widget.onApprove,
                icon:
                    isApproving
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                        : const Icon(Icons.check, size: 18),
                label: Text(
                  isApproving ? AppLocalizations.of(context)!.approving : AppLocalizations.of(context)!.approve,
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white),
              );
            },
          ),
          const SizedBox(width: 8),
        ],

        // Convert to Investigation button (HR only, for pending requests)
        if (widget.onConvertToInvestigation != null && widget.request.status == 'pending') ...[
          ElevatedButton.icon(
            onPressed: widget.onConvertToInvestigation,
            icon: const Icon(Icons.transform, size: 18),
            label: Text(AppLocalizations.of(context)!.convertToInvestigation),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[600], foregroundColor: Colors.white),
          ),
          const SizedBox(width: 8),
        ],

        // Legal Acknowledge Button
        if (widget.onLegalAcknowledge != null) ...[
          BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
            builder: (context, state) {
              final isAcknowledging =
                  state.legalAcknowledgeStatus == Status.loading && state.processingRequestId == widget.request.id;

              return ElevatedButton.icon(
                onPressed: isAcknowledging ? null : widget.onLegalAcknowledge,
                icon:
                    isAcknowledging
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                        : const Icon(Icons.check_circle_outline, size: 18),
                label: Text(
                  isAcknowledging
                      ? AppLocalizations.of(context)!.acknowledging
                      : AppLocalizations.of(context)!.acknowledge,
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[600], foregroundColor: Colors.white),
              );
            },
          ),
          const SizedBox(width: 8),
        ],

        // Legal Upload Button
        if (widget.onLegalUpload != null) ...[
          BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
            builder: (context, state) {
              final isUploading =
                  state.legalUploadStatus == Status.loading && state.processingRequestId == widget.request.id;

              return ElevatedButton.icon(
                onPressed: isUploading ? null : widget.onLegalUpload,
                icon:
                    isUploading
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                        : const Icon(Icons.upload_file, size: 18),
                label: Text(
                  isUploading
                      ? AppLocalizations.of(context)!.uploading
                      : AppLocalizations.of(context)!.uploadInvestigationPDF,
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white),
              );
            },
          ),
          const SizedBox(width: 8),
        ],

        // Escalate to Legal Button
        if (widget.onEscalateToLegal != null) ...[
          BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
            builder: (context, state) {
              final isEscalating =
                  state.escalateToLegalStatus == Status.loading && state.processingRequestId == widget.request.id;

              return ElevatedButton.icon(
                onPressed: isEscalating ? null : widget.onEscalateToLegal,
                icon:
                    isEscalating
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                        : const Icon(Icons.gavel, size: 18),
                label: Text(
                  isEscalating
                      ? AppLocalizations.of(context)!.escalatingToLegal
                      : AppLocalizations.of(context)!.escalateToLegal,
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[600], foregroundColor: Colors.white),
              );
            },
          ),
          const SizedBox(width: 8),
        ],

        // Cancel button (for user's own requests)
        if (widget.onCancel != null &&
            widget.request.employeeCode != userCode &&
            widget.request.currentApprover?.toLowerCase() == 'employee') ...[
          BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
            builder: (context, state) {
              final isCancelling =
                  state.cancelStatus == Status.loading && state.processingRequestId == widget.request.id;

              return ElevatedButton.icon(
                onPressed: isCancelling ? null : widget.onCancel,
                icon:
                    isCancelling
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                        : const Icon(Icons.cancel, size: 18),
                label: Text(
                  isCancelling ? AppLocalizations.of(context)!.cancelling : AppLocalizations.of(context)!.cancelRequest,
                ),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildSectionActionButtons(BuildContext context) {
    return Row(
      children: [
        // Cancel button
        TextButton.icon(
          onPressed: () {
            setState(() {
              _activeSection = ActiveSectionType.none;
              // Reset form controllers and validation errors
              _selectedDeductDays = _currentRequest.writtenWarningOptions?.deductDays;
              _suspensionDaysController.text = _currentRequest.suspensionDays.toString();
              _deductDaysError = null;
              _suspensionDaysError = null;
            });
          },
          icon: const Icon(Icons.close, size: 18),
          label: Text(AppLocalizations.of(context)!.cancel),
          style: TextButton.styleFrom(foregroundColor: Colors.black),
        ),
        const SizedBox(width: 12),
        // Save button
        BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
          builder: (context, state) {
            final isSaving = state.editStatus == Status.loading && state.processingRequestId == widget.request.id;

            return SizedBox(
              width: 120,
              child: ElevatedButton.icon(
                onPressed: (isSaving || !_canSave) ? null : () => _saveWrittenWarningOptions(context),
                icon:
                    isSaving
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                        : const Icon(Icons.save, size: 18),
                label: Text(isSaving ? AppLocalizations.of(context)!.saving : AppLocalizations.of(context)!.save),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white),
              ),
            );
          },
        ),
      ],
    );
  }

  void _validateSuspensionDays(String value) {
    setState(() {
      if (value.isEmpty) {
        _suspensionDaysError = null; // Allow empty for optional field
      } else {
        final days = int.tryParse(value);
        if (days == null || days < 1 || days > 7) {
          _suspensionDaysError = AppLocalizations.of(context)!.suspensionDaysRange;
        } else {
          _suspensionDaysError = null;
        }
      }
    });
  }

  bool get _canSave {
    return _deductDaysError == null && _suspensionDaysError == null;
  }

  void _saveWrittenWarningOptions(BuildContext context) {
    // Validate before saving
    _validateSuspensionDays(_suspensionDaysController.text);

    if (!_canSave) {
      return; // Don't save if there are validation errors
    }

    final currentOptions = widget.request.writtenWarningOptions;
    final newDeductDays = _selectedDeductDays ?? currentOptions?.deductDays;
    final newSuspensionDays = int.tryParse(_suspensionDaysController.text) ?? currentOptions?.suspensionDays;

    final updatedOptions = WrittenWarningOptions(deductDays: newDeductDays, suspensionDays: newSuspensionDays);

    // Get user information for change log
    final userBloc = context.read<UserBloc>();
    final user = userBloc.state.user;
    final userEnglishName = user?.englishName ?? 'Unknown User';
    final userArabicName = user?.arabicName ?? 'مستخدم غير معروف';

    context.read<UserDisciplinaryActionRequestsBloc>().add(
      EditWrittenWarningOptionsDisciplinaryActionRequest(
        widget.request.id!,
        updatedOptions,
        currentOptions ?? WrittenWarningOptions(),
        userEnglishName,
        userArabicName,
      ),
    );
  }
}
