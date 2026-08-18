// GENERATED SCAFFOLD - in-memory stand-in for OvertimeRequestRepo.
//
// The demo build has no backend. Every member below returns a type-correct
// empty value unless it has been hand-written to read from DemoStore, so a
// screen that touches an unmodelled corner renders empty instead of crashing.

import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/overtime_request_model.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_request_repo.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_requests_query.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeOvertimeRequestRepo implements OvertimeRequestRepo {
  FakeOvertimeRequestRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  @override
  Future<int> submitOvertimeRequest(OvertimeRequestModel request) async => 0;

  @override
  Future<PagedResult<OvertimeRequestModel>> getOvertimeRequestsPage( OvertimeRequestsQuery query, { required int offset, required int limit, }) async => throw UnimplementedError('OvertimeRequestRepo.getOvertimeRequestsPage is not part of the demo dataset.');

  @override
  Future<List<DateTime>> getOvertimeRequestMonths(OvertimeRequestScope scope) async => <DateTime>[];

  @override
  Future<bool> hasAnyRequests(OvertimeRequestScope scope, int userCode) async => false;

  @override
  Future<List<OvertimeRequestModel>> getMyOvertimeRequests(int userCode) async => <OvertimeRequestModel>[];

  @override
  Future<List<OvertimeRequestModel>> getTeamRequests(int userCode) async => <OvertimeRequestModel>[];

  @override
  Future<List<OvertimeRequestModel>> getProcessedRequests(int approverCode) async => <OvertimeRequestModel>[];

  @override
  Future<void> approveRequest(int requestId, String currentApprover, int approverCode) async {}

  @override
  Future<void> declineRequest(int requestId, String reason, int userCode, String currentApprover, int approverCode) async {}

  @override
  Future<List<OvertimeRequestModel>> getRequestsByMonth(int userCode, DateTime month) async => <OvertimeRequestModel>[];

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
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
