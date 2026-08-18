import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/investigation_request_model.dart';
import '../../../data/models/investigation_decision.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/user_disciplinary_action_requests_bloc.dart';
import '../bloc/user_disciplinary_action_requests_event.dart';

/// TM Decision Stage Content Widget
/// Extracted from TopManagementInvestigationDecisionDialog for use in multi-stage flow
/// Displays decision history, employee decision cards with comments, PDF upload, and decision summary
class TmDecisionStageContent extends StatefulWidget {
  final InvestigationRequestModel investigation;
  final Map<int, TopManagementDecision> employeeDecisions;
  final Map<int, String> employeeComments;
  final List<PlatformFile>? decisionPdfs;
  final GlobalKey<FormState> formKey;
  final List<int> escalatedEmployees;
  final Function(int employeeCode, TopManagementDecision decision) onDecisionChanged;
  final Function(int employeeCode, String comment) onCommentChanged;
  final Function(List<PlatformFile>? pdfs) onPdfsChanged;

  const TmDecisionStageContent({
    super.key,
    required this.investigation,
    required this.employeeDecisions,
    required this.employeeComments,
    required this.decisionPdfs,
    required this.formKey,
    required this.escalatedEmployees,
    required this.onDecisionChanged,
    required this.onCommentChanged,
    required this.onPdfsChanged,
  });

  @override
  State<TmDecisionStageContent> createState() => _TmDecisionStageContentState();
}

class _TmDecisionStageContentState extends State<TmDecisionStageContent> {
  final Map<int, TextEditingController> _commentControllers = {};

  @override
  void initState() {
    super.initState();
    for (final code in widget.escalatedEmployees) {
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

    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === INVESTIGATION SUMMARY ===
          _buildInvestigationSummary(l10n),

          const Divider(height: 24),

          // === DECISION HISTORY ===
          Text(l10n.decisionHistory, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          // HR Decisions
          _buildHrDecisionSection(l10n, isArabic),

          // Legal Review (if exists)
          if (widget.investigation.legalInvestigationPdfUrl != null) ...[
            const SizedBox(height: 12),
            _buildLegalReviewSection(context, l10n),
          ],

          const Divider(height: 24),

          // === TOP MANAGEMENT DECISIONS ===
          Row(
            children: [
              Text(l10n.topManagementDecisions, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(12)),
                child: Text(
                  l10n.employeesRequireReview(widget.escalatedEmployees.length),
                  style: TextStyle(color: Colors.orange[900], fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(l10n.reviewSuspendTerminateDecisions, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 12),

          if (widget.escalatedEmployees.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.yellow[700]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.yellow[700]),
                  const SizedBox(width: 8),
                  Expanded(child: Text(l10n.noEmployeesRequireTmReview)),
                ],
              ),
            )
          else
            _buildEmployeeDecisionCards(l10n, isArabic),

          if (widget.escalatedEmployees.isNotEmpty) ...[
            const Divider(height: 24),

            // === PDF UPLOAD ===
            _buildPdfUploadSection(context, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildInvestigationSummary(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(
                '${l10n.investigation} #${widget.investigation.id}',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[900]),
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
        ],
      ),
    );
  }

  Widget _buildHrDecisionSection(AppLocalizations l10n, bool isArabic) {
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
          Row(
            children: [
              Icon(Icons.business_center, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(l10n.hrDecisions, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900])),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.escalatedEmployees.map((code) {
                  final employeeName = widget.investigation.getEmployeeName(code, isArabic);

                  final hrDecision = widget.investigation.hrDecisions?.firstWhere(
                    (d) => d.employeeCode == code,
                    orElse: () => InvestigationDecision(employeeCode: code, decision: 'unknown'),
                  );

                  return _buildEmployeeDecisionChip(
                    code,
                    employeeName,
                    _hrDecisionToLocalizedString(hrDecision?.decision ?? 'unknown', l10n),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeDecisionChip(int code, String name, String decision) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (decision.toLowerCase() == 'suspend') {
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[900]!;
      icon = Icons.pause_circle;
    } else if (decision.toLowerCase() == 'terminate') {
      backgroundColor = Colors.red[200]!;
      textColor = Colors.red[900]!;
      icon = Icons.cancel;
    } else {
      backgroundColor = Colors.grey[200]!;
      textColor = Colors.grey[800]!;
      icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text('$name ($code)', style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(': ${decision.toUpperCase()}', style: TextStyle(color: textColor, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildLegalReviewSection(BuildContext context, AppLocalizations l10n) {
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
              Icon(Icons.gavel, color: Colors.purple[700], size: 20),
              const SizedBox(width: 8),
              Text(l10n.legalReview, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple[900])),
            ],
          ),
          const SizedBox(height: 8),
          Text(l10n.legalHasReviewedInvestigation, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
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
      ),
    );
  }

  Widget _buildEmployeeDecisionCards(AppLocalizations l10n, bool isArabic) {
    return Column(
      children:
          widget.escalatedEmployees.map((code) {
            final employeeName = widget.investigation.getEmployeeName(code, isArabic);

            final hrDecision = widget.investigation.hrDecisions?.firstWhere(
              (d) => d.employeeCode == code,
              orElse: () => InvestigationDecision(employeeCode: code, decision: 'unknown'),
            );
            final hrDecisionLocalized = _hrDecisionToLocalizedString(hrDecision?.decision ?? 'unknown', l10n);

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
                    DropdownButtonFormField<TopManagementDecision>(
                      value: widget.employeeDecisions[code] ?? TopManagementDecision.confirm,
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
                          value: TopManagementDecision.confirm,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                              const SizedBox(width: 6),
                              Text(
                                '${l10n.confirmDecision} ($hrDecisionLocalized)',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: TopManagementDecision.convertToDisciplinary,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.transform, size: 16, color: Colors.orange[700]),
                              const SizedBox(width: 6),
                              Text(l10n.convertToDisciplinaryAction, style: const TextStyle(fontSize: 13)),
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

  Widget _buildPdfUploadSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.uploadDecisionPdfOptional, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: Text(
            widget.decisionPdfs == null || widget.decisionPdfs!.isEmpty
                ? l10n.choosePdfFiles
                : '${widget.decisionPdfs!.length} ${l10n.filesSelected}',
          ),
          onPressed: () async {
            final result = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf'],
              allowMultiple: true,
              withData: true, // Required for web platform to get file bytes
            );

            if (result != null) {
              widget.onPdfsChanged(result.files);
            }
          },
        ),
        if (widget.decisionPdfs != null && widget.decisionPdfs!.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...(widget.decisionPdfs!.map(
            (file) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, size: 16, color: Colors.red[700]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(file.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      final updatedPdfs = List<PlatformFile>.from(widget.decisionPdfs!);
                      updatedPdfs.remove(file);
                      widget.onPdfsChanged(updatedPdfs.isEmpty ? null : updatedPdfs);
                    },
                  ),
                ],
              ),
            ),
          )),
        ],
      ],
    );
  }
}

/// Top Management Decision enum
enum TopManagementDecision {
  confirm, // Confirm the suspend/terminate decision
  convertToDisciplinary, // Convert to normal disciplinary action
}

String _hrDecisionToLocalizedString(String decision, AppLocalizations l10n) {
  switch (decision.toLowerCase()) {
    case 'suspension':
      return l10n.suspension;
    case 'termination':
      return l10n.termination;
    default:
      return l10n.unknown;
  }
}
