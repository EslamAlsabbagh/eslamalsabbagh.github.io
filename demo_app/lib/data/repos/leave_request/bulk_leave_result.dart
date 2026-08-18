import 'package:hrms_demo/data/models/user_model.dart';
import 'package:equatable/equatable.dart';

/// One employee that could not be given a leave request during a bulk
/// normal-cycle submission.
///
/// The normal-cycle path is best-effort: every employee goes through
/// `submit_leave_request`, which runs `validate_leave_request` per employee, so
/// one person being over their annual cap must not abort the whole batch.
/// Rejections are collected here and reported back to HR instead of thrown.
class BulkLeaveFailure extends Equatable {
  final UserModel employee;

  /// Raw server message (e.g. 'Annual leave cap exceeded for this year').
  /// Kept raw so the data layer stays free of AppLocalizations; the UI runs it
  /// through `localizeLeaveError`, which already maps every message the leave
  /// RPCs can raise.
  final String rawError;

  const BulkLeaveFailure({required this.employee, required this.rawError});

  @override
  List<Object?> get props => [employee, rawError];
}

/// Outcome of a best-effort normal-cycle bulk submission.
///
/// [createdIds] holds the `leave_requests.id` of every request that was actually
/// created, in selection order; [failures] holds the employees the server
/// rejected. The ids are what lets the caller attach a medical report to a
/// single-employee submission after the fact.
class BulkLeaveSubmissionResult extends Equatable {
  final List<int> createdIds;
  final List<BulkLeaveFailure> failures;

  const BulkLeaveSubmissionResult({required this.createdIds, required this.failures});

  @override
  List<Object?> get props => [createdIds, failures];
}
