import 'package:hrms_demo/data/models/bulk_employee_row.dart';
import 'package:equatable/equatable.dart';

class BulkUploadState extends Equatable {
  final BulkUploadStatus status;
  final List<BulkEmployeeRow> rows;
  final String? errorMessage;
  final int processedCount;
  final int successCount;
  final int failedCount;
  final Map<int, String> failedEmployees; // rowIndex -> error message
  final String? currentFilePath;

  const BulkUploadState({
    this.status = BulkUploadStatus.initial,
    this.rows = const [],
    this.errorMessage,
    this.processedCount = 0,
    this.successCount = 0,
    this.failedCount = 0,
    this.failedEmployees = const {},
    this.currentFilePath,
  });

  /// Check if all rows are valid
  bool get allValid => rows.every((row) => row.isValid);

  /// Get count of valid rows
  int get validCount => rows.where((row) => row.isValid).length;

  /// Get count of invalid rows
  int get invalidCount => rows.where((row) => row.hasErrors).length;

  /// Get valid rows only
  List<BulkEmployeeRow> get validRows => rows.where((row) => row.isValid).toList();

  /// Get invalid rows only
  List<BulkEmployeeRow> get invalidRows => rows.where((row) => row.hasErrors).toList();

  /// Check if upload is in progress
  bool get isUploading => status == BulkUploadStatus.uploading;

  /// Check if parsing is in progress
  bool get isParsing => status == BulkUploadStatus.parsing;

  /// Check if validating is in progress
  bool get isValidating => status == BulkUploadStatus.validating;

  /// Check if ready to submit
  bool get isReady => status == BulkUploadStatus.ready && allValid;

  /// Check if upload was successful
  bool get isSuccess => status == BulkUploadStatus.success;

  /// Check if upload had partial success
  bool get isPartialSuccess => status == BulkUploadStatus.partialSuccess;

  /// Get upload progress percentage
  double get progressPercentage {
    if (rows.isEmpty) return 0;
    return processedCount / rows.length;
  }

  BulkUploadState copyWith({
    BulkUploadStatus? status,
    List<BulkEmployeeRow>? rows,
    String? errorMessage,
    int? processedCount,
    int? successCount,
    int? failedCount,
    Map<int, String>? failedEmployees,
    String? currentFilePath,
    bool clearErrorMessage = false,
  }) {
    return BulkUploadState(
      status: status ?? this.status,
      rows: rows ?? this.rows,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      processedCount: processedCount ?? this.processedCount,
      successCount: successCount ?? this.successCount,
      failedCount: failedCount ?? this.failedCount,
      failedEmployees: failedEmployees ?? this.failedEmployees,
      currentFilePath: currentFilePath ?? this.currentFilePath,
    );
  }

  @override
  List<Object?> get props => [
    status,
    rows,
    errorMessage,
    processedCount,
    successCount,
    failedCount,
    failedEmployees,
    currentFilePath,
  ];
}
