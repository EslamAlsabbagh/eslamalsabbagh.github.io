// GENERATED SCAFFOLD - in-memory stand-in for HrLetterRequestRepo.
//
// The demo build has no backend. Every member below returns a type-correct
// empty value unless it has been hand-written to read from DemoStore, so a
// screen that touches an unmodelled corner renders empty instead of crashing.

import 'package:hrms_demo/core/bases/paged_result.dart';
import 'package:hrms_demo/data/models/hr_letter_request_model.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_request_repo.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_requests_query.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeHrLetterRequestRepo implements HrLetterRequestRepo {
  FakeHrLetterRequestRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  @override
  Future<int> submitHrLetterRequest(HrLetterRequestModel request) async => 0;

  @override
  Future<PagedResult<HrLetterRequestModel>> getHrLetterRequestsPage( HrLetterRequestsQuery query, { required int offset, required int limit, }) async => throw UnimplementedError('HrLetterRequestRepo.getHrLetterRequestsPage is not part of the demo dataset.');

  @override
  Future<List<DateTime>> getHrLetterRequestMonths(HrLetterRequestScope scope) async => <DateTime>[];

  @override
  Future<bool> hasAnyRequests(HrLetterRequestScope scope) async => false;

  @override
  Future<List<HrLetterRequestModel>> getMyHrLetterRequests(int employeeCode) async => <HrLetterRequestModel>[];

  @override
  Future<List<HrLetterRequestModel>> getAllHrLetterRequests() async => <HrLetterRequestModel>[];

  @override
  Future<bool> hasMyRequests(int employeeCode) async => false;

  @override
  Future<bool> hasTeamRequests() async => false;

  @override
  Future<bool> hasProcessedRequests() async => false;

  @override
  Future<void> acknowledgeRequest(int requestId, int hrCode) async {}

  @override
  Future<void> completeRequest(int requestId, int hrCode) async {}

  @override
  Future<void> declineRequest(int requestId, int hrCode, String reason) async {}

  @override
  Future<void> cancelRequest(int requestId) async {}

  @override
  Future<void> sendSubmissionNotification(int requestId) async {}

  @override
  Future<void> sendCompletionNotification(int requestId) async {}

  @override
  Future<void> sendDeclineNotification(int requestId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
