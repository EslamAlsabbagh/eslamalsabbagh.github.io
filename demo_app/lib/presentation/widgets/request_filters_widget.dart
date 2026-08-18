import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Status filter option model
class StatusFilterOption {
  final String value;
  final String Function(BuildContext) labelBuilder;

  const StatusFilterOption({required this.value, required this.labelBuilder});
}

/// Unified filter widget for request pages
/// Provides search, status filter, and month filter in a single row
class RequestFiltersWidget extends StatelessWidget {
  const RequestFiltersWidget({
    super.key,
    required this.searchQuery,
    required this.statusFilter,
    required this.selectedMonth,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onMonthChanged,
    this.statusOptions,
    this.searchHintText,
    this.onResetPage,
    this.showSearch = true,
    this.showStatus = true,
    this.availableMonths,
  });

  /// Current search query value
  final String searchQuery;

  /// Current status filter value
  final String statusFilter;

  /// Currently selected month (null means all months)
  final DateTime? selectedMonth;

  /// Callback when search query changes
  final ValueChanged<String> onSearchChanged;

  /// Callback when status filter changes
  final ValueChanged<String> onStatusChanged;

  /// Callback when month changes (null means all months)
  final ValueChanged<DateTime?> onMonthChanged;

  /// List of status options to display in dropdown
  /// If null, uses default common status options
  final List<StatusFilterOption>? statusOptions;

  /// Hint text for search field
  /// If null, uses default hint
  final String? searchHintText;

  /// Optional callback to reset pagination when filters change
  final VoidCallback? onResetPage;

  /// Whether to show the search field (default: true)
  /// Set to false for "My Requests" where searching by name/code is not needed
  final bool showSearch;

  /// Whether to show the status filter (default: true)
  /// Set to false for "Actionable" requests where all requests are pending
  final bool showStatus;

  /// Set of available months that have requests
  /// Format: Set of DateTime objects representing year-month (day is always 1)
  /// If null, all months are considered available (no graying out)
  final Set<DateTime>? availableMonths;

  /// Default status options used if none provided
  static List<StatusFilterOption> get defaultStatusOptions => [
    StatusFilterOption(value: 'all', labelBuilder: (context) => AppLocalizations.of(context)!.allStatus),
    StatusFilterOption(value: 'pending', labelBuilder: (context) => AppLocalizations.of(context)!.pending),
    StatusFilterOption(value: 'approved', labelBuilder: (context) => AppLocalizations.of(context)!.approved),
    StatusFilterOption(value: 'declined', labelBuilder: (context) => AppLocalizations.of(context)!.declined),
    StatusFilterOption(value: 'cancelled', labelBuilder: (context) => AppLocalizations.of(context)!.cancelled),
  ];

  /// Extended status options including pending employee confirmation
  static List<StatusFilterOption> get extendedStatusOptions => [
    ...defaultStatusOptions,
    StatusFilterOption(
      value: 'pending_employee_confirmation',
      labelBuilder: (context) => AppLocalizations.of(context)!.pendingEmployeeConfirmation,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final effectiveStatusOptions = statusOptions ?? defaultStatusOptions;
    final width = context.screenWidth > 700 ? context.screenWidth * 0.9 - 32 : 600 - 32;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8, left: 16, right: 8),
        child: SizedBox(
          width: width.toDouble() + 32,
          child: Row(
            children: [
              // Search Field (only show in Team Requests)
              if (showSearch) ...[
                SizedBox(
                  width: width * 0.4,
                  child: TextField(
                    onChanged: (value) {
                      onSearchChanged(value);
                      onResetPage?.call();
                    },
                    decoration: InputDecoration(
                      hintText: searchHintText ?? AppLocalizations.of(context)!.searchByNameOrCode,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Status Filter (hide in Actionable mode)
              if (showStatus) ...[
                SizedBox(
                  width: width * 0.35,
                  child: DropdownButtonFormField<String>(
                    value: statusFilter,
                    onChanged: (value) {
                      if (value != null) {
                        onStatusChanged(value);
                        onResetPage?.call();
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items:
                        effectiveStatusOptions
                            .map(
                              (option) =>
                                  DropdownMenuItem(value: option.value, child: Text(option.labelBuilder(context))),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // Month Filter
              SizedBox(
                width: width * 0.25,
                child: InkWell(
                  onTap: () async {
                    final selectedDate = await _showMonthYearPicker(context);
                    if (selectedDate != null) {
                      onMonthChanged(selectedDate);
                      onResetPage?.call();
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
                                  onMonthChanged(null);
                                  onResetPage?.call();
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
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a custom month and year picker dialog
  Future<DateTime?> _showMonthYearPicker(BuildContext context) async {
    final currentYear = DateTime.now().year;
    //final currentMonth = DateTime.now().month;
    final selectedYear = selectedMonth?.year ?? currentYear;
    final selectedMonthValue = selectedMonth?.month;

    // Calculate available years from availableMonths
    final availableYears = availableMonths != null ? availableMonths!.map((date) => date.year).toSet() : <int>{};

    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        int tempYear = selectedYear;
        int? tempMonth = selectedMonthValue;

        return StatefulBuilder(
          builder: (context, setState) {
            // Check if previous/next years have data
            final hasPreviousYear = availableMonths == null || availableYears.contains(tempYear - 1);
            final hasNextYear = availableMonths == null || availableYears.contains(tempYear + 1);

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
                        final isAvailable = availableMonths == null || availableMonths!.contains(monthDate);

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
                                      color: isAvailable ? null : Colors.grey.shade400,
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

  /// Returns localized month name based on current locale
  String _getLocalizedMonthName(BuildContext context, int month) {
    final locale = Localizations.localeOf(context);
    final date = DateTime(2024, month);
    return DateFormat.MMM(locale.languageCode).format(date);
  }
}
