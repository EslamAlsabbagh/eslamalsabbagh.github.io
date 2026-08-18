// GENERATED SCAFFOLD - in-memory stand-in for LeaveCancellationRequestsRepo.
//
// The demo build has no backend. Every member below returns a type-correct
// empty value unless it has been hand-written to read from DemoStore, so a
// screen that touches an unmodelled corner renders empty instead of crashing.

import 'package:hrms_demo/data/models/leave_cancellation_request_model.dart';
import 'package:hrms_demo/data/repos/leave_cancellation_request/leave_cancellation_request_repo.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeLeaveCancellationRequestsRepo implements LeaveCancellationRequestsRepo {
  FakeLeaveCancellationRequestsRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  @override
  Future<int> submitCancellationRequest(LeaveCancellationRequestModel request) async => 0;

  @override
  Future<List<LeaveCancellationRequestModel>> getMyCancellationRequests(int userCode) async => <LeaveCancellationRequestModel>[];

  @override
  Future<List<LeaveCancellationRequestModel>> getCancellationRequestsToApprove(int approverCode) async => <LeaveCancellationRequestModel>[];

  @override
  Future<List<LeaveCancellationRequestModel>> getProcessedCancellationRequests(int approverCode) async => <LeaveCancellationRequestModel>[];

  @override
  Future<void> approveCancellationRequest(int requestId, String approverTitle, int approverCode) async {}

  @override
  Future<void> declineCancellationRequest(int requestId, String reason, String currentApprover, int approverCode) async {}

  @override
  Future<List<LeaveCancellationRequestModel>> getCancellationRequestsByMonth( int userCode, DateTime month, ) async => <LeaveCancellationRequestModel>[];

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
  Future<bool> canRequestCancellation(int originalLeaveRequestId) async => false;

  @override
  Future<bool> hasPendingCancellationRequest(int originalLeaveRequestId) async => false;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
