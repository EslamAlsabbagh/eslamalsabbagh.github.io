import 'package:hrms_demo/data/models/leave_cancellation_request_model.dart';
import 'package:hrms_demo/data/models/leave_request_model.dart';

/// One row of the merged leave / leave-cancellation table.
///
/// The two request kinds are shown interleaved in a single `DataTable`, so the
/// server returns them as one ordered stream (see `v_leave_request_rows` in
/// `supabase/migrations/20260802120000_leave_requests_pagination.sql`).
///
/// This replaces the untyped `List<Map<String, dynamic>>` with `'type'` /
/// `'data'` string keys that the old `_mixedRequests` getter built. Being
/// `sealed` means the row builder's `switch` is checked for exhaustiveness at
/// compile time instead of falling through on a typo.
sealed class UserRequestRow {
  const UserRequestRow();

  /// Primary key *within this row's own table*. Not unique across the merged
  /// stream — a leave request and a cancellation request can share an id, which
  /// is why the server orders on `(row_kind, row_id)`.
  int? get rowId;

  DateTime? get createdAt;
}

final class LeaveRequestRow extends UserRequestRow {
  const LeaveRequestRow(this.request);

  final LeaveRequestModel request;

  @override
  int? get rowId => request.id;

  @override
  DateTime? get createdAt => request.createdAt;
}

final class LeaveCancellationRow extends UserRequestRow {
  const LeaveCancellationRow(this.request);

  final LeaveCancellationRequestModel request;

  @override
  int? get rowId => request.id;

  @override
  DateTime? get createdAt => request.createdAt;
}
