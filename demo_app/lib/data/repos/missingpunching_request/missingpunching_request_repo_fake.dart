// GENERATED SCAFFOLD - in-memory stand-in for MissingpunchingRequestsRepo.
//
// The demo build has no backend. Every member below returns a type-correct
// empty value unless it has been hand-written to read from DemoStore, so a
// screen that touches an unmodelled corner renders empty instead of crashing.

import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/missingpunching_request_model.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunch_requests_query.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunching_request_repo.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeMissingpunchingRequestsRepo implements MissingpunchingRequestsRepo {
  FakeMissingpunchingRequestsRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  @override
  Future<int> submitMissingpunchingRequest(MissingpunchingRequestModel request) async => 0;

  @override
  Future<PagedResult<MissingpunchingRequestModel>> getMissingpunchRequestsPage( MissingpunchRequestsQuery query, { required int offset, required int limit, }) async => throw UnimplementedError('MissingpunchingRequestsRepo.getMissingpunchRequestsPage is not part of the demo dataset.');

  @override
  Future<List<DateTime>> getMissingpunchRequestMonths(MissingpunchRequestScope scope) async => <DateTime>[];

  @override
  Future<bool> hasAnyRequests(MissingpunchRequestScope scope, int userCode) async => false;

  @override
  Future<List<MissingpunchingRequestModel>> getMyMissingpunchingRequests(int userCode) async => <MissingpunchingRequestModel>[];

  @override
  Future<List<MissingpunchingRequestModel>> getRequestsToApprove(int approverCode) async => <MissingpunchingRequestModel>[];

  @override
  Future<List<MissingpunchingRequestModel>> getProcessedRequests(int approverCode) async => <MissingpunchingRequestModel>[];

  @override
  Future<void> approveRequest(int requestId, String approverTitle, int approverCode) async {}

  @override
  Future<void> declineRequest(int requestId, String reason, String currentApprover, int approverCode) async {}

  @override
  Future<List<MissingpunchingRequestModel>> getRequestsByMonth(int userCode, DateTime month) async => <MissingpunchingRequestModel>[];

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
