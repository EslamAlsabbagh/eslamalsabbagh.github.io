import 'dart:typed_data';
import 'package:hrms_demo/core/services/employee_validation_service.dart';
import 'package:hrms_demo/core/services/file_parser_service.dart';
import 'package:hrms_demo/data/models/bulk_employee_row.dart';
import 'package:hrms_demo/data/repos/auth/auth_repo.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/bulk_upload/bloc/bulk_upload_bloc.dart';
import 'package:hrms_demo/presentation/bulk_upload/bloc/bulk_upload_event.dart';
import 'package:hrms_demo/presentation/bulk_upload/bloc/bulk_upload_state.dart';
import 'package:hrms_demo/presentation/bulk_upload/widgets/bulk_upload_review_table.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BulkUploadPage extends StatelessWidget {
  const BulkUploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: _createBloc, child: const _BulkUploadView());
  }

  BulkUploadBloc _createBloc(BuildContext context) {
    return BulkUploadBloc(
      fileParserService: context.read<FileParserService>(),
      validationService: context.read<EmployeeValidationService>(),
      usersRepo: context.read<UsersRepo>(),
      authRepo: context.read<AuthRepo>(),
    );
  }
}

class _BulkUploadView extends StatefulWidget {
  const _BulkUploadView();

  @override
  State<_BulkUploadView> createState() => _BulkUploadViewState();
}

class _BulkUploadViewState extends State<_BulkUploadView> {
  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: AppLocalizations.of(context)!.bulkEmployeeUpload,
      child: Scaffold(
        body: BlocConsumer<BulkUploadBloc, BulkUploadState>(
          listener: _handleStateChange,
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInstructions(context),
                  const SizedBox(height: 24),
                  _buildActionButtons(context, state),
                  if (state.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorMessage(context, state.errorMessage!),
                  ],
                  if (state.status == BulkUploadStatus.parsing || state.status == BulkUploadStatus.validating) ...[
                    const SizedBox(height: 24),
                    _buildLoadingIndicator(context, state),
                  ],
                  if (state.rows.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSummary(context, state),
                    const SizedBox(height: 16),
                    _buildReviewTable(context, state),
                    const SizedBox(height: 24),
                    _buildSubmitSection(context, state),
                  ],
                  if (state.status == BulkUploadStatus.success || state.status == BulkUploadStatus.partialSuccess) ...[
                    const SizedBox(height: 24),
                    _buildResultSummary(context, state),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleStateChange(BuildContext context, BulkUploadState state) {
    if (state.status == BulkUploadStatus.success) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.employeesAddedSuccessfully(state.successCount))),
        );
    }
  }

  Widget _buildInstructions(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.instructions,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInstructionStep(context, 1, AppLocalizations.of(context)!.downloadTemplateInstruction),
            _buildInstructionStep(context, 2, AppLocalizations.of(context)!.fillEmployeeDataInstruction),
            _buildInstructionStep(context, 3, AppLocalizations.of(context)!.uploadFileInstruction),
            _buildInstructionStep(context, 4, AppLocalizations.of(context)!.reviewAndFixErrorsInstruction),
            _buildInstructionStep(context, 5, AppLocalizations.of(context)!.submitToAddEmployeesInstruction),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionStep(BuildContext context, int step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
            child: Center(
              child: Text(
                step.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, BulkUploadState state) {
    final isProcessing =
        state.status == BulkUploadStatus.parsing ||
        state.status == BulkUploadStatus.validating ||
        state.status == BulkUploadStatus.uploading;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        AppButton(
          label: AppLocalizations.of(context)!.downloadExcelTemplate,
          onPressed: isProcessing ? null : () => _downloadExcelTemplate(context),
        ),
        AppButton(
          label: AppLocalizations.of(context)!.uploadFile,
          onPressed: isProcessing ? null : () => _pickFile(context),
        ),
        if (state.rows.isNotEmpty)
          AppButton(
            label: AppLocalizations.of(context)!.clearAll,
            color: Colors.orange,
            onPressed: isProcessing ? null : () => context.read<BulkUploadBloc>().add(const ResetBulkUpload()),
          ),
      ],
    );
  }

  Widget _buildErrorMessage(BuildContext context, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        border: Border.all(color: Colors.red[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: Colors.red[700]))),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(BuildContext context, BulkUploadState state) {
    String message =
        state.status == BulkUploadStatus.parsing
            ? AppLocalizations.of(context)!.parsingFile
            : AppLocalizations.of(context)!.validatingData;

    return Center(
      child: Column(children: [const CircularProgressIndicator(), const SizedBox(height: 16), Text(message)]),
    );
  }

  Widget _buildSummary(BuildContext context, BulkUploadState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _buildSummaryItem(
              context,
              AppLocalizations.of(context)!.totalEmployees,
              state.rows.length.toString(),
              Colors.blue,
            ),
            const SizedBox(width: 24),
            _buildSummaryItem(context, AppLocalizations.of(context)!.valid, state.validCount.toString(), Colors.green),
            const SizedBox(width: 24),
            _buildSummaryItem(
              context,
              AppLocalizations.of(context)!.withErrors,
              state.invalidCount.toString(),
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildReviewTable(BuildContext context, BulkUploadState state) {
    return BulkUploadReviewTable(
      rows: state.rows,
      onFieldChanged: (rowIndex, field, value) {
        context.read<BulkUploadBloc>().add(UpdateRowField(rowIndex: rowIndex, field: field, value: value));
      },
      onRevalidate: () {
        context.read<BulkUploadBloc>().add(const RevalidateRows());
      },
      onRemoveRow: (rowIndex) {
        context.read<BulkUploadBloc>().add(RemoveRow(rowIndex));
      },
    );
  }

  Widget _buildSubmitSection(BuildContext context, BulkUploadState state) {
    final isUploading = state.status == BulkUploadStatus.uploading;
    final canSubmit = state.allValid && !isUploading;

    return SizedBox(
      width: double.infinity,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isUploading) ...[
                LinearProgressIndicator(value: state.progressPercentage),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.uploadingProgress(state.processedCount, state.rows.length)),
                const SizedBox(height: 16),
              ],
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: 800,
                  child: Row(
                    children: [
                      AppButton(
                        label:
                            isUploading
                                ? AppLocalizations.of(context)!.uploading
                                : canSubmit
                                ? AppLocalizations.of(context)!.submitEmployees(state.validCount)
                                : AppLocalizations.of(context)!.submit,
                        onPressed: canSubmit ? () => _showSubmitConfirmation(context, state) : null,
                        color: canSubmit ? Colors.blue : Colors.grey,
                      ),
                      if (!state.allValid && state.validCount > 0) ...[
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.fixErrorsToSubmit,
                          style: TextStyle(color: Colors.orange[700]),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultSummary(BuildContext context, BulkUploadState state) {
    final isSuccess = state.status == BulkUploadStatus.success;
    final color = isSuccess ? Colors.green : Colors.orange;

    return Card(
      color: isSuccess ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(isSuccess ? Icons.check_circle : Icons.warning, color: color, size: 32),
                const SizedBox(width: 12),
                Text(
                  isSuccess
                      ? AppLocalizations.of(context)!.uploadComplete
                      : AppLocalizations.of(context)!.partialUploadComplete,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildSummaryItem(
                  context,
                  AppLocalizations.of(context)!.succeeded,
                  state.successCount.toString(),
                  Colors.green,
                ),
                const SizedBox(width: 24),
                _buildSummaryItem(
                  context,
                  AppLocalizations.of(context)!.failed,
                  state.failedCount.toString(),
                  Colors.red,
                ),
              ],
            ),
            if (state.failedEmployees.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(AppLocalizations.of(context)!.failedEmployeesList, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...state.failedEmployees.entries.map((entry) {
                final row = state.rows.firstWhere((r) => r.rowIndex == entry.key, orElse: () => state.rows.first);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Text('${row.employeeCode ?? 'Unknown'}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(entry.value, style: TextStyle(color: Colors.red[700]))),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              AppButton(
                label: AppLocalizations.of(context)!.retryFailed,
                onPressed: () => context.read<BulkUploadBloc>().add(const RetryFailedEmployees()),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSubmitConfirmation(BuildContext context, BulkUploadState state) {
    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.confirmUpload),
            content: Text(AppLocalizations.of(context)!.confirmUploadMessage(state.validCount)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<BulkUploadBloc>().add(const SubmitBulkUpload());
                },
                child: Text(AppLocalizations.of(context)!.confirm),
              ),
            ],
          ),
    );
  }

  Future<void> _downloadExcelTemplate(BuildContext context) async {
    try {
      final service = FileParserService();
      final bytes = service.generateExcelTemplate();

      // Use file picker to let user choose save location
      final result = await FilePicker.saveFile(
        dialogTitle: 'Save Excel Template',
        fileName: 'employee_upload_template.xlsx',
        type: FileType.custom,
        allowedExtensions: ['xlsx'],
        bytes: Uint8List.fromList(bytes),
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.templateSavedTo(result))));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true, // Required for web platform to get file bytes
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // For web platform, path is a blob URL, so we need to use file.name for extension
        // and file.bytes for content
        if (file.bytes != null) {
          // Web platform or any platform where we have bytes
          if (mounted) {
            context.read<BulkUploadBloc>().add(UploadFileWithBytes(fileName: file.name, bytes: file.bytes!));
          }
        } else if (file.path != null) {
          // Desktop platforms with file path
          if (mounted) {
            context.read<BulkUploadBloc>().add(UploadFile(file.path!));
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Could not access file. Please try again.')));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      }
    }
  }
}
