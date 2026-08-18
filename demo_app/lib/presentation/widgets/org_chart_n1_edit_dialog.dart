import 'dart:async';

import 'package:hrms_demo/core/constants/employee_type_selection.dart';
import 'package:hrms_demo/core/utils/search_filter_utils.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/shared/employee_search_field.dart';
import 'package:hrms_demo/presentation/shared/selected_employee_section.dart';
import 'package:flutter/material.dart';

/// Dialog for reassigning an employee's direct manager (N+1) from the org chart.
///
/// Reuses the shared [EmployeeSearchField] in search-only mode (no type toggle,
/// no browse dropdown), driving it directly from [UsersRepo.searchAllActiveEmployees]
/// — the same global active-employee search the suspension reassignment picker uses.
///
/// On a successful save it pops `true`, signalling the caller to reload the chart.
class OrgChartN1EditDialog extends StatefulWidget {
  /// Code of the employee whose manager is being changed.
  final int employeeId;

  /// Display name of that employee (from the clicked node).
  final String employeeName;

  /// Current N+1 (manager) code, if any.
  final int? currentN1;

  /// The currently rendered hierarchy as `{id, pid, name, post}` maps.
  /// Used both to resolve the current manager's name and to guard against cycles.
  final List<Map<String, dynamic>> nodes;

  final UsersRepo usersRepo;

  /// Code of the HR/Top-Management user performing the change (for attribution).
  final int? actorCode;

  const OrgChartN1EditDialog({
    super.key,
    required this.employeeId,
    required this.employeeName,
    required this.currentN1,
    required this.nodes,
    required this.usersRepo,
    this.actorCode,
  });

  @override
  State<OrgChartN1EditDialog> createState() => _OrgChartN1EditDialogState();
}

class _OrgChartN1EditDialogState extends State<OrgChartN1EditDialog> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, String> _errors = {};
  static const _kValidationKey = 'n1';

  Timer? _debounce;
  bool _isSearching = false;
  bool _isSaving = false;
  List<UserModel> _results = [];
  UserModel? _selected;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Resolve the current manager's display name from the in-memory node list.
  String? get _currentManagerName {
    if (widget.currentN1 == null) return null;
    for (final n in widget.nodes) {
      if (n['id'] == widget.currentN1) return n['name']?.toString();
    }
    return null;
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final term = value.trim();
    if (term.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final res = await widget.usersRepo.searchAllActiveEmployees(term);
        // Never offer the employee themselves as their own manager.
        final filtered = res.where((e) => e.id != widget.employeeId).toList();
        SearchFilterUtils.sortByRelevance(filtered, term);
        if (mounted) {
          setState(() {
            _results = filtered;
            _isSearching = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _results = [];
            _isSearching = false;
          });
        }
      }
    });
  }

  void _onEmployeeSelected(UserModel employee) {
    setState(() {
      _selected = employee;
      _results = [];
      _errors.remove(_kValidationKey);
      _searchController.clear();
    });
  }

  void _clearSelection() {
    setState(() => _selected = null);
  }

  /// Walk up the hierarchy from [newManagerId]; if we reach the employee being
  /// edited, the assignment would create a circular reporting line.
  bool _wouldCreateCycle(int newManagerId) {
    final pidById = <int, int?>{};
    for (final n in widget.nodes) {
      final id = n['id'];
      if (id is int) {
        final pid = n['pid'];
        pidById[id] = pid is int ? pid : null;
      }
    }
    final visited = <int>{};
    int? cur = newManagerId;
    while (cur != null) {
      if (cur == widget.employeeId) return true;
      if (!visited.add(cur)) break; // pre-existing loop in stored data — stop
      cur = pidById[cur];
    }
    return false;
  }

  Future<void> _onSave() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = _selected;
    if (selected == null || selected.id == null) {
      setState(() => _errors[_kValidationKey] = l10n.pleaseSelectManager);
      return;
    }
    final newManagerId = selected.id!;
    if (newManagerId == widget.employeeId || _wouldCreateCycle(newManagerId)) {
      setState(() => _errors[_kValidationKey] = l10n.circularReportingLine);
      return;
    }

    setState(() {
      _isSaving = true;
      _errors.remove(_kValidationKey);
    });
    try {
      // Keep N+2 consistent with the Edit Employee page: N+2 = new manager's N+1.
      final manager = await widget.usersRepo.getEmployeeById(newManagerId);
      await widget.usersRepo.updateEmployeeManager(
        widget.employeeId,
        n1: newManagerId,
        n2: manager.n1,
        actorCode: widget.actorCode,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errors[_kValidationKey] = l10n.failedToUpdateManager;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final currentManager = _currentManagerName;

    // Give the dialog a proper, bigger fixed width on roomy screens, but never
    // wider than the viewport (minus inset) on small ones.
    final screenWidth = MediaQuery.of(context).size.width;
    const targetWidth = 620.0;
    final dialogWidth = screenWidth < targetWidth + 48 ? screenWidth - 48 : targetWidth;

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.supervisor_account, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.editManagerTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  widget.employeeName.isEmpty ? widget.employeeId.toString() : widget.employeeName,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
            tooltip: l10n.cancel,
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current manager banner.
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person_outline, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${l10n.currentManager}: '
                        '${currentManager ?? (widget.currentN1?.toString() ?? l10n.notAssigned)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              EmployeeSearchField(
                searchController: _searchController,
                labelText: l10n.newManager,
                isSearching: _isSearching,
                isLoadingAllEmployees: false,
                searchResults: _results,
                allManagedEmployees: const [],
                validationErrors: _errors,
                validationKey: _kValidationKey,
                employeeType: EmployeeTypeSelection.direct,
                onEmployeeTypeToggle: (_) {},
                onSearchChanged: _onSearchChanged,
                onClearSearch: () {
                  _searchController.clear();
                  _onSearchChanged('');
                },
                onEmployeeSelected: _onEmployeeSelected,
                showEmployeeTypeToggle: false,
                showBrowseDropdown: false,
              ),

              if (_selected != null) ...[
                const SizedBox(height: 16),
                SelectedEmployeeSection(employee: _selected!, onClear: _clearSelection),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSaving ? null : () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
        ElevatedButton.icon(
          icon:
              _isSaving
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                  : const Icon(Icons.save, size: 18),
          label: Text(_isSaving ? l10n.processing : l10n.save),
          onPressed: (_selected != null && !_isSaving) ? _onSave : null,
        ),
      ],
    );
  }
}
