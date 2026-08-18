import 'package:hrms_demo/core/utils/display_name_utils.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// A widget that displays selected employee(s) in a styled card format.
/// Supports both single and multi-select modes.
class SelectedEmployeeSection extends StatelessWidget {
  /// Single employee to display (used in single-select mode)
  final UserModel? employee;

  /// List of employees to display (used in multi-select mode)
  final List<UserModel> employees;

  /// Callback when clear button is pressed (single-select mode)
  final VoidCallback? onClear;

  /// Callback when an employee is removed (multi-select mode)
  final Function(UserModel)? onRemoveEmployee;

  /// Callback when clear all button is pressed (multi-select mode)
  final VoidCallback? onClearAll;

  /// Optional tooltip for clear button
  final String? clearTooltip;

  /// Whether this is in multi-select mode
  final bool multiSelect;

  /// Constructor for single-select mode
  const SelectedEmployeeSection({
    super.key,
    required UserModel this.employee,
    required VoidCallback this.onClear,
    this.clearTooltip,
  }) : employees = const [],
       onRemoveEmployee = null,
       onClearAll = null,
       multiSelect = false;

  /// Constructor for multi-select mode
  const SelectedEmployeeSection.multiSelect({
    super.key,
    required this.employees,
    required this.onRemoveEmployee,
    required this.onClearAll,
    this.clearTooltip,
  }) : employee = null,
       onClear = null,
       multiSelect = true;

  @override
  Widget build(BuildContext context) {
    if (multiSelect) {
      return _buildMultiSelectSection(context);
    }
    return _buildSingleSelectSection(context);
  }

  Widget _buildSingleSelectSection(BuildContext context) {
    final displayName = DisplayNameUtils.getDisplayName(context, employee!.englishName, employee!.arabicName);

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
                      value: employee!.id?.toString() ?? 'N/A',
                      icon: Icons.badge,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDetailItem(
                      context,
                      label: AppLocalizations.of(context)!.hireDate,
                      value: employee!.hireDate ?? 'N/A',
                      icon: Icons.calendar_today,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.blue[700], size: 18),
                    onPressed: onClear,
                    tooltip: clearTooltip ?? AppLocalizations.of(context)!.clearSelection,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectSection(BuildContext context) {
    if (employees.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count and clear all button
        Row(
          children: [
            const Icon(Icons.people, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              '${l10n.selectedEmployees} (${employees.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const Spacer(),
            TextButton(onPressed: onClearAll, child: Text(l10n.clearAll, style: TextStyle(color: Colors.blue[600]))),
          ],
        ),
        const SizedBox(height: 8),

        // Employee cards
        ...employees.map((emp) {
          final displayName = DisplayNameUtils.getDisplayName(context, emp.englishName, emp.arabicName);

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!, width: 1.5),
            ),
            child: Row(
              children: [
                // Name
                Expanded(
                  child: _buildDetailItem(
                    context,
                    label: AppLocalizations.of(context)!.name,
                    value: displayName.isEmpty ? AppLocalizations.of(context)!.unknown : displayName,
                    icon: Icons.person,
                  ),
                ),
                // Code
                Expanded(
                  child: _buildDetailItem(
                    context,
                    label: AppLocalizations.of(context)!.code,
                    value: emp.id?.toString() ?? 'N/A',
                    icon: Icons.badge,
                  ),
                ),
                // Hire Date
                Expanded(
                  child: _buildDetailItem(
                    context,
                    label: AppLocalizations.of(context)!.hireDate,
                    value: emp.hireDate ?? 'N/A',
                    icon: Icons.calendar_today,
                  ),
                ),
                // Remove button
                IconButton(
                  icon: Icon(Icons.close, color: Colors.blue[700], size: 18),
                  onPressed: () => onRemoveEmployee?.call(emp),
                  tooltip: clearTooltip ?? l10n.removeEmployee,
                ),
              ],
            ),
          );
        }),
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
}
