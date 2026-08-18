import 'package:hrms_demo/data/models/businesstrip_cancellation_request_model.dart';
import 'package:hrms_demo/data/models/businesstrip_request_model.dart';

/// One row of the merged business-trip / business-trip-cancellation table.
///
/// The two request kinds are shown interleaved in a single `DataTable`, so the
/// server returns them as one ordered stream (see `_bt_rows_sql` in
/// `supabase/migrations/20260803120000_businesstrip_requests_pagination.sql`).
///
/// This replaces the untyped `List<Map<String, dynamic>>` with `'type'` /
/// `'data'` string keys that the old `_mixedRequests` getter built. Being
/// `sealed` means the row builder's `switch` is checked for exhaustiveness at
/// compile time instead of falling through on a typo.
///
/// Mirrors [UserRequestRow] in `user_request_row.dart`, which does the same job
/// for leave.
sealed class BusinesstripRequestRow {
  const BusinesstripRequestRow();

  /// Primary key *within this row's own table*. Not unique across the merged
  /// stream — a trip request and a cancellation request can share an id, which
  /// is why the server orders on `(row_kind, row_id)`.
  int? get rowId;

  DateTime? get createdAt;
}

final class BusinesstripTripRow extends BusinesstripRequestRow {
  const BusinesstripTripRow(this.request);

  final BusinesstripRequestModel request;

  @override
  int? get rowId => request.id;

  @override
  DateTime? get createdAt => request.createdAt;
}

final class BusinesstripCancellationRow extends BusinesstripRequestRow {
  const BusinesstripCancellationRow(this.request);

  final BusinesstripCancellationRequestModel request;

  @override
  int? get rowId => request.id;

  @override
  DateTime? get createdAt => request.createdAt;
}
