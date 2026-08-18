import 'package:hrms_demo/presentation/widgets/custom_date_picker.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:hrms_demo/core/utils/search_filter_utils.dart';
import 'package:hrms_demo/presentation/employees/widgets/requests_report_helpers.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_bloc.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_event.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_state.dart';
import 'package:hrms_demo/core/constants/department.dart';
import 'dart:async';
import 'dart:math' as math;

class RequestsReportContent extends StatefulWidget {
  final List<dynamic> requests;
  final bool withMultiUser;

  /// When the report is opened for a single specific employee (e.g. from the
  /// employee edit page), pass their UserModel here so segment filtering
  /// ("Made by Employee" / "Made Against Employee") knows whose role to check.
  final UserModel? initialUser;

  const RequestsReportContent({super.key, required this.requests, this.withMultiUser = false, this.initialUser});

  @override
  State<RequestsReportContent> createState() => _RequestsReportContentState();
}

class _RequestsReportContentState extends State<RequestsReportContent> {
  // Track which sections are expanded
  final Map<String, bool> _expandedSections = {
    'leave': false,
    'overtime': false,
    'business_trip': false,
    'missing_punching': false,
    'advance_on_salary': false,
    'hr_letter': false,
    'disciplinary_action': false,
    'investigation': false,
  };

  // Per-section segment selection: 'all' | 'made_by' | 'made_against'
  // DA, Investigation, and Advance on Salary use this; HR Letter always shows flat list.
  // For Advance on Salary, 'made_against' means "made for the employee" (borrower).
  final Map<String, String> _sectionSegment = {
    'disciplinary_action': 'all',
    'investigation': 'all',
    'advance_on_salary': 'all',
  };

  // Per-section status filter (replaces global status filter when set)
  final Map<String, String?> _sectionStatusFilter = {
    'hr_letter': null,
    'disciplinary_action': null,
    'investigation': null,
  };

  // Filter state
  // Date-filter mode: 'effective' filters/sorts by each request's effective date
  // (leave dateFrom, punch date, violationDate, …); 'created_at' uses createdAt.
  String _dateFilterMode = 'effective';
  DateTime? _selectedDateFrom;
  DateTime? _selectedDateTo;
  List<String> _selectedRequestTypes = [];
  String? _selectedRequestStatus;
  List<dynamic> _filteredRequests = [];
  List<dynamic> _allRequests = [];

  // User search state
  final TextEditingController _userSearchController = TextEditingController();
  final FocusNode _userSearchFocusNode = FocusNode();
  List<UserModel> _searchResults = [];
  List<UserModel> _selectedUsers = [];
  bool _showSearchResults = false;
  bool _showSelectedUsers = false;
  late final UsersRepo _usersRepo = context.read<UsersRepo>();

  // Approver name state
  Map<dynamic, List<String>> _approverNames = {};

  // Department filter state
  List<Department> _selectedDepartments = [];
  bool _showDepartmentDropdown = false;
  bool _allDepartmentsSelected = false;

  // Pending employee requests tracking
  final Set<String> _pendingEmployeeIds = {};
  bool _isAddingEmployees = false;

  // Per-employee request cache: employeeId → requests loaded for that employee.
  // Used to rebuild _allRequests correctly when an employee is removed, without
  // having to inspect model-specific fields like requestorCode / employeeCode.
  final Map<String, List<dynamic>> _employeeRequestsCache = {};

  // Scroll controller for back to top functionality
  late ScrollController _scrollController;
  bool _showBackToTop = false;

  // Filter section scroll behavior
  bool _isScrollingUp = false;
  bool _isFilterVisible = true;
  double _filterOffset = 0.0;
  double _lastScrollPosition = 0.0;
  static const double _filterHeight = 200.0; // Approximate filter section height
  static const double _animationThreshold = 100.0; // Threshold for triggering animation

  // Scroll throttling
  Timer? _scrollTimer;

  // Method to fetch approver name with caching
  Future<List<String>> _getApproverName(dynamic approverCode) async {
    if (approverCode == null) {
      return ['N/A'];
    }

    if (approverCode == "hr") {
      return ["الموارد البشرية", "HR"];
    }

    if (approverCode == "finance") {
      return ["المالية", "Finance"];
    }

    if (approverCode is int && _approverNames.containsKey(approverCode)) {
      return _approverNames[approverCode]!;
    }

    if (approverCode is int) {
      try {
        final approver = await _usersRepo.getEmployeeById(approverCode);
        final approverNameList = [approver.arabicName ?? 'N/A', approver.englishName ?? 'N/A'];

        if (mounted) {
          setState(() {
            _approverNames[approverCode] = approverNameList;
          });
        }
        return approverNameList;
      } catch (e) {
        if (mounted) {
          setState(() {
            _approverNames[approverCode] = ['N/A'];
          });
        }
        return ['N/A'];
      }
    }

    return ['N/A'];
  }

  // Preload approver names for better performance
  void _preloadApproverNames(List<dynamic> requests) {
    final approverCodes = <int>{};
    for (final request in requests) {
      // HR Letter, DA, and Investigation don't use the n1/n2 approver chain
      final type = request.requestType?.toString();
      if (type == 'hr_letter' || type == 'disciplinary_action' || type == 'investigation') {
        continue;
      }

      final approverCode =
          request.currentApprover == "n1"
              ? request.n1Code
              : request.currentApprover == "n2"
              ? request.n2Code
              : request.currentApprover == "hr"
              ? "hr"
              : "finance";

      if (approverCode is int && !_approverNames.containsKey(approverCode)) {
        approverCodes.add(approverCode);
      }
    }

    // Load all approver names asynchronously
    for (final code in approverCodes) {
      _getApproverName(code);
    }
  }

  @override
  void initState() {
    super.initState();
    // Ensure _filteredRequests is a mutable list
    _filteredRequests = List<dynamic>.from(widget.requests);
    _allRequests = List<dynamic>.from(widget.requests);

    // Pre-populate the selected user so segment filtering works in single-employee mode
    if (widget.initialUser != null) {
      _selectedUsers = [widget.initialUser!];
    }

    // Initialize scroll controller
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Preload initial approver names
    _preloadApproverNames(_filteredRequests);
  }

  void _onScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 16), () {
      if (!mounted) return;

      // Show back to top button when scrolled down
      final currentPosition = _scrollController.position.pixels;
      final showBackToTop = currentPosition > 500;
      final isScrollingUp = currentPosition < _lastScrollPosition;

      // Only update state if values actually changed
      if (_showBackToTop != showBackToTop ||
          _isScrollingUp != isScrollingUp ||
          _shouldUpdateFilterPosition(currentPosition, isScrollingUp)) {
        setState(() {
          _showBackToTop = showBackToTop;
          _isScrollingUp = isScrollingUp;

          if (isScrollingUp) {
            // Scrolling up - show filter with slide-in animation
            _isFilterVisible = true;
            _filterOffset = 0.0;
          } else if (!isScrollingUp && currentPosition > _filterHeight) {
            // Scrolling down and past filter height - hide filter
            _isFilterVisible = false;
            _filterOffset = -_filterHeight;
          } else if (currentPosition <= _animationThreshold) {
            // Near the top - always show filter
            _isFilterVisible = true;
            _filterOffset = 0.0;
          }
        });
      }

      _lastScrollPosition = currentPosition;
    });
  }

  bool _shouldUpdateFilterPosition(double currentPosition, bool isScrollingUp) {
    if (isScrollingUp && !_isFilterVisible) return true;
    if (!isScrollingUp && currentPosition > _filterHeight && _isFilterVisible) return true;
    if (currentPosition <= _animationThreshold && !_isFilterVisible) return true;
    return false;
  }

  void _scrollToTop() {
    RequestsReportHelpers.scrollToTop(_scrollController);
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _scrollController.dispose();
    _userSearchController.dispose();
    _userSearchFocusNode.dispose();
    _hideDepartmentOverlay();
    super.dispose();
  }

  // User search methods
  // This method searches for users by name or code and shows the first 5 results
  Future<void> _searchUsers(String searchTerm) async {
    if (searchTerm.isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      return;
    }

    setState(() {
      _showSearchResults = true;
    });

    try {
      final results = await _usersRepo.searchEmployees(
        searchTerm,
        locale: Localizations.localeOf(context).languageCode,
      );

      SearchFilterUtils.sortByRelevance(results, searchTerm);

      setState(() {
        _searchResults = results.take(5).toList();
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
      });
    }
  }

  void _addUserToFilter(UserModel user) {
    if (!_selectedUsers.any((u) => u.id == user.id)) {
      setState(() {
        _selectedUsers.add(user);
        _userSearchController.clear();
        _searchResults = [];

        // Add to pending set
        _pendingEmployeeIds.add(user.id!.toString());
      });

      // Hide search results after adding user
      _hideSearchResults();

      // Load requests for this user and apply filters
      context.read<EmployeesBloc>().add(LoadEmployeeRequests(user.id!.toString()));
    }
  }

  void _removeUserFromFilter(UserModel user) {
    setState(() {
      _selectedUsers.removeWhere((u) => u.id == user.id);

      // Remove from pending if it was there
      _pendingEmployeeIds.remove(user.id!.toString());

      // Clear adding flag if no more pending
      if (_pendingEmployeeIds.isEmpty) {
        _isAddingEmployees = false;
      }
    });

    // Rebuild _allRequests from the per-employee cache, excluding the removed
    // employee. Then deduplicate in case cross-requests (e.g. a DA filed by
    // another employee against the removed one) appear in multiple caches.
    _employeeRequestsCache.remove(user.id!.toString());
    _allRequests = _deduplicateRequests([
      ...List<dynamic>.from(widget.requests),
      ..._employeeRequestsCache.values.expand((r) => r),
    ]);
    _applyFilters();
  }

  void _clearUserFilters() {
    setState(() {
      _selectedUsers.clear();
      _employeeRequestsCache.clear();
      _allRequests = List<dynamic>.from(widget.requests);
      _filteredRequests = [];
      _showSelectedUsers = false;

      // Clear pending state
      _pendingEmployeeIds.clear();
      _isAddingEmployees = false;
    });
  }

  // Department methods
  void _toggleDepartmentDropdown() {
    setState(() {
      _showDepartmentDropdown = !_showDepartmentDropdown;
    });
  }

  OverlayEntry? _departmentOverlayEntry;
  final ScrollController _departmentScrollController = ScrollController();

  void _hideDepartmentOverlay() {
    _departmentOverlayEntry?.remove();
    _departmentOverlayEntry = null;
  }

  void _toggleDepartment(Department department) {
    setState(() {
      if (_selectedDepartments.contains(department)) {
        _selectedDepartments.remove(department);
        _allDepartmentsSelected = false;
      } else {
        _selectedDepartments.add(department);
        // Check if all departments are now selected
        if (_selectedDepartments.length == Department.values.length) {
          _allDepartmentsSelected = true;
        }
      }
    });
  }

  void _toggleAllDepartments(bool? value) {
    setState(() {
      if (value == true) {
        _selectedDepartments = List.from(Department.values);
        _allDepartmentsSelected = true;
      } else {
        _selectedDepartments.clear();
        _allDepartmentsSelected = false;
      }
    });
  }

  Future<void> _addDepartmentEmployees() async {
    if (_selectedDepartments.isEmpty) return;

    setState(() {
      _isAddingEmployees = true; // Set loading flag
    });

    try {
      // Get all employees from selected departments
      List<UserModel> departmentEmployees = [];

      for (Department dept in _selectedDepartments) {
        // Try both English and Arabic department names
        final englishDept = dept.getEnglishText();
        final arabicDept = dept.getArabicText();

        // Get employees by English department name
        final englishEmployees = await _usersRepo.searchEmployeesByDepartment(
          englishDept,
          locale: Localizations.localeOf(context).languageCode,
        );

        // Get employees by Arabic department name
        final arabicEmployees = await _usersRepo.searchEmployeesByDepartment(
          arabicDept,
          locale: Localizations.localeOf(context).languageCode,
        );

        // Combine and remove duplicates
        final allEmployees = [...englishEmployees, ...arabicEmployees];
        final uniqueEmployees = <UserModel>[];

        for (final employee in allEmployees) {
          if (!uniqueEmployees.any((e) => e.id == employee.id)) {
            uniqueEmployees.add(employee);
          }
        }

        departmentEmployees.addAll(uniqueEmployees);
      }

      // Add all department employees to selected users (avoiding duplicates)
      for (final employee in departmentEmployees) {
        if (!_selectedUsers.any((u) => u.id == employee.id)) {
          _selectedUsers.add(employee);

          // Add to pending set BEFORE dispatching event
          _pendingEmployeeIds.add(employee.id!.toString());

          // Load requests for this user
          context.read<EmployeesBloc>().add(LoadEmployeeRequests(employee.id!.toString()));
        }
      }

      setState(() {
        _showDepartmentDropdown = false;
      });
      _hideDepartmentOverlay();

      // Apply filters after adding department employees
      _applyFilters();
    } catch (e) {
      setState(() {
        _isAddingEmployees = false; // Clear loading flag on error
        _pendingEmployeeIds.clear(); // Clear pending on error
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading department employees: $e'), backgroundColor: Colors.red));
      }
    }
  }

  void _clearDepartmentFilters() {
    setState(() {
      _selectedDepartments.clear();
      _allDepartmentsSelected = false;
    });
  }

  void _hideSearchResults() {
    setState(() {
      _showSearchResults = false;
    });
  }

  Widget _buildUserSearchField() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Search input field
            Container(
              width: 350,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _userSearchController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchByNameOrCode,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon:
                            _userSearchController.text.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    _userSearchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _showSearchResults = false;
                                    });
                                  },
                                )
                                : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          setState(() {
                            _searchResults = [];
                          });
                          _hideSearchResults();
                        } else {
                          _searchUsers(value);
                        }
                      },
                    ),
                  ),
                  // Arrow button with user count
                  Container(
                    width: 60,
                    height: 48,
                    decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey[300]!))),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _showSelectedUsers = !_showSelectedUsers;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_selectedUsers.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue[600],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_selectedUsers.length}',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          const SizedBox(width: 4),
                          Icon(
                            _showSelectedUsers ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Stack(
                  children: [
                    if (_showSelectedUsers && _selectedUsers.isNotEmpty) ...[
                      Center(
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 350,
                            height: 130,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: Colors.white,
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${AppLocalizations.of(context)!.filterByUser}:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: _clearUserFilters,
                                        child: Text(
                                          AppLocalizations.of(context)!.clearFilters,
                                          style: TextStyle(fontSize: 11, color: Colors.blue[600]),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children:
                                        _selectedUsers.map((user) {
                                          final displayName =
                                              Localizations.localeOf(context).languageCode == 'ar'
                                                  ? (user.arabicName ?? user.englishName ?? 'Unknown')
                                                  : (user.englishName ?? user.arabicName ?? 'Unknown');
                                          final displayCode = user.id?.toString() ?? 'N/A';

                                          return Chip(
                                            label: Text(
                                              '$displayName ($displayCode)',
                                              style: const TextStyle(fontSize: 11),
                                            ),
                                            deleteIcon: const Icon(Icons.close, size: 16),
                                            onDeleted: () => _removeUserFromFilter(user),
                                            backgroundColor: Colors.blue[100],
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                    // Search results dropdown
                    if (_showSearchResults && _searchResults.isNotEmpty)
                      Center(
                        child: Container(
                          width: 350,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[300]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children:
                                _searchResults.map((user) {
                                  final displayName =
                                      Localizations.localeOf(context).languageCode == 'ar'
                                          ? (user.arabicName ?? user.englishName ?? 'Unknown')
                                          : (user.englishName ?? user.arabicName ?? 'Unknown');
                                  final displayCode = user.id?.toString() ?? 'N/A';

                                  return Material(
                                    color: Colors.transparent,
                                    child: ListTile(
                                      dense: true,
                                      title: Text(
                                        displayName,
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                      ),
                                      subtitle: Text(
                                        'Code: $displayCode',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                      onTap: () => _addUserToFilter(user),
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // Selected users display
          ],
        ),

        const SizedBox(width: 20),

        // Department Dropdown
        Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 350,
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: InkWell(
                    onTap: _toggleDepartmentDropdown,
                    child: Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(Icons.business, size: 20, color: Colors.grey[600]),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedDepartments.isEmpty
                                        ? AppLocalizations.of(context)!.selectDepartments
                                        : '${_selectedDepartments.length} ${AppLocalizations.of(context)!.departmentsSelected}',
                                    style: TextStyle(
                                      color: _selectedDepartments.isEmpty ? Colors.grey[500] : Colors.black,
                                      fontSize: 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey[300]!))),
                          child: Icon(
                            _showDepartmentDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_showDepartmentDropdown)
              Container(
                width: 350,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with actions
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(4),
                          topRight: Radius.circular(4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!.selectDepartments,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          if (_selectedDepartments.isNotEmpty) ...[
                            TextButton(
                              onPressed: _clearDepartmentFilters,
                              child: Text(
                                AppLocalizations.of(context)!.clear,
                                style: TextStyle(fontSize: 12, color: Colors.red[600]),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          ElevatedButton(
                            onPressed:
                                _selectedDepartments.isNotEmpty && !_isAddingEmployees ? _addDepartmentEmployees : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: const Size(0, 32),
                            ),
                            child:
                                _isAddingEmployees
                                    ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(context)!.addingEmployees,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    )
                                    : Text(
                                      AppLocalizations.of(context)!.addEmployees,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                          ),
                        ],
                      ),
                    ),

                    // Department list
                    Container(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: SingleChildScrollView(
                        controller: _departmentScrollController,
                        child: Column(
                          children: [
                            // Select All checkbox section
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
                              child: InkWell(
                                onTap: () => _toggleAllDepartments(!_allDepartmentsSelected),
                                child: Row(
                                  children: [
                                    SizedBox(width: 4),
                                    Checkbox(
                                      value: _allDepartmentsSelected,
                                      onChanged: _toggleAllDepartments,
                                      activeColor: Colors.blue[600],
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      Localizations.localeOf(context).languageCode == 'ar'
                                          ? 'تحديد الكل'
                                          : 'Select All',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Department options
                            Column(
                              children:
                                  Department.values.map((dept) {
                                    final isSelected = _selectedDepartments.contains(dept);
                                    final displayName =
                                        Localizations.localeOf(context).languageCode == 'ar'
                                            ? dept.getArabicText()
                                            : dept.getEnglishText();

                                    return ListTile(
                                      dense: true,
                                      leading: Checkbox(
                                        value: isSelected,
                                        onChanged: (value) => _toggleDepartment(dept),
                                        activeColor: Colors.blue[600],
                                      ),
                                      title: Text(
                                        displayName,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          color: isSelected ? Colors.blue[700] : Colors.black87,
                                        ),
                                      ),
                                      onTap: () => _toggleDepartment(dept),
                                    );
                                  }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  /// Removes duplicate requests from [requests] by composite key
  /// `requestType_id`. This is needed because a cross-request (e.g. a DA filed
  /// by B against X) can appear in both B's and X's loaded request lists.
  List<dynamic> _deduplicateRequests(List<dynamic> requests) {
    final seen = <String>{};
    return requests.where((r) {
      final key = '${r.requestType}_${r.id}';
      return seen.add(key);
    }).toList();
  }

  // Apply filters to the current filtered requests (date, type, status)
  // User filtering is handled separately in _loadRequestsForUsers
  void _applyFilters() {
    setState(() {
      // Apply basic filters (date, type, status) to current filtered requests
      _filteredRequests = RequestsReportHelpers.applyFilters(
        _allRequests,
        _selectedDateFrom,
        _selectedDateTo,
        _selectedRequestTypes,
        _selectedRequestStatus,
        null, // User filter is already applied
        _dateFilterMode,
      );
    });

    // Preload approver names for the filtered results
    _preloadApproverNames(_filteredRequests);
  }

  void _showRequestTypeMultiSelect(BuildContext context) {
    RequestsReportHelpers.showRequestTypeMultiSelect(context, _selectedRequestTypes, () {
      setState(() {});
      _applyFilters();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedDateFrom = null;
      _selectedDateTo = null;
      _selectedRequestTypes = [];
      _selectedRequestStatus = null;
      _dateFilterMode = 'effective';
    });
    _applyFilters();
  }

  void _exportToExcel() {
    // Rebuild per section so each type respects its own per-type status override
    // (the 'all' sentinel and _sectionStatusFilter are handled by _getRequestsForSection).
    final exportRequests =
        const [
            'leave',
            'overtime',
            'business_trip',
            'missing_punching',
            'advance_on_salary',
            'hr_letter',
            'disciplinary_action',
            'investigation',
          ].expand(_getEffectiveRequestsForSection).toList()
          ..sort((a, b) {
            final aDate = RequestsReportHelpers.getRequestDate(a, dateMode: _dateFilterMode);
            final bDate = RequestsReportHelpers.getRequestDate(b, dateMode: _dateFilterMode);
            if (aDate == null) return 1;
            if (bDate == null) return -1;
            return aDate.compareTo(bDate);
          });
    final csvData = RequestsReportHelpers.generateCSVData(exportRequests, context);
    final csvContent = RequestsReportHelpers.convertToCSV(csvData, context);

    RequestsReportHelpers.exportToExcel(
      csvData,
      csvContent,
      context,
      (csvContent) => RequestsReportHelpers.showCSVDialog(context, csvContent),
    );
  }

  void _exportToExcelByEmployee() {
    // Single-employee context: fall back to the standard single-workbook export.
    // Use widget flag + selected users — NOT csvData names, which are misleading
    // for DA (name = subject) and Investigation (name = comma-joined subjects).
    if (!widget.withMultiUser || _selectedUsers.length == 1) {
      _exportToExcel();
      return;
    }

    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Build: typeKey → employeeName → List<rawRequest>
    // Grouping mirrors _applySegmentFilter so DA/Investigation respect
    // the active segment (made_by / made_against / all).
    const typeKeys = [
      'leave',
      'overtime',
      'business_trip',
      'missing_punching',
      'advance_on_salary',
      'hr_letter',
      'disciplinary_action',
      'investigation',
    ];

    final Map<String, Map<String, List<dynamic>>> byTypeByEmployee = {};

    for (final typeKey in typeKeys) {
      final typeRequests = _getEffectiveRequestsForSection(typeKey)..sort((a, b) {
        final aDate = RequestsReportHelpers.getRequestDate(a, dateMode: _dateFilterMode);
        final bDate = RequestsReportHelpers.getRequestDate(b, dateMode: _dateFilterMode);
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });
      if (typeRequests.isEmpty) continue;

      final Map<String, List<dynamic>> byEmployee = {};

      if (_selectedUsers.isNotEmpty) {
        // Use selected users as grouping keys; assign requests via ownership check.
        for (final user in _selectedUsers) {
          final userRequests = typeRequests.where((req) => _reqBelongsToUser(req, user.id, typeKey)).toList();
          if (userRequests.isEmpty) continue;
          final name =
              isArabic
                  ? (user.arabicName ?? user.englishName ?? 'Unknown')
                  : (user.englishName ?? user.arabicName ?? 'Unknown');
          byEmployee[name] = userRequests;
        }
      } else {
        // All-employees mode: extract primary employee name from each request.
        for (final req in typeRequests) {
          final name = _primaryEmployeeName(req, typeKey, isArabic);
          byEmployee.putIfAbsent(name, () => []).add(req);
        }
      }

      if (byEmployee.isNotEmpty) byTypeByEmployee[typeKey] = byEmployee;
    }

    // If only 1 unique employee resolved across all types, still fall back.
    final allNames = byTypeByEmployee.values.expand((m) => m.keys).toSet();
    if (allNames.length <= 1) {
      _exportToExcel();
      return;
    }

    // Generate csvData per employee per type — each call uses the correct
    // column set for that type.
    final Map<String, Map<String, List<Map<String, dynamic>>>> csvGrouped = {};
    for (final typeEntry in byTypeByEmployee.entries) {
      final empCsvMap = <String, List<Map<String, dynamic>>>{};
      for (final empEntry in typeEntry.value.entries) {
        empCsvMap[empEntry.key] = RequestsReportHelpers.generateCSVData(empEntry.value, context);
      }
      csvGrouped[typeEntry.key] = empCsvMap;
    }

    final count = csvGrouped.length;
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.downloadingFiles(count))));
    }

    RequestsReportHelpers.exportToExcelGroupedByEmployee(
      csvGrouped,
      context,
      (csv) => RequestsReportHelpers.showCSVDialog(context, csv),
    );
  }

  /// Returns true if [req] belongs to [userId] for [typeKey] given the active segment.
  /// Mirrors _applySegmentFilter ownership logic.
  bool _reqBelongsToUser(dynamic req, int? userId, String typeKey) {
    if (userId == null) return false;
    final segment = _sectionSegment[typeKey] ?? 'all';
    switch (typeKey) {
      case 'disciplinary_action':
        final isRequestor = req.requestorCode == userId;
        final isTarget = req.employeeCode == userId;
        if (segment == 'made_by') return isRequestor;
        if (segment == 'made_against') return isTarget;
        return isRequestor || isTarget;
      case 'investigation':
        final isRequestor = req.requestorCode == userId;
        final codes = (req.employeeCodes as List?)?.cast<int>() ?? <int>[];
        final isTarget = codes.contains(userId);
        if (segment == 'made_by') return isRequestor;
        if (segment == 'made_against') return isTarget;
        return isRequestor || isTarget;
      case 'advance_on_salary':
        // 'made_against' segment = made *for* the employee (borrower).
        final isRequestor = req.requestorCode == userId;
        final isTarget = req.borrowerCode == userId;
        if (segment == 'made_by') return isRequestor;
        if (segment == 'made_against') return isTarget;
        return isRequestor || isTarget;
      case 'hr_letter':
        return req.employeeCode == userId;
      default:
        return req.userId == userId;
    }
  }

  /// Extracts the display name of the primary employee for grouping in
  /// all-employees mode (no specific users selected).
  String _primaryEmployeeName(dynamic req, String typeKey, bool isArabic) {
    switch (typeKey) {
      case 'disciplinary_action':
        final segment = _sectionSegment[typeKey] ?? 'all';
        if (segment == 'made_against') {
          return isArabic
              ? (req.employeeArabicName ?? req.employeeEnglishName ?? 'Unknown')
              : (req.employeeEnglishName ?? req.employeeArabicName ?? 'Unknown');
        }
        return isArabic
            ? (req.requestorArabicName ?? req.requestorEnglishName ?? 'Unknown')
            : (req.requestorEnglishName ?? req.requestorArabicName ?? 'Unknown');
      case 'investigation':
        // Requestor is the single stable identity per Investigation.
        return isArabic
            ? (req.requestorArabicName ?? req.requestorEnglishName ?? 'Unknown')
            : (req.requestorEnglishName ?? req.requestorArabicName ?? 'Unknown');
      case 'advance_on_salary':
        final segment = _sectionSegment[typeKey] ?? 'all';
        // 'made_against' segment = made *for* the employee (borrower).
        if (segment == 'made_against') {
          return isArabic
              ? (req.borrowerArabicName ?? req.borrowerEnglishName ?? 'Unknown')
              : (req.borrowerEnglishName ?? req.borrowerArabicName ?? 'Unknown');
        }
        return isArabic
            ? (req.requestorArabicName ?? req.requestorEnglishName ?? 'Unknown')
            : (req.requestorEnglishName ?? req.requestorArabicName ?? 'Unknown');
      case 'hr_letter':
        return isArabic
            ? (req.employeeArabicName ?? req.employeeEnglishName ?? 'Unknown')
            : (req.employeeEnglishName ?? req.employeeArabicName ?? 'Unknown');
      default:
        return isArabic
            ? (req.userArabicName ?? req.userEnglishName ?? 'Unknown')
            : (req.userEnglishName ?? req.userArabicName ?? 'Unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Categorize requests by type using filtered requests
    final leaveRequests = _filteredRequests.where((r) => r.requestType == 'leave').toList();
    final overtimeRequests = _filteredRequests.where((r) => r.requestType == 'overtime').toList();
    final businessTripRequests = _filteredRequests.where((r) => r.requestType == 'business_trip').toList();
    final missingPunchRequests = _filteredRequests.where((r) => r.requestType == 'missing_punching').toList();
    final advanceOnSalaryRequests = _filteredRequests.where((r) => r.requestType == 'advance_on_salary').toList();

    return MainLayout(
      title: AppLocalizations.of(context)!.employeeRequestsReport,
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, viewport) {
            // Make the page at least 1000, or expand to the viewport if wider
            final pageWidth = viewport.maxWidth < 1110 ? 1110.0 : viewport.maxWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: BlocListener<EmployeesBloc, EmployeesState>(
                listener: (context, state) {
                  // Check if requests were loaded (even if empty)
                  if (state.status == EmployeesStatus.requestsLoaded) {
                    final employeeId = state.userCode.toString();

                    // Only process if this employee is in our pending set
                    if (_pendingEmployeeIds.contains(employeeId)) {
                      setState(() {
                        // Only add requests if there are any
                        if (state.employeeRequests.isNotEmpty) {
                          final newRequests = List<dynamic>.from(state.employeeRequests);
                          // Cache per-employee so removal can rebuild _allRequests precisely
                          _employeeRequestsCache[employeeId] = newRequests;
                          _allRequests = _deduplicateRequests([..._allRequests, ...newRequests]);
                        }

                        // Remove the specific employee that completed
                        _pendingEmployeeIds.remove(employeeId);

                        // If no more pending, clear the adding employees flag
                        if (_pendingEmployeeIds.isEmpty) {
                          _isAddingEmployees = false;
                        }
                      });

                      // Only apply filters if we actually added new requests
                      if (state.employeeRequests.isNotEmpty) {
                        _applyFilters();
                      }
                    }
                  }

                  // Handle error case - remove the specific employee that errored
                  if (state.status == EmployeesStatus.error) {
                    final employeeId = state.userCode.toString();

                    if (_pendingEmployeeIds.contains(employeeId)) {
                      setState(() {
                        _pendingEmployeeIds.remove(employeeId);

                        if (_pendingEmployeeIds.isEmpty) {
                          _isAddingEmployees = false;
                        }
                      });
                    }
                  }
                },
                child: BlocBuilder<EmployeesBloc, EmployeesState>(
                  builder: (context, employeesState) {
                    // Use pending set to track loading state - shows until ALL employees' requests load
                    final isLoadingRequests = _pendingEmployeeIds.isNotEmpty;

                    return ConstrainedBox(
                      // Guarantees at least pageWidth (=> 1000 min)
                      constraints: BoxConstraints(minWidth: pageWidth),
                      child: SizedBox(
                        width: pageWidth,
                        child: Stack(
                          children: [
                            // Main content with dynamic padding based on filter visibility
                            SingleChildScrollView(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(top: 220.0, left: 16.0, right: 16.0, bottom: 16.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey[25],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Filter Summary
                                    _buildFilterSummary(context, isLoadingRequests),
                                    // Summary Cards
                                    RepaintBoundary(child: _buildSummarySection(context)),
                                    const SizedBox(height: 24),
                                    if (_selectedRequestTypes.contains('leave') || _selectedRequestTypes.isEmpty) ...[
                                      RepaintBoundary(
                                        child: _buildRequestTypeSection(
                                          context,
                                          AppLocalizations.of(context)!.leaveRequests,
                                          leaveRequests,
                                          Icons.back_hand_outlined,
                                          Colors.blue,
                                          'leave',
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    if (_selectedRequestTypes.contains('overtime') ||
                                        _selectedRequestTypes.isEmpty) ...[
                                      RepaintBoundary(
                                        child: _buildRequestTypeSection(
                                          context,
                                          AppLocalizations.of(context)!.overtimeRequests,
                                          overtimeRequests,
                                          Icons.access_time,
                                          Colors.orange,
                                          'overtime',
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    if (_selectedRequestTypes.contains('business_trip') ||
                                        _selectedRequestTypes.isEmpty) ...[
                                      RepaintBoundary(
                                        child: _buildRequestTypeSection(
                                          context,
                                          AppLocalizations.of(context)!.businessTripRequests,
                                          businessTripRequests,
                                          Icons.mode_of_travel_outlined,
                                          Colors.green,
                                          'business_trip',
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    if (_selectedRequestTypes.contains('missing_punching') ||
                                        _selectedRequestTypes.isEmpty) ...[
                                      RepaintBoundary(
                                        child: _buildRequestTypeSection(
                                          context,
                                          AppLocalizations.of(context)!.missingPunchRequests,
                                          missingPunchRequests,
                                          Icons.fingerprint,
                                          Colors.purple,
                                          'missing_punching',
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    if (_selectedRequestTypes.contains('advance_on_salary') ||
                                        _selectedRequestTypes.isEmpty) ...[
                                      RepaintBoundary(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            _buildSegmentBar(context, 'advance_on_salary', Colors.teal),
                                            _buildRequestTypeSection(
                                              context,
                                              AppLocalizations.of(context)!.advanceOnSalaryRequests,
                                              _applySegmentFilter(advanceOnSalaryRequests, 'advance_on_salary'),
                                              Icons.account_balance_wallet_outlined,
                                              Colors.teal,
                                              'advance_on_salary',
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    if (_selectedRequestTypes.contains('hr_letter') ||
                                        _selectedRequestTypes.isEmpty) ...[
                                      RepaintBoundary(
                                        child: _buildEnhancedSection(
                                          context: context,
                                          title: AppLocalizations.of(context)!.hrLetterRequests,
                                          typeKey: 'hr_letter',
                                          icon: Icons.article_outlined,
                                          color: Colors.indigo,
                                          withSegment: false,
                                          perTypeStatusOptions: const [
                                            'pending',
                                            'acknowledged',
                                            'completed',
                                            'declined',
                                            'cancelled',
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    if (_selectedRequestTypes.contains('disciplinary_action') ||
                                        _selectedRequestTypes.isEmpty) ...[
                                      RepaintBoundary(
                                        child: _buildEnhancedSection(
                                          context: context,
                                          title: AppLocalizations.of(context)!.disciplinaryActionRequests,
                                          typeKey: 'disciplinary_action',
                                          icon: Icons.gavel_outlined,
                                          color: Colors.deepOrange,
                                          withSegment: true,
                                          perTypeStatusOptions: const [
                                            'pending',
                                            'approved',
                                            'on_hold',
                                            'converted_to_investigation',
                                            'declined',
                                            'cancelled',
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                    if (_selectedRequestTypes.contains('investigation') ||
                                        _selectedRequestTypes.isEmpty)
                                      RepaintBoundary(
                                        child: _buildEnhancedSection(
                                          context: context,
                                          title: AppLocalizations.of(context)!.investigations,
                                          typeKey: 'investigation',
                                          icon: Icons.manage_search_outlined,
                                          color: Colors.brown,
                                          withSegment: true,
                                          perTypeStatusOptions: const ['pending', 'closed', 'cancelled'],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Filter section overlay - animated based on scroll
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              top: _filterOffset,
                              left: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: _buildFilterSection(),
                              ),
                            ),

                            // Back to top button
                            if (_showBackToTop)
                              Positioned(
                                bottom: 20,
                                right: 20,
                                child: AnimatedOpacity(
                                  opacity: _showBackToTop ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: FloatingActionButton(
                                    onPressed: _scrollToTop,
                                    backgroundColor: Colors.blue[600],
                                    foregroundColor: Colors.white,
                                    elevation: 8,
                                    child: const Icon(Icons.keyboard_arrow_up, size: 28),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSelectedUsers = false;
          _showDepartmentDropdown = false;
        });
      },
      child: Stack(
        children: [
          // Main filter content
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_list, size: 24, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.filterRequests,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                    ),
                    const Spacer(),
                    // Export Button
                    PopupMenuButton<String>(
                      enabled: _effectiveTotal > 0,
                      onSelected: (value) {
                        if (value == 'by_type') _exportToExcel();
                        if (value == 'by_employee') _exportToExcelByEmployee();
                      },
                      itemBuilder:
                          (ctx) => [
                            PopupMenuItem(
                              value: 'by_type',
                              child: Row(
                                children: [
                                  const Icon(Icons.table_chart_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text(AppLocalizations.of(ctx)!.exportByRequestType),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'by_employee',
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outlined, size: 18),
                                  const SizedBox(width: 8),
                                  Text(AppLocalizations.of(ctx)!.exportByEmployee),
                                ],
                              ),
                            ),
                          ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: _effectiveTotal > 0 ? Colors.green[600] : Colors.grey[400],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.download, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              '${AppLocalizations.of(context)!.exportToXlsx} ($_effectiveTotal)',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                Row(
                  children: [
                    // Date Range Filter
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.filterByDateRange,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _CustomDateRangePicker(
                                  selectedDateFrom: _selectedDateFrom,
                                  selectedDateTo: _selectedDateTo,
                                  onDateFromChanged: (date) {
                                    setState(() {
                                      _selectedDateFrom = date;
                                    });
                                    _applyFilters();
                                  },
                                  onDateToChanged: (date) {
                                    setState(() {
                                      _selectedDateTo = date;
                                    });
                                    _applyFilters();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              SizedBox(width: 200, child: _buildDateModeToggle(context)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Request Type Filter
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              AppLocalizations.of(context)!.filterByRequestType,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            height: 48,
                            child: InkWell(
                              onTap: () => _showRequestTypeMultiSelect(context),
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    // Selected types display with proper scrolling
                                    if (_selectedRequestTypes.isNotEmpty) ...[
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              physics: const BouncingScrollPhysics(),
                                              child: Row(
                                                children:
                                                    _selectedRequestTypes.map((type) {
                                                      return Padding(
                                                        padding: const EdgeInsets.only(right: 8),
                                                        child: Chip(
                                                          label: Text(
                                                            RequestsReportHelpers.getRequestTypeDisplayName(
                                                              type,
                                                              context,
                                                            ),
                                                            style: const TextStyle(fontSize: 12),
                                                          ),
                                                          deleteIcon: const Icon(Icons.close, size: 16),
                                                          onDeleted: () {
                                                            setState(() {
                                                              _selectedRequestTypes.remove(type);
                                                            });
                                                            _applyFilters();
                                                          },
                                                          backgroundColor: Colors.blue[100],
                                                        ),
                                                      );
                                                    }).toList(),
                                              ),
                                            ),
                                            // Left fade indicator when scrolled to the right
                                            if (Localizations.localeOf(context).languageCode == "ar")
                                              Positioned(
                                                left: 0,
                                                top: 0,
                                                bottom: 0,
                                                child: Container(
                                                  width: 20,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.white,
                                                        Colors.white.withOpacity(0.8),
                                                        Colors.white.withOpacity(0.0),
                                                      ],
                                                      begin: Alignment.centerLeft,
                                                      end: Alignment.centerRight,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            // Right fade indicator when content overflows
                                            if (Localizations.localeOf(context).languageCode == "en")
                                              Positioned(
                                                right: 0,
                                                top: 0,
                                                bottom: 0,
                                                child: Container(
                                                  width: 20,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Colors.white.withOpacity(0.0),
                                                        Colors.white.withOpacity(0.8),
                                                        Colors.white,
                                                      ],
                                                      begin: Alignment.centerLeft,
                                                      end: Alignment.centerRight,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      Expanded(
                                        child: Text(
                                          AppLocalizations.of(context)!.allTypes,
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                      ),
                                    ],
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Request Status Filter
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.filterByRequestStatus,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 48, // Fixed height to match other filters
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedRequestStatus,
                              hint: const Text('All Statuses', style: TextStyle(fontSize: 14)),
                              isExpanded: true,
                              underline: const SizedBox(),
                              items: [
                                DropdownMenuItem<String>(
                                  value: null,
                                  child: Text(AppLocalizations.of(context)!.allStatuses),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'pending',
                                  child: Text(AppLocalizations.of(context)!.pendingStatus),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'approved',
                                  child: Text(AppLocalizations.of(context)!.approvedStatus),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'declined',
                                  child: Text(AppLocalizations.of(context)!.declinedStatus),
                                ),
                                DropdownMenuItem<String>(
                                  value: 'cancelled',
                                  child: Text(AppLocalizations.of(context)!.cancelledStatus),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedRequestStatus = value;
                                });
                                _applyFilters();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    Padding(
                      padding: const EdgeInsets.only(top: 25),
                      child: TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear),
                        label: Text(AppLocalizations.of(context)!.clearFilters),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // User search field positioned on top and centered
          if (widget.withMultiUser)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(child: Container(margin: const EdgeInsets.all(8), child: _buildUserSearchField())),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSummary(BuildContext context, bool isLoading) {
    if (_selectedDateFrom != null ||
        _selectedDateTo != null ||
        _selectedRequestTypes.isNotEmpty ||
        _selectedRequestStatus != null ||
        _selectedUsers.isNotEmpty ||
        (isLoading && _selectedUsers.isNotEmpty)) {
      return Column(
        children: [
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
                Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.showingRequests(_effectiveTotal, _loadedTotal),
                        style: TextStyle(color: Colors.blue[800], fontSize: 14, fontWeight: FontWeight.w500),
                      ),

                      // Loading indicator
                      if (isLoading && _selectedUsers.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              AppLocalizations.of(context)!.loadingEmployeeRequests,
                              style: TextStyle(
                                color: Colors.blue[600],
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Filtered by users
                      if (_selectedUsers.isNotEmpty)
                        Text(
                          '${AppLocalizations.of(context)!.filteredBy} ${_selectedUsers.length} ${_selectedUsers.length == 1 ? AppLocalizations.of(context)!.employee : AppLocalizations.of(context)!.employeesWithoutAl}',
                          style: TextStyle(color: Colors.blue[600], fontSize: 12, fontWeight: FontWeight.w400),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSummarySection(BuildContext context) {
    final statusCounts = RequestsReportHelpers.calculateStatusCounts(_effectiveRequests);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, size: 28, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.overallSummary,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue[800]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    AppLocalizations.of(context)!.totalRequests,
                    _effectiveTotal.toString(),
                    Icons.list_alt,
                    Colors.blue[600]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    AppLocalizations.of(context)!.pending,
                    (statusCounts['pending'] ?? 0).toString(),
                    Icons.hourglass_top,
                    Colors.orange[600]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    AppLocalizations.of(context)!.approved,
                    (statusCounts['approved'] ?? 0).toString(),
                    Icons.check_circle,
                    Colors.green[600]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    AppLocalizations.of(context)!.declined,
                    (statusCounts['declined'] ?? 0).toString(),
                    Icons.cancel,
                    Colors.red[600]!,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    AppLocalizations.of(context)!.cancelledStatus,
                    (statusCounts['cancelled'] ?? 0).toString(),
                    Icons.block,
                    Colors.grey[600]!,
                  ),
                ),
                if ((statusCounts['other'] ?? 0) > 0) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      AppLocalizations.of(context)!.other,
                      (statusCounts['other'] ?? 0).toString(),
                      Icons.more_horiz,
                      Colors.blueGrey[400]!,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 8),
          Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTypeSection(
    BuildContext context,
    String title,
    List<dynamic> requests,
    IconData icon,
    Color color,
    String requestType,
  ) {
    // Calculate status counts for this request type
    final statusCounts = RequestsReportHelpers.calculateStatusCounts(requests);
    final isExpanded = _expandedSections[requestType] ?? false;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 4))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 24, color: color),
                  const SizedBox(width: 12),
                  Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      '${requests.length}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            // Status Summary Row
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if ((statusCounts['pending'] ?? 0) > 0)
                    _buildStatusChip(AppLocalizations.of(context)!.pending, statusCounts['pending']!, Colors.orange),
                  if ((statusCounts['approved'] ?? 0) > 0)
                    _buildStatusChip(AppLocalizations.of(context)!.approved, statusCounts['approved']!, Colors.green),
                  if ((statusCounts['declined'] ?? 0) > 0)
                    _buildStatusChip(AppLocalizations.of(context)!.declined, statusCounts['declined']!, Colors.red),
                  if ((statusCounts['cancelled'] ?? 0) > 0)
                    _buildStatusChip(
                      AppLocalizations.of(context)!.cancelledStatus,
                      statusCounts['cancelled']!,
                      Colors.grey,
                    ),
                  if ((statusCounts['other'] ?? 0) > 0)
                    _buildStatusChip(AppLocalizations.of(context)!.other, statusCounts['other']!, Colors.blueGrey),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildRequestsList(requests, isExpanded, color, context),
            ),

            // Show More/Less Button
            if (requests.length > 5) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _expandedSections[requestType] = !isExpanded;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isExpanded ? 'Show Less' : 'Show More',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                      Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16),
                    ],
                  ),
                ),
              ),
            ],

            // Show remaining count when not expanded
            if (!isExpanded && requests.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  AppLocalizations.of(context)!.andMoreRequests(requests.length - 5),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Enhanced section helpers (HR Letter / DA / Investigation) ───────────

  /// Returns requests for a section, applying the per-type status filter
  /// in place of the global status filter when one is set.
  List<dynamic> _getRequestsForSection(String typeKey) {
    final perTypeStatus = _sectionStatusFilter[typeKey];
    if (perTypeStatus == null) {
      // Inherit global filter — use already-filtered list
      return _filteredRequests.where((r) => r.requestType == typeKey).toList();
    }
    // 'all' sentinel = explicit override: show every status ignoring global filter.
    // Any other value = specific per-type status filter.
    return RequestsReportHelpers.applyFilters(
      _allRequests,
      _selectedDateFrom,
      _selectedDateTo,
      [typeKey],
      perTypeStatus == 'all' ? null : perTypeStatus,
      _selectedUsers.isNotEmpty ? _selectedUsers : null,
      _dateFilterMode,
    );
  }

  /// Returns the fully-filtered list for a section: status filter + segment filter.
  /// This is what the UI displays and what the export should include.
  List<dynamic> _getEffectiveRequestsForSection(String typeKey) {
    final base = _getRequestsForSection(typeKey);
    if (typeKey == 'disciplinary_action' || typeKey == 'investigation' || typeKey == 'advance_on_salary') {
      return _applySegmentFilter(base, typeKey);
    }
    return base;
  }

  /// The single source of truth for all currently-displayed requests.
  /// Non-segment types come straight from [_filteredRequests] so no request type
  /// is ever dropped by a hardcoded list. DA and Investigation are rebuilt via
  /// [_applySegmentFilter] so the active segment selection is respected.
  List<dynamic> get _effectiveRequests {
    const segmentTypes = {'disciplinary_action', 'investigation', 'advance_on_salary'};
    final nonSegment = _filteredRequests.where((r) => !segmentTypes.contains(r.requestType)).toList();
    final da = _applySegmentFilter(
      _filteredRequests.where((r) => r.requestType == 'disciplinary_action').toList(),
      'disciplinary_action',
    );
    final investigation = _applySegmentFilter(
      _filteredRequests.where((r) => r.requestType == 'investigation').toList(),
      'investigation',
    );
    final advance = _applySegmentFilter(
      _filteredRequests.where((r) => r.requestType == 'advance_on_salary').toList(),
      'advance_on_salary',
    );
    return [...nonSegment, ...da, ...investigation, ...advance];
  }

  int get _effectiveTotal => _effectiveRequests.length;

  /// Denominator for the "showing X of Y" summary: the number of loaded
  /// requests that actually belong to the selected employee(s), using the same
  /// role rules the sections use (segment-independent). This keeps X == Y when
  /// no filters are applied. Notably it excludes advance-on-salary records
  /// loaded only because the employee manages the borrower (he is neither the
  /// requestor nor the borrower) — those never appear in any section.
  int get _loadedTotal {
    if (!widget.withMultiUser) return widget.requests.length;
    if (_selectedUsers.isEmpty) return _allRequests.length;
    return _allRequests.where(_reqOwnedByAnySelected).length;
  }

  /// True if [r] belongs to any selected employee under the union of its roles
  /// (ignores the active segment). Mirrors the per-type ownership in
  /// [_reqBelongsToUser] but without the made_by / made_against narrowing.
  bool _reqOwnedByAnySelected(dynamic r) {
    final ids = _selectedUsers.map((u) => u.id).toSet();
    switch (r.requestType) {
      case 'disciplinary_action':
        return ids.contains(r.requestorCode) || ids.contains(r.employeeCode);
      case 'investigation':
        final codes = (r.employeeCodes as List?)?.cast<int>() ?? const <int>[];
        return ids.contains(r.requestorCode) || codes.any(ids.contains);
      case 'advance_on_salary':
        return ids.contains(r.requestorCode) || ids.contains(r.borrowerCode);
      case 'hr_letter':
        return ids.contains(r.employeeCode);
      default:
        try {
          return ids.contains(r.userId);
        } catch (_) {
          return false;
        }
    }
  }

  /// Applies the segment filter (made_by / made_against) to a DA or Investigation list.
  ///
  /// For DA and Investigation, role-based filtering is owned entirely here.
  /// We always re-source from _allRequests (with date/type/status filters but no
  /// user filter), then apply the appropriate role check:
  ///   made_by       → requestorCode is the selected employee
  ///   made_against  → employeeCode / employeeCodes contains the selected employee
  ///   all           → either role
  List<dynamic> _applySegmentFilter(List<dynamic> requests, String typeKey) {
    if (_selectedRequestTypes.isNotEmpty && !_selectedRequestTypes.contains(typeKey)) {
      return [];
    }
    final segment = _sectionSegment[typeKey] ?? 'all';

    if (typeKey == 'disciplinary_action' || typeKey == 'investigation' || typeKey == 'advance_on_salary') {
      // Re-query from _allRequests with date/status filters but no user filter,
      // so records from both "made by" and "made against/for" perspectives are available.
      final perTypeStatus = _sectionStatusFilter[typeKey];
      // 'all' sentinel overrides global; null inherits global; anything else is explicit.
      final effectiveStatus = perTypeStatus == 'all' ? null : (perTypeStatus ?? _selectedRequestStatus);
      final allOfType = RequestsReportHelpers.applyFilters(
        _allRequests,
        _selectedDateFrom,
        _selectedDateTo,
        [typeKey],
        effectiveStatus,
        null, // role filtering handled below
        _dateFilterMode,
      );

      if (_selectedUsers.isEmpty) return allOfType;

      final selectedIds = _selectedUsers.map((u) => u.id).toSet();
      return allOfType.where((r) {
        if (typeKey == 'disciplinary_action') {
          final isRequestor = selectedIds.contains(r.requestorCode);
          final isTarget = selectedIds.contains(r.employeeCode);
          if (segment == 'all') return isRequestor || isTarget;
          if (segment == 'made_by') return isRequestor;
          if (segment == 'made_against') return isTarget;
          return false;
        } else if (typeKey == 'advance_on_salary') {
          // 'made_against' segment = made *for* the employee (borrower).
          final isRequestor = selectedIds.contains(r.requestorCode);
          final isTarget = selectedIds.contains(r.borrowerCode);
          if (segment == 'all') return isRequestor || isTarget;
          if (segment == 'made_by') return isRequestor;
          if (segment == 'made_against') return isTarget;
          return false;
        } else {
          // investigation
          final isRequestor = selectedIds.contains(r.requestorCode);
          final codes = (r.employeeCodes as List?)?.cast<int>() ?? <int>[];
          final isTarget = codes.any((c) => selectedIds.contains(c));
          if (segment == 'all') return isRequestor || isTarget;
          if (segment == 'made_by') return isRequestor;
          if (segment == 'made_against') return isTarget;
          return false;
        }
      }).toList();
    }

    // Non-segment types (should not be called, but safe fallback)
    return requests;
  }

  /// Returns the effective request count for a given segment value without
  /// mutating [_sectionSegment]. Used to show live counts on each segment button.
  int _countForSegment(String typeKey, String segmentValue) {
    if (typeKey != 'disciplinary_action' && typeKey != 'investigation' && typeKey != 'advance_on_salary') {
      return _getRequestsForSection(typeKey).length;
    }
    if (_selectedRequestTypes.isNotEmpty && !_selectedRequestTypes.contains(typeKey)) {
      return 0;
    }
    final perTypeStatus = _sectionStatusFilter[typeKey];
    final effectiveStatus = perTypeStatus == 'all' ? null : (perTypeStatus ?? _selectedRequestStatus);
    final allOfType = RequestsReportHelpers.applyFilters(
      _allRequests,
      _selectedDateFrom,
      _selectedDateTo,
      [typeKey],
      effectiveStatus,
      null,
      _dateFilterMode,
    );
    if (_selectedUsers.isEmpty) return allOfType.length;
    final selectedIds = _selectedUsers.map((u) => u.id).toSet();
    return allOfType.where((r) {
      if (typeKey == 'disciplinary_action') {
        final isRequestor = selectedIds.contains(r.requestorCode);
        final isTarget = selectedIds.contains(r.employeeCode);
        if (segmentValue == 'all') return isRequestor || isTarget;
        if (segmentValue == 'made_by') return isRequestor;
        if (segmentValue == 'made_against') return isTarget;
        return false;
      } else if (typeKey == 'advance_on_salary') {
        final isRequestor = selectedIds.contains(r.requestorCode);
        final isTarget = selectedIds.contains(r.borrowerCode);
        if (segmentValue == 'all') return isRequestor || isTarget;
        if (segmentValue == 'made_by') return isRequestor;
        if (segmentValue == 'made_against') return isTarget;
        return false;
      } else {
        final isRequestor = selectedIds.contains(r.requestorCode);
        final codes = (r.employeeCodes as List?)?.cast<int>() ?? <int>[];
        final isTarget = codes.any((c) => selectedIds.contains(c));
        if (segmentValue == 'all') return isRequestor || isTarget;
        if (segmentValue == 'made_by') return isRequestor;
        if (segmentValue == 'made_against') return isTarget;
        return false;
      }
    }).length;
  }

  /// Builds the segment toggle bar shown above DA and Investigation sections.
  /// Toggle that switches the whole report between filtering/sorting on each
  /// request's effective date (dateFrom/date/violationDate/…) and its createdAt.
  /// Mirrors the visual idiom of [_buildSegmentBar] but is global (no per-type counts).
  Widget _buildDateModeToggle(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const color = Color(0xFF1565C0);
    final modes = [('effective', l10n.dateFilterEffective), ('created_at', l10n.dateFilterCreated)];
    return Container(
      height: 49,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: color.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children:
            modes.map((mode) {
              final isActive = _dateFilterMode == mode.$1;
              return Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      if (_dateFilterMode == mode.$1) return;
                      setState(() => _dateFilterMode = mode.$1);
                      _applyFilters();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isActive ? color : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isActive ? color : color.withOpacity(0.3)),
                      ),
                      child: Text(
                        mode.$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Colors.white : color,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildSegmentBar(BuildContext context, String typeKey, Color color) {
    final selected = _sectionSegment[typeKey] ?? 'all';
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    // Advance on Salary is made *for* the borrower, not *against* a subject.
    final madeAgainstLabel =
        typeKey == 'advance_on_salary'
            ? (isArabic ? 'صادر لصالح الموظف' : 'Made for Employee')
            : (isArabic ? 'صادر ضد الموظف' : 'Made Against Employee');
    final segments = [
      ('all', l10n.allTypes),
      ('made_by', isArabic ? 'صادر من الموظف' : 'Made by Employee'),
      ('made_against', madeAgainstLabel),
    ];
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: Row(
        children:
            segments.map((seg) {
              final isActive = selected == seg.$1;
              return Expanded(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _sectionSegment[typeKey] = seg.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isActive ? color : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isActive ? color : color.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${seg.$2} (${_countForSegment(typeKey, seg.$1)})',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive ? Colors.white : color,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  /// Builds the per-type status filter dropdown shown inside the section.
  Widget _buildPerTypeStatusFilter(
    BuildContext context,
    String typeKey,
    List<String> options,
    Color color,
    String? globalStatus,
  ) {
    final current = _sectionStatusFilter[typeKey];
    final l10n = AppLocalizations.of(context)!;

    String statusLabel(String s) {
      switch (s) {
        case 'pending':
          return l10n.pendingStatus;
        case 'acknowledged':
          return l10n.acknowledged;
        case 'completed':
          return l10n.completed;
        case 'approved':
          return l10n.approvedStatus;
        case 'declined':
          return l10n.declinedStatus;
        case 'cancelled':
          return l10n.cancelledStatus;
        case 'closed':
          return l10n.closed;
        case 'on_hold':
          return l10n.onHold;
        case 'converted_to_investigation':
          return l10n.convertedToInvestigation;
        default:
          return s;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey[50], border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            Localizations.localeOf(context).languageCode == 'ar' ? 'الحالة:' : 'Status:',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(width: 8),
          DropdownButton<String?>(
            value: current,
            isDense: true,
            underline: const SizedBox(),
            hint:
                globalStatus != null && current == null
                    ? Text(statusLabel(globalStatus), style: TextStyle(fontSize: 12, color: color))
                    : Text(l10n.allStatuses, style: const TextStyle(fontSize: 12)),
            style: TextStyle(fontSize: 12, color: color),
            items: [
              DropdownMenuItem<String?>(
                value: 'all',
                child: Text(l10n.allStatuses, style: const TextStyle(fontSize: 12)),
              ),
              ...options.map(
                (s) => DropdownMenuItem<String?>(
                  value: s,
                  child: Text(statusLabel(s), style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _sectionStatusFilter[typeKey] = value),
          ),
          if (current != null) ...[
            const SizedBox(width: 4),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _sectionStatusFilter[typeKey] = null),
                child: Icon(Icons.close, size: 14, color: Colors.grey[500]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Wraps _buildRequestTypeSection with optional segment bar and per-type status filter.
  Widget _buildEnhancedSection({
    required BuildContext context,
    required String title,
    required String typeKey,
    required IconData icon,
    required Color color,
    required bool withSegment,
    required List<String> perTypeStatusOptions,
  }) {
    final baseRequests = _getRequestsForSection(typeKey);
    final displayRequests = withSegment ? _applySegmentFilter(baseRequests, typeKey) : baseRequests;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (withSegment) _buildSegmentBar(context, typeKey, color),
        // Inject per-type filter inside card by prepending via a decorated container
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            decoration: BoxDecoration(border: Border(left: BorderSide(color: color, width: 4))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row (mirrors _buildRequestTypeSection header)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(withSegment ? 0 : 12),
                      topRight: Radius.circular(withSegment ? 0 : 12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 24, color: color),
                      const SizedBox(width: 12),
                      Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          '${displayRequests.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                // Per-type status filter row
                _buildPerTypeStatusFilter(context, typeKey, perTypeStatusOptions, color, _selectedRequestStatus),
                // Reuse existing status chips + list via a nested section widget
                _buildRequestTypeSectionBody(context, displayRequests, color, typeKey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds exact per-status chips for HR Letter, DA, and Investigation sections.
  /// Shows one chip per distinct raw status value in the order defined for each type.
  Widget _buildExactStatusChips(BuildContext context, List<dynamic> requests, String requestType) {
    final l10n = AppLocalizations.of(context)!;

    // Count each raw status value
    final counts = <String, int>{};
    for (final r in requests) {
      final s = r.status?.toString().toLowerCase() ?? '';
      if (s.isNotEmpty) counts[s] = (counts[s] ?? 0) + 1;
    }

    // Ordered config per type: (rawStatus, localizedLabel, chipColor)
    final List<(String, String, Color)> config;
    switch (requestType) {
      case 'hr_letter':
        config = [
          ('pending', l10n.pending, Colors.orange),
          ('acknowledged', l10n.acknowledged, Colors.blue),
          ('completed', l10n.completed, Colors.green),
          ('declined', l10n.declined, Colors.red),
          ('cancelled', l10n.cancelledStatus, Colors.grey),
        ];
      case 'disciplinary_action':
        config = [
          ('pending', l10n.pending, Colors.orange),
          ('approved', l10n.approved, Colors.green),
          ('on_hold', l10n.onHold, Colors.amber),
          ('converted_to_investigation', l10n.convertedToInvestigation, Colors.blue),
          ('declined', l10n.declined, Colors.red),
          ('cancelled', l10n.cancelledStatus, Colors.grey),
        ];
      case 'investigation':
        config = [
          ('pending', l10n.pending, Colors.orange),
          ('closed', l10n.closed, Colors.green),
          ('cancelled', l10n.cancelledStatus, Colors.grey),
        ];
      default:
        config = [];
    }

    final knownStatuses = config.map((c) => c.$1).toSet();
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      children: [
        // Show chips in the defined order, only when count > 0
        for (final c in config)
          if ((counts[c.$1] ?? 0) > 0) _buildStatusChip(c.$2, counts[c.$1]!, c.$3),
        // Fallback chip for any unrecognized status values
        for (final entry in counts.entries)
          if (!knownStatuses.contains(entry.key)) _buildStatusChip(entry.key, entry.value, Colors.blueGrey),
      ],
    );
  }

  /// Builds only the body (status chips + list) of a request type section,
  /// used by _buildEnhancedSection to avoid duplicating the card structure.
  Widget _buildRequestTypeSectionBody(BuildContext context, List<dynamic> requests, Color color, String requestType) {
    final isExpanded = _expandedSections[requestType] ?? false;

    // New types use exact per-status chips; legacy types use semantic buckets.
    final bool useExact =
        requestType == 'hr_letter' || requestType == 'disciplinary_action' || requestType == 'investigation';

    Widget chipsRow;
    if (useExact) {
      chipsRow = _buildExactStatusChips(context, requests, requestType);
    } else {
      final statusCounts = RequestsReportHelpers.calculateStatusCounts(requests);
      final l10n = AppLocalizations.of(context)!;
      chipsRow = Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          if ((statusCounts['pending'] ?? 0) > 0)
            _buildStatusChip(l10n.pending, statusCounts['pending']!, Colors.orange),
          if ((statusCounts['approved'] ?? 0) > 0)
            _buildStatusChip(l10n.approved, statusCounts['approved']!, Colors.green),
          if ((statusCounts['declined'] ?? 0) > 0)
            _buildStatusChip(l10n.declined, statusCounts['declined']!, Colors.red),
          if ((statusCounts['cancelled'] ?? 0) > 0)
            _buildStatusChip(l10n.cancelledStatus, statusCounts['cancelled']!, Colors.grey),
          if ((statusCounts['other'] ?? 0) > 0) _buildStatusChip(l10n.other, statusCounts['other']!, Colors.blueGrey),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: chipsRow,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildRequestsList(requests, isExpanded, color, context),
        ),
        if (requests.length > 5) ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _expandedSections[requestType] = !isExpanded),
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isExpanded ? 'Show Less' : 'Show More',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 16),
                ],
              ),
            ),
          ),
        ],
        if (!isExpanded && requests.length > 5) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              AppLocalizations.of(context)!.andMoreRequests(requests.length - 5),
              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────

  Widget _buildRequestsList(List<dynamic> requests, bool isExpanded, Color color, BuildContext context) {
    final itemCount = isExpanded ? requests.length : math.min(requests.length, 5);

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return RepaintBoundary(child: _buildRequestItem(requests[index], color, context));
      },
    );
  }

  Widget _buildRequestItem(dynamic request, Color color, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final status =
        request.status == 'pending'
            ? l10n.pending
            : request.status == 'approved'
            ? l10n.approved
            : request.status == 'declined'
            ? l10n.declined
            : request.status == 'cancelled'
            ? l10n.cancelledStatus
            : request.status == 'on_hold'
            ? l10n.onHold
            : request.status == 'converted_to_investigation'
            ? l10n.convertedToInvestigation
            : request.status == 'acknowledged'
            ? l10n.acknowledged
            : request.status == 'completed'
            ? l10n.completedStatus
            : request.status == 'closed'
            ? l10n.closed
            : request.status?.toString() ?? l10n.unknown;
    final statusColor = RequestsReportHelpers.getStatusColor(request.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with status indicator and status badge
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  RequestsReportHelpers.getRequestTitle(request, context),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Request details based on type
          _buildRequestTypeSpecificDetails(request, context),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildRequestTypeSpecificDetails(dynamic request, BuildContext context) {
    switch (request.requestType) {
      case 'leave':
        return _buildLeaveRequestDetails(request, context);
      case 'overtime':
        return _buildOvertimeRequestDetails(request, context);
      case 'business_trip':
        return _buildBusinessTripRequestDetails(request, context);
      case 'missing_punching':
        return _buildMissingPunchRequestDetails(request, context);
      case 'advance_on_salary':
        return _buildAdvanceOnSalaryRequestDetails(request, context);
      case 'hr_letter':
        return _buildHrLetterRequestDetails(request, context);
      case 'disciplinary_action':
        return _buildDisciplinaryActionRequestDetails(request, context);
      case 'investigation':
        return _buildInvestigationRequestDetails(request, context);
      default:
        return _buildGenericRequestDetails(request, context);
    }
  }

  Widget _buildLeaveRequestDetails(dynamic request, BuildContext context) {
    final approverCode =
        request.currentApprover == "n1"
            ? request.n1Code
            : request.currentApprover == "n2"
            ? request.n2Code
            : "hr";
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      direction: Axis.horizontal,
      children: [
        _buildDetailRow(AppLocalizations.of(context)!.id, request.id.toString()),
        _buildDetailRow(
          AppLocalizations.of(context)!.name,
          Localizations.localeOf(context).languageCode == 'ar'
              ? request.userArabicName ?? 'N/A'
              : request.userEnglishName ?? 'N/A',
        ),
        _buildDetailRow(AppLocalizations.of(context)!.createdAt, request.createdAt?.toString().split(' ')[0] ?? 'N/A'),
        _buildDetailRow(AppLocalizations.of(context)!.dateFrom, request.dateFrom?.toString().split(' ')[0] ?? 'N/A'),
        _buildDetailRow(AppLocalizations.of(context)!.dateTo, request.dateTo?.toString().split(' ')[0] ?? 'N/A'),
        if (request.getLocalizedLeaveType(context) != null)
          _buildDetailRow(AppLocalizations.of(context)!.leaveType, request.getLocalizedLeaveType(context)),
        if (request.numberOfDays != null)
          _buildDetailRow(AppLocalizations.of(context)!.numberOfDays, request.numberOfDays.toString()),
        if (request.declineReason != null)
          _buildDetailRow(AppLocalizations.of(context)!.declineReason, request.declineReason.toString()),
        _buildApproverRow(AppLocalizations.of(context)!.approver, approverCode),
      ],
    );
  }

  Widget _buildOvertimeRequestDetails(dynamic request, BuildContext context) {
    final approverCode =
        request.currentApprover == "n1"
            ? request.n1Code
            : request.currentApprover == "n2"
            ? request.n2Code
            : "hr";
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      direction: Axis.horizontal,
      children: [
        _buildDetailRow(AppLocalizations.of(context)!.id, request.id.toString()),
        _buildDetailRow(
          AppLocalizations.of(context)!.name,
          Localizations.localeOf(context).languageCode == 'ar'
              ? request.userArabicName ?? 'N/A'
              : request.userEnglishName ?? 'N/A',
        ),
        _buildDetailRow(AppLocalizations.of(context)!.createdAt, request.createdAt?.toString().split(' ')[0] ?? 'N/A'),
        _buildDetailRow(AppLocalizations.of(context)!.date, request.date?.toString().split(' ')[0] ?? 'N/A'),
        if (request.timeFrom != null)
          _buildDetailRow(AppLocalizations.of(context)!.timeFrom, RequestsReportHelpers.formatTime(request.timeFrom)),
        if (request.timeTo != null)
          _buildDetailRow(AppLocalizations.of(context)!.timeTo, RequestsReportHelpers.formatTime(request.timeTo)),
        if (request.numberOfHours != null)
          _buildDetailRow(AppLocalizations.of(context)!.numOfHours, request.numberOfHours.toString()),
        if (request.getLocalizedOvertimeType(context) != null)
          _buildDetailRow(AppLocalizations.of(context)!.type, request.getLocalizedOvertimeType(context)),
        if (request.reason != null && request.reason.toString().isNotEmpty)
          _buildDetailRow(AppLocalizations.of(context)!.reason, request.reason.toString()),

        if (request.declineReason != null)
          _buildDetailRow(AppLocalizations.of(context)!.declineReason, request.declineReason.toString()),
        _buildApproverRow(AppLocalizations.of(context)!.approver, approverCode),
      ],
    );
  }

  Widget _buildBusinessTripRequestDetails(dynamic request, BuildContext context) {
    final approverCode =
        request.currentApprover == "n1"
            ? request.n1Code
            : request.currentApprover == "n2"
            ? request.n2Code
            : "hr";
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      direction: Axis.horizontal,
      children: [
        _buildDetailRow(AppLocalizations.of(context)!.id, request.id.toString()),
        _buildDetailRow(
          AppLocalizations.of(context)!.name,
          Localizations.localeOf(context).languageCode == 'ar'
              ? request.userArabicName ?? 'N/A'
              : request.userEnglishName ?? 'N/A',
        ),
        _buildDetailRow(AppLocalizations.of(context)!.createdAt, request.createdAt?.toString().split(' ')[0] ?? 'N/A'),
        _buildDetailRow(AppLocalizations.of(context)!.dateFrom, request.dateFrom?.toString().split(' ')[0] ?? 'N/A'),
        _buildDetailRow(AppLocalizations.of(context)!.dateTo, request.dateTo?.toString().split(' ')[0] ?? 'N/A'),
        if (request.numberOfDays != null)
          _buildDetailRow(AppLocalizations.of(context)!.numOfDays, request.numberOfDays.toString()),
        if (request.getLocalizedLocation(context) != null)
          _buildDetailRow(AppLocalizations.of(context)!.location, request.getLocalizedLocation(context)),
        if (request.declineReason != null)
          _buildDetailRow(AppLocalizations.of(context)!.declineReason, request.declineReason.toString()),
        _buildApproverRow(AppLocalizations.of(context)!.approver, approverCode),
      ],
    );
  }

  Widget _buildMissingPunchRequestDetails(dynamic request, BuildContext context) {
    final approverCode =
        request.currentApprover == "n1"
            ? request.n1Code
            : request.currentApprover == "n2"
            ? request.n2Code
            : "hr";
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      direction: Axis.horizontal,
      children: [
        _buildDetailRow(AppLocalizations.of(context)!.id, request.id.toString()),
        _buildDetailRow(
          AppLocalizations.of(context)!.name,
          Localizations.localeOf(context).languageCode == 'ar'
              ? request.userArabicName ?? 'N/A'
              : request.userEnglishName ?? 'N/A',
        ),
        _buildDetailRow(AppLocalizations.of(context)!.createdAt, request.createdAt?.toString().split(' ')[0] ?? 'N/A'),
        _buildDetailRow(AppLocalizations.of(context)!.date, request.date?.toString().split(' ')[0] ?? 'N/A'),
        if (request.time != null)
          _buildDetailRow(AppLocalizations.of(context)!.time, RequestsReportHelpers.formatTime(request.time)),
        if (request.getLocalizedType(context) != null)
          _buildDetailRow(AppLocalizations.of(context)!.type, request.getLocalizedType(context)),
        if (request.declineReason != null)
          _buildDetailRow(AppLocalizations.of(context)!.declineReason, request.declineReason.toString()),
        _buildApproverRow(AppLocalizations.of(context)!.approver, approverCode),
      ],
    );
  }

  Widget _buildAdvanceOnSalaryRequestDetails(dynamic request, BuildContext context) {
    final approverCode =
        request.currentApprover == "n2"
            ? request.n2Code
            : request.currentApprover == "hr"
            ? "hr"
            : "finance";
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      direction: Axis.horizontal,
      children: [
        _buildDetailRow(AppLocalizations.of(context)!.id, request.id.toString()),
        _buildDetailRow(
          AppLocalizations.of(context)!.requestor,
          Localizations.localeOf(context).languageCode == 'ar'
              ? request.requestorArabicName ?? 'N/A'
              : request.requestorEnglishName ?? 'N/A',
        ),
        _buildDetailRow(
          AppLocalizations.of(context)!.borrower,
          Localizations.localeOf(context).languageCode == 'ar'
              ? request.borrowerArabicName ?? 'N/A'
              : request.borrowerEnglishName ?? 'N/A',
        ),
        _buildDetailRow(AppLocalizations.of(context)!.createdAt, request.createdAt?.toString().split(' ')[0] ?? 'N/A'),
        if (request.amount != null) _buildDetailRow(AppLocalizations.of(context)!.amount, request.amount.toString()),
        _buildDetailRow(
          AppLocalizations.of(context)!.period,
          '${request.periodInMonths ?? 'N/A'} ${AppLocalizations.of(context)!.months}',
        ),
        _buildDetailRow(AppLocalizations.of(context)!.monthlyPayment, request.monthlyPayment?.toString() ?? 'N/A'),
        _buildDetailRow(
          AppLocalizations.of(context)!.paymentStartDate,
          request.paymentStartDate?.toString().split(' ')[0] ?? 'N/A',
        ),
        _buildDetailRow(
          AppLocalizations.of(context)!.paymentEndDate,
          request.paymentEndDate?.toString().split(' ')[0] ?? 'N/A',
        ),
        if (request.declineReason != null)
          _buildDetailRow(AppLocalizations.of(context)!.declineReason, request.declineReason.toString()),
        _buildApproverRow(AppLocalizations.of(context)!.approver, approverCode),
      ],
    );
  }

  Widget _buildGenericRequestDetails(dynamic request, BuildContext context) {
    final approverCode =
        request.currentApprover == "n1"
            ? request.n1Code
            : request.currentApprover == "n2"
            ? request.n2Code
            : "hr";
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      direction: Axis.horizontal,
      children: [
        _buildDetailRow(AppLocalizations.of(context)!.id, request.id.toString()),
        _buildDetailRow(AppLocalizations.of(context)!.createdAt, request.createdAt?.toString().split(' ')[0] ?? 'N/A'),
        if (request.date != null)
          _buildDetailRow(AppLocalizations.of(context)!.date, request.date.toString().split(' ')[0]),
        if (request.dateFrom != null)
          _buildDetailRow(AppLocalizations.of(context)!.dateFrom, request.dateFrom.toString().split(' ')[0]),
        if (request.dateTo != null)
          _buildDetailRow(AppLocalizations.of(context)!.dateTo, request.dateTo.toString().split(' ')[0]),
        if (request.reason != null && request.reason.toString().isNotEmpty)
          _buildDetailRow(AppLocalizations.of(context)!.reason, request.reason.toString()),
        _buildApproverRow(AppLocalizations.of(context)!.approver, approverCode),
      ],
    );
  }

  Widget _buildHrLetterRequestDetails(dynamic request, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      direction: Axis.horizontal,
      children: [
        _buildDetailRow(l10n.id, request.id.toString()),
        _buildDetailRow(l10n.status, request.getLocalizedStatus(context)),
        _buildDetailRow(l10n.createdAt, request.createdAt?.toString().split(' ')[0] ?? 'N/A'),
        _buildDetailRow(
          l10n.name,
          isArabic
              ? (request.employeeArabicName ?? request.employeeEnglishName ?? 'N/A')
              : (request.employeeEnglishName ?? request.employeeArabicName ?? 'N/A'),
        ),
        _buildDetailRow(
          l10n.department,
          isArabic
              ? (request.employeeDepartment ?? request.employeeEnglishDepartment ?? 'N/A')
              : (request.employeeEnglishDepartment ?? request.employeeDepartment ?? 'N/A'),
        ),
        if (request.employeeTitle != null || request.employeeEnglishTitle != null)
          _buildDetailRow(
            l10n.title,
            isArabic
                ? (request.employeeTitle ?? request.employeeEnglishTitle ?? 'N/A')
                : (request.employeeEnglishTitle ?? request.employeeTitle ?? 'N/A'),
          ),
        if (request.nationalId != null) _buildDetailRow(l10n.nationalId, request.nationalId.toString()),
        if (request.employeeHireDate != null) _buildDetailRow(l10n.hireDate, request.employeeHireDate.toString()),
        _buildDetailRow(l10n.letterPurpose, request.getLocalizedLetterPurpose(context)),
        if (request.travelFromDate != null)
          _buildDetailRow(l10n.travelFromDate, request.travelFromDate.toString().split(' ')[0]),
        if (request.travelToDate != null)
          _buildDetailRow(l10n.travelToDate, request.travelToDate.toString().split(' ')[0]),
        if (request.details != null && request.details.toString().isNotEmpty)
          _buildDetailRow(l10n.hrLetterDetails, request.details.toString()),
        if (request.hrHandlerEnglishName != null || request.hrHandlerArabicName != null)
          _buildDetailRow(
            l10n.hrHandler,
            isArabic
                ? (request.hrHandlerArabicName ?? request.hrHandlerEnglishName ?? 'N/A')
                : (request.hrHandlerEnglishName ?? request.hrHandlerArabicName ?? 'N/A'),
          ),
        if (request.declineReason != null) _buildDetailRow(l10n.declineReason, request.declineReason.toString()),
        if (request.acknowledgedAt != null)
          _buildDetailRow(l10n.acknowledgedAt, request.acknowledgedAt.toString().split(' ')[0]),
        if (request.completedAt != null)
          _buildDetailRow(l10n.completedAt, request.completedAt.toString().split(' ')[0]),
        if (request.declinedAt != null) _buildDetailRow(l10n.declinedAt, request.declinedAt.toString().split(' ')[0]),
        if (request.cancelledAt != null)
          _buildDetailRow(l10n.cancelledAt, request.cancelledAt.toString().split(' ')[0]),
        if (request.lastActionAt != null)
          _buildDetailRow(l10n.lastActionAt, request.lastActionAt.toString().split(' ')[0]),
      ],
    );
  }

  Widget _buildDisciplinaryActionRequestDetails(dynamic request, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      direction: Axis.horizontal,
      children: [
        // Core
        _buildDetailRow(l10n.id, request.id.toString()),
        _buildDetailRow(l10n.status, request.getLocalizedStatus(context)),
        _buildDetailRow(l10n.createdAt, request.createdAt?.toString().split(' ')[0] ?? 'N/A'),
        if (request.currentApprover != null)
          _buildDetailRow(l10n.currentApprover, request.getLocalizedApproverName(context)),
        // Employee
        _buildDetailRow(
          l10n.name,
          isArabic
              ? (request.employeeArabicName ?? request.employeeEnglishName ?? 'N/A')
              : (request.employeeEnglishName ?? request.employeeArabicName ?? 'N/A'),
        ),
        _buildDetailRow(
          l10n.department,
          isArabic
              ? (request.employeeDepartment ?? request.employeeEnglishDepartment ?? 'N/A')
              : (request.employeeEnglishDepartment ?? request.employeeDepartment ?? 'N/A'),
        ),
        if (request.employeeTitle != null || request.employeeEnglishTitle != null)
          _buildDetailRow(
            l10n.title,
            isArabic
                ? (request.employeeTitle ?? request.employeeEnglishTitle ?? 'N/A')
                : (request.employeeEnglishTitle ?? request.employeeTitle ?? 'N/A'),
          ),
        if (request.employeeHireDate != null) _buildDetailRow(l10n.hireDate, request.employeeHireDate.toString()),
        // Requestor
        _buildDetailRow(
          l10n.requestor,
          isArabic
              ? (request.requestorArabicName ?? request.requestorEnglishName ?? 'N/A')
              : (request.requestorEnglishName ?? request.requestorArabicName ?? 'N/A'),
        ),
        if (request.requestorTitle != null || request.requestorEnglishTitle != null)
          _buildDetailRow(
            l10n.requestorTitle,
            isArabic
                ? (request.requestorTitle ?? request.requestorEnglishTitle ?? 'N/A')
                : (request.requestorEnglishTitle ?? request.requestorTitle ?? 'N/A'),
          ),
        if (request.requestorDepartment != null || request.requestorEnglishDepartment != null)
          _buildDetailRow(
            l10n.requestorDepartment,
            isArabic
                ? (request.requestorDepartment ?? request.requestorEnglishDepartment ?? 'N/A')
                : (request.requestorEnglishDepartment ?? request.requestorDepartment ?? 'N/A'),
          ),
        // N+2
        if (request.n2EnglishName != null || request.n2ArabicName != null)
          _buildDetailRow(
            l10n.n2Manager,
            isArabic
                ? (request.n2ArabicName ?? request.n2EnglishName ?? 'N/A')
                : (request.n2EnglishName ?? request.n2ArabicName ?? 'N/A'),
          ),
        // Incident
        if (request.violationDate != null)
          _buildDetailRow(l10n.violationDate, request.violationDate.toString().split(' ')[0]),
        if (request.violationCategory != null)
          _buildDetailRow(l10n.violationCategory, request.violationCategory.toString()),
        if (request.violation != null) _buildDetailRow(l10n.violation, request.violation.toString()),
        if (request.actionType != null)
          _buildDetailRow(l10n.actionType, request.getLocalizedActionType(context).toString()),
        if (request.incidentDescription != null && request.incidentDescription.toString().isNotEmpty)
          _buildDetailRow(l10n.incidentDescription, request.incidentDescription.toString()),
        // Written warning options
        if ((request.writtenWarningOptions?.deductDays ?? 0) > 0)
          _buildDetailRow(l10n.deductDays, request.writtenWarningOptions!.deductDays.toString()),
        if ((request.writtenWarningOptions?.suspensionDays ?? 0) > 0)
          _buildDetailRow(l10n.suspensionDays, request.writtenWarningOptions!.suspensionDays.toString()),
        // Approval chain
        if (request.n2ApprovalDate != null)
          _buildDetailRow(l10n.n2ApprovalDate, request.n2ApprovalDate.toString().split(' ')[0]),
        if (request.n2ApprovalReason != null && request.n2ApprovalReason.toString().isNotEmpty)
          _buildDetailRow(l10n.n2ApprovalReason, request.n2ApprovalReason.toString()),
        if (request.hrApprovalDate != null)
          _buildDetailRow(l10n.hrApprovalDate, request.hrApprovalDate.toString().split(' ')[0]),
        if (request.hrApprovalReason != null && request.hrApprovalReason.toString().isNotEmpty)
          _buildDetailRow(l10n.hrApprovalReason, request.hrApprovalReason.toString()),
        // HR final decision
        if (request.hrFinalAction != null && request.hrFinalAction.toString().isNotEmpty)
          _buildDetailRow(l10n.hrFinalDecision, request.hrFinalAction.toString()),
        if (request.suspensionDaysField != null)
          _buildDetailRow(l10n.suspensionDays, request.suspensionDaysField.toString()),
        if (request.suspensionStartDate != null)
          _buildDetailRow(l10n.suspensionStartDate, request.suspensionStartDate.toString().split(' ')[0]),
        if (request.suspensionEndDate != null)
          _buildDetailRow(l10n.suspensionEndDate, request.suspensionEndDate.toString().split(' ')[0]),
        if (request.terminationRecommendedDate != null)
          _buildDetailRow(l10n.terminationRecommendedDate, request.terminationRecommendedDate.toString().split(' ')[0]),
        // Legal escalation
        if (request.escalatedToLegal == true) ...[
          _buildDetailRow(l10n.legalEscalation, l10n.yes),
          if (request.legalEscalationDate != null)
            _buildDetailRow(l10n.legalEscalationDate, request.legalEscalationDate.toString().split(' ')[0]),
          if (request.legalEscalationReason != null && request.legalEscalationReason.toString().isNotEmpty)
            _buildDetailRow(l10n.legalEscalationReason, request.legalEscalationReason.toString()),
          if (request.legalCompletionDate != null)
            _buildDetailRow(l10n.legalCompletionDate, request.legalCompletionDate.toString().split(' ')[0]),
          if (request.legalEnglishName != null || request.legalArabicName != null)
            _buildDetailRow(
              isArabic ? 'الشؤون القانونية' : 'Legal',
              isArabic
                  ? (request.legalArabicName ?? request.legalEnglishName ?? 'N/A')
                  : (request.legalEnglishName ?? request.legalArabicName ?? 'N/A'),
            ),
        ],
        // Employee acknowledgment
        if (request.employeeAcknowledgmentDate != null) ...[
          _buildDetailRow(l10n.employeeAcknowledgmentDate, request.employeeAcknowledgmentDate.toString().split(' ')[0]),
          if (request.employeeAcknowledgmentType != null && request.employeeAcknowledgmentType.toString().isNotEmpty)
            _buildDetailRow(l10n.employeeAcknowledgmentType, request.employeeAcknowledgmentType.toString()),
          if (request.employeeAcknowledgmentRemark != null &&
              request.employeeAcknowledgmentRemark.toString().isNotEmpty)
            _buildDetailRow(l10n.employeeAcknowledgmentRemark, request.employeeAcknowledgmentRemark.toString()),
        ],
        // Outcome
        if (request.declineReason != null) _buildDetailRow(l10n.declineReason, request.declineReason.toString()),
        if (request.holdReason != null) _buildDetailRow(l10n.holdReason, request.holdReason.toString()),
        // Links
        if (request.investigationId != null)
          _buildDetailRow(l10n.linkedInvestigation, request.investigationId.toString()),
        if (request.lastActionAt != null)
          _buildDetailRow(l10n.lastActionAt, request.lastActionAt.toString().split(' ')[0]),
      ],
    );
  }

  Widget _buildInvestigationRequestDetails(dynamic request, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final employeeInfoMap = request.employeeInfoMap as Map? ?? {};
    final employeeCodes = request.employeeCodes as List<int>? ?? [];
    final employeeNames = employeeCodes
        .map((code) {
          final info = employeeInfoMap[code];
          if (info == null) return code.toString();
          return isArabic
              ? (info.arabicName ?? info.englishName ?? code.toString())
              : (info.englishName ?? info.arabicName ?? code.toString());
        })
        .join(', ');
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      direction: Axis.horizontal,
      children: [
        // Core
        _buildDetailRow(l10n.id, request.id.toString()),
        _buildDetailRow(l10n.status, request.getLocalizedStatus(context)),
        _buildDetailRow(l10n.createdAt, request.createdAt?.toString().split(' ')[0] ?? 'N/A'),
        if (request.currentApprover != null)
          _buildDetailRow(l10n.currentApprover, request.getLocalizedCurrentApprover(isArabic)),
        // Requestor & employees
        _buildDetailRow(
          l10n.requestor,
          isArabic
              ? (request.requestorArabicName ?? request.requestorEnglishName ?? 'N/A')
              : (request.requestorEnglishName ?? request.requestorArabicName ?? 'N/A'),
        ),
        if (employeeNames.isNotEmpty) _buildDetailRow(l10n.name, employeeNames),
        // Incident
        if (request.violationDate != null)
          _buildDetailRow(l10n.violationDate, request.violationDate.toString().split(' ')[0]),
        if (request.violationCategory != null)
          _buildDetailRow(l10n.violationCategory, request.violationCategory.toString()),
        if (request.violation != null) _buildDetailRow(l10n.violation, request.violation.toString()),
        if (request.incidentDescription != null && request.incidentDescription.toString().isNotEmpty)
          _buildDetailRow(l10n.incidentDescription, request.incidentDescription.toString()),
        // HR handler
        if (request.hrEnglishName != null || request.hrArabicName != null)
          _buildDetailRow(
            l10n.hrHandler,
            isArabic
                ? (request.hrArabicName ?? request.hrEnglishName ?? 'N/A')
                : (request.hrEnglishName ?? request.hrArabicName ?? 'N/A'),
          ),
        // Legal escalation
        if (request.escalatedToLegal == true) ...[
          _buildDetailRow(l10n.legalEscalation, l10n.yes),
          if (request.legalEscalationDate != null)
            _buildDetailRow(l10n.legalEscalationDate, request.legalEscalationDate.toString().split(' ')[0]),
          if (request.legalEscalationReason != null && request.legalEscalationReason.toString().isNotEmpty)
            _buildDetailRow(l10n.legalEscalationReason, request.legalEscalationReason.toString()),
          if (request.legalEnglishName != null || request.legalArabicName != null)
            _buildDetailRow(
              isArabic ? 'الشؤون القانونية' : 'Legal',
              isArabic
                  ? (request.legalArabicName ?? request.legalEnglishName ?? 'N/A')
                  : (request.legalEnglishName ?? request.legalArabicName ?? 'N/A'),
            ),
        ],
        // Top management
        if (request.topManagementEnglishName != null || request.topManagementArabicName != null)
          _buildDetailRow(
            isArabic ? 'الإدارة العليا' : 'Top Management',
            isArabic
                ? (request.topManagementArabicName ?? request.topManagementEnglishName ?? 'N/A')
                : (request.topManagementEnglishName ?? request.topManagementArabicName ?? 'N/A'),
          ),
        // Links
        if (request.escalatedFromDisciplinary == true && request.escalatedDisciplinaryActionId != null)
          _buildDetailRow(l10n.linkedDisciplinaryAction, request.escalatedDisciplinaryActionId.toString()),
        if (request.lastActionAt != null)
          _buildDetailRow(l10n.lastActionAt, request.lastActionAt.toString().split(' ')[0]),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 4, right: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          Flexible(
            child: Text(value, style: TextStyle(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.w400)),
          ),
        ],
      ),
    );
  }

  Widget _buildApproverRow(String label, dynamic approverCode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(bottom: 4, right: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label:', style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(width: 10),
          Flexible(child: _buildApproverNameWidget(approverCode)),
        ],
      ),
    );
  }

  Widget _buildApproverNameWidget(dynamic approverCode) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    // Check if we have the name cached
    if (approverCode == "hr") {
      return Text(
        isArabic ? "الموارد البشرية" : "HR",
        style: TextStyle(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.w400),
      );
    } else if (approverCode == "finance") {
      return Text(
        isArabic ? "المالية" : "Finance",
        style: TextStyle(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.w400),
      );
    }

    if (approverCode is int && _approverNames.containsKey(approverCode)) {
      return Text(
        Localizations.localeOf(context).languageCode == 'ar'
            ? _approverNames[approverCode]![0]
            : _approverNames[approverCode]![1],
        style: TextStyle(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.w400),
      );
    }

    // If not cached, use FutureBuilder to fetch it
    return FutureBuilder<List<String>>(
      future: _getApproverName(approverCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
        }
        return Text(
          Localizations.localeOf(context).languageCode == 'ar' ? snapshot.data![0] : snapshot.data![1],
          style: TextStyle(color: Colors.grey[800], fontSize: 12, fontWeight: FontWeight.w400),
        );
      },
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text('$label: $count', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CustomDateRangePicker extends StatefulWidget {
  final DateTime? selectedDateFrom;
  final DateTime? selectedDateTo;
  final Function(DateTime?) onDateFromChanged;
  final Function(DateTime?) onDateToChanged;

  const _CustomDateRangePicker({
    required this.selectedDateFrom,
    required this.selectedDateTo,
    required this.onDateFromChanged,
    required this.onDateToChanged,
  });

  @override
  State<_CustomDateRangePicker> createState() => _CustomDateRangePickerState();
}

class _CustomDateRangePickerState extends State<_CustomDateRangePicker> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateDateText();
  }

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    super.dispose();
  }

  void _updateDateText() {
    // This method is no longer needed since we're not using TextField controllers
    // The display is handled directly in the build method
  }

  void _showDatePicker(TextEditingController controller, Function(DateTime?) onDateChanged) async {
    final bool isFromDate = controller == _fromDateController;

    final date = await showCustomDatePicker(
      context: context,
      initialDate:
          isFromDate
              ? (widget.selectedDateFrom ?? DateTime.now().subtract(const Duration(days: 30)))
              : (widget.selectedDateTo ?? DateTime.now()),
      firstDate: isFromDate ? DateTime(2020) : (widget.selectedDateFrom ?? DateTime(2020)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      onDateChanged(date);
      setState(() {
        // Trigger rebuild to update the display
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      height: 49,
      child: Row(
        children: [
          Icon(Icons.calendar_today, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                // Date From
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showDatePicker(_fromDateController, widget.onDateFromChanged),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.selectedDateFrom != null
                                ? DateFormat('MMM dd').format(widget.selectedDateFrom!)
                                : AppLocalizations.of(context)!.from,
                            style: TextStyle(
                              color: widget.selectedDateFrom != null ? Colors.black87 : Colors.grey[500],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.to,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                // Date To
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showDatePicker(_toDateController, widget.onDateToChanged),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.selectedDateTo != null
                                ? DateFormat('MMM dd').format(widget.selectedDateTo!)
                                : AppLocalizations.of(context)!.to,
                            style: TextStyle(
                              color: widget.selectedDateTo != null ? Colors.black87 : Colors.grey[500],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[600]),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
