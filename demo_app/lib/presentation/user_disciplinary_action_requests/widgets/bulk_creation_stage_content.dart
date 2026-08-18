import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../../../data/models/investigation_request_model.dart';
import '../../../data/models/disciplinary_action_request_model.dart';
import '../../../l10n/app_localizations.dart';

/// Bulk Creation Stage Content Widget
/// Extracted from BulkDisciplinaryCreationDialog for use in multi-stage flow
/// Displays employee action type selection and optional attachments
class BulkCreationStageContent extends StatelessWidget {
  final InvestigationRequestModel investigation;
  final List<int> actionableEmployees;
  final Map<int, DisciplinaryActionType> employeeActionTypes;
  final Map<int, double?> employeeDeductDays;
  final List<Uint8List> attachmentFiles;
  final List<String> attachmentFileNames;
  final Function(int employeeCode, DisciplinaryActionType actionType) onActionTypeChanged;
  final Function(int employeeCode, double? deductDays) onDeductDaysChanged;
  final Function(List<Uint8List> files, List<String> names) onAttachmentsChanged;

  const BulkCreationStageContent({
    super.key,
    required this.investigation,
    required this.actionableEmployees,
    required this.employeeActionTypes,
    required this.employeeDeductDays,
    required this.attachmentFiles,
    required this.attachmentFileNames,
    required this.onActionTypeChanged,
    required this.onDeductDaysChanged,
    required this.onAttachmentsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Column(
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
              child: Text(l10n.bulkCreationInstruction, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // === EMPLOYEE ACTION TYPE TABLE ===
        Text(l10n.employeeActionTypes, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        _buildEmployeeActionTypeTable(context, l10n, isArabic),

        const SizedBox(height: 24),

        // === SHARED ATTACHMENTS ===
        Text(l10n.attachmentsOptional, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(l10n.attachmentsWillBeAddedToAll, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 12),
        _buildAttachmentsSection(context, l10n),
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
                  '${l10n.investigation} #${investigation.id}: ${actionableEmployees.length} ${actionableEmployees.length == 1 ? l10n.action : l10n.actions}',
                  style: TextStyle(color: Colors.green[900], fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeActionTypeTable(BuildContext context, AppLocalizations l10n, bool isArabic) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          dataTextStyle: const TextStyle(fontSize: 12),
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
          dataRowColor: WidgetStateProperty.all(Colors.white),
          columns: [
            DataColumn(label: Text(l10n.code)),
            DataColumn(label: Text(l10n.employeeName)),
            DataColumn(label: Text(l10n.actionType)),
            DataColumn(label: Text(l10n.deductDays)),
          ],
          rows:
              actionableEmployees.map((code) {
                final employeeName = investigation.getEmployeeName(code, isArabic);

                return DataRow(
                  cells: [
                    DataCell(Text(code.toString())),
                    DataCell(Text(employeeName.length > 20 ? '${employeeName.substring(0, 20)}...' : employeeName)),
                    DataCell(
                      DropdownButton<DisciplinaryActionType>(
                        value: employeeActionTypes[code] ?? DisciplinaryActionType.writtenWarning,
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
                          if (value != null) {
                            onActionTypeChanged(code, value);
                          }
                        },
                      ),
                    ),
                    DataCell(_buildDeductDaysDropdown(context, code, l10n)),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildDeductDaysDropdown(BuildContext context, int employeeCode, AppLocalizations l10n) {
    final isWrittenWarning = employeeActionTypes[employeeCode] == DisciplinaryActionType.writtenWarning;

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
      value: employeeDeductDays[employeeCode],
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
      onChanged: isWrittenWarning ? (value) => onDeductDaysChanged(employeeCode, value) : null,
    );
  }

  Widget _buildAttachmentsSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.supportedFormats, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file, size: 18),
              label: Text(l10n.uploadDocuments),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              onPressed: attachmentFileNames.length >= 5 ? null : () => _pickAttachments(context, l10n),
            ),
            if (attachmentFileNames.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(
                l10n.documentsAttached(attachmentFileNames.length),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ],
        ),
        if (attachmentFileNames.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children:
                  attachmentFileNames.asMap().entries.map((entry) {
                    final index = entry.key;
                    final name = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(_getFileIcon(name), size: 16, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _removeAttachment(index),
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

  Future<void> _pickAttachments(BuildContext context, AppLocalizations l10n) async {
    // Check if max files reached
    if (attachmentFileNames.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.maxFilesReached)));
      return;
    }

    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result != null && result.files.isNotEmpty && context.mounted) {
      final List<Uint8List> newFiles = [];
      final List<String> newFileNames = [];

      for (final file in result.files) {
        // Check file size (10MB limit)
        if (file.size > 10 * 1024 * 1024) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${file.name}: ${l10n.fileTooLarge}')));
          }
          continue;
        }

        // Check total files limit
        if (attachmentFileNames.length + newFiles.length >= 5) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.maxFilesReached)));
          }
          break;
        }

        // Check for duplicate filenames
        if (attachmentFileNames.contains(file.name) || newFileNames.contains(file.name)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.duplicateFileSkipped(file.name))));
          }
          continue;
        }

        if (file.bytes != null) {
          newFiles.add(file.bytes!);
          newFileNames.add(file.name);
        }
      }

      if (newFiles.isNotEmpty && context.mounted) {
        final updatedFiles = [...attachmentFiles, ...newFiles];
        final updatedNames = [...attachmentFileNames, ...newFileNames];
        onAttachmentsChanged(updatedFiles, updatedNames);
      }
    }
  }

  void _removeAttachment(int index) {
    final updatedFiles = List<Uint8List>.from(attachmentFiles);
    final updatedNames = List<String>.from(attachmentFileNames);
    updatedFiles.removeAt(index);
    updatedNames.removeAt(index);
    onAttachmentsChanged(updatedFiles, updatedNames);
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
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
}
