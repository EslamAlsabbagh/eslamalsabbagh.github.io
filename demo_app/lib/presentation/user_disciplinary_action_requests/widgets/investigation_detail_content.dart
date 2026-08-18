import 'package:hrms_demo/core/constants/violation_category.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/app_localizations.dart';
import '../../../data/models/investigation_request_model.dart';
import '../../../data/models/investigation_decision.dart';
import '../../../core/constants/status.dart';
import '../bloc/user_disciplinary_action_requests_bloc.dart';
import '../bloc/user_disciplinary_action_requests_event.dart';
import '../bloc/user_disciplinary_action_requests_state.dart';
import '../../dashboard/bloc/user_bloc.dart';

/// Investigation Detail Content Widget
/// Pure presentation widget for displaying investigation details.
/// Extracted from InvestigationDetailDialog for reuse in InvestigationWorkflowDialog.
class InvestigationDetailContent extends StatefulWidget {
  final InvestigationRequestModel investigation;
  final bool showActionButtons;
  final VoidCallback? onRecordDecision; // Callback to trigger view transition
  final Function(int disciplinaryActionId)? onOpenDisciplinaryAction; // Callback to open linked DA

  // Role-based visibility controls (defaults preserve existing behavior)
  final bool showIncidentDescription;
  final bool showRequestorAttachments;
  final bool showDecisionHistory;
  final bool showLinkedDisciplinaryActions;
  final bool showEmployeesList;
  final bool showCurrentApprover;
  final bool showDecisionDetails; // Controls remarks, PDFs, attachments within decision stages

  const InvestigationDetailContent({
    super.key,
    required this.investigation,
    this.showActionButtons = false,
    this.onRecordDecision,
    this.onOpenDisciplinaryAction,
    this.showIncidentDescription = true,
    this.showRequestorAttachments = true,
    this.showDecisionHistory = true,
    this.showLinkedDisciplinaryActions = true,
    this.showEmployeesList = true,
    this.showCurrentApprover = true,
    this.showDecisionDetails = true,
  });

  @override
  State<InvestigationDetailContent> createState() => _InvestigationDetailContentState();
}

class _InvestigationDetailContentState extends State<InvestigationDetailContent> {
  /// Whether any action buttons will actually be visible.
  /// Combines the parent's showActionButtons flag with the investigation's pending status.
  bool _acknowledged = false;

  /// Inline message overlay state (like advance on salary requests)
  String? _messageText;
  Color? _messageColor;
  bool _showMessage = false;

  bool get _hasVisibleActionButtons => widget.showActionButtons && widget.investigation.isPending;

  /// Shows a success message overlay that auto-hides after 3 seconds
  void _showSuccessMessage(String message) {
    setState(() {
      _messageText = message;
      _messageColor = Colors.green;
      _showMessage = true;
    });

    // Auto-hide message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showMessage = false;
        });
      }
    });
  }

  /// Hides the message overlay immediately
  void _hideMessage() {
    setState(() {
      _showMessage = false;
    });
  }

  String _getViolationDisplayName(BuildContext context, InvestigationRequestModel request) {
    if (request.violationCategory == null || request.violation == null) {
      return '';
    }

    // For "Other" category, return the custom text directly
    if (request.violationCategory == 'other') {
      return request.violation!;
    }

    // For predefined categories, find the violation and return localized name
    final violation = ViolationData.findViolationByKey(request.violation!);
    return violation?.getLocalizedName(context) ?? request.violation!;
  }

  String _getLocalizedCategoryName(BuildContext context, String? categoryValue) {
    if (categoryValue == null) return '';
    final category = ViolationCategory.fromString(categoryValue);
    return category.getLocalizedName(context);
  }

  @override
  void initState() {
    super.initState();
    // Fetch linked disciplinary actions (skip if section is hidden)
    if (widget.showLinkedDisciplinaryActions && widget.investigation.id != null) {
      context.read<UserDisciplinaryActionRequestsBloc>().add(FetchLinkedDisciplinaryActions(widget.investigation.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Main scrollable content
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: _hasVisibleActionButtons ? 70 : 16, // Add extra bottom padding if action buttons are shown
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === SECTION 1: Basic Information ===
                _buildBasicInfoSection(l10n),

                const Divider(height: 32, thickness: 2),

                // === SECTION 2: Investigation Details ===
                _buildInvestigationDetailsSection(l10n),

                // === SECTION 2.5: Requestor Attachments ===
                if (widget.showRequestorAttachments) _buildRequestorAttachmentsSection(l10n),

                // === SECTION 3: Employees List ===
                if (widget.showEmployeesList) _buildEmployeesSection(l10n, isArabic),

                // === SECTION 4: Decision History ===
                if (widget.showDecisionHistory) _buildDecisionHistorySection(l10n, isArabic),

                // === SECTION 5: Linked Disciplinary Actions ===
                if (widget.showLinkedDisciplinaryActions) _buildLinkedDisciplinaryActionsSection(l10n, isArabic),

                const SizedBox(height: 16), // Reduced padding since we now have explicit spacing
              ],
            ),
          ),
        ),

        // Message overlay (positioned at top)
        if (_showMessage && _messageText != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _messageColor == Colors.green ? Colors.green[50] : Colors.red[50],
                border: Border.all(color: _messageColor ?? Colors.transparent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _messageColor == Colors.green ? Icons.check_circle : Icons.error,
                    color: _messageColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_messageText!, style: TextStyle(color: _messageColor, fontWeight: FontWeight.w500)),
                  ),
                  IconButton(
                    onPressed: _hideMessage,
                    icon: Icon(Icons.close, color: _messageColor, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),

        // Action buttons at the bottom
        if (_hasVisibleActionButtons) ...[
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              width: 600,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
              ),
              clipBehavior: Clip.hardEdge,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Divider(height: 1),
                  Padding(padding: const EdgeInsets.all(16), child: _buildActionButtons(l10n)),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Builds action buttons section
  Widget _buildActionButtons(AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        // "Escalate to Legal" button - shown only if HR is current approver and not already escalated
        if (widget.investigation.isPending &&
            widget.investigation.currentApprover?.toLowerCase() == 'hr' &&
            widget.investigation.escalatedToLegal != true)
          ElevatedButton.icon(
            icon: const Icon(Icons.gavel),
            label: Text(l10n.escalateToLegal),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700], foregroundColor: Colors.white),
            onPressed: () => _showEscalateToLegalDialog(context),
          ),

        // Legal member buttons - shown if current user is legal AND investigation is at legal stage
        if (widget.investigation.isPending &&
            widget.investigation.currentApprover?.toLowerCase() == 'legal' &&
            _isCurrentUserInLegalGroup()) ...[
          // Acknowledge button (only if not yet acknowledged)
          if (widget.investigation.legalAcknowledged != true && !_acknowledged)
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: Text(l10n.acknowledgeInvestigation),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
              onPressed: () => _showAcknowledgeInvestigationDialog(context),
            ),

          // Submit full legal review (per-employee notes + mandatory PDF)
          if (widget.investigation.legalInvestigationPdfUrl == null)
            ElevatedButton.icon(
              icon: const Icon(Icons.gavel),
              label: Text(l10n.submitLegalReview),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
              onPressed: widget.onRecordDecision,
            ),
        ],

        // "Record Decision" button - shown for HR (non-legal) and Top Management
        if (widget.investigation.isPending && widget.investigation.currentApprover?.toLowerCase() != 'legal')
          ElevatedButton.icon(
            icon: const Icon(Icons.edit),
            label: Text(l10n.recordDecision),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
            onPressed: widget.onRecordDecision, // Trigger callback instead of showing dialog
          ),
      ],
    );
  }

  // === SECTION 1: Basic Information ===
  Widget _buildBasicInfoSection(AppLocalizations l10n) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.basicInformation, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 24,
          runSpacing: 12,
          children: [
            _buildInfoChip(label: l10n.requestId, value: '#${widget.investigation.id}', color: Colors.grey),
            _buildInfoChip(
              label: l10n.requestor,
              value: widget.investigation.getRequestorName(isArabic),
              color: Colors.grey,
            ),
            _buildInfoChip(
              label: l10n.createdAt,
              value:
                  widget.investigation.createdAt != null
                      ? DateFormat('yyyy-MM-dd HH:mm').format(widget.investigation.createdAt!.toLocal())
                      : '-',
              color: Colors.grey,
            ),
            _buildInfoChip(
              label: l10n.status,
              value: widget.investigation.getLocalizedStatus(context),
              color: Colors.grey,
            ),
            if (widget.showCurrentApprover &&
                widget.investigation.currentApprover != null &&
                widget.investigation.status == 'pending')
              _buildInfoChip(
                label: l10n.currentApprover,
                value: widget.investigation.getLocalizedCurrentApprover(isArabic),
                color: Colors.grey,
              ),
          ],
        ),
        if (widget.investigation.wasEscalatedFromDisciplinary) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap:
                widget.onOpenDisciplinaryAction != null
                    ? () => widget.onOpenDisciplinaryAction!(widget.investigation.escalatedDisciplinaryActionId!)
                    : null,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.transform, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Text(
                    l10n.escalatedFromDisciplinaryAction(widget.investigation.escalatedDisciplinaryActionId!),
                    style: TextStyle(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.bold,
                      decoration: widget.onOpenDisciplinaryAction != null ? TextDecoration.underline : null,
                      decorationColor: Colors.orange[900],
                    ),
                  ),
                  if (widget.onOpenDisciplinaryAction != null) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.open_in_new, size: 16, color: Colors.orange[700]),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChip({required String label, required String value, required MaterialColor color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: color[600], fontWeight: FontWeight.w500)),
              Text(value, style: TextStyle(fontSize: 14, color: color[900], fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // === SECTION 2: Investigation Details ===
  Widget _buildInvestigationDetailsSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.investigationDetails, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (widget.investigation.violationCategory != null || widget.investigation.violation != null) ...[
          _buildDetailRow(
            l10n.violationCategory,
            _getLocalizedCategoryName(context, widget.investigation.violationCategory),
            Icons.warning,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(l10n.violation, _getViolationDisplayName(context, widget.investigation), Icons.warning),
          const SizedBox(height: 8),
        ],
        if (widget.investigation.violationDate != null)
          _buildDetailRow(
            l10n.violationDate,
            DateFormat('yyyy-MM-dd').format(widget.investigation.violationDate!),
            Icons.event,
          ),
        if (widget.showIncidentDescription && widget.investigation.incidentDescription != null) ...[
          const SizedBox(height: 12),
          Text(l10n.incidentDescription, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(widget.investigation.incidentDescription!),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  // === SECTION 2.5: Requestor Attachments ===
  Widget _buildRequestorAttachmentsSection(AppLocalizations l10n) {
    if (widget.investigation.attachments == null || widget.investigation.attachments!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filter out HR and TM decision attachments — show only original requestor attachments
    final requestorAttachments =
        widget.investigation.attachments!
            .where((path) => !path.contains('hr_attachments') && !path.contains('tm_attachments'))
            .toList();

    if (requestorAttachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(l10n.attachments, style: const TextStyle(fontWeight: FontWeight.bold)), // TODO: Add key if missing
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              requestorAttachments.map((attachmentPath) {
                final fileName = attachmentPath.split('/').last;
                return InkWell(
                  onTap: () {
                    context.read<UserDisciplinaryActionRequestsBloc>().add(OpenInvestigationPdf(attachmentPath));
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getFileIcon(fileName), size: 20, color: Theme.of(context).primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          fileName.length > 25 ? '${fileName.substring(0, 25)}...' : fileName,
                          style: const TextStyle(fontSize: 13, decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
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

  // === SECTION 3: Employees List ===
  Widget _buildEmployeesSection(AppLocalizations l10n, bool isArabic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32, thickness: 2),

        Row(
          children: [
            Text(l10n.employees, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue[300]!, width: 1.5),
              ),
              child: Text(
                '${widget.investigation.employeeCount}',
                style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildEmployeeTable(l10n, isArabic),
      ],
    );
  }

  Widget _buildEmployeeTable(AppLocalizations l10n, bool isArabic) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: 580,
        child: DataTable(
          dataTextStyle: const TextStyle(fontSize: 12),
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
          columns: [
            DataColumn(label: Text(l10n.code)),
            DataColumn(label: Text(l10n.name)),
            DataColumn(label: Text(l10n.department)),
            DataColumn(label: Text(l10n.hireDate)),
          ],
          rows:
              widget.investigation.employeeCodes.map((code) {
                final info = widget.investigation.employeeInfoMap?[code];
                return DataRow(
                  cells: [
                    DataCell(Text(code.toString())),
                    DataCell(
                      Text(
                        isArabic
                            ? info!.arabicName!.length > 20
                                ? '${info.arabicName!.substring(0, 20)}...'
                                : info.arabicName ?? l10n.unknown
                            : info!.englishName!.length > 20
                            ? '${info.englishName!.substring(0, 20)}...'
                            : info.englishName ?? l10n.unknown,
                      ),
                    ),
                    DataCell(Text(isArabic ? info.arabicDepartmentName ?? '-' : info.departmentName ?? '-')),
                    DataCell(Text(info.hireDate ?? '-')),
                  ],
                );
              }).toList(),
        ),
      ),
    );
  }

  /// Checks if current logged-in user is in legal group
  bool _isCurrentUserInLegalGroup() {
    final userBloc = context.read<UserBloc>();
    final user = userBloc.state.user;
    return user?.groups?.contains('legal') ?? false;
  }

  void _showEscalateToLegalDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final TextEditingController reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    final bloc = context.read<UserDisciplinaryActionRequestsBloc>();

    showDialog(
      context: context,
      builder:
          (dialogContext) => BlocProvider.value(
            value: bloc,
            child: StatefulBuilder(
              builder: (ctx, setDialogState) {
                return BlocListener<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
                  listenWhen:
                      (prev, curr) => isLoading && prev.investigationDecisionStatus != curr.investigationDecisionStatus,
                  listener: (ctx, state) {
                    if (state.investigationDecisionStatus == Status.success) {
                      Navigator.pop(dialogContext); // close confirmation dialog
                      if (context.mounted) {
                        Navigator.pop(context, true); // close parent workflow dialog
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(l10n.requestSubmittedSuccessfully)));
                      }
                    } else if (state.investigationDecisionStatus == Status.failure) {
                      setDialogState(() => isLoading = false);
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(state.operationFailure?.message ?? 'Failed to escalate to legal'),
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                  },
                  child: AlertDialog(
                    title: Row(
                      children: [
                        const Icon(Icons.gavel),
                        const SizedBox(width: 8),
                        Expanded(child: Text(l10n.escalateToLegalDepartment, style: const TextStyle(fontSize: 18))),
                      ],
                    ),
                    content: SizedBox(
                      width: 500,
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Investigation summary box
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.purple[200]!, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${l10n.investigation} #${widget.investigation.id}',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple[900]),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n.afterSubmittingReturnedToHr,
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Reason text field
                            TextFormField(
                              controller: reasonController,
                              decoration: InputDecoration(
                                labelText: l10n.escalationReason,
                                hintText: l10n.provideReasonForEscalation,
                                border: const OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return l10n.pleaseProvideEscalationReason;
                                }
                                if (value.trim().length < 10) {
                                  return l10n.pleaseProvideEscalationReason;
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
                        child: Text(l10n.cancel),
                      ),
                      ElevatedButton.icon(
                        icon:
                            isLoading
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                                : const Icon(Icons.gavel),
                        label: Text(l10n.escalateToLegal),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                        ),
                        onPressed:
                            isLoading
                                ? null
                                : () {
                                  if (formKey.currentState!.validate()) {
                                    final userCode = context.read<UserBloc>().state.user!.id!;
                                    setDialogState(() => isLoading = true);
                                    context.read<UserDisciplinaryActionRequestsBloc>().add(
                                      EscalateInvestigationToLegal(
                                        investigationId: widget.investigation.id!,
                                        hrCode: userCode,
                                        reason: reasonController.text.trim(),
                                      ),
                                    );
                                    // BlocListener above handles pop + snackbar on success/failure
                                  }
                                },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }

  void _showAcknowledgeInvestigationDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(child: Text(l10n.acknowledgeInvestigation, style: const TextStyle(fontSize: 18))),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
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
                        const SizedBox(height: 8),
                        Text(
                          l10n.acknowledgeInvestigationMessage,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.acknowledgeInvestigationNote,
                          style: TextStyle(fontSize: 12, color: Colors.orange[700], fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(l10n.cancel)),
              ElevatedButton.icon(
                icon: const Icon(Icons.check),
                label: Text(l10n.acknowledge),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700], foregroundColor: Colors.white),
                onPressed: () {
                  final userCode = context.read<UserBloc>().state.user!.id!;

                  Navigator.pop(dialogContext); // Close confirmation dialog

                  // Dispatch acknowledge event
                  context.read<UserDisciplinaryActionRequestsBloc>().add(
                    AcknowledgeInvestigation(investigationId: widget.investigation.id!, legalCode: userCode),
                  );

                  // Hide the acknowledge button immediately
                  setState(() => _acknowledged = true);

                  // Show success message overlay inline (above dialog content)
                  _showSuccessMessage('${l10n.investigation} #${widget.investigation.id} ${l10n.acknowledgedByLegal}');
                },
              ),
            ],
          ),
    );
  }

  // === SECTION 4: Decision History ===
  Widget _buildDecisionHistorySection(AppLocalizations l10n, bool isArabic) {
    // Check if any decision stages will actually be visible
    final hasVisibleDecisions =
        widget.investigation.hasHrDecisions ||
        widget.investigation.hasTopManagementDecisions ||
        (widget.showDecisionDetails &&
            ((widget.investigation.legalDecisions != null && widget.investigation.legalDecisions!.isNotEmpty) ||
                widget.investigation.escalatedToLegal == true));

    if (!hasVisibleDecisions) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32, thickness: 2),
        Text(l10n.decisionHistory, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),

        // HR Decisions
        if (widget.investigation.hasHrDecisions) ...[
          _buildDecisionStage(
            title: l10n.hrDecisions,
            icon: Icons.business_center,
            color: Colors.blue,
            approverName: widget.investigation.getHrName(isArabic),
            decisions: widget.investigation.hrDecisions!,
            pdfUrl: widget.investigation.hrInvestigationPdfUrl,
            pdfUploadedAt: widget.investigation.hrInvestigationPdfUploadedAt,
            // Pass HR attachments (filtered from main attachments list)
            attachments: widget.investigation.attachments?.where((path) => path.contains('hr_attachments')).toList(),
            isArabic: isArabic,
            l10n: l10n,
          ),
          const SizedBox(height: 16),
        ],

        // Legal Review (hidden when decision details are restricted)
        if (widget.showDecisionDetails && widget.investigation.escalatedToLegal == true) ...[
          _buildLegalReviewStage(l10n, isArabic),
          const SizedBox(height: 16),
        ],

        // Top Management Decisions
        if (widget.investigation.hasTopManagementDecisions) ...[
          _buildDecisionStage(
            title: l10n.topManagementDecisions,
            icon: Icons.supervisor_account,
            color: Colors.red,
            approverName: widget.investigation.getTopManagementName(isArabic),
            decisions: widget.investigation.topManagementDecisions!,
            pdfUrl: null,
            pdfUploadedAt: null,
            attachments: widget.investigation.attachments?.where((path) => path.contains('tm_attachments')).toList(),
            isArabic: isArabic,
            l10n: l10n,
          ),
        ],
      ],
    );
  }

  Widget _buildDecisionStage({
    required String title,
    required IconData icon,
    required MaterialColor color,
    required String approverName,
    required List<InvestigationDecision> decisions,
    String? pdfUrl,
    DateTime? pdfUploadedAt,
    List<String>? attachments, // Added attachments parameter
    required bool isArabic,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color[200]!, width: 1.5),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 530,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(icon, color: color[700], size: 22),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color[900])),
                  const SizedBox(width: 12),
                  // Approver
                  Row(
                    children: [
                      Text(
                        '( $approverName ) :',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color[900]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Decisions table
              ..._buildDecisionRows(decisions, isArabic, color, l10n),

              // PDF link
              if (widget.showDecisionDetails && pdfUrl != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 18, color: Colors.red[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          context.read<UserDisciplinaryActionRequestsBloc>().add(OpenInvestigationPdf(pdfUrl));
                        },
                        child: Text(
                          AppLocalizations.of(context)!.viewInvestigationReportPdf,
                          style: TextStyle(color: color[700], decoration: TextDecoration.underline, fontSize: 13),
                        ),
                      ),
                    ),
                    if (pdfUploadedAt != null)
                      Text(
                        '${AppLocalizations.of(context)!.uploaded}: ${DateFormat('yyyy-MM-dd').format(pdfUploadedAt)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ],

              // Attachments list
              if (widget.showDecisionDetails && attachments != null && attachments.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Text(l10n.attachments, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color[900])),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      attachments.map((path) {
                        final fileName = path.split('/').last;
                        return InkWell(
                          onTap: () {
                            context.read<UserDisciplinaryActionRequestsBloc>().add(OpenInvestigationPdf(path));
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: color[200]!),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getFileIcon(fileName), size: 16, color: color[700]),
                                const SizedBox(width: 6),
                                Text(
                                  fileName.length > 20 ? '${fileName.substring(0, 20)}...' : fileName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                    color: color[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDecisionRows(
    List<InvestigationDecision> decisions,
    bool isArabic,
    MaterialColor color,
    AppLocalizations l10n,
  ) {
    return decisions.map((decision) {
      final employeeName = widget.investigation.getEmployeeName(decision.employeeCode, isArabic);

      final decisionIcon = _getDecisionIcon(decision.decision);
      final decisionColor = _getDecisionColor(decision.decision);
      final decisionText = _getDecisionText(decision.decision, l10n);

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(decisionIcon, size: 20, color: decisionColor),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: color[900], fontSize: 14),
                      children: [
                        TextSpan(text: employeeName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        const TextSpan(text: ' - '),
                        TextSpan(
                          text: decisionText,
                          style: TextStyle(color: decisionColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (widget.showDecisionDetails && decision.comment != null && decision.comment!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 28, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.subdirectory_arrow_right, size: 14, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Expanded(child: Text(decision.comment!, style: TextStyle(fontSize: 12, color: Colors.grey[600]))),
                  ],
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildLegalReviewStage(AppLocalizations l10n, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[300]!, width: 1.5),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 530,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(Icons.gavel, color: Colors.purple[700], size: 22),
                  const SizedBox(width: 8),
                  Text(
                    l10n.legalReview,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple[900]),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Escalation date
              if (widget.investigation.legalEscalationDate != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_upward, size: 18, color: Colors.purple[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Escalated on: ${DateFormat('yyyy-MM-dd').format(widget.investigation.legalEscalationDate!)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),

              // Escalation reason
              if (widget.investigation.legalEscalationReason != null &&
                  widget.investigation.legalEscalationReason!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.legalEscalationReason}:',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(widget.investigation.legalEscalationReason!, style: TextStyle(fontSize: 13)),
                    ],
                  ),
                ),

              // Acknowledgment status (hidden when legal PDF is uploaded)
              if (!widget.investigation.hasLegalPdf)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        (widget.investigation.legalAcknowledged == true || _acknowledged)
                            ? Icons.check_circle
                            : Icons.pending,
                        size: 18,
                        color:
                            (widget.investigation.legalAcknowledged == true || _acknowledged)
                                ? Colors.green[700]
                                : Colors.orange[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        (widget.investigation.legalAcknowledged == true || _acknowledged)
                            ? l10n.acknowledgedByLegal
                            : l10n.pendingAcknowledgment,
                        style: TextStyle(
                          fontSize: 13,
                          color:
                              (widget.investigation.legalAcknowledged == true || _acknowledged)
                                  ? Colors.green[900]
                                  : Colors.orange[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

              // PDF link
              if (widget.showDecisionDetails && widget.investigation.hasLegalPdf) ...[
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.picture_as_pdf, size: 18, color: Colors.red[700]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          context.read<UserDisciplinaryActionRequestsBloc>().add(
                            OpenInvestigationPdf(widget.investigation.legalInvestigationPdfUrl!),
                          );
                        },
                        child: Text(
                          l10n.viewLegalInvestigationReportPdf,
                          style: TextStyle(
                            color: Colors.purple[700],
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    if (widget.investigation.legalInvestigationPdfUploadedAt != null)
                      Text(
                        '${l10n.uploaded}: ${DateFormat('yyyy-MM-dd').format(widget.investigation.legalInvestigationPdfUploadedAt!)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                  ],
                ),
              ],

              // Per-employee legal notes (only when comments exist)
              if (widget.showDecisionDetails &&
                  widget.investigation.legalDecisions != null &&
                  widget.investigation.legalDecisions!.any((d) => d.comment?.isNotEmpty == true)) ...[
                const Divider(height: 20),
                for (final d in widget.investigation.legalDecisions!.where((d) => d.comment?.isNotEmpty == true))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: Colors.purple[700]),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.investigation.getEmployeeName(d.employeeCode, isArabic),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.purple[900]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 22, top: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.subdirectory_arrow_right, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(d.comment!, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDecisionIcon(String decision) {
    switch (decision.toLowerCase()) {
      case 'cleared':
      case 'no_action':
        return Icons.check_circle;
      case 'verbal_warning':
        return Icons.warning;
      case 'written_warning':
        return Icons.description;
      case 'suspension':
      case 'suspend':
        return Icons.pause_circle;
      case 'termination':
      case 'terminate':
        return Icons.cancel;
      case 'disciplinary_action':
      case 'take_action':
        return Icons.gavel;
      default:
        return Icons.info;
    }
  }

  Color _getDecisionColor(String decision) {
    switch (decision.toLowerCase()) {
      case 'cleared':
      case 'no_action':
        return Colors.green[700]!;
      case 'verbal_warning':
      case 'written_warning':
        return Colors.orange[700]!;
      case 'suspension':
      case 'suspend':
        return Colors.red[700]!;
      case 'termination':
      case 'terminate':
        return Colors.red[900]!;
      case 'disciplinary_action':
      case 'take_action':
        return Colors.blue[700]!;
      default:
        return Colors.grey[700]!;
    }
  }

  String _getDecisionText(String decision, AppLocalizations l10n) {
    switch (decision.toLowerCase()) {
      case 'cleared':
        return l10n.cleared;
      case 'no_action':
        return l10n.noAction;
      case 'verbal_warning':
        return l10n.verbalWarning;
      case 'written_warning':
        return l10n.writtenWarning;
      case 'suspension':
      case 'suspend':
        return l10n.suspension;
      case 'termination':
      case 'terminate':
        return l10n.termination;
      case 'disciplinary_action':
      case 'take_action':
        return l10n.disciplinaryAction;
      case 'converttodisciplinary':
        return l10n.convertToDisciplinary;
      case 'confirm':
        return l10n.confirmDecision;
      default:
        return decision.replaceAll('_', ' ').toUpperCase();
    }
  }

  // === SECTION 5: Linked Disciplinary Actions ===
  Widget _buildLinkedDisciplinaryActionsSection(AppLocalizations l10n, bool isArabic) {
    return BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
      builder: (context, state) {
        // Loading state
        if (state.linkedDisciplinaryActionsStatus == Status.loading) {
          return Column(
            children: [
              const Divider(height: 32, thickness: 2),
              Text(l10n.linkedActions, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
            ],
          );
        }

        // Error state
        if (state.linkedDisciplinaryActionsStatus == Status.failure) {
          return const SizedBox.shrink(); // Hide section on error
        }

        // Filter out the source DA (the one that escalated to create this investigation)
        final linkedActions =
            state.linkedDisciplinaryActions
                .where((a) => a.id != widget.investigation.escalatedDisciplinaryActionId)
                .toList();

        // Empty state
        if (linkedActions.isEmpty) {
          return const SizedBox.shrink(); // Hide section if no linked actions
        }

        // Success state with data
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 32, thickness: 2),
            Row(
              children: [
                Text(l10n.linkedActions, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.orange[300]!, width: 1.5),
                  ),
                  child: Text(
                    '${linkedActions.length}',
                    style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table of linked actions
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 24,
                dataTextStyle: const TextStyle(fontSize: 12),
                headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
                columns: [
                  const DataColumn(label: Text('#')),
                  DataColumn(label: Text(l10n.code)),
                  DataColumn(label: Text(l10n.employeeName)),
                  DataColumn(label: Text(l10n.actionType)),
                  DataColumn(label: Text(l10n.deductDays)),
                ],
                rows:
                    linkedActions.map((action) {
                      final employeeName =
                          (isArabic
                              ? action.employeeArabicName!.length > 20
                                  ? '${action.employeeArabicName!.substring(0, 20)}...'
                                  : action.employeeArabicName
                              : action.employeeEnglishName!.length > 20
                              ? '${action.employeeEnglishName!.substring(0, 20)}...'
                              : action.employeeEnglishName ?? 'Employee ${action.employeeCode}');

                      final onTap =
                          widget.onOpenDisciplinaryAction != null
                              ? () => widget.onOpenDisciplinaryAction!(action.id!)
                              : null;

                      return DataRow(
                        cells: [
                          DataCell(
                            Text(
                              '#${action.id}',
                              style:
                                  widget.onOpenDisciplinaryAction != null
                                      ? TextStyle(color: Colors.blue[700], decoration: TextDecoration.underline)
                                      : null,
                            ),
                            onTap: onTap,
                          ),
                          DataCell(Text(action.employeeCode?.toString() ?? '-'), onTap: onTap),
                          DataCell(Text(employeeName!), onTap: onTap),
                          DataCell(Text(action.getLocalizedActionType(context)), onTap: onTap),
                          DataCell(
                            Text(
                              '${action.deductionDays.toString()} ${action.deductionDays <= 1 ? l10n.day : l10n.days}',
                            ),
                            onTap: onTap,
                          ),
                        ],
                      );
                    }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
