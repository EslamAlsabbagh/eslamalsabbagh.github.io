import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/investigation_request_model.dart';
import '../../../data/models/disciplinary_action_request_model.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/user_disciplinary_action_requests_bloc.dart';
import '../bloc/user_disciplinary_action_requests_event.dart';
import '../../dashboard/bloc/user_bloc.dart';

/// Bulk Disciplinary Action Creation Dialog (Simplified)
/// Creates N disciplinary actions (one per employee)
/// Each employee can have DIFFERENT action types
/// Violation details auto-filled from investigation (not shown in dialog)
class BulkDisciplinaryCreationDialog extends StatefulWidget {
  final InvestigationRequestModel investigation;
  final List<int>? actionableEmployeeCodes; // Optional: pre-computed actionable employees

  const BulkDisciplinaryCreationDialog({
    super.key,
    required this.investigation,
    this.actionableEmployeeCodes, // Pass employee codes that need actions
  });

  @override
  State<BulkDisciplinaryCreationDialog> createState() => _BulkDisciplinaryCreationDialogState();
}

class _BulkDisciplinaryCreationDialogState extends State<BulkDisciplinaryCreationDialog> {
  final _formKey = GlobalKey<FormState>();

  // Employees that need disciplinary actions
  List<int> _actionableEmployees = [];

  // Per-employee action type selections
  final Map<int, DisciplinaryActionType> _employeeActionTypes = {};

  // Per-employee deduct days selections (only for written warnings)
  final Map<int, double?> _employeeDeductDays = {};

  // Shared attachments for all actions
  List<PlatformFile>? _attachments;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadActionableEmployees();
    _loadEmployeeInfo();
  }

  void _loadActionableEmployees() {
    // Use pre-computed actionable employees if provided, otherwise extract from investigation
    if (widget.actionableEmployeeCodes != null && widget.actionableEmployeeCodes!.isNotEmpty) {
      setState(() {
        _actionableEmployees = List.from(widget.actionableEmployeeCodes!)..sort();
        // Initialize all employees with default action type and null deduct days
        for (final code in _actionableEmployees) {
          _employeeActionTypes[code] = DisciplinaryActionType.writtenWarning;
          _employeeDeductDays[code] = null;
        }
      });
      return;
    }

    // Fallback: Extract from investigation decisions
    final hrDecisions = widget.investigation.hrDecisions ?? [];
    final tmDecisions = widget.investigation.topManagementDecisions ?? [];

    final Set<int> actionableCodes = {};

    // Check HR decisions for "take_action"
    for (final decision in hrDecisions) {
      if (decision.decision.toLowerCase() == 'take_action' || decision.decision.toLowerCase() == 'takeaction') {
        actionableCodes.add(decision.employeeCode);
      }
    }

    // Check TM decisions for "confirm"
    for (final decision in tmDecisions) {
      if (decision.decision.toLowerCase() == 'confirm') {
        actionableCodes.add(decision.employeeCode);
      }
    }

    setState(() {
      _actionableEmployees = actionableCodes.toList()..sort();
      // Initialize all employees with default action type and null deduct days
      for (final code in _actionableEmployees) {
        _employeeActionTypes[code] = DisciplinaryActionType.writtenWarning;
        _employeeDeductDays[code] = null;
      }
    });
  }

  void _loadEmployeeInfo() {
    // Employee info is now provided by the investigation model
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return _buildDialog(context, l10n, isArabic);
  }

  Widget _buildDialog(BuildContext context, AppLocalizations l10n, bool isArabic) {
    // If no actionable employees, show message
    if (_actionableEmployees.isEmpty) {
      return AlertDialog(
        title: Row(children: [Icon(Icons.info_outline), const SizedBox(width: 8), const Text('No Actions Required')]),
        content: const Text(
          'No employees in this investigation require disciplinary actions. '
          'All employees either received "No Action" decisions or other outcomes.',
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.close))],
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.post_add),
          const SizedBox(width: 8),
          const Expanded(child: Text('Create Disciplinary Actions', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
      contentPadding: EdgeInsets.zero,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000, maxHeight: 800),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === SUMMARY CARD ===
                _buildSummaryCard(l10n),

                const SizedBox(height: 16),

                // === INSTRUCTION ===
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Select the disciplinary action type for each employee. '
                        'Violation details will be copied from the investigation.',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // === EMPLOYEE ACTION TYPE TABLE ===
                const Text('Employee Action Types', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                _buildEmployeeActionTypeTable(l10n, isArabic),

                const SizedBox(height: 24),

                // === SHARED ATTACHMENTS ===
                const Text('Attachments (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'These attachments will be added to all created disciplinary actions',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                _buildAttachmentsSection(l10n),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _isSubmitting ? null : () => Navigator.pop(context), child: Text(l10n.cancel)),
        ElevatedButton.icon(
          icon:
              _isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                  : const Icon(Icons.add_circle),
          label: Text(
            _isSubmitting
                ? 'Creating...'
                : 'Create ${_actionableEmployees.length} ${_actionableEmployees.length == 1 ? 'Action' : 'Actions'}',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
          ),
          onPressed: _isSubmitting ? null : _submitBulkCreation,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[300]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.green[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creating ${_actionableEmployees.length} disciplinary '
                  '${_actionableEmployees.length == 1 ? 'action' : 'actions'} '
                  'from Investigation #${widget.investigation.id}',
                  style: TextStyle(color: Colors.green[900], fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Violation details will be auto-filled from investigation',
                  style: TextStyle(color: Colors.green[800], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeActionTypeTable(AppLocalizations l10n, bool isArabic) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 30,
          headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
          dataRowColor: WidgetStateProperty.all(Colors.white),
          columns: [
            DataColumn(label: Text(l10n.employeeCode)),
            const DataColumn(label: Text('Employee Name')),
            DataColumn(label: Text(l10n.actionType)),
            DataColumn(label: Text(l10n.deductDays)),
          ],
          rows:
              _actionableEmployees.map((code) {
                final employeeName = widget.investigation.getEmployeeName(code, isArabic);

                return DataRow(
                  cells: [
                    DataCell(Text(code.toString())),
                    DataCell(Text(employeeName)),
                    DataCell(
                      DropdownButton<DisciplinaryActionType>(
                        value: _employeeActionTypes[code] ?? DisciplinaryActionType.writtenWarning,
                        isExpanded: false,
                        underline: Container(),
                        items:
                            DisciplinaryActionType.values
                                .where((type) => type != DisciplinaryActionType.hrInvestigation)
                                .map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type.getLocalizedName(context), style: const TextStyle(fontSize: 13)),
                                  );
                                })
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _employeeActionTypes[code] = value!;
                            // Clear deduct days if not written warning
                            if (value != DisciplinaryActionType.writtenWarning) {
                              _employeeDeductDays[code] = null;
                            }
                          });
                        },
                      ),
                    ),
                    DataCell(_buildDeductDaysDropdown(code, l10n)),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildDeductDaysDropdown(int employeeCode, AppLocalizations l10n) {
    final isWrittenWarning = _employeeActionTypes[employeeCode] == DisciplinaryActionType.writtenWarning;

    final deductDaysOptions = [
      (label: l10n.quarterDay, value: 0.25),
      (label: l10n.halfDay, value: 0.5),
      (label: '1 ${l10n.day}', value: 1.0),
      (label: '2 ${l10n.days}', value: 2.0),
      (label: '3 ${l10n.days}', value: 3.0),
      (label: '4 ${l10n.days}', value: 4.0),
      (label: '5 ${l10n.days}', value: 5.0),
    ];

    return DropdownButton<double>(
      value: _employeeDeductDays[employeeCode],
      isExpanded: false,
      underline: Container(),
      hint: Text(
        isWrittenWarning ? l10n.selectDeductDays : '-',
        style: TextStyle(fontSize: 13, color: isWrittenWarning ? Colors.grey[600] : Colors.grey[400]),
      ),
      items:
          isWrittenWarning
              ? deductDaysOptions
                  .map(
                    (opt) => DropdownMenuItem<double>(
                      value: opt.value,
                      child: Text(opt.label, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList()
              : null,
      onChanged: isWrittenWarning ? (value) => setState(() => _employeeDeductDays[employeeCode] = value) : null,
    );
  }

  Widget _buildAttachmentsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.attach_file),
          label: Text(
            _attachments == null || _attachments!.isEmpty
                ? 'Add Attachments'
                : '${_attachments!.length} file(s) selected',
          ),
          onPressed: () async {
            final result = await FilePicker.pickFiles(
              allowMultiple: true,
              type: FileType.custom,
              allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
            );

            if (result != null) {
              setState(() {
                _attachments = result.files;
              });
            }
          },
        ),
        if (_attachments != null && _attachments!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children:
                  _attachments!.map((file) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(_getFileIcon(file.extension ?? ''), size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              file.name,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _attachments!.remove(file);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _submitBulkCreation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Extract attachment bytes and file names from picked files
      final attachmentFiles = _attachments?.where((f) => f.bytes != null).map((f) => f.bytes!).toList();
      final attachmentFileNames = _attachments?.where((f) => f.bytes != null).map((f) => f.name).toList();

      // Get current user code
      final userCode = context.read<UserBloc>().state.user?.id ?? 0;

      // Group employees by action type AND deduct days to minimize bulk operations
      final Map<(DisciplinaryActionType, double?), List<int>> employeesByGroup = {};
      for (final employeeCode in _actionableEmployees) {
        final actionType = _employeeActionTypes[employeeCode]!;
        final deductDays =
            actionType == DisciplinaryActionType.writtenWarning ? _employeeDeductDays[employeeCode] : null;

        final key = (actionType, deductDays);
        employeesByGroup.putIfAbsent(key, () => []).add(employeeCode);
      }

      // Create bulk disciplinary actions for each group
      for (final entry in employeesByGroup.entries) {
        final (actionType, deductDays) = entry.key;
        final employeeCodes = entry.value;

        // Create WrittenWarningOptions for written warning with deduct days
        final writtenWarningOptions =
            actionType == DisciplinaryActionType.writtenWarning && deductDays != null
                ? WrittenWarningOptions(deductDays: deductDays)
                : null;

        // Dispatch create event for this group
        context.read<UserDisciplinaryActionRequestsBloc>().add(
          CreateBulkDisciplinaryActionsFromInvestigation(
            investigationId: widget.investigation.id!,
            requestorCode: userCode,
            employeeCodes: employeeCodes,
            actionType: actionType,
            violationCategory: widget.investigation.violationCategory,
            violation: widget.investigation.violation,
            violationDate: widget.investigation.violationDate!,
            incidentDescription: widget.investigation.incidentDescription,
            writtenWarningOptions: writtenWarningOptions,
            attachmentFiles: attachmentFiles,
            attachmentFileNames: attachmentFileNames,
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Creating ${_actionableEmployees.length} disciplinary actions...')));

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
