import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/investigation_request_model.dart';
import '../../../data/models/investigation_decision.dart';
import '../../../l10n/app_localizations.dart';
import '../bloc/user_disciplinary_action_requests_bloc.dart';
import '../bloc/user_disciplinary_action_requests_event.dart';
import '../../dashboard/bloc/user_bloc.dart';
import 'tm_decision_stage_content.dart';

/// Top Management Investigation Decision Dialog
/// Final authority - Reviews employees with Suspend/Terminate decisions
/// Options: Confirm Decision OR Convert to Disciplinary Action
class TopManagementInvestigationDecisionDialog extends StatefulWidget {
  final InvestigationRequestModel investigation;

  const TopManagementInvestigationDecisionDialog({super.key, required this.investigation});

  @override
  State<TopManagementInvestigationDecisionDialog> createState() => _TopManagementInvestigationDecisionDialogState();
}

class _TopManagementInvestigationDecisionDialogState extends State<TopManagementInvestigationDecisionDialog> {
  final _formKey = GlobalKey<FormState>();

  // Decision for each escalated employee: Map<employeeCode, TmDecision>
  final Map<int, TopManagementDecision> _employeeDecisions = {};

  // Optional PDF upload
  List<PlatformFile>? _decisionPdfs;

  bool _isSubmitting = false;

  // Get only employees with Suspend or Terminate decisions
  List<int> get _escalatedEmployees {
    if (widget.investigation.hrDecisions == null) return [];

    return widget.investigation.hrDecisions!
        .where((d) {
          final decision = d.decision.toLowerCase();
          return decision == 'suspension' || decision == 'termination';
        })
        .map((d) => d.employeeCode)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    // Initialize all escalated employees with default decision (confirm)
    for (final code in _escalatedEmployees) {
      _employeeDecisions[code] = TopManagementDecision.confirm;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.supervisor_account),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.topManagementDecision, style: const TextStyle(fontWeight: FontWeight.bold))),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
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
                  _buildLegalReviewSection(l10n),
                ],

                const Divider(height: 24),

                // === TOP MANAGEMENT DECISIONS ===
                Row(
                  children: [
                    Text(
                      l10n.topManagementDecisions,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        l10n.employeesRequireReview(_escalatedEmployees.length),
                        style: TextStyle(color: Colors.orange[900], fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(l10n.reviewSuspendTerminateDecisions, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 12),

                if (_escalatedEmployees.isEmpty)
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
                  _buildEmployeeDecisionTable(l10n, isArabic),

                if (_escalatedEmployees.isNotEmpty) ...[
                  const Divider(height: 24),

                  // === PDF UPLOAD ===
                  _buildPdfUploadSection(l10n),

                  const Divider(height: 24),

                  // === DECISION SUMMARY ===
                  _buildDecisionSummary(l10n),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (_escalatedEmployees.isNotEmpty)
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitDecision,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
            child:
                _isSubmitting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                    : Text(l10n.submitFinalDecision),
          ),
      ],
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
                _escalatedEmployees.map((code) {
                  final employeeName = widget.investigation.getEmployeeName(code, isArabic);

                  final hrDecision = widget.investigation.hrDecisions?.firstWhere(
                    (d) => d.employeeCode == code,
                    orElse: () => InvestigationDecision(employeeCode: code, decision: 'unknown'),
                  );

                  return _buildEmployeeDecisionChip(code, employeeName, hrDecision?.decision ?? 'unknown');
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

    if (decision.toLowerCase() == 'suspension') {
      backgroundColor = Colors.red[100]!;
      textColor = Colors.red[900]!;
      icon = Icons.pause_circle;
    } else if (decision.toLowerCase() == 'termination') {
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
          Text('→ ${decision.toUpperCase()}', style: TextStyle(color: textColor, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildLegalReviewSection(AppLocalizations l10n) {
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

  Widget _buildEmployeeDecisionTable(AppLocalizations l10n, bool isArabic) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        headingRowColor: WidgetStateProperty.all(Colors.red[50]),
        columns: [
          DataColumn(label: Text(l10n.employeeCode)),
          DataColumn(label: Text(l10n.employeeName)),
          DataColumn(label: Text(l10n.hrDecision)),
          DataColumn(label: Text(l10n.tmDecision)),
        ],
        rows:
            _escalatedEmployees.map((code) {
              final employeeName = widget.investigation.getEmployeeName(code, isArabic);

              final hrDecision = widget.investigation.hrDecisions?.firstWhere(
                (d) => d.employeeCode == code,
                orElse: () => InvestigationDecision(employeeCode: code, decision: 'unknown'),
              );

              return DataRow(
                cells: [
                  DataCell(Text(code.toString())),
                  DataCell(Text(employeeName)),
                  DataCell(_buildHrDecisionChip(hrDecision?.decision ?? 'unknown')),
                  DataCell(
                    DropdownButton<TopManagementDecision>(
                      value: _employeeDecisions[code] ?? TopManagementDecision.confirm,
                      items: [
                        DropdownMenuItem(
                          value: TopManagementDecision.confirm,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 18, color: Colors.green[700]),
                              const SizedBox(width: 6),
                              Text(l10n.confirmDecision),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: TopManagementDecision.convertToDisciplinary,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.transform, size: 18, color: Colors.orange[700]),
                              const SizedBox(width: 6),
                              Text(l10n.convertToDisciplinaryAction),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _employeeDecisions[code] = value!;
                        });
                      },
                    ),
                  ),
                ],
              );
            }).toList(),
      ),
    );
  }

  Widget _buildHrDecisionChip(String decision) {
    final l10n = AppLocalizations.of(context)!;
    Color backgroundColor;
    Color textColor;
    String label;

    switch (decision.toLowerCase()) {
      case 'suspension':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[900]!;
        label = l10n.suspend;
        break;
      case 'termination':
        backgroundColor = Colors.red[200]!;
        textColor = Colors.red[900]!;
        label = l10n.terminate;
        break;
      default:
        backgroundColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        label = decision;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPdfUploadSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.uploadDecisionPdfOptional, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: Text(
            _decisionPdfs == null || _decisionPdfs!.isEmpty
                ? l10n.choosePdfFiles
                : '${_decisionPdfs!.length} ${l10n.filesSelected}',
          ),
          onPressed: () async {
            final result = await FilePicker.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['pdf'],
              allowMultiple: true,
              withData: true, // Required for web platform to get file bytes
            );

            if (result != null) {
              setState(() {
                _decisionPdfs = result.files;
              });
            }
          },
        ),
        if (_decisionPdfs != null && _decisionPdfs!.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...(_decisionPdfs!.map(
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
                      setState(() {
                        _decisionPdfs!.remove(file);
                      });
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

  Widget _buildDecisionSummary(AppLocalizations l10n) {
    final confirmCount = _employeeDecisions.values.where((d) => d == TopManagementDecision.confirm).length;
    final convertCount =
        _employeeDecisions.values.where((d) => d == TopManagementDecision.convertToDisciplinary).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.decisionSummary, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryChip(l10n.confirmed, confirmCount, Colors.green),
              const SizedBox(width: 12),
              _buildSummaryChip(l10n.converted, convertCount, Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[300]!, width: 1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.finalDecisionWarning,
                    style: TextStyle(color: Colors.red[900], fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, int count, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: color[900], fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color[700], borderRadius: BorderRadius.circular(10)),
            child: Text(
              count.toString(),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitDecision() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation: Ensure all escalated employees have decisions
    if (_employeeDecisions.length != _escalatedEmployees.length) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectDecisionForAll)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Extract PDF bytes and file names from picked files
      final pdfBytes = _decisionPdfs?.where((f) => f.bytes != null).map((f) => f.bytes!).toList();
      final pdfFileNames = _decisionPdfs?.where((f) => f.bytes != null).map((f) => f.name).toList();

      // Convert enum to string for backend
      final decisionsAsStrings = _employeeDecisions.map((code, decision) => MapEntry(code, decision.name));

      // Call BLoC event to record Top Management decision
      context.read<UserDisciplinaryActionRequestsBloc>().add(
        RecordTopManagementInvestigationDecision(
          investigationId: widget.investigation.id!,
          decidedBy: context.read<UserBloc>().state.user!.id!,
          employeeDecisions: decisionsAsStrings,
          pdfBytes: pdfBytes,
          pdfFileNames: pdfFileNames,
        ),
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.tmDecisionSubmittedSuccess)));

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
