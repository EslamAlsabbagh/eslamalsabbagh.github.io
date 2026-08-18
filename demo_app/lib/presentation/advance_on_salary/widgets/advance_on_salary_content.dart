import 'package:hrms_demo/core/constants/employee_type_selection.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/navigation_helper.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/advance_on_salary/widgets/advance_on_salary_page.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:hrms_demo/presentation/shared/employee_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hrms_demo/presentation/advance_on_salary/bloc/advance_on_salary_bloc.dart';
import 'package:hrms_demo/presentation/advance_on_salary/bloc/advance_on_salary_event.dart';
import 'package:hrms_demo/presentation/advance_on_salary/bloc/advance_on_salary_state.dart';
import 'package:hrms_demo/data/models/advance_on_salary_request_model.dart';

class AdvanceOnSalaryContent extends StatefulWidget {
  const AdvanceOnSalaryContent({super.key});

  @override
  State<AdvanceOnSalaryContent> createState() => _AdvanceOnSalaryContentState();
}

class _AdvanceOnSalaryContentState extends State<AdvanceOnSalaryContent> {
  final TextEditingController _employeeSearchController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _periodController = TextEditingController();
  final FocusNode _employeeSearchFocusNode = FocusNode();

  bool _isEligibleForAdvance(String? hireDate) {
    if (hireDate == null || hireDate.isEmpty) return false;

    try {
      DateTime hireDateParsed;

      if (hireDate.contains('/')) {
        // Handle DD/MM/YYYY format
        final parts = hireDate.split('/');
        if (parts.length == 3) {
          hireDateParsed = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else {
          return false;
        }
      } else if (hireDate.contains('-') && hireDate.split('-').length == 3) {
        // Handle D-MMM-YYYY format (e.g., "4-Dec-2024")
        final parts = hireDate.split('-');
        if (parts.length == 3) {
          final day = int.parse(parts[0]);
          final monthStr = parts[1];
          final year = int.parse(parts[2]);

          // Map month abbreviations to numbers
          final monthMap = {
            'Jan': 1,
            'Feb': 2,
            'Mar': 3,
            'Apr': 4,
            'May': 5,
            'Jun': 6,
            'Jul': 7,
            'Aug': 8,
            'Sep': 9,
            'Oct': 10,
            'Nov': 11,
            'Dec': 12,
          };

          final month = monthMap[monthStr];
          if (month == null) return false;

          hireDateParsed = DateTime(year, month, day);
        } else {
          return false;
        }
      } else {
        // Try parsing as ISO format
        hireDateParsed = DateTime.parse(hireDate);
      }

      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 6, now.day);

      return hireDateParsed.isBefore(sixMonthsAgo) || hireDateParsed.isAtSameMomentAs(sixMonthsAgo);
    } catch (e) {
      return false;
    }
  }

  bool _isWithinSubmissionWindow(DateTime? serverDate) {
    if (serverDate == null) return false;
    final currentDay = serverDate.day;
    return currentDay >= 15 && currentDay <= 25;
  }

  bool _isEligibleByAdvanceDate(DateTime? advanceEligibilityDate, DateTime? serverDate) {
    // If no eligibility date is set, assume eligible
    if (advanceEligibilityDate == null) return true;

    // If server date is not available, use local date as fallback
    final currentDate = serverDate ?? DateTime.now();

    // Employee is eligible if the eligibility date is today or before today
    return advanceEligibilityDate.isBefore(currentDate) || advanceEligibilityDate.isAtSameMomentAs(currentDate);
  }

  @override
  void initState() {
    super.initState();
    context.read<AdvanceOnSalaryBloc>().add(InitializeAdvanceOnSalaryForm());
  }

  @override
  void dispose() {
    _employeeSearchController.dispose();
    _amountController.dispose();
    _periodController.dispose();
    _employeeSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Align(
        alignment: Alignment.topLeft,
        child: SingleChildScrollView(
          child: BlocListener<AdvanceOnSalaryBloc, AdvanceOnSalaryState>(
            listener: (context, state) {
              if (state is AdvanceOnSalaryFormState) {
                if (state.isSubmissionSuccessful) {
                  final userBloc = context.read<UserBloc>();
                  final userId = userBloc.state.user?.id.toString();

                  userBloc.add(MarkRequestsAvailable(hasAdvanceRequests: true));
                  if (userId != null) {
                    userBloc.add(LoadUserProfile(userId));
                  }

                  NavigationHelper.pushReplacementWithSidebarSync(
                    context,
                    routeName: '/advance/new',
                    page: const AdvanceOnSalaryPage(),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.advanceOnSalarySubmittedSuccessfully)),
                  );
                } else if (state.submissionError != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: ${state.submissionError}')));
                }
              }
            },
            child: BlocBuilder<AdvanceOnSalaryBloc, AdvanceOnSalaryState>(
              builder: (context, state) {
                if (state is AdvanceOnSalaryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AdvanceOnSalaryError) {
                  return Center(child: Text(state.message, style: TextStyle(color: Colors.red[600])));
                }

                if (state is AdvanceOnSalaryFormState) {
                  return _buildFormContent(context, state);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, AdvanceOnSalaryFormState state) {
    final isWithinSubmissionWindow = _isWithinSubmissionWindow(state.serverDate);
    final isEligible = _isEligibleForAdvance(state.hireDate);
    final isEligibleByAdvanceDate = _isEligibleByAdvanceDate(
      state.selectedEmployee?.advanceOnSalaryEligibilityDate,
      state.serverDate,
    );
    final hasPendingRequest = state.hasPendingRequest;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: context.screenWidth < 600 ? 600 : context.screenWidth - 65,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Form Title
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Theme.of(context).primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.advanceOnSalaryRequestTitle,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Employee Search Field - Always visible at the top
              _buildEmployeeSearchField(context, state),

              const SizedBox(height: 16),

              // Selected Employee Details Section
              if (state.selectedEmployee != null) ...[
                _buildSelectedEmployeeSection(context, state),
                const SizedBox(height: 16),
              ],

              // Show loading indicator if checking for pending request
              if (state.isCheckingPendingRequest) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.blue[600]),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.checkingPendingRequests,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.blue[700]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Show loading indicator if server date is being fetched
              if (state.isLoadingServerDate) ...[
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(AppLocalizations.of(context)!.loading),
                    ],
                  ),
                ),
              ] else if (state.serverDate == null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.error, color: Colors.red[600], size: 48),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.unableToVerifyCurrentDate,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.checkInternetConnectionAndRetry,
                        style: TextStyle(fontSize: 14, color: Colors.red[600]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ] else if (!isWithinSubmissionWindow) ...[
                // invert this check to show form only within submission window
                _buildSubmissionWindowMessage(context),
              ] else ...[
                // Show eligibility message or form fields
                if (!isEligible && state.selectedEmployee != null) ...[
                  _buildNotEligibleMessage(context),
                ] else if (!isEligibleByAdvanceDate && state.selectedEmployee != null) ...[
                  _buildNotEligibleByAdvanceDateMessage(context, state),
                ] else if (hasPendingRequest && state.selectedEmployee != null) ...[
                  _buildPendingRequestMessage(context),
                ] else if (isEligible &&
                    isEligibleByAdvanceDate &&
                    !hasPendingRequest &&
                    state.selectedEmployee != null) ...[
                  // Amount Requested (Input)
                  _buildAmountRequestedField(context, state),

                  const SizedBox(height: 16),

                  // Amount in Letters (Calculated)
                  _buildReadOnlyField(
                    label: AppLocalizations.of(context)!.amountInLetters,
                    value: () {
                      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                      final amountInLetters = isArabic ? state.amountInLettersArabic : state.amountInLettersEnglish;
                      return amountInLetters.isEmpty ? AppLocalizations.of(context)!.willBeCalculated : amountInLetters;
                    }(),
                    icon: Icons.text_fields,
                  ),

                  const SizedBox(height: 16),

                  // Period in Months (Input or Calculated for new employees)
                  _buildPeriodField(context, state),

                  const SizedBox(height: 16),

                  // Payment Start Date (Input)
                  _buildPaymentStartDateField(context, state),

                  const SizedBox(height: 16),

                  // Payment End Date (Calculated)
                  _buildReadOnlyField(
                    label: AppLocalizations.of(context)!.paymentEndDate,
                    value:
                        state.paymentEndDate != null
                            ? DateFormat('dd/MM/yyyy').format(state.paymentEndDate!)
                            : AppLocalizations.of(context)!.willBeCalculated,
                    icon: Icons.date_range,
                  ),

                  const SizedBox(height: 16),

                  // Monthly Payment (Calculated)
                  _buildReadOnlyField(
                    label: AppLocalizations.of(context)!.monthlyPayment,
                    value:
                        state.monthlyPayment != null
                            ? '${state.monthlyPayment!.toStringAsFixed(2)} EGP'
                            : AppLocalizations.of(context)!.willBeCalculated,
                    icon: Icons.payment,
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  SizedBox(
                    width: context.screenWidth < 600 ? context.screenWidth - 81 : context.screenWidth - 65,
                    child: _buildActionButtons(context, state),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedEmployeeSection(BuildContext context, AdvanceOnSalaryFormState state) {
    final employee = state.selectedEmployee!;
    final displayName = _getDisplayName(context, employee.englishName, employee.arabicName);

    return Column(
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.person_pin, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)!.selectedEmployee,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Employee details grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      label: AppLocalizations.of(context)!.name,
                      value: displayName.isEmpty ? AppLocalizations.of(context)!.unknown : displayName,
                      icon: Icons.person,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      label: AppLocalizations.of(context)!.code,
                      value: employee.id?.toString() ?? 'N/A',
                      icon: Icons.badge,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      label: AppLocalizations.of(context)!.hireDate,
                      value: employee.hireDate ?? 'N/A',
                      icon: Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.blue[700], size: 18),
                    onPressed: () {
                      _employeeSearchController.clear();
                      context.read<AdvanceOnSalaryBloc>().add(ResetForm());
                    },
                    tooltip: AppLocalizations.of(context)!.clearSelection,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue[600])),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.blue[700]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                value,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.blue[800]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmployeeSearchField(BuildContext context, AdvanceOnSalaryFormState state) {
    return EmployeeSearchField(
      searchController: _employeeSearchController,
      searchFocusNode: _employeeSearchFocusNode,
      isSearching: state.isSearching,
      isLoadingAllEmployees: state.isLoadingAllEmployees,
      searchResults: state.employeeSearchResults,
      allManagedEmployees: _getAllEmployeesForCurrentType(state),
      validationErrors: state.validationErrors,
      validationKey: 'employee',
      employeeType: state.employeeType,
      onEmployeeTypeToggle: (employeeType) {
        _employeeSearchController.clear();
        context.read<AdvanceOnSalaryBloc>().add(ResetForm());
        context.read<AdvanceOnSalaryBloc>().add(ToggleEmployeeType(employeeType));
      },
      onSearchChanged: (value) {
        if (value.trim().isNotEmpty) {
          context.read<AdvanceOnSalaryBloc>().add(SearchEmployees(value.trim()));
        } else {
          context.read<AdvanceOnSalaryBloc>().add(ClearSearchResults());
        }
      },
      onClearSearch: () {
        _employeeSearchController.clear();
        context.read<AdvanceOnSalaryBloc>().add(ClearSearchResults());
      },
      onEmployeeSelected: (employee) {
        context.read<AdvanceOnSalaryBloc>().add(SelectEmployee(employee));
      },
    );
  }

  Widget _buildAmountRequestedField(BuildContext context, AdvanceOnSalaryFormState state) {
    final hasError = state.validationErrors.containsKey('amount');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.amountRequestedEgp,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasError ? Colors.red : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.enterAmountBetween,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            prefixIcon: const Icon(Icons.money, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
                width: hasError ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
                width: hasError ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hasError ? Colors.red : Theme.of(context).primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          onChanged: (value) {
            final amount = double.tryParse(value);
            if (amount != null) {
              context.read<AdvanceOnSalaryBloc>().add(UpdateAmountRequested(amount));
            }
          },
        ),

        // Error message
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(state.validationErrors['amount']!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildPeriodField(BuildContext context, AdvanceOnSalaryFormState state) {
    final hasError = state.validationErrors.containsKey('period');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.periodInMonths,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasError ? Colors.red : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _periodController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.enterPeriodBetween,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
            prefixIcon: const Icon(Icons.calendar_view_month, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
                width: hasError ? 2 : 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
                width: hasError ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hasError ? Colors.red : Theme.of(context).primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          onChanged: (value) {
            final months = int.tryParse(value);
            if (months != null && months > 0) {
              context.read<AdvanceOnSalaryBloc>().add(UpdatePeriodInMonths(months));
            }
          },
        ),

        // Error message
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(state.validationErrors['period']!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildPaymentStartDateField(BuildContext context, AdvanceOnSalaryFormState state) {
    final hasError = state.validationErrors.containsKey('paymentStartDate');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.paymentStartDate,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasError ? Colors.red : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectStartDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
                width: hasError ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20),
                const SizedBox(width: 12),
                Text(
                  state.paymentStartDate != null
                      ? DateFormat('dd/MM/yyyy').format(state.paymentStartDate!)
                      : AppLocalizations.of(context)!.mustBeOnFirstDay,
                  style: TextStyle(
                    fontSize: state.paymentStartDate != null ? 14 : 12,
                    fontWeight: FontWeight.w500,
                    fontStyle: state.paymentStartDate != null ? null : FontStyle.italic,
                    color:
                        hasError
                            ? Colors.red
                            : state.paymentStartDate != null
                            ? Colors.black87
                            : Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Icon(Icons.arrow_drop_down, color: hasError ? Colors.red : null),
              ],
            ),
          ),
        ),

        // Error message
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              state.validationErrors['paymentStartDate']!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmissionWindowMessage(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(Icons.schedule, color: Colors.orange[600], size: 48),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.requestsCantBeSubmitted,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.submissionWindowMessage,
            style: TextStyle(fontSize: 14, color: Colors.orange[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotEligibleMessage(BuildContext context) {
    // Calculate eligibility date: hire date + 6 months at day 15
    String eligibilityDateText = 'N/A';
    final state = context.read<AdvanceOnSalaryBloc>().state;
    if (state is AdvanceOnSalaryFormState && state.selectedEmployee?.hireDate != null) {
      try {
        DateTime hireDateParsed;
        final hireDate = state.selectedEmployee!.hireDate!;

        if (hireDate.contains('/')) {
          // Handle DD/MM/YYYY format
          final parts = hireDate.split('/');
          if (parts.length == 3) {
            hireDateParsed = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          } else {
            throw Exception('Invalid date format');
          }
        } else if (hireDate.contains('-') && hireDate.split('-').length == 3) {
          // Handle D-MMM-YYYY format (e.g., "4-Dec-2024")
          final parts = hireDate.split('-');
          if (parts.length == 3) {
            final day = int.parse(parts[0]);
            final monthStr = parts[1];
            final year = int.parse(parts[2]);

            // Map month abbreviations to numbers
            final monthMap = {
              'Jan': 1,
              'Feb': 2,
              'Mar': 3,
              'Apr': 4,
              'May': 5,
              'Jun': 6,
              'Jul': 7,
              'Aug': 8,
              'Sep': 9,
              'Oct': 10,
              'Nov': 11,
              'Dec': 12,
            };

            final month = monthMap[monthStr];
            if (month == null) throw Exception('Invalid month');

            hireDateParsed = DateTime(year, month, day);
          } else {
            throw Exception('Invalid date format');
          }
        } else {
          // Try parsing as ISO format
          hireDateParsed = DateTime.parse(hireDate);
        }

        // Calculate eligibility date: hire date + 6 months, set to day 15
        final eligibilityDate = DateTime(
          hireDateParsed.year,
          hireDateParsed.month + (hireDateParsed.day > 25 ? 7 : 6),
          hireDateParsed.day < 15 || hireDateParsed.day > 25 ? 15 : hireDateParsed.day,
        );
        eligibilityDateText = DateFormat('dd/MM/yyyy').format(eligibilityDate);
      } catch (e) {
        eligibilityDateText = 'N/A';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!, width: 1.5),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.notEligibleForAdvance,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.tenureLessThanSixMonths,
            style: TextStyle(fontSize: 14, color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.advanceEligibilityDateRestriction(eligibilityDateText),
            style: TextStyle(fontSize: 14, color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotEligibleByAdvanceDateMessage(BuildContext context, AdvanceOnSalaryFormState state) {
    DateTime? eligibilityDate = state.selectedEmployee?.advanceOnSalaryEligibilityDate;
    eligibilityDate = eligibilityDate?.add(Duration(days: 14)); // Add 14 day to the date
    final formattedDate = eligibilityDate != null ? DateFormat('dd/MM/yyyy').format(eligibilityDate) : 'N/A';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.notEligibleForAdvance,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.currentAdvanceOnSalaryRequest,
            style: TextStyle(fontSize: 14, color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.advanceEligibilityDateRestriction(formattedDate),
            style: TextStyle(fontSize: 14, color: Colors.red[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestMessage(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[200]!, width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            AppLocalizations.of(context)!.pendingRequestExists,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.pendingRequestMessage,
            style: TextStyle(fontSize: 14, color: Colors.amber[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({required String label, required String value, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.grey[600]),
              const SizedBox(width: 12),
              Expanded(child: Text(value, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500))),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, AdvanceOnSalaryFormState state) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            onPressed:
                state.isSubmitting
                    ? null
                    : state.isFormValid
                    ? () => _submitForm(context, state)
                    : () {
                      // Trigger validation to show errors
                      context.read<AdvanceOnSalaryBloc>().add(ValidateForm());
                    },
            label: state.isSubmitting ? AppLocalizations.of(context)!.submitting : AppLocalizations.of(context)!.submit,
          ),
        ),
      ],
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final now = DateTime.now();
    final oneMonthFromNow = DateTime(now.year, now.month + 1, 1);
    final twoMonthsFromNow = DateTime(now.year, now.month + 2, 1);

    // Show dialog with two options instead of date picker
    final DateTime? selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectPaymentStartDate),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('MMMM 1, yyyy').format(oneMonthFromNow)),
                onTap: () => Navigator.of(context).pop(oneMonthFromNow),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(DateFormat('MMMM 1, yyyy').format(twoMonthsFromNow)),
                onTap: () => Navigator.of(context).pop(twoMonthsFromNow),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(AppLocalizations.of(context)!.cancel)),
          ],
        );
      },
    );

    if (selectedDate != null && context.mounted) {
      context.read<AdvanceOnSalaryBloc>().add(UpdatePaymentStartDate(selectedDate));
    }
  }

  String _getDisplayName(BuildContext context, String? englishName, String? arabicName) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? (arabicName ?? englishName ?? '') : (englishName ?? arabicName ?? '');
  }

  void _submitForm(BuildContext context, AdvanceOnSalaryFormState state) async {
    if (state.selectedEmployee == null ||
        state.amountRequested == null ||
        state.periodInMonths == null ||
        state.paymentStartDate == null ||
        state.paymentEndDate == null ||
        state.monthlyPayment == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.pleaseFillAllRequiredFields)));
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(context, state);
    if (confirmed != true || !context.mounted) return;

    // Determine the initial approver:
    // If creating for indirect employee (N+2), skip N+2 approval and go straight to HR
    // If creating for direct employee (N+1), start with N+2 approval
    final currentUser = context.read<UserBloc>().state.user!;
    final isIndirectEmployee = state.employeeType != EmployeeTypeSelection.direct;
    final initialApprover = isIndirectEmployee ? 'hr' : 'n2';

    final request = AdvanceOnSalaryRequestModel(
      requestorCode: currentUser.id!,
      borrowerCode: state.selectedEmployee!.id,
      n2Code: state.selectedEmployee!.n2,
      amount: state.amountRequested,
      amountInLettersArabic: state.amountInLettersArabic,
      amountInLettersEnglish: state.amountInLettersEnglish,
      monthlyPayment: state.monthlyPayment,
      paymentStartDate: state.paymentStartDate,
      paymentEndDate: state.paymentEndDate,
      periodInMonths: state.periodInMonths,
      currentApprover: initialApprover,
      status: 'pending',
    );

    context.read<AdvanceOnSalaryBloc>().add(SubmitAdvanceOnSalaryRequest(request));
  }

  Future<bool?> _showConfirmationDialog(BuildContext context, AdvanceOnSalaryFormState state) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final displayName = _getDisplayName(
      context,
      state.selectedEmployee!.englishName,
      state.selectedEmployee!.arabicName,
    );

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmSubmitRequest),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.areYouSureToSubmitRequest,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildConfirmationDetailRow(
                  context,
                  label: AppLocalizations.of(context)!.name,
                  value: displayName,
                  icon: Icons.person,
                ),
                const SizedBox(height: 12),
                _buildConfirmationDetailRow(
                  context,
                  label: AppLocalizations.of(context)!.amountRequestedEgp,
                  value: '${state.amountRequested!.toStringAsFixed(2)} EGP',
                  icon: Icons.money,
                ),
                const SizedBox(height: 12),
                _buildConfirmationDetailRow(
                  context,
                  label: AppLocalizations.of(context)!.amountInLetters,
                  value: isArabic ? state.amountInLettersArabic : state.amountInLettersEnglish,
                  icon: Icons.text_fields,
                ),
                const SizedBox(height: 12),
                _buildConfirmationDetailRow(
                  context,
                  label: AppLocalizations.of(context)!.periodInMonths,
                  value: '${state.periodInMonths} ${AppLocalizations.of(context)!.months}',
                  icon: Icons.calendar_view_month,
                ),
                const SizedBox(height: 12),
                _buildConfirmationDetailRow(
                  context,
                  label: AppLocalizations.of(context)!.paymentStartDate,
                  value: DateFormat('dd/MM/yyyy').format(state.paymentStartDate!),
                  icon: Icons.date_range,
                ),
                const SizedBox(height: 12),
                _buildConfirmationDetailRow(
                  context,
                  label: AppLocalizations.of(context)!.paymentEndDate,
                  value: DateFormat('dd/MM/yyyy').format(state.paymentEndDate!),
                  icon: Icons.date_range,
                ),
                const SizedBox(height: 12),
                _buildConfirmationDetailRow(
                  context,
                  label: AppLocalizations.of(context)!.monthlyPayment,
                  value: '${state.monthlyPayment!.toStringAsFixed(2)} EGP',
                  icon: Icons.payment,
                ),
                const SizedBox(height: 8),
                const Divider(),
              ],
            ),
          ),
          actions: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 300),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      label: AppLocalizations.of(context)!.cancel,
                      color: Colors.red,
                      width: 120,
                    ),
                    const SizedBox(width: 16),
                    AppButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      label: AppLocalizations.of(context)!.submit,
                      width: 120,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmationDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  List<UserModel> _getAllEmployeesForCurrentType(AdvanceOnSalaryFormState state) {
    switch (state.employeeType) {
      case EmployeeTypeSelection.direct:
        return state.allManagedEmployees;
      case EmployeeTypeSelection.indirect:
        return state.allIndirectEmployees;
      case EmployeeTypeSelection.allSubordinates:
        return state.allDeepSubordinates;
    }
  }
}
