import 'package:equatable/equatable.dart';

abstract class BulkUploadEvent extends Equatable {
  const BulkUploadEvent();

  @override
  List<Object?> get props => [];
}

/// Event to upload and parse a file (for desktop platforms with file path)
class UploadFile extends BulkUploadEvent {
  final String filePath;

  const UploadFile(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

/// Event to upload and parse a file with bytes (for web platform)
class UploadFileWithBytes extends BulkUploadEvent {
  final String fileName;
  final List<int> bytes;

  const UploadFileWithBytes({required this.fileName, required this.bytes});

  @override
  List<Object?> get props => [fileName, bytes];
}

/// Event to update a specific row's field value
class UpdateRowField extends BulkUploadEvent {
  final int rowIndex;
  final String field;
  final String value;

  const UpdateRowField({required this.rowIndex, required this.field, required this.value});

  @override
  List<Object?> get props => [rowIndex, field, value];
}

/// Event to revalidate all rows after edits
class RevalidateRows extends BulkUploadEvent {
  const RevalidateRows();
}

/// Event to submit all valid employees
class SubmitBulkUpload extends BulkUploadEvent {
  const SubmitBulkUpload();
}

/// Event to retry failed employees only
class RetryFailedEmployees extends BulkUploadEvent {
  const RetryFailedEmployees();
}

/// Event to reset the state
class ResetBulkUpload extends BulkUploadEvent {
  const ResetBulkUpload();
}

/// Event to remove a row from the list
class RemoveRow extends BulkUploadEvent {
  final int rowIndex;

  const RemoveRow(this.rowIndex);

  @override
  List<Object?> get props => [rowIndex];
}

/// Event to add a new empty row
class AddEmptyRow extends BulkUploadEvent {
  const AddEmptyRow();
}
