import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../data/models/investigation_request_model.dart';
import '../../../l10n/app_localizations.dart';

/// Legal Decision Stage Content Widget
/// Embedded in InvestigationWorkflowDialog for the legal review stage.
/// Shows per-employee note cards and mandatory PDF upload.
class LegalDecisionStageContent extends StatefulWidget {
  final InvestigationRequestModel investigation;
  final Map<int, String> employeeComments; // for initState seeding (nav-back safe)
  final List<PlatformFile>? selectedPdfs;
  final Function(int employeeCode, String comment) onCommentChanged;
  final Function(List<PlatformFile>? pdfs) onPdfsChanged;

  const LegalDecisionStageContent({
    super.key,
    required this.investigation,
    required this.employeeComments,
    required this.selectedPdfs,
    required this.onCommentChanged,
    required this.onPdfsChanged,
  });

  @override
  State<LegalDecisionStageContent> createState() => _LegalDecisionStageContentState();
}

class _LegalDecisionStageContentState extends State<LegalDecisionStageContent> {
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === INVESTIGATION SUMMARY ===
        _buildInvestigationSummary(l10n),

        const Divider(height: 24),

        // === PER-EMPLOYEE NOTE CARDS ===
        Text(l10n.employeeDecisions, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(l10n.yourRemark, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 12),

        _buildEmployeeNoteCards(l10n, isArabic),

        const Divider(height: 24),

        // === MANDATORY PDF UPLOAD ===
        Row(
          children: [
            Text(l10n.legalDocument, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(12)),
              child: Text(
                l10n.required,
                style: TextStyle(color: Colors.red[900], fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildPdfUploadSection(l10n),

        if (widget.selectedPdfs == null || widget.selectedPdfs!.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red[700]),
                const SizedBox(width: 4),
                Text(
                  l10n.legalPdfMandatory,
                  style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // === INFO MESSAGE ===
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[300]!, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(l10n.afterSubmittingReturnedToHr, style: TextStyle(color: Colors.blue[900], fontSize: 13)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvestigationSummary(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel, color: Colors.purple[700]),
              const SizedBox(width: 8),
              Text(
                '${l10n.investigation} #${widget.investigation.id}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple[900]),
              ),
            ],
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
          if (widget.investigation.legalEscalationReason != null &&
              widget.investigation.legalEscalationReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            Text('${l10n.legalEscalationReason}:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(widget.investigation.legalEscalationReason!, style: TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeNoteCards(AppLocalizations l10n, bool isArabic) {
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
                    // Note field (optional)
                    TextField(
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

  Widget _buildPdfUploadSection(AppLocalizations l10n) {
    final hasPdfs = widget.selectedPdfs != null && widget.selectedPdfs!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          icon: Icon(Icons.upload_file, color: hasPdfs ? Colors.purple[700] : Colors.red[700]),
          label: Text(
            hasPdfs ? '${widget.selectedPdfs!.length} ${l10n.filesSelected}' : l10n.chooseLegalPdfRequired,
            style: TextStyle(color: hasPdfs ? Colors.purple[700] : Colors.red[700], fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: hasPdfs ? Colors.purple[700]! : Colors.red[700]!, width: 2),
          ),
          onPressed: () async {
            final result = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf'],
              allowMultiple: true,
              withData: true,
            );
            if (result != null) {
              widget.onPdfsChanged(result.files);
            }
          },
        ),
        if (hasPdfs) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              children:
                  widget.selectedPdfs!
                      .map(
                        (file) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                              const SizedBox(width: 4),
                              Icon(Icons.picture_as_pdf, size: 16, color: Colors.red[700]),
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
                                  final updated = List<PlatformFile>.from(widget.selectedPdfs!);
                                  updated.remove(file);
                                  widget.onPdfsChanged(updated.isEmpty ? null : updated);
                                },
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ],
    );
  }
}
