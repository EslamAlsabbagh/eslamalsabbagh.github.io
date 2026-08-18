import 'package:hrms_demo/core/constants/employee_type_selection.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/hr_tools/bloc/hr_tools_bloc.dart';
import 'package:hrms_demo/presentation/hr_tools/bloc/hr_tools_event.dart';
import 'package:hrms_demo/presentation/hr_tools/bloc/hr_tools_state.dart';
import 'package:hrms_demo/presentation/hr_tools/widgets/bulk_leave_result_dialog.dart';
import 'package:hrms_demo/presentation/hr_tools/widgets/bulk_leave_tab.dart';
import 'package:hrms_demo/presentation/hr_tools/widgets/bulk_overtime_tab.dart';
import 'package:hrms_demo/presentation/shared/employee_search_field.dart';
import 'package:hrms_demo/presentation/shared/selected_employee_section.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HrToolsContent extends StatefulWidget {
  const HrToolsContent({super.key});

  @override
  State<HrToolsContent> createState() => _HrToolsContentState();
}

class _HrToolsContentState extends State<HrToolsContent> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<HrToolsBloc>().add(HrToolsTabChanged(_tabController.index));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MainLayout(
      child: BlocConsumer<HrToolsBloc, HrToolsState>(
        listenWhen:
            (prev, curr) => prev.successMessage != curr.successMessage || prev.errorMessage != curr.errorMessage,
        listener: (context, state) {
          if (state.successMessage == 'bulk_leaves_partial') {
            // Normal-cycle submission where the server rejected some employees —
            // a snackbar can't carry per-employee reasons, so report in a dialog.
            BulkLeaveResultDialog.show(
              context,
              createdCount: state.submissionSuccessCount,
              totalCount: state.submissionSuccessCount + state.submissionFailures.length,
              failures: state.submissionFailures,
            );
            context.read<HrToolsBloc>().add(const HrToolsMessageCleared());
          } else if (state.successMessage == 'bulk_leaves_success_note_failed') {
            // The leave row is committed and cannot be rolled back — only the
            // medical report upload failed, so report it as a warning rather
            // than a plain success.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.bulkLeaveNoteUploadFailed),
                backgroundColor: Colors.orange.shade800,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<HrToolsBloc>().add(const HrToolsMessageCleared());
          } else if (state.successMessage != null) {
            final msg =
                state.successMessage == 'bulk_leaves_success'
                    ? l10n.bulkLeavesSubmittedSuccessfully
                    : l10n.bulkOvertimeSubmittedSuccessfully;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
            );
            context.read<HrToolsBloc>().add(const HrToolsMessageCleared());
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.read<HrToolsBloc>().add(const HrToolsMessageCleared());
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: context.screenWidth < 600 ? 600 - 113 : context.screenWidth - 113,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.hrTools, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),

                    // Employee search — search-only, no toggle, no browse dropdown
                    EmployeeSearchField(
                      searchController: _searchController,
                      searchFocusNode: _searchFocusNode,
                      isSearching: state.isSearching,
                      isLoadingAllEmployees: false,
                      searchResults: state.searchResults,
                      allManagedEmployees: const [],
                      validationErrors: state.validationErrors,
                      validationKey: 'employees',
                      employeeType: EmployeeTypeSelection.direct,
                      onEmployeeTypeToggle: (_) {},
                      onSearchChanged: (query) {
                        context.read<HrToolsBloc>().add(HrToolsEmployeeSearchChanged(query));
                      },
                      onClearSearch: () {
                        _searchController.clear();
                        context.read<HrToolsBloc>().add(const HrToolsSearchCleared());
                      },
                      onEmployeeSelected: (employee) {
                        context.read<HrToolsBloc>().add(HrToolsEmployeeAdded(employee));
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                      },
                      multiSelect: true,
                      selectedEmployees: state.selectedEmployees,
                      onEmployeeAdded: (employee) {
                        context.read<HrToolsBloc>().add(HrToolsEmployeeAdded(employee));
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                      },
                      onEmployeeRemoved: (employee) {
                        context.read<HrToolsBloc>().add(HrToolsEmployeeRemoved(employee));
                      },
                      onClearAllEmployees: () {
                        context.read<HrToolsBloc>().add(const HrToolsAllEmployeesCleared());
                      },
                      showEmployeeTypeToggle: false,
                      showBrowseDropdown: false,
                    ),

                    // Selected employees chips
                    if (state.selectedEmployees.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 250),
                        child: SingleChildScrollView(
                          child: SelectedEmployeeSection.multiSelect(
                            employees: state.selectedEmployees,
                            onRemoveEmployee: (employee) {
                              context.read<HrToolsBloc>().add(HrToolsEmployeeRemoved(employee));
                            },
                            onClearAll: () {
                              context.read<HrToolsBloc>().add(const HrToolsAllEmployeesCleared());
                            },
                          ),
                        ),
                      ),
                    ],

                    // Validation error for employees
                    if (state.validationErrors.containsKey('employees')) ...[
                      const SizedBox(height: 6),
                      Text(l10n.selectEmployeesFirst, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],

                    const SizedBox(height: 24),

                    // Tabs
                    Container(
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Theme.of(context).primaryColor,
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: Theme.of(context).primaryColor,
                        indicatorSize: TabBarIndicatorSize.tab,
                        dividerColor: Colors.transparent,
                        tabs: [Tab(text: l10n.bulkLeaves), Tab(text: l10n.bulkOvertimeIncrement)],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tab content — not using TabBarView to avoid scroll conflicts
                    if (_tabController.index == 0) const BulkLeaveTab() else const BulkOvertimeTab(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
