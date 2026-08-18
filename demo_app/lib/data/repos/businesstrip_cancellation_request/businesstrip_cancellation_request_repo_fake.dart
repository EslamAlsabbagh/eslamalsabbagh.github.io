// GENERATED SCAFFOLD - in-memory stand-in for BusinesstripCancellationRequestsRepo.
//
// The demo build has no backend. Every member below returns a type-correct
// empty value unless it has been hand-written to read from DemoStore, so a
// screen that touches an unmodelled corner renders empty instead of crashing.

import 'package:hrms_demo/data/models/businesstrip_cancellation_request_model.dart';
import 'package:hrms_demo/data/repos/businesstrip_cancellation_request/businesstrip_cancellation_request_repo.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeBusinesstripCancellationRequestsRepo implements BusinesstripCancellationRequestsRepo {
  FakeBusinesstripCancellationRequestsRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  @override
  Future<int> submitCancellationRequest(BusinesstripCancellationRequestModel request) async => 0;

  @override
  Future<List<BusinesstripCancellationRequestModel>> getMyCancellationRequests(int userCode) async => <BusinesstripCancellationRequestModel>[];

  @override
  Future<List<BusinesstripCancellationRequestModel>> getCancellationRequestsToApprove(int approverCode) async => <BusinesstripCancellationRequestModel>[];

  @override
  Future<List<BusinesstripCancellationRequestModel>> getProcessedCancellationRequests(int approverCode) async => <BusinesstripCancellationRequestModel>[];

  @override
  Future<void> approveCancellationRequest(int requestId, String approverTitle, int approverCode) async {}

  @override
  Future<void> declineCancellationRequest(int requestId, String reason, String currentApprover, int approverCode) async {}

  @override
  Future<List<BusinesstripCancellationRequestModel>> getCancellationRequestsByMonth( int userCode, DateTime month, ) async => <BusinesstripCancellationRequestModel>[];

  @override
  Future<bool> hasMyCancellationRequests(int userCode) async => false;

  @override
  Future<bool> hasTeamCancellationRequests(int approverCode) async => false;

  @override
  Future<void> cancelCancellationRequest(int requestId) async {}

  @override
  Future<void> removeCancellationRequest(int requestId) async {}

  @override
  Future<void> removeCancellationRequestForN1(int requestId) async {}

  @override
  Future<bool> canRequestCancellation(int originalBusinesstripRequestId) async => false;

  @override
  Future<bool> hasPendingCancellationRequest(int originalBusinesstripRequestId) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
