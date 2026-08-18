import 'package:hrms_demo/core/constants/employee_type_selection.dart';
import 'package:hrms_demo/core/constants/request_constants.dart';
import 'package:hrms_demo/core/constants/violation_category.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/display_name_utils.dart';
import 'package:hrms_demo/core/utils/navigation_helper.dart';
import 'package:hrms_demo/data/models/disciplinary_action_request_model.dart';
import 'package:hrms_demo/data/models/investigation_request_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/disciplinary_action/widgets/disciplinary_action_page.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/custom_date_picker.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:hrms_demo/presentation/shared/employee_search_field.dart';
import 'package:hrms_demo/presentation/shared/selected_employee_section.dart';
import 'package:hrms_demo/presentation/shared/form_styling.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hrms_demo/presentation/disciplinary_action/bloc/disciplinary_action_bloc.dart';
import 'package:hrms_demo/presentation/disciplinary_action/bloc/disciplinary_action_event.dart';
import 'package:hrms_demo/presentation/disciplinary_action/bloc/disciplinary_action_state.dart';

class DisciplinaryActionContent extends StatefulWidget {
  const DisciplinaryActionContent({super.key});

  @override
  State<DisciplinaryActionContent> createState() => _DisciplinaryActionContentState();
}

class _DisciplinaryActionContentState extends State<DisciplinaryActionContent> {
  final TextEditingController _employeeSearchController = TextEditingController();
  final TextEditingController _incidentController = TextEditingController();
  final TextEditingController _customViolationController = TextEditingController();
  final FocusNode _employeeSearchFocusNode = FocusNode();

  String _formatDeductDaysForDisplay(BuildContext context, double days) {
    final l10n = AppLocalizations.of(context)!;
    if (days == 0.25) return l10n.quarterDay;
    if (days == 0.5) return l10n.halfDay;
    if (days == 1.0) return '1 ${l10n.day}';
    return '${days.toInt()} ${l10n.days}';
  }

  String _getViolationDisplayName(BuildContext context, DisciplinaryActionFormState state) {
    if (state.violationCategory == null || state.selectedViolation == null) {
      return '';
    }

    // For "Other" category, return the custom text directly
    if (state.violationCategory!.isOther) {
      return state.selectedViolation!;
    }

    // For predefined categories, find the violation and return localized name
    final violation = ViolationData.findViolationByKey(state.selectedViolation!);
    return violation?.getLocalizedName(context) ?? state.selectedViolation!;
  }

  Future<void> _pickAttachments(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final currentState = context.read<DisciplinaryActionBloc>().state;

    if (currentState is DisciplinaryActionFormState) {
      // Check if max files reached
      if (currentState.attachmentFileNames.length >= 5) {
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
          // Check file size (10MB limit)
          if (file.size > 10 * 1024 * 1024) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${file.name}: ${l10n.fileTooLarge}')));
            }
            continue;
          }

          // Check total files limit
          if (currentState.attachmentFileNames.length + newFiles.length >= 5) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.maxFilesReached)));
            }
            break;
          }

          // Check for duplicate filenames
          if (currentState.attachmentFileNames.contains(file.name) || newFileNames.contains(file.name)) {
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
          final updatedFiles = [...currentState.attachmentFiles, ...newFiles];
          final updatedNames = [...currentState.attachmentFileNames, ...newFileNames];

          context.read<DisciplinaryActionBloc>().add(UpdateAttachments(updatedFiles, updatedNames));
        }
      }
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<DisciplinaryActionBloc>().add(InitializeDisciplinaryActionForm());
  }

  @override
  void dispose() {
    _employeeSearchController.dispose();
    _incidentController.dispose();
    _customViolationController.dispose();
    _employeeSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Align(
        alignment: Alignment.topLeft,
        child: SingleChildScrollView(
          child: BlocListener<DisciplinaryActionBloc, DisciplinaryActionState>(
            listenWhen: (previous, current) {
              // Only listen when isSubmissionSuccessful changes from false to true
              if (previous is DisciplinaryActionFormState && current is DisciplinaryActionFormState) {
                return !previous.isSubmissionSuccessful && current.isSubmissionSuccessful;
              }
              return false;
            },
            listener: (context, state) {
              if (state is DisciplinaryActionFormState) {
                if (state.isSubmissionSuccessful) {
                  final userBloc = context.read<UserBloc>();
                  final userId = userBloc.state.user?.id.toString();

                  userBloc.add(MarkRequestsAvailable(hasDisciplinaryRequests: true));
                  if (userId != null) {
                    userBloc.add(LoadUserProfile(userId));
                  }

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.requestSubmittedSuccessfully)));

                  NavigationHelper.pushReplacementWithSidebarSync(
                    context,
                    routeName: '/disciplinary/new',
                    page: const DisciplinaryActionPage(),
                  );
                }

                if (state.submissionError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.submissionError!)));
                }
              }
            },
            child: BlocBuilder<DisciplinaryActionBloc, DisciplinaryActionState>(
              builder: (context, state) {
                if (state is DisciplinaryActionLoading) {
                  return const SizedBox(height: 250, child: Center(child: CircularProgressIndicator()));
                }

                if (state is DisciplinaryActionError) {
                  return Center(
                    child: Text(
                      '${AppLocalizations.of(context)!.errorPrefix}: ${state.message}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                if (state is DisciplinaryActionFormState) {
                  return _buildForm(context, state);
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context, DisciplinaryActionFormState state) {
    final isInvestigationMode = state.formMode == DisciplinaryFormMode.investigation;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: context.screenWidth < 600 ? 600 : context.screenWidth - 65,
        child: FormContainer(
          header: FormHeader(
            icon: isInvestigationMode ? Icons.content_paste_search : Icons.gavel_outlined,
            title:
                isInvestigationMode
                    ? AppLocalizations.of(context)!.investigation
                    : AppLocalizations.of(context)!.disciplinaryActionRequest,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Mode Segment Button
              _buildModeSegmentButton(context, state),

              // Employee Selection - using shared EmployeeSearchField for both modes
              EmployeeSearchField(
                searchController: _employeeSearchController,
                searchFocusNode: _employeeSearchFocusNode,
                isSearching: state.isSearching,
                isLoadingAllEmployees: state.isLoadingAllEmployees,
                searchResults: state.employeeSearchResults,
                allManagedEmployees: _getAllEmployeesForCurrentType(state),
                validationErrors: _getLocalizedValidationErrors(context, state.validationErrors),
                validationKey: isInvestigationMode ? 'employees' : 'employee',
                employeeType: state.employeeType,
                onEmployeeTypeToggle: (employeeType) {
                  _employeeSearchController.clear();
                  _incidentController.clear();
                  _customViolationController.clear();
                  context.read<DisciplinaryActionBloc>().add(ToggleEmployeeType(employeeType));
                },
                onSearchChanged: (value) {
                  if (value.trim().isNotEmpty) {
                    context.read<DisciplinaryActionBloc>().add(SearchEmployees(value.trim()));
                  } else {
                    context.read<DisciplinaryActionBloc>().add(ClearSearchResults());
                  }
                },
                onClearSearch: () {
                  _employeeSearchController.clear();
                  context.read<DisciplinaryActionBloc>().add(ClearSearchResults());
                },
                onEmployeeSelected: (employee) {
                  context.read<DisciplinaryActionBloc>().add(SelectEmployee(employee));
                },
                // Multi-select parameters for investigation mode
                multiSelect: isInvestigationMode,
                selectedEmployees: state.selectedEmployees,
                onEmployeeAdded: (employee) {
                  context.read<DisciplinaryActionBloc>().add(AddEmployeeToSelection(employee));
                  _employeeSearchController.clear();
                  context.read<DisciplinaryActionBloc>().add(ClearSearchResults());
                },
                onEmployeeRemoved: (employee) {
                  context.read<DisciplinaryActionBloc>().add(RemoveEmployeeFromSelection(employee));
                },
                onClearAllEmployees: () {
                  context.read<DisciplinaryActionBloc>().add(ClearSelectedEmployees());
                },
              ),

              const SizedBox(height: 16),

              // Selected Employee(s) Section - using shared SelectedEmployeeSection
              if (isInvestigationMode && state.selectedEmployees.isNotEmpty) ...[
                SelectedEmployeeSection.multiSelect(
                  employees: state.selectedEmployees,
                  onRemoveEmployee: (employee) {
                    context.read<DisciplinaryActionBloc>().add(RemoveEmployeeFromSelection(employee));
                  },
                  onClearAll: () {
                    context.read<DisciplinaryActionBloc>().add(ClearSelectedEmployees());
                  },
                ),
                const SizedBox(height: 16),
              ] else if (!isInvestigationMode && state.selectedEmployee != null) ...[
                SelectedEmployeeSection(
                  employee: state.selectedEmployee!,
                  onClear: () {
                    _employeeSearchController.clear();
                    _incidentController.clear();
                    context.read<DisciplinaryActionBloc>().add(ResetForm());
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Show form fields only if employee(s) selected
              if (_hasEmployeeSelected(state, isInvestigationMode)) ...[
                // Employee Warning History Alert (only for disciplinary mode with single employee)
                if (!isInvestigationMode && state.shouldShowTerminationWarning) ...[
                  _buildTerminationWarningAlert(context, state),
                  const SizedBox(height: 16),
                ],

                // Violation Category
                _buildViolationCategoryField(context, state),
                const SizedBox(height: 16),

                // Violation (dropdown or text field based on category)
                _buildViolationField(context, state),
                const SizedBox(height: 16),

                // Violation Date
                _buildViolationDateField(context, state),
                const SizedBox(height: 16),
                // Disciplinary Action Type - ONLY for disciplinary mode
                if (!isInvestigationMode) ...[_buildActionTypeField(context, state), const SizedBox(height: 16)],

                // Incident Description
                _buildIncidentDescriptionField(context, state),
                const SizedBox(height: 16),

                // Attach Documents
                _buildAttachmentsField(context, state),
                const SizedBox(height: 16),

                // Written Warning Options (only for disciplinary mode with written warning selected)
                if (!isInvestigationMode && state.actionType == DisciplinaryActionType.writtenWarning) ...[
                  _buildWrittenWarningOptions(context, state),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 8),

                // Action Buttons
                SizedBox(
                  width: context.screenWidth < 600 ? context.screenWidth - 81 : context.screenWidth - 65,
                  child: _buildActionButtons(context, state),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTerminationWarningAlert(BuildContext context, DisciplinaryActionFormState state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.terminationWarning,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700]),
                ),
                Text(
                  AppLocalizations.of(context)!.employeeTerminationWarningMessage(state.currentWarningsCount),
                  style: TextStyle(color: Colors.red[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViolationCategoryField(BuildContext context, DisciplinaryActionFormState state) {
    final hasError = state.validationErrors.containsKey('violationCategory');
    return FormFieldWithLabel(
      label: AppLocalizations.of(context)!.violationCategory,
      required: true,
      errorMessage: _getLocalizedErrorMessage(context, state.validationErrors['violationCategory']),
      field: DropdownButtonFormField2<ViolationCategory>(
        valueListenable: ValueNotifier(state.violationCategory),
        dropdownStyleData: DropdownStyleData(decoration: BoxDecoration(borderRadius: BorderRadius.circular(8))),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
              width: hasError ? 2 : 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
              width: hasError ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: hasError ? Colors.red : Theme.of(context).primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        hint: Text(
          AppLocalizations.of(context)!.selectViolationCategory,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        items:
            ViolationCategory.values.map((category) {
              return DropdownItem(
                value: category,
                child: Text(category.getLocalizedName(context), style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
        onChanged: (value) {
          // Clear custom violation text when category changes
          _customViolationController.clear();
          context.read<DisciplinaryActionBloc>().add(UpdateViolationCategory(value));
        },
      ),
    );
  }

  Widget _buildViolationField(BuildContext context, DisciplinaryActionFormState state) {
    final hasError = state.validationErrors.containsKey('selectedViolation');
    final l10n = AppLocalizations.of(context)!;

    // If no category selected, show disabled dropdown
    if (state.violationCategory == null) {
      return FormFieldWithLabel(
        label: l10n.violation,
        required: true,
        field: DropdownButtonFormField2<String>(
          dropdownStyleData: DropdownStyleData(decoration: BoxDecoration(borderRadius: BorderRadius.circular(8))),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          hint: Text(l10n.selectCategoryFirst, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          items: const [],
          onChanged: null,
        ),
      );
    }

    // If "Other" category is selected, show text field
    if (state.violationCategory!.isOther) {
      return FormFieldWithLabel(
        label: l10n.violationDescription,
        required: true,
        errorMessage: _getLocalizedErrorMessage(context, state.validationErrors['selectedViolation']),
        field: StyledTextField(
          controller: _customViolationController,
          maxLines: 2,
          hasError: hasError,
          hintText: l10n.describeViolation,
          onChanged: (value) {
            context.read<DisciplinaryActionBloc>().add(UpdateSelectedViolation(value));
          },
        ),
      );
    }

    // For other categories, show dropdown with violations
    final violations = ViolationData.getViolationsForCategory(state.violationCategory!);
    return FormFieldWithLabel(
      label: l10n.violation,
      required: true,
      errorMessage: _getLocalizedErrorMessage(context, state.validationErrors['selectedViolation']),
      field: DropdownButtonFormField2<String>(
        valueListenable: ValueNotifier(state.selectedViolation),
        dropdownStyleData: DropdownStyleData(decoration: BoxDecoration(borderRadius: BorderRadius.circular(8))),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
              width: hasError ? 2 : 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
              width: hasError ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: hasError ? Colors.red : Theme.of(context).primaryColor, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        hint: Text(l10n.selectViolation, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        items:
            violations.map((violation) {
              return DropdownItem(
                value: violation.key,
                child: Text(violation.getLocalizedName(context), style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
        onChanged: (value) {
          context.read<DisciplinaryActionBloc>().add(UpdateSelectedViolation(value));
        },
      ),
    );
  }

  Widget _buildActionTypeField(BuildContext context, DisciplinaryActionFormState state) {
    final hasError = state.validationErrors.containsKey('actionType');
    return FormFieldWithLabel(
      label: AppLocalizations.of(context)!.actionType,
      required: true,
      errorMessage: _getLocalizedErrorMessage(context, state.validationErrors['actionType']),
      field: DropdownButtonFormField2<DisciplinaryActionType>(
        valueListenable: ValueNotifier(state.actionType),
        dropdownStyleData: DropdownStyleData(decoration: BoxDecoration(borderRadius: BorderRadius.circular(8))),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
              width: hasError ? 2 : 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
              width: hasError ? 2 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: hasError ? Colors.red : Theme.of(context).primaryColor, width: 2),
          ),

          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        hint: Text(
          AppLocalizations.of(context)!.selectActionType,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        items:
            DisciplinaryActionType.values.where((type) => type != DisciplinaryActionType.hrInvestigation).map((type) {
              return DropdownItem(
                value: type,
                child: Text(type.getLocalizedName(context), style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
        onChanged: (value) {
          if (value != null) {
            context.read<DisciplinaryActionBloc>().add(UpdateActionType(value));
          }
        },
      ),
    );
  }

  Widget _buildIncidentDescriptionField(BuildContext context, DisciplinaryActionFormState state) {
    final hasError = state.validationErrors.containsKey('incidentDescription');
    return FormFieldWithLabel(
      label: AppLocalizations.of(context)!.incidentDescription,
      required: true,
      errorMessage: _getLocalizedErrorMessage(context, state.validationErrors['incidentDescription']),
      field: StyledTextField(
        controller: _incidentController,
        maxLines: 4,
        hasError: hasError,
        hintText: AppLocalizations.of(context)!.describeIncident,
        onChanged: (value) {
          context.read<DisciplinaryActionBloc>().add(UpdateIncidentDescription(value));
        },
      ),
    );
  }

  Widget _buildAttachmentsField(BuildContext context, DisciplinaryActionFormState state) {
    final l10n = AppLocalizations.of(context)!;
    return FormFieldWithLabel(
      label: l10n.attachDocuments,
      required: false,
      field: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: state.attachmentFileNames.length >= 5 ? null : () => _pickAttachments(context),
                icon: const Icon(Icons.attach_file, size: 18),
                label: Text(l10n.uploadDocuments),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              ),
              if (state.attachmentFileNames.isNotEmpty) ...[
                const SizedBox(width: 12),
                Text(
                  l10n.documentsAttached(state.attachmentFileNames.length),
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(l10n.supportedFormats, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          if (state.attachmentFileNames.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...state.attachmentFileNames.asMap().entries.map((entry) {
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
                      onPressed: () {
                        context.read<DisciplinaryActionBloc>().add(RemoveAttachment(index));
                      },
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
      ),
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

  Widget _buildViolationDateField(BuildContext context, DisciplinaryActionFormState state) {
    final hasError = state.validationErrors.containsKey('violationDate');
    return FormFieldWithLabel(
      label: AppLocalizations.of(context)!.violationDate,
      required: true,
      errorMessage: _getLocalizedErrorMessage(context, state.validationErrors['violationDate']),
      field: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: StyledTextField(
          mouseCursor: SystemMouseCursors.click,
          readOnly: true,
          hintText: AppLocalizations.of(context)!.selectDate,
          hasError: hasError,
          controller: TextEditingController(
            text: state.violationDate != null ? DateFormat('yyyy-MM-dd').format(state.violationDate!) : '',
          ),
          onTap: () async {
            final selectedDate = await showCustomDatePicker(
              context: context,
              initialDate: state.violationDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: kRequestBackWindowDays)),
              lastDate: DateTime.now(),
            );
            if (selectedDate != null && context.mounted) {
              context.read<DisciplinaryActionBloc>().add(UpdateViolationDate(selectedDate));
            }
          },
        ),
      ),
    );
  }

  Widget _buildWrittenWarningOptions(BuildContext context, DisciplinaryActionFormState state) {
    final l10n = AppLocalizations.of(context)!;

    // Dropdown options for deduct days
    final deductDaysOptions = [
      (label: l10n.quarterDay, value: 0.25),
      (label: l10n.halfDay, value: 0.5),
      (label: '1 ${l10n.day}', value: 1.0),
      (label: '2 ${l10n.days}', value: 2.0),
      (label: '3 ${l10n.days}', value: 3.0),
      (label: '4 ${l10n.days}', value: 4.0),
      (label: '5 ${l10n.days}', value: 5.0),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormFieldLabel(text: l10n.writtenWarningOptions, required: false),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField2<double>(
                valueListenable: ValueNotifier(state.deductDays),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1),
                  ),
                  labelStyle: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  errorText: _getLocalizedErrorMessage(context, state.validationErrors['deductDays']),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 1),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                hint: Text(l10n.selectDeductDays, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                items:
                    deductDaysOptions
                        .map(
                          (opt) => DropdownItem<double>(
                            value: opt.value,
                            child: Text(opt.label, style: const TextStyle(fontSize: 14)),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  context.read<DisciplinaryActionBloc>().add(UpdateDeductDays(value));
                },
                dropdownStyleData: DropdownStyleData(decoration: BoxDecoration(borderRadius: BorderRadius.circular(8))),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, DisciplinaryActionFormState state) {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            onPressed:
                state.isSubmitting
                    ? null
                    : state.isFormValid
                    ? () => _submitRequest(context, state)
                    : () {
                      // Trigger validation to show errors
                      context.read<DisciplinaryActionBloc>().add(ValidateForm());
                    },
            label: state.isSubmitting ? AppLocalizations.of(context)!.submitting : AppLocalizations.of(context)!.submit,
          ),
        ),
      ],
    );
  }

  void _submitRequest(BuildContext context, DisciplinaryActionFormState state) async {
    // Validate form before submission
    context.read<DisciplinaryActionBloc>().add(ValidateForm());

    if (!state.isFormValid) {
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(context, state);
    if (confirmed != true || !context.mounted) return;

    final userBloc = context.read<UserBloc>();
    final currentUser = userBloc.state.user;

    if (currentUser?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.errorOccurred)));
      return;
    }

    final bloc = context.read<DisciplinaryActionBloc>();

    // Check form mode and submit accordingly
    if (state.formMode == DisciplinaryFormMode.investigation) {
      // Investigation submission
      final investigationRequest = InvestigationRequestModel(
        requestorCode: currentUser!.id,
        employeeCodes: state.selectedEmployees.map((e) => e.id!).toList(),
        incidentDescription: state.incidentDescription!,
        violationDate: state.violationDate!,
        violationCategory: state.violationCategory!.value,
        violation: state.selectedViolation!,
        status: 'pending',
        currentApprover: 'hr',
      );

      bloc.add(SubmitInvestigationRequest(investigationRequest));
    } else {
      // Disciplinary action submission (existing logic)
      final request = DisciplinaryActionRequestModel(
        requestorCode: currentUser!.id, // Requestor is the employee's N+1 or N+2
        employeeCode: state.selectedEmployee!.id,
        n2Code: state.selectedEmployee!.n2, // Employee's N+2
        violationCategory: state.violationCategory!.value,
        violation: state.selectedViolation!,
        actionType: state.actionType!,
        incidentDescription: state.incidentDescription!,
        violationDate: state.violationDate!,
        writtenWarningOptions:
            state.actionType == DisciplinaryActionType.writtenWarning
                ? WrittenWarningOptions(deductDays: state.deductDays)
                : null,
        status: 'pending',
      );

      bloc.add(SubmitDisciplinaryActionRequest(request));
    }
  }

  Future<bool?> _showConfirmationDialog(BuildContext context, DisciplinaryActionFormState state) {
    final isInvestigationMode = state.formMode == DisciplinaryFormMode.investigation;

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.confirmSubmitRequest),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.areYouSureToSubmitDisciplinaryRequest,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                // Show employee name(s) based on mode
                if (isInvestigationMode) ...[
                  _buildConfirmationDetailRow(
                    context,
                    label: AppLocalizations.of(context)!.employees,
                    value: '${state.selectedEmployees.length} ${AppLocalizations.of(context)!.employees}',
                    icon: Icons.people,
                  ),
                ] else ...[
                  _buildConfirmationDetailRow(
                    context,
                    label: AppLocalizations.of(context)!.name,
                    value: DisplayNameUtils.getDisplayName(
                      context,
                      state.selectedEmployee!.englishName,
                      state.selectedEmployee!.arabicName,
                    ),
                    icon: Icons.person,
                  ),
                ],
                const SizedBox(height: 12),
                _buildConfirmationDetailRow(
                  context,
                  label: AppLocalizations.of(context)!.violationCategory,
                  value: state.violationCategory!.getLocalizedName(context),
                  icon: Icons.category,
                ),
                const SizedBox(height: 12),
                _buildConfirmationDetailRow(
                  context,
                  label: AppLocalizations.of(context)!.violation,
                  value: _getViolationDisplayName(context, state),
                  icon: Icons.report_problem,
                ),
                // Only show action type in disciplinary action mode
                if (!isInvestigationMode) ...[
                  const SizedBox(height: 12),
                  _buildConfirmationDetailRow(
                    context,
                    label: AppLocalizations.of(context)!.actionType,
                    value: state.actionType!.getLocalizedName(context),
                    icon: Icons.gavel,
                  ),
                ],
                const SizedBox(height: 12),
                _buildConfirmationDetailRow(
                  context,
                  label: AppLocalizations.of(context)!.violationDate,
                  value: DateFormat('yyyy-MM-dd').format(state.violationDate!),
                  icon: Icons.calendar_today,
                ),
                const SizedBox(height: 12),
                _buildConfirmationDetailRow(
                  context,
                  label: AppLocalizations.of(context)!.incidentDescription,
                  value: state.incidentDescription!,
                  icon: Icons.description,
                ),
                if (!isInvestigationMode &&
                    state.actionType == DisciplinaryActionType.writtenWarning &&
                    state.deductDays != null) ...[
                  const SizedBox(height: 12),
                  _buildConfirmationDetailRow(
                    context,
                    label: AppLocalizations.of(context)!.deductDays,
                    value: _formatDeductDaysForDisplay(context, state.deductDays!),
                    icon: Icons.event_busy,
                  ),
                ],
                if (state.attachmentFiles.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildConfirmationDetailRow(
                    context,
                    label: AppLocalizations.of(context)!.attachments,
                    value: AppLocalizations.of(context)!.documentsAttached(state.attachmentFiles.length),
                    icon: Icons.attach_file,
                  ),
                ],
                const SizedBox(height: 8),
                const Divider(),
              ],
            ),
          ),
          actions: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 300),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      label: AppLocalizations.of(context)!.cancel,
                      color: Colors.red,
                      width: 120,
                    ),
                    const SizedBox(width: 16),
                    AppButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      label: AppLocalizations.of(context)!.submit,
                      width: 120,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConfirmationDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, String> _getLocalizedErrorMessages(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return {
      'pleaseSelectEmployee': l10n.pleaseSelectEmployee,
      'pleaseSelectAtLeastOneEmployee': l10n.pleaseSelectAtLeastOneEmployee,
      'pleaseSelectViolationCategory': l10n.pleaseSelectViolationCategory,
      'pleaseSelectViolation': l10n.pleaseSelectViolation,
      'pleaseDescribeViolation': l10n.pleaseDescribeViolation,
      'violationDescriptionTooShort': l10n.violationDescriptionTooShort,
      'pleaseSelectActionType': l10n.pleaseSelectActionType,
      'pleaseProvideIncidentDetails': l10n.pleaseProvideIncidentDetails,
      'incidentDescriptionTooShort': l10n.incidentDescriptionTooShort,
      'pleaseSelectViolationDate': l10n.pleaseSelectViolationDate,
      'violationDateFuture': l10n.violationDateFuture,
      'violationDateTooOld': l10n.violationDateTooOld,
      'deductDaysRange': l10n.deductDaysRange,
    };
  }

  String? _getLocalizedErrorMessage(BuildContext context, String? errorKey) {
    if (errorKey == null) return null;

    final messages = _getLocalizedErrorMessages(context);
    return messages[errorKey];
  }

  Map<String, String> _getLocalizedValidationErrors(BuildContext context, Map<String, String> errorKeys) {
    final localizedErrors = <String, String>{};
    final messages = _getLocalizedErrorMessages(context);

    for (final entry in errorKeys.entries) {
      final localizedMessage = messages[entry.value];
      if (localizedMessage != null) {
        localizedErrors[entry.key] = localizedMessage;
      }
    }

    return localizedErrors;
  }

  List<UserModel> _getAllEmployeesForCurrentType(DisciplinaryActionFormState state) {
    switch (state.employeeType) {
      case EmployeeTypeSelection.direct:
        return state.allManagedEmployees;
      case EmployeeTypeSelection.indirect:
        return state.allIndirectEmployees;
      case EmployeeTypeSelection.allSubordinates:
        return state.allDeepSubordinates;
    }
  }

  bool _hasEmployeeSelected(DisciplinaryActionFormState state, bool isInvestigationMode) {
    if (isInvestigationMode) {
      return state.selectedEmployees.isNotEmpty;
    } else {
      return state.selectedEmployee != null;
    }
  }

  Widget _buildModeSegmentButton(BuildContext context, DisciplinaryActionFormState state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: SegmentedButton<DisciplinaryFormMode>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment<DisciplinaryFormMode>(
            value: DisciplinaryFormMode.disciplinaryAction,
            label: Text(AppLocalizations.of(context)!.disciplinaryAction),
            icon: const Icon(Icons.gavel),
          ),
          ButtonSegment<DisciplinaryFormMode>(
            value: DisciplinaryFormMode.investigation,
            label: Text(AppLocalizations.of(context)!.investigation),
            icon: const Icon(Icons.content_paste_search),
          ),
        ],
        selected: {state.formMode},
        onSelectionChanged: (Set<DisciplinaryFormMode> selection) {
          _employeeSearchController.clear();
          _incidentController.clear();
          _customViolationController.clear();
          context.read<DisciplinaryActionBloc>().add(SwitchFormMode(selection.first));
        },
      ),
    );
  }
}
