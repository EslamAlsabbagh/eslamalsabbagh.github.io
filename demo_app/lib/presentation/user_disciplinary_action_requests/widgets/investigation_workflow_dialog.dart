import 'dart:typed_data';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/status.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/models/investigation_request_model.dart';
import '../../../data/models/disciplinary_action_request_model.dart';
import '../bloc/user_disciplinary_action_requests_bloc.dart';
import '../bloc/user_disciplinary_action_requests_event.dart';
import '../bloc/user_disciplinary_action_requests_state.dart';
import '../../dashboard/bloc/user_bloc.dart';
import 'disciplinary_action_detail_content.dart';
import 'investigation_detail_content.dart';
import 'hr_decision_stage_content.dart';
import 'bulk_creation_stage_content.dart';
import 'tm_decision_stage_content.dart';
import 'legal_decision_stage_content.dart';

/// Unified Investigation Workflow Dialog
/// Provides smooth animated transitions between:
/// - View 0: Investigation Detail (read-only information)
/// - View 1: Decision Recording (HR/Legal/TM specific dialogs)
///
/// Uses the same AnimatedSwitcher pattern as MultiStageHrInvestigationDialog
/// for consistent, professional slide transitions throughout the app.
class InvestigationWorkflowDialog extends StatefulWidget {
  final InvestigationRequestModel investigation;
  final bool showActionButtons;
  final bool isEmployeeSubject;
  final bool isPassiveObserver;

  const InvestigationWorkflowDialog({
    super.key,
    required this.investigation,
    this.showActionButtons = false,
    this.isEmployeeSubject = false,
    this.isPassiveObserver = false,
  });

  @override
  State<InvestigationWorkflowDialog> createState() => _InvestigationWorkflowDialogState();
}

class _InvestigationWorkflowDialogState extends State<InvestigationWorkflowDialog> {
  late UserDisciplinaryActionRequestsBloc _bloc;

  // View management
  int _currentView = 0; // 0 = detail, 1 = decision recording, 2 = DA details
  bool _forwardNavigation = true; // Controls animation direction

  // DA navigation state (view 2)
  DisciplinaryActionRequestModel? _fetchedDA;
  bool _isLoadingDA = false;

  // HR Decision state (for multi-stage HR workflow)
  final _formKey = GlobalKey<FormState>();
  int _hrStage = 0; // 0 = HR Decisions, 1 = Bulk Actions
  bool _hrForwardNavigation = true; // Controls HR stage animation direction
  final Map<int, HrDecision> _employeeDecisions = {};
  final Map<int, String> _hrEmployeeComments = {};
  List<Uint8List> _hrAttachmentFiles = [];
  List<String> _hrAttachmentFileNames = [];
  List<int> _actionableEmployees = [];
  final Map<int, DisciplinaryActionType> _employeeActionTypes = {};
  final Map<int, double?> _employeeDeductDays = {};
  List<Uint8List> _bulkAttachmentFiles = [];
  List<String> _bulkAttachmentFileNames = [];
  bool _isSubmitting = false;
  bool _hrDecisionSucceeded = false; // Latch: HR decision completed, waiting for bulk creation

  // TM Decision state (for multi-stage TM workflow)
  final _tmFormKey = GlobalKey<FormState>();
  int _tmStage = 0; // 0 = TM Decisions, 1 = Bulk Actions
  bool _tmForwardNavigation = true; // Controls TM stage animation direction
  final Map<int, TopManagementDecision> _tmEmployeeDecisions = {};
  final Map<int, String> _tmEmployeeComments = {};
  List<PlatformFile>? _tmDecisionPdfs;
  List<int> _tmEscalatedEmployees = [];
  List<int> _tmActionableEmployees = []; // employees converted to disciplinary
  final Map<int, DisciplinaryActionType> _tmEmployeeActionTypes = {};
  final Map<int, double?> _tmEmployeeDeductDays = {};
  List<Uint8List> _tmBulkAttachmentFiles = [];
  List<String> _tmBulkAttachmentFileNames = [];

  // Legal Decision state
  final Map<int, String> _legalEmployeeComments = {};
  List<PlatformFile>? _legalDecisionPdfs;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bloc = context.read<UserDisciplinaryActionRequestsBloc>();
  }

  @override
  void dispose() {
    _bloc.add(const ResetAttachmentUrls());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Initialize employee decisions when entering HR decision view
    if (widget.investigation.currentApprover?.toLowerCase() == 'hr') {
      for (final code in widget.investigation.employeeCodes) {
        _employeeDecisions[code] = HrDecision.takeAction;
      }
    }

    // Initialize TM decisions when entering TM decision view
    if (widget.investigation.currentApprover?.toLowerCase() == 'top_management') {
      // Compute escalated employees (suspend/terminate from HR decisions)
      _tmEscalatedEmployees =
          (widget.investigation.hrDecisions ?? [])
              .where((d) {
                final decision = d.decision.toLowerCase();
                return decision == 'suspension' || decision == 'termination';
              })
              .map((d) => d.employeeCode)
              .toList();

      // Initialize all with default "confirm"
      for (final code in _tmEscalatedEmployees) {
        _tmEmployeeDecisions[code] = TopManagementDecision.confirm;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Listen to investigation decision status (HR decision recording)
        BlocListener<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
          listenWhen:
              (previous, current) => previous.investigationDecisionStatus != current.investigationDecisionStatus,
          listener: (context, state) {
            if (state.investigationDecisionStatus == Status.failure && _isSubmitting) {
              // Show error for investigation decision recording
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to record decisions: ${state.operationFailure?.message ?? "Unknown error"}'),
                  duration: const Duration(seconds: 5),
                ),
              );
              if (mounted)
                setState(() {
                  _isSubmitting = false;
                  _hrDecisionSucceeded = false;
                });
            } else if (state.investigationDecisionStatus == Status.success &&
                widget.investigation.currentApprover?.toLowerCase() == 'top_management' &&
                _isSubmitting) {
              // TM decision recorded successfully
              _handleTmDecisionSuccess();
            } else if (state.investigationDecisionStatus == Status.success &&
                widget.investigation.currentApprover?.toLowerCase() == 'hr' &&
                _actionableEmployees.isEmpty &&
                _isSubmitting) {
              // HR decisions-only recorded successfully (no bulk actions needed)
              if (mounted) {
                Navigator.pop(context, true);
                final l10n = AppLocalizations.of(context)!;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.requestSubmittedSuccessfully)));
              }
            } else if (state.investigationDecisionStatus == Status.success &&
                widget.investigation.currentApprover?.toLowerCase() == 'hr' &&
                _actionableEmployees.isNotEmpty &&
                _isSubmitting) {
              // HR decisions completed, bulk creation still pending — latch success before
              // LoadUserDisciplinaryActionRequests resets investigationDecisionStatus to initial
              if (mounted) setState(() => _hrDecisionSucceeded = true);
            } else if (state.investigationDecisionStatus == Status.success &&
                widget.investigation.currentApprover?.toLowerCase() == 'legal' &&
                _isSubmitting) {
              // Legal review submitted successfully
              if (mounted) {
                Navigator.pop(context, true);
                final l10n = AppLocalizations.of(context)!;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.requestSubmittedSuccessfully)));
              }
            }
          },
        ),

        // Listen to bulk creation status
        BlocListener<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
          listenWhen: (previous, current) => previous.bulkCreationStatus != current.bulkCreationStatus,
          listener: (context, state) {
            if (state.bulkCreationStatus == Status.failure) {
              // Show error for bulk creation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to create disciplinary actions: ${state.operationFailure?.message ?? "Unknown error"}',
                  ),
                  duration: const Duration(seconds: 5),
                ),
              );
              if (mounted) setState(() => _isSubmitting = false);
            } else if (state.bulkCreationStatus == Status.success &&
                (_hrDecisionSucceeded || state.investigationDecisionStatus == Status.success)) {
              // Both operations succeeded - now close dialog (works for both HR and TM stage 1)
              // _hrDecisionSucceeded is used because LoadUserDisciplinaryActionRequests resets
              // investigationDecisionStatus to initial before bulk creation completes
              if (mounted && _isSubmitting) {
                setState(() => _hrDecisionSucceeded = false);
                if (widget.investigation.currentApprover?.toLowerCase() == 'top_management') {
                  context.read<UserDisciplinaryActionRequestsBloc>().add(
                    SendTopManagementDecisionNotification(investigationId: widget.investigation.id!),
                  );
                }
                Navigator.pop(context, true);
                final l10n = AppLocalizations.of(context)!;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.requestSubmittedSuccessfully)));
              }
            }
          },
        ),

        // Listen to fetched disciplinary action status (for viewing linked DA)
        BlocListener<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
          listenWhen:
              (previous, current) =>
                  previous.fetchedDisciplinaryActionStatus != current.fetchedDisciplinaryActionStatus,
          listener: (context, state) {
            if (state.fetchedDisciplinaryActionStatus == Status.success && state.fetchedDisciplinaryAction != null) {
              context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetFetchedDisciplinaryAction());
              setState(() {
                _fetchedDA = state.fetchedDisciplinaryAction;
                _isLoadingDA = false;
              });
              _navigateToDADetails();
            } else if (state.fetchedDisciplinaryActionStatus == Status.failure) {
              context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetFetchedDisciplinaryAction());
              setState(() => _isLoadingDA = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to load disciplinary action: ${state.operationFailure?.message ?? "Unknown error"}',
                  ),
                ),
              );
            }
          },
        ),

        // Handle PDF/attachment open requests from investigation attachments
        BlocListener<UserDisciplinaryActionRequestsBloc, UserDisciplinaryActionRequestsState>(
          listenWhen: (previous, current) => previous.pdfOpenStatus != current.pdfOpenStatus,
          listener: (context, state) async {
            if (state.pdfOpenStatus == Status.success && state.pdfSignedUrl != null) {
              final uri = Uri.parse(state.pdfSignedUrl!);
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              if (context.mounted) {
                context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetPdfOpenStatus());
              }
            } else if (state.pdfOpenStatus == Status.failure) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.operationFailure?.message ?? 'Failed to open attachment')));
                context.read<UserDisciplinaryActionRequestsBloc>().add(const ResetPdfOpenStatus());
              }
            }
          },
        ),
      ],
      child: Stack(
        children: [
          Dialog(
            child: Container(
              width: 600,
              decoration: BoxDecoration(color: Colors.grey[250], borderRadius: BorderRadius.circular(12)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title section
                  _buildTitle(),

                  // Content section
                  SizedBox(
                    width: 600,
                    height: context.screenHeight > 700 ? 600 : context.screenHeight * 0.8,
                    child: ClipRect(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchOutCurve: const Threshold(0.0), // Exit instantly at start
                        switchInCurve: const Interval(0.1, 1.0, curve: Curves.easeInOut), // Delay then animate
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          // Extract view from child key
                          final childKey = child.key as ValueKey<int>;
                          final childView = childKey.value;

                          // Determine if this is entering or exiting widget
                          final isEntering = childView == _currentView;

                          // Exiting widget: hide instantly
                          if (!isEntering) {
                            return const SizedBox.shrink(); // Disappear immediately
                          }

                          // Entering widget: slide in from navigation direction
                          final slideDirection = _forwardNavigation ? 1.0 : -1.0;
                          final offset = Tween<Offset>(
                            begin: Offset(slideDirection, 0.0),
                            end: Offset.zero,
                          ).animate(animation);

                          return SlideTransition(position: offset, child: child);
                        },
                        child: KeyedSubtree(key: ValueKey<int>(_currentView), child: _buildCurrentView()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the title based on current view
  Widget _buildTitle() {
    final l10n = AppLocalizations.of(context)!;
    Widget titleContent;

    if (_currentView == 0) {
      // Investigation Detail View
      titleContent = Row(
        children: [
          const Icon(Icons.content_paste_search),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.investigation, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
          if (_isLoadingDA)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      );
    } else if (_currentView == 2) {
      // DA Details View
      titleContent = Row(
        children: [
          const Icon(Icons.gavel),
          const SizedBox(width: 8),
          Expanded(
            child: Text(l10n.disciplinaryAction, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      );
    } else {
      // Decision Recording View - title depends on approver type
      final approver = widget.investigation.currentApprover?.toLowerCase();
      String titleText = l10n.recordDecision;
      IconData titleIcon = Icons.edit;

      if (approver == 'hr') {
        final hasLegalReview = widget.investigation.legalInvestigationPdfUrl != null;
        titleText = hasLegalReview ? l10n.hrFinalDecisionAfterLegal : l10n.hrDecision;
        titleIcon = Icons.business_center;
      } else if (approver == 'legal') {
        titleText = l10n.legalReview;
        titleIcon = Icons.gavel;
      } else if (approver == 'top_management') {
        titleText = l10n.topManagementDecision;
        titleIcon = Icons.supervisor_account;
      }

      titleContent = Row(
        children: [
          Icon(titleIcon),
          const SizedBox(width: 8),
          Expanded(child: Text(titleText, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
          // Disable close button in decision view (must use Back button)
          IconButton(icon: const Icon(Icons.close), onPressed: null),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
      ),
      child: titleContent,
    );
  }

  /// Builds the current view content
  Widget _buildCurrentView() {
    if (_currentView == 0) {
      // View 0: Investigation Detail Content
      // Three-level visibility:
      //   Employee subject → everything hidden
      //   Passive observer (N+1/N+2) → employees + decisions visible, no remarks/PDFs
      //   Normal viewer → everything visible
      final hideAll = widget.isEmployeeSubject;
      final restricted = widget.isPassiveObserver;
      return InvestigationDetailContent(
        investigation: widget.investigation,
        showActionButtons: widget.showActionButtons,
        onRecordDecision: _navigateToDecisionRecording,
        onOpenDisciplinaryAction: _onOpenDisciplinaryAction,
        showIncidentDescription: !hideAll && !restricted,
        showRequestorAttachments: !hideAll && !restricted,
        showDecisionHistory: !hideAll,
        showDecisionDetails: !hideAll && !restricted,
        showLinkedDisciplinaryActions: !hideAll && !restricted,
        showEmployeesList: !hideAll,
        showCurrentApprover: !hideAll && !restricted,
      );
    } else if (_currentView == 2) {
      // View 2: DA Details
      return _buildDADetailsView();
    } else {
      // View 1: Decision Recording (HR/Legal/TM specific)
      return _buildDecisionRecordingView();
    }
  }

  /// Builds the decision recording view based on approver type
  Widget _buildDecisionRecordingView() {
    final l10n = AppLocalizations.of(context)!;
    final approver = widget.investigation.currentApprover?.toLowerCase();

    if (approver == 'hr') {
      // HR Decision Recording (multi-stage)
      return _buildHrDecisionView();
    } else if (approver == 'legal') {
      // Legal Review
      return _buildLegalDecisionView();
    } else if (approver == 'top_management') {
      // Top Management Decision
      return _buildTopManagementDecisionView();
    }

    // Fallback (should never happen)
    return Center(child: Text(l10n.invalidApproverType));
  }

  /// Builds HR decision view with nested multi-stage workflow
  Widget _buildHrDecisionView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Multi-stage content with nested animation
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 70, // Leave space for buttons (Divider 1px + Padding 16px + Button ~48px)
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchOutCurve: const Threshold(0.0),
                switchInCurve: const Interval(0.1, 1.0, curve: Curves.easeInOut),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final childKey = child.key as ValueKey<int>;
                  final childStage = childKey.value;
                  final isEntering = childStage == _hrStage;

                  if (!isEntering) {
                    return const SizedBox.shrink();
                  }

                  final slideDirection = _hrForwardNavigation ? 1.0 : -1.0;
                  final offset = Tween<Offset>(begin: Offset(slideDirection, 0.0), end: Offset.zero).animate(animation);

                  return SlideTransition(position: offset, child: child);
                },
                child: KeyedSubtree(key: ValueKey<int>(_hrStage), child: _buildHrStageContent()),
              ),
            ),
          ),
        ),

        // Action buttons
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1),
                Padding(padding: const EdgeInsets.all(16), child: _buildHrActionButtons()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the current HR stage content
  Widget _buildHrStageContent() {
    if (_hrStage == 0) {
      // Stage 0: HR Decision Entry
      return HrDecisionStageContent(
        investigation: widget.investigation,
        employeeDecisions: _employeeDecisions,
        employeeComments: _hrEmployeeComments,
        attachmentFiles: _hrAttachmentFiles,
        attachmentFileNames: _hrAttachmentFileNames,
        formKey: _formKey,
        onDecisionChanged: (employeeCode, decision) {
          setState(() {
            _employeeDecisions[employeeCode] = decision;
          });
        },
        onCommentChanged: (employeeCode, comment) {
          _hrEmployeeComments[employeeCode] = comment;
        },
        onAttachmentsChanged: (files, names) {
          setState(() {
            _hrAttachmentFiles = files;
            _hrAttachmentFileNames = names;
          });
        },
      );
    } else {
      // Stage 1: Bulk Action Creation
      return BulkCreationStageContent(
        investigation: widget.investigation,
        actionableEmployees: _actionableEmployees,
        employeeActionTypes: _employeeActionTypes,
        employeeDeductDays: _employeeDeductDays,
        attachmentFiles: _bulkAttachmentFiles,
        attachmentFileNames: _bulkAttachmentFileNames,
        onActionTypeChanged: (employeeCode, actionType) {
          setState(() {
            _employeeActionTypes[employeeCode] = actionType;
            // Clear deduct days if not written warning
            if (actionType != DisciplinaryActionType.writtenWarning) {
              _employeeDeductDays[employeeCode] = null;
            }
          });
        },
        onDeductDaysChanged: (employeeCode, deductDays) {
          setState(() {
            _employeeDeductDays[employeeCode] = deductDays;
          });
        },
        onAttachmentsChanged: (files, names) {
          setState(() {
            _bulkAttachmentFiles = files;
            _bulkAttachmentFileNames = names;
          });
        },
      );
    }
  }

  /// Builds HR action buttons based on current stage
  Widget _buildHrActionButtons() {
    final l10n = AppLocalizations.of(context)!;
    if (_hrStage == 0) {
      // Stage 0: Back to Details + Continue
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n.back),
            onPressed: _isSubmitting ? null : _navigateBackToDetails,
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _validateAndContinueToActions,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
            child:
                _isSubmitting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                    : Text(l10n.continueButton),
          ),
        ],
      );
    } else {
      // Stage 1: Back + Submit All
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n.back),
            onPressed: _isSubmitting ? null : _goBackToHrDecisions,
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitHrDecisionsAndActions,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
            child:
                _isSubmitting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                    : Text(
                      '${l10n.submit} ${l10n.total} (${_actionableEmployees.length} ${_actionableEmployees.length == 1 ? l10n.action : l10n.actions})',
                    ),
          ),
        ],
      );
    }
  }

  /// Validates HR decisions and continues to bulk creation stage
  Future<void> _validateAndContinueToActions() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Ensure all employees have decisions
    if (_employeeDecisions.length != widget.investigation.employeeCodes.length) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectDecisionForAll)));
      return;
    }

    // Compute actionable employees
    _actionableEmployees =
        _employeeDecisions.entries.where((e) => e.value == HrDecision.takeAction).map((e) => e.key).toList();

    // If no take_action decisions, submit HR decisions only
    if (_actionableEmployees.isEmpty) {
      await _submitHrDecisionsOnly();
      return;
    }

    // Initialize new employees + clean up removed ones (preserves existing selections)
    for (final code in _actionableEmployees) {
      _employeeActionTypes.putIfAbsent(code, () => DisciplinaryActionType.writtenWarning);
      _employeeDeductDays.putIfAbsent(code, () => null);
    }
    _employeeActionTypes.removeWhere((code, _) => !_actionableEmployees.contains(code));
    _employeeDeductDays.removeWhere((code, _) => !_actionableEmployees.contains(code));

    // Carryover: Pre-populate bulk attachments with HR attachments (if not already set)
    if (_bulkAttachmentFiles.isEmpty && _hrAttachmentFiles.isNotEmpty) {
      _bulkAttachmentFiles = List.from(_hrAttachmentFiles);
      _bulkAttachmentFileNames = List.from(_hrAttachmentFileNames);
    }

    // Transition to Stage 1
    setState(() {
      _hrForwardNavigation = true;
      _hrStage = 1;
    });
  }

  /// Navigate back to HR decisions stage
  void _goBackToHrDecisions() {
    setState(() {
      _hrForwardNavigation = false;
      _hrStage = 0;
    });
  }

  /// Submit both HR decisions and bulk actions
  Future<void> _submitHrDecisionsAndActions() async {
    setState(() => _isSubmitting = true);

    try {
      final userId = context.read<UserBloc>().state.user!.id!;

      // 1. Submit HR Decisions (use mapping extension to fix escalation logic)
      final decisionsAsStrings = _employeeDecisions.map(
        (code, decision) => MapEntry(code, decision.toInvestigationDecisionString()),
      );

      final daTypes = Map.fromEntries(_employeeActionTypes.entries.map((e) => MapEntry(e.key, e.value.value)));
      final deductDays = Map.fromEntries(
        _employeeDeductDays.entries.where((e) => e.value != null).map((e) => MapEntry(e.key, e.value!)),
      );

      context.read<UserDisciplinaryActionRequestsBloc>().add(
        RecordHrInvestigationDecision(
          investigationId: widget.investigation.id!,
          decidedBy: userId,
          employeeDecisions: decisionsAsStrings,
          employeeComments: _hrEmployeeComments.isEmpty ? null : Map.from(_hrEmployeeComments),
          escalateToLegal: false,
          attachmentFileNames: _hrAttachmentFileNames,
          attachmentFiles: _hrAttachmentFiles,
          employeeDaTypes: daTypes.isEmpty ? null : daTypes,
          employeeDeductDays: deductDays.isEmpty ? null : deductDays,
        ),
      );

      // 2. Submit Bulk Actions (grouped by action type AND deduct days)
      final Map<(DisciplinaryActionType, double?), List<int>> groupedByTypeAndDeductDays = {};
      for (final entry in _employeeActionTypes.entries) {
        final employeeCode = entry.key;
        final actionType = entry.value;
        final deductDays =
            actionType == DisciplinaryActionType.writtenWarning ? _employeeDeductDays[employeeCode] : null;

        final key = (actionType, deductDays);
        groupedByTypeAndDeductDays.putIfAbsent(key, () => []).add(employeeCode);
      }

      for (final entry in groupedByTypeAndDeductDays.entries) {
        final (actionType, deductDays) = entry.key;
        final employeeCodes = entry.value;

        // Create WrittenWarningOptions for written warning with deduct days
        final writtenWarningOptions =
            actionType == DisciplinaryActionType.writtenWarning && deductDays != null
                ? WrittenWarningOptions(deductDays: deductDays)
                : null;

        context.read<UserDisciplinaryActionRequestsBloc>().add(
          CreateBulkDisciplinaryActionsFromInvestigation(
            investigationId: widget.investigation.id!,
            requestorCode: userId,
            employeeCodes: employeeCodes,
            actionType: actionType,
            violationCategory: widget.investigation.violationCategory,
            violation: widget.investigation.violation,
            violationDate: widget.investigation.violationDate!,
            incidentDescription: widget.investigation.incidentDescription,
            writtenWarningOptions: writtenWarningOptions,
            attachmentFileNames: _bulkAttachmentFileNames,
            attachmentFiles: _bulkAttachmentFiles,
          ),
        );
      }

      // 3. Success/error handling now done via BlocListener
      // Dialog will close automatically when both operations succeed
      // Errors will be shown via BlocListener
    } catch (e) {
      // Catch any synchronous errors (unlikely with event dispatch)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Submit HR decisions only (no actions needed)
  Future<void> _submitHrDecisionsOnly() async {
    setState(() => _isSubmitting = true);

    try {
      final decisionsAsStrings = _employeeDecisions.map(
        (code, decision) => MapEntry(code, decision.toInvestigationDecisionString()),
      );

      context.read<UserDisciplinaryActionRequestsBloc>().add(
        RecordHrInvestigationDecision(
          investigationId: widget.investigation.id!,
          decidedBy: context.read<UserBloc>().state.user!.id!,
          employeeDecisions: decisionsAsStrings,
          employeeComments: _hrEmployeeComments.isEmpty ? null : Map.from(_hrEmployeeComments),
          escalateToLegal: false,
          pdfUrls: null,
          attachmentFileNames: _hrAttachmentFileNames.isEmpty ? null : _hrAttachmentFileNames,
          attachmentFiles: _hrAttachmentFiles.isEmpty ? null : _hrAttachmentFiles,
        ),
      );
      // Success/error handled via BlocListener (investigationDecisionStatus)
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Builds legal decision view with per-employee comments, legal opinion, and mandatory PDF upload
  Widget _buildLegalDecisionView() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: LegalDecisionStageContent(
              investigation: widget.investigation,
              employeeComments: _legalEmployeeComments,
              selectedPdfs: _legalDecisionPdfs,
              onCommentChanged: (code, comment) => _legalEmployeeComments[code] = comment,
              onPdfsChanged: (pdfs) => setState(() => _legalDecisionPdfs = pdfs),
            ),
          ),
        ),

        // Actions
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.backToDetails),
                onPressed: _isSubmitting ? null : _navigateBackToDetails,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon:
                    _isSubmitting
                        ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                        : const Icon(Icons.gavel),
                label: Text(l10n.submitLegalReview),
                onPressed: _isSubmitting || _legalDecisionPdfs == null ? null : _submitLegalReview,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700], foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _submitLegalReview() {
    // PDF is mandatory
    if (_legalDecisionPdfs == null || _legalDecisionPdfs!.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.legalPdfMandatory)));
      return;
    }

    final userId = context.read<UserBloc>().state.user!.id!;
    setState(() => _isSubmitting = true);

    context.read<UserDisciplinaryActionRequestsBloc>().add(
      RecordLegalInvestigationReview(
        investigationId: widget.investigation.id!,
        reviewedBy: userId,
        employeeComments: _legalEmployeeComments.isEmpty ? null : Map.from(_legalEmployeeComments),
        pdfUrls: const [],
        pdfBytes: _legalDecisionPdfs!.map((f) => f.bytes!).toList(),
        pdfFileNames: _legalDecisionPdfs!.map((f) => f.name).toList(),
      ),
    );
    // BlocListener handles success (pop + snackbar) and failure (reset _isSubmitting)
  }

  /// Builds top management decision view with nested multi-stage workflow
  /// Stage 0: TM Decision Form, Stage 1: Bulk Action Creation (if any convertToDisciplinary)
  Widget _buildTopManagementDecisionView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Multi-stage content with nested animation
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 70,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ClipRect(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchOutCurve: const Threshold(0.0),
                switchInCurve: const Interval(0.1, 1.0, curve: Curves.easeInOut),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  final childKey = child.key as ValueKey<int>;
                  final childStage = childKey.value;
                  final isEntering = childStage == _tmStage;

                  if (!isEntering) {
                    return const SizedBox.shrink();
                  }

                  final slideDirection = _tmForwardNavigation ? 1.0 : -1.0;
                  final offset = Tween<Offset>(begin: Offset(slideDirection, 0.0), end: Offset.zero).animate(animation);

                  return SlideTransition(position: offset, child: child);
                },
                child: KeyedSubtree(key: ValueKey<int>(_tmStage), child: _buildTmStageContent()),
              ),
            ),
          ),
        ),

        // Action buttons
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(height: 1),
                Padding(padding: const EdgeInsets.all(16), child: _buildTmActionButtons()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the current TM stage content
  Widget _buildTmStageContent() {
    if (_tmStage == 0) {
      // Stage 0: TM Decision Entry
      return TmDecisionStageContent(
        investigation: widget.investigation,
        employeeDecisions: _tmEmployeeDecisions,
        employeeComments: _tmEmployeeComments,
        decisionPdfs: _tmDecisionPdfs,
        formKey: _tmFormKey,
        escalatedEmployees: _tmEscalatedEmployees,
        onDecisionChanged: (employeeCode, decision) {
          setState(() {
            _tmEmployeeDecisions[employeeCode] = decision;
          });
        },
        onCommentChanged: (employeeCode, comment) {
          _tmEmployeeComments[employeeCode] = comment;
        },
        onPdfsChanged: (pdfs) {
          setState(() {
            _tmDecisionPdfs = pdfs;
          });
        },
      );
    } else {
      // Stage 1: Bulk Action Creation (only convertToDisciplinary employees)
      return BulkCreationStageContent(
        investigation: widget.investigation,
        actionableEmployees: _tmActionableEmployees,
        employeeActionTypes: _tmEmployeeActionTypes,
        employeeDeductDays: _tmEmployeeDeductDays,
        attachmentFiles: _tmBulkAttachmentFiles,
        attachmentFileNames: _tmBulkAttachmentFileNames,
        onActionTypeChanged: (employeeCode, actionType) {
          setState(() {
            _tmEmployeeActionTypes[employeeCode] = actionType;
            if (actionType != DisciplinaryActionType.writtenWarning) {
              _tmEmployeeDeductDays[employeeCode] = null;
            }
          });
        },
        onDeductDaysChanged: (employeeCode, deductDays) {
          setState(() {
            _tmEmployeeDeductDays[employeeCode] = deductDays;
          });
        },
        onAttachmentsChanged: (files, names) {
          setState(() {
            _tmBulkAttachmentFiles = files;
            _tmBulkAttachmentFileNames = names;
          });
        },
      );
    }
  }

  /// Builds TM action buttons based on current stage
  Widget _buildTmActionButtons() {
    final l10n = AppLocalizations.of(context)!;
    if (_tmStage == 0) {
      // Stage 0: Back to Details + dynamic button (Continue or Submit)
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n.back),
            onPressed: _isSubmitting ? null : _navigateBackToDetails,
          ),
          const SizedBox(width: 8),
          if (_tmEscalatedEmployees.isNotEmpty)
            _hasConvertToDisciplinary()
                ? ElevatedButton(
                  onPressed: _isSubmitting ? null : _validateAndContinueToTmActions,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700], foregroundColor: Colors.white),
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                          : Text(l10n.continueButton),
                )
                : ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTmDecisionOnly,
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
    } else {
      // Stage 1: Back + Submit All
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: Text(l10n.back),
            onPressed: _isSubmitting ? null : _goBackToTmDecisions,
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitTmDecisionAndActions,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700], foregroundColor: Colors.white),
            child:
                _isSubmitting
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                    : Text(
                      '${l10n.submit} ${l10n.total} (${_tmActionableEmployees.length} ${_tmActionableEmployees.length == 1 ? l10n.action : l10n.actions})',
                    ),
          ),
        ],
      );
    }
  }

  /// Returns true if any TM employee decision is convertToDisciplinary
  bool _hasConvertToDisciplinary() {
    return _tmEmployeeDecisions.values.any((d) => d == TopManagementDecision.convertToDisciplinary);
  }

  /// Validates TM decisions and continues to bulk creation stage
  Future<void> _validateAndContinueToTmActions() async {
    if (!_tmFormKey.currentState!.validate()) return;

    // Validate all escalated employees have decisions
    if (_tmEmployeeDecisions.length != _tmEscalatedEmployees.length) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectDecisionForAll)));
      return;
    }

    // Compute actionable employees (only convertToDisciplinary)
    _tmActionableEmployees =
        _tmEmployeeDecisions.entries
            .where((e) => e.value == TopManagementDecision.convertToDisciplinary)
            .map((e) => e.key)
            .toList();

    if (_tmActionableEmployees.isEmpty) {
      // Safety check: no convertToDisciplinary, submit directly
      await _submitTmDecisionOnly();
      return;
    }

    // Initialize new employees + clean up removed ones (preserves existing selections)
    for (final code in _tmActionableEmployees) {
      _tmEmployeeActionTypes.putIfAbsent(code, () => DisciplinaryActionType.writtenWarning);
      _tmEmployeeDeductDays.putIfAbsent(code, () => null);
    }
    _tmEmployeeActionTypes.removeWhere((code, _) => !_tmActionableEmployees.contains(code));
    _tmEmployeeDeductDays.removeWhere((code, _) => !_tmActionableEmployees.contains(code));

    // Transition to Stage 1
    setState(() {
      _tmForwardNavigation = true;
      _tmStage = 1;
    });
  }

  /// Navigate back to TM decisions stage
  void _goBackToTmDecisions() {
    setState(() {
      _tmForwardNavigation = false;
      _tmStage = 0;
    });
  }

  /// Submit TM decisions only (no convertToDisciplinary employees)
  Future<void> _submitTmDecisionOnly() async {
    if (!_tmFormKey.currentState!.validate()) return;

    if (_tmEmployeeDecisions.length != _tmEscalatedEmployees.length) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectDecisionForAll)));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final decisionsAsStrings = _tmEmployeeDecisions.map((code, decision) => MapEntry(code, decision.name));

      // Extract PDF bytes and file names from picked files
      final pdfBytes = _tmDecisionPdfs?.where((f) => f.bytes != null).map((f) => f.bytes!).toList();
      final pdfFileNames = _tmDecisionPdfs?.where((f) => f.bytes != null).map((f) => f.name).toList();

      context.read<UserDisciplinaryActionRequestsBloc>().add(
        RecordTopManagementInvestigationDecision(
          investigationId: widget.investigation.id!,
          decidedBy: context.read<UserBloc>().state.user!.id!,
          employeeDecisions: decisionsAsStrings,
          employeeComments: _tmEmployeeComments.isEmpty ? null : Map.from(_tmEmployeeComments),
          pdfBytes: pdfBytes,
          pdfFileNames: pdfFileNames,
        ),
      );

      // Success/error handling via BlocListener → _handleTmDecisionSuccess()
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Submit both TM decisions and bulk disciplinary actions
  Future<void> _submitTmDecisionAndActions() async {
    setState(() => _isSubmitting = true);

    try {
      final userId = context.read<UserBloc>().state.user!.id!;

      // 1. Submit TM Decisions
      final decisionsAsStrings = _tmEmployeeDecisions.map((code, decision) => MapEntry(code, decision.name));

      // Extract PDF bytes and file names from picked files
      final pdfBytes = _tmDecisionPdfs?.where((f) => f.bytes != null).map((f) => f.bytes!).toList();
      final pdfFileNames = _tmDecisionPdfs?.where((f) => f.bytes != null).map((f) => f.name).toList();

      context.read<UserDisciplinaryActionRequestsBloc>().add(
        RecordTopManagementInvestigationDecision(
          investigationId: widget.investigation.id!,
          decidedBy: userId,
          employeeDecisions: decisionsAsStrings,
          employeeComments: _tmEmployeeComments.isEmpty ? null : Map.from(_tmEmployeeComments),
          pdfBytes: pdfBytes,
          pdfFileNames: pdfFileNames,
        ),
      );

      // 2. Submit Bulk Actions (grouped by action type AND deduct days)
      final Map<(DisciplinaryActionType, double?), List<int>> groupedByTypeAndDeductDays = {};
      for (final entry in _tmEmployeeActionTypes.entries) {
        final employeeCode = entry.key;
        final actionType = entry.value;
        final deductDays =
            actionType == DisciplinaryActionType.writtenWarning ? _tmEmployeeDeductDays[employeeCode] : null;

        final key = (actionType, deductDays);
        groupedByTypeAndDeductDays.putIfAbsent(key, () => []).add(employeeCode);
      }

      for (final entry in groupedByTypeAndDeductDays.entries) {
        final (actionType, deductDays) = entry.key;
        final employeeCodes = entry.value;

        final writtenWarningOptions =
            actionType == DisciplinaryActionType.writtenWarning && deductDays != null
                ? WrittenWarningOptions(deductDays: deductDays)
                : null;

        context.read<UserDisciplinaryActionRequestsBloc>().add(
          CreateBulkDisciplinaryActionsFromInvestigation(
            investigationId: widget.investigation.id!,
            requestorCode: userId,
            employeeCodes: employeeCodes,
            actionType: actionType,
            violationCategory: widget.investigation.violationCategory,
            violation: widget.investigation.violation,
            violationDate: widget.investigation.violationDate!,
            incidentDescription: widget.investigation.incidentDescription,
            writtenWarningOptions: writtenWarningOptions,
            attachmentFileNames: _tmBulkAttachmentFileNames,
            attachmentFiles: _tmBulkAttachmentFiles,
          ),
        );
      }

      // Success/error handling via BlocListener (both statuses must succeed)
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  /// Handle successful TM decision submission (stage 0 only, no bulk actions)
  void _handleTmDecisionSuccess() {
    if (!mounted || _tmStage != 0) return;

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.tmDecisionSubmittedSuccess)));

    context.read<UserDisciplinaryActionRequestsBloc>().add(
      SendTopManagementDecisionNotification(investigationId: widget.investigation.id!),
    );

    Navigator.pop(context, true);
  }

  /// Navigate from detail view to decision recording view
  void _navigateToDecisionRecording() {
    setState(() {
      _forwardNavigation = true;
      _currentView = 1;
    });
  }

  /// Navigate back from decision recording to detail view
  void _navigateBackToDetails() {
    setState(() {
      _forwardNavigation = false;
      _currentView = 0;
    });
  }

  /// Navigate to DA details view
  void _navigateToDADetails() {
    setState(() {
      _forwardNavigation = true; // Same direction as DA→Investigation (slide from right)
      _currentView = 2;
    });
  }

  /// Navigate back from DA details to investigation detail
  void _navigateBackFromDA() {
    setState(() {
      _forwardNavigation = false; // Slide from left (going back)
      _currentView = 0;
    });
  }

  /// Handle opening a disciplinary action from the linked actions table
  void _onOpenDisciplinaryAction(int daId) {
    setState(() => _isLoadingDA = true);
    context.read<UserDisciplinaryActionRequestsBloc>().add(FetchDisciplinaryActionById(daId));
  }

  /// Builds the DA details view using the extracted widget
  Widget _buildDADetailsView() {
    final l10n = AppLocalizations.of(context)!;
    final da = _fetchedDA!;
    final userId = context.read<UserBloc>().state.user?.id;
    final isHrUser = context.read<UserBloc>().state.user?.groups?.contains('hr') ?? false;
    final isEmployee = userId == da.employeeCode;
    final isN1NotRequestor =
        userId != da.employeeCode && userId != da.requestorCode && userId != da.n2Code && !isHrUser;
    final isHrInvestigation = da.actionType == DisciplinaryActionType.hrInvestigation;

    // Same visibility rules as the main DA detail dialog
    final canViewIncidentDescription = !(isEmployee && isHrInvestigation) && !(isN1NotRequestor && isHrInvestigation);
    final canViewAttachments = !isEmployee && !(isN1NotRequestor && isHrInvestigation);
    final canViewInvestigationDetails = !isEmployee && !(isN1NotRequestor && isHrInvestigation);
    final canViewLegalEscalation = !isEmployee && !(isN1NotRequestor && isHrInvestigation);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Main content
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 70,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 16),
            child: DisciplinaryActionDetailContent(
              request: da,
              showIncidentDescription: canViewIncidentDescription,
              showAttachments: canViewAttachments,
              showInvestigationDetails: canViewInvestigationDetails,
              showLegalEscalation: canViewLegalEscalation,
              isEmployeeView: isEmployee,
              currentApproverOverride:
                  isEmployee && da.currentApprover?.toLowerCase() == 'legal' ? l10n.hrDepartment : null,
            ),
          ),
        ),

        // Back button
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
            child: Column(
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: Text('${l10n.back} ${l10n.to} ${l10n.investigation}'),
                        onPressed: _navigateBackFromDA,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // /// Close the entire dialog (called when decision is submitted)
  // void _closeDialog({bool refresh = false}) {
  //   Navigator.pop(context, refresh);
  // }
}
