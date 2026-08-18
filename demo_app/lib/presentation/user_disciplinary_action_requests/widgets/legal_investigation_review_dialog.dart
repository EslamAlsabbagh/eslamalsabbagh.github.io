import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/investigation_request_model.dart';
import '../../../data/models/investigation_decision.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/user_disciplinary_action_requests_bloc.dart';
import '../bloc/user_disciplinary_action_requests_event.dart';
import '../../dashboard/bloc/user_bloc.dart';

/// Legal Investigation Review Dialog
/// Legal does NOT make per-employee decisions
/// Instead: Reviews HR decisions, provides opinion, uploads MANDATORY PDF, returns to HR
class LegalInvestigationReviewDialog extends StatefulWidget {
  final InvestigationRequestModel investigation;

  const LegalInvestigationReviewDialog({super.key, required this.investigation});

  @override
  State<LegalInvestigationReviewDialog> createState() => _LegalInvestigationReviewDialogState();
}

class _LegalInvestigationReviewDialogState extends State<LegalInvestigationReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _opinionController = TextEditingController();

  // MANDATORY PDF upload
  List<PlatformFile>? _legalPdfs;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _opinionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.gavel),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.legalReview, style: const TextStyle(fontWeight: FontWeight.bold))),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
      contentPadding: EdgeInsets.zero,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === INVESTIGATION SUMMARY ===
                _buildInvestigationSummary(l10n),

                const Divider(height: 24),

                // === HR DECISIONS (READ-ONLY) ===
                Text(l10n.hrDecisions, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(l10n.reviewHrDecisions, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 12),

                _buildHrDecisionsTable(l10n, isArabic),

                const Divider(height: 24),

                // === LEGAL OPINION ===
                Text(l10n.legalOpinion, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _opinionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: l10n.enterLegalOpinion,
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.legalOpinionRequired;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

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

                // Validation message
                if (_legalPdfs == null || _legalPdfs!.isEmpty)
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
                        child: Text(
                          l10n.afterSubmittingReturnedToHr,
                          style: TextStyle(color: Colors.blue[900], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: (_isSubmitting || _legalPdfs == null || _legalPdfs!.isEmpty) ? null : _submitReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple[700],
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey[300],
          ),
          child:
              _isSubmitting
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                  : Text(l10n.submitLegalReview),
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
              Icon(Icons.search, color: Colors.purple[700]),
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
        ],
      ),
    );
  }

  Widget _buildHrDecisionsTable(AppLocalizations l10n, bool isArabic) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
          dataRowColor: WidgetStateProperty.all(Colors.white),
          columns: [
            DataColumn(label: Text(l10n.employeeCode)),
            DataColumn(label: Text(l10n.employeeName)),
            DataColumn(label: Text(l10n.hrDecision)),
          ],
          rows:
              widget.investigation.employeeCodes.map((code) {
                final employeeName = widget.investigation.getEmployeeName(code, isArabic);

                // Get HR decision for this employee
                final hrDecision = widget.investigation.hrDecisions?.firstWhere(
                  (d) => d.employeeCode == code,
                  orElse: () => InvestigationDecision(employeeCode: code, decision: 'pending'),
                );

                return DataRow(
                  cells: [
                    DataCell(Text(code.toString())),
                    DataCell(Text(employeeName)),
                    DataCell(_buildDecisionChip(hrDecision?.decision ?? 'pending', l10n)),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildDecisionChip(String decision, AppLocalizations l10n) {
    Color backgroundColor;
    Color textColor;
    IconData icon;
    String label;

    switch (decision.toLowerCase()) {
      case 'take_action':
      case 'takeaction':
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[900]!;
        icon = Icons.warning;
        label = l10n.takeAction;
        break;
      case 'no_action':
      case 'noaction':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[900]!;
        icon = Icons.check_circle;
        label = l10n.noAction;
        break;
      case 'suspend':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        icon = Icons.pause_circle;
        label = l10n.suspend;
        break;
      case 'terminate':
        backgroundColor = Colors.red[200]!;
        textColor = Colors.red[900]!;
        icon = Icons.cancel;
        label = l10n.terminate;
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        icon = Icons.help_outline;
        label = decision;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPdfUploadSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(
          icon: Icon(
            Icons.upload_file,
            color: (_legalPdfs == null || _legalPdfs!.isEmpty) ? Colors.red[700] : Colors.purple[700],
          ),
          label: Text(
            _legalPdfs == null || _legalPdfs!.isEmpty
                ? l10n.chooseLegalPdfRequired
                : '${_legalPdfs!.length} ${l10n.filesSelected}',
            style: TextStyle(
              color: (_legalPdfs == null || _legalPdfs!.isEmpty) ? Colors.red[700] : Colors.purple[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: (_legalPdfs == null || _legalPdfs!.isEmpty) ? Colors.red[700]! : Colors.purple[700]!,
              width: 2,
            ),
          ),
          onPressed: () async {
            final result = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf'],
              allowMultiple: true,
            );

            if (result != null) {
              setState(() {
                _legalPdfs = result.files;
              });
            }
          },
        ),
        if (_legalPdfs != null && _legalPdfs!.isNotEmpty) ...[
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
                  _legalPdfs!
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
                                  setState(() {
                                    _legalPdfs!.remove(file);
                                  });
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

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) return;

    // Double-check PDF is uploaded
    if (_legalPdfs == null || _legalPdfs!.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.legalPdfRequired)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Extract PDF bytes and file names from picked files
      final pdfBytes = _legalPdfs!.where((f) => f.bytes != null).map((f) => f.bytes!).toList();
      final pdfFileNames = _legalPdfs!.where((f) => f.bytes != null).map((f) => f.name).toList();

      // Call BLoC event to record legal review with PDF upload
      context.read<UserDisciplinaryActionRequestsBloc>().add(
        RecordLegalInvestigationReview(
          investigationId: widget.investigation.id!,
          reviewedBy: context.read<UserBloc>().state.user!.id!,
          pdfUrls: const <String>[],
          pdfBytes: pdfBytes,
          pdfFileNames: pdfFileNames,
        ),
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.legalReviewRecordedSuccess)));

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
