// GENERATED SCAFFOLD - in-memory stand-in for BusinesstripRequestsRepo.
//
// The demo build has no backend. Every member below returns a type-correct
// empty value unless it has been hand-written to read from DemoStore, so a
// screen that touches an unmodelled corner renders empty instead of crashing.

import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/businesstrip_request_model.dart';
import 'package:hrms_demo/data/models/businesstrip_request_row.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_requests_query.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeBusinesstripRequestsRepo implements BusinesstripRequestsRepo {
  FakeBusinesstripRequestsRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  @override
  Future<int> submitBusinesstripRequest(BusinesstripRequestModel request) async => 0;

  @override
  Future<PagedResult<BusinesstripRequestRow>> getBusinesstripRequestsPage( BusinesstripRequestsQuery query, { required int offset, required int limit, }) async => throw UnimplementedError('BusinesstripRequestsRepo.getBusinesstripRequestsPage is not part of the demo dataset.');

  @override
  Future<List<DateTime>> getBusinesstripRequestMonths(BusinesstripRequestScope scope) async => <DateTime>[];

  @override
  Future<bool> hasAnyRequests(BusinesstripRequestScope scope, int userCode) async => false;

  @override
  Future<List<BusinesstripRequestModel>> getMybusinesstripRequests( int userCode, ) async => <BusinesstripRequestModel>[];

  @override
  Future<List<BusinesstripRequestModel>> getRequestsToApprove(int approverCode) async => <BusinesstripRequestModel>[];

  @override
  Future<List<BusinesstripRequestModel>> getProcessedRequests(int approverCode) async => <BusinesstripRequestModel>[];

  @override
  Future<void> approveRequest( int requestId, String currentApprover, int approverCode, { double? transportationFeeAmount, }) async {}

  @override
  Future<void> declineRequest(int requestId, String reason, String currentApprover, int approverCode) async {}

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
