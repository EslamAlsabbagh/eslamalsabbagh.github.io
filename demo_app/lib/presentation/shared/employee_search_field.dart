import 'package:hrms_demo/core/constants/employee_type_selection.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/display_name_utils.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

class EmployeeSearchField extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode? searchFocusNode;
  final String? labelText;
  final String? hintText;
  final bool isSearching;
  final bool isLoadingAllEmployees;
  final List<UserModel> searchResults;
  final List<UserModel> allManagedEmployees;
  final Map<String, String> validationErrors;
  final String validationKey;
  final EmployeeTypeSelection employeeType;
  final Function(EmployeeTypeSelection) onEmployeeTypeToggle;
  final Function(String) onSearchChanged;
  final VoidCallback onClearSearch;
  final Function(UserModel) onEmployeeSelected;

  // Multi-select mode parameters
  final bool multiSelect;
  final List<UserModel> selectedEmployees;
  final Function(UserModel)? onEmployeeAdded;
  final Function(UserModel)? onEmployeeRemoved;
  final VoidCallback? onClearAllEmployees;

  // Display toggles — set false to hide sections not needed (e.g. HR all-employees mode)
  final bool showEmployeeTypeToggle;
  final bool showBrowseDropdown;

  // When false, keep the picked value in the search box after selection instead of
  // clearing it (e.g. the Edit Employee N+1 picker shows the selected manager's code).
  final bool clearOnSelect;

  const EmployeeSearchField({
    super.key,
    required this.searchController,
    this.searchFocusNode,
    this.labelText,
    this.hintText,
    required this.isSearching,
    required this.isLoadingAllEmployees,
    required this.searchResults,
    required this.allManagedEmployees,
    required this.validationErrors,
    required this.validationKey,
    required this.employeeType,
    required this.onEmployeeTypeToggle,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onEmployeeSelected,
    // Multi-select defaults
    this.multiSelect = false,
    this.selectedEmployees = const [],
    this.onEmployeeAdded,
    this.onEmployeeRemoved,
    this.onClearAllEmployees,
    this.showEmployeeTypeToggle = true,
    this.showBrowseDropdown = true,
    this.clearOnSelect = true,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = validationErrors.containsKey(validationKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Segment Control for Direct/Indirect/All Subordinates Selection
        if (showEmployeeTypeToggle) ...[_buildEmployeeTypeToggle(context), const SizedBox(height: 12)],
        Text(
          labelText ??
              (multiSelect
                  ? AppLocalizations.of(context)!.selectEmployees
                  : AppLocalizations.of(context)!.selectEmployee),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasError ? Colors.red : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            decoration: InputDecoration(
              hintText: hintText ?? AppLocalizations.of(context)!.searchByNameOrCode,
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon:
                  isSearching
                      ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                      : searchController.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear, size: 20), onPressed: onClearSearch)
                      : null,

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
            onChanged: onSearchChanged,
          ),
        ),

        // Browse All Employees Dropdown - Conditionally visible
        if (showBrowseDropdown) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
                width: hasError ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                isLoadingAllEmployees
                    ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Row(
                        children: [
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 12),
                          Text(AppLocalizations.of(context)!.loading, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    )
                    : DropdownButtonHideUnderline(
                      child: DropdownButton2<UserModel>(
                        isExpanded: true,
                        // Always show hint (no valueListenable = no selection)
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            children: [
                              const Icon(Icons.people, size: 20),
                              const SizedBox(width: 12),
                              Text(_getBrowseText(context), style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                        iconStyleData: const IconStyleData(
                          icon: Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.arrow_drop_down)),
                        ),
                        buttonStyleData: ButtonStyleData(
                          height: 50,
                          padding: EdgeInsets.zero,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                        ),
                        dropdownStyleData: DropdownStyleData(
                          maxHeight: 300,
                          width: context.screenWidth < 600 ? context.screenWidth - 89 : null,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          offset: const Offset(0, -5),
                          scrollbarTheme: ScrollbarThemeData(
                            radius: const Radius.circular(40),
                            thickness: WidgetStateProperty.all(6),
                            thumbVisibility: WidgetStateProperty.all(true),
                          ),
                        ),
                        menuItemStyleData: const MenuItemStyleData(padding: EdgeInsets.symmetric(horizontal: 8)),
                        items:
                            allManagedEmployees.map((employee) {
                              final displayName = DisplayNameUtils.getDisplayName(
                                context,
                                employee.englishName,
                                employee.arabicName,
                              );
                              final isAlreadySelected =
                                  multiSelect && selectedEmployees.any((e) => e.id == employee.id);
                              return DropdownItem<UserModel>(
                                value: employee,
                                enabled: !isAlreadySelected,
                                height: 60,
                                key: ValueKey('employee_${employee.id}'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            isAlreadySelected
                                                ? Colors.green.withValues(alpha: 0.1)
                                                : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                        radius: 16,
                                        child: Icon(
                                          isAlreadySelected ? Icons.check : Icons.person,
                                          color: isAlreadySelected ? Colors.green : Theme.of(context).primaryColor,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              displayName.isEmpty ? AppLocalizations.of(context)!.unknown : displayName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: isAlreadySelected ? Colors.grey : null,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              '${AppLocalizations.of(context)!.code}: ${employee.id?.toString() ?? 'N/A'}',
                                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                        onChanged: (UserModel? selectedEmployee) {
                          if (selectedEmployee != null) {
                            if (multiSelect) {
                              onEmployeeAdded?.call(selectedEmployee);
                            } else {
                              onEmployeeSelected(selectedEmployee);
                            }
                            // Keep search field empty to show hint text
                            if (clearOnSelect) searchController.clear();
                            searchFocusNode?.unfocus();
                          }
                        },
                      ),
                    ),
          ),
        ], // end showBrowseDropdown
        // Search Results Dropdown - Always visible when there are results
        if (searchResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  searchResults.map((employee) {
                    final displayName = DisplayNameUtils.getDisplayName(
                      context,
                      employee.englishName,
                      employee.arabicName,
                    );
                    final isAlreadySelected = multiSelect && selectedEmployees.any((e) => e.id == employee.id);
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          isAlreadySelected ? Icons.check_circle : Icons.person,
                          size: 18,
                          color: isAlreadySelected ? Colors.green : null,
                        ),
                        title: Text(
                          displayName.isEmpty ? AppLocalizations.of(context)!.unknown : displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isAlreadySelected ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Text(
                          '${AppLocalizations.of(context)!.code}: ${employee.id?.toString() ?? 'N/A'}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        enabled: !isAlreadySelected,
                        onTap:
                            isAlreadySelected
                                ? null
                                : () {
                                  if (multiSelect) {
                                    onEmployeeAdded?.call(employee);
                                  } else {
                                    onEmployeeSelected(employee);
                                  }
                                  // Keep search field empty to show hint text
                                  if (clearOnSelect) searchController.clear();
                                  searchFocusNode?.unfocus();
                                },
                      ),
                    );
                  }).toList(),
            ),
          ),
        // Error message
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(validationErrors[validationKey]!, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildEmployeeTypeToggle(BuildContext context) {
    return Container(
      width: context.screenWidth > 450 ? 450 : context.screenWidth * 0.95,
      height: 40,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onEmployeeTypeToggle(EmployeeTypeSelection.direct),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        employeeType == EmployeeTypeSelection.direct
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          employeeType == EmployeeTypeSelection.direct ? Theme.of(context).primaryColor : Colors.white,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppLocalizations.of(context)!.directEmployees,
                    style: TextStyle(
                      color: employeeType == EmployeeTypeSelection.direct ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onEmployeeTypeToggle(EmployeeTypeSelection.indirect),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        employeeType == EmployeeTypeSelection.indirect
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          employeeType == EmployeeTypeSelection.indirect
                              ? Theme.of(context).primaryColor
                              : Colors.white,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppLocalizations.of(context)!.indirectEmployees,
                    style: TextStyle(
                      color: employeeType == EmployeeTypeSelection.indirect ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onEmployeeTypeToggle(EmployeeTypeSelection.allSubordinates),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        employeeType == EmployeeTypeSelection.allSubordinates
                            ? Theme.of(context).primaryColor
                            : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          employeeType == EmployeeTypeSelection.allSubordinates
                              ? Theme.of(context).primaryColor
                              : Colors.white,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    AppLocalizations.of(context)!.allSubordinates,
                    style: TextStyle(
                      color: employeeType == EmployeeTypeSelection.allSubordinates ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
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

  String _getBrowseText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (employeeType) {
      case EmployeeTypeSelection.direct:
        return l10n.browseAllManagedEmployees(allManagedEmployees.length);
      case EmployeeTypeSelection.indirect:
        return l10n.browseAllIndirectEmployees(allManagedEmployees.length);
      case EmployeeTypeSelection.allSubordinates:
        return l10n.browseAllSubordinates(allManagedEmployees.length);
    }
  }
}
