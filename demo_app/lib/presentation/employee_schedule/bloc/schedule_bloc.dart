import 'dart:async';

import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/models/schedule_model.dart';
import 'package:hrms_demo/data/models/shift_swap_request_model.dart';
import 'package:hrms_demo/data/models/shift_template_model.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/repos/schedule/schedule_repo.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_event.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

DateTime _shiftDateTime(DateTime weekDay, double hour, {bool nextDay = false}) {
  final h = hour.floor();
  final m = ((hour - h) * 60).round();
  final base = DateTime(weekDay.year, weekDay.month, weekDay.day, h, m);
  return nextDay ? base.add(const Duration(days: 1)) : base;
}

class _WeekCache {
  final Map<String, ScheduleModel> schedule;
  final Map<String, String> leaveKeys;
  final Map<String, ScheduleModel> leaveBackups;
  final Map<String, ScheduleModel> selfSchedule;
  final Map<String, ScheduleModel> peersSchedule;
  final Map<String, ScheduleModel> n1Schedule;
  final Map<String, String> n1LeaveKeys;
  final Map<String, ScheduleModel> nextWeekSelfSchedule;
  final Map<String, ScheduleModel> nextWeekPeersSchedule;
  final Map<int, ScheduleModel> prevOvernight;
  final Map<int, ScheduleModel> prevWeekLastDay;
  final Map<int, ScheduleModel> nextWeekFirstDay;
  final int lastWeekShiftCount;
  final int selfLastWeekShiftCount;
  final PublishState publishState;
  // Non-null only when this week's month differs from the previously loaded month
  final Map<String, ScheduleModel>? monthSchedule;
  final Map<String, String>? monthLeaveKeys;
  final DateTime? loadedMonth;

  const _WeekCache({
    required this.schedule,
    required this.leaveKeys,
    required this.leaveBackups,
    required this.selfSchedule,
    required this.peersSchedule,
    required this.n1Schedule,
    required this.n1LeaveKeys,
    required this.nextWeekSelfSchedule,
    required this.nextWeekPeersSchedule,
    required this.prevOvernight,
    required this.prevWeekLastDay,
    required this.nextWeekFirstDay,
    required this.lastWeekShiftCount,
    required this.selfLastWeekShiftCount,
    required this.publishState,
    this.monthSchedule,
    this.monthLeaveKeys,
    this.loadedMonth,
  });
}

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  ScheduleBloc(this._repo) : super(ScheduleState()) {
    on<LoadSchedule>(_onLoad);
    on<ChangeWeek>(_onChangeWeek);
    on<ChangeMonth>(_onChangeMonth);
    on<ChangeView>(_onChangeView);
    on<ChangeFilters>(_onChangeFilters);
    on<SaveShift>(_onSaveShift);
    on<DeleteShift>(_onDeleteShift);
    on<PublishWeek>(_onPublishWeek);
    on<CopyLastWeek>(_onCopyLastWeek);
    on<ApproveSwap>(_onApproveSwap);
    on<DeclineSwap>(_onDeclineSwap);
    on<DeleteTemplate>(_onDeleteTemplate);
    on<SubmitSwapRequest>(_onSubmitSwapRequest);
    on<AcceptSwapAsTarget>(_onAcceptSwapAsTarget);
    on<DeclineSwapAsTarget>(_onDeclineSwapAsTarget);
    on<CancelSwapRequest>(_onCancelSwapRequest);
    on<BulkAssignShifts>(_onBulkAssignShifts);
    on<ChangeViewMode>(_onChangeViewMode);
  }

  final ScheduleRepo _repo;
  final Map<DateTime, _WeekCache> _weekCache = {};
  static const int _maxCacheSize = 10;

  // Tail of the pending-writes chain. Each mutating handler links its DB write
  // onto this chain so that PublishWeek can await the entire backlog before
  // calling publish_week. Without this, optimistic UI lets the user click
  // Publish while a bulk-save is still in flight — the RPC then misses the
  // not-yet-inserted rows and the user sees a "partial publish".
  Future<void>? _pendingWrites;

  Future<T> _trackWrite<T>(Future<T> Function() op) async {
    final prev = _pendingWrites;
    final completer = Completer<void>();
    _pendingWrites = completer.future;
    try {
      if (prev != null) {
        try {
          await prev;
        } catch (_) {
          /* prior write's error already handled by its own handler */
        }
      }
      return await op();
    } finally {
      completer.complete();
      if (identical(_pendingWrites, completer.future)) {
        _pendingWrites = null;
      }
    }
  }

  /// Exposed so the UI can disable the Publish button while writes are queued.
  bool get hasPendingWrites => _pendingWrites != null;

  Future<void> _onLoad(LoadSchedule event, Emitter<ScheduleState> emit) async {
    emit(state.copyWith(status: Status.loading, weekStart: event.weekStart));
    try {
      final mid = event.managerId;

      // ── Wave A: team + own record concurrently ──────────────────────────────
      final teamF = _repo.fetchTeam(mid);
      final selfF = _repo.fetchSelf(mid);
      var team = await teamF;
      final selfFetched = await selfF;
      // Non-manager: no reports — fall back to the user's own record so SelfView renders
      if (team.isEmpty && selfFetched != null) team = [selfFetched];
      final isSelfOnly = team.length == 1 && team.first.id == mid;
      final selfUser = isSelfOnly ? team.first : selfFetched;
      final n1Id = selfUser?.n1;

      // ── Wave B: peers + N+1 user concurrently (both keyed on n1Id) ──────────
      final peersF = n1Id != null ? _repo.fetchPeers(n1Id, mid) : Future.value(<UserModel>[]);
      final n1UserF = n1Id != null ? _repo.fetchSelf(n1Id) : Future<UserModel?>.value(null);
      final peers = await peersF;
      final n1User = await n1UserF;

      final teamIds = team.map((e) => e.id!).toList();
      final peerIds = peers.map((p) => p.id!).toList();
      final todayWeekStart = _weekStartOf(DateTime.now());
      final sameToday = _sameDate(event.weekStart, todayWeekStart);
      final month = _monthOf(event.weekStart);
      final eventNextWeek = event.weekStart.add(const Duration(days: 7));
      final todayNextWeek = todayWeekStart.add(const Duration(days: 7));
      final leaveIds = {mid, ...teamIds, ...peerIds}.toList();

      // filteredTeam is a pure local derivation (no fetch) — compute it now so the
      // "shifts to copy" count fetch can join the parallel wave below.
      final List<UserModel> filtered;
      if (isSelfOnly && selfUser != null) {
        final dept = selfUser.englishDepartment ?? selfUser.department;
        filtered =
            <UserModel>[selfUser, ...peers].where((u) {
              if (dept == null) return true;
              return u.englishDepartment == dept || u.department == dept;
            }).toList();
      } else {
        filtered = _applyFilters(team, state.filters, mid);
      }
      final filteredIds = filtered.map((e) => e.id!).toList();
      // Non-managers start in colleagues mode — pre-fetch their colleagues' monthly data
      final colleagueMonthIds = isSelfOnly ? <int>[mid, ...peerIds] : <int>[];

      // ── Wave C: every remaining read is independent — fire concurrently ─────
      final scheduleF = _repo.fetchWeekSchedule(teamIds, event.weekStart);
      final todayScheduleF = sameToday ? null : _repo.fetchWeekSchedule(teamIds, todayWeekStart);
      final selfScheduleF = isSelfOnly ? null : _repo.fetchWeekSchedule([mid], event.weekStart);
      final todaySelfScheduleF = sameToday ? null : _repo.fetchWeekSchedule([mid], todayWeekStart);
      final leaveF = _repo.fetchLeaveOverlay(leaveIds, event.weekStart);
      final todaySelfLeaveF = sameToday ? null : _repo.fetchLeaveOverlay([mid], todayWeekStart);
      final nextWeekSelfLeaveF = _repo.fetchLeaveOverlay([mid], todayNextWeek);
      final monthScheduleF = _repo.fetchMonthSchedule(teamIds, month);
      final monthLeaveF = _repo.fetchMonthLeaveOverlay(teamIds, month);
      final swapsF = _repo.fetchSwapRequests(teamIds);
      final nextWeekSelfF = _repo.fetchWeekSchedule([mid], eventNextWeek);
      final nextWeekTodaySelfF = sameToday ? null : _repo.fetchWeekSchedule([mid], todayNextWeek);
      final mySwapsF = _repo.fetchMySwapRequests(mid);
      final incomingSwapsF = _repo.fetchIncomingSwapRequests(mid);
      final declinedSwapsF = _repo.fetchMyDeclinedSwapRequests(mid);
      final acceptedIncomingF = _repo.fetchAcceptedSwapRequestsAsTarget(mid);
      final processedSwapsF = _repo.fetchProcessedSwapRequests(mid);
      final peersScheduleF = peerIds.isNotEmpty ? _repo.fetchWeekSchedule(peerIds, event.weekStart) : null;
      final n1DataF = _fetchN1Schedule(n1Id, mid, event.weekStart);
      final nextWeekPeersF = peerIds.isNotEmpty ? _repo.fetchWeekSchedule(peerIds, eventNextWeek) : null;
      final todayPeersF = (peerIds.isNotEmpty && !sameToday) ? _repo.fetchWeekSchedule(peerIds, todayWeekStart) : null;
      final nextWeekTodayPeersF =
          (peerIds.isNotEmpty && !sameToday) ? _repo.fetchWeekSchedule(peerIds, todayNextWeek) : null;
      final peerTodayLeaveF =
          (peerIds.isNotEmpty && !sameToday) ? _repo.fetchLeaveOverlay(peerIds, todayWeekStart) : null;
      final peerNextWeekLeaveF = peerIds.isNotEmpty ? _repo.fetchLeaveOverlay(peerIds, todayNextWeek) : null;
      final colleagueMonthF = colleagueMonthIds.isNotEmpty ? _repo.fetchMonthSchedule(colleagueMonthIds, month) : null;
      final templatesF = _repo.fetchTopTemplates(mid);
      final lastWeekCountF = _repo.fetchLastWeekShiftCount(filteredIds, event.weekStart);
      final selfLastWeekCountF = _repo.fetchSelfLastWeekCopyableCount(mid, event.weekStart);
      final prevOvernightF = _repo.fetchPrevWeekLastDayOvernight(teamIds, event.weekStart);
      final prevWeekLastDayF = _repo.fetchWeekDaySchedule(
        teamIds,
        event.weekStart.subtract(const Duration(days: 7)),
        6,
      );
      final nextWeekFirstDayF = _repo.fetchWeekDaySchedule(teamIds, eventNextWeek, 0);

      // One join point: Future.wait attaches an error handler to every future, so
      // a sibling failure surfaces here (→ the catch below) rather than becoming
      // an unhandled async error. The typed awaits afterwards are instant.
      await Future.wait<dynamic>([
        scheduleF,
        leaveF,
        nextWeekSelfLeaveF,
        monthScheduleF,
        monthLeaveF,
        swapsF,
        nextWeekSelfF,
        mySwapsF,
        incomingSwapsF,
        declinedSwapsF,
        acceptedIncomingF,
        processedSwapsF,
        n1DataF,
        templatesF,
        lastWeekCountF,
        selfLastWeekCountF,
        prevOvernightF,
        prevWeekLastDayF,
        nextWeekFirstDayF,
        if (todayScheduleF != null) todayScheduleF,
        if (selfScheduleF != null) selfScheduleF,
        if (todaySelfScheduleF != null) todaySelfScheduleF,
        if (todaySelfLeaveF != null) todaySelfLeaveF,
        if (nextWeekTodaySelfF != null) nextWeekTodaySelfF,
        if (peersScheduleF != null) peersScheduleF,
        if (nextWeekPeersF != null) nextWeekPeersF,
        if (todayPeersF != null) todayPeersF,
        if (nextWeekTodayPeersF != null) nextWeekTodayPeersF,
        if (peerTodayLeaveF != null) peerTodayLeaveF,
        if (peerNextWeekLeaveF != null) peerNextWeekLeaveF,
        if (colleagueMonthF != null) colleagueMonthF,
      ]);

      final scheduleMap = await scheduleF;
      final leaveKeys = await leaveF;
      final todayScheduleMap = sameToday ? scheduleMap : await todayScheduleF!;
      final selfScheduleMap = isSelfOnly ? scheduleMap : await selfScheduleF!;
      final todaySelfScheduleMap = sameToday ? selfScheduleMap : await todaySelfScheduleF!;
      final todaySelfLeaveKeys = sameToday ? _scopedLeaveKeys(leaveKeys, {mid}) : await todaySelfLeaveF!;
      final nextWeekSelfLeaveKeys = await nextWeekSelfLeaveF;
      final monthScheduleMap = await monthScheduleF;
      final monthLeaveKeys = await monthLeaveF;
      final swaps = await swapsF;
      final nextWeekSelfScheduleMap = await nextWeekSelfF;
      final nextWeekTodaySelfScheduleMap = sameToday ? nextWeekSelfScheduleMap : await nextWeekTodaySelfF!;
      final mySwaps = await mySwapsF;
      final incomingSwaps = await incomingSwapsF;
      final declinedSwaps = await declinedSwapsF;
      final acceptedIncoming = await acceptedIncomingF;
      final processedSwaps = await processedSwapsF;
      final peersScheduleMap = peersScheduleF != null ? await peersScheduleF : <String, ScheduleModel>{};
      final n1Data = await n1DataF;
      final nextWeekPeersScheduleMap = nextWeekPeersF != null ? await nextWeekPeersF : <String, ScheduleModel>{};
      final todayPeersScheduleMap =
          peerIds.isEmpty ? <String, ScheduleModel>{} : (sameToday ? peersScheduleMap : await todayPeersF!);
      final nextWeekTodayPeersScheduleMap =
          peerIds.isEmpty
              ? <String, ScheduleModel>{}
              : (sameToday ? nextWeekPeersScheduleMap : await nextWeekTodayPeersF!);
      final teamScopedLeaveKeys = _scopedLeaveKeys(leaveKeys, teamIds.toSet());
      final peerScopedLeaveKeys = _scopedLeaveKeys(leaveKeys, peerIds.toSet());
      final peerTodayLeaveKeys =
          peerIds.isEmpty ? <String, String>{} : (sameToday ? peerScopedLeaveKeys : await peerTodayLeaveF!);
      final peerNextWeekLeaveKeys = peerNextWeekLeaveF != null ? await peerNextWeekLeaveF : <String, String>{};
      final colleagueMonthMap = colleagueMonthF != null ? await colleagueMonthF : <String, ScheduleModel>{};
      final templates = await templatesF;
      final lastWeekCount = await lastWeekCountF;
      final selfLastWeekCount = await selfLastWeekCountF;
      final prevOvernight = await prevOvernightF;
      final prevWeekLastDay = await prevWeekLastDayF;
      final nextWeekFirstDay = await nextWeekFirstDayF;

      final peersScheduleOverlaid = _applyConflicts(
        _applyLeaveOverlay(peersScheduleMap, peerScopedLeaveKeys, [], mid, event.weekStart),
        peerScopedLeaveKeys,
      );
      final todayPeersScheduleOverlaid = _applyConflicts(
        _applyLeaveOverlay(todayPeersScheduleMap, peerTodayLeaveKeys, [], mid, todayWeekStart),
        peerTodayLeaveKeys,
      );
      final nextWeekTodayPeersScheduleOverlaid = _applyConflicts(
        _applyLeaveOverlay(nextWeekTodayPeersScheduleMap, peerNextWeekLeaveKeys, [], mid, todayNextWeek),
        peerNextWeekLeaveKeys,
      );

      final leaveBackups = _buildLeaveBackups(scheduleMap, teamScopedLeaveKeys);
      final overlaid = _applyLeaveOverlay(scheduleMap, teamScopedLeaveKeys, team, event.managerId, event.weekStart);
      final schedule = _applyConflicts(
        overlaid,
        teamScopedLeaveKeys,
        prevWeekLastDay: prevWeekLastDay,
        nextWeekFirstDay: nextWeekFirstDay,
      );
      final selfScheduleOverlaid =
          isSelfOnly
              ? overlaid
              : _applyLeaveOverlay(
                selfScheduleMap,
                _scopedLeaveKeys(leaveKeys, {event.managerId}),
                [],
                event.managerId,
                event.weekStart,
              );
      final monthSchedule = _applyMonthLeaveOverlay(monthScheduleMap, monthLeaveKeys, team, event.managerId);
      final todaySelfOverlaid = _applyLeaveOverlay(
        todaySelfScheduleMap,
        todaySelfLeaveKeys,
        [],
        event.managerId,
        todayWeekStart,
      );
      final todaySelfWithConflicts = _applyConflicts(todaySelfOverlaid, todaySelfLeaveKeys);
      final nextWeekSelfOverlaid = _applyLeaveOverlay(
        nextWeekTodaySelfScheduleMap,
        nextWeekSelfLeaveKeys,
        [],
        event.managerId,
        todayWeekStart.add(const Duration(days: 7)),
      );
      final nextWeekTodaySelfWithConflicts = _applyConflicts(nextWeekSelfOverlaid, nextWeekSelfLeaveKeys);

      emit(
        state.copyWith(
          status: Status.success,
          managerId: event.managerId,
          selfUser: selfUser,
          selfSchedule: selfScheduleOverlaid,
          nextWeekSelfSchedule: nextWeekSelfScheduleMap,
          todaySelfSchedule: todaySelfWithConflicts,
          nextWeekTodaySelfSchedule: nextWeekTodaySelfWithConflicts,
          mySwapRequests: mySwaps,
          incomingSwapRequests: incomingSwaps,
          declinedSwapRequests: declinedSwaps,
          acceptedIncomingSwapRequests: acceptedIncoming,
          processedSwapRequests: processedSwaps,
          peers: peers,
          peersSchedule: peersScheduleOverlaid,
          nextWeekPeersSchedule: nextWeekPeersScheduleMap,
          todayPeersSchedule: todayPeersScheduleOverlaid,
          nextWeekTodayPeersSchedule: nextWeekTodayPeersScheduleOverlaid,
          allTeam: team,
          filteredTeam: filtered,
          schedule: schedule,
          todaySchedule: todayScheduleMap,
          monthSchedule: monthSchedule,
          monthLeaveKeys: monthLeaveKeys,
          loadedMonth: month,
          leaveKeys: leaveKeys,
          leaveBackups: leaveBackups,
          prevWeekLastDayOvernight: prevOvernight,
          prevWeekLastDay: prevWeekLastDay,
          nextWeekFirstDay: nextWeekFirstDay,
          lastWeekShiftCount: lastWeekCount,
          selfLastWeekShiftCount: selfLastWeekCount,
          swapRequests: swaps,
          topTemplates: templates,
          weekStart: event.weekStart,
          publishState: _derivePublishState(schedule),
          viewMode: isSelfOnly ? ScheduleViewMode.colleagues : ScheduleViewMode.team,
          monthPeersSchedule: colleagueMonthMap,
          n1User: n1User,
          n1Schedule: n1Data.schedule,
          n1LeaveKeys: n1Data.leaveKeys,
        ),
      );
      _prefetchAdjacent(event.weekStart);
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  /// Fetches and overlays the N+1 manager's weekly schedule for the pinned
  /// comparison row, plus the manager's own leave keys (so the row can show the
  /// leave annotation on shift+leave days). Returns empty maps when no N+1.
  Future<({Map<String, ScheduleModel> schedule, Map<String, String> leaveKeys})> _fetchN1Schedule(
    int? n1Id,
    int managerId,
    DateTime weekStart,
  ) async {
    if (n1Id == null) {
      return (schedule: <String, ScheduleModel>{}, leaveKeys: <String, String>{});
    }
    final scheduleMap = await _repo.fetchWeekSchedule([n1Id], weekStart);
    final leaveKeys = await _repo.fetchLeaveOverlay([n1Id], weekStart);
    final overlaid = _applyConflicts(_applyLeaveOverlay(scheduleMap, leaveKeys, [], managerId, weekStart), leaveKeys);
    return (schedule: overlaid, leaveKeys: leaveKeys);
  }

  Future<void> _onChangeWeek(ChangeWeek event, Emitter<ScheduleState> emit) async {
    if (state.managerId == null) return;
    final managerId = state.managerId!;
    final cached = _weekCache[event.weekStart];
    if (cached != null) {
      final targetMonth = _monthOf(event.weekStart);
      final needsMonthUpdate = cached.monthSchedule == null && targetMonth != state.loadedMonth;
      emit(
        state.copyWith(
          status: Status.success,
          weekStart: event.weekStart,
          schedule: cached.schedule,
          leaveKeys: cached.leaveKeys,
          leaveBackups: cached.leaveBackups,
          selfSchedule: cached.selfSchedule,
          peersSchedule: cached.peersSchedule,
          n1Schedule: cached.n1Schedule,
          n1LeaveKeys: cached.n1LeaveKeys,
          nextWeekSelfSchedule: cached.nextWeekSelfSchedule,
          nextWeekPeersSchedule: cached.nextWeekPeersSchedule,
          prevWeekLastDayOvernight: cached.prevOvernight,
          prevWeekLastDay: cached.prevWeekLastDay,
          nextWeekFirstDay: cached.nextWeekFirstDay,
          lastWeekShiftCount: cached.lastWeekShiftCount,
          selfLastWeekShiftCount: cached.selfLastWeekShiftCount,
          publishState: cached.publishState,
          monthSchedule: cached.monthSchedule ?? state.monthSchedule,
          monthLeaveKeys: cached.monthLeaveKeys,
          loadedMonth: cached.loadedMonth,
        ),
      );
      if (needsMonthUpdate) add(ChangeMonth(event.weekStart));
      _prefetchAdjacent(event.weekStart);
      // Swap requests are global (not week-specific) and absent from the cache —
      // refresh them. These 6 reads are independent, so fire them concurrently
      // (hot futures start on call) and await afterwards: 6 serial RTTs → 1 wave.
      final mySwapsF = _repo.fetchMySwapRequests(managerId);
      final incomingSwapsF = _repo.fetchIncomingSwapRequests(managerId);
      final declinedSwapsF = _repo.fetchMyDeclinedSwapRequests(managerId);
      final acceptedIncomingF = _repo.fetchAcceptedSwapRequestsAsTarget(managerId);
      final processedSwapsF = _repo.fetchProcessedSwapRequests(managerId);
      // The cached count may have been computed under different filters; recompute
      // it against the current filtered team so "shifts to copy" stays accurate.
      final lastWeekCountF = _repo.fetchLastWeekShiftCount(_filteredTeamIds(), event.weekStart);
      final mySwaps = await mySwapsF;
      final incomingSwaps = await incomingSwapsF;
      final declinedSwaps = await declinedSwapsF;
      final acceptedIncoming = await acceptedIncomingF;
      final processedSwaps = await processedSwapsF;
      final lastWeekCount = await lastWeekCountF;
      emit(
        state.copyWith(
          mySwapRequests: mySwaps,
          incomingSwapRequests: incomingSwaps,
          declinedSwapRequests: declinedSwaps,
          acceptedIncomingSwapRequests: acceptedIncoming,
          processedSwapRequests: processedSwaps,
          lastWeekShiftCount: lastWeekCount,
        ),
      );
      return;
    }
    emit(state.copyWith(status: Status.loading, weekStart: event.weekStart));
    try {
      final isSelfOnly = state.allTeam.length == 1 && state.allTeam.firstOrNull?.id == managerId;
      final teamIds = state.allTeam.map((e) => e.id!).toList();
      final peerIds = state.peers.map((p) => p.id!).toList();
      final todayWeekStart = _weekStartOf(DateTime.now());
      final sameToday = _sameDate(event.weekStart, todayWeekStart);
      final month = _monthOf(event.weekStart);
      final sameMonth = month == state.loadedMonth;
      final eventNextWeek = event.weekStart.add(const Duration(days: 7));
      final todayNextWeek = todayWeekStart.add(const Duration(days: 7));
      final leaveIds = {managerId, ...teamIds, ...peerIds}.toList();
      final n1Id = state.n1User?.id ?? state.selfUser?.n1;

      // All independent — fire concurrently (hot futures), join once, read typed.
      final scheduleF = _repo.fetchWeekSchedule(teamIds, event.weekStart);
      final todayScheduleF = sameToday ? null : _repo.fetchWeekSchedule(teamIds, todayWeekStart);
      final selfScheduleF = isSelfOnly ? null : _repo.fetchWeekSchedule([managerId], event.weekStart);
      final todaySelfScheduleF = sameToday ? null : _repo.fetchWeekSchedule([managerId], todayWeekStart);
      final leaveF = _repo.fetchLeaveOverlay(leaveIds, event.weekStart);
      final todaySelfLeaveF = sameToday ? null : _repo.fetchLeaveOverlay([managerId], todayWeekStart);
      final nextWeekSelfLeaveF = _repo.fetchLeaveOverlay([managerId], todayNextWeek);
      final monthScheduleF = sameMonth ? null : _repo.fetchMonthSchedule(teamIds, month);
      final monthLeaveF = sameMonth ? null : _repo.fetchMonthLeaveOverlay(teamIds, month);
      final nextWeekSelfF = _repo.fetchWeekSchedule([managerId], eventNextWeek);
      final nextWeekTodaySelfF = sameToday ? null : _repo.fetchWeekSchedule([managerId], todayNextWeek);
      final mySwapsF = _repo.fetchMySwapRequests(managerId);
      final incomingSwapsF = _repo.fetchIncomingSwapRequests(managerId);
      final declinedSwapsF = _repo.fetchMyDeclinedSwapRequests(managerId);
      final acceptedIncomingF = _repo.fetchAcceptedSwapRequestsAsTarget(managerId);
      final processedSwapsF = _repo.fetchProcessedSwapRequests(managerId);
      final peersScheduleF = peerIds.isNotEmpty ? _repo.fetchWeekSchedule(peerIds, event.weekStart) : null;
      final n1DataF = _fetchN1Schedule(n1Id, managerId, event.weekStart);
      final nextWeekPeersF = peerIds.isNotEmpty ? _repo.fetchWeekSchedule(peerIds, eventNextWeek) : null;
      final todayPeersF = (peerIds.isNotEmpty && !sameToday) ? _repo.fetchWeekSchedule(peerIds, todayWeekStart) : null;
      final nextWeekTodayPeersF =
          (peerIds.isNotEmpty && !sameToday) ? _repo.fetchWeekSchedule(peerIds, todayNextWeek) : null;
      final peerTodayLeaveF =
          (peerIds.isNotEmpty && !sameToday) ? _repo.fetchLeaveOverlay(peerIds, todayWeekStart) : null;
      final peerNextWeekLeaveF = peerIds.isNotEmpty ? _repo.fetchLeaveOverlay(peerIds, todayNextWeek) : null;
      final lastWeekCountF = _repo.fetchLastWeekShiftCount(_filteredTeamIds(), event.weekStart);
      final selfLastWeekCountF = _repo.fetchSelfLastWeekCopyableCount(managerId, event.weekStart);
      final prevOvernightF = _repo.fetchPrevWeekLastDayOvernight(teamIds, event.weekStart);
      final prevWeekLastDayF = _repo.fetchWeekDaySchedule(
        teamIds,
        event.weekStart.subtract(const Duration(days: 7)),
        6,
      );
      final nextWeekFirstDayF = _repo.fetchWeekDaySchedule(teamIds, eventNextWeek, 0);

      await Future.wait<dynamic>([
        scheduleF,
        leaveF,
        nextWeekSelfLeaveF,
        mySwapsF,
        incomingSwapsF,
        declinedSwapsF,
        acceptedIncomingF,
        processedSwapsF,
        nextWeekSelfF,
        n1DataF,
        lastWeekCountF,
        selfLastWeekCountF,
        prevOvernightF,
        prevWeekLastDayF,
        nextWeekFirstDayF,
        if (todayScheduleF != null) todayScheduleF,
        if (selfScheduleF != null) selfScheduleF,
        if (todaySelfScheduleF != null) todaySelfScheduleF,
        if (todaySelfLeaveF != null) todaySelfLeaveF,
        if (monthScheduleF != null) monthScheduleF,
        if (monthLeaveF != null) monthLeaveF,
        if (nextWeekTodaySelfF != null) nextWeekTodaySelfF,
        if (peersScheduleF != null) peersScheduleF,
        if (nextWeekPeersF != null) nextWeekPeersF,
        if (todayPeersF != null) todayPeersF,
        if (nextWeekTodayPeersF != null) nextWeekTodayPeersF,
        if (peerTodayLeaveF != null) peerTodayLeaveF,
        if (peerNextWeekLeaveF != null) peerNextWeekLeaveF,
      ]);

      final scheduleMap = await scheduleF;
      final leaveKeys = await leaveF;
      final todayScheduleMap = sameToday ? scheduleMap : await todayScheduleF!;
      final selfScheduleMap = isSelfOnly ? scheduleMap : await selfScheduleF!;
      final todaySelfScheduleMap = sameToday ? selfScheduleMap : await todaySelfScheduleF!;
      final todaySelfLeaveKeys = sameToday ? _scopedLeaveKeys(leaveKeys, {managerId}) : await todaySelfLeaveF!;
      final nextWeekSelfLeaveKeys = await nextWeekSelfLeaveF;
      final monthScheduleMap = monthScheduleF != null ? await monthScheduleF : <String, ScheduleModel>{};
      final newMonthLeaveKeys = monthLeaveF != null ? await monthLeaveF : <String, String>{};
      final nextWeekSelfScheduleMap = await nextWeekSelfF;
      final nextWeekTodaySelfScheduleMap = sameToday ? nextWeekSelfScheduleMap : await nextWeekTodaySelfF!;
      final mySwaps = await mySwapsF;
      final incomingSwaps = await incomingSwapsF;
      final declinedSwaps = await declinedSwapsF;
      final acceptedIncoming = await acceptedIncomingF;
      final processedSwaps = await processedSwapsF;
      final teamScopedLeaveKeys = _scopedLeaveKeys(leaveKeys, teamIds.toSet());
      final peerScopedLeaveKeys = _scopedLeaveKeys(leaveKeys, peerIds.toSet());
      final peersScheduleMap = peersScheduleF != null ? await peersScheduleF : <String, ScheduleModel>{};
      final peersScheduleOverlaid = _applyConflicts(
        _applyLeaveOverlay(peersScheduleMap, peerScopedLeaveKeys, [], managerId, event.weekStart),
        peerScopedLeaveKeys,
      );
      final n1Data = await n1DataF;
      final nextWeekPeersScheduleMap = nextWeekPeersF != null ? await nextWeekPeersF : <String, ScheduleModel>{};
      final todayPeersScheduleMap =
          peerIds.isEmpty ? <String, ScheduleModel>{} : (sameToday ? peersScheduleMap : await todayPeersF!);
      final nextWeekTodayPeersScheduleMap =
          peerIds.isEmpty
              ? <String, ScheduleModel>{}
              : (sameToday ? nextWeekPeersScheduleMap : await nextWeekTodayPeersF!);
      final peerTodayLeaveKeys =
          peerIds.isEmpty ? <String, String>{} : (sameToday ? peerScopedLeaveKeys : await peerTodayLeaveF!);
      final peerNextWeekLeaveKeys = peerNextWeekLeaveF != null ? await peerNextWeekLeaveF : <String, String>{};
      final todayPeersScheduleOverlaid = _applyConflicts(
        _applyLeaveOverlay(todayPeersScheduleMap, peerTodayLeaveKeys, [], managerId, todayWeekStart),
        peerTodayLeaveKeys,
      );
      final nextWeekTodayPeersScheduleOverlaid = _applyConflicts(
        _applyLeaveOverlay(nextWeekTodayPeersScheduleMap, peerNextWeekLeaveKeys, [], managerId, todayNextWeek),
        peerNextWeekLeaveKeys,
      );
      final lastWeekCount = await lastWeekCountF;
      final selfLastWeekCount = await selfLastWeekCountF;
      final prevOvernight = await prevOvernightF;
      final prevWeekLastDay = await prevWeekLastDayF;
      final nextWeekFirstDay = await nextWeekFirstDayF;
      final leaveBackups = _buildLeaveBackups(scheduleMap, teamScopedLeaveKeys);
      final overlaid = _applyLeaveOverlay(scheduleMap, teamScopedLeaveKeys, state.allTeam, managerId, event.weekStart);
      final schedule = _applyConflicts(
        overlaid,
        teamScopedLeaveKeys,
        prevWeekLastDay: prevWeekLastDay,
        nextWeekFirstDay: nextWeekFirstDay,
      );
      final selfScheduleOverlaid =
          isSelfOnly
              ? overlaid
              : _applyLeaveOverlay(
                selfScheduleMap,
                _scopedLeaveKeys(leaveKeys, {managerId}),
                [],
                managerId,
                event.weekStart,
              );
      final monthSchedule =
          sameMonth
              ? state.monthSchedule
              : _applyMonthLeaveOverlay(monthScheduleMap, newMonthLeaveKeys, state.allTeam, managerId);
      final todaySelfOverlaid = _applyLeaveOverlay(
        todaySelfScheduleMap,
        todaySelfLeaveKeys,
        [],
        managerId,
        todayWeekStart,
      );
      final todaySelfWithConflicts = _applyConflicts(todaySelfOverlaid, todaySelfLeaveKeys);
      final nextWeekSelfOverlaid = _applyLeaveOverlay(
        nextWeekTodaySelfScheduleMap,
        nextWeekSelfLeaveKeys,
        [],
        managerId,
        todayWeekStart.add(const Duration(days: 7)),
      );
      final nextWeekTodaySelfWithConflicts = _applyConflicts(nextWeekSelfOverlaid, nextWeekSelfLeaveKeys);
      emit(
        state.copyWith(
          status: Status.success,
          schedule: schedule,
          todaySchedule: todayScheduleMap,
          monthSchedule: monthSchedule,
          monthLeaveKeys: sameMonth ? null : newMonthLeaveKeys,
          loadedMonth: sameMonth ? null : month,
          selfSchedule: selfScheduleOverlaid,
          nextWeekSelfSchedule: nextWeekSelfScheduleMap,
          todaySelfSchedule: todaySelfWithConflicts,
          nextWeekTodaySelfSchedule: nextWeekTodaySelfWithConflicts,
          mySwapRequests: mySwaps,
          incomingSwapRequests: incomingSwaps,
          declinedSwapRequests: declinedSwaps,
          acceptedIncomingSwapRequests: acceptedIncoming,
          processedSwapRequests: processedSwaps,
          peersSchedule: peersScheduleOverlaid,
          n1Schedule: n1Data.schedule,
          n1LeaveKeys: n1Data.leaveKeys,
          nextWeekPeersSchedule: nextWeekPeersScheduleMap,
          todayPeersSchedule: todayPeersScheduleOverlaid,
          nextWeekTodayPeersSchedule: nextWeekTodayPeersScheduleOverlaid,
          leaveKeys: leaveKeys,
          leaveBackups: leaveBackups,
          prevWeekLastDayOvernight: prevOvernight,
          prevWeekLastDay: prevWeekLastDay,
          nextWeekFirstDay: nextWeekFirstDay,
          lastWeekShiftCount: lastWeekCount,
          selfLastWeekShiftCount: selfLastWeekCount,
          weekStart: event.weekStart,
          publishState: _derivePublishState(schedule),
        ),
      );
      _storeCache(
        event.weekStart,
        _WeekCache(
          schedule: schedule,
          leaveKeys: leaveKeys,
          leaveBackups: leaveBackups,
          selfSchedule: selfScheduleOverlaid,
          peersSchedule: peersScheduleOverlaid,
          n1Schedule: n1Data.schedule,
          n1LeaveKeys: n1Data.leaveKeys,
          nextWeekSelfSchedule: nextWeekSelfScheduleMap,
          nextWeekPeersSchedule: nextWeekPeersScheduleMap,
          selfLastWeekShiftCount: selfLastWeekCount,
          prevOvernight: prevOvernight,
          prevWeekLastDay: prevWeekLastDay,
          nextWeekFirstDay: nextWeekFirstDay,
          lastWeekShiftCount: lastWeekCount,
          publishState: _derivePublishState(schedule),
          monthSchedule: sameMonth ? null : monthSchedule,
          monthLeaveKeys: sameMonth ? null : newMonthLeaveKeys,
          loadedMonth: sameMonth ? null : month,
        ),
      );
      _prefetchAdjacent(event.weekStart);
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onChangeMonth(ChangeMonth event, Emitter<ScheduleState> emit) async {
    if (state.managerId == null) return;
    final month = _monthOf(event.month);
    if (month == state.loadedMonth) return;
    emit(state.copyWith(monthLoading: true));
    try {
      final managerId = state.managerId!;
      final teamIds = state.allTeam.map((e) => e.id!).toList();
      final monthScheduleMap = await _repo.fetchMonthSchedule(teamIds, month);
      final monthLeaveKeys = await _repo.fetchMonthLeaveOverlay(teamIds, month);
      final monthSchedule = _applyMonthLeaveOverlay(monthScheduleMap, monthLeaveKeys, state.allTeam, managerId);
      final peerMonthMap =
          state.viewMode == ScheduleViewMode.colleagues
              ? await _repo.fetchMonthSchedule(state.colleaguesTeam.map((e) => e.id!).toList(), month)
              : state.monthPeersSchedule;
      emit(
        state.copyWith(
          status: Status.success,
          monthSchedule: monthSchedule,
          monthLeaveKeys: monthLeaveKeys,
          loadedMonth: month,
          monthLoading: false,
          monthPeersSchedule: peerMonthMap,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString()), monthLoading: false));
    }
  }

  Future<void> _onChangeView(ChangeView event, Emitter<ScheduleState> emit) async {
    emit(
      state.copyWith(view: event.view, selectedDayIndex: event.dayIndex, clearSelectedDayIndex: event.dayIndex == null),
    );
    if (event.view == ScheduleView.self && state.managerId != null) {
      try {
        final mySwaps = await _repo.fetchMySwapRequests(state.managerId!);
        final incomingSwaps = await _repo.fetchIncomingSwapRequests(state.managerId!);
        emit(state.copyWith(mySwapRequests: mySwaps, incomingSwapRequests: incomingSwaps));
      } catch (_) {}
    }
  }

  Future<void> _onChangeFilters(ChangeFilters event, Emitter<ScheduleState> emit) async {
    final filtered = _applyFilters(state.allTeam, event.filters, state.managerId ?? 0);
    final filteredTeam = state.viewMode == ScheduleViewMode.colleagues ? state.colleaguesTeam : filtered;
    emit(state.copyWith(filters: event.filters, filteredTeam: filteredTeam));
    if (state.managerId == null) return;
    final filteredIds = filtered.map((e) => e.id!).toList();
    final count = await _repo.fetchLastWeekShiftCount(filteredIds, state.weekStart);
    emit(state.copyWith(lastWeekShiftCount: count));
  }

  Future<void> _onChangeViewMode(ChangeViewMode event, Emitter<ScheduleState> emit) async {
    if (event.mode == ScheduleViewMode.colleagues) {
      final peerIds = state.colleaguesTeam.map((e) => e.id!).toList();
      final month = state.loadedMonth ?? _monthOf(state.weekStart);
      final peerMonthMap =
          peerIds.isNotEmpty ? await _repo.fetchMonthSchedule(peerIds, month) : <String, ScheduleModel>{};
      emit(state.copyWith(viewMode: event.mode, filteredTeam: state.colleaguesTeam, monthPeersSchedule: peerMonthMap));
    } else {
      final filtered = _applyFilters(state.allTeam, state.filters, state.managerId ?? 0);
      emit(state.copyWith(viewMode: event.mode, filteredTeam: filtered));
    }
  }

  /// IDs of the team after applying the current filters — the set the copy
  /// action operates on, and which the "shifts to copy" count must match.
  /// Self-only users have no reports and are never their own "direct report",
  /// so the teamScope filter would always drop them — target self instead.
  List<int> _filteredTeamIds() {
    if (state.isSelfOnly) return [state.managerId ?? 0];
    return _applyFilters(state.allTeam, state.filters, state.managerId ?? 0).map((e) => e.id).whereType<int>().toList();
  }

  /// Number of employees the "copy last week" action will actually reproduce
  /// shifts for — distinct reports with shifts, plus my own row when it has
  /// copyable shifts. Fetched on demand for the copy confirm dialog (not the
  /// whole team size). Colleagues mode copies my own row only.
  Future<int> lastWeekCopyEmployeeCount() async {
    // Count my own row only when the copy would actually add a shift to it
    // (source shifts AND room to paste into).
    final selfCopies = state.canSelfCopyLastWeek ? 1 : 0;
    if (state.viewMode == ScheduleViewMode.colleagues) return selfCopies;
    final teamCount = await _repo.fetchLastWeekEmployeeCount(_filteredTeamIds(), state.weekStart);
    return teamCount + selfCopies;
  }

  // ── Week cache helpers ────────────────────────────────────────────────────

  void _storeCache(DateTime weekStart, _WeekCache cache) {
    _weekCache[weekStart] = cache;
    if (_weekCache.length > _maxCacheSize) {
      _weekCache.remove(_weekCache.keys.first);
    }
  }

  /// Invalidate only the mutated week and its two neighbors, instead of wiping
  /// the whole cache. Neighbors are dropped too because _applyConflicts derives
  /// cross-week rest conflicts from prevWeekLastDay / nextWeekFirstDay, so a
  /// boundary-day (dayIndex 0 or 6) edit can invalidate an adjacent week's
  /// overlay. Every other prefetched week survives, so navigating after an edit
  /// no longer re-triggers the full fan-out.
  void _evictAround(DateTime weekStart) {
    _weekCache.remove(weekStart);
    _weekCache.remove(weekStart.add(const Duration(days: 7)));
    _weekCache.remove(weekStart.subtract(const Duration(days: 7)));
  }

  void _prefetchAdjacent(DateTime weekStart) {
    _prefetchWeek(weekStart.add(const Duration(days: 7)));
    _prefetchWeek(weekStart.subtract(const Duration(days: 7)));
  }

  Future<void> _prefetchWeek(DateTime target) async {
    if (_weekCache.containsKey(target)) return;
    if (state.managerId == null) return;
    try {
      final managerId = state.managerId!;
      final isSelfOnly = state.allTeam.length == 1 && state.allTeam.firstOrNull?.id == managerId;
      final teamIds = state.allTeam.map((e) => e.id!).toList();
      final peerIds = state.peers.map((p) => p.id!).toList();
      final leaveIds = {managerId, ...teamIds, ...peerIds}.toList();
      final n1Id = state.n1User?.id ?? state.selfUser?.n1;
      final targetNextWeek = target.add(const Duration(days: 7));
      final targetMonth = _monthOf(target);
      final crossesMonth = targetMonth != state.loadedMonth;

      // All independent — fire concurrently (hot futures), join once, read typed.
      final scheduleF = _repo.fetchWeekSchedule(teamIds, target);
      final leaveF = _repo.fetchLeaveOverlay(leaveIds, target);
      final selfScheduleF = isSelfOnly ? null : _repo.fetchWeekSchedule([managerId], target);
      final nextWeekSelfF = _repo.fetchWeekSchedule([managerId], targetNextWeek);
      final peersScheduleF = peerIds.isNotEmpty ? _repo.fetchWeekSchedule(peerIds, target) : null;
      final n1DataF = _fetchN1Schedule(n1Id, managerId, target);
      final nextWeekPeersF = peerIds.isNotEmpty ? _repo.fetchWeekSchedule(peerIds, targetNextWeek) : null;
      final prevOvernightF = _repo.fetchPrevWeekLastDayOvernight(teamIds, target);
      final prevWeekLastDayF = _repo.fetchWeekDaySchedule(teamIds, target.subtract(const Duration(days: 7)), 6);
      final nextWeekFirstDayF = _repo.fetchWeekDaySchedule(teamIds, targetNextWeek, 0);
      final lastWeekCountF = _repo.fetchLastWeekShiftCount(_filteredTeamIds(), target);
      final selfLastWeekCountF = _repo.fetchSelfLastWeekCopyableCount(managerId, target);
      final monthScheduleF = crossesMonth ? _repo.fetchMonthSchedule(teamIds, targetMonth) : null;
      final monthLeaveF = crossesMonth ? _repo.fetchMonthLeaveOverlay(teamIds, targetMonth) : null;

      await Future.wait<dynamic>([
        scheduleF,
        leaveF,
        nextWeekSelfF,
        n1DataF,
        prevOvernightF,
        prevWeekLastDayF,
        nextWeekFirstDayF,
        lastWeekCountF,
        selfLastWeekCountF,
        if (selfScheduleF != null) selfScheduleF,
        if (peersScheduleF != null) peersScheduleF,
        if (nextWeekPeersF != null) nextWeekPeersF,
        if (monthScheduleF != null) monthScheduleF,
        if (monthLeaveF != null) monthLeaveF,
      ]);

      final scheduleMap = await scheduleF;
      final leaveKeys = await leaveF;
      final selfScheduleMap = isSelfOnly ? scheduleMap : await selfScheduleF!;
      final nextWeekSelfMap = await nextWeekSelfF;
      final teamScopedLeaveKeys = _scopedLeaveKeys(leaveKeys, teamIds.toSet());
      final peerScopedLeaveKeys = _scopedLeaveKeys(leaveKeys, peerIds.toSet());
      final peersScheduleMap = peersScheduleF != null ? await peersScheduleF : <String, ScheduleModel>{};
      final peersScheduleOverlaid = _applyLeaveOverlay(peersScheduleMap, peerScopedLeaveKeys, [], managerId, target);
      final n1Data = await n1DataF;
      final nextWeekPeersMap = nextWeekPeersF != null ? await nextWeekPeersF : <String, ScheduleModel>{};
      final prevOvernight = await prevOvernightF;
      final prevWeekLastDay = await prevWeekLastDayF;
      final nextWeekFirstDay = await nextWeekFirstDayF;
      final lastWeekCount = await lastWeekCountF;
      final selfLastWeekCount = await selfLastWeekCountF;
      final leaveBackups = _buildLeaveBackups(scheduleMap, teamScopedLeaveKeys);
      final overlaid = _applyLeaveOverlay(scheduleMap, teamScopedLeaveKeys, state.allTeam, managerId, target);
      final schedule = _applyConflicts(
        overlaid,
        teamScopedLeaveKeys,
        prevWeekLastDay: prevWeekLastDay,
        nextWeekFirstDay: nextWeekFirstDay,
      );
      final selfScheduleOverlaid =
          isSelfOnly
              ? overlaid
              : _applyLeaveOverlay(selfScheduleMap, _scopedLeaveKeys(leaveKeys, {managerId}), [], managerId, target);
      Map<String, ScheduleModel>? cachedMonthSchedule;
      Map<String, String>? cachedMonthLeaveKeys;
      if (crossesMonth) {
        final rawMonth = await monthScheduleF!;
        final rawMonthLeaveKeys = await monthLeaveF!;
        cachedMonthSchedule = _applyMonthLeaveOverlay(rawMonth, rawMonthLeaveKeys, state.allTeam, managerId);
        cachedMonthLeaveKeys = rawMonthLeaveKeys;
      }
      _storeCache(
        target,
        _WeekCache(
          schedule: schedule,
          leaveKeys: leaveKeys,
          leaveBackups: leaveBackups,
          selfSchedule: selfScheduleOverlaid,
          peersSchedule: peersScheduleOverlaid,
          n1Schedule: n1Data.schedule,
          n1LeaveKeys: n1Data.leaveKeys,
          nextWeekSelfSchedule: nextWeekSelfMap,
          nextWeekPeersSchedule: nextWeekPeersMap,
          prevOvernight: prevOvernight,
          prevWeekLastDay: prevWeekLastDay,
          nextWeekFirstDay: nextWeekFirstDay,
          lastWeekShiftCount: lastWeekCount,
          selfLastWeekShiftCount: selfLastWeekCount,
          publishState: _derivePublishState(schedule),
          monthSchedule: cachedMonthSchedule,
          monthLeaveKeys: cachedMonthLeaveKeys,
          loadedMonth: crossesMonth ? targetMonth : null,
        ),
      );
    } catch (_) {
      // Silent — user gets a normal load if they navigate to an unprefetched week
    }
  }

  Future<void> _onSaveShift(SaveShift event, Emitter<ScheduleState> emit) async {
    _evictAround(state.weekStart);
    // Snapshot before optimistic update so we can revert on failure.
    final snapshotSchedule = state.schedule;
    final snapshotTodaySchedule = state.todaySchedule;
    final snapshotMonthSchedule = state.monthSchedule;
    final snapshotSelfSchedule = state.selfSchedule;
    final snapshotTodaySelfSchedule = state.todaySelfSchedule;
    final snapshotPublishState = state.publishState;

    // Ownership: created_by = last writer (me). Self-edits (my own row) are
    // filed under my N+1 so the row lands in my manager's team view and
    // satisfies the employee self-draft RLS policy.
    final myId = state.managerId ?? 0;
    final isSelfEdit = event.keys.every((k) => int.tryParse(k.split('-').first) == myId);
    final payload = event.payload.copyWith(
      createdBy: myId,
      managerId: isSelfEdit ? (state.selfUser?.n1 ?? myId) : event.payload.managerId,
    );

    final newSchedule = Map<String, ScheduleModel>.from(state.schedule);
    final newMonthSchedule = Map<String, ScheduleModel>.from(state.monthSchedule);
    final newSelfSchedule = Map<String, ScheduleModel>.from(state.selfSchedule);
    var selfTouched = false;
    for (final key in event.keys) {
      final parts = key.split('-');
      final empId = int.parse(parts[0]);
      final dayIdx = int.parse(parts[1]);
      final shift = payload.copyWith(employeeId: empId, weekStart: state.weekStart, dayIndex: dayIdx);
      // A manager's own row lives in selfSchedule, not the team map — keep
      // team-only aggregates (publish keys, KPIs) free of self shifts.
      if (empId != myId || state.isSelfOnly) newSchedule[key] = shift;
      if (empId == myId) {
        newSelfSchedule[key] = shift;
        selfTouched = true;
      }
      final shiftDate = shift.weekStart.add(Duration(days: shift.dayIndex));
      if (_isInLoadedMonthRange(shiftDate) && (empId != myId || state.isSelfOnly)) {
        newMonthSchedule[_monthKey(empId, shiftDate)] = shift;
      }
    }
    final withConflicts = _applyConflicts(
      newSchedule,
      state.leaveKeys,
      prevWeekLastDay: state.prevWeekLastDay,
      nextWeekFirstDay: state.nextWeekFirstDay,
    );
    emit(
      state.copyWith(
        schedule: withConflicts,
        todaySchedule: _isCurrentWeekSelected() ? withConflicts : null,
        monthSchedule: newMonthSchedule,
        selfSchedule: selfTouched ? newSelfSchedule : null,
        todaySelfSchedule: selfTouched && _isCurrentWeekSelected() ? newSelfSchedule : null,
        publishState: _derivePublishState(withConflicts),
      ),
    );

    try {
      await _trackWrite(() => _repo.saveShifts(event.keys, payload));
      if (event.template != null) {
        final saved = await _repo.saveTemplate(event.template!);
        final updated = List<ShiftTemplateModel>.from(state.topTemplates);
        final idx = updated.indexWhere((t) => t.id == saved.id);
        if (idx >= 0) {
          updated[idx] = saved;
        } else {
          updated.insert(0, saved);
          if (updated.length > 6) updated.removeLast();
        }
        updated.sort((a, b) => b.useCount.compareTo(a.useCount));
        emit(state.copyWith(topTemplates: updated));
      }
    } catch (e) {
      // Revert optimistic update; do NOT emit Status.failure (that replaces the page).
      emit(
        state.copyWith(
          schedule: snapshotSchedule,
          todaySchedule: snapshotTodaySchedule,
          monthSchedule: snapshotMonthSchedule,
          selfSchedule: snapshotSelfSchedule,
          todaySelfSchedule: snapshotTodaySelfSchedule,
          publishState: snapshotPublishState,
          failure: Failure(e.toString()),
        ),
      );
    }
  }

  Future<void> _onBulkAssignShifts(BulkAssignShifts event, Emitter<ScheduleState> emit) async {
    _evictAround(state.weekStart);
    if (event.employeeIds.isEmpty || event.dayIndices.isEmpty) return;

    // My own row may include days I can't touch — published shifts, leave days,
    // and drafts my manager owns ("reserved"). The RPC skips them server-side;
    // filter them per-row here (below) so the optimistic state stays honest even
    // when I'm bulk-assigning myself alongside my reports.
    final myId = state.managerId ?? 0;
    final dayIndices = event.dayIndices;
    // If self is the *only* target and none of the chosen days are editable,
    // there's nothing to write at all.
    final selfOnlyTarget = event.employeeIds.length == 1 && event.employeeIds.first == myId;
    if (selfOnlyTarget && !dayIndices.any((d) => state.canSelfEdit(state.selfSchedule['$myId-$d']))) {
      return;
    }

    // Snapshot before optimistic update.
    final snapshotSchedule = state.schedule;
    final snapshotTodaySchedule = state.todaySchedule;
    final snapshotMonthSchedule = state.monthSchedule;
    final snapshotSelfSchedule = state.selfSchedule;
    final snapshotTodaySelfSchedule = state.todaySelfSchedule;
    final snapshotPublishState = state.publishState;

    final newSchedule = Map<String, ScheduleModel>.from(state.schedule);
    final newMonthSchedule = Map<String, ScheduleModel>.from(state.monthSchedule);
    final newSelfSchedule = Map<String, ScheduleModel>.from(state.selfSchedule);
    var selfTouched = false;
    final hours =
        event.customEnd > event.customStart
            ? event.customEnd - event.customStart
            : (24 - event.customStart) + event.customEnd;

    for (final empId in event.employeeIds) {
      for (final dayIdx in dayIndices) {
        // Never write a day on my own row that I'm not allowed to draft; the
        // RPC silently skips these too, so skipping here avoids optimistic drift.
        if (empId == myId && !state.canSelfEdit(state.selfSchedule['$myId-$dayIdx'])) {
          continue;
        }
        final shift = ScheduleModel(
          employeeId: empId,
          managerId: empId == myId ? (state.selfUser?.n1 ?? myId) : myId,
          weekStart: state.weekStart,
          dayIndex: dayIdx,
          customStart: event.customStart,
          customEnd: event.customEnd,
          hours: hours,
          note: event.note,
          isPublished: false,
          createdBy: myId,
        );
        final key = '$empId-$dayIdx';
        if (empId != myId || state.isSelfOnly) newSchedule[key] = shift;
        if (empId == myId) {
          newSelfSchedule[key] = shift;
          selfTouched = true;
        }
        final shiftDate = state.weekStart.add(Duration(days: dayIdx));
        if (_isInLoadedMonthRange(shiftDate) && (empId != myId || state.isSelfOnly)) {
          newMonthSchedule[_monthKey(empId, shiftDate)] = shift;
        }
      }
    }

    final withConflicts = _applyConflicts(
      newSchedule,
      state.leaveKeys,
      prevWeekLastDay: state.prevWeekLastDay,
      nextWeekFirstDay: state.nextWeekFirstDay,
    );
    emit(
      state.copyWith(
        schedule: withConflicts,
        todaySchedule: _isCurrentWeekSelected() ? withConflicts : null,
        monthSchedule: newMonthSchedule,
        selfSchedule: selfTouched ? newSelfSchedule : null,
        todaySelfSchedule: selfTouched && _isCurrentWeekSelected() ? newSelfSchedule : null,
        publishState: _derivePublishState(withConflicts),
      ),
    );

    try {
      await _trackWrite(
        () => _repo.bulkSaveShifts(
          employeeIds: event.employeeIds,
          dayIndices: dayIndices,
          weekStart: state.weekStart,
          managerId: state.managerId ?? 0,
          customStart: event.customStart,
          customEnd: event.customEnd,
          note: event.note,
        ),
      );
      if (event.template != null) {
        final saved = await _repo.saveTemplate(event.template!);
        final updated = List<ShiftTemplateModel>.from(state.topTemplates);
        final idx = updated.indexWhere((t) => t.id == saved.id);
        if (idx >= 0) {
          updated[idx] = saved;
        } else {
          updated.insert(0, saved);
          if (updated.length > 6) updated.removeLast();
        }
        updated.sort((a, b) => b.useCount.compareTo(a.useCount));
        emit(state.copyWith(topTemplates: updated));
      }
    } catch (e) {
      emit(
        state.copyWith(
          schedule: snapshotSchedule,
          todaySchedule: snapshotTodaySchedule,
          monthSchedule: snapshotMonthSchedule,
          selfSchedule: snapshotSelfSchedule,
          todaySelfSchedule: snapshotTodaySelfSchedule,
          publishState: snapshotPublishState,
          failure: Failure(e.toString()),
        ),
      );
    }
  }

  Future<void> _onDeleteShift(DeleteShift event, Emitter<ScheduleState> emit) async {
    _evictAround(state.weekStart);
    // Snapshot before optimistic update.
    final snapshotSchedule = state.schedule;
    final snapshotTodaySchedule = state.todaySchedule;
    final snapshotMonthSchedule = state.monthSchedule;
    final snapshotSelfSchedule = state.selfSchedule;
    final snapshotTodaySelfSchedule = state.todaySelfSchedule;
    final snapshotPublishState = state.publishState;

    // Self keys are deletable only while they are my own drafts (published or
    // manager-owned rows are locked for me — RLS enforces the same rule).
    final myId = state.managerId ?? 0;
    final keys =
        event.keys.where((k) {
          final empId = int.tryParse(k.split('-').first);
          if (empId != myId) return true;
          return state.canSelfEdit(state.selfSchedule[k]);
        }).toList();
    if (keys.isEmpty) return;

    // Collect published shifts for the archive step.
    final publishedShifts =
        keys
            .map((k) => state.schedule[k])
            .whereType<ScheduleModel>()
            .where((s) => s.isPublished && !s.isLeave)
            .toList();

    final newSchedule = Map<String, ScheduleModel>.from(state.schedule);
    final newMonthSchedule = Map<String, ScheduleModel>.from(state.monthSchedule);
    final newSelfSchedule = Map<String, ScheduleModel>.from(state.selfSchedule);
    var selfTouched = false;
    var deletedPublished = false;
    for (final key in keys) {
      final existing = state.schedule[key];
      if (existing != null && existing.isPublished && !existing.isLeave) {
        deletedPublished = true;
      }
      newSchedule.remove(key);
      final leaveType = state.leaveKeys[key];
      final parts = key.split('-');
      final empId = int.parse(parts[0]);
      final dayIdx = int.parse(parts[1]);
      if (empId == myId) {
        newSelfSchedule.remove(key);
        selfTouched = true;
      }
      final date = state.weekStart.add(Duration(days: dayIdx));
      final monthKey = _monthKey(empId, date);
      newMonthSchedule.remove(monthKey);
      if (leaveType != null) {
        newSchedule[key] = ScheduleModel.leave(
          employeeId: empId,
          managerId: state.managerId ?? 0,
          weekStart: state.weekStart,
          dayIndex: dayIdx,
          leaveType: leaveType,
        );
      }
      final monthLeaveType = state.monthLeaveKeys[monthKey];
      if (monthLeaveType != null) {
        newMonthSchedule[monthKey] = ScheduleModel.leave(
          employeeId: empId,
          managerId: state.managerId ?? 0,
          weekStart: state.weekStart,
          dayIndex: dayIdx,
          leaveType: monthLeaveType,
        );
      }
    }
    final withConflicts = _applyConflicts(
      newSchedule,
      state.leaveKeys,
      prevWeekLastDay: state.prevWeekLastDay,
      nextWeekFirstDay: state.nextWeekFirstDay,
    );
    final newPublishState = deletedPublished ? PublishState.draft : _derivePublishState(withConflicts);
    emit(
      state.copyWith(
        schedule: withConflicts,
        todaySchedule: _isCurrentWeekSelected() ? withConflicts : null,
        monthSchedule: newMonthSchedule,
        selfSchedule: selfTouched ? newSelfSchedule : null,
        todaySelfSchedule: selfTouched && _isCurrentWeekSelected() ? newSelfSchedule : null,
        publishState: newPublishState,
      ),
    );
    try {
      await _trackWrite(
        () => _repo.deleteShifts(
          keys,
          state.weekStart,
          publishedShifts: publishedShifts,
          deletedByManagerId: state.managerId ?? 0,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          schedule: snapshotSchedule,
          todaySchedule: snapshotTodaySchedule,
          monthSchedule: snapshotMonthSchedule,
          selfSchedule: snapshotSelfSchedule,
          todaySelfSchedule: snapshotTodaySelfSchedule,
          publishState: snapshotPublishState,
          failure: Failure(e.toString()),
        ),
      );
    }
  }

  Future<void> _onPublishWeek(PublishWeek event, Emitter<ScheduleState> emit) async {
    _evictAround(state.weekStart);
    emit(state.copyWith(publishState: PublishState.publishing));
    try {
      // Snapshot the exact draft keys the user saw at click time. Anything
      // they add or edit AFTER this point is not in publishKeys, so the
      // RPC (and the local-state flip below) leave it alone.
      final filteredIds = state.filteredTeam.map((e) => e.id).whereType<int>().toSet();
      final publishKeys =
          state.schedule.entries
              .where((e) {
                final empId = int.tryParse(e.key.split('-').first);
                return empId != null && filteredIds.contains(empId) && !e.value.isPublished && !e.value.isLeave;
              })
              .map((e) => e.key)
              .toList();
      final publishKeySet = publishKeys.toSet();
      final notifyIds = publishKeys.map((k) => int.parse(k.split('-').first)).toSet().toList();

      // Drain any in-flight save/delete/copy AFTER snapshotting, so the rows
      // we just listed are guaranteed to exist in DB by the time the RPC
      // runs (defeats Race A) — without letting writes that start during the
      // drain sneak into the publish scope (defeats Race C).
      final pending = _pendingWrites;
      if (pending != null) {
        try {
          await pending;
        } catch (_) {
          /* surfaced by the originating handler */
        }
      }

      final results = await Future.wait([
        _repo.publishWeek(publishKeys, state.weekStart, notifyIds: notifyIds),
        Future.delayed(const Duration(seconds: 2)),
      ]);
      final updated = results[0] as int;
      if (updated < publishKeys.length) {
        emit(
          state.copyWith(
            publishState: PublishState.draft,
            failure: Failure('Partial publish: $updated of ${publishKeys.length} shifts updated. Please retry.'),
          ),
        );
        return;
      }
      final newSchedule = state.schedule.map((k, v) {
        if (publishKeySet.contains(k)) {
          return MapEntry(k, v.copyWith(isPublished: true));
        }
        return MapEntry(k, v);
      });
      final newMonthSchedule = state.monthSchedule.map((k, v) {
        final date = v.weekStart.add(Duration(days: v.dayIndex));
        final weekKey = '${v.employeeId}-${v.dayIndex}';
        if (!v.isLeave && _sameWeek(date, state.weekStart) && publishKeySet.contains(weekKey)) {
          return MapEntry(k, v.copyWith(isPublished: true));
        }
        return MapEntry(k, v);
      });
      emit(
        state.copyWith(
          schedule: newSchedule,
          todaySchedule: _isCurrentWeekSelected() ? newSchedule : null,
          monthSchedule: newMonthSchedule,
          publishState: _derivePublishState(newSchedule),
        ),
      );
    } catch (e) {
      emit(state.copyWith(publishState: PublishState.draft, failure: Failure(e.toString())));
    }
  }

  Future<void> _onCopyLastWeek(CopyLastWeek event, Emitter<ScheduleState> emit) async {
    // Invalidate cached week snapshots (like the other write handlers) — a
    // pre-copy snapshot of this week may already be cached, and _onChangeWeek
    // restores cached weeks verbatim with no re-fetch, so without this the copy
    // silently disappears when navigating away and back.
    _evictAround(state.weekStart);
    emit(state.copyWith(status: Status.loading));
    try {
      final managerId = state.managerId ?? 0;
      final allTeamIds = state.allTeam.map((e) => e.id!).toList();
      // Copy targets: colleagues mode copies MY OWN row only; team mode copies
      // the filtered team PLUS my own pinned row. created_by = last writer
      // (me); my own copies are filed under my N+1 so the employee self-draft
      // RLS policy accepts them (source rows may carry any manager_id).
      final targetIds =
          state.viewMode == ScheduleViewMode.colleagues
              ? <int>[managerId]
              : <int>{..._filteredTeamIds(), managerId}.toList();
      await _trackWrite(
        () => _repo.copyLastWeek(
          targetIds,
          state.weekStart,
          createdBy: managerId,
          selfId: managerId,
          selfManagerId: state.selfUser?.n1 ?? managerId,
        ),
      );
      // Post-copy refetch: these reads are independent of each other (they only
      // depend on the just-completed write above), so fire them concurrently.
      final month = _monthOf(state.weekStart);
      final scheduleF = _repo.fetchWeekSchedule(allTeamIds, state.weekStart);
      final leaveF = _repo.fetchLeaveOverlay({...allTeamIds, managerId}.toList(), state.weekStart);
      // My own row lives in selfSchedule (pinned row / colleagues own row) —
      // refetch it so the copied drafts render without a manual reload.
      final selfF = state.isSelfOnly ? null : _repo.fetchWeekSchedule([managerId], state.weekStart);
      final monthScheduleF = _repo.fetchMonthSchedule(allTeamIds, month);
      final monthLeaveF = _repo.fetchMonthLeaveOverlay(allTeamIds, month);
      await Future.wait<dynamic>([scheduleF, leaveF, monthScheduleF, monthLeaveF, if (selfF != null) selfF]);
      final scheduleMap = await scheduleF;
      final leaveKeys = await leaveF;
      final selfMap = selfF != null ? await selfF : null;
      final monthScheduleMap = await monthScheduleF;
      final monthLeaveKeys = await monthLeaveF;
      final leaveBackups = _buildLeaveBackups(scheduleMap, leaveKeys);
      final overlaid = _applyLeaveOverlay(scheduleMap, leaveKeys, state.allTeam, managerId, state.weekStart);
      final schedule = _applyConflicts(
        overlaid,
        leaveKeys,
        prevWeekLastDay: state.prevWeekLastDay,
        nextWeekFirstDay: state.nextWeekFirstDay,
      );
      final monthSchedule = _applyMonthLeaveOverlay(monthScheduleMap, monthLeaveKeys, state.allTeam, managerId);
      // Self-only users render their row from the (self == team) schedule map;
      // managers get their own row refetched separately for the pinned row.
      final selfOverlaid =
          state.isSelfOnly
              ? schedule
              : _applyLeaveOverlay(selfMap!, _scopedLeaveKeys(leaveKeys, {managerId}), [], managerId, state.weekStart);
      emit(
        state.copyWith(
          status: Status.success,
          schedule: schedule,
          monthSchedule: monthSchedule,
          monthLeaveKeys: monthLeaveKeys,
          loadedMonth: month,
          leaveKeys: leaveKeys,
          leaveBackups: leaveBackups,
          selfSchedule: selfOverlaid,
          todaySelfSchedule: _isCurrentWeekSelected() ? selfOverlaid : null,
          publishState: PublishState.draft,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString())));
    }
  }

  Future<void> _onApproveSwap(ApproveSwap event, Emitter<ScheduleState> emit) async {
    // Approving a swap rewrites the two days' shift times in state.schedule;
    // drop cached week snapshots so navigating away and back doesn't restore the
    // stale pre-swap grid (same invariant the other write handlers hold).
    _evictAround(state.weekStart);
    try {
      await _repo.approveSwap(event.id);

      final updatedSwaps = state.swapRequests.where((s) => s.id != event.id).toList();

      // Find the approved request so we can patch local schedule state in-place,
      // avoiding a full network refetch while keeping the week grid up-to-date.
      ShiftSwapRequestModel? req;
      for (final s in state.swapRequests) {
        if (s.id == event.id) {
          req = s;
          break;
        }
      }

      final reqEmpId = req?.scheduleEmployeeId;
      final reqDayIdx = req?.scheduleDayIndex;
      final tgtEmpId = req?.targetEmployeeId;
      final tgtDayIdx = req?.targetScheduleDayIndex;

      Map<String, ScheduleModel> newSchedule = state.schedule;

      if (reqEmpId != null && reqDayIdx != null && tgtEmpId != null && tgtDayIdx != null) {
        final keyA = '$reqEmpId-$reqDayIdx';
        final keyB = '$tgtEmpId-$tgtDayIdx';
        final a = newSchedule[keyA];
        final b = newSchedule[keyB];

        if (a != null && b != null) {
          newSchedule = Map.from(newSchedule);
          newSchedule[keyA] = a.copyWith(
            customStart: b.customStart,
            customEnd: b.customEnd,
            shiftTemplateId: b.shiftTemplateId,
            hours: b.hours,
          );
          newSchedule[keyB] = b.copyWith(
            customStart: a.customStart,
            customEnd: a.customEnd,
            shiftTemplateId: a.shiftTemplateId,
            hours: a.hours,
          );
          newSchedule = _applyConflicts(
            newSchedule,
            state.leaveKeys,
            prevWeekLastDay: state.prevWeekLastDay,
            nextWeekFirstDay: state.nextWeekFirstDay,
          );
        }
      }

      emit(
        state.copyWith(
          swapRequests: updatedSwaps,
          schedule: newSchedule,
          publishState: _derivePublishState(newSchedule),
        ),
      );
    } catch (e) {
      emit(state.copyWith(failure: Failure(e.toString())));
    }
  }

  Future<void> _onDeclineSwap(DeclineSwap event, Emitter<ScheduleState> emit) async {
    try {
      await _repo.declineSwap(event.id);
      final updated = state.swapRequests.where((s) => s.id != event.id).toList();
      emit(state.copyWith(swapRequests: updated));
    } catch (e) {
      emit(state.copyWith(failure: Failure(e.toString())));
    }
  }

  Future<void> _onDeleteTemplate(DeleteTemplate event, Emitter<ScheduleState> emit) async {
    try {
      await _repo.deleteTemplate(event.templateId);
      emit(state.copyWith(topTemplates: state.topTemplates.where((t) => t.id != event.templateId).toList()));
    } catch (e) {
      emit(state.copyWith(failure: Failure(e.toString())));
    }
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  Map<String, String> _scopedLeaveKeys(Map<String, String> leaveKeys, Set<int> empIds) {
    return Map.fromEntries(
      leaveKeys.entries.where((e) {
        final empId = int.tryParse(e.key.split('-').first);
        return empId != null && empIds.contains(empId);
      }),
    );
  }

  Map<String, ScheduleModel> _buildLeaveBackups(Map<String, ScheduleModel> schedule, Map<String, String> leaveKeys) {
    final backups = <String, ScheduleModel>{};
    for (final key in leaveKeys.keys) {
      final existing = schedule[key];
      if (existing != null && !existing.isLeave) {
        backups[key] = existing;
      }
    }
    return backups;
  }

  Map<String, ScheduleModel> _applyLeaveOverlay(
    Map<String, ScheduleModel> schedule,
    Map<String, String> leaveKeys,
    List<UserModel> team,
    int managerId,
    DateTime weekStart,
  ) {
    final result = Map<String, ScheduleModel>.from(schedule);
    for (final entry in leaveKeys.entries) {
      final existing = result[entry.key];
      if (existing == null || existing.isLeave) {
        // No shift — show the leave placeholder
        final parts = entry.key.split('-');
        final empId = int.parse(parts[0]);
        final dayIdx = int.parse(parts[1]);
        result[entry.key] = ScheduleModel.leave(
          employeeId: empId,
          managerId: managerId,
          weekStart: weekStart,
          dayIndex: dayIdx,
          leaveType: entry.value,
        );
      }
      // If a real shift exists: keep it as-is — _applyConflicts will mark the leave conflict
    }
    return result;
  }

  Map<String, ScheduleModel> _applyMonthLeaveOverlay(
    Map<String, ScheduleModel> schedule,
    Map<String, String> leaveKeys,
    List<UserModel> team,
    int managerId,
  ) {
    final result = Map<String, ScheduleModel>.from(schedule);
    final teamIds = team.map((e) => e.id).whereType<int>().toSet();
    for (final entry in leaveKeys.entries) {
      final existing = result[entry.key];
      if (existing != null && !existing.isLeave) continue;

      final parsed = _parseMonthKey(entry.key);
      if (parsed == null || !teamIds.contains(parsed.employeeId)) continue;

      final weekStart = _weekStartOf(parsed.date);
      final dayIdx = parsed.date.difference(weekStart).inDays;
      result[entry.key] = ScheduleModel.leave(
        employeeId: parsed.employeeId,
        managerId: managerId,
        weekStart: weekStart,
        dayIndex: dayIdx,
        leaveType: entry.value,
      );
    }
    return result;
  }

  Map<String, ScheduleModel> _applyConflicts(
    Map<String, ScheduleModel> schedule,
    Map<String, String> leaveKeys, {
    Map<int, ScheduleModel> prevWeekLastDay = const {},
    Map<int, ScheduleModel> nextWeekFirstDay = const {},
  }) {
    final result = Map<String, ScheduleModel>.from(schedule);
    for (final key in result.keys.toList()) {
      final shift = result[key]!;
      if (shift.isLeave || shift.isOffType) continue;

      final parts = key.split('-');
      final empId = parts[0];
      final dayIdx = int.parse(parts[1]);
      ShiftConflictType? conflict;

      // 1. Approved leave on this day
      if (leaveKeys.containsKey(key)) {
        conflict = ShiftConflictType.approvedLeave;
      }

      // 2. Shift exceeds 16 hours
      if (conflict == null) {
        final hours =
            shift.customEnd > shift.customStart
                ? shift.customEnd - shift.customStart
                : (shift.customEnd + 24) - shift.customStart;
        if (hours > 16) conflict = ShiftConflictType.exceedsMaxHours;
      }

      // 3. < 8h rest from previous week's last day (boundary: dayIdx == 0 only)
      if (conflict == null && dayIdx == 0) {
        final empIdInt = int.tryParse(empId);
        final prev = empIdInt != null ? prevWeekLastDay[empIdInt] : null;
        if (prev != null && !prev.isLeave && !prev.isOffType) {
          final prevDay = shift.weekStart.subtract(const Duration(days: 1));
          final curDay = shift.weekStart;
          final prevEnd = _shiftDateTime(prevDay, prev.customEnd, nextDay: prev.customEnd < prev.customStart);
          final curStart = _shiftDateTime(curDay, shift.customStart);
          if (curStart.difference(prevEnd).inMinutes < 8 * 60) {
            conflict = ShiftConflictType.insufficientRestAfter;
          }
        }
      }

      // 4. < 8h rest from previous day's shift
      if (conflict == null && dayIdx > 0) {
        final prev = result['$empId-${dayIdx - 1}'];
        if (prev != null && !prev.isLeave && !prev.isOffType) {
          final prevDay = shift.weekStart.add(Duration(days: dayIdx - 1));
          final curDay = shift.weekStart.add(Duration(days: dayIdx));
          final prevEnd = _shiftDateTime(prevDay, prev.customEnd, nextDay: prev.customEnd < prev.customStart);
          final curStart = _shiftDateTime(curDay, shift.customStart);
          if (curStart.difference(prevEnd).inMinutes < 8 * 60) {
            conflict = ShiftConflictType.insufficientRestAfter;
          }
        }
      }

      // 5. < 8h rest before next day's shift
      if (conflict == null && dayIdx < 6) {
        final next = result['$empId-${dayIdx + 1}'];
        if (next != null && !next.isLeave && !next.isOffType) {
          final curDay = shift.weekStart.add(Duration(days: dayIdx));
          final nextDay = shift.weekStart.add(Duration(days: dayIdx + 1));
          final curEnd = _shiftDateTime(curDay, shift.customEnd, nextDay: shift.customEnd < shift.customStart);
          final nextStart = _shiftDateTime(nextDay, next.customStart);
          if (nextStart.difference(curEnd).inMinutes < 8 * 60) {
            conflict = ShiftConflictType.insufficientRestBefore;
          }
        }
      }

      // 6. < 8h rest before next week's first day (boundary: dayIdx == 6 only)
      if (conflict == null && dayIdx == 6) {
        final empIdInt = int.tryParse(empId);
        final next = empIdInt != null ? nextWeekFirstDay[empIdInt] : null;
        if (next != null && !next.isLeave && !next.isOffType) {
          final curDay = shift.weekStart.add(const Duration(days: 6));
          final nextDay = shift.weekStart.add(const Duration(days: 7));
          final curEnd = _shiftDateTime(curDay, shift.customEnd, nextDay: shift.customEnd < shift.customStart);
          final nextStart = _shiftDateTime(nextDay, next.customStart);
          if (nextStart.difference(curEnd).inMinutes < 8 * 60) {
            conflict = ShiftConflictType.insufficientRestBefore;
          }
        }
      }

      if (conflict != shift.conflict) {
        result[key] =
            conflict != null
                ? shift.copyWith(
                  conflict: conflict,
                  leaveType: conflict == ShiftConflictType.approvedLeave ? leaveKeys[key] : null,
                )
                : shift.copyWith(clearConflict: true);
      }
    }
    return result;
  }

  PublishState _derivePublishState(Map<String, ScheduleModel> schedule) {
    final shifts = schedule.values.where((s) => !s.isLeave);
    if (shifts.isEmpty) return PublishState.draft;
    return shifts.every((s) => s.isPublished) ? PublishState.published : PublishState.draft;
  }

  List<UserModel> _applyFilters(List<UserModel> team, ScheduleFilters filters, int managerId) {
    return team.where((e) {
      if (filters.department != null &&
          e.englishDepartment != filters.department &&
          e.department != filters.department) {
        return false;
      }
      if (filters.location != null && e.location != filters.location) {
        return false;
      }
      if (filters.teamScope == TeamScope.direct && e.n1 != managerId) {
        return false;
      }
      if (filters.teamScope == TeamScope.indirect && e.n2 != managerId) {
        return false;
      }
      return true;
    }).toList();
  }

  DateTime _monthOf(DateTime date) => DateTime(date.year, date.month);

  DateTime _weekStartOf(DateTime date) {
    return DateTime(date.year, date.month, date.day - (date.weekday % 7));
  }

  bool _sameWeek(DateTime date, DateTime weekStart) {
    final start = _weekStartOf(date);
    return start.year == weekStart.year && start.month == weekStart.month && start.day == weekStart.day;
  }

  bool _sameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isCurrentWeekSelected() {
    return _sameDate(state.weekStart, _weekStartOf(DateTime.now()));
  }

  bool _isInLoadedMonthRange(DateTime date) {
    final loadedMonth = state.loadedMonth;
    if (loadedMonth == null) return false;

    final firstDay = DateTime(loadedMonth.year, loadedMonth.month);
    final lastDay = DateTime(loadedMonth.year, loadedMonth.month + 1, 0);
    final firstVisibleDay = _weekStartOf(firstDay);
    final lastVisibleDay = _weekStartOf(lastDay).add(const Duration(days: 6));
    return !date.isBefore(firstVisibleDay) && !date.isAfter(lastVisibleDay);
  }

  ({int employeeId, DateTime date})? _parseMonthKey(String key) {
    final separator = key.indexOf('-');
    if (separator < 1 || separator >= key.length - 1) return null;

    final employeeId = int.tryParse(key.substring(0, separator));
    final date = DateTime.tryParse(key.substring(separator + 1));
    if (employeeId == null || date == null) return null;

    return (employeeId: employeeId, date: DateTime(date.year, date.month, date.day));
  }

  String _monthKey(int employeeId, DateTime date) {
    final datePart = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$employeeId-$datePart';
  }

  Future<void> _onSubmitSwapRequest(SubmitSwapRequest event, Emitter<ScheduleState> emit) async {
    try {
      final created = await _repo.submitSwapRequest(event.request);
      // Use enriched data from event.request; take only id from DB response
      // (the DB insert returns a bare row without JOINed name/date fields)
      final enriched = event.request.copyWith(id: created.id);
      emit(state.copyWith(mySwapRequests: [...state.mySwapRequests, enriched]));
    } catch (e) {
      emit(state.copyWith(failure: Failure(e.toString())));
    }
  }

  Future<void> _onAcceptSwapAsTarget(AcceptSwapAsTarget event, Emitter<ScheduleState> emit) async {
    try {
      await _repo.acceptSwapAsTarget(event.id);
      final accepted = state.incomingSwapRequests.firstWhere((r) => r.id == event.id);
      final pendingAccepted = accepted.copyWith(status: 'pending');
      emit(
        state.copyWith(
          incomingSwapRequests: state.incomingSwapRequests.where((r) => r.id != event.id).toList(),
          acceptedIncomingSwapRequests: [...state.acceptedIncomingSwapRequests, pendingAccepted],
          swapRequests: [...state.swapRequests, pendingAccepted],
        ),
      );
    } catch (e) {
      emit(state.copyWith(failure: Failure(e.toString())));
    }
  }

  Future<void> _onDeclineSwapAsTarget(DeclineSwapAsTarget event, Emitter<ScheduleState> emit) async {
    try {
      await _repo.declineSwapAsTarget(event.id);
      emit(state.copyWith(incomingSwapRequests: state.incomingSwapRequests.where((r) => r.id != event.id).toList()));
    } catch (e) {
      emit(state.copyWith(failure: Failure(e.toString())));
    }
  }

  Future<void> _onCancelSwapRequest(CancelSwapRequest event, Emitter<ScheduleState> emit) async {
    try {
      await _repo.cancelSwapRequest(event.id);
      final matches = [...state.mySwapRequests, ...state.acceptedIncomingSwapRequests].where((r) => r.id == event.id);
      final cancelled = matches.isEmpty ? null : matches.first;
      emit(
        state.copyWith(
          mySwapRequests: state.mySwapRequests.where((r) => r.id != event.id).toList(),
          acceptedIncomingSwapRequests: state.acceptedIncomingSwapRequests.where((r) => r.id != event.id).toList(),
          processedSwapRequests: [
            ...state.processedSwapRequests,
            if (cancelled != null) cancelled.copyWith(status: 'cancelled'),
          ],
        ),
      );
    } catch (e) {
      emit(state.copyWith(failure: Failure(e.toString())));
    }
  }
}
