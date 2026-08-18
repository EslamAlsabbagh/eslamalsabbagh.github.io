import 'dart:async';
import 'package:hrms_demo/core/services/employee_validation_service.dart';
import 'package:hrms_demo/core/services/file_parser_service.dart';
import 'package:hrms_demo/data/models/bulk_employee_row.dart';
import 'package:hrms_demo/data/repos/auth/auth_repo.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/presentation/bulk_upload/bloc/bulk_upload_event.dart';
import 'package:hrms_demo/presentation/bulk_upload/bloc/bulk_upload_state.dart';

class BulkUploadBloc extends Bloc<BulkUploadEvent, BulkUploadState> {
  final FileParserService _fileParserService;
  final EmployeeValidationService _validationService;
  final UsersRepo _usersRepo;
  final AuthRepo _authRepo;

  BulkUploadBloc({
    required FileParserService fileParserService,
    required EmployeeValidationService validationService,
    required UsersRepo usersRepo,
    required AuthRepo authRepo,
  }) : _fileParserService = fileParserService,
       _validationService = validationService,
       _usersRepo = usersRepo,
       _authRepo = authRepo,
       super(const BulkUploadState()) {
    on<UploadFile>(_onUploadFile);
    on<UploadFileWithBytes>(_onUploadFileWithBytes);
    on<UpdateRowField>(_onUpdateRowField);
    on<RevalidateRows>(_onRevalidateRows);
    on<SubmitBulkUpload>(_onSubmitBulkUpload);
    on<RetryFailedEmployees>(_onRetryFailedEmployees);
    on<ResetBulkUpload>(_onResetBulkUpload);
    on<RemoveRow>(_onRemoveRow);
    on<AddEmptyRow>(_onAddEmptyRow);
  }

  /// Handle file upload event with bytes (for web platform)
  Future<void> _onUploadFileWithBytes(UploadFileWithBytes event, Emitter<BulkUploadState> emit) async {
    emit(state.copyWith(status: BulkUploadStatus.parsing, clearErrorMessage: true));

    try {
      // Parse the file from bytes
      final rows = await _fileParserService.parseFileFromBytes(event.fileName, event.bytes);

      if (rows.isEmpty) {
        emit(state.copyWith(status: BulkUploadStatus.error, errorMessage: 'No data found in the file'));
        return;
      }

      emit(state.copyWith(status: BulkUploadStatus.validating, rows: rows));

      // Validate all rows
      final validatedRows = await _validationService.validateAllRows(rows);

      // Determine if ready or has errors
      final hasErrors = validatedRows.any((row) => row.hasErrors);
      final newStatus = hasErrors ? BulkUploadStatus.ready : BulkUploadStatus.ready;

      // Sort invalid rows to the top so users can find and fix errors without scrolling.
      validatedRows.sort((a, b) {
        final aOrder = a.hasErrors ? 0 : 1;
        final bOrder = b.hasErrors ? 0 : 1;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        return a.rowIndex.compareTo(b.rowIndex);
      });
      emit(state.copyWith(status: newStatus, rows: validatedRows));
    } catch (e) {
      emit(state.copyWith(status: BulkUploadStatus.error, errorMessage: 'Failed to parse file: ${e.toString()}'));
    }
  }

  /// Handle file upload event
  Future<void> _onUploadFile(UploadFile event, Emitter<BulkUploadState> emit) async {
    emit(state.copyWith(status: BulkUploadStatus.parsing, currentFilePath: event.filePath, clearErrorMessage: true));

    try {
      // Parse the file
      final rows = await _fileParserService.parseFile(event.filePath);

      if (rows.isEmpty) {
        emit(state.copyWith(status: BulkUploadStatus.error, errorMessage: 'No data found in the file'));
        return;
      }

      emit(state.copyWith(status: BulkUploadStatus.validating, rows: rows));

      // Validate all rows
      final validatedRows = await _validationService.validateAllRows(rows);

      // Determine if ready or has errors
      final hasErrors = validatedRows.any((row) => row.hasErrors);
      final newStatus = hasErrors ? BulkUploadStatus.ready : BulkUploadStatus.ready;

      // Sort invalid rows to the top so users can find and fix errors without scrolling.
      validatedRows.sort((a, b) {
        final aOrder = a.hasErrors ? 0 : 1;
        final bOrder = b.hasErrors ? 0 : 1;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        return a.rowIndex.compareTo(b.rowIndex);
      });
      emit(state.copyWith(status: newStatus, rows: validatedRows));
    } catch (e) {
      emit(state.copyWith(status: BulkUploadStatus.error, errorMessage: 'Failed to parse file: ${e.toString()}'));
    }
  }

  /// Handle row field update event
  Future<void> _onUpdateRowField(UpdateRowField event, Emitter<BulkUploadState> emit) async {
    final rowIndex = state.rows.indexWhere((row) => row.rowIndex == event.rowIndex);
    if (rowIndex == -1) return;

    final row = state.rows[rowIndex];
    BulkEmployeeRow updatedRow;

    // Update the specific field
    switch (event.field) {
      case 'englishName':
        updatedRow = row.copyWith(englishName: event.value, isEdited: true);
        break;
      case 'arabicName':
        updatedRow = row.copyWith(arabicName: event.value, isEdited: true);
        break;
      case 'arabicTitle':
        updatedRow = row.copyWith(arabicTitle: event.value, isEdited: true);
        break;
      case 'englishTitle':
        updatedRow = row.copyWith(englishTitle: event.value, isEdited: true);
        break;
      case 'departmentArabic':
        // Also update English department if valid Arabic department
        final englishDept = EmployeeValidationService.getEnglishDepartment(event.value);
        updatedRow = row.copyWith(
          departmentArabic: event.value,
          departmentEnglish: englishDept ?? row.departmentEnglish,
          isEdited: true,
        );
        break;
      case 'departmentEnglish':
        // Also update Arabic department if valid English department
        final arabicDept = EmployeeValidationService.getArabicDepartment(event.value);
        updatedRow = row.copyWith(
          departmentEnglish: event.value,
          departmentArabic: arabicDept ?? row.departmentArabic,
          isEdited: true,
        );
        break;
      case 'employeeCode':
        updatedRow = row.copyWith(employeeCode: event.value, isEdited: true);
        break;
      case 'hireDate':
        updatedRow = row.copyWith(hireDate: event.value, isEdited: true);
        break;
      case 'n1Code':
        updatedRow = row.copyWith(n1Code: event.value, isEdited: true);
        break;
      case 'n2Code':
        updatedRow = row.copyWith(n2Code: event.value, isEdited: true);
        break;
      case 'location':
        updatedRow = row.copyWith(location: event.value, isEdited: true);
        break;
      case 'costCenter':
        updatedRow = row.copyWith(costCenter: event.value, isEdited: true);
        break;
      case 'shiftHours':
        updatedRow = row.copyWith(shiftHours: event.value, isEdited: true);
        break;
      case 'workingDays':
        updatedRow = row.copyWith(workingDays: event.value, isEdited: true);
        break;
      case 'leavesEligibility':
        updatedRow = row.copyWith(leavesEligibility: event.value, isEdited: true);
        break;
      case 'email':
        updatedRow = row.copyWith(email: event.value, isEdited: true);
        break;
      case 'nationalId':
        updatedRow = row.copyWith(nationalId: event.value, isEdited: true);
        break;
      case 'englishNickname':
        updatedRow = row.copyWith(englishNickname: event.value, isEdited: true);
        break;
      case 'arabicNickname':
        updatedRow = row.copyWith(arabicNickname: event.value, isEdited: true);
        break;
      default:
        return;
    }

    // Validation errors are intentionally NOT cleared here.
    // Errors only change when the user presses Revalidate (_onRevalidateRows),
    // which runs a full fresh validateAllRows pass. Optimistic clearing would
    // allow a row to appear valid after editing one wrong value for another,
    // since the new value cannot be verified without async DB queries.

    // Update the rows list
    final newRows = List<BulkEmployeeRow>.from(state.rows);
    newRows[rowIndex] = updatedRow;

    emit(state.copyWith(rows: newRows));
  }

  /// Handle revalidate rows event
  Future<void> _onRevalidateRows(RevalidateRows event, Emitter<BulkUploadState> emit) async {
    emit(state.copyWith(status: BulkUploadStatus.validating));

    try {
      final rawValidatedRows = await _validationService.validateAllRows(state.rows);
      // Clear isEdited so the Revalidate button disappears after a full validation pass.
      final validatedRows = rawValidatedRows.map((row) => row.copyWith(isEdited: false)).toList();
      // Sort invalid rows to the top so users can find and fix errors without scrolling.
      validatedRows.sort((a, b) {
        final aOrder = a.hasErrors ? 0 : 1;
        final bOrder = b.hasErrors ? 0 : 1;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        return a.rowIndex.compareTo(b.rowIndex);
      });
      emit(state.copyWith(status: BulkUploadStatus.ready, rows: validatedRows));
    } catch (e) {
      emit(state.copyWith(status: BulkUploadStatus.error, errorMessage: 'Validation failed: ${e.toString()}'));
    }
  }

  /// Handle submit bulk upload event
  Future<void> _onSubmitBulkUpload(SubmitBulkUpload event, Emitter<BulkUploadState> emit) async {
    if (!state.allValid) {
      emit(state.copyWith(errorMessage: 'Please fix all validation errors before submitting'));
      return;
    }

    emit(
      state.copyWith(
        status: BulkUploadStatus.uploading,
        processedCount: 0,
        successCount: 0,
        failedCount: 0,
        failedEmployees: {},
        clearErrorMessage: true,
      ),
    );

    final failedEmployees = <int, String>{};
    int successCount = 0;

    for (var i = 0; i < state.rows.length; i++) {
      final row = state.rows[i];

      // Update progress
      emit(state.copyWith(processedCount: i + 1));

      try {
        // Create the employee in the database
        final userModel = row.toUserModel();
        // final newEmployee =
        await _usersRepo.addEmployee(userModel);

        // Create auth account
        final authEmail = '${row.employeeCode}@demo.local';
        await _authRepo.createEmployeeAuthAccount('123456', authEmail);

        successCount++;
      } catch (e) {
        failedEmployees[row.rowIndex] = e.toString();
      }
    }

    // Determine final status
    final failedCount = failedEmployees.length;
    final newStatus =
        failedCount == 0
            ? BulkUploadStatus.success
            : successCount == 0
            ? BulkUploadStatus.error
            : BulkUploadStatus.partialSuccess;

    emit(
      state.copyWith(
        status: newStatus,
        successCount: successCount,
        failedCount: failedCount,
        failedEmployees: failedEmployees,
        // Clear the table on full success — partial success keeps rows so user can retry.
        rows: failedCount == 0 ? [] : null,
      ),
    );
  }

  /// Handle retry failed employees event
  Future<void> _onRetryFailedEmployees(RetryFailedEmployees event, Emitter<BulkUploadState> emit) async {
    if (state.failedEmployees.isEmpty) return;

    emit(state.copyWith(status: BulkUploadStatus.uploading, processedCount: 0, clearErrorMessage: true));

    final failedEmployeeIndexes = state.failedEmployees.keys.toList();
    final stillFailed = <int, String>{};
    int newSuccessCount = state.successCount;

    for (var i = 0; i < failedEmployeeIndexes.length; i++) {
      final rowIndex = failedEmployeeIndexes[i];
      final row = state.rows.firstWhere((r) => r.rowIndex == rowIndex);

      emit(state.copyWith(processedCount: i + 1));

      try {
        final userModel = row.toUserModel();
        await _usersRepo.addEmployee(userModel);

        final authEmail = '${row.employeeCode}@demo.local';
        await _authRepo.createEmployeeAuthAccount('123456', authEmail);

        newSuccessCount++;
      } catch (e) {
        stillFailed[rowIndex] = e.toString();
      }
    }

    final newFailedCount = stillFailed.length;
    final newStatus = newFailedCount == 0 ? BulkUploadStatus.success : BulkUploadStatus.partialSuccess;

    emit(
      state.copyWith(
        status: newStatus,
        successCount: newSuccessCount,
        failedCount: newFailedCount,
        failedEmployees: stillFailed,
        // Clear the table on full success — partial success keeps rows so user can retry.
        rows: newFailedCount == 0 ? [] : null,
      ),
    );
  }

  /// Handle reset event
  void _onResetBulkUpload(ResetBulkUpload event, Emitter<BulkUploadState> emit) {
    emit(const BulkUploadState());
  }

  /// Handle remove row event
  void _onRemoveRow(RemoveRow event, Emitter<BulkUploadState> emit) {
    final newRows = state.rows.where((row) => row.rowIndex != event.rowIndex).toList();
    emit(state.copyWith(rows: newRows));
  }

  /// Handle add empty row event
  void _onAddEmptyRow(AddEmptyRow event, Emitter<BulkUploadState> emit) {
    final maxIndex = state.rows.isEmpty ? 0 : state.rows.map((r) => r.rowIndex).reduce((a, b) => a > b ? a : b);
    final newRow = BulkEmployeeRow(rowIndex: maxIndex + 1);
    final newRows = [...state.rows, newRow];
    emit(state.copyWith(rows: newRows));
  }
}
