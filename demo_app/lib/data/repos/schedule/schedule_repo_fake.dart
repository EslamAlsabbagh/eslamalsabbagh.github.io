// GENERATED SCAFFOLD - in-memory stand-in for ScheduleRepo.
//
// The demo build has no backend. Every member below returns a type-correct
// empty value unless it has been hand-written to read from DemoStore, so a
// screen that touches an unmodelled corner renders empty instead of crashing.

import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/data/models/shift_swap_request_model.dart';
import 'package:hrms_demo/data/models/shift_template_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/repos/schedule/schedule_repo.dart';
import 'package:hrms_demo/demo/demo_store.dart';

class FakeScheduleRepo implements ScheduleRepo {
  FakeScheduleRepo([DemoStore? store]) : store = store ?? DemoStore.instance;

  final DemoStore store;

  @override
  Future<List<UserModel>> fetchTeam(int managerId) async => <UserModel>[];

  @override
  Future<UserModel?> fetchSelf(int userId) async => null;

  @override
  Future<List<UserModel>> fetchPeers(int n1Id, int excludeUserId) async => <UserModel>[];

  @override
  Future<Map<String, ScheduleModel>> fetchWeekSchedule( List<int> employeeIds, DateTime weekStart, ) async => <String, ScheduleModel>{};

  @override
  Future<Map<String, ScheduleModel>> fetchMonthSchedule( List<int> employeeIds, DateTime month, ) async => <String, ScheduleModel>{};

  @override
  Future<void> saveShifts(List<String> keys, ScheduleModel payload) async {}

  @override
  Future<void> bulkSaveShifts({ required List<int> employeeIds, required List<int> dayIndices, required DateTime weekStart, required int managerId, required double customStart, required double customEnd, String? note, }) async {}

  @override
  Future<void> deleteShifts( List<String> keys, DateTime weekStart, { required List<ScheduleModel> publishedShifts, required int deletedByManagerId, }) async {}

  @override
  Future<int> publishWeek( List<String> shiftKeys, DateTime weekStart, { List<int>? notifyIds, }) async => 0;

  @override
  Future<void> copyLastWeek( List<int> employeeIds, DateTime weekStart, { required int createdBy, int? selfId, int? selfManagerId, }) async {}

  @override
  Future<List<ShiftSwapRequestModel>> fetchSwapRequests(List<int> employeeIds) async => <ShiftSwapRequestModel>[];

  @override
  Future<ShiftSwapRequestModel> submitSwapRequest(ShiftSwapRequestModel request) async => throw UnimplementedError('ScheduleRepo.submitSwapRequest is not part of the demo dataset.');

  @override
  Future<List<ShiftSwapRequestModel>> fetchMySwapRequests(int requesterId) async => <ShiftSwapRequestModel>[];

  @override
  Future<List<ShiftSwapRequestModel>> fetchIncomingSwapRequests(int targetEmployeeId) async => <ShiftSwapRequestModel>[];

  @override
  Future<void> approveSwap(int id) async {}

  @override
  Future<void> declineSwap(int id) async {}

  @override
  Future<void> acceptSwapAsTarget(int id) async {}

  @override
  Future<void> declineSwapAsTarget(int id) async {}

  @override
  Future<void> cancelSwapRequest(int id) async {}

  @override
  Future<List<ShiftSwapRequestModel>> fetchMyDeclinedSwapRequests(int requesterId) async => <ShiftSwapRequestModel>[];

  @override
  Future<List<ShiftSwapRequestModel>> fetchAcceptedSwapRequestsAsTarget(int targetEmployeeId) async => <ShiftSwapRequestModel>[];

  @override
  Future<List<ShiftSwapRequestModel>> fetchProcessedSwapRequests(int userId) async => <ShiftSwapRequestModel>[];

  @override
  Future<int> countAcceptedSwapRequestsAsTarget(int targetEmployeeId) async => 0;

  @override
  Future<int> countMyRecentlyProcessedSwapRequests(int userId) async => 0;

  @override
  Future<Map<String, String>> fetchLeaveOverlay( List<int> employeeIds, DateTime weekStart, ) async => <String, String>{};

  @override
  Future<Map<String, String>> fetchMonthLeaveOverlay( List<int> employeeIds, DateTime month, ) async => <String, String>{};

  @override
  Future<int> fetchLastWeekShiftCount(List<int> employeeIds, DateTime weekStart) async => 0;

  @override
  Future<int> fetchSelfLastWeekCopyableCount(int selfId, DateTime weekStart) async => 0;

  @override
  Future<int> fetchLastWeekEmployeeCount(List<int> employeeIds, DateTime weekStart) async => 0;

  @override
  Future<Map<int, ScheduleModel>> fetchPrevWeekLastDayOvernight(List<int> employeeIds, DateTime weekStart) async => <int, ScheduleModel>{};

  @override
  Future<Map<int, ScheduleModel>> fetchWeekDaySchedule( List<int> employeeIds, DateTime weekStart, int dayIndex, ) async => <int, ScheduleModel>{};

  @override
  Future<List<ShiftTemplateModel>> fetchTopTemplates(int managerId) async => <ShiftTemplateModel>[];

  @override
  Future<ShiftTemplateModel> saveTemplate(ShiftTemplateModel template) async => throw UnimplementedError('ScheduleRepo.saveTemplate is not part of the demo dataset.');

  @override
  Future<void> incrementTemplateUse(int templateId) async {}

  @override
  Future<void> deleteTemplate(int templateId) async {}

  @override
  Future<int> countPendingSwapRequests(int managerId) async => 0;

  @override
  Future<int> countMyInProcessSwapRequests(int requesterId) async => 0;

  @override
  Future<int> countIncomingSwapRequests(int targetEmployeeId) async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
