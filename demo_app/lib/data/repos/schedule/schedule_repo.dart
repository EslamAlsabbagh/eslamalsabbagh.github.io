import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/data/models/shift_swap_request_model.dart';
import 'package:hrms_demo/data/models/shift_template_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';

abstract class ScheduleRepo {
  Future<List<UserModel>> fetchTeam(int managerId);

  Future<UserModel?> fetchSelf(int userId);

  Future<List<UserModel>> fetchPeers(int n1Id, int excludeUserId);

  Future<Map<String, ScheduleModel>> fetchWeekSchedule(
    List<int> employeeIds,
    DateTime weekStart,
  );

  /// Returns schedules for the calendar month view, keyed as
  /// "employeeId-yyyy-MM-dd" so the same dayIndex from different weeks does
  /// not collide.
  Future<Map<String, ScheduleModel>> fetchMonthSchedule(
    List<int> employeeIds,
    DateTime month,
  );

  Future<void> saveShifts(List<String> keys, ScheduleModel payload);

  /// Upsert one shift template for every (employeeId × dayIndex) pair in a
  /// single backend round-trip.
  Future<void> bulkSaveShifts({
    required List<int> employeeIds,
    required List<int> dayIndices,
    required DateTime weekStart,
    required int managerId,
    required double customStart,
    required double customEnd,
    String? note,
  });

  /// Deletes shifts: archives published ones to `deleted_employee_schedules`,
  /// then hard-deletes all keys from the active table.
  Future<void> deleteShifts(
    List<String> keys,
    DateTime weekStart, {
    required List<ScheduleModel> publishedShifts,
    required int deletedByManagerId,
  });

  /// Publishes exactly the shift rows identified by [shiftKeys] (formatted
  /// as "empId-dayIdx") for the given week. Returns the number of rows the
  /// RPC actually flipped, so the caller can detect under-counts.
  Future<int> publishWeek(
    List<String> shiftKeys,
    DateTime weekStart, {
    List<int>? notifyIds,
  });

  /// Copies last week's shifts into [weekStart] as drafts. [createdBy] stamps
  /// the new rows' owner (last-writer rule). When [selfId] is among the
  /// targets, that row gets special handling: source drafts owned by someone
  /// else are skipped (they are manager-internal) and the copies are refiled
  /// under [selfManagerId] (the user's N+1) so the employee self-draft RLS
  /// policy accepts them.
  Future<void> copyLastWeek(
    List<int> employeeIds,
    DateTime weekStart, {
    required int createdBy,
    int? selfId,
    int? selfManagerId,
  });

  Future<List<ShiftSwapRequestModel>> fetchSwapRequests(List<int> employeeIds);

  Future<ShiftSwapRequestModel> submitSwapRequest(ShiftSwapRequestModel request);

  Future<List<ShiftSwapRequestModel>> fetchMySwapRequests(int requesterId);

  Future<List<ShiftSwapRequestModel>> fetchIncomingSwapRequests(int targetEmployeeId);

  Future<void> approveSwap(int id);

  Future<void> declineSwap(int id);

  Future<void> acceptSwapAsTarget(int id);

  Future<void> declineSwapAsTarget(int id);

  Future<void> cancelSwapRequest(int id);

  Future<List<ShiftSwapRequestModel>> fetchMyDeclinedSwapRequests(int requesterId);

  Future<List<ShiftSwapRequestModel>> fetchAcceptedSwapRequestsAsTarget(int targetEmployeeId);

  Future<List<ShiftSwapRequestModel>> fetchProcessedSwapRequests(int userId);

  Future<int> countAcceptedSwapRequestsAsTarget(int targetEmployeeId);

  Future<int> countMyRecentlyProcessedSwapRequests(int userId);

  /// Returns a map of key ("empId-dayIndex") → leaveType for approved leaves
  Future<Map<String, String>> fetchLeaveOverlay(
    List<int> employeeIds,
    DateTime weekStart,
  );

  /// Returns approved leaves for the calendar month view, keyed as
  /// "employeeId-yyyy-MM-dd".
  Future<Map<String, String>> fetchMonthLeaveOverlay(
    List<int> employeeIds,
    DateTime month,
  );

  Future<int> fetchLastWeekShiftCount(List<int> employeeIds, DateTime weekStart);

  /// Last week's shift count for [selfId]'s own row, restricted to rows the
  /// self-copy will actually reproduce: published shifts and drafts the user
  /// owns. A manager's private ("reserved") drafts on this row are excluded —
  /// copyLastWeek skips them, so they must not inflate the "shifts to copy"
  /// count shown to the user.
  Future<int> fetchSelfLastWeekCopyableCount(int selfId, DateTime weekStart);

  /// Number of DISTINCT employees in [employeeIds] that have at least one
  /// non-removed shift last week — i.e. employees the copy will actually
  /// reproduce shifts for (not the whole team size).
  Future<int> fetchLastWeekEmployeeCount(List<int> employeeIds, DateTime weekStart);

  /// Returns overnight shifts (customEnd < customStart) from day 6 of the
  /// previous week, keyed by employeeId — used for carryover on day 0.
  Future<Map<int, ScheduleModel>> fetchPrevWeekLastDayOvernight(List<int> employeeIds, DateTime weekStart);

  /// Returns all shifts for a single day (weekStart + dayIndex), keyed by
  /// employeeId — used for cross-week boundary conflict detection.
  Future<Map<int, ScheduleModel>> fetchWeekDaySchedule(
    List<int> employeeIds,
    DateTime weekStart,
    int dayIndex,
  );

  Future<List<ShiftTemplateModel>> fetchTopTemplates(int managerId);

  Future<ShiftTemplateModel> saveTemplate(ShiftTemplateModel template);

  Future<void> incrementTemplateUse(int templateId);

  Future<void> deleteTemplate(int templateId);

  Future<int> countPendingSwapRequests(int managerId);

  Future<int> countMyInProcessSwapRequests(int requesterId);

  Future<int> countIncomingSwapRequests(int targetEmployeeId);
}
