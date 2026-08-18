import 'package:hrms_demo/core/services/employee_validation_service.dart';
import 'package:hrms_demo/data/models/bulk_employee_row.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/widgets/safe_tooltip.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';

/// A review table widget for bulk employee upload with editable cells
class BulkUploadReviewTable extends StatefulWidget {
  final List<BulkEmployeeRow> rows;
  final Function(int rowIndex, String field, String value) onFieldChanged;
  final VoidCallback onRevalidate;
  final Function(int rowIndex)? onRemoveRow;

  const BulkUploadReviewTable({
    super.key,
    required this.rows,
    required this.onFieldChanged,
    required this.onRevalidate,
    this.onRemoveRow,
  });

  @override
  State<BulkUploadReviewTable> createState() => _BulkUploadReviewTableState();
}

class _BulkUploadReviewTableState extends State<BulkUploadReviewTable> {
  static const _editableTextFields = [
    'employeeCode',
    'englishName',
    'arabicName',
    'arabicTitle',
    'englishTitle',
    'n1Code',
    'hireDate',
    'email',
  ];

  // Dropdown fields that need local value tracking so _flushAndRevalidate can
  // compare against the BLoC-committed value and flush any pending differences.
  static const _editableDropdownFields = [
    'departmentArabic',
    'location',
    'costCenter',
    'shiftHours',
    'workingDays',
    'leavesEligibility',
  ];

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};

  /// Tracks the most-recently selected dropdown value per "rowIndex.field" key.
  /// Updated immediately on selection — before the BLoC state propagates back.
  final Map<String, String?> _localDropdownValues = {};

  @override
  void initState() {
    super.initState();
    _initControllers(widget.rows);
    _initDropdownValues(widget.rows);
  }

  void _initDropdownValues(List<BulkEmployeeRow> rows) {
    for (final row in rows) {
      for (final field in _editableDropdownFields) {
        _localDropdownValues['${row.rowIndex}.$field'] = _getDropdownFieldValue(row, field);
      }
    }
  }

  void _initControllers(List<BulkEmployeeRow> rows) {
    for (final row in rows) {
      for (final field in _editableTextFields) {
        final key = '${row.rowIndex}.$field';
        _controllers[key] = TextEditingController(text: _getFieldValue(row, field) ?? '');
        final focusNode = FocusNode();
        final capturedRowIndex = row.rowIndex;
        focusNode.addListener(() {
          if (!focusNode.hasFocus) {
            widget.onFieldChanged(capturedRowIndex, field, _controllers[key]!.text);
          }
        });
        _focusNodes[key] = focusNode;
      }
    }
  }

  @override
  void didUpdateWidget(BulkUploadReviewTable oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Add controllers+focusNodes for newly added rows
    for (final row in widget.rows) {
      for (final field in _editableTextFields) {
        final key = '${row.rowIndex}.$field';
        if (!_controllers.containsKey(key)) {
          _controllers[key] = TextEditingController(text: _getFieldValue(row, field) ?? '');
          final focusNode = FocusNode();
          final capturedRowIndex = row.rowIndex;
          focusNode.addListener(() {
            if (!focusNode.hasFocus) {
              widget.onFieldChanged(capturedRowIndex, field, _controllers[key]!.text);
            }
          });
          _focusNodes[key] = focusNode;
        }
      }
    }

    // Sync values changed externally (e.g., after revalidation).
    // Skip any field that currently has focus — the user is still typing and
    // the controller text is intentionally ahead of the BLoC state.
    for (final row in widget.rows) {
      for (final field in _editableTextFields) {
        final key = '${row.rowIndex}.$field';
        final newValue = _getFieldValue(row, field) ?? '';
        final controller = _controllers[key];
        final isFocused = _focusNodes[key]?.hasFocus ?? false;
        if (!isFocused && controller != null && controller.text != newValue) {
          controller.text = newValue;
        }
      }
    }

    // Sync dropdown local values from BLoC state (external updates, e.g. cascade
    // auto-fills like departmentArabic → departmentEnglish after a revalidation).
    for (final row in widget.rows) {
      for (final field in _editableDropdownFields) {
        final key = '${row.rowIndex}.$field';
        _localDropdownValues[key] = _getDropdownFieldValue(row, field);
      }
    }

    // Dispose stale controllers+focusNodes for deleted rows
    final currentTextKeys = {
      for (final row in widget.rows)
        for (final field in _editableTextFields) '${row.rowIndex}.$field',
    };
    final staleKeys = _controllers.keys.where((k) => !currentTextKeys.contains(k)).toList();
    for (final key in staleKeys) {
      _controllers[key]!.dispose();
      _controllers.remove(key);
      _focusNodes[key]!.dispose();
      _focusNodes.remove(key);
    }

    // Remove stale dropdown keys for deleted rows
    final currentDropdownKeys = {
      for (final row in widget.rows)
        for (final field in _editableDropdownFields) '${row.rowIndex}.$field',
    };
    _localDropdownValues.removeWhere((k, _) => !currentDropdownKeys.contains(k));
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes.values) {
      focusNode.dispose();
    }
    super.dispose();
  }

  /// Commits any uncommitted controller text to BLoC, then revalidates.
  /// Required because FocusNode dispatch-on-blur is not reliably ordered
  /// relative to button onPressed on all platforms — RevalidateRows must
  /// always run AFTER all UpdateRowField events are queued.
  void _flushAndRevalidate() {
    // Flush any uncommitted text-field values (blur may not have fired yet).
    for (final row in widget.rows) {
      for (final field in _editableTextFields) {
        final key = '${row.rowIndex}.$field';
        final controller = _controllers[key];
        if (controller == null) continue;
        final committedValue = _getFieldValue(row, field) ?? '';
        if (controller.text != committedValue) {
          widget.onFieldChanged(row.rowIndex, field, controller.text);
        }
      }
    }
    // Flush any dropdown values that are locally ahead of the BLoC state.
    // Dropdowns call onFieldChanged immediately on selection, but if the widget
    // hasn't rebuilt yet, _localDropdownValues may be ahead of widget.rows.
    for (final row in widget.rows) {
      for (final field in _editableDropdownFields) {
        final key = '${row.rowIndex}.$field';
        final localValue = _localDropdownValues[key];
        final committedValue = _getDropdownFieldValue(row, field);
        if (localValue != null && localValue != committedValue) {
          widget.onFieldChanged(row.rowIndex, field, localValue);
        }
      }
    }
    widget.onRevalidate();
  }

  String? _getFieldValue(BulkEmployeeRow row, String field) {
    switch (field) {
      case 'employeeCode':
        return row.employeeCode;
      case 'englishName':
        return row.englishName;
      case 'arabicName':
        return row.arabicName;
      case 'arabicTitle':
        return row.arabicTitle;
      case 'englishTitle':
        return row.englishTitle;
      case 'n1Code':
        return row.n1Code;
      case 'hireDate':
        return row.hireDate;
      case 'email':
        return row.email;
      default:
        return null;
    }
  }

  String? _getDropdownFieldValue(BulkEmployeeRow row, String field) {
    switch (field) {
      case 'departmentArabic':
        return row.departmentArabic;
      case 'location':
        return row.location;
      case 'costCenter':
        return row.costCenter;
      case 'shiftHours':
        return row.shiftHours;
      case 'workingDays':
        return row.workingDays;
      case 'leavesEligibility':
        return row.leavesEligibility;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.reviewData,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (widget.rows.any((r) => r.isEdited))
                  TextButton.icon(
                    onPressed: _flushAndRevalidate,
                    icon: const Icon(Icons.refresh),
                    label: Text(AppLocalizations.of(context)!.revalidate),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.clickOnRedCellsToFix,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child: DataTable2(
                columnSpacing: 12,
                horizontalMargin: 12,
                minWidth: 2600,
                headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                columns: _buildColumns(context),
                rows: _buildRows(context),
                showBottomBorder: true,
                border: TableBorder.all(color: Colors.grey[300]!, width: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns(BuildContext context) {
    return [
      DataColumn2(label: Text('#', style: const TextStyle(fontWeight: FontWeight.bold)), size: ColumnSize.S),
      DataColumn2(
        label: Text(AppLocalizations.of(context)!.employeeCode, style: const TextStyle(fontWeight: FontWeight.bold)),
        size: ColumnSize.M,
      ),
      DataColumn2(
        label: Text(AppLocalizations.of(context)!.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
        size: ColumnSize.M,
      ),
      DataColumn2(
        label: Text(AppLocalizations.of(context)!.arabicName, style: const TextStyle(fontWeight: FontWeight.bold)),
        size: ColumnSize.M,
      ),
      DataColumn2(
        label: Text(
          AppLocalizations.of(context)!.jobTitleInArabic,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        size: ColumnSize.M,
      ),
      DataColumn2(
        label: Text(
          AppLocalizations.of(context)!.jobTitleInEnglish,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        size: ColumnSize.M,
      ),
      DataColumn2(
        label: Text(
          AppLocalizations.of(context)!.departmentInArabic,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        size: ColumnSize.L,
      ),
      DataColumn2(
        label: Text(AppLocalizations.of(context)!.location, style: const TextStyle(fontWeight: FontWeight.bold)),
        size: ColumnSize.M,
      ),
      DataColumn2(
        label: Text(AppLocalizations.of(context)!.costCenter, style: const TextStyle(fontWeight: FontWeight.bold)),
        size: ColumnSize.M,
      ),
      DataColumn2(
        label: Text(AppLocalizations.of(context)!.n1Code, style: const TextStyle(fontWeight: FontWeight.bold)),
        size: ColumnSize.M,
      ),
      DataColumn2(
        label: Text(AppLocalizations.of(context)!.hireDate, style: const TextStyle(fontWeight: FontWeight.bold)),
        size: ColumnSize.M,
      ),
      DataColumn2(
        label: Text(AppLocalizations.of(context)!.shiftHours, style: const TextStyle(fontWeight: FontWeight.bold)),
        size: ColumnSize.S,
      ),
      DataColumn2(
        label: Text(AppLocalizations.of(context)!.workingDays, style: const TextStyle(fontWeight: FontWeight.bold)),
        size: ColumnSize.S,
      ),
      DataColumn2(
        label: Text(
          AppLocalizations.of(context)!.leavesEligibility,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        size: ColumnSize.S,
      ),
      DataColumn2(
        label: Text(AppLocalizations.of(context)!.email, style: const TextStyle(fontWeight: FontWeight.bold)),
        size: ColumnSize.L,
      ),
      DataColumn2(
        label: Text(AppLocalizations.of(context)!.status, style: const TextStyle(fontWeight: FontWeight.bold)),
        size: ColumnSize.S,
      ),
    ];
  }

  List<DataRow2> _buildRows(BuildContext context) {
    return widget.rows.map((row) {
      return DataRow2(
        color: WidgetStateProperty.resolveWith<Color?>((states) {
          if (row.hasErrors) {
            return Colors.red[50];
          }
          return null;
        }),
        cells: [
          DataCell(Text(row.rowIndex.toString())),
          _buildTextCell(context: context, fieldName: 'employeeCode', row: row),
          _buildTextCell(context: context, fieldName: 'englishName', row: row),
          _buildTextCell(context: context, fieldName: 'arabicName', row: row),
          _buildTextCell(context: context, fieldName: 'arabicTitle', row: row),
          _buildTextCell(context: context, fieldName: 'englishTitle', row: row),
          _buildDropdownCell(
            context: context,
            value: row.departmentArabic,
            fieldName: 'departmentArabic',
            row: row,
            items: EmployeeValidationService.getAllArabicDepartments(),
          ),
          _buildDropdownCell(
            context: context,
            value: row.location,
            fieldName: 'location',
            row: row,
            items: EmployeeValidationService.validLocations,
          ),
          _buildDropdownCell(
            context: context,
            value: row.costCenter,
            fieldName: 'costCenter',
            row: row,
            items: EmployeeValidationService.validCostCenters,
          ),
          _buildTextCell(context: context, fieldName: 'n1Code', row: row),
          _buildTextCell(context: context, fieldName: 'hireDate', row: row),
          _buildDropdownCell(
            context: context,
            value: row.shiftHours,
            fieldName: 'shiftHours',
            row: row,
            items: EmployeeValidationService.validShiftHours,
          ),
          _buildDropdownCell(
            context: context,
            value: row.workingDays,
            fieldName: 'workingDays',
            row: row,
            items: EmployeeValidationService.validWorkingDays,
          ),
          _buildDropdownCell(
            context: context,
            value: row.leavesEligibility,
            fieldName: 'leavesEligibility',
            row: row,
            items: EmployeeValidationService.validLeavesEligibility,
          ),
          _buildTextCell(context: context, fieldName: 'email', row: row),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: row.isValid ? Colors.green[100] : Colors.red[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                row.isValid ? AppLocalizations.of(context)!.valid : AppLocalizations.of(context)!.invalid,
                style: TextStyle(
                  color: row.isValid ? Colors.green[700] : Colors.red[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      );
    }).toList();
  }

  DataCell _buildTextCell({required BuildContext context, required String fieldName, required BulkEmployeeRow row}) {
    final hasError = row.hasError(fieldName);
    final error = row.getError(fieldName);
    final key = '${row.rowIndex}.$fieldName';
    final controller = _controllers[key]!;
    final focusNode = _focusNodes[key]!;

    return DataCell(
      SafeTooltip(
        message: hasError ? error ?? '' : '',
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          style: TextStyle(color: hasError ? Colors.red[700] : null, fontSize: 12),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            filled: true,
            fillColor: hasError ? Colors.red[50] : Colors.grey[50],
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: hasError ? Colors.red[300]! : Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: hasError ? Colors.red[400]! : Colors.blue[400]!),
            ),
          ),
        ),
      ),
    );
  }

  DataCell _buildDropdownCell({
    required BuildContext context,
    required String? value,
    required String fieldName,
    required BulkEmployeeRow row,
    required List<String> items,
  }) {
    final hasError = row.hasError(fieldName);
    final error = row.getError(fieldName);

    // Use the locally tracked value as the source of truth — it is updated
    // immediately on selection before the BLoC state propagates back.
    final localKey = '${row.rowIndex}.$fieldName';
    final resolvedValue = _localDropdownValues[localKey] ?? value;

    return DataCell(
      SafeTooltip(
        message: hasError ? error ?? '' : (resolvedValue ?? ''),
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<String>(
            isExpanded: true,
            valueListenable: ValueNotifier(items.contains(resolvedValue) ? resolvedValue : null),
            hint: Text(
              resolvedValue ?? '',
              style: TextStyle(color: hasError ? Colors.red[700] : Colors.grey[600], fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            items:
                items.map((item) {
                  return DropdownItem<String>(
                    value: item,
                    height: 32,
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  );
                }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                // Update local state immediately for instant UI feedback,
                // then propagate to the BLoC.
                setState(() => _localDropdownValues[localKey] = newValue);
                widget.onFieldChanged(row.rowIndex, fieldName, newValue);
              }
            },
            buttonStyleData: ButtonStyleData(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: hasError ? Colors.red[50] : Colors.grey[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: hasError ? Colors.red[300]! : Colors.grey[300]!),
              ),
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: 200,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
            ),
            menuItemStyleData: const MenuItemStyleData(),
          ),
        ),
      ),
    );
  }
}
