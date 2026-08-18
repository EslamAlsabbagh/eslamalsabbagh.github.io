import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/investigation_request_model.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/user_disciplinary_action_requests_bloc.dart';
import '../bloc/user_disciplinary_action_requests_event.dart';

/// HR Decision Stage Content Widget
/// Extracted from HrInvestigationDecisionDialog for use in multi-stage flow
/// Displays investigation summary, employee decision table, and attachment upload
class HrDecisionStageContent extends StatefulWidget {
  final InvestigationRequestModel investigation;
  final Map<int, HrDecision> employeeDecisions;
  final Map<int, String> employeeComments;
  final List<Uint8List> attachmentFiles;
  final List<String> attachmentFileNames;
  final GlobalKey<FormState> formKey;
  final Function(int employeeCode, HrDecision decision) onDecisionChanged;
  final Function(int employeeCode, String comment) onCommentChanged;
  final Function(List<Uint8List> files, List<String> names) onAttachmentsChanged;

  const HrDecisionStageContent({
    super.key,
    required this.investigation,
    required this.employeeDecisions,
    required this.employeeComments,
    required this.attachmentFiles,
    required this.attachmentFileNames,
    required this.formKey,
    required this.onDecisionChanged,
    required this.onCommentChanged,
    required this.onAttachmentsChanged,
  });

  @override
  State<HrDecisionStageContent> createState() => _HrDecisionStageContentState();
}

class _HrDecisionStageContentState extends State<HrDecisionStageContent> {
  final Map<int, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    for (final code in widget.investigation.employeeCodes) {
      _commentControllers[code] = TextEditingController(text: widget.employeeComments[code] ?? '');
    }
  }

  @override
  void dispose() {
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final hasLegalReview = widget.investigation.legalInvestigationPdfUrl != null;

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === INVESTIGATION SUMMARY ===
          _buildInvestigationSummary(l10n),

          const Divider(height: 24),

          // === LEGAL REVIEW SUMMARY (if exists) ===
          if (hasLegalReview) ...[_buildLegalReviewSummary(context, l10n), const Divider(height: 24)],

          // === EMPLOYEE DECISION CARDS ===
          Text(l10n.employeeDecisions, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _buildEmployeeDecisionCards(l10n, isArabic),

          // === AUTO-ESCALATION WARNING ===
          if (_hasSuspendOrTerminate()) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!, width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(l10n.autoEscalateWarning, style: TextStyle(color: Colors.orange[900], fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 24),

          // === ATTACHMENT UPLOAD ===
          _buildAttachmentUploadSection(context, l10n),
        ],
      ),
    );
  }

  Widget _buildInvestigationSummary(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.investigation} #${widget.investigation.id}',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900]),
          ),
          if (widget.investigation.incidentDescription != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.investigation.incidentDescription!,
              style: const TextStyle(fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${widget.investigation.employeeCount} ${l10n.employeesWithoutAl.toLowerCase()}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalReviewSummary(BuildContext context, AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, color: Colors.purple[700]),
              const SizedBox(width: 8),
              Text(l10n.legalReviewCompleted, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple[900])),
            ],
          ),
          const SizedBox(height: 8),
          Text(l10n.legalReviewCompletedMessage, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          if (widget.investigation.legalInvestigationPdfUrl != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                context.read<UserDisciplinaryActionRequestsBloc>().add(
                  OpenInvestigationPdf(widget.investigation.legalInvestigationPdfUrl!),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.picture_as_pdf, size: 16, color: Colors.red[700]),
                  const SizedBox(width: 4),
                  Text(
                    l10n.viewLegalPdf,
                    style: TextStyle(color: Colors.purple[700], decoration: TextDecoration.underline, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeDecisionCards(AppLocalizations l10n, bool isArabic) {
    return Column(
      children:
          widget.investigation.employeeCodes.map((code) {
            final employeeName = widget.investigation.getEmployeeName(code, isArabic);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.grey[300]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Employee header
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            employeeName,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
                          child: Text('#$code', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Decision dropdown
                    DropdownButtonFormField<HrDecision>(
                      value: widget.employeeDecisions[code] ?? HrDecision.takeAction,
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 13, color: Colors.black87),
                      items: [
                        DropdownMenuItem(
                          value: HrDecision.takeAction,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warning, size: 16, color: Colors.orange[700]),
                              const SizedBox(width: 6),
                              Text(l10n.takeAction, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: HrDecision.noAction,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                              const SizedBox(width: 6),
                              Text(l10n.noAction, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: HrDecision.suspend,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.pause_circle, size: 16, color: Colors.red[700]),
                              const SizedBox(width: 6),
                              Text(l10n.suspend, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: HrDecision.terminate,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cancel, size: 16, color: Colors.red[900]),
                              const SizedBox(width: 6),
                              Text(l10n.terminate, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          widget.onDecisionChanged(code, value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    // Comment field
                    TextFormField(
                      controller: _commentControllers[code],
                      maxLines: 2,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        labelText: l10n.yourRemark,
                        hintText: l10n.enterYourRemark,
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[50],
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      onChanged: (value) => widget.onCommentChanged(code, value),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildAttachmentUploadSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.attachmentsOptional, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(l10n.supportedFormats, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        const SizedBox(height: 12),
        Row(
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file, size: 18),
              label: Text(l10n.uploadDocuments),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              onPressed: widget.attachmentFileNames.length >= 5 ? null : () => _pickAttachments(context, l10n),
            ),
            if (widget.attachmentFileNames.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(
                l10n.documentsAttached(widget.attachmentFileNames.length),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ],
          ],
        ),
        if (widget.attachmentFileNames.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...widget.attachmentFileNames.asMap().entries.map((entry) {
            final index = entry.key;
            final name = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(_getFileIcon(name), size: 20, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 10),
                  Expanded(child: Text(name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                  IconButton(
                    icon: Icon(Icons.close, size: 18, color: Colors.grey[600]),
                    onPressed: () => _removeAttachment(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: l10n.removeDocument,
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Future<void> _pickAttachments(BuildContext context, AppLocalizations l10n) async {
    if (widget.attachmentFileNames.length >= 5) {
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
        if (file.size > 10 * 1024 * 1024) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${file.name}: ${l10n.fileTooLarge}')));
          }
          continue;
        }

        if (widget.attachmentFileNames.length + newFiles.length >= 5) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.maxFilesReached)));
          }
          break;
        }

        if (widget.attachmentFileNames.contains(file.name) || newFileNames.contains(file.name)) {
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
        final updatedFiles = [...widget.attachmentFiles, ...newFiles];
        final updatedNames = [...widget.attachmentFileNames, ...newFileNames];
        widget.onAttachmentsChanged(updatedFiles, updatedNames);
      }
    }
  }

  void _removeAttachment(int index) {
    final updatedFiles = List<Uint8List>.from(widget.attachmentFiles);
    final updatedNames = List<String>.from(widget.attachmentFileNames);
    updatedFiles.removeAt(index);
    updatedNames.removeAt(index);
    widget.onAttachmentsChanged(updatedFiles, updatedNames);
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

  bool _hasSuspendOrTerminate() {
    return widget.employeeDecisions.values.any((d) => d == HrDecision.suspend || d == HrDecision.terminate);
  }
}

enum HrDecision {
  takeAction, // Take disciplinary action
  noAction, // No action required
  suspend, // Suspend employee (auto-escalates to TM)
  terminate, // Terminate employee (auto-escalates to TM)
}

/// Extension to map HrDecision enum values to investigation decision strings
/// This ensures proper escalation logic in the repository
extension HrDecisionMapper on HrDecision {
  /// Converts HrDecision to the string format expected by InvestigationDecision
  /// and the repository's escalation check logic
  String toInvestigationDecisionString() {
    switch (this) {
      case HrDecision.takeAction:
        return 'take_action';
      case HrDecision.noAction:
        return 'no_action';
      case HrDecision.suspend:
        return 'suspension'; // Maps to repository check: d.decision == 'suspension'
      case HrDecision.terminate:
        return 'termination'; // Maps to repository check: d.decision == 'termination'
    }
  }
}
