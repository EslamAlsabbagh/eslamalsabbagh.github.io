import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/constants/approver_codes.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/request_month_utils.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_requests_query.dart';
import 'package:hrms_demo/presentation/widgets/paged_requests_pagination_controls.dart';
import 'package:hrms_demo/presentation/widgets/request_filters_mixin.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/services/pdf/pdf_generation_service.dart';
import 'package:hrms_demo/services/pdf/advance_pdf_storage_service.dart';
import 'package:hrms_demo/services/advance_request/advance_request_workflow_service.dart';
import 'package:printing/printing.dart';
import 'package:hrms_demo/services/pdf/web_pdf_download.dart'
    if (dart.library.html) 'package:hrms_demo/services/pdf/web_pdf_download_web.dart'
    if (dart.library.io) 'package:hrms_demo/services/pdf/web_pdf_download_io.dart';
import 'package:hrms_demo/data/models/advance_on_salary_request_model.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/user_advance_on_salary_requests/bloc/user_advance_on_salary_requests_bloc.dart';
import 'package:hrms_demo/presentation/user_advance_on_salary_requests/bloc/user_advance_on_salary_requests_state.dart';
import 'package:hrms_demo/presentation/user_advance_on_salary_requests/bloc/user_advance_on_salary_requests_event.dart';
import 'package:hrms_demo/presentation/widgets/custom_date_picker.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

enum ActiveSectionType { editPeriod, unscheduledPayment }

class UserAdvanceOnSalaryRequestsContent extends StatefulWidget {
  final RequestSourceType? sourceType;
  const UserAdvanceOnSalaryRequestsContent({super.key, this.sourceType});

  @override
  State<UserAdvanceOnSalaryRequestsContent> createState() => _UserAdvanceOnSalaryRequestsContentState();
}

class _UserAdvanceOnSalaryRequestsContentState extends State<UserAdvanceOnSalaryRequestsContent>
    with RequestFiltersMixin<UserAdvanceOnSalaryRequestsContent> {
  // Workflow service for PDF generation
  late final AdvanceRequestWorkflowService _workflowService;

  /// LEGACY page index. On the paged path the window lives in the bloc's
  /// `PagedSection`, because only the server knows how many pages there are.
  int _currentPage = 0;

  /// Page size. Shared by both paths — the paged one forwards it to the bloc.
  int _itemsPerPage = 10;

  // Sorting
  String _sortBy = 'createdAt';
  bool _sortAscending = false;

  /// Which of the four team tabs is selected.
  ///
  /// One field rather than three booleans, because they were never independent.
  /// Note this is NOT [RequestFiltersMixin.showProcessedRequests]: that is a
  /// two-state toggle, and this screen has four tabs. The mixin is used here for
  /// its debounced search and its filter reset, not for its tab state.
  String _activeTab = 'actionable';

  bool get _showProcessedRequests => _activeTab == 'processed';
  bool get _showUnsettledRequests => _activeTab == 'unsettled';
  bool get _showSettledRequests => _activeTab == 'settled';

  @override
  void initState() {
    super.initState();
    _initializeWorkflowService();
  }

  void _initializeWorkflowService() {
    _workflowService = context.read<AdvanceRequestWorkflowService>();
  }

  // ── Server-paged query plumbing ────────────────────────────────────────────

  /// The tab the user is on, as the server understands it.
  AdvanceRequestScope get _effectiveScope {
    if (widget.sourceType != RequestSourceType.teamRequests) {
      return (widget.sourceType ?? RequestSourceType.myRequests).scope;
    }
    return switch (_activeTab) {
      'processed' => AdvanceRequestScope.processed,
      'unsettled' => AdvanceRequestScope.unsettled,
      'settled' => AdvanceRequestScope.settled,
      _ => AdvanceRequestScope.team,
    };
  }

  AdvanceRequestSortKey get _serverSortKey => switch (_sortBy) {
    'amount' => AdvanceRequestSortKey.amount,
    'status' => AdvanceRequestSortKey.status,
    'period' => AdvanceRequestSortKey.period,
    _ => AdvanceRequestSortKey.createdAt,
  };

  /// The sort controls are the single source of truth for ordering — no tab
  /// seeds a different one, so `_sortBy`/`_sortAscending` map straight through.
  /// Their defaults ('createdAt', descending) are what every tab has always
  /// displayed.
  AdvanceRequestsQuery _buildQuery() => AdvanceRequestsQuery(
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
    if (!FeatureFlags.serverPagedAdvanceRequests) return;
    context.read<UserAdvanceOnSalaryRequestsBloc>().add(AdvanceQueryChanged(_buildQuery()));
  }

  /// Fires after every filter change made through [RequestFiltersMixin] —
  /// debounced for search, immediate for the discrete filters.
  @override
  void onFiltersChanged() => _applyQuery();

  // ── Legacy client-side filtering (flag off) ────────────────────────────────

  List<AdvanceOnSalaryRequestModel> get _filteredAndSortedRequests {
    List<AdvanceOnSalaryRequestModel> filtered = List.from(
      context.read<UserAdvanceOnSalaryRequestsBloc>().state.requests,
    );

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((request) => _matchesSearchQuery(request, searchQuery)).toList();
    }

    // Apply status filter
    if (statusFilter != 'all') {
      if (statusFilter == 'cancelled') {
        // Special handling for cancelled status
        filtered = filtered.where((request) => request.isCancelled || request.isEmployeeCancelled).toList();
      } else if (statusFilter == 'pending_employee_confirmation') {
        // Special handling for pending employee confirmation status
        filtered = filtered.where((request) => request.needsEmployeeConfirmation && !request.isCancelled).toList();
      } else {
        // Regular status filtering for non-cancelled statuses
        filtered = filtered.where((request) => request.status == statusFilter && !request.isCancelled).toList();
      }
    }

    // Apply month filter
    if (selectedMonth != null) {
      filtered =
          filtered.where((request) {
            return request.createdAt != null &&
                request.createdAt!.year == selectedMonth!.year &&
                request.createdAt!.month == selectedMonth!.month;
          }).toList();
    }

    // Apply tab-specific filtering for actionable vs processed requests
    if (!_showProcessedRequests &&
        !_showUnsettledRequests &&
        !_showSettledRequests &&
        widget.sourceType == RequestSourceType.teamRequests) {
      // Actionable tab: show only pending and not cancelled requests or requests that need finance confirmation (if finance user)
      filtered =
          filtered
              .where((request) => request.isActionable || (request.needsFinanceAcknowledgment && _isFinanceUser))
              .toList();
    } else if (_showProcessedRequests) {
      // Processed tab: show approved, declined, or cancelled requests
      //filtered = filtered.where((request) => request.isProcessed).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      // If there's a search query, prioritize by match relevance first
      if (searchQuery.isNotEmpty) {
        double scoreA = _getMatchScore(a, searchQuery);
        double scoreB = _getMatchScore(b, searchQuery);

        // If match scores are different, prioritize higher scores
        if (scoreA != scoreB) {
          return scoreB.compareTo(scoreA); // Higher scores first
        }
      }

      // Apply regular sorting
      int result = 0;
      switch (_sortBy) {
        case 'createdAt':
          result = (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());
          break;
        case 'amount':
          result = (a.amount ?? 0).compareTo(b.amount ?? 0);
          break;
        case 'status':
          result = (a.status ?? '').compareTo(b.status ?? '');
          break;
        case 'period':
          result = (a.effectivePeriodInMonths ?? 0).compareTo(b.effectivePeriodInMonths ?? 0);
          break;
        default:
          result = (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());
      }
      return _sortAscending ? result : -result;
    });

    return filtered;
  }

  bool _matchesSearchQuery(AdvanceOnSalaryRequestModel request, String query) {
    if (query.isEmpty) return true;

    final searchTerms = query.toLowerCase().trim().split(RegExp(r'\s+'));

    // Get all searchable text fields - same as scoring system
    final searchableFields = [
      //request.requestorCode.toString(),
      ((request.borrowerCode ?? 0) - 10000000).toString(),
      request.getAmountInLetters(context).toLowerCase(),
      request.amount?.toString() ?? '',
      request.borrowerEnglishName?.toLowerCase() ?? '',
      request.borrowerArabicName?.toLowerCase() ?? '',
      //request.requestorEnglishName?.toLowerCase() ?? '',
      //request.requestorArabicName?.toLowerCase() ?? '',
    ];

    // Check if all search terms are found in any of the fields
    for (String term in searchTerms) {
      bool termFound = false;

      for (String field in searchableFields) {
        if (_fieldContainsTerm(field, term)) {
          termFound = true;
          break;
        }
      }

      // If any term is not found, the record doesn't match
      if (!termFound) {
        return false;
      }
    }

    return true;
  }

  double _getMatchScore(AdvanceOnSalaryRequestModel request, String query) {
    if (query.isEmpty) return 0.0;

    final searchTerms = query.toLowerCase().trim().split(RegExp(r'\s+'));
    double totalScore = 0.0;

    // Define field weights (name fields get higher priority)
    final fieldWeights = {
      //'requestorCode': 3.5,
      'borrowerCode': 3.5,
      'borrowerEnglishName': 3.0,
      //'requestorEnglishName': 3.0,
      'borrowerArabicName': 2.5,
      //'requestorArabicName': 2.5,
      'amount': 1.5,
      'amountInLetters': 1.0,
    };

    final searchableFields = {
      //'requestorCode': request.requestorCode.toString(),
      'borrowerCode': ((request.borrowerCode ?? 0) - 10000000).toString(),
      'borrowerEnglishName': request.borrowerEnglishName?.toLowerCase() ?? '',
      //'requestorEnglishName': request.requestorEnglishName?.toLowerCase() ?? '',
      'borrowerArabicName': request.borrowerArabicName?.toLowerCase() ?? '',
      //'requestorArabicName': request.requestorArabicName?.toLowerCase() ?? '',
      'amount': request.amount?.toString() ?? '',
      'amountInLetters': request.getAmountInLetters(context).toLowerCase(),
    };

    for (String term in searchTerms) {
      double termScore = 0.0;

      for (String fieldName in searchableFields.keys) {
        String field = searchableFields[fieldName]!;
        double weight = fieldWeights[fieldName]!;

        if (field.isEmpty || term.isEmpty) continue;

        double fieldScore = 0.0;

        // Exact match gets highest score
        if (field == term) {
          fieldScore = 1.0;
        }
        // Direct substring match
        else if (field.contains(term)) {
          // Higher score if term appears at the beginning
          if (field.startsWith(term)) {
            fieldScore = 0.9;
          } else {
            fieldScore = 0.7;
          }
        }
        // Word boundary matching
        else {
          final words = field.split(RegExp(r'\s+'));
          double wordScore = 0.0;

          for (String word in words) {
            if (word == term) {
              wordScore = 0.9;
              break;
            } else if (word.startsWith(term)) {
              wordScore = 0.8;
            } else if (term.length >= 3 && word.length >= 3) {
              double similarity = _calculateSimilarity(word, term);
              if (similarity > 0.7) {
                wordScore = similarity * 0.6;
              }
            }
          }
          fieldScore = wordScore;
        }

        // Apply weight and add to term score
        termScore += fieldScore * weight;
      }

      totalScore += termScore;
    }

    // Normalize by number of search terms
    return totalScore / searchTerms.length;
  }

  bool _fieldContainsTerm(String field, String term) {
    if (field.isEmpty || term.isEmpty) return false;

    // Direct substring match
    if (field.contains(term)) {
      return true;
    }

    // Word boundary matching - check if any word in the field starts with the search term
    final words = field.split(RegExp(r'\s+'));
    for (String word in words) {
      if (word.startsWith(term)) {
        return true;
      }
    }

    // Fuzzy matching for names (allowing for small differences)
    if (term.length >= 3) {
      final words = field.split(RegExp(r'\s+'));
      for (String word in words) {
        if (word.length >= 3 && _calculateSimilarity(word, term) > 0.7) {
          return true;
        }
      }
    }

    return false;
  }

  double _calculateSimilarity(String str1, String str2) {
    if (str1 == str2) return 1.0;
    if (str1.isEmpty || str2.isEmpty) return 0.0;

    final len1 = str1.length;
    final len2 = str2.length;
    final maxLen = len1 > len2 ? len1 : len2;

    // Simple Levenshtein-based similarity
    final distance = _levenshteinDistance(str1, str2);
    return (maxLen - distance) / maxLen;
  }

  int _levenshteinDistance(String str1, String str2) {
    if (str1 == str2) return 0;
    if (str1.isEmpty) return str2.length;
    if (str2.isEmpty) return str1.length;

    final len1 = str1.length + 1;
    final len2 = str2.length + 1;

    List<List<int>> matrix = List.generate(len1, (_) => List.filled(len2, 0));

    for (int i = 0; i < len1; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j < len2; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i < len1; i++) {
      for (int j = 1; j < len2; j++) {
        final cost = str1[i - 1] == str2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[len1 - 1][len2 - 1];
  }

  List<AdvanceOnSalaryRequestModel> get _paginatedRequests {
    final filtered = _filteredAndSortedRequests;
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filtered.length);

    if (startIndex >= filtered.length) return [];
    return filtered.sublist(startIndex, endIndex);
  }

  int get _totalPages {
    final filtered = _filteredAndSortedRequests;
    return (filtered.length / _itemsPerPage).ceil();
  }

  bool get _isFinanceUser {
    final userCode = context.read<UserBloc>().state.user?.id;
    return userCode != null && ApproverCodes.financeCodes.map(int.parse).contains(userCode);
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: BlocListener<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
        listener: (context, state) {
          // Handle approve operation feedback
          if (state.approveStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestApprovedSuccessfully)));
            // Reset approve status
            context.read<UserAdvanceOnSalaryRequestsBloc>().add(const ResetApproveStatus());
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
            context.read<UserAdvanceOnSalaryRequestsBloc>().add(const ResetApproveStatus());
          }

          // Handle decline operation feedback
          if (state.declineStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestDeclinedSuccessfully)));
            // Reset decline status
            context.read<UserAdvanceOnSalaryRequestsBloc>().add(const ResetDeclineStatus());
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
            context.read<UserAdvanceOnSalaryRequestsBloc>().add(const ResetDeclineStatus());
          }

          // Handle settle operation feedback
          if (state.settleStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestSettledSuccessfully)));
            // Reset settle status
            context.read<UserAdvanceOnSalaryRequestsBloc>().add(const ResetSettleStatus());
          } else if (state.settleStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.failedToSettleRequest(
                    state.operationFailure?.message ?? AppLocalizations.of(context)!.unknownError,
                  ),
                ),
              ),
            );
            // Reset settle status
            context.read<UserAdvanceOnSalaryRequestsBloc>().add(const ResetSettleStatus());
          }

          // Handle cancel operation feedback
          if (state.cancelStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestCancelledSuccessfully)));
            // Reset cancel status
            context.read<UserAdvanceOnSalaryRequestsBloc>().add(const ResetCancelStatus());
          } else if (state.cancelStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to cancel request: ${state.operationFailure?.message ?? AppLocalizations.of(context)!.unknownError}',
                ),
              ),
            );
            // Reset cancel status
            context.read<UserAdvanceOnSalaryRequestsBloc>().add(const ResetCancelStatus());
          }

          // Handle employee confirmation operation feedback
          if (state.employeeConfirmationStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.changesConfirmedSuccessfully)));
            // Reset employee confirmation status
            context.read<UserAdvanceOnSalaryRequestsBloc>().add(const ResetEmployeeConfirmationStatus());
          } else if (state.employeeConfirmationStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.failedToConfirmChanges(
                    state.operationFailure?.message ?? AppLocalizations.of(context)!.unknownError,
                  ),
                ),
              ),
            );
            // Reset employee confirmation status
            context.read<UserAdvanceOnSalaryRequestsBloc>().add(const ResetEmployeeConfirmationStatus());
          }

          // Handle finance acknowledgment operation feedback
          if (state.financeAcknowledgmentStatus == Status.success) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.decisionAcknowledgedSuccessfully)));
            // Reset finance acknowledgment status
            context.read<UserAdvanceOnSalaryRequestsBloc>().add(const ResetFinanceAcknowledgmentStatus());
          } else if (state.financeAcknowledgmentStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  AppLocalizations.of(context)!.failedToAcknowledgeDecision(
                    state.operationFailure?.message ?? AppLocalizations.of(context)!.unknownError,
                  ),
                ),
              ),
            );
            // Reset finance acknowledgment status
            context.read<UserAdvanceOnSalaryRequestsBloc>().add(const ResetFinanceAcknowledgmentStatus());
          }
        },
        child: BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
          builder: (context, state) {
            // On the paged path the months come from the server: deriving them
            // from the rows in memory would offer only the months that happen to
            // appear on the current page.
            final availableMonths =
                FeatureFlags.serverPagedAdvanceRequests
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
                          if (FeatureFlags.serverPagedAdvanceRequests) ...[
                            if (state.paged.totalPages > 1) ...[
                              const SizedBox(height: 16),
                              PagedRequestsPaginationControls(
                                page: state.paged.page,
                                totalCount: state.paged.totalCount,
                                pageSize: state.paged.pageSize,
                                isLoading: state.paged.isPageLoading,
                                onPageChanged:
                                    (page) =>
                                        context.read<UserAdvanceOnSalaryRequestsBloc>().add(AdvancePageChanged(page)),
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
    final title =
        widget.sourceType == RequestSourceType.myRequests
            ? AppLocalizations.of(context)!.myAdvanceOnSalaryRequests
            : AppLocalizations.of(context)!.teamAdvanceOnSalaryRequests;

    return Row(
      children: [
        Icon(Icons.account_balance_wallet_outlined, color: Theme.of(context).primaryColor, size: 28),
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
                        value: 'processed',
                        label: Text(AppLocalizations.of(context)!.processed),
                        icon: Icon(Icons.check_circle_outline),
                      ),
                      if (_isFinanceUser)
                        ButtonSegment<String>(
                          value: 'unsettled',
                          label: Text(AppLocalizations.of(context)!.unsettled),
                          icon: Icon(Icons.account_balance_wallet_outlined),
                        ),
                      if (_isFinanceUser)
                        ButtonSegment<String>(
                          value: 'settled',
                          label: Text(AppLocalizations.of(context)!.settled),
                          icon: Icon(Icons.check_circle),
                        ),
                    ],
                    selected: {
                      _showSettledRequests
                          ? 'settled'
                          : _showUnsettledRequests
                          ? 'unsettled'
                          : _showProcessedRequests
                          ? 'processed'
                          : 'actionable',
                    },
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
                      hintText: AppLocalizations.of(context)!.searchByNameCodeOrAmount,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Status Filter
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: statusFilter,
                    onChanged: (value) {
                      _currentPage = 0;
                      updateStatusFilter(value ?? 'all');
                    },
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: [
                      DropdownMenuItem(value: 'all', child: Text(AppLocalizations.of(context)!.allStatus)),
                      DropdownMenuItem(value: 'pending', child: Text(AppLocalizations.of(context)!.pending)),
                      DropdownMenuItem(value: 'approved', child: Text(AppLocalizations.of(context)!.approved)),
                      DropdownMenuItem(value: 'declined', child: Text(AppLocalizations.of(context)!.declined)),
                      DropdownMenuItem(value: 'cancelled', child: Text(AppLocalizations.of(context)!.cancelled)),
                      DropdownMenuItem(
                        value: 'pending_employee_confirmation',
                        child: Text(AppLocalizations.of(context)!.pendingEmployeeConfirmation),
                      ),
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
                      if (FeatureFlags.serverPagedAdvanceRequests) {
                        context.read<UserAdvanceOnSalaryRequestsBloc>().add(AdvancePageSizeChanged(_itemsPerPage));
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
                        DropdownMenuItem(value: 'amount', child: Text(AppLocalizations.of(context)!.amount)),
                        DropdownMenuItem(value: 'status', child: Text(AppLocalizations.of(context)!.status)),
                        DropdownMenuItem(value: 'period', child: Text(AppLocalizations.of(context)!.period)),
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

  Widget _buildRequestsList(BuildContext context, UserAdvanceOnSalaryRequestsState state) {
    if (FeatureFlags.serverPagedAdvanceRequests) return _buildPagedRequestsList(context, state);

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
                  context.read<UserAdvanceOnSalaryRequestsBloc>().add(
                    LoadUserAdvanceOnSalaryRequests(userCode, widget.sourceType ?? RequestSourceType.myRequests),
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
        ...paginatedRequests.map((request) => _buildRequestCard(context, request)),
      ],
    );
  }

  /// The server-paged list.
  ///
  /// Note what is NOT here: a full-height spinner while a page is in flight. The
  /// cards of the previous page stay on screen and only the paginator is
  /// disabled, so the list does not collapse and reflow on every page turn — and
  /// the card whose mutation triggered the refresh keeps its own spinner.
  Widget _buildPagedRequestsList(BuildContext context, UserAdvanceOnSalaryRequestsState state) {
    final l10n = AppLocalizations.of(context)!;
    final paged = state.paged;

    // The scope-wide reads failed (not a page fetch), so there is nothing
    // trustworthy to render.
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
        ...paged.items.map((request) => _buildRequestCard(context, request)),
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
              onPressed: () => context.read<UserAdvanceOnSalaryRequestsBloc>().add(const RefreshAdvancePage()),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, AdvanceOnSalaryRequestModel request) {
    final userCode = context.read<UserBloc>().state.user?.id ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: InkWell(
        onTap: () => _showRequestDetails(context, request),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // requestor name and code
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 360),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.requestor,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getDisplayName(context, request.requestorEnglishName, request.requestorArabicName)} (${request.requestorCode})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),
                  // borrower name and code
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.borrower,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getDisplayName(context, request.borrowerEnglishName, request.borrowerArabicName)} (${request.borrowerCode})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  Spacer(),
                  // Status Badge
                  if (!request.needsEmployeeConfirmation)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getRequestStatusColor(request).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _getRequestStatusColor(request)),
                      ),
                      child: Text(
                        request.getLocalizedStatus(context),
                        style: TextStyle(
                          color: _getRequestStatusColor(request),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  if (request.needsEmployeeConfirmation) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.pendingEmployeeConfirmation,
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
              Divider(),
              // Main Content Row
              Row(
                children: [
                  // Amount Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.amountRequested,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${request.amount ?? 0} ${Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP'}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),

                  // created at section
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
                          request.createdAt != null ? DateFormat('MMM dd, yyyy').format(request.createdAt!) : 'N/A',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // Period Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.period,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${request.effectivePeriodInMonths ?? 0} ${AppLocalizations.of(context)!.months}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // Monthly Payment Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.monthlyPaymentLabel,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${NumberFormat('#,##0.00').format(request.currentMonthlyPayment ?? 0)} ${Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP'}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),

                  // Payment Start Date Section
                  if (request.paymentStartDate != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.paymentStartDateLabel,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(request.paymentStartDate!),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                  // Payment End Date Section
                  if (request.effectivePaymentEndDate != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.paymentEndDateLabel,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(request.effectivePaymentEndDate!),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                  // current approver section
                  if (request.status == 'pending')
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.currentApprover,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            request.getLocalizedApproverName(context),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),

                  // Action buttons for team requests (only show for actionable requests)
                  if (widget.sourceType == RequestSourceType.teamRequests &&
                      !_showProcessedRequests &&
                      !_showUnsettledRequests &&
                      !_showSettledRequests &&
                      request.status == 'pending') ...[
                    BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
                      builder: (context, state) {
                        final isApproving =
                            state.approveStatus == Status.loading && state.processingRequestId == request.id;
                        final isDeclining =
                            state.declineStatus == Status.loading && state.processingRequestId == request.id;
                        final isProcessing = isApproving || isDeclining;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: isProcessing ? null : () => _showDeclineDialog(context, request),
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
                                      : const Icon(Icons.close, size: 16),
                              label: Text(
                                isDeclining
                                    ? AppLocalizations.of(context)!.declining
                                    : AppLocalizations.of(context)!.decline,
                              ),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.red[600],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: isProcessing ? null : () => _showApprovalConfirmation(context, request),
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
                                      : const Icon(Icons.check, size: 16),
                              label: Text(
                                isApproving
                                    ? AppLocalizations.of(context)!.approving
                                    : AppLocalizations.of(context)!.approve,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],

                  // Settlement button for unsettled requests
                  if (widget.sourceType == RequestSourceType.teamRequests &&
                      _showUnsettledRequests &&
                      request.status == 'approved' &&
                      request.borrowerCode != userCode &&
                      request.requestorCode != userCode) ...[
                    BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
                      builder: (context, state) {
                        final isSettling =
                            state.settleStatus == Status.loading && state.processingRequestId == request.id;

                        return ElevatedButton.icon(
                          onPressed: isSettling ? null : () => _showRequestDetails(context, request),
                          icon:
                              isSettling
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                  : const Icon(Icons.payment, size: 16),
                          label: Text(
                            isSettling ? AppLocalizations.of(context)!.settling : AppLocalizations.of(context)!.settle,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[600],
                            foregroundColor: Colors.white,
                          ),
                        );
                      },
                    ),
                  ],

                  // Cancel button for user's own requests (only show for actionable requests)
                  if (widget.sourceType == RequestSourceType.myRequests &&
                      !_showProcessedRequests &&
                      !_showUnsettledRequests &&
                      !_showSettledRequests &&
                      request.isActionable &&
                      userCode != request.borrowerCode &&
                      request.currentApprover?.toLowerCase() == 'n2') ...[
                    BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
                      builder: (context, state) {
                        final isCancelling =
                            state.cancelStatus == Status.loading && state.processingRequestId == request.id;

                        return ElevatedButton.icon(
                          onPressed: isCancelling ? null : () => _showCancelConfirmationDialog(context, request),
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
                        );
                      },
                    ),
                  ],

                  // Employee confirmation buttons (for borrower when finance has made changes)
                  if (request.needsEmployeeConfirmation && request.borrowerCode == userCode) ...[
                    BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
                      builder: (context, state) {
                        final isConfirming =
                            state.employeeConfirmationStatus == Status.loading &&
                            state.processingRequestId == request.id;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Confirm button
                            ElevatedButton.icon(
                              onPressed:
                                  isConfirming ? null : () => _showEmployeeConfirmationDialog(context, false, request),
                              icon:
                                  isConfirming
                                      ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                      : const Icon(Icons.check, size: 16),
                              label: Text(
                                isConfirming
                                    ? AppLocalizations.of(context)!.confirmingChanges
                                    : AppLocalizations.of(context)!.confirmFinanceEdit,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[600],
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Cancel button
                            ElevatedButton.icon(
                              onPressed:
                                  isConfirming ? null : () => _showEmployeeCancelConfirmationDialog(context, request),
                              icon: const Icon(Icons.close, size: 16),
                              label: Text(AppLocalizations.of(context)!.cancelFinanceEdit),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[600],
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],

                  // Finance acknowledgment button (for finance when employee has responded)
                  if (request.needsFinanceAcknowledgment && _isFinanceUser) ...[
                    BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
                      builder: (context, state) {
                        final isAcknowledging =
                            state.financeAcknowledgmentStatus == Status.loading &&
                            state.processingRequestId == request.id;

                        return ElevatedButton.icon(
                          onPressed: isAcknowledging ? null : () => _acknowledgeEmployeeDecision(context, request),
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
                                  : const Icon(Icons.thumb_up, size: 16),
                          label: Text(
                            isAcknowledging
                                ? AppLocalizations.of(context)!.acknowledgingDecision
                                : AppLocalizations.of(context)!.acknowledgeEmployeeDecision,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
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

  void _showCancelConfirmationDialog(BuildContext context, AdvanceOnSalaryRequestModel request) {
    // Capture the bloc reference before showing the dialog
    final bloc = context.read<UserAdvanceOnSalaryRequestsBloc>();

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
                bloc.add(CancelAdvanceOnSalaryRequest(request.id!));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
              child: Text(AppLocalizations.of(dialogContext)!.cancelRequest),
            ),
          ],
        );
      },
    );
  }

  void _showCancelConfirmationFromDetails(BuildContext context, AdvanceOnSalaryRequestModel request) {
    // Capture the bloc reference before showing the dialog
    final bloc = context.read<UserAdvanceOnSalaryRequestsBloc>();

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
                bloc.add(CancelAdvanceOnSalaryRequest(request.id!));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[600], foregroundColor: Colors.white),
              child: Text(AppLocalizations.of(dialogContext)!.cancelRequest),
            ),
          ],
        );
      },
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

  /// Loads the tab the user is on from scratch — scope facts and first page.
  void _refreshRequests() {
    final userCode = context.read<UserBloc>().state.user?.id ?? 0;
    final bloc = context.read<UserAdvanceOnSalaryRequestsBloc>();

    if (FeatureFlags.serverPagedAdvanceRequests) {
      // One expression instead of the three-branch source-type reconstruction
      // below: the scope already knows which tab is active.
      bloc.add(InitAdvanceRequests(userCode, _effectiveScope));
      return;
    }

    if (_showUnsettledRequests && widget.sourceType == RequestSourceType.teamRequests) {
      bloc.add(LoadUserAdvanceOnSalaryRequests(userCode, RequestSourceType.unsettledRequests));
    } else if (_showSettledRequests && widget.sourceType == RequestSourceType.teamRequests) {
      bloc.add(LoadUserAdvanceOnSalaryRequests(userCode, RequestSourceType.settledRequests));
    } else {
      final sourceType =
          _showProcessedRequests && widget.sourceType == RequestSourceType.teamRequests
              ? RequestSourceType.processedRequests
              : widget.sourceType ?? RequestSourceType.myRequests;

      bloc.add(LoadUserAdvanceOnSalaryRequests(userCode, sourceType));
    }
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getRequestStatusColor(AdvanceOnSalaryRequestModel request) {
    // Check if cancelled first, as this overrides the status field
    if (request.isCancelled) {
      return Colors.grey[600]!;
    }

    return _getStatusColor(request.status);
  }

  String _getDisplayName(BuildContext context, String? englishName, String? arabicName) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? (arabicName ?? englishName ?? '') : (englishName ?? arabicName ?? '');
  }

  void _showRequestDetails(BuildContext context, AdvanceOnSalaryRequestModel request) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<UserAdvanceOnSalaryRequestsBloc>(),
            child: _RequestDetailsDialog(
              request: request,
              sourceType: widget.sourceType,
              onApprove:
                  widget.sourceType == RequestSourceType.teamRequests &&
                          !_showProcessedRequests &&
                          !_showUnsettledRequests &&
                          !_showSettledRequests &&
                          request.status == 'pending'
                      ? () => _approveRequest(context, request)
                      : null,
              onDecline:
                  widget.sourceType == RequestSourceType.teamRequests &&
                          !_showProcessedRequests &&
                          !_showUnsettledRequests &&
                          !_showSettledRequests &&
                          request.status == 'pending'
                      ? () => _showDeclineDialog(context, request, fromDetails: true)
                      : null,
              onSettle:
                  widget.sourceType == RequestSourceType.teamRequests &&
                          _showUnsettledRequests &&
                          request.status == 'approved'
                      ? () => _settleRequest(context, request)
                      : null,
              onCancel:
                  widget.sourceType == RequestSourceType.myRequests &&
                          !_showProcessedRequests &&
                          !_showUnsettledRequests &&
                          !_showSettledRequests &&
                          request.isActionable
                      ? () => _showCancelConfirmationFromDetails(context, request)
                      : null,
            ),
          ),
    );
  }

  void _showApprovalConfirmation(BuildContext context, AdvanceOnSalaryRequestModel request) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<UserAdvanceOnSalaryRequestsBloc>(),
            child: _RequestDetailsDialog(
              request: request,
              sourceType: widget.sourceType,
              isApprovalConfirmation: true,
              onApprove: () => _approveRequest(context, request),
              onDecline: null, // No decline button in confirmation
            ),
          ),
    );
  }

  Future<void> _approveRequest(BuildContext context, AdvanceOnSalaryRequestModel request) async {
    final userCode = context.read<UserBloc>().state.user?.id ?? 0;
    final currentApprover = request.currentApprover ?? 'hr';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Text(isArabic ? 'جاري الموافقة...' : 'Approving request...'),
                ],
              ),
            ),
      );

      // Check if this is a finance approval (final approval that needs PDF generation)
      if (currentApprover == 'finance') {
        // Use the workflow service for finance approval with PDF generation
        await _workflowService.financeApproveWithPDFWorkflow(
          request.id!,
          userCode,
          Localizations.localeOf(context).languageCode, // You can make this dynamic based on user locale
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'تمت الموافقة على الطلب بنجاح! وإنشاء ملف ال PDF وتم إرسال رسائل البريد الإلكتروني.'
                    : 'Request approved successfully! PDF generated and emails sent.',
              ),
            ),
          );
        }
      } else {
        // For non-finance approvals, use the existing bloc logic
        context.read<UserAdvanceOnSalaryRequestsBloc>().add(
          ApproveAdvanceOnSalaryRequest(request.id!, currentApprover, userCode),
        );

        if (mounted) {
          Navigator.of(context).pop(); // Close loading dialog
        }
      }

      // Refresh the requests list
      if (mounted && request.currentApprover == 'finance') {
        final bloc = context.read<UserAdvanceOnSalaryRequestsBloc>();
        if (FeatureFlags.serverPagedAdvanceRequests) {
          // The approve handler already refreshed the current page; this second
          // pass exists because the finance branch also regenerates the PDF.
          // Re-reading the page keeps the user where they are — re-dispatching
          // the load event would send them back to the Actionable tab, page 1.
          bloc.add(const RefreshAdvancePage());
        } else {
          bloc.add(LoadUserAdvanceOnSalaryRequests(context.read<UserBloc>().state.user?.id ?? 0, widget.sourceType!));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error approving request: $e')));
      }
    }
  }

  void _showDeclineDialog(BuildContext context, AdvanceOnSalaryRequestModel request, {bool fromDetails = false}) {
    final formKey = GlobalKey<FormState>();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: context.read<UserAdvanceOnSalaryRequestsBloc>(),
            child: Builder(
              builder: (childContext) {
                void onFieldSubmitted() {
                  if (formKey.currentState!.validate()) {
                    final reason = reasonController.text.trim();
                    context.read<UserAdvanceOnSalaryRequestsBloc>().add(
                      DeclineAdvanceOnSalaryRequest(
                        request.id!,
                        request.currentApprover ?? 'hr',
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

                return AlertDialog(
                  title: Text(AppLocalizations.of(context)!.declineRequest),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(AppLocalizations.of(context)!.provideDeclinereason),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: reasonController,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(context)!.pleaseEnterDeclineReason;
                            }
                            return null;
                          },
                          onFieldSubmitted: (_) => onFieldSubmitted(),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.enterDeclineReason,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(childContext).pop(),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      child: Text(AppLocalizations.of(context)!.cancel),
                    ),
                    ElevatedButton(
                      onPressed: onFieldSubmitted,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      child: Text(AppLocalizations.of(context)!.decline),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  void _settleRequest(BuildContext context, AdvanceOnSalaryRequestModel request) {
    final user = context.read<UserBloc>().state.user;
    context.read<UserAdvanceOnSalaryRequestsBloc>().add(
      SettleAdvanceOnSalaryRequest(request.id!, user?.arabicName ?? '', user?.englishName ?? '', user?.id ?? 0),
    );
  }
}

class _RequestDetailsDialog extends StatefulWidget {
  final AdvanceOnSalaryRequestModel request;
  final RequestSourceType? sourceType;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;
  final VoidCallback? onSettle;
  final VoidCallback? onCancel;
  final bool isApprovalConfirmation;

  const _RequestDetailsDialog({
    required this.request,
    this.sourceType,
    this.onApprove,
    this.onDecline,
    this.onSettle,
    this.onCancel,
    this.isApprovalConfirmation = false,
  });

  @override
  State<_RequestDetailsDialog> createState() => _RequestDetailsDialogState();
}

class _RequestDetailsDialogState extends State<_RequestDetailsDialog> {
  bool _isDownloadingPDF = false;
  bool _isPrintingPDF = false;

  // Finance editing controllers
  late TextEditingController _periodController;
  late TextEditingController _unscheduledPaymentAmountController;
  late TextEditingController _unscheduledPaymentMonthsController;
  late TextEditingController _unscheduledPaymentNotesController;
  DateTime? _selectedPaymentDate;
  bool _isPayingByMonths = false;
  int _selectedMonths = 1;
  //bool _isUnscheduledPaymentMode = false;
  AdvanceOnSalaryRequestModel? _editedRequest;
  late AdvanceOnSalaryRequestModel _currentRequest;
  final _periodFormKey = GlobalKey<FormState>();
  String? _messageText;
  Color? _messageColor;
  bool _showMessage = false;

  // Section visibility controls
  bool _showEditSection = false;
  bool _showUnscheduledPaymentSection = false;
  bool _showPDFActionsSection = false;

  // Track the type of finance operation being performed
  bool _isAddingUnscheduledPayment = false;

  // Track which section's buttons should be shown in bottom action area
  ActiveSectionType? _activeSectionForButtons;

  @override
  void initState() {
    super.initState();
    _currentRequest = widget.request;
    _periodController = TextEditingController(
      text: _currentRequest.updatedPeriod?.toString() ?? _currentRequest.periodInMonths?.toString() ?? '',
    );
    _unscheduledPaymentAmountController = TextEditingController();
    _unscheduledPaymentMonthsController = TextEditingController();
    _unscheduledPaymentNotesController = TextEditingController();
    _editedRequest = _currentRequest;
  }

  @override
  void dispose() {
    _periodController.dispose();
    _unscheduledPaymentAmountController.dispose();
    _unscheduledPaymentMonthsController.dispose();
    _unscheduledPaymentNotesController.dispose();
    super.dispose();
  }

  void _showSuccessMessage(String message) {
    setState(() {
      _messageText = message;
      _messageColor = Colors.green;
      _showMessage = true;
    });

    // Auto-hide message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showMessage = false;
        });
      }
    });
  }

  void _showErrorMessage(String message) {
    setState(() {
      _messageText = message;
      _messageColor = Colors.red;
      _showMessage = true;
    });

    // Auto-hide message after 5 seconds (longer for errors)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showMessage = false;
        });
      }
    });
  }

  void _hideMessage() {
    setState(() {
      _showMessage = false;
    });
  }

  String _getDisplayName(BuildContext context, String? englishName, String? arabicName) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? (arabicName ?? englishName ?? '') : (englishName ?? arabicName ?? '');
  }

  bool get _isFinanceUser {
    return context.read<UserBloc>().state.user?.groups?.contains('finance') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
      listener: (context, state) {
        // Handle finance edit operation feedback
        if (state.financeEditStatus == Status.success) {
          // Update the current request with fresh data from the bloc
          final updatedRequest = state.requests.firstWhere(
            (request) => request.id == _currentRequest.id,
            orElse: () => _currentRequest,
          );

          setState(() {
            _currentRequest = updatedRequest;
          });

          // Only show success message for unscheduled payment operations
          // Period changes handle their own success message
          if (_isAddingUnscheduledPayment) {
            _showSuccessMessage(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'تم إضافة الدفعة بنجاح وتحديث ملف PDF!'
                  : 'Payment added successfully and PDF updated!',
            );

            // Reset the flag
            _isAddingUnscheduledPayment = false;
          }

          // Reset finance edit status
          context.read<UserAdvanceOnSalaryRequestsBloc>().add(const ResetFinanceEditStatus());
        } else if (state.financeEditStatus == Status.failure) {
          // Show appropriate error message based on operation type
          if (_isAddingUnscheduledPayment) {
            _showErrorMessage(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'فشل في إضافة الدفعة. ${state.operationFailure?.message ?? "يرجى المحاولة مرة أخرى."}'
                  : 'Failed to add payment. ${state.operationFailure?.message ?? "Please try again."}',
            );
            _isAddingUnscheduledPayment = false; // Reset flag
          } else {
            _showErrorMessage(
              Localizations.localeOf(context).languageCode == 'ar'
                  ? 'فشل في حفظ التغييرات: ${state.operationFailure?.message ?? 'خطأ غير معروف'}'
                  : 'Failed to save changes: ${state.operationFailure?.message ?? 'Unknown error'}',
            );
          }

          // Reset finance edit status
          context.read<UserAdvanceOnSalaryRequestsBloc>().add(const ResetFinanceEditStatus());
        }
      },
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: context.screenWidth < 600 ? context.screenWidth * 0.95 : 600,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Theme.of(context).primaryColor, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.isApprovalConfirmation
                            ? AppLocalizations.of(context)!.approvalConfirmation
                            : AppLocalizations.of(context)!.requestDetails,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
                      builder: (context, state) {
                        final isProcessing =
                            state.financeEditStatus == Status.loading && state.processingRequestId == widget.request.id;

                        return IconButton(
                          icon: const Icon(Icons.close),
                          onPressed:
                              isProcessing
                                  ? null // Disable close during processing
                                  : () => Navigator.of(context).pop(),
                          tooltip:
                              isProcessing
                                  ? (Localizations.localeOf(context).languageCode == 'ar'
                                      ? 'لا يمكن الإغلاق أثناء المعالجة'
                                      : 'Cannot close while processing')
                                  : (Localizations.localeOf(context).languageCode == 'ar' ? 'إغلاق' : 'Close'),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Message Area
              if (_showMessage && _messageText != null)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _messageColor?.withOpacity(0.1),
                    border: Border.all(color: _messageColor ?? Colors.transparent),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _messageColor == Colors.green ? Icons.check_circle : Icons.error,
                        color: _messageColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_messageText!, style: TextStyle(color: _messageColor, fontWeight: FontWeight.w500)),
                      ),
                      IconButton(
                        onPressed: _hideMessage,
                        icon: Icon(Icons.close, color: _messageColor, size: 18),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

              // Loading message when processing unscheduled payment
              BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
                builder: (context, state) {
                  final isProcessing =
                      state.financeEditStatus == Status.loading && state.processingRequestId == _currentRequest.id;

                  if (!isProcessing) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? 'جاري معالجة الدفعة وتحديث ملف PDF. قد يستغرق ذلك بضع ثوان...'
                                : 'Processing your payment and regenerating PDF. This may take a few seconds...',
                            style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Conditional Action Sections
              if (_showEditSection || _showUnscheduledPaymentSection || _showPDFActionsSection) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    width: context.screenWidth < 600 ? context.screenWidth * 0.9 : 550,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        if (_showEditSection) _buildEditSectionWithClose(),
                        if (_showUnscheduledPaymentSection) _buildUnscheduledPaymentSectionWithClose(),
                        if (_showPDFActionsSection) _buildPDFActionsSectionWithClose(context, _currentRequest),
                      ],
                    ),
                  ),
                ),
                const Divider(),
              ],

              // Scrollable Content
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: context.screenWidth < 600 ? context.screenWidth * 0.9 : 550,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Request Details
                          _buildDetailRow(
                            AppLocalizations.of(context)!.requestId,
                            _currentRequest.id?.toString() ?? 'N/A',
                          ),

                          if (_currentRequest.createdAt != null)
                            _buildDetailRow(
                              AppLocalizations.of(context)!.createdAt,
                              DateFormat('yyyy-MM-dd hh:mm a').format(_currentRequest.tzCreatedAt),
                            ),

                          // Requestor Information Section
                          if (widget.sourceType == RequestSourceType.teamRequests) ...[
                            const SizedBox(height: 8),
                            Container(
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
                                    AppLocalizations.of(context)!.requestor,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                    AppLocalizations.of(context)!.name,
                                    '${_getDisplayName(context, _currentRequest.requestorEnglishName, _currentRequest.requestorArabicName)} (${_currentRequest.requestorCode})',
                                  ),
                                  _buildDetailRow(
                                    AppLocalizations.of(context)!.title,
                                    Localizations.localeOf(context).languageCode == 'ar'
                                        ? (_currentRequest.requestorTitle ?? '')
                                        : (_currentRequest.requestorEnglishTitle ??
                                            _currentRequest.requestorTitle ??
                                            ''),
                                  ),
                                  _buildDetailRow(
                                    AppLocalizations.of(context)!.department,
                                    Localizations.localeOf(context).languageCode == 'ar'
                                        ? (_currentRequest.requestorDepartment ?? '')
                                        : (_currentRequest.requestorEnglishDepartment ??
                                            _currentRequest.requestorDepartment ??
                                            ''),
                                  ),
                                  _buildDetailRow(
                                    AppLocalizations.of(context)!.hireDate,
                                    _currentRequest.requestorHireDate ?? '',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
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
                                    AppLocalizations.of(context)!.borrower,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildDetailRow(
                                    AppLocalizations.of(context)!.name,
                                    '${_getDisplayName(context, _currentRequest.borrowerEnglishName, _currentRequest.borrowerArabicName)} (${_currentRequest.borrowerCode})',
                                  ),
                                  _buildDetailRow(
                                    AppLocalizations.of(context)!.title,
                                    Localizations.localeOf(context).languageCode == 'ar'
                                        ? (_currentRequest.borrowerTitle ?? '')
                                        : (_currentRequest.borrowerEnglishTitle ?? _currentRequest.borrowerTitle ?? ''),
                                  ),
                                  _buildDetailRow(
                                    AppLocalizations.of(context)!.department,
                                    Localizations.localeOf(context).languageCode == 'ar'
                                        ? (_currentRequest.borrowerDepartment ?? '')
                                        : (_currentRequest.borrowerEnglishDepartment ??
                                            _currentRequest.borrowerDepartment ??
                                            ''),
                                  ),
                                  _buildDetailRow(
                                    AppLocalizations.of(context)!.hireDate,
                                    _currentRequest.borrowerHireDate ?? '',
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                          ] else ...[
                            _buildDetailRow(
                              AppLocalizations.of(context)!.requestor,
                              '${_getDisplayName(context, _currentRequest.requestorEnglishName, _currentRequest.requestorArabicName)} (${_currentRequest.requestorCode})',
                            ),
                            _buildDetailRow(
                              AppLocalizations.of(context)!.borrower,
                              '${_getDisplayName(context, _currentRequest.borrowerEnglishName, _currentRequest.borrowerArabicName)} (${_currentRequest.borrowerCode})',
                            ),
                          ],
                          _buildDetailRow(
                            AppLocalizations.of(context)!.amountRequested,
                            '${NumberFormat('#,##0.00').format(_currentRequest.amount ?? 0)} ${Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP'}',
                          ),
                          _buildDetailRow(
                            AppLocalizations.of(context)!.amountInLetters,
                            _currentRequest.getAmountInLetters(context).isNotEmpty
                                ? _currentRequest.getAmountInLetters(context)
                                : 'N/A',
                          ),
                          _buildDetailRow(
                            AppLocalizations.of(context)!.period,
                            '${_currentRequest.periodInMonths ?? 0} ${AppLocalizations.of(context)!.months}',
                          ),
                          _buildDetailRow(
                            AppLocalizations.of(context)!.monthlyPaymentLabel,
                            '${NumberFormat('#,##0.00').format(_currentRequest.monthlyPayment ?? 0)} ${Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP'}',
                          ),

                          if (_currentRequest.paymentStartDate != null)
                            _buildDetailRow(
                              AppLocalizations.of(context)!.paymentStartDateLabel,
                              DateFormat('MMM dd, yyyy').format(_currentRequest.paymentStartDate!),
                            ),

                          if (_currentRequest.paymentEndDate != null)
                            _buildDetailRow(
                              AppLocalizations.of(context)!.paymentEndDateLabel,
                              DateFormat('MMM dd, yyyy').format(_currentRequest.paymentEndDate!),
                            ),

                          _buildDetailRow(
                            AppLocalizations.of(context)!.status,
                            _currentRequest.getLocalizedStatus(context),
                          ),
                          if (_currentRequest.status == 'pending')
                            _buildDetailRow(
                              AppLocalizations.of(context)!.currentApprover,
                              _currentRequest.getLocalizedApproverName(context),
                            ),

                          // Approval History Section
                          if (_currentRequest.n2ApprovalDate != null)
                            _buildDetailRow(
                              () {
                                final bool isDeclinedByN2 =
                                    _currentRequest.status?.toLowerCase() == 'declined' &&
                                    _currentRequest.currentApprover?.toLowerCase() == 'n2';
                                return isDeclinedByN2
                                    ? AppLocalizations.of(context)!.declinedByN2
                                    : AppLocalizations.of(context)!.approvedByN2;
                              }(),
                              Localizations.localeOf(context).languageCode == 'ar'
                                  ? "${_currentRequest.n2ArabicName ?? 'N+2'} ${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(_currentRequest.n2ApprovalDate!)}"
                                  : "${_currentRequest.n2EnglishName ?? 'N+2'} ${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(_currentRequest.n2ApprovalDate!)}",
                            ),

                          if (_currentRequest.hrApprovalDate != null)
                            _buildDetailRow(
                              () {
                                final bool isDeclinedByHR =
                                    _currentRequest.status?.toLowerCase() == 'declined' &&
                                    _currentRequest.currentApprover?.toLowerCase() == 'hr';
                                return isDeclinedByHR
                                    ? AppLocalizations.of(context)!.declinedByHR
                                    : AppLocalizations.of(context)!.approvedByHR;
                              }(),
                              () {
                                final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                                String approverName;
                                if (_currentRequest.hrEnglishName != null || _currentRequest.hrArabicName != null) {
                                  approverName =
                                      isArabic
                                          ? (_currentRequest.hrArabicName ?? _currentRequest.hrEnglishName ?? '')
                                          : (_currentRequest.hrEnglishName ?? _currentRequest.hrArabicName ?? '');
                                } else {
                                  approverName = '';
                                }
                                if (approverName.isNotEmpty) {
                                  return "$approverName ${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(_currentRequest.hrApprovalDate!)}";
                                } else {
                                  return "${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(_currentRequest.hrApprovalDate!)}";
                                }
                              }(),
                            ),

                          if (_currentRequest.financeApprovalDate != null)
                            _buildDetailRow(
                              () {
                                final bool isDeclinedByFinance =
                                    _currentRequest.status?.toLowerCase() == 'declined' &&
                                    _currentRequest.currentApprover?.toLowerCase() == 'finance';
                                return isDeclinedByFinance
                                    ? AppLocalizations.of(context)!.declinedByFinance
                                    : AppLocalizations.of(context)!.approvedByFinance;
                              }(),
                              () {
                                final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                                String approverName;
                                if (_currentRequest.financeEnglishName != null ||
                                    _currentRequest.financeArabicName != null) {
                                  approverName =
                                      isArabic
                                          ? (_currentRequest.financeArabicName ??
                                              _currentRequest.financeEnglishName ??
                                              '')
                                          : (_currentRequest.financeEnglishName ??
                                              _currentRequest.financeArabicName ??
                                              '');
                                } else {
                                  approverName = '';
                                }
                                if (approverName.isNotEmpty) {
                                  return "$approverName ${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(_currentRequest.financeApprovalDate!)}";
                                } else {
                                  return "${AppLocalizations.of(context)!.on} ${DateFormat('yyyy-MM-dd').format(_currentRequest.financeApprovalDate!)}";
                                }
                              }(),
                            ),

                          if (_currentRequest.declineReason != null && _currentRequest.declineReason!.isNotEmpty)
                            _buildDetailRow(
                              AppLocalizations.of(context)!.declineReason,
                              _currentRequest.declineReason!,
                            ),

                          if (_currentRequest.status == 'approved' &&
                              !_currentRequest.needsEmployeeConfirmation &&
                              !_currentRequest.needsFinanceAcknowledgment)
                            _buildDetailRow(
                              AppLocalizations.of(context)!.manuallySettled,
                              _currentRequest.manuallySettled == true
                                  ? AppLocalizations.of(context)!.yes
                                  : AppLocalizations.of(context)!.no,
                            ),

                          if (_currentRequest.manuallySettled == true &&
                              _currentRequest.settlementInfo != null &&
                              _currentRequest.settlementInfo!.isNotEmpty)
                            _buildDetailRow(
                              AppLocalizations.of(context)!.settledBy,
                              _currentRequest.getLatestSettlerName(
                                Localizations.localeOf(context).languageCode == 'ar' ? true : false,
                              ),
                            ),

                          if (_currentRequest.manuallySettled == true &&
                              _currentRequest.settlementInfo != null &&
                              _currentRequest.settlementInfo!.isNotEmpty)
                            _buildDetailRow(
                              AppLocalizations.of(context)!.settlementDate,
                              DateFormat('MMM dd, yyyy').format(_currentRequest.getLatestSettlementDate()!),
                            ),

                          // Updated Fields Section (if any values have been updated)
                          if (_currentRequest.updatedPeriod != null ||
                              _currentRequest.updatedMonthlyPayment != null ||
                              _currentRequest.updatedPaymentEndDate != null)
                            _buildUpdatedFieldsSection(),

                          // Updated Monthly Amount Section (when unscheduled payments exist)
                          if (_currentRequest.unscheduledPayments != null &&
                              _currentRequest.unscheduledPayments!.isNotEmpty)
                            _buildUpdatedMonthlyAmountSection(),

                          // Unscheduled Payments Display
                          if (_currentRequest.unscheduledPayments != null &&
                              _currentRequest.unscheduledPayments!.isNotEmpty &&
                              _isFinanceUser)
                            _buildUnscheduledPaymentsDisplay(),

                          // Scheduled Payments Display
                          if (_currentRequest.scheduledPayments != null &&
                              _currentRequest.scheduledPayments!.isNotEmpty)
                            _buildScheduledPaymentsDisplay(),

                          // Unified Payments Summary
                          if ((_currentRequest.unscheduledPayments != null &&
                                  _currentRequest.unscheduledPayments!.isNotEmpty) ||
                              (_currentRequest.scheduledPayments != null &&
                                  _currentRequest.scheduledPayments!.isNotEmpty))
                            _buildUnifiedPaymentsSummary(),

                          // Change Log Display
                          if (_currentRequest.comments != null && _currentRequest.comments!.isNotEmpty)
                            _buildChangeLogSection(),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Fixed Action Buttons at bottom
              if ((widget.request.status != 'declined' && widget.sourceType != RequestSourceType.myRequests) ||
                  (widget.request.status == 'pending' && !widget.request.cancelled!) ||
                  (widget.request.status == 'approved' &&
                      widget.request.needsEmployeeConfirmation == true &&
                      widget.sourceType == RequestSourceType.myRequests))
                Row(children: [Expanded(child: _buildFixedActionButtons(context))]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPDFActionsSection(BuildContext context, AdvanceOnSalaryRequestModel request) {
    // Only show PDF actions for approved requests
    if (!request.shouldHavePDF && !request.hasPDF && request.status == 'pending') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)!.pdfGeneratedWhenApproved,
                style: TextStyle(fontSize: 12, color: Colors.orange[700]),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isDownloadingPDF || _isPrintingPDF ? null : () => _downloadPDF(context, request),
                icon:
                    _isDownloadingPDF
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                        : const Icon(Icons.download, size: 18),
                label: Text(
                  _isDownloadingPDF
                      ? AppLocalizations.of(context)!.downloading
                      : AppLocalizations.of(context)!.downloadPdf,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isDownloadingPDF || _isPrintingPDF ? null : () => _printPDF(context, request),
                icon:
                    _isPrintingPDF
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                        : const Icon(Icons.print, size: 18),
                label: Text(
                  _isPrintingPDF ? AppLocalizations.of(context)!.printing : AppLocalizations.of(context)!.printPdf,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _downloadPDF(BuildContext context, AdvanceOnSalaryRequestModel request) async {
    setState(() {
      _isDownloadingPDF = true;
    });

    try {
      final pdfStorageService = context.read<AdvancePDFStorageService>();
      final locale = Localizations.localeOf(context).languageCode;

      // For web, use direct download
      if (kIsWeb) {
        // Use service method for on-demand generation (no storage)
        final pdfBytes = await pdfStorageService.generateCurrentStatePDFBytes(request, locale);
        final fileName = 'Advance_Salary_Request_${request.id}.pdf';

        downloadPdfWeb(pdfBytes, fileName);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.pdfDownloadedSuccessfully('Downloads/$fileName')),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // For mobile/desktop, save to file system
        final filePath = await context.read<PDFGenerationService>().generateAdvanceRequestPDF(request, locale);

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
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingPDF = false;
        });
      }
    }
  }

  Future<void> _printPDF(BuildContext context, AdvanceOnSalaryRequestModel request) async {
    setState(() {
      _isPrintingPDF = true;
    });

    try {
      // Generate PDF for printing
      final pdfStorageService = context.read<AdvancePDFStorageService>();
      final locale = Localizations.localeOf(context).languageCode;

      // Use service method for on-demand generation (no storage)
      final pdfBytes = await pdfStorageService.generateCurrentStatePDFBytes(request, locale);

      // Use the printing package to print
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes, name: 'Advance_Salary_Request_${request.id}');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to print PDF: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrintingPDF = false;
        });
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildFinanceEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period Editor
        _buildPeriodEditor(),
      ],
    );
  }

  Widget _buildPeriodEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Localizations.localeOf(context).languageCode == 'ar'
              ? 'تعديل فترة السداد (بالأشهر):'
              : 'Edit Payment Period (months):',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Form(
          key: _periodFormKey,
          child: TextFormField(
            controller: _periodController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText:
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'أدخل عدد الأشهر (1-12)'
                      : 'Enter number of months (1-12)',
              helperText:
                  Localizations.localeOf(context).languageCode == 'ar'
                      ? 'الفترة يجب أن تكون بين 1 و 12 شهر'
                      : 'Period must be between 1 and 12 months',
              suffixText: Localizations.localeOf(context).languageCode == 'ar' ? 'شهر' : 'months',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return Localizations.localeOf(context).languageCode == 'ar'
                    ? 'يرجى إدخال الفترة'
                    : 'Please enter the period';
              }
              final period = int.tryParse(value);
              if (period == null) {
                return Localizations.localeOf(context).languageCode == 'ar'
                    ? 'يرجى إدخال رقم صحيح'
                    : 'Please enter a valid number';
              }
              if (period < 1 || period > 12) {
                return Localizations.localeOf(context).languageCode == 'ar'
                    ? 'الفترة يجب أن تكون بين 1 و 12 شهر'
                    : 'Period must be between 1 and 12 months';
              }
              return null;
            },
            onChanged: _onPeriodChanged,
          ),
        ),
        if (_editedRequest != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'القسط الشهري الجديد:'
                            : 'New Monthly Payment:',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,##0.00').format(_editedRequest!.updatedMonthlyPayment ?? _editedRequest!.monthlyPayment ?? 0)} ${Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'تاريخ انتهاء السداد الجديد:'
                            : 'New Payment End Date:',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy',
                      ).format(_editedRequest!.updatedPaymentEndDate ?? _editedRequest!.paymentEndDate!),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUnscheduledPaymentEditor() {
    return BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
      builder: (context, state) {
        final isProcessing =
            state.financeEditStatus == Status.loading && state.processingRequestId == _currentRequest.id;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // // Toggle between Amount and Months
            // Container(
            //   decoration: BoxDecoration(
            //     border: Border.all(color: Colors.grey.shade300),
            //     borderRadius: BorderRadius.circular(8),
            //   ),
            //   padding: const EdgeInsets.all(8),
            //   child: Row(
            //     mainAxisSize: MainAxisSize.min,
            //     children: [
            //       Text(
            //         Localizations.localeOf(context).languageCode == 'ar'
            //             ? 'طريقة الدفع:'
            //             : 'Payment Mode:',
            //         style: const TextStyle(fontWeight: FontWeight.w500),
            //       ),
            //       const SizedBox(width: 12),
            //       ToggleButtons(
            //         isSelected: [!_isPayingByMonths, _isPayingByMonths],
            //         onPressed: (int index) {
            //           setState(() {
            //             _isPayingByMonths = index == 1;
            //             // Clear both controllers when switching
            //             _unscheduledPaymentAmountController.clear();
            //             _unscheduledPaymentMonthsController.clear();
            //             // Reset months to 1 when switching to months mode
            //             if (_isPayingByMonths) {
            //               _selectedMonths = 1;
            //               _updateAmountFromMonths();
            //             }
            //           });
            //         },
            //         borderRadius: BorderRadius.circular(6),
            //         selectedColor: Colors.white,
            //         fillColor: Colors.blue,
            //         children: [
            //           Padding(
            //             padding: const EdgeInsets.symmetric(horizontal: 12),
            //             child: Text(
            //               Localizations.localeOf(context).languageCode == 'ar'
            //                   ? 'مبلغ'
            //                   : 'Amount',
            //             ),
            //           ),
            //           Padding(
            //             padding: const EdgeInsets.symmetric(horizontal: 12),
            //             child: Text(
            //               Localizations.localeOf(context).languageCode == 'ar'
            //                   ? 'شهور'
            //                   : 'Months',
            //             ),
            //           ),
            //         ],
            //       ),
            //     ],
            //   ),
            // ),

            // const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child:
                  // _isPayingByMonths
                  //     ? _buildMonthsPicker()
                  TextField(
                    controller: _unscheduledPaymentAmountController,
                    enabled: !isProcessing,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: Localizations.localeOf(context).languageCode == 'ar' ? 'المبلغ' : 'Amount',
                      suffixText: Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: isProcessing ? null : () => _selectPaymentDate(context),
                    child: Container(
                      height: 49,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[800]!, width: 0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedPaymentDate != null
                                  ? DateFormat('MMM dd, yyyy').format(_selectedPaymentDate!)
                                  : (Localizations.localeOf(context).languageCode == 'ar'
                                      ? 'اختر تاريخ الدفع'
                                      : 'Select Payment Date'),
                              style: TextStyle(color: _selectedPaymentDate != null ? Colors.black87 : Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _unscheduledPaymentNotesController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText:
                    Localizations.localeOf(context).languageCode == 'ar' ? 'ملاحظات (اختياري)' : 'Notes (Optional)',
                hintText:
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'أدخل أي ملاحظات حول هذه الدفعة'
                        : 'Enter any notes about this payment',
              ),
              maxLines: 2,
              enabled: !isProcessing,
            ),
          ],
        );
      },
    );
  }

  Widget _buildUnscheduledPaymentsDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        Row(
          children: [
            Icon(Icons.history, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              Localizations.localeOf(context).languageCode == 'ar' ? 'الدفعات غير المجدولة' : 'Unscheduled Payments',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),

        const SizedBox(height: 16),

        ..._currentRequest.unscheduledPayments!.map((payment) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.payment, color: Colors.white),
              ),
              title: Text(
                '${NumberFormat('#,##0.00').format(payment.amount)} ${Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('MMM dd, yyyy').format(payment.paymentDate)),
                  if (payment.notes != null && payment.notes!.isNotEmpty) Text(payment.notes!),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildScheduledPaymentsDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        Row(
          children: [
            Icon(Icons.schedule, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              Localizations.localeOf(context).languageCode == 'ar' ? 'الدفعات المجدولة' : 'Scheduled Payments',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Sort scheduled payments by date
        ...(_currentRequest.scheduledPayments!..sort((a, b) => a.paymentDate.compareTo(b.paymentDate))).map((payment) {
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.schedule, color: Colors.white),
              ),
              title: Text(
                '${NumberFormat('#,##0.00').format(payment.amount)} ${Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(DateFormat('MMM dd, yyyy').format(payment.paymentDate))],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildUnifiedPaymentsSummary() {
    final hasUnscheduledPayments =
        _currentRequest.unscheduledPayments != null && _currentRequest.unscheduledPayments!.isNotEmpty;
    final hasScheduledPayments =
        _currentRequest.scheduledPayments != null && _currentRequest.scheduledPayments!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        Row(
          children: [
            Icon(Icons.summarize, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              Localizations.localeOf(context).languageCode == 'ar' ? 'ملخص الدفعات' : 'Payments Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Card(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Original Loan Amount
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'مبلغ القرض الأصلي:'
                            : 'Original Loan Amount:',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,##0.00').format(_currentRequest.amount ?? 0)} ${Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                  ],
                ),

                // Unscheduled Payments
                if (hasUnscheduledPayments) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'إجمالي الدفعات غير المجدولة:'
                              : 'Total Unscheduled Payments:',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,##0.00').format(_currentRequest.totalUnscheduledPayments)} ${Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ],

                // Scheduled Payments
                if (hasScheduledPayments) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'إجمالي الدفعات المجدولة:'
                              : 'Total Scheduled Payments:',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,##0.00').format(_currentRequest.totalScheduledPayments)} ${Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ],

                // Total All Payments (if both types exist)
                if (hasUnscheduledPayments && hasScheduledPayments) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'إجمالي جميع الدفعات:'
                              : 'Total All Payments:',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blue),
                        ),
                      ),
                      Text(
                        '${NumberFormat('#,##0.00').format(_currentRequest.totalUnscheduledPayments + _currentRequest.totalScheduledPayments)} ${Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP'}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ],

                // Divider before remaining amount
                const SizedBox(height: 12),
                Divider(color: Colors.blue[200]),
                const SizedBox(height: 8),

                // Remaining Amount
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'المبلغ المتبقي:' : 'Remaining Amount:',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,##0.00').format(_currentRequest.remainingAmount)} ${Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP'}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _currentRequest.remainingAmount > 0 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ],
                ),

                // Payment completion status
                if (_currentRequest.remainingAmount <= 0 || _currentRequest.manuallySettled == true) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[700], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? _currentRequest.manuallySettled == true
                                  ? 'تمت تسوية القرض يدويًا'
                                  : 'تم سداد القرض بالكامل'
                              : _currentRequest.manuallySettled == true
                              ? 'Loan Manually Settled'
                              : 'Loan Fully Paid',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700]),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChangeLogSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        Row(
          children: [
            Icon(Icons.history, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              Localizations.localeOf(context).languageCode == 'ar' ? 'سجل التغييرات' : 'Change Log',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxHeight: 200, // Maximum height for scrolling
          ),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              _parseChangeLogForLocale(_currentRequest.comments!),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdatedFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        Row(
          children: [
            Icon(Icons.edit, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              Localizations.localeOf(context).languageCode == 'ar' ? 'التحديثات المالية' : 'Finance Updates',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Updated Period
              if (_currentRequest.updatedPeriod != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 2,
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar' ? 'الفترة المحدثة:' : 'Updated Period:',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        flex: 3,
                        child: Text(
                          '${_currentRequest.updatedPeriod} ${AppLocalizations.of(context)!.months}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

              // Updated Monthly Payment (only if no unscheduled payments exist)
              if (_currentRequest.updatedMonthlyPayment != null &&
                  (_currentRequest.unscheduledPayments == null || _currentRequest.unscheduledPayments!.isEmpty))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 2,
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'القسط الشهري المحدث:'
                              : 'Updated Monthly Payment:',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        flex: 3,
                        child: Text(
                          '${NumberFormat('#,##0.00').format(_currentRequest.updatedMonthlyPayment!)} ${Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP'}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),

              // Updated Payment End Date
              if (_currentRequest.updatedPaymentEndDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        flex: 2,
                        child: Text(
                          Localizations.localeOf(context).languageCode == 'ar'
                              ? 'تاريخ انتهاء السداد المحدث:'
                              : 'Updated Payment End Date:',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        flex: 3,
                        child: Text(
                          DateFormat('MMM dd, yyyy').format(_currentRequest.updatedPaymentEndDate!),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpdatedMonthlyAmountSection() {
    // Use the new currentMonthlyPayment getter
    final currentMonthlyAmount = _currentRequest.currentMonthlyPayment;
    final originalMonthlyPayment = _currentRequest.updatedMonthlyPayment ?? _currentRequest.monthlyPayment;

    // Only show section if we have a valid calculation and there's a meaningful change
    if (currentMonthlyAmount == null ||
        originalMonthlyPayment == null ||
        (currentMonthlyAmount - originalMonthlyPayment).abs() < 0.01) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        Row(
          children: [
            Icon(Icons.calculate, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              Localizations.localeOf(context).languageCode == 'ar' ? 'القسط الشهري المعدل' : 'Adjusted Monthly Payment',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Remaining Amount
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'المبلغ المتبقي:' : 'Remaining Amount:',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 3,
                      child: Text(
                        '${NumberFormat('#,##0.00').format(_currentRequest.remainingAmount)} ${Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP'}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              // Remaining Months
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar' ? 'الأشهر المتبقية:' : 'Remaining Months:',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 3,
                      child: Text(
                        '${_currentRequest.remainingMonths ?? 0} ${Localizations.localeOf(context).languageCode == 'ar' ? 'شهر' : 'months'}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

              // Updated Monthly Amount
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      flex: 2,
                      child: Text(
                        Localizations.localeOf(context).languageCode == 'ar'
                            ? 'القسط الشهري المعدل:'
                            : 'Adjusted Monthly Payment:',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Flexible(
                      flex: 3,
                      child: Text(
                        '${NumberFormat('#,##0.00').format(currentMonthlyAmount)} ${Localizations.localeOf(context).languageCode == 'ar' ? 'جنيه' : 'EGP'}',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Parse change log and return the appropriate language version based on current locale
  String _parseChangeLogForLocale(String comments) {
    final locale = Localizations.localeOf(context).languageCode;
    final isArabic = locale == 'ar';
    final lines = comments.split('\n');
    final parsedLines = <String>[];

    for (String line in lines) {
      if (line.contains(' EN: ') && line.contains(' | AR: ')) {
        // This is a bilingual entry, parse it
        final timestamp = line.substring(0, line.indexOf(']') + 1);
        final content = line.substring(line.indexOf(']') + 2);

        final enIndex = content.indexOf('EN: ');
        final arIndex = content.indexOf(' | AR: ');

        if (enIndex != -1 && arIndex != -1) {
          final englishText = content.substring(enIndex + 4, arIndex);
          final arabicText = content.substring(arIndex + 6);

          parsedLines.add('$timestamp ${isArabic ? arabicText : englishText}');
        } else {
          // Fallback to original line if parsing fails
          parsedLines.add(line);
        }
      } else {
        // This is a regular entry, keep as is
        parsedLines.add(line);
      }
    }

    return parsedLines.join('\n');
  }

  void _onPeriodChanged(String value) {
    final newPeriod = int.tryParse(value);
    if (newPeriod != null && newPeriod >= 1 && newPeriod <= 12) {
      setState(() {
        _editedRequest = _currentRequest.recalculateWithNewPeriod(newPeriod);
      });
    }
  }

  void _savePeriodChanges() async {
    if (!_periodFormKey.currentState!.validate()) {
      return;
    }

    final newPeriod = int.parse(_periodController.text);

    // Get current user information
    final currentUser = context.read<UserBloc>().state.user;
    final englishUserName = currentUser?.englishName ?? 'Finance';
    final arabicUserName = currentUser?.arabicName ?? 'المالية';

    // Add bilingual change log entry
    final englishChangeLog =
        '$englishUserName: Changed payment period from ${_currentRequest.periodInMonths} to $newPeriod months. New monthly payment: ${NumberFormat('#,##0.00').format(_editedRequest!.updatedMonthlyPayment)}';
    final arabicChangeLog =
        '$arabicUserName: تم تغيير فترة السداد من ${_currentRequest.periodInMonths} إلى $newPeriod شهر. القسط الشهري الجديد: ${NumberFormat('#,##0.00').format(_editedRequest!.updatedMonthlyPayment)}';

    final updatedRequest = _editedRequest!.addBilingualChangeLog(
      englishChange: englishChangeLog,
      arabicChange: arabicChangeLog,
    );

    try {
      context.read<UserAdvanceOnSalaryRequestsBloc>().add(UpdateRequestByFinance(updatedRequest));

      setState(() {
        _showEditSection = false;
        _currentRequest = updatedRequest;
        _editedRequest = updatedRequest;
      });

      _showSuccessMessage(
        Localizations.localeOf(context).languageCode == 'ar' ? 'تم حفظ التغييرات بنجاح' : 'Changes saved successfully',
      );

      // Reset UI state after successful save
      setState(() {
        _showEditSection = false;
        _activeSectionForButtons = null;
      });
    } catch (e) {
      _showErrorMessage(
        Localizations.localeOf(context).languageCode == 'ar' ? 'فشل في حفظ التغييرات' : 'Failed to save changes',
      );
    }
  }

  Future<void> _selectPaymentDate(BuildContext context) async {
    final DateTime? picked = await showCustomDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedPaymentDate = picked;
      });
    }
  }

  // Widget _buildMonthsPicker() {
  //   final maxMonths =
  //       (_currentRequest.remainingAmount / _currentRequest.monthlyPayment!)
  //           .toInt();

  //   return Container(
  //     height: 49,
  //     decoration: BoxDecoration(
  //       border: Border.all(color: Colors.grey[800]!, width: 0.7),
  //       borderRadius: BorderRadius.circular(4),
  //     ),
  //     padding: const EdgeInsets.symmetric(horizontal: 12),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         // Minus button
  //         Container(
  //           width: 28,
  //           height: 28,
  //           decoration: BoxDecoration(
  //             border: Border.all(color: Colors.grey[400]!),
  //             borderRadius: BorderRadius.circular(4),
  //           ),
  //           child: IconButton(
  //             padding: EdgeInsets.zero,
  //             onPressed:
  //                 _selectedMonths > 1
  //                     ? () {
  //                       setState(() {
  //                         _selectedMonths--;
  //                         _updateAmountFromMonths();
  //                       });
  //                     }
  //                     : null,
  //             icon: Icon(
  //               Icons.remove,
  //               size: 14,
  //               color: _selectedMonths > 1 ? Colors.blue : Colors.grey,
  //             ),
  //           ),
  //         ),

  //         // Display months value
  //         Expanded(
  //           child: Center(
  //             child: RichText(
  //               text: TextSpan(
  //                 children: [
  //                   TextSpan(
  //                     text: '$_selectedMonths ',
  //                     style: const TextStyle(
  //                       fontSize: 16,
  //                       fontWeight: FontWeight.bold,
  //                       color: Colors.black87,
  //                     ),
  //                   ),
  //                   TextSpan(
  //                     text:
  //                         Localizations.localeOf(context).languageCode == 'ar'
  //                             ? 'شهر'
  //                             : 'months',
  //                     style: TextStyle(fontSize: 14, color: Colors.grey[600]),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ),
  //         ),

  //         // Plus button
  //         Container(
  //           width: 28,
  //           height: 28,
  //           decoration: BoxDecoration(
  //             border: Border.all(color: Colors.grey[400]!),
  //             borderRadius: BorderRadius.circular(4),
  //           ),
  //           child: IconButton(
  //             padding: EdgeInsets.zero,
  //             onPressed:
  //                 _selectedMonths < maxMonths
  //                     ? () {
  //                       setState(() {
  //                         _selectedMonths++;
  //                         _updateAmountFromMonths();
  //                       });
  //                     }
  //                     : null,
  //             icon: Icon(
  //               Icons.add,
  //               size: 14,
  //               color: _selectedMonths < maxMonths ? Colors.blue : Colors.grey,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // void _updateAmountFromMonths() {
  //   final monthlyPayment = _currentRequest.monthlyPayment ?? 0;
  //   final calculatedAmount = (monthlyPayment * _selectedMonths).round();
  //   _unscheduledPaymentAmountController.text = calculatedAmount.toString();
  // }

  void _addUnscheduledPayment() async {
    // Set flag to indicate we're adding an unscheduled payment
    _isAddingUnscheduledPayment = true;

    // Check if we have payment date
    if (_selectedPaymentDate == null) {
      _isAddingUnscheduledPayment = false; // Reset flag on early return
      _showErrorMessage(
        Localizations.localeOf(context).languageCode == 'ar' ? 'يرجى اختيار تاريخ الدفع' : 'Please select payment date',
      );
      return;
    }

    double amount;
    // For amount mode, validate amount input
    final amountText = _unscheduledPaymentAmountController.text.trim();
    if (amountText.isEmpty) {
      _isAddingUnscheduledPayment = false; // Reset flag on early return
      _showErrorMessage(
        Localizations.localeOf(context).languageCode == 'ar' ? 'يرجى إدخال المبلغ' : 'Please enter amount',
      );
      return;
    }

    final parsedAmount = double.tryParse(amountText);
    if (parsedAmount == null || parsedAmount <= 0) {
      _isAddingUnscheduledPayment = false; // Reset flag on early return
      _showErrorMessage(
        Localizations.localeOf(context).languageCode == 'ar' ? 'يرجى إدخال مبلغ صحيح' : 'Please enter a valid amount',
      );
      return;
    }
    amount = parsedAmount;

    // Create notes with months info if in months mode
    String finalNotes = _unscheduledPaymentNotesController.text.trim();
    if (_isPayingByMonths) {
      final monthsNote =
          Localizations.localeOf(context).languageCode == 'ar'
              ? 'دفع $_selectedMonths شهر من الأقساط'
              : 'Payment for $_selectedMonths months of installments';

      if (finalNotes.isNotEmpty) {
        finalNotes = '$monthsNote\n$finalNotes';
      } else {
        finalNotes = monthsNote;
      }
    }

    final payment = UnscheduledPayment(
      advanceRequestId: _currentRequest.id!,
      amount: amount,
      paymentDate: _selectedPaymentDate!,
      notes: finalNotes,
      // recordedBy will be set from current user context
    );

    final userCode = context.read<UserBloc>().state.user?.id ?? 0;

    // Add the unscheduled payment
    context.read<UserAdvanceOnSalaryRequestsBloc>().add(AddUnscheduledPayment(_currentRequest.id!, payment, userCode));

    // Clear form and close editor
    _unscheduledPaymentAmountController.clear();
    _unscheduledPaymentMonthsController.clear();
    _unscheduledPaymentNotesController.clear();

    setState(() {
      _selectedPaymentDate = null;
      _selectedMonths = 1;
      _showUnscheduledPaymentSection = false;
      _activeSectionForButtons = null;
    });
  }

  Widget _buildFixedActionButtons(BuildContext context) {
    final userCode = context.read<UserBloc>().state.user?.id ?? 0;
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
          children:
              _activeSectionForButtons != null
                  ? _buildSectionActionButtons(context)
                  : [
                    // Edit button
                    if (_currentRequest.currentApprover?.toLowerCase() == 'finance' &&
                        _currentRequest.status?.toLowerCase() == 'pending' &&
                        _isFinanceUser) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showEditSection = !_showEditSection;
                            _showUnscheduledPaymentSection = false;
                            _showPDFActionsSection = false;
                            // Set active section for buttons
                            _activeSectionForButtons = _showEditSection ? ActiveSectionType.editPeriod : null;
                          });
                        },
                        icon: Icon(_showEditSection ? Icons.close : Icons.edit, size: 18),
                        label: Text(
                          _showEditSection
                              ? AppLocalizations.of(context)!.close
                              : AppLocalizations.of(context)!.editPeriod,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showEditSection ? Colors.grey[600] : Colors.teal[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Unscheduled Payment button
                    if (_currentRequest.status?.toLowerCase() == 'approved' &&
                        !_currentRequest.needsEmployeeConfirmation &&
                        !_currentRequest.needsFinanceAcknowledgment &&
                        _isFinanceUser &&
                        _currentRequest.manuallySettled == false &&
                        (_currentRequest.effectivePaymentEndDate == null ||
                            _currentRequest.effectivePaymentEndDate!.isAfter(DateTime.now())) &&
                        _currentRequest.borrowerCode != userCode &&
                        _currentRequest.requestorCode != userCode) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showUnscheduledPaymentSection = !_showUnscheduledPaymentSection;
                            _showEditSection = false;
                            _showPDFActionsSection = false;
                            // Set active section for buttons
                            _activeSectionForButtons =
                                _showUnscheduledPaymentSection ? ActiveSectionType.unscheduledPayment : null;
                          });
                        },
                        icon: Icon(_showUnscheduledPaymentSection ? Icons.close : Icons.payment_outlined, size: 18),
                        label: Text(
                          _showUnscheduledPaymentSection
                              ? AppLocalizations.of(context)!.close
                              : AppLocalizations.of(context)!.unscheduledPayment,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showUnscheduledPaymentSection ? Colors.grey[600] : Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // PDF Actions button
                    if (_currentRequest.status == 'approved' &&
                        !_currentRequest.needsEmployeeConfirmation &&
                        !_currentRequest.needsFinanceAcknowledgment) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showPDFActionsSection = !_showPDFActionsSection;
                            _showEditSection = false;
                            _showUnscheduledPaymentSection = false;
                            // Reset active section since PDF doesn't have action buttons
                            _activeSectionForButtons = null;
                          });
                        },
                        icon: Icon(_showPDFActionsSection ? Icons.close : Icons.picture_as_pdf, size: 18),
                        label: Text(
                          _showPDFActionsSection
                              ? AppLocalizations.of(context)!.close
                              : AppLocalizations.of(context)!.pdfActions,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _showPDFActionsSection ? Colors.grey[600] : Colors.purple[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Employee confirmation buttons
                    if (_currentRequest.needsEmployeeConfirmation && _currentRequest.borrowerCode == userCode) ...[
                      BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
                        builder: (context, state) {
                          final isConfirming =
                              state.employeeConfirmationStatus == Status.loading &&
                              state.processingRequestId == widget.request.id;

                          return Row(
                            children: [
                              // Confirm button
                              ElevatedButton.icon(
                                onPressed: isConfirming ? null : () => _showEmployeeConfirmationDialog(context, true),
                                icon:
                                    isConfirming
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
                                  isConfirming
                                      ? AppLocalizations.of(context)!.confirmingChanges
                                      : AppLocalizations.of(context)!.confirmFinanceEdit,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[600],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Cancel button
                              ElevatedButton.icon(
                                onPressed: isConfirming ? null : () => _showEmployeeCancelConfirmationDialog(context),
                                icon: const Icon(Icons.cancel, size: 18),
                                label: Text(AppLocalizations.of(context)!.cancelFinanceEdit),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red[600],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          );
                        },
                      ),
                    ],

                    // Finance acknowledgment button
                    if (_currentRequest.needsFinanceAcknowledgment && _isFinanceUser) ...[
                      BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
                        builder: (context, state) {
                          final isAcknowledging =
                              state.financeAcknowledgmentStatus == Status.loading &&
                              state.processingRequestId == widget.request.id;

                          return ElevatedButton.icon(
                            onPressed: isAcknowledging ? null : () => _acknowledgeEmployeeDecision(context),
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
                                    : const Icon(Icons.thumb_up, size: 18),
                            label: Text(
                              isAcknowledging
                                  ? AppLocalizations.of(context)!.acknowledgingDecision
                                  : AppLocalizations.of(context)!.acknowledgeEmployeeDecision,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Approve button
                    if (widget.onApprove != null) ...[
                      BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
                        builder: (context, state) {
                          final isApproving =
                              state.approveStatus == Status.loading && state.processingRequestId == widget.request.id;

                          return ElevatedButton.icon(
                            onPressed:
                                isApproving
                                    ? null
                                    : () {
                                      Navigator.of(context).pop();
                                      widget.onApprove!();
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
                                  ? (widget.isApprovalConfirmation
                                      ? AppLocalizations.of(context)!.confirming
                                      : AppLocalizations.of(context)!.approving)
                                  : (widget.isApprovalConfirmation
                                      ? AppLocalizations.of(context)!.confirmApproval
                                      : AppLocalizations.of(context)!.approve),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Decline button
                    if (widget.onDecline != null) ...[
                      BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
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
                      const SizedBox(width: 8),
                    ],

                    // Settle button
                    if (widget.onSettle != null &&
                        widget.request.requestorCode != userCode &&
                        widget.request.borrowerCode != userCode) ...[
                      BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
                        builder: (context, state) {
                          final isSettling =
                              state.settleStatus == Status.loading && state.processingRequestId == widget.request.id;

                          return ElevatedButton.icon(
                            onPressed:
                                isSettling
                                    ? null
                                    : () {
                                      // Show confirmation dialog for settlement
                                      showDialog(
                                        context: context,
                                        builder:
                                            (confirmContext) => AlertDialog(
                                              title: Text(AppLocalizations.of(context)!.confirmSettlement),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(AppLocalizations.of(context)!.confirmSettlementMessage),
                                                  const SizedBox(height: 16),
                                                  Container(
                                                    padding: const EdgeInsets.all(12),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange[50],
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: Colors.orange[200]!),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.warning, color: Colors.orange[600], size: 20),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            AppLocalizations.of(context)!.settlementWarning,
                                                            style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(confirmContext).pop(),
                                                  child: Text(AppLocalizations.of(context)!.cancel),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () {
                                                    Navigator.of(confirmContext).pop();
                                                    Navigator.of(context).pop();
                                                    widget.onSettle!();
                                                  },
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.orange[600],
                                                    foregroundColor: Colors.white,
                                                  ),
                                                  child: Text(AppLocalizations.of(context)!.confirmSettle),
                                                ),
                                              ],
                                            ),
                                      );
                                    },
                            icon:
                                isSettling
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                    : const Icon(Icons.payment, size: 18),
                            label: Text(
                              isSettling
                                  ? AppLocalizations.of(context)!.settling
                                  : AppLocalizations.of(context)!.settle,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
                              foregroundColor: Colors.white,
                            ),
                          );
                        },
                      ),
                    ],

                    // Cancel button
                    if (widget.onCancel != null &&
                        userCode != widget.request.borrowerCode &&
                        widget.request.currentApprover?.toLowerCase() == 'n2') ...[
                      BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
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
                              isCancelling
                                  ? AppLocalizations.of(context)!.cancelling
                                  : AppLocalizations.of(context)!.cancelRequest,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                            ),
                          );
                        },
                      ),
                    ],
                  ], // Close the original buttons list
        ),
      ),
    );
  }

  List<Widget> _buildSectionActionButtons(BuildContext context) {
    switch (_activeSectionForButtons) {
      case ActiveSectionType.editPeriod:
        return [
          TextButton(
            onPressed: () {
              setState(() {
                _showEditSection = false;
                _activeSectionForButtons = null;
                _periodController.text =
                    _currentRequest.updatedPeriod?.toString() ?? _currentRequest.periodInMonths.toString();
                _editedRequest = _currentRequest;
              });
            },
            child: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'إلغاء' : 'Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _savePeriodChanges,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
            child: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'حفظ التغييرات' : 'Save Changes'),
          ),
        ];

      case ActiveSectionType.unscheduledPayment:
        return [
          TextButton(
            onPressed: () {
              setState(() {
                _showUnscheduledPaymentSection = false;
                _activeSectionForButtons = null;
                _selectedPaymentDate = null;
                _selectedMonths = 1;
              });
              _unscheduledPaymentAmountController.clear();
              _unscheduledPaymentMonthsController.clear();
              _unscheduledPaymentNotesController.clear();
            },
            child: Text(Localizations.localeOf(context).languageCode == 'ar' ? 'إلغاء' : 'Cancel'),
          ),
          const SizedBox(width: 12),
          BlocBuilder<UserAdvanceOnSalaryRequestsBloc, UserAdvanceOnSalaryRequestsState>(
            builder: (context, state) {
              final isProcessing =
                  state.financeEditStatus == Status.loading && state.processingRequestId == _currentRequest.id;
              final isArabic = Localizations.localeOf(context).languageCode == 'ar';

              return ElevatedButton.icon(
                onPressed: isProcessing ? null : _addUnscheduledPayment,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                icon:
                    isProcessing
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                        : Icon(Icons.payment),
                label: Text(
                  isProcessing
                      ? (isArabic ? 'جاري المعالجة...' : 'Processing...')
                      : (isArabic ? 'إضافة الدفعة' : 'Add Payment'),
                ),
              );
            },
          ),
        ];

      case null:
        return [];
    }
  }

  Widget _buildEditSectionWithClose() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.teal[50],
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.teal[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.editPeriod,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal[700]),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showEditSection = false;
                      _activeSectionForButtons = null;
                    });
                  },
                  icon: Icon(Icons.close, color: Colors.teal[600], size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: _buildFinanceEditSection()),
        ],
      ),
    );
  }

  Widget _buildUnscheduledPaymentSectionWithClose() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.payment_outlined, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.unscheduledPayment,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showUnscheduledPaymentSection = false;
                      _activeSectionForButtons = null;
                    });
                  },
                  icon: Icon(Icons.close, color: Colors.blue[600], size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: _buildUnscheduledPaymentEditor()),
        ],
      ),
    );
  }

  Widget _buildPDFActionsSectionWithClose(BuildContext context, AdvanceOnSalaryRequestModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple[50],
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Colors.purple[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.pdfActions,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple[700]),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showPDFActionsSection = false;
                    });
                  },
                  icon: Icon(Icons.close, color: Colors.purple[600], size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: _buildPDFActionsSection(context, request)),
        ],
      ),
    );
  }

  // Detail view methods for employee confirmation and finance acknowledgment
  void _showEmployeeConfirmationDialog(BuildContext context, bool isConfirming) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.employeeConfirmationRequired),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context)!.financeHasEditedPaymentPeriod),
                const SizedBox(height: 16),
                if (_currentRequest.hasPeriodBeenModified) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${AppLocalizations.of(context)!.originalPeriod}: ${_currentRequest.periodInMonths} ${AppLocalizations.of(context)!.months}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${AppLocalizations.of(context)!.updatedPeriod}: ${_currentRequest.updatedPeriod} ${AppLocalizations.of(context)!.months}',
                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blue[700]),
                        ),
                        if (_currentRequest.updatedMonthlyPayment != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${AppLocalizations.of(context)!.newMonthlyPayment}: ${NumberFormat('#,##0.00').format(_currentRequest.updatedMonthlyPayment)} EGP',
                            style: TextStyle(fontWeight: FontWeight.w500, color: Colors.green[700]),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                  _confirmFinanceEdit(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                child: Text(AppLocalizations.of(context)!.confirmFinanceEdit),
              ),
            ],
          ),
    );
  }

  void _showEmployeeCancelConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.cancelFinanceEdit),
            content: Text(AppLocalizations.of(context)!.cancelRequestMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                  _cancelFinanceEdit(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                child: Text(AppLocalizations.of(context)!.cancelFinanceEdit),
              ),
            ],
          ),
    );
  }

  void _acknowledgeEmployeeDecision(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.financeAcknowledgmentRequired),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppLocalizations.of(context)!.employeeHasRespondedToFinanceEdit),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _currentRequest.isEmployeeConfirmed ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _currentRequest.isEmployeeConfirmed ? Colors.green[200]! : Colors.red[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _currentRequest.isEmployeeConfirmed ? Icons.check_circle : Icons.cancel,
                        color: _currentRequest.isEmployeeConfirmed ? Colors.green[600] : Colors.red[600],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _currentRequest.isEmployeeConfirmed
                              ? AppLocalizations.of(context)!.employeeConfirmed
                              : AppLocalizations.of(context)!.employeeCancelled,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: _currentRequest.isEmployeeConfirmed ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
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
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop();
                  final userCode = context.read<UserBloc>().state.user?.id ?? 0;
                  context.read<UserAdvanceOnSalaryRequestsBloc>().add(
                    AcknowledgeEmployeeDecision(_currentRequest.id!, userCode),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                child: Text(AppLocalizations.of(context)!.acknowledgeEmployeeDecision),
              ),
            ],
          ),
    );
  }

  void _confirmFinanceEdit(BuildContext context) {
    final userCode = context.read<UserBloc>().state.user?.id ?? 0;
    context.read<UserAdvanceOnSalaryRequestsBloc>().add(ConfirmFinanceEdit(_currentRequest.id!, userCode));
  }

  void _cancelFinanceEdit(BuildContext context) {
    final userCode = context.read<UserBloc>().state.user?.id ?? 0;
    context.read<UserAdvanceOnSalaryRequestsBloc>().add(CancelFinanceEdit(_currentRequest.id!, userCode));
  }
}

// Employee confirmation and finance acknowledgment methods for card view
void _showEmployeeConfirmationDialog(BuildContext context, bool isConfirming, AdvanceOnSalaryRequestModel request) {
  showDialog(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.employeeConfirmationRequired),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.financeHasEditedPaymentPeriod),
              const SizedBox(height: 16),
              if (request.hasPeriodBeenModified) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${AppLocalizations.of(context)!.originalPeriod}: ${request.periodInMonths} ${AppLocalizations.of(context)!.months}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${AppLocalizations.of(context)!.updatedPeriod}: ${request.updatedPeriod} ${AppLocalizations.of(context)!.months}',
                        style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blue[700]),
                      ),
                      if (request.updatedMonthlyPayment != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${AppLocalizations.of(context)!.newMonthlyPayment}: ${NumberFormat('#,##0.00').format(request.updatedMonthlyPayment)} EGP',
                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.green[700]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final userCode = context.read<UserBloc>().state.user?.id ?? 0;
                context.read<UserAdvanceOnSalaryRequestsBloc>().add(ConfirmFinanceEdit(request.id!, userCode));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: Text(AppLocalizations.of(context)!.confirmFinanceEdit),
            ),
          ],
        ),
  );
}

void _showEmployeeCancelConfirmationDialog(BuildContext context, AdvanceOnSalaryRequestModel request) {
  showDialog(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.cancelFinanceEdit),
          content: Text(AppLocalizations.of(context)!.cancelRequestMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final userCode = context.read<UserBloc>().state.user?.id ?? 0;
                context.read<UserAdvanceOnSalaryRequestsBloc>().add(CancelFinanceEdit(request.id!, userCode));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: Text(AppLocalizations.of(context)!.cancelFinanceEdit),
            ),
          ],
        ),
  );
}

void _acknowledgeEmployeeDecision(BuildContext context, AdvanceOnSalaryRequestModel request) {
  showDialog(
    context: context,
    builder:
        (dialogContext) => AlertDialog(
          title: Text(AppLocalizations.of(context)!.financeAcknowledgmentRequired),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(AppLocalizations.of(context)!.employeeHasRespondedToFinanceEdit),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: request.isEmployeeConfirmed ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: request.isEmployeeConfirmed ? Colors.green[200]! : Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      request.isEmployeeConfirmed ? Icons.check_circle : Icons.cancel,
                      color: request.isEmployeeConfirmed ? Colors.green[600] : Colors.red[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.isEmployeeConfirmed
                            ? AppLocalizations.of(context)!.employeeConfirmed
                            : AppLocalizations.of(context)!.employeeCancelled,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: request.isEmployeeConfirmed ? Colors.green[700] : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
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
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final userCode = context.read<UserBloc>().state.user?.id ?? 0;
                context.read<UserAdvanceOnSalaryRequestsBloc>().add(AcknowledgeEmployeeDecision(request.id!, userCode));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              child: Text(AppLocalizations.of(context)!.acknowledgeEmployeeDecision),
            ),
          ],
        ),
  );
}
