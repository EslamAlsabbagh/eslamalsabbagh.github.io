// GENERATED SCAFFOLD - in-memory stand-in for LeaveRequestsRepo.
//
// The demo build has no backend. Every member below returns a type-correct
// empty value unless it has been hand-written to read from DemoStore, so a
// screen that touches an unmodelled corner renders empty instead of crashing.

import 'dart:typed_data';
import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/leave_request_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/models/user_request_row.dart';
import 'package:hrms_demo/data/repos/leave_request/bulk_leave_result.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_requests_query.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeLeaveRequestsRepo implements LeaveRequestsRepo {
  FakeLeaveRequestsRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  @override
  Future<int> submitLeaveRequest(LeaveRequestModel request) async => 0;

  @override
  Future<PagedResult<UserRequestRow>> getLeaveRequestsPage( LeaveRequestsQuery query, { required int offset, required int limit, }) async => throw UnimplementedError('LeaveRequestsRepo.getLeaveRequestsPage is not part of the demo dataset.');

  @override
  Future<List<DateTime>> getLeaveRequestMonths(LeaveRequestScope scope) async => <DateTime>[];

  @override
  Future<bool> hasAnyRequests(LeaveRequestScope scope, int userCode) async => false;

  @override
  Future<List<LeaveRequestModel>> getMyLeaveRequests(int userCode) async => <LeaveRequestModel>[];

  @override
  Future<List<LeaveRequestModel>> getRequestsToApprove(int approverCode) async => <LeaveRequestModel>[];

  @override
  Future<List<LeaveRequestModel>> getProcessedRequests(int approverCode) async => <LeaveRequestModel>[];

  @override
  Future<void> approveRequest(int requestId, String approverTitle, int approverCode) async {}

  @override
  Future<void> declineRequest(int requestId, String reason, String currentApprover, int approverCode) async {}

  @override
  Future<void> uploadSickNote(List<Uint8List> sickNotes, List<String>? sickNoteFileNames, int requestId) async {}

  @override
  Future<List<LeaveRequestModel>> getRequestsByMonth(int userCode, DateTime month) async => <LeaveRequestModel>[];

  @override
  Future<bool> hasMyRequests(int userCode) async => false;

  @override
  Future<bool> hasTeamRequests(int approverCode) async => false;

  @override
  Future<bool> hasProcessedRequests(int approverCode) async => false;

  @override
  Future<void> cancelRequest(int requestId) async {}

  @override
  Future<void> removeRequest(int requestId) async {}

  @override
  Future<void> removeRequestForN1(int requestId) async {}

  @override
  Future<List<int>> submitBulkLeaveRequests({ required List<UserModel> employees, required DateTime dateFrom, required DateTime dateTo, required String leaveType, required double numberOfDays, required int hrApproverCode, }) async => <int>[];

  @override
  Future<BulkLeaveSubmissionResult> submitBulkLeaveRequestsForApproval({ required List<UserModel> employees, required DateTime dateFrom, required DateTime dateTo, required String leaveType, required double numberOfDays, }) async => throw UnimplementedError('LeaveRequestsRepo.submitBulkLeaveRequestsForApproval is not part of the demo dataset.');

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
