import 'package:hrms_demo/core/constants/leave_type.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/hr_tools/bloc/hr_tools_bloc.dart';
import 'package:hrms_demo/presentation/hr_tools/bloc/hr_tools_event.dart';
import 'package:hrms_demo/presentation/hr_tools/bloc/hr_tools_state.dart';
import 'package:hrms_demo/presentation/shared/form_styling.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/custom_date_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class BulkLeaveTab extends StatefulWidget {
  const BulkLeaveTab({super.key});

  @override
  State<BulkLeaveTab> createState() => _BulkLeaveTabState();
}

class _BulkLeaveTabState extends State<BulkLeaveTab> {
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _leaveTypeController = TextEditingController();

  @override
  void dispose() {
    _fromDateController.dispose();
    _toDateController.dispose();
    _leaveTypeController.dispose();
    super.dispose();
  }

  Future<void> _pickFromDate(BuildContext context, HrToolsState state) async {
    final picked = await showCustomDatePicker(
      context: context,
      initialDate: state.dateFrom ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && context.mounted) {
      _fromDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      context.read<HrToolsBloc>().add(HrToolsLeaveDateFromChanged(picked));
    }
  }

  Future<void> _pickToDate(BuildContext context, HrToolsState state) async {
    final firstDate = state.dateFrom ?? DateTime.now();
    final picked = await showCustomDatePicker(
      context: context,
      initialDate: state.dateTo ?? firstDate,
      firstDate: firstDate,
      lastDate: DateTime(2100),
    );
    if (picked != null && context.mounted) {
      _toDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      context.read<HrToolsBloc>().add(HrToolsLeaveDateToChanged(picked));
    }
  }

  /// Mirrors the employee form's picker (request_leave_content.dart:187-212):
  /// multiple files, any type, `withData: true` because the app runs on web and
  /// the bytes are what get uploaded.
  Future<void> _pickSickNotes(BuildContext context) async {
    final result = await FilePicker.pickFiles(allowMultiple: true, withData: true);
    if (result == null || result.files.isEmpty || !context.mounted) return;

    final files = result.files.where((f) => f.bytes != null).map((f) => f.bytes!).toList();
    final names = result.files.where((f) => f.bytes != null).map((f) => f.name).toList();
    if (files.isEmpty) return;

    context.read<HrToolsBloc>().add(HrToolsSickNotesPicked(files, names));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<HrToolsBloc, HrToolsState>(
      builder: (context, state) {
        // Sync date controllers with bloc state (e.g. after form reset)
        if (state.dateFrom == null) _fromDateController.clear();
        if (state.dateTo == null) _toDateController.clear();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Approval mode — auto-approve (default) vs. the normal N+1 cycle
            FormFieldWithLabel(
              label: l10n.approvalMode,
              field: SegmentedButton<bool>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment<bool>(
                    value: true,
                    label: Text(l10n.autoApproveMode),
                    icon: const Icon(Icons.flash_on_outlined, size: 16),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label: Text(l10n.normalApprovalCycleMode),
                    icon: const Icon(Icons.alt_route_outlined, size: 16),
                  ),
                ],
                selected: {state.autoApprove},
                onSelectionChanged:
                    state.isSubmitting
                        ? null
                        : (selection) =>
                            context.read<HrToolsBloc>().add(HrToolsApprovalModeChanged(selection.first)),
              ),
            ),
            const SizedBox(height: 16),

            // Info note — reflects the selected mode
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.autoApprove ? l10n.bulkLeaveNote : l10n.bulkLeaveApprovalCycleNote,
                      style: TextStyle(fontSize: 13, color: Theme.of(context).primaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Leave Type
            FormFieldWithLabel(
              label: l10n.leaveType,
              required: true,
              errorMessage: state.validationErrors['leaveType'],
              field: _buildLeaveTypeDropdown(context, state, l10n),
            ),
            const SizedBox(height: 16),

            // From Date
            FormFieldWithLabel(
              label: l10n.from,
              required: true,
              errorMessage: state.validationErrors['dateFrom'],
              field: StyledTextField(
                controller: _fromDateController,
                hintText: l10n.selectDate,
                readOnly: true,
                mouseCursor: SystemMouseCursors.click,
                hasError: state.validationErrors.containsKey('dateFrom'),
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                onTap: () => _pickFromDate(context, state),
              ),
            ),
            const SizedBox(height: 16),

            // To Date
            FormFieldWithLabel(
              label: l10n.to,
              required: true,
              errorMessage: state.validationErrors['dateTo'],
              field: StyledTextField(
                controller: _toDateController,
                hintText: l10n.selectDate,
                readOnly: true,
                mouseCursor: SystemMouseCursors.click,
                hasError: state.validationErrors.containsKey('dateTo'),
                suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
                onTap: () => _pickToDate(context, state),
              ),
            ),

            // Medical report — only for Sick leave, and only for a single
            // employee: the report documents one person, so it is not offered
            // for a batch (state.canAttachSickNote is the shared rule).
            if (state.canAttachSickNote) ...[
              const SizedBox(height: 16),
              FormFieldWithLabel(
                label: l10n.sickNotes,
                field: _buildSickNoteField(context, state, l10n),
              ),
            ] else if (state.leaveType == LeaveType.sick.label) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.bulkSickNoteSingleEmployeeOnly,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 28),

            // Submit
            AppButton(
              label: l10n.submit,
              width: double.infinity,
              isLoading: state.isSubmitting,
              onPressed:
                  state.isSubmitting ? null : () => context.read<HrToolsBloc>().add(const HrToolsBulkLeaveSubmitted()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSickNoteField(BuildContext context, HrToolsState state, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppButton(
          label: l10n.upSicknote,
          width: double.infinity,
          onPressed: state.isSubmitting ? null : () => _pickSickNotes(context),
        ),
        for (var i = 0; i < state.sickNoteFileNames.length; i++)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(Icons.attach_file, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Expanded(child: Text(state.sickNoteFileNames[i], style: const TextStyle(fontSize: 13))),
                IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.close,
                  onPressed:
                      state.isSubmitting ? null : () => context.read<HrToolsBloc>().add(HrToolsSickNoteRemoved(i)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLeaveTypeDropdown(BuildContext context, HrToolsState state, AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: state.validationErrors.containsKey('leaveType') ? Colors.red : Colors.grey.withValues(alpha: 0.3),
          width: state.validationErrors.containsKey('leaveType') ? 2 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.leaveType,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: BorderRadius.circular(8),
          items:
              LeaveType.values.map((type) {
                return DropdownMenuItem<String>(
                  value: type.label,
                  child: Text(type.localizedLabel(context), style: const TextStyle(fontSize: 14)),
                );
              }).toList(),
          onChanged: (value) {
            if (value != null) {
              context.read<HrToolsBloc>().add(HrToolsLeaveTypeChanged(value));
            }
          },
        ),
      ),
    );
  }
}
