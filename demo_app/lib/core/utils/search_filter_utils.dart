import 'package:hrms_demo/data/models/user_model.dart';

/// Utility class for common search and filter operations across request pages
class SearchFilterUtils {
  /// Sorts [employees] by search relevance in-place and returns the list.
  ///
  /// Order: exact code match → code prefix (ascending) → name prefix → name substring → alphabetical.
  /// Short code is derived as `id - 10000000` so that typing "24" matches codes 240–249, 2400–2499, etc.
  static List<UserModel> sortByRelevance(List<UserModel> employees, String searchTerm) {
    if (searchTerm.isEmpty || employees.length <= 1) return employees;
    final term = searchTerm.toLowerCase();
    final isNumeric = int.tryParse(searchTerm) != null;

    employees.sort((a, b) {
      final scA = ((a.id ?? 0) - 10000000).toString();
      final scB = ((b.id ?? 0) - 10000000).toString();
      final isCodeA = isNumeric && scA.startsWith(searchTerm);
      final isCodeB = isNumeric && scB.startsWith(searchTerm);

      if (isCodeA && !isCodeB) return -1;
      if (!isCodeA && isCodeB) return 1;
      if (isCodeA && isCodeB) return (a.id ?? 0).compareTo(b.id ?? 0);

      int bestNamePos(UserModel e) {
        final pe = (e.englishName?.toLowerCase() ?? '').indexOf(term);
        final pa = (e.arabicName?.toLowerCase() ?? '').indexOf(term);
        if (pe == -1) return pa == -1 ? 999 : pa;
        if (pa == -1) return pe;
        return pe < pa ? pe : pa;
      }

      final diff = bestNamePos(a).compareTo(bestNamePos(b));
      if (diff != 0) return diff;
      return (a.englishName ?? a.arabicName ?? '').compareTo(b.englishName ?? b.arabicName ?? '');
    });

    return employees;
  }

  /// Performs a simple case-insensitive search across name and user_code fields
  /// Returns true if the query matches either field
  static bool matchesSearch({
    required String? name,
    required String? userCode,
    required String query,
  }) {
    if (query.isEmpty) return true;

    final lowercaseQuery = query.toLowerCase().trim();
    final lowercaseName = (name ?? '').toLowerCase();
    final lowercaseUserCode = (userCode ?? '').toLowerCase();

    return lowercaseName.contains(lowercaseQuery) ||
        lowercaseUserCode.contains(lowercaseQuery);
  }

  /// Filters a list of requests based on search query, status, and month
  /// T is the request type (e.g., LeaveRequest, OvertimeRequest, etc.)
  static List<T> applyFilters<T>({
    required List<T> requests,
    required String searchQuery,
    required String statusFilter,
    required DateTime? selectedMonth,
    required String? Function(T) getNameField,
    required String? Function(T) getUserCodeField,
    required String? Function(T) getStatusField,
    required DateTime? Function(T) getDateField,
  }) {
    return requests.where((request) {
      // Apply search filter
      if (searchQuery.isNotEmpty) {
        final name = getNameField(request);
        final userCode = getUserCodeField(request);
        if (!matchesSearch(
          name: name,
          userCode: userCode,
          query: searchQuery,
        )) {
          return false;
        }
      }

      // Apply status filter
      if (statusFilter != 'all') {
        final status = getStatusField(request);
        if (status != statusFilter) {
          return false;
        }
      }

      // Apply month filter
      if (selectedMonth != null) {
        final requestDate = getDateField(request);
        if (requestDate == null) return false;

        if (requestDate.year != selectedMonth.year ||
            requestDate.month != selectedMonth.month) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Common status options that can be used across different request types
  static const List<Map<String, String>> commonStatusOptions = [
    {'value': 'all', 'label': 'All'},
    {'value': 'pending', 'label': 'Pending'},
    {'value': 'approved', 'label': 'Approved'},
    {'value': 'declined', 'label': 'Declined'},
    {'value': 'cancelled', 'label': 'Cancelled'},
  ];

  /// Extended status options including pending employee confirmation
  static const List<Map<String, String>> extendedStatusOptions = [
    {'value': 'all', 'label': 'All'},
    {'value': 'pending', 'label': 'Pending'},
    {'value': 'approved', 'label': 'Approved'},
    {'value': 'declined', 'label': 'Declined'},
    {'value': 'cancelled', 'label': 'Cancelled'},
    {'value': 'pending_employee_confirmation', 'label': 'Pending Employee Confirmation'},
  ];
}
