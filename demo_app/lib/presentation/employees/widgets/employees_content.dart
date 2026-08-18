import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_action_request_repo.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_request_repo.dart';
import 'package:hrms_demo/data/repos/investigation_request/investigation_request_repo.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunching_request_repo.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_request_repo.dart';
import 'package:hrms_demo/presentation/bulk_upload/bulk_upload_page.dart';
import 'package:hrms_demo/presentation/employees/widgets/add_employee_content.dart';
import 'package:hrms_demo/presentation/employees/widgets/requests_report_content.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_bloc.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_event.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_state.dart';
import 'package:hrms_demo/presentation/employees/widgets/edit_employee_content.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/data/repos/auth/auth_repo.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/employee_groups/widgets/employee_groups_page.dart';

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = EmployeesBloc(
          businessTripRequestRepository: context.read<BusinesstripRequestsRepo>(),
          leaveRequestRepository: context.read<LeaveRequestsRepo>(),
          missingPunchingRequestRepository: context.read<MissingpunchingRequestsRepo>(),
          overtimeRequestRepository: context.read<OvertimeRequestRepo>(),
          advanceOnSalaryRequestRepository: context.read<AdvanceOnSalaryRequestsRepo>(),
          hrLetterRequestRepository: context.read<HrLetterRequestRepo>(),
          disciplinaryActionRequestRepository: context.read<DisciplinaryActionRequestRepo>(),
          investigationRequestRepository: context.read<InvestigationRequestRepo>(),
          employeeRepository: context.read<UsersRepo>(),
          authRepo: context.read<AuthRepo>(),
        );

        // Add the initial event after bloc creation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          bloc.add(LoadEmployees(locale: Localizations.localeOf(context).languageCode));
        });

        return bloc;
      },
      child: const EmployeesView(),
    );
  }
}

class EmployeesView extends StatefulWidget {
  const EmployeesView({super.key});

  @override
  State<EmployeesView> createState() => _EmployeesViewState();
}

class _EmployeesViewState extends State<EmployeesView> {
  final TextEditingController _searchController = TextEditingController();
  late ScrollController _scrollController; // New

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(); // New
    _scrollController.addListener(_onScroll); // New
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose(); // New
    super.dispose();
  }

  void _onScroll() {
    // New method
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // User has scrolled to the end
      final bloc = context.read<EmployeesBloc>();
      if (bloc.state.status != EmployeesStatus.loading && !bloc.state.hasReachedMax && _searchController.text.isEmpty) {
        final currentLocale = Localizations.localeOf(context).languageCode;
        bloc.add(LoadMoreEmployees(locale: currentLocale));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final currentUser = context.read<UserBloc>().state.user;
    final isTopManagement = currentUser?.groups?.any((g) => g.toLowerCase() == 'top management') ?? false;
    return MainLayout(
      title: AppLocalizations.of(context)!.employeesList,
      child: SizedBox(
        height: context.screenHeight - 56.0,
        child: Column(
          children: [
            // Header with Add Employee Button and Search
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.grey[50],
              child: Align(
                alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Search Field
                      SizedBox(
                        height: 50,
                        width: context.screenWidth * 0.35,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.searchByNameOrCode,
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon:
                                _searchController.text.isNotEmpty
                                    ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        context.read<EmployeesBloc>().add(const ClearSearch());
                                      },
                                    )
                                    : null,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (value) {
                            final currentLocale = Localizations.localeOf(context).languageCode;
                            if (value.isEmpty) {
                              context.read<EmployeesBloc>().add(const ClearSearch());
                            } else {
                              context.read<EmployeesBloc>().add(SearchEmployees(value, locale: currentLocale));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      SizedBox(
                        height: 50,
                        width: 160,
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToAddEmployee(context),
                          icon: const Icon(Icons.person_add),
                          label: Text(AppLocalizations.of(context)!.addEmployee),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      SizedBox(
                        height: 50,
                        width: 200,
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToBulkUpload(context),
                          icon: const Icon(Icons.upload_file),
                          label: Text(AppLocalizations.of(context)!.bulkEmployeeUpload),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      SizedBox(
                        height: 50,
                        width: 160,
                        child: ElevatedButton.icon(
                          onPressed: () => _navigateToRequestsReport(context),
                          icon: const Icon(Icons.list_alt_outlined),
                          label: Text(AppLocalizations.of(context)!.requestsReport),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(12.0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      if (isTopManagement) ...[
                        const SizedBox(width: 16.0),
                        SizedBox(
                          height: 50,
                          width: 175,
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToEmployeeGroups(context),
                            icon: const Icon(Icons.manage_accounts),
                            label: Text(AppLocalizations.of(context)!.manageGroups),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(12.0),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Employee List
            Expanded(
              child: BlocConsumer<EmployeesBloc, EmployeesState>(
                listener: (context, state) {
                  if (state.status == EmployeesStatus.error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.errorMessage ?? 'An error occurred'), backgroundColor: Colors.red),
                    );
                  }
                },
                builder: (context, state) {
                  if (state.status == EmployeesStatus.loading && state.employees.isEmpty && state.isSearching) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == EmployeesStatus.error && state.employees.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('Failed to load employees', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              final currentLocale = Localizations.localeOf(context).languageCode;
                              context.read<EmployeesBloc>().add(LoadEmployees(locale: currentLocale));
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state.filteredEmployees.isEmpty && !state.isSearching) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            state.searchTerm.isNotEmpty ? Icons.search_off : Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.searchTerm.isNotEmpty
                                ? '${AppLocalizations.of(context)!.noEmployeesFoundMatching} "${state.searchTerm}"'
                                : AppLocalizations.of(context)!.noEmployeesYet,
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      final currentLocale = Localizations.localeOf(context).languageCode;
                      context.read<EmployeesBloc>().add(RefreshEmployees(locale: currentLocale));
                    },
                    child: ListView.builder(
                      controller: _scrollController, // Assign controller
                      padding: const EdgeInsets.all(16.0),
                      itemCount: state.filteredEmployees.length, //+
                      // (state.hasReachedMax
                      //     ? 0
                      //     : 1), // Add 1 for loading indicator
                      itemBuilder: (context, index) {
                        // if (index == state.filteredEmployees.length) {
                        //   return const Padding(
                        //     padding: EdgeInsets.symmetric(vertical: 16.0),
                        //     child: Center(child: CircularProgressIndicator()),
                        //   );
                        // }
                        final employee = state.filteredEmployees[index];
                        return _EmployeeCard(
                          employee: employee,
                          onTap: () => _navigateToEditEmployee(context, employee),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddEmployee(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BlocProvider.value(value: context.read<EmployeesBloc>(), child: const AddEmployeePage()),
      ),
    );
  }

  void _navigateToBulkUpload(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const BulkUploadPage()));
  }

  void _navigateToEditEmployee(BuildContext context, UserModel employee) async {
    // Get the current employees state
    final employeesBloc = context.read<EmployeesBloc>();
    final currentState = employeesBloc.state;

    // Find the latest version of this employee in the current state
    UserModel latestEmployee = employee; // Fallback to passed employee

    // Try to find updated employee in the main employees list
    final employeeInMainList = currentState.employees.where((emp) => emp.id == employee.id).firstOrNull;

    if (employeeInMainList != null) {
      latestEmployee = employeeInMainList;
    } else {
      // Try to find in filtered employees list
      final employeeInFilteredList = currentState.filteredEmployees.where((emp) => emp.id == employee.id).firstOrNull;

      if (employeeInFilteredList != null) {
        latestEmployee = employeeInFilteredList;
      }
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => BlocProvider.value(value: employeesBloc, child: EditEmployeePage(employee: latestEmployee)),
      ),
    );
  }

  void _navigateToRequestsReport(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => BlocProvider.value(
              value: context.read<EmployeesBloc>(),
              child: const RequestsReportContent(requests: [], withMultiUser: true),
            ),
      ),
    );
  }

  void _navigateToEmployeeGroups(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => const EmployeeGroupsPage()));
  }
}

class _EmployeeCard extends StatelessWidget {
  final UserModel employee;
  final VoidCallback onTap;

  const _EmployeeCard({required this.employee, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final displayName = _getLocalizedName(employee, currentLocale);
    final displayTitle = _getLocalizedTitle(employee, currentLocale);
    final displayDepartment = _getLocalizedDepartment(employee, currentLocale);

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(employee.email ?? ''),
            const SizedBox(height: 4),
            Text('$displayTitle • $displayDepartment', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  String _getLocalizedName(UserModel employee, String locale) {
    return employee.getLocalizedName(locale);
  }

  String _getLocalizedTitle(UserModel employee, String locale) {
    return employee.getLocalizedTitle(locale);
  }

  String _getLocalizedDepartment(UserModel employee, String locale) {
    return employee.getLocalizedDepartment(locale);
  }
}
