import 'dart:typed_data';

import 'package:hrms_demo/core/constants/leave_type.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/repos/leave_request/bulk_leave_result.dart';
import 'package:equatable/equatable.dart';

class HrToolsState extends Equatable {
  final List<UserModel> searchResults;
  final List<UserModel> selectedEmployees;
  final bool isSearching;
  final int tabIndex;

  // Leave tab fields
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String leaveType;

  /// `true` — force-approve every request (the historical behaviour).
  /// `false` — send each request through the normal cycle starting at N+1.
  final bool autoApprove;

  /// Medical report staged for upload, held in memory until the request row
  /// exists (the `sicknotes` bucket write needs its id). Only ever populated
  /// while [leaveType] is 'Sick' AND exactly one employee is selected — a
  /// medical report belongs to one person, so it is not offered for a batch.
  final List<Uint8List> sickNoteFiles;
  final List<String> sickNoteFileNames;

  // Overtime tab fields
  final double overtimeDelta;

  // Submission state
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;
  final Map<String, String> validationErrors;

  /// Employees the normal-cycle submission could not create a request for, with
  /// the server's reason. Always empty after an auto-approve submission, which
  /// is a single all-or-nothing insert.
  final List<BulkLeaveFailure> submissionFailures;

  /// How many requests the last submission actually created.
  final int submissionSuccessCount;

  const HrToolsState({
    this.searchResults = const [],
    this.selectedEmployees = const [],
    this.isSearching = false,
    this.tabIndex = 0,
    this.dateFrom,
    this.dateTo,
    this.leaveType = 'Annual',
    this.autoApprove = true,
    this.sickNoteFiles = const [],
    this.sickNoteFileNames = const [],
    this.overtimeDelta = 0,
    this.isSubmitting = false,
    this.successMessage,
    this.errorMessage,
    this.validationErrors = const {},
    this.submissionFailures = const [],
    this.submissionSuccessCount = 0,
  });

  /// Whether a medical report may be attached to this submission.
  ///
  /// Single source of truth for the rule, shared by the bloc (which clears
  /// staged files the moment it stops holding) and the form (which shows the
  /// upload control only while it holds).
  bool get canAttachSickNote => leaveType == LeaveType.sick.label && selectedEmployees.length == 1;

  HrToolsState copyWith({
    List<UserModel>? searchResults,
    List<UserModel>? selectedEmployees,
    bool? isSearching,
    int? tabIndex,
    DateTime? dateFrom,
    bool clearDateFrom = false,
    DateTime? dateTo,
    bool clearDateTo = false,
    String? leaveType,
    bool? autoApprove,
    List<Uint8List>? sickNoteFiles,
    List<String>? sickNoteFileNames,
    double? overtimeDelta,
    bool? isSubmitting,
    String? successMessage,
    bool clearSuccessMessage = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    Map<String, String>? validationErrors,
    List<BulkLeaveFailure>? submissionFailures,
    int? submissionSuccessCount,
  }) {
    return HrToolsState(
      searchResults: searchResults ?? this.searchResults,
      selectedEmployees: selectedEmployees ?? this.selectedEmployees,
      isSearching: isSearching ?? this.isSearching,
      tabIndex: tabIndex ?? this.tabIndex,
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      leaveType: leaveType ?? this.leaveType,
      autoApprove: autoApprove ?? this.autoApprove,
      sickNoteFiles: sickNoteFiles ?? this.sickNoteFiles,
      sickNoteFileNames: sickNoteFileNames ?? this.sickNoteFileNames,
      overtimeDelta: overtimeDelta ?? this.overtimeDelta,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: clearSuccessMessage ? null : (successMessage ?? this.successMessage),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      validationErrors: validationErrors ?? this.validationErrors,
      submissionFailures: submissionFailures ?? this.submissionFailures,
      submissionSuccessCount: submissionSuccessCount ?? this.submissionSuccessCount,
    );
  }

  @override
  List<Object?> get props => [
    searchResults,
    selectedEmployees,
    isSearching,
    tabIndex,
    dateFrom,
    dateTo,
    leaveType,
    autoApprove,
    sickNoteFiles,
    sickNoteFileNames,
    overtimeDelta,
    isSubmitting,
    successMessage,
    errorMessage,
    validationErrors,
    submissionFailures,
    submissionSuccessCount,
  ];
}
