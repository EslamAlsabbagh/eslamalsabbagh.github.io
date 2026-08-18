import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/constants/violation_category.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/bloc/user_disciplinary_action_requests_bloc.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/bloc/user_disciplinary_action_requests_event.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/bloc/user_disciplinary_action_requests_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// A read-only widget that displays disciplinary action details.
/// Follows the same pattern as InvestigationDetailContent — a public,
/// reusable widget that can be embedded in any dialog.
class DisciplinaryActionDetailContent extends StatefulWidget {
  final DisciplinaryActionRequestModel request;

  /// Controls visibility of sections based on user role
  final bool showIncidentDescription;
  final bool showAttachments;
  final bool showInvestigationDetails; // N+2 investigation reason + investigation PDF
  final bool showLegalEscalation; // Legal escalation section + legal PDF
  final bool isEmployeeView; // Shows "Closed at HR" for suspend/terminate
  final bool showDetailedUserInfo; // Team requests: requestor/employee boxes with title/dept
  final String? currentApproverOverride; // Overrides current approver display text

  const DisciplinaryActionDetailContent({
    super.key,
    required this.request,
    this.showIncidentDescription = true,
    this.showAttachments = true,
    this.showInvestigationDetails = true,
    this.showLegalEscalation = true,
    this.isEmployeeView = false,
    this.showDetailedUserInfo = false,
    this.currentApproverOverride,
  });

  @override
  State<DisciplinaryActionDetailContent> createState() => _DisciplinaryActionDetailContentState();
}

class _DisciplinaryActionDetailContentState extends State<DisciplinaryActionDetailContent> {
  String _getDisplayName(BuildContext context, String? englishName, String? arabicName) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return isArabic ? (arabicName ?? englishName ?? '') : (englishName ?? arabicName ?? '');
  }

  String _formatDeductDays(BuildContext context, double days) {
    final l10n = AppLocalizations.of(context)!;
    if (days == 0.25) return l10n.quarterDay;
    if (days == 0.5) return l10n.halfDay;
    if (days == 1.0) return '1 ${l10n.day}';
    return '${days.toInt()} ${l10n.days}';
  }

  String _getViolationDisplayName(BuildContext context, DisciplinaryActionRequestModel request) {
    if (request.violationCategory == null || request.violation == null) return '';
    if (request.violationCategory == 'other') return request.violation!;
    final violation = ViolationData.findViolationByKey(request.violation!);
    return violation?.getLocalizedName(context) ?? request.violation!;
  }

  String _getLocalizedCategoryName(BuildContext context, String? categoryValue) {
    if (categoryValue == null) return '';
    final category = ViolationCategory.fromString(categoryValue);
    return category.getLocalizedName(context);
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildUserInfoBox({
    required String title,
    required String name,
    required String titleText,
    required String department,
    required String hireDate,
    required AppLocalizations l10n,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          _buildDetailRow(l10n.name, name),
          _buildDetailRow(l10n.title, titleText),
          _buildDetailRow(l10n.department, department),
          _buildDetailRow(l10n.hireDate, hireDate),
        ],
      ),
    );
  }

  String _getFileNameFromPath(String path) {
    final parts = path.split('_');
    if (parts.length >= 4) return parts.sublist(3).join('_');
    return path;
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.attach_file;
    }
  }

  Future<void> _openAttachment(String url, String fileName) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.openAttachmentFailed)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.openAttachmentFailed)));
      }
    }
  }

  String _parseChangeLogForLocale(String comments) {
    final locale = Localizations.localeOf(context).languageCode;
    final isArabic = locale == 'ar';
    final lines = comments.split('\n');
    final parsedLines = <String>[];

    for (String line in lines) {
      if (line.contains(' EN: ') && line.contains(' | AR: ')) {
        final timestamp = line.substring(0, line.indexOf(']') + 1);
        final content = line.substring(line.indexOf(']') + 2);
        final enIndex = content.indexOf('EN: ');
        final arIndex = content.indexOf(' | AR: ');

        if (enIndex != -1 && arIndex != -1) {
          final englishText = content.substring(enIndex + 4, arIndex);
          final arabicText = content.substring(arIndex + 6);
          parsedLines.add('$timestamp ${isArabic ? arabicText : englishText}');
        } else {
          parsedLines.add(line);
        }
      } else {
        parsedLines.add(line);
      }
    }

    return parsedLines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: 550,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request Details
            _buildDetailRow(l10n.requestId, request.id?.toString() ?? 'N/A'),

            if (request.createdAt != null)
              _buildDetailRow(l10n.createdAt, DateFormat('yyyy-MM-dd hh:mm a').format(request.tzCreatedAt)),

            // Requestor & Employee information
            if (widget.showDetailedUserInfo) ...[
              const SizedBox(height: 8),
              _buildUserInfoBox(
                title: l10n.requestor,
                name:
                    '${_getDisplayName(context, request.requestorEnglishName, request.requestorArabicName)} (${request.requestorCode})',
                titleText:
                    isArabic
                        ? (request.requestorTitle ?? '')
                        : (request.requestorEnglishTitle ?? request.requestorTitle ?? ''),
                department:
                    isArabic
                        ? (request.requestorDepartment ?? '')
                        : (request.requestorEnglishDepartment ?? request.requestorDepartment ?? ''),
                hireDate: request.requestorHireDate ?? '',
                l10n: l10n,
              ),
              const SizedBox(height: 12),
              _buildUserInfoBox(
                title: l10n.employeewithAl,
                name:
                    '${_getDisplayName(context, request.employeeEnglishName, request.employeeArabicName)} (${request.employeeCode})',
                titleText:
                    isArabic
                        ? (request.employeeTitle ?? '')
                        : (request.employeeEnglishTitle ?? request.employeeTitle ?? ''),
                department:
                    isArabic
                        ? (request.employeeDepartment ?? '')
                        : (request.employeeEnglishDepartment ?? request.employeeDepartment ?? ''),
                hireDate: request.employeeHireDate ?? '',
                l10n: l10n,
              ),
              const SizedBox(height: 8),
            ] else ...[
              _buildDetailRow(
                l10n.requestor,
                '${_getDisplayName(context, request.requestorEnglishName, request.requestorArabicName)} (${request.requestorCode})',
              ),
              _buildDetailRow(
                l10n.employee,
                '${_getDisplayName(context, request.employeeEnglishName, request.employeeArabicName)} (${request.employeeCode})',
              ),
            ],

            _buildDetailRow(l10n.actionType, request.getLocalizedActionType(context)),

            if (request.violationCategory != null)
              _buildDetailRow(l10n.violationCategory, _getLocalizedCategoryName(context, request.violationCategory)),

            if (request.violation != null) _buildDetailRow(l10n.violation, _getViolationDisplayName(context, request)),

            if (request.violationDate != null)
              _buildDetailRow(l10n.violationDate, DateFormat('MMM dd, yyyy').format(request.violationDate!)),

            if (request.hasDeductionDays)
              _buildDetailRow(l10n.deductDays, _formatDeductDays(context, request.deductionDays)),

            if (request.hasSuspensionDays)
              _buildDetailRow(
                l10n.suspensionDays,
                '${request.suspensionDays} ${request.suspensionDays == 1 ? l10n.day : l10n.days}',
              ),

            _buildDetailRow(l10n.status, request.getLocalizedStatus(context)),

            if (request.status == 'pending' || request.status == 'on_hold')
              _buildDetailRow(
                l10n.currentApprover,
                widget.currentApproverOverride ?? request.getLocalizedApproverName(context),
              ),

            // Approval History
            if (request.n2ApprovalDate != null)
              _buildDetailRow(
                () {
                  final isDeclinedByN2 =
                      request.status?.toLowerCase() == 'declined' && request.currentApprover?.toLowerCase() == 'n2';
                  return isDeclinedByN2 ? l10n.declinedByN2 : l10n.approvedByN2;
                }(),
                Localizations.localeOf(context).languageCode == 'ar'
                    ? "${request.n2ArabicName ?? 'N+2'} ${l10n.on} ${DateFormat('yyyy-MM-dd').format(request.n2ApprovalDate!)}"
                    : "${request.n2EnglishName ?? 'N+2'} ${l10n.on} ${DateFormat('yyyy-MM-dd').format(request.n2ApprovalDate!)}",
              ),

            if (request.hrApprovalDate != null)
              _buildDetailRow(
                () {
                  final isDeclinedByHR =
                      request.status?.toLowerCase() == 'declined' && request.currentApprover?.toLowerCase() == 'hr';
                  return isDeclinedByHR ? l10n.declinedByHR : l10n.approvedByHR;
                }(),
                () {
                  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
                  String approverName;
                  if (request.hrEnglishName != null || request.hrArabicName != null) {
                    approverName =
                        isArabic
                            ? (request.hrArabicName ?? request.hrEnglishName ?? '')
                            : (request.hrEnglishName ?? request.hrArabicName ?? '');
                  } else {
                    approverName = '';
                  }
                  if (approverName.isNotEmpty) {
                    return "$approverName ${l10n.on} ${DateFormat('yyyy-MM-dd').format(request.hrApprovalDate!)}";
                  } else {
                    return "${l10n.on} ${DateFormat('yyyy-MM-dd').format(request.hrApprovalDate!)}";
                  }
                }(),
              ),

            // Incident Description
            if (request.incidentDescription?.isNotEmpty == true && widget.showIncidentDescription) ...[
              const SizedBox(height: 16),
              Text(
                l10n.incidentDescription,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(request.incidentDescription!, style: const TextStyle(fontSize: 14)),
              ),
            ],

            // Attachments
            if (request.attachments != null && request.attachments!.isNotEmpty && widget.showAttachments) ...[
              const SizedBox(height: 16),
              Text(
                l10n.attachments,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              BlocBuilder<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
                builder: (context, state) {
                  final isLoading = state.attachmentUrlsStatus == Status.loading;
                  final signedUrls = state.attachmentSignedUrls;

                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child:
                        isLoading
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(l10n.loadingAttachments),
                                  ],
                                ),
                              ),
                            )
                            : signedUrls == null
                            ? TextButton.icon(
                              onPressed: () {
                                context.read<UserDisciplinaryActionRequestsBloc>().add(
                                  FetchAttachmentSignedUrls(request.attachments!),
                                );
                              },
                              icon: const Icon(Icons.folder_open, size: 20),
                              label: Text('${l10n.viewAttachment} (${request.attachments!.length})'),
                            )
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (int i = 0; i < request.attachments!.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: InkWell(
                                      onTap:
                                          () => _openAttachment(
                                            signedUrls[i],
                                            _getFileNameFromPath(request.attachments![i]),
                                          ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getFileIcon(request.attachments![i]),
                                            color: Colors.blue[700],
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _getFileNameFromPath(request.attachments![i]),
                                              style: TextStyle(
                                                color: Colors.blue[700],
                                                decoration: TextDecoration.underline,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Icon(Icons.open_in_new, size: 16, color: Colors.blue[700]),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                  );
                },
              ),
            ],

            // Employee Acknowledgment
            if (request.employeeAcknowledgmentDate != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: request.autoEscalated == true ? Colors.orange[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: request.autoEscalated == true ? Colors.orange[200]! : Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          request.autoEscalated == true ? Icons.access_time : Icons.check_circle,
                          color: request.autoEscalated == true ? Colors.orange[700] : Colors.green[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          request.autoEscalated == true ? l10n.autoEscalated : l10n.employeeAcknowledged,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: request.autoEscalated == true ? Colors.orange[900] : Colors.green[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          '${request.autoEscalated == true ? l10n.escalationDate : l10n.acknowledgmentDate}: ',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          DateFormat('yyyy-MM-dd HH:mm').format(request.employeeAcknowledgmentDate!),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    if (request.employeeAcknowledgmentType != null &&
                        request.employeeAcknowledgmentType != 'auto_escalated') ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            '${l10n.acknowledgmentType}: ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            request.employeeAcknowledgmentType == 'confirm'
                                ? l10n.confirmed
                                : l10n.acknowledgedWithRemark,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                    if (request.employeeAcknowledgmentRemark != null &&
                        request.employeeAcknowledgmentRemark!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(l10n.employeeRemark, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(request.employeeAcknowledgmentRemark!, style: const TextStyle(fontSize: 14)),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // N+2 Approval Reason
            if (request.n2ApprovalReason != null && request.n2ApprovalReason!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '${l10n.approvalReason} (N+2)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(request.n2ApprovalReason!, style: const TextStyle(fontSize: 14)),
              ),
            ],

            // N+2 Investigation Reason (hidden from Employee and N+1)
            if (request.n2InvestigationReason != null &&
                request.n2InvestigationReason!.isNotEmpty &&
                widget.showInvestigationDetails) ...[
              const SizedBox(height: 16),
              Text(
                '${_getDisplayName(context, request.n2EnglishName, request.n2ArabicName)} ${l10n.n2SendingForInvestigationReason}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(request.n2InvestigationReason!, style: const TextStyle(fontSize: 14)),
              ),
            ],

            // Hold Reason
            if (request.holdReason != null && request.holdReason!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.holdReason,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Text(request.holdReason!, style: const TextStyle(fontSize: 14)),
              ),
            ],

            // HR Approval Reason
            if (request.hrApprovalReason != null && request.hrApprovalReason!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '${l10n.approvalReason} (HR)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Text(request.hrApprovalReason!, style: const TextStyle(fontSize: 14)),
              ),
            ],

            // Decline Reason
            if (request.declineReason != null && request.declineReason!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.declineReason,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(request.declineReason!, style: const TextStyle(fontSize: 14)),
              ),
            ],

            // Investigation PDF (hidden from Employee and N+1)
            if (request.hasInvestigationPdf && widget.showInvestigationDetails) _buildInvestigationPdfSection(request),

            // Change Log
            if (request.comments != null && request.comments!.isNotEmpty) _buildChangeLogSection(request),

            const SizedBox(height: 24),

            // Legal Escalation (hidden from Employee and N+1)
            if (request.escalatedToLegal == true && widget.showLegalEscalation) ...[
              const SizedBox(height: 16),
              Text(
                l10n.legalEscalation,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (request.legalEscalationReason != null && request.legalEscalationReason!.isNotEmpty) ...[
                      Text(
                        '${l10n.escalationReason}:',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(request.legalEscalationReason!, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 12),
                    ],
                    if (request.legalEscalationDate != null) ...[
                      Row(
                        children: [
                          Text(
                            '${l10n.escalationDate}: ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            DateFormat('yyyy-MM-dd').format(request.legalEscalationDate!),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (request.legalEnglishName != null || request.legalArabicName != null) ...[
                      Row(
                        children: [
                          Text(
                            '${l10n.legalApprover}: ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            _getDisplayName(context, request.legalEnglishName, request.legalArabicName),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (request.legalCompletionDate != null) ...[
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700], size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${l10n.completionDate}: ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            DateFormat('yyyy-MM-dd').format(request.legalCompletionDate!),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],

            // Legal Investigation PDF (hidden from Employee and N+1)
            if (request.hasLegalInvestigationPdf && widget.showLegalEscalation)
              _buildLegalInvestigationPdfSection(request),

            // HR Final Action
            if (request.hrFinalAction != null) ...[
              const SizedBox(height: 16),
              if (widget.isEmployeeView && (request.hrFinalAction == 'suspend' || request.hrFinalAction == 'terminate'))
                // Employee view: show "Closed at HR" for suspend/terminate
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock, color: Colors.grey[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n.closedAtHR,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey[800]),
                      ),
                    ],
                  ),
                )
              else
                _buildHRFinalActionDetails(request),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestigationPdfSection(DisciplinaryActionRequestModel request) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.hrInvestigationPdf,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.investigationPdfDocument,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    if (request.hrInvestigationPdfUploadedAt != null)
                      Text(
                        l10n.uploadedDate(
                          DateFormat('MMM dd, yyyy HH:mm').format(request.hrInvestigationPdfUploadedAt!),
                        ),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  if (request.hrInvestigationPdfUrl != null) {
                    context.read<UserDisciplinaryActionRequestsBloc>().add(
                      OpenInvestigationPdf(request.hrInvestigationPdfUrl!),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(l10n.viewButton, style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegalInvestigationPdfSection(DisciplinaryActionRequestModel request) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.purple, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.legalInvestigationPdf,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.purple),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple[200]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.legalInvestigationPdfDocument,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    if (request.legalInvestigationPdfUploadedAt != null)
                      Text(
                        l10n.uploadedDate(
                          DateFormat('MMM dd, yyyy HH:mm').format(request.legalInvestigationPdfUploadedAt!),
                        ),
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  if (request.legalInvestigationPdfUrl != null) {
                    context.read<UserDisciplinaryActionRequestsBloc>().add(
                      OpenInvestigationPdf(request.legalInvestigationPdfUrl!),
                    );
                  }
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(l10n.viewButton, style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.purple,
                  side: const BorderSide(color: Colors.purple),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChangeLogSection(DisciplinaryActionRequestModel request) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.history, color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Text(
              l10n.changeLog,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text(
              _parseChangeLogForLocale(request.comments!),
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHRFinalActionDetails(DisciplinaryActionRequestModel request) {
    final l10n = AppLocalizations.of(context)!;

    String actionLabel;
    Color actionColor;
    Color backgroundColor;
    Color borderColor;

    switch (request.hrFinalAction) {
      case 'approve':
        actionLabel = l10n.finalApproval;
        actionColor = Colors.green[700]!;
        backgroundColor = Colors.green[50]!;
        borderColor = Colors.green[200]!;
        break;
      case 'decline':
        actionLabel = l10n.finalDecline;
        actionColor = Colors.red[700]!;
        backgroundColor = Colors.red[50]!;
        borderColor = Colors.red[200]!;
        break;
      case 'suspend':
        actionLabel = l10n.suspension;
        actionColor = Colors.orange[700]!;
        backgroundColor = Colors.orange[50]!;
        borderColor = Colors.orange[200]!;
        break;
      case 'terminate':
        actionLabel = l10n.termination;
        actionColor = Colors.red[900]!;
        backgroundColor = Colors.red[50]!;
        borderColor = Colors.red[300]!;
        break;
      default:
        actionLabel = request.hrFinalAction ?? '';
        actionColor = Colors.grey[700]!;
        backgroundColor = Colors.grey[50]!;
        borderColor = Colors.grey[200]!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.hrFinalDecision,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    request.hrFinalAction == 'approve'
                        ? Icons.check_circle
                        : request.hrFinalAction == 'decline'
                        ? Icons.cancel
                        : request.hrFinalAction == 'suspend'
                        ? Icons.pause_circle
                        : Icons.block,
                    color: actionColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(actionLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: actionColor)),
                ],
              ),
              if (request.hrFinalAction == 'suspend' &&
                  (request.suspensionStartDate != null || request.suspensionEndDate != null)) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                if (request.suspensionStartDate != null) ...[
                  Row(
                    children: [
                      Text('${l10n.startDate}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        DateFormat('yyyy-MM-dd').format(request.suspensionStartDate!),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                if (request.suspensionEndDate != null) ...[
                  Row(
                    children: [
                      Text('${l10n.endDate}: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(
                        DateFormat('yyyy-MM-dd').format(request.suspensionEndDate!),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ],
              if (request.hrFinalAction == 'terminate' && request.terminationRecommendedDate != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${l10n.terminationRecommendedDate}: ',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      DateFormat('yyyy-MM-dd').format(request.terminationRecommendedDate!),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
