import 'dart:async';

import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/user_model.dart';
import '../bloc/employees_bloc.dart';
import '../bloc/employees_event.dart';
import '../bloc/employees_state.dart';

/// Dialog shown when suspending an employee who has direct reports.
/// Forces the admin to assign a new N+1 for every direct report
/// before the suspension can be confirmed.
class ReassignAndSuspendDialog extends StatefulWidget {
  final UserModel employeeBeingSuspended;
  final List<UserModel> directReports;

  /// Suspension reason/date already chosen in the SuspendReasonDialog; forwarded
  /// into the SuspendWithReassignment event so they land on the users record.
  final String suspensionReason;
  final DateTime? lastWorkingDate;

  const ReassignAndSuspendDialog({
    super.key,
    required this.employeeBeingSuspended,
    required this.directReports,
    required this.suspensionReason,
    this.lastWorkingDate,
  });

  @override
  State<ReassignAndSuspendDialog> createState() => _ReassignAndSuspendDialogState();
}

class _ReassignAndSuspendDialogState extends State<ReassignAndSuspendDialog> {
  /// Checkbox state: managedEmployee.id -> isSelected
  final Map<int, bool> _selectedRows = {};

  /// Assigned N+1: managedEmployee.id -> chosen UserModel
  final Map<int, UserModel> _assignedN1 = {};

  final TextEditingController _n1SearchController = TextEditingController();
  bool _isConfirming = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    for (final emp in widget.directReports) {
      _selectedRows[emp.id!] = false;
    }
    // Clear any stale N+1 search results from a previous dialog open.
    context.read<EmployeesBloc>().add(const SearchActiveEmployeesForReassignment(''));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _n1SearchController.dispose();
    context.read<EmployeesBloc>().add(const SearchActiveEmployeesForReassignment(''));
    super.dispose();
  }

  List<int> get _selectedIds => _selectedRows.entries.where((e) => e.value).map((e) => e.key).toList();

  bool get _allAssigned => _assignedN1.length == widget.directReports.length;

  bool get _allSelected => _selectedRows.isNotEmpty && _selectedRows.values.every((v) => v);

  bool get _anySelected => _selectedRows.values.any((v) => v);

  void _toggleSelectAll(bool? value) {
    setState(() {
      final newVal = value == true; // null (tristate from all-selected) → deselect all
      for (final key in _selectedRows.keys) {
        _selectedRows[key] = newVal;
      }
    });
  }

  void _applyN1ToSelected(UserModel newN1) {
    setState(() {
      for (final id in _selectedIds) {
        _assignedN1[id] = newN1;
        _selectedRows[id] = false; // deselect after assigning to prevent accidental re-assignment
      }
      _n1SearchController.clear();
    });
    context.read<EmployeesBloc>().add(const SearchActiveEmployeesForReassignment(''));
  }

  Future<void> _onConfirm() async {
    setState(() => _isConfirming = true);

    final Map<int, int> assignments = {for (final entry in _assignedN1.entries) entry.key: entry.value.id!};

    context.read<EmployeesBloc>().add(
      SuspendWithReassignment(
        employeeId: widget.employeeBeingSuspended.id!,
        n1Assignments: assignments,
        suspensionReason: widget.suspensionReason,
        lastWorkingDate: widget.lastWorkingDate,
      ),
    );

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final assignedCount = _assignedN1.length;
    final totalCount = widget.directReports.length;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.reassignDirectReports, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  l10n.suspendingEmployee(
                    widget.employeeBeingSuspended.getLocalizedName(locale).isNotEmpty
                        ? widget.employeeBeingSuspended.getLocalizedName(locale)
                        : widget.employeeBeingSuspended.id.toString(),
                  ),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _isConfirming ? null : () => Navigator.of(context).pop(false),
            tooltip: l10n.cancel,
          ),
        ],
      ),
      contentPadding: EdgeInsets.zero,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.directReportsAssignmentWarning,
                        style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Progress header
              _buildProgressHeader(assignedCount, totalCount, l10n),
              const SizedBox(height: 12),

              // Bulk assign toolbar
              _buildBulkAssignBar(l10n, locale),

              // Table
              _buildDirectReportsTable(l10n, locale),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isConfirming ? null : () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
        ElevatedButton.icon(
          icon:
              _isConfirming
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                  : const Icon(Icons.pause_circle, size: 18),
          label: Text(_isConfirming ? l10n.processing : l10n.confirmAndSuspend),
          style: ElevatedButton.styleFrom(
            backgroundColor: _allAssigned && !_isConfirming ? Colors.red[700] : Colors.grey[400],
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[400],
            disabledForegroundColor: Colors.white,
          ),
          onPressed: _allAssigned && !_isConfirming ? _onConfirm : null,
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    );
  }

  Widget _buildProgressHeader(int assignedCount, int totalCount, AppLocalizations l10n) {
    final allDone = assignedCount == totalCount;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.employeesAssignedProgress(assignedCount, totalCount),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: allDone ? Colors.green[700] : Colors.orange[700],
                ),
              ),
              if (allDone) Icon(Icons.check_circle, color: Colors.green[600], size: 18),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: totalCount == 0 ? 1.0 : assignedCount / totalCount,
              color: allDone ? Colors.green[600] : Colors.orange[600],
              backgroundColor: Colors.grey[200],
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkAssignBar(AppLocalizations l10n, String locale) {
    final hasSelection = _anySelected;
    final selectedCount = _selectedIds.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 6),
              Text(
                hasSelection
                    ? (selectedCount == 1 ? l10n.assignN1ToEmployee : l10n.assignN1ToEmployees(selectedCount))
                    : l10n.bulkAssignN1SelectFirst,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: hasSelection ? Colors.blue[700] : Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // TextField is intentionally outside any BlocBuilder to prevent
          // platform text input connection disruption on state changes.
          TextField(
            controller: _n1SearchController,
            enabled: hasSelection,
            decoration: InputDecoration(
              hintText: hasSelection ? l10n.searchByNameOrCode : l10n.selectRowsFirstToSearch,
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _n1SearchController,
                builder:
                    (_, textValue, __) => BlocBuilder<EmployeesBloc, EmployeesState>(
                      buildWhen: (prev, curr) => prev.isSearchingN1 != curr.isSearchingN1,
                      builder: (context, state) {
                        if (state.isSearchingN1) {
                          return const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          );
                        }
                        if (textValue.text.isNotEmpty) {
                          return IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _n1SearchController.clear();
                              _debounce?.cancel();
                              context.read<EmployeesBloc>().add(const SearchActiveEmployeesForReassignment(''));
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
              filled: true,
              fillColor: hasSelection ? Colors.white : Colors.grey[100],
            ),
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              if (value.isEmpty) {
                context.read<EmployeesBloc>().add(const SearchActiveEmployeesForReassignment(''));
                return;
              }
              _debounce = Timer(const Duration(milliseconds: 300), () {
                context.read<EmployeesBloc>().add(SearchActiveEmployeesForReassignment(value));
              });
            },
          ),

          // Results dropdown — scoped BlocBuilder so the TextField above never rebuilds
          BlocBuilder<EmployeesBloc, EmployeesState>(
            buildWhen: (prev, curr) => prev.n1SearchResults != curr.n1SearchResults,
            builder: (context, state) {
              if (state.n1SearchResults.isEmpty || !hasSelection) {
                return const SizedBox.shrink();
              }
              return Container(
                constraints: const BoxConstraints(maxHeight: 180),
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        state.n1SearchResults
                            .where((c) => c.id != widget.employeeBeingSuspended.id)
                            .map(
                              (candidate) => Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.blue[50],
                                    child: Icon(Icons.person, size: 16, color: Colors.blue[700]),
                                  ),
                                  title: Text(
                                    candidate.getLocalizedName(locale).isNotEmpty
                                        ? candidate.getLocalizedName(locale)
                                        : 'Unknown',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  subtitle: Text(
                                    '${candidate.id}  •  ${candidate.getLocalizedDepartment(locale)}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                  ),
                                  onTap: () => _applyN1ToSelected(candidate),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDirectReportsTable(AppLocalizations l10n, String locale) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.directReportsCount(widget.directReports.length),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 290),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 20,
                      headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                      dividerThickness: 1,
                      columns: [
                        DataColumn(
                          label: Checkbox(
                            tristate: true,
                            value:
                                _selectedRows.isEmpty
                                    ? false
                                    : _allSelected
                                    ? true
                                    : _anySelected
                                    ? null
                                    : false,
                            onChanged: _toggleSelectAll,
                          ),
                        ),
                        DataColumn(label: Text(l10n.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(l10n.code, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(l10n.department, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(l10n.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text(l10n.newN1, style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows:
                          widget.directReports.map((emp) {
                            final isSelected = _selectedRows[emp.id!] ?? false;
                            final assignedN1 = _assignedN1[emp.id!];
                            final displayName = emp.getLocalizedName(locale);
                            final displayDept = emp.getLocalizedDepartment(locale);
                            final displayTitle = emp.getLocalizedTitle(locale);

                            return DataRow(
                              selected: isSelected,
                              color: WidgetStateProperty.resolveWith((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return Colors.blue.withValues(alpha: 0.08);
                                }
                                if (assignedN1 != null) {
                                  return Colors.green[50];
                                }
                                return null;
                              }),
                              cells: [
                                DataCell(
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (value) => setState(() => _selectedRows[emp.id!] = value ?? false),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 200,
                                    child: Text(
                                      displayName.isEmpty ? 'N/A' : displayName,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(Text(emp.id.toString(), style: const TextStyle(fontSize: 13))),
                                DataCell(
                                  SizedBox(
                                    width: 160,
                                    child: Text(
                                      displayDept.isEmpty ? 'N/A' : displayDept,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 150,
                                    child: Text(
                                      displayTitle.isEmpty ? 'N/A' : displayTitle,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                DataCell(
                                  assignedN1 != null
                                      ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                                          const SizedBox(width: 4),
                                          SizedBox(
                                            width: 150,
                                            child: Text(
                                              assignedN1.getLocalizedName(locale).isNotEmpty
                                                  ? assignedN1.getLocalizedName(locale)
                                                  : 'Unknown',
                                              style: TextStyle(
                                                color: Colors.green[700],
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      )
                                      : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.radio_button_unchecked, color: Colors.grey[400], size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n.notAssigned,
                                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                          ),
                                        ],
                                      ),
                                ),
                              ],
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
