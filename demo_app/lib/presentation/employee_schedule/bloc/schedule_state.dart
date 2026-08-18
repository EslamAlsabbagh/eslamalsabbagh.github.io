import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/data/models/shift_swap_request_model.dart';
import 'package:hrms_demo/data/models/shift_template_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:flutter/foundation.dart';

enum ScheduleView { week, day, month, live, self }

enum ScheduleViewMode { team, colleagues }

enum ShiftConflictType { approvedLeave, exceedsMaxHours, insufficientRestAfter, insufficientRestBefore }

enum PublishState { draft, publishing, published }

@immutable
class ScheduleFilters {
  final String? department;
  final String? location;
  final TeamScope teamScope;

  const ScheduleFilters({this.department, this.location, this.teamScope = TeamScope.direct});

  ScheduleFilters copyWith({
    String? department,
    String? location,
    TeamScope? teamScope,
    bool clearDepartment = false,
    bool clearLocation = false,
  }) {
    return ScheduleFilters(
      department: clearDepartment ? null : (department ?? this.department),
      location: clearLocation ? null : (location ?? this.location),
      teamScope: teamScope ?? this.teamScope,
    );
  }
}

enum TeamScope { all, direct, indirect }

@immutable
class ScheduleState {
  ScheduleState({
    this.status = Status.initial,
    this.failure,
    this.managerId,
    this.selfUser,
    this.selfSchedule = const {},
    this.nextWeekSelfSchedule = const {},
    this.todaySelfSchedule = const {},
    this.nextWeekTodaySelfSchedule = const {},
    this.schedule = const {},
    this.todaySchedule = const {},
    this.monthSchedule = const {},
    this.monthLeaveKeys = const {},
    this.loadedMonth,
    this.leaveKeys = const {},
    this.leaveBackups = const {},
    this.prevWeekLastDayOvernight = const {},
    this.prevWeekLastDay = const {},
    this.nextWeekFirstDay = const {},
    this.lastWeekShiftCount = -1,
    this.selfLastWeekShiftCount = -1,
    this.allTeam = const [],
    this.filteredTeam = const [],
    this.peers = const [],
    this.peersSchedule = const {},
    this.nextWeekPeersSchedule = const {},
    this.todayPeersSchedule = const {},
    this.nextWeekTodayPeersSchedule = const {},
    this.view = ScheduleView.week,
    DateTime? weekStart,
    this.filters = const ScheduleFilters(),
    this.publishState = PublishState.draft,
    this.swapRequests = const [],
    this.mySwapRequests = const [],
    this.incomingSwapRequests = const [],
    this.declinedSwapRequests = const [],
    this.acceptedIncomingSwapRequests = const [],
    this.processedSwapRequests = const [],
    this.topTemplates = const [],
    this.monthLoading = false,
    this.selectedDayIndex,
    this.viewMode = ScheduleViewMode.team,
    this.monthPeersSchedule = const {},
    this.n1User,
    this.n1Schedule = const {},
    this.n1LeaveKeys = const {},
  }) : weekStart = weekStart ?? _currentWeekStart();

  static DateTime _currentWeekStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day - (now.weekday % 7));
  }

  final Status status;
  final Failure? failure;
  final int? managerId;
  final UserModel? selfUser;
  final Map<String, ScheduleModel> selfSchedule;
  final Map<String, ScheduleModel> nextWeekSelfSchedule;
  final Map<String, ScheduleModel> todaySelfSchedule;
  final Map<String, ScheduleModel> nextWeekTodaySelfSchedule;
  final Map<String, ScheduleModel> schedule;
  final Map<String, ScheduleModel> todaySchedule;
  final Map<String, ScheduleModel> monthSchedule;
  final Map<String, String> monthLeaveKeys;
  final DateTime? loadedMonth;
  final Map<String, String> leaveKeys;
  final Map<String, ScheduleModel> leaveBackups;
  final Map<int, ScheduleModel> prevWeekLastDayOvernight;
  final Map<int, ScheduleModel> prevWeekLastDay;
  final Map<int, ScheduleModel> nextWeekFirstDay;
  final int lastWeekShiftCount;
  // My own shifts last week — gates the self "copy last week" action.
  final int selfLastWeekShiftCount;
  final List<UserModel> allTeam;
  final List<UserModel> filteredTeam;
  final List<UserModel> peers;
  final Map<String, ScheduleModel> peersSchedule;
  final Map<String, ScheduleModel> nextWeekPeersSchedule;
  final Map<String, ScheduleModel> todayPeersSchedule;
  final Map<String, ScheduleModel> nextWeekTodayPeersSchedule;
  final ScheduleView view;
  final DateTime weekStart;
  final ScheduleFilters filters;
  final PublishState publishState;
  final List<ShiftSwapRequestModel> swapRequests;
  final List<ShiftSwapRequestModel> mySwapRequests;
  final List<ShiftSwapRequestModel> incomingSwapRequests;
  final List<ShiftSwapRequestModel> declinedSwapRequests;
  final List<ShiftSwapRequestModel> acceptedIncomingSwapRequests;
  final List<ShiftSwapRequestModel> processedSwapRequests;
  final List<ShiftTemplateModel> topTemplates;
  final bool monthLoading;
  final int? selectedDayIndex;
  final ScheduleViewMode viewMode;
  final Map<String, ScheduleModel> monthPeersSchedule;
  // The current user's N+1 (immediate manager) and their weekly schedule, used to
  // render the pinned comparison row at the top of the colleagues weekly view.
  final UserModel? n1User;
  final Map<String, ScheduleModel> n1Schedule;
  final Map<String, String> n1LeaveKeys;

  bool get hasLastWeekShifts => lastWeekShiftCount > 0;
  bool get hasSelfLastWeekShifts => selfLastWeekShiftCount > 0;

  /// True when the viewed week's own row has at least one day free to receive a
  /// copied shift. Copy skips days that already hold a row (a manager's
  /// "reserved" draft, or my own shift), so a fully-occupied week has no room
  /// to paste into. Leave-only days count as free (no real row to collide with).
  bool get hasFreeSelfDay {
    final me = managerId;
    if (me == null) return false;
    for (int d = 0; d < 7; d++) {
      final s = selfSchedule['$me-$d'];
      if (s == null || s.isLeave) return true;
    }
    return false;
  }

  /// True when copying last week into my own row would actually add at least one
  /// shift: I have copyable source shifts AND the destination week has room.
  bool get canSelfCopyLastWeek => hasSelfLastWeekShifts && hasFreeSelfDay;

  /// True when at least one filtered report has a free day this week to receive
  /// a copied shift — the team-side "room to paste" (negation of the fully
  /// scheduled week). Guarded so an empty team never reads as having room.
  bool get teamHasRoomToCopy => filteredTeam.isNotEmpty && !allWeekCellsFilled;

  /// Manager pinned at the top of the weekly view for comparison.
  /// Team view → me (the N+1 of the listed subordinates); colleagues view → my N+1.
  UserModel? get pinnedManager => viewMode == ScheduleViewMode.colleagues ? n1User : selfUser;

  /// Pinned row's shifts, keyed '${id}-$dayIndex'. Colleagues mode pins my N+1:
  /// read-only, published shifts only (their drafts are internal). Team mode
  /// pins MY OWN row, which is self-editable: published shifts plus my own
  /// drafts (last writer = me). Leave placeholders are isPublished: true, so
  /// approved-leave days still survive.
  // Memoized: computed once per state instance on first access. Safe because the
  // state is immutable (a fresh instance is built on every copyWith), and this
  // is read repeatedly within a single build pass.
  late final Map<String, ScheduleModel> pinnedManagerSchedule = _computePinnedManagerSchedule();
  Map<String, ScheduleModel> _computePinnedManagerSchedule() {
    if (viewMode == ScheduleViewMode.colleagues) {
      return Map.fromEntries(n1Schedule.entries.where((e) => e.value.isPublished));
    }
    return Map.fromEntries(selfSchedule.entries.where((e) => e.value.isPublished || isOwnDraft(e.value)));
  }

  /// Leave keys for the pinned manager row. Team view → self (already in
  /// leaveKeys); colleagues view → the N+1's own leaves.
  Map<String, String> get pinnedManagerLeaveKeys => viewMode == ScheduleViewMode.colleagues ? n1LeaveKeys : leaveKeys;

  /// Render the pinned row only when there is a manager AND they aren't already a
  /// listed row (guards the isSelfOnly case where filteredTeam == [self]).
  bool get showPinnedManagerRow {
    final m = pinnedManager;
    if (m?.id == null) return false;
    return !filteredTeam.any((u) => u.id == m!.id);
  }

  bool get isPastWeek => weekStart.isBefore(_currentWeekStart());

  /// True when the current user has no team and is viewing only their own schedule.
  bool get isSelfOnly => allTeam.isNotEmpty && allTeam.length == 1 && allTeam.first.id == managerId;

  /// True when [s] is a draft on my own row that I wrote (last-writer rule).
  /// These are the only rows an employee may edit or delete; anything the
  /// manager touched (owner != me) or published is locked.
  bool isOwnDraft(ScheduleModel s) => !s.isPublished && !s.isLeave && s.employeeId == managerId && s.owner == managerId;

  /// True when the cell (empty or my own draft) can be edited by me as an
  /// employee. Published shifts, leave days and manager-owned drafts cannot.
  bool canSelfEdit(ScheduleModel? s) => s == null || isOwnDraft(s);

  /// Day indexes on my own row occupied by a draft someone else owns (my
  /// manager is working on them). Rendered as a neutral "reserved" placeholder
  /// — the draft's contents stay manager-internal.
  late final Set<int> reservedSelfDays = _computeReservedSelfDays();
  Set<int> _computeReservedSelfDays() {
    final out = <int>{};
    for (final s in selfSchedule.values) {
      if (!s.isPublished && !s.isLeave && s.employeeId == managerId && s.owner != managerId) {
        out.add(s.dayIndex);
      }
    }
    return out;
  }

  /// Effective schedule map: peers + self when in colleagues mode, team schedule otherwise.
  /// In colleagues mode published shifts are exposed for everyone, plus MY OWN
  /// drafts (self-draft feature) — other people's drafts stay internal.
  late final Map<String, ScheduleModel> effectiveSchedule = _computeEffectiveSchedule();
  Map<String, ScheduleModel> _computeEffectiveSchedule() {
    if (viewMode != ScheduleViewMode.colleagues) return schedule;
    final raw = {...peersSchedule, ...selfSchedule};
    return Map.fromEntries(raw.entries.where((e) => e.value.isPublished || isOwnDraft(e.value)));
  }

  /// Effective today schedule: peers + self when in colleagues mode, team today schedule otherwise.
  /// In colleagues mode published shifts plus my own drafts are exposed.
  late final Map<String, ScheduleModel> effectiveTodaySchedule = _computeEffectiveTodaySchedule();
  Map<String, ScheduleModel> _computeEffectiveTodaySchedule() {
    if (viewMode != ScheduleViewMode.colleagues) return todaySchedule;
    final raw = {...todayPeersSchedule, ...todaySelfSchedule};
    return Map.fromEntries(raw.entries.where((e) => e.value.isPublished || isOwnDraft(e.value)));
  }

  /// Effective month schedule: peer month data when in colleagues mode, team month schedule otherwise.
  /// For non-managers (isSelfOnly) also merges their own monthly data from monthSchedule.
  /// In colleagues mode published shifts plus my own drafts are exposed.
  // Highest-impact memoization: read once per calendar cell (~35-42x) per rebuild.
  late final Map<String, ScheduleModel> effectiveMonthSchedule = _computeEffectiveMonthSchedule();
  Map<String, ScheduleModel> _computeEffectiveMonthSchedule() {
    if (viewMode != ScheduleViewMode.colleagues) return monthSchedule;
    final raw = isSelfOnly ? {...monthPeersSchedule, ...monthSchedule} : monthPeersSchedule;
    return Map.fromEntries(raw.entries.where((e) => e.value.isPublished || isOwnDraft(e.value)));
  }

  /// Colleagues: peers with same N+1 + same department, including self.
  late final List<UserModel> colleaguesTeam = _computeColleaguesTeam();
  List<UserModel> _computeColleaguesTeam() {
    if (selfUser == null) return [];
    final dept = selfUser!.englishDepartment ?? selfUser!.department;
    return [selfUser!, ...peers].where((u) {
      if (dept == null) return true;
      return u.englishDepartment == dept || u.department == dept;
    }).toList();
  }

  /// Returns true if the current user already has an open (awaiting_target / pending)
  /// swap request tied to [shiftId] or targeting their schedule on [date].
  bool hasOpenSwapOnDay(int? shiftId, DateTime date) {
    const openStatuses = {'awaiting_target', 'pending'};
    final seen = <int?>{};
    final all =
        [
          ...mySwapRequests,
          ...incomingSwapRequests,
          ...acceptedIncomingSwapRequests,
          ...declinedSwapRequests,
          ...processedSwapRequests,
        ].where((r) => seen.add(r.id)).toList();

    final outgoingByShiftId = <int, List<ShiftSwapRequestModel>>{};
    for (final r in all) {
      if (r.requesterId == (managerId ?? 0) && r.scheduleId != null) {
        outgoingByShiftId.putIfAbsent(r.scheduleId!, () => []).add(r);
      }
    }

    final outgoing =
        shiftId != null
            ? (outgoingByShiftId[shiftId] ?? const <ShiftSwapRequestModel>[])
            : const <ShiftSwapRequestModel>[];
    if (outgoing.any((r) => openStatuses.contains(r.status))) return true;

    return all.any((r) {
      if (r.targetEmployeeId != (managerId ?? 0)) return false;
      if (!openStatuses.contains(r.status)) return false;
      if (r.scheduleWeekStart == null || r.targetScheduleDayIndex == null) return false;
      final targetDate = r.scheduleWeekStart!.add(Duration(days: r.targetScheduleDayIndex!));
      return targetDate.year == date.year && targetDate.month == date.month && targetDate.day == date.day;
    });
  }

  late final int conflictCount = effectiveSchedule.values.where((s) => s.conflict != null).length;

  late final int draftCount = effectiveSchedule.values.where((s) => !s.isPublished && !s.isLeave).length;

  int get leaveCount => leaveKeys.length;

  /// True when every filteredTeam × 7 cell has an entry in the team schedule.
  /// Approved leave overlays already populate the schedule map, so they count automatically.
  bool get allWeekCellsFilled {
    for (final emp in filteredTeam) {
      if (emp.id == null) continue;
      for (int d = 0; d < 7; d++) {
        if (!schedule.containsKey('${emp.id}-$d')) return false;
      }
    }
    return true;
  }

  /// Number of unfilled cells across filteredTeam × 7.
  late final int emptyCount = _computeEmptyCount();
  int _computeEmptyCount() {
    var count = 0;
    for (final emp in filteredTeam) {
      if (emp.id == null) continue;
      for (int d = 0; d < 7; d++) {
        if (!schedule.containsKey('${emp.id}-$d')) count++;
      }
    }
    return count;
  }

  ScheduleState copyWith({
    Status? status,
    Failure? failure,
    int? managerId,
    UserModel? selfUser,
    Map<String, ScheduleModel>? selfSchedule,
    Map<String, ScheduleModel>? nextWeekSelfSchedule,
    Map<String, ScheduleModel>? todaySelfSchedule,
    Map<String, ScheduleModel>? nextWeekTodaySelfSchedule,
    Map<String, ScheduleModel>? schedule,
    Map<String, ScheduleModel>? todaySchedule,
    Map<String, ScheduleModel>? monthSchedule,
    Map<String, String>? monthLeaveKeys,
    DateTime? loadedMonth,
    Map<String, String>? leaveKeys,
    Map<String, ScheduleModel>? leaveBackups,
    Map<int, ScheduleModel>? prevWeekLastDayOvernight,
    Map<int, ScheduleModel>? prevWeekLastDay,
    Map<int, ScheduleModel>? nextWeekFirstDay,
    int? lastWeekShiftCount,
    int? selfLastWeekShiftCount,
    List<UserModel>? allTeam,
    List<UserModel>? filteredTeam,
    List<UserModel>? peers,
    Map<String, ScheduleModel>? peersSchedule,
    Map<String, ScheduleModel>? nextWeekPeersSchedule,
    Map<String, ScheduleModel>? todayPeersSchedule,
    Map<String, ScheduleModel>? nextWeekTodayPeersSchedule,
    ScheduleView? view,
    DateTime? weekStart,
    ScheduleFilters? filters,
    PublishState? publishState,
    List<ShiftSwapRequestModel>? swapRequests,
    List<ShiftSwapRequestModel>? mySwapRequests,
    List<ShiftSwapRequestModel>? incomingSwapRequests,
    List<ShiftSwapRequestModel>? declinedSwapRequests,
    List<ShiftSwapRequestModel>? acceptedIncomingSwapRequests,
    List<ShiftSwapRequestModel>? processedSwapRequests,
    List<ShiftTemplateModel>? topTemplates,
    bool? monthLoading,
    int? selectedDayIndex,
    bool clearSelectedDayIndex = false,
    ScheduleViewMode? viewMode,
    Map<String, ScheduleModel>? monthPeersSchedule,
    UserModel? n1User,
    Map<String, ScheduleModel>? n1Schedule,
    Map<String, String>? n1LeaveKeys,
  }) {
    return ScheduleState(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      managerId: managerId ?? this.managerId,
      selfUser: selfUser ?? this.selfUser,
      selfSchedule: selfSchedule ?? this.selfSchedule,
      nextWeekSelfSchedule: nextWeekSelfSchedule ?? this.nextWeekSelfSchedule,
      todaySelfSchedule: todaySelfSchedule ?? this.todaySelfSchedule,
      nextWeekTodaySelfSchedule: nextWeekTodaySelfSchedule ?? this.nextWeekTodaySelfSchedule,
      schedule: schedule ?? this.schedule,
      todaySchedule: todaySchedule ?? this.todaySchedule,
      monthSchedule: monthSchedule ?? this.monthSchedule,
      monthLeaveKeys: monthLeaveKeys ?? this.monthLeaveKeys,
      loadedMonth: loadedMonth ?? this.loadedMonth,
      leaveKeys: leaveKeys ?? this.leaveKeys,
      leaveBackups: leaveBackups ?? this.leaveBackups,
      prevWeekLastDayOvernight: prevWeekLastDayOvernight ?? this.prevWeekLastDayOvernight,
      prevWeekLastDay: prevWeekLastDay ?? this.prevWeekLastDay,
      nextWeekFirstDay: nextWeekFirstDay ?? this.nextWeekFirstDay,
      lastWeekShiftCount: lastWeekShiftCount ?? this.lastWeekShiftCount,
      selfLastWeekShiftCount: selfLastWeekShiftCount ?? this.selfLastWeekShiftCount,
      allTeam: allTeam ?? this.allTeam,
      filteredTeam: filteredTeam ?? this.filteredTeam,
      peers: peers ?? this.peers,
      peersSchedule: peersSchedule ?? this.peersSchedule,
      nextWeekPeersSchedule: nextWeekPeersSchedule ?? this.nextWeekPeersSchedule,
      todayPeersSchedule: todayPeersSchedule ?? this.todayPeersSchedule,
      nextWeekTodayPeersSchedule: nextWeekTodayPeersSchedule ?? this.nextWeekTodayPeersSchedule,
      view: view ?? this.view,
      weekStart: weekStart ?? this.weekStart,
      filters: filters ?? this.filters,
      publishState: publishState ?? this.publishState,
      swapRequests: swapRequests ?? this.swapRequests,
      mySwapRequests: mySwapRequests ?? this.mySwapRequests,
      incomingSwapRequests: incomingSwapRequests ?? this.incomingSwapRequests,
      declinedSwapRequests: declinedSwapRequests ?? this.declinedSwapRequests,
      acceptedIncomingSwapRequests: acceptedIncomingSwapRequests ?? this.acceptedIncomingSwapRequests,
      processedSwapRequests: processedSwapRequests ?? this.processedSwapRequests,
      topTemplates: topTemplates ?? this.topTemplates,
      monthLoading: monthLoading ?? this.monthLoading,
      selectedDayIndex: clearSelectedDayIndex ? null : (selectedDayIndex ?? this.selectedDayIndex),
      viewMode: viewMode ?? this.viewMode,
      monthPeersSchedule: monthPeersSchedule ?? this.monthPeersSchedule,
      n1User: n1User ?? this.n1User,
      n1Schedule: n1Schedule ?? this.n1Schedule,
      n1LeaveKeys: n1LeaveKeys ?? this.n1LeaveKeys,
    );
  }
}
