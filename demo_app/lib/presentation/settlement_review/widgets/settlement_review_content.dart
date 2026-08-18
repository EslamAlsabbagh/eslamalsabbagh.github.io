import 'package:hrms_demo/core/constants/feature_flags.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/advance_on_salary_request_model.dart';
import 'package:hrms_demo/presentation/settlement_review/bloc/settlement_review_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:hrms_demo/presentation/widgets/paged_requests_pagination_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SettlementReviewContent extends StatelessWidget {
  const SettlementReviewContent({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final userCode = context.read<UserBloc>().state.user?.id;

    return MainLayout(
      title: AppLocalizations.of(context)!.settlementReview,
      child: BlocConsumer<SettlementReviewBloc, SettlementReviewState>(
        listener: (context, state) {
          // Show success message when notification is sent
          if (state.sendStatus == Status.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.settlementNotificationSent),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Show error message if sending fails
          if (state.sendStatus == Status.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.failure?.message ?? 'Error sending notification'),
                backgroundColor: Colors.red,
              ),
            );
          }

          // Show success message when all notifications are sent
          if (state.sendAllStatus == Status.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.allNotificationsSent),
                backgroundColor: Colors.green,
              ),
            );
          }

          // Show success message when notification is skipped
          if (state.skipStatus == Status.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context)!.notificationSkipped),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
        builder: (context, state) {
          // On the paged path `requests` is always empty and the rows live in
          // `paged`; the rest of this builder reads through `rows` so both
          // paths share one layout.
          final paged = state.paged;
          final rows = FeatureFlags.serverPagedAdvanceRequests ? paged.items : state.requests;
          // The server's total across all pages, not the length of what is on
          // screen — the header count and the Send All confirmation both quote
          // it, and both would understate the work otherwise.
          final totalCount = FeatureFlags.serverPagedAdvanceRequests ? paged.totalCount : state.requests.length;

          if (state.status == Status.loading ||
              (FeatureFlags.serverPagedAdvanceRequests && paged.isPageLoading && rows.isEmpty)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (FeatureFlags.serverPagedAdvanceRequests && paged.pageFailure != null && rows.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(paged.pageFailure?.message ?? 'Error loading requests'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<SettlementReviewBloc>().add(LoadSettlementReviewRequests()),
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            );
          }

          if (state.status == Status.failure) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.failure?.message ?? 'Error loading requests'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<SettlementReviewBloc>().add(LoadSettlementReviewRequests());
                    },
                    child: Text(AppLocalizations.of(context)!.retry),
                  ),
                ],
              ),
            );
          }

          if (rows.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 64, color: Colors.green[300]),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noSettlementReviewRequests,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: context.screenWidth >= 600 ? context.screenWidth - 65 : 1000,
              child: Column(
                children: [
                  // Header with Send All button
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$totalCount ${AppLocalizations.of(context)!.settlementReviewRequests}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed:
                              state.sendAllStatus == Status.loading
                                  ? null
                                  // Quotes the whole-scope total, which is what
                                  // Send All actually acts on — the server
                                  // supplies the id list.
                                  : () => _showSendAllConfirmation(context, totalCount, userCode!),
                          icon:
                              state.sendAllStatus == Status.loading
                                  ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                  : const Icon(Icons.send),
                          label: Text(AppLocalizations.of(context)!.sendAllNotifications),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // List of requests
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final request = rows[index];
                        final isProcessing = state.processingRequestId == request.id;

                        return _buildRequestCard(context, request, isProcessing, state, userCode!, isArabic);
                      },
                    ),
                  ),
                  if (FeatureFlags.serverPagedAdvanceRequests && paged.totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: PagedRequestsPaginationControls(
                        page: paged.page,
                        totalCount: paged.totalCount,
                        pageSize: paged.pageSize,
                        isLoading: paged.isPageLoading,
                        onPageChanged:
                            (page) => context.read<SettlementReviewBloc>().add(SettlementReviewPageChanged(page)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    AdvanceOnSalaryRequestModel request,
    bool isProcessing,
    SettlementReviewState state,
    int userCode,
    bool isArabic,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      child: InkWell(
        onTap: () => _showRequestDetailsDialog(context, request, isArabic),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row - Requestor, Borrower, and Status Badge
              Row(
                children: [
                  // Requestor name and code
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 280),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.requestor,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getDisplayName(context, request.requestorEnglishName, request.requestorArabicName)} (${request.requestorCode})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Borrower name and code
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.borrower,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_getDisplayName(context, request.borrowerEnglishName, request.borrowerArabicName)} (${request.borrowerCode})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Ready for Review Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.readyForReview,
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const Divider(),
              // Main Content Row
              Row(
                children: [
                  // Amount Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.amountRequested,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${request.amount ?? 0} ${isArabic ? 'جنيه' : 'EGP'}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                        ),
                      ],
                    ),
                  ),
                  // Period Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.period,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${request.effectivePeriodInMonths ?? 0} ${AppLocalizations.of(context)!.months}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  // Monthly Payment Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.monthlyPaymentLabel,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${NumberFormat('#,##0.00').format(request.currentMonthlyPayment ?? 0)} ${isArabic ? 'جنيه' : 'EGP'}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  // Payment End Date Section
                  if (request.effectivePaymentEndDate != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.paymentEndDateLabel,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(request.effectivePaymentEndDate!),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  // Ready Date Section
                  if (request.settlementReadyDate != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.readyForReview,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy').format(request.settlementReadyDate!),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // View PDF button
                  OutlinedButton.icon(
                    onPressed: request.pdfFilePath != null ? () => _openPDF(context, request.pdfFilePath!) : null,
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: Text(AppLocalizations.of(context)!.reviewPdf),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red[700]),
                  ),
                  const SizedBox(width: 8),
                  // Skip button
                  OutlinedButton.icon(
                    onPressed:
                        isProcessing || state.skipStatus == Status.loading
                            ? null
                            : () {
                              context.read<SettlementReviewBloc>().add(
                                SkipSettlementNotification(request.id!, userCode),
                              );
                            },
                    icon:
                        isProcessing && state.skipStatus == Status.loading
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.skip_next, size: 16),
                    label: Text(AppLocalizations.of(context)!.skipNotification),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                  ),
                  const SizedBox(width: 8),
                  // Send Notification button
                  ElevatedButton.icon(
                    onPressed:
                        isProcessing || state.sendStatus == Status.loading
                            ? null
                            : () {
                              context.read<SettlementReviewBloc>().add(
                                SendSettlementNotification(request.id!, userCode),
                              );
                            },
                    icon:
                        isProcessing && state.sendStatus == Status.loading
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                            : const Icon(Icons.send, size: 16),
                    label: Text(AppLocalizations.of(context)!.sendNotification),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600], foregroundColor: Colors.white),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayName(BuildContext context, String? englishName, String? arabicName) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    if (isArabic) {
      return arabicName ?? englishName ?? '';
    }
    return englishName ?? arabicName ?? '';
  }

  void _showRequestDetailsDialog(BuildContext context, AdvanceOnSalaryRequestModel request, bool isArabic) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.requestDetails),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDetailRow(
                    context,
                    AppLocalizations.of(context)!.requestor,
                    '${_getDisplayName(context, request.requestorEnglishName, request.requestorArabicName)} (${request.requestorCode})',
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    AppLocalizations.of(context)!.borrower,
                    '${_getDisplayName(context, request.borrowerEnglishName, request.borrowerArabicName)} (${request.borrowerCode})',
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    AppLocalizations.of(context)!.amountRequested,
                    '${request.amount ?? 0} ${isArabic ? 'جنيه' : 'EGP'}',
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    AppLocalizations.of(context)!.period,
                    '${request.effectivePeriodInMonths ?? 0} ${AppLocalizations.of(context)!.months}',
                  ),
                  const Divider(),
                  _buildDetailRow(
                    context,
                    AppLocalizations.of(context)!.monthlyPaymentLabel,
                    '${NumberFormat('#,##0.00').format(request.currentMonthlyPayment ?? 0)} ${isArabic ? 'جنيه' : 'EGP'}',
                  ),
                  if (request.effectivePaymentEndDate != null) ...[
                    const Divider(),
                    _buildDetailRow(
                      context,
                      AppLocalizations.of(context)!.paymentEndDateLabel,
                      DateFormat('MMM dd, yyyy').format(request.effectivePaymentEndDate!),
                    ),
                  ],
                  if (request.settlementReadyDate != null) ...[
                    const Divider(),
                    _buildDetailRow(
                      context,
                      AppLocalizations.of(context)!.readyForReview,
                      DateFormat('MMM dd, yyyy').format(request.settlementReadyDate!),
                    ),
                  ],
                  if (request.pdfUrl != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openPDF(context, request.pdfUrl!),
                        icon: const Icon(Icons.picture_as_pdf),
                        label: Text(AppLocalizations.of(context)!.reviewPdf),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red[700]),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  void _showSendAllConfirmation(BuildContext context, int count, int userCode) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.confirmSendAll,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 350, maxWidth: 450),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context)!.confirmSendAllNotifications(count.toString()),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<SettlementReviewBloc>().add(SendAllSettlementNotifications(userCode));
                },
                icon: const Icon(Icons.send, size: 18),
                label: Text(AppLocalizations.of(context)!.sendAllNotifications),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
    );
  }

  void _openPDF(BuildContext context, String pdfUrl) async {
    final uri = Uri.parse(pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorOccurred), backgroundColor: Colors.red),
        );
      }
    }
  }
}
