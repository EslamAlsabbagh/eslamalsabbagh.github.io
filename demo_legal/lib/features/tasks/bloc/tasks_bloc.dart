import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/live_changes.dart';
import '../data/task_file.dart';
import '../data/task_list_item.dart';
import '../data/task_topic.dart';
import '../data/tasks_repository.dart';
import '../data/team_member.dart';
import 'person_groups.dart';
import 'topic_groups.dart';

export 'person_groups.dart';
export 'topic_groups.dart';

part 'tasks_event.dart';
part 'tasks_state.dart';

/// The «المهام والأولوية», «المواضيع» and «الموظفون» views, the tab and file chip of every view (also «العقود»), and
/// the header counters. Provided by the shell, so it lives
/// only while someone is signed in.
///
/// It follows other people's changes: each one heard from [liveChanges] (or a
/// burst of them) reloads quietly, and so does midnight.
class TasksBloc extends Bloc<TasksEvent, TasksState> {
  TasksBloc({
    required this._tasksRepository,
    Stream<LiveChange> liveChanges = const Stream.empty(),
    this._searchDelay = const Duration(milliseconds: 300),
    this._liveDelay = const Duration(milliseconds: 500),
    this._clock = DateTime.now,
  }) : super(const TasksState()) {
    on<TasksLoadRequested>(_onLoadRequested);
    on<TasksRefreshRequested>(_onRefreshRequested);
    on<TasksDayChanged>(_onDayChanged);
    on<TasksTaskCreated>(_onTaskCreated);
    on<TasksTabSelected>(_onTabSelected);
    on<TasksFileSelected>(_onFileSelected);
    on<TasksClosedToggled>(_onClosedToggled);
    on<TasksSearchChanged>(_onSearchChanged);
    _liveSubscription = liveChanges.listen(_onLiveChange);
    _scheduleMidnight();
  }

  final TasksRepository _tasksRepository;

  /// The pause in typing before a search is sent.
  final Duration _searchDelay;

  /// How long a burst of changes is gathered into one reload. One save is a
  /// `tasks` update plus its history rows, and several people may save at once.
  final Duration _liveDelay;

  /// "Now", for the midnight reload.
  final DateTime Function() _clock;

  late final StreamSubscription<LiveChange> _liveSubscription;
  Timer? _liveTimer;
  Timer? _midnightTimer;

  /// Reads are numbered, so an older one that lands after a newer one is
  /// dropped instead of putting stale rows back.
  int _fetchesStarted = 0;
  int _fetchApplied = 0;

  /// A file a refresh asked to select, and the first read that may know it
  /// (see [_fetch]).
  ({String fileId, int from})? _pendingSelect;

  /// Each change is only a signal: the rows are read again, so urgency stays
  /// the database's. Nothing is read before the first load has landed (that
  /// load, or retry, reads everything anyway). The bell's own table changes
  /// no list: each event it reports comes with its own tasks change. The
  /// contracts tables are the «العقود» list's.
  void _onLiveChange(LiveChange change) {
    if (change.table == LiveTable.notifications || LiveTable.contractTables.contains(change.table)) return;
    _liveTimer?.cancel();
    _liveTimer = Timer(_liveDelay, () {
      if (!isClosed && state.status == TasksStatus.success) add(const TasksRefreshRequested());
    });
  }

  /// A few seconds after the device's midnight. Office devices run on Cairo
  /// time; the database still decides what "today" is, this only decides
  /// when to ask again.
  void _scheduleMidnight() {
    final now = _clock();
    final next = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    _midnightTimer = Timer(next.difference(now), () {
      if (isClosed) return;
      add(const TasksDayChanged());
      _scheduleMidnight();
    });
  }

  @override
  Future<void> close() async {
    _liveTimer?.cancel();
    _midnightTimer?.cancel();
    await _liveSubscription.cancel();
    return super.close();
  }

  Future<void> _onLoadRequested(TasksLoadRequested event, Emitter<TasksState> emit) async {
    emit(state.copyWith(status: TasksStatus.loading));
    try {
      await _fetch(emit);
    } catch (error, stackTrace) {
      log('Loading tasks failed', name: 'tasks', error: error, stackTrace: stackTrace);
      emit(state.copyWith(status: TasksStatus.failure));
      return;
    }
    await _researchIfActive(emit);
  }

  Future<void> _onRefreshRequested(TasksRefreshRequested event, Emitter<TasksState> emit) async {
    final select = event.selectFileId;
    if (select != null) _pendingSelect = (fileId: select, from: _fetchesStarted + 1);
    try {
      await _fetch(emit);
    } catch (error, stackTrace) {
      log('Refreshing tasks failed', name: 'tasks', error: error, stackTrace: stackTrace);
      return;
    }
    await _researchIfActive(emit);
  }

  Future<void> _onDayChanged(TasksDayChanged event, Emitter<TasksState> emit) async {
    emit(state.copyWith(dayRevision: state.dayRevision + 1));
    if (state.status != TasksStatus.success) return;
    await _onRefreshRequested(const TasksRefreshRequested(), emit);
  }

  /// Loads everything. A file asked for by a refresh ([_pendingSelect])
  /// replaces the selected one if it is visible; a read dropped as stale
  /// leaves that for the read that lands.
  Future<void> _fetch(Emitter<TasksState> emit) async {
    final generation = ++_fetchesStarted;
    final (tasks, files, topics, team) = await (
      _tasksRepository.fetchTasks(),
      _tasksRepository.fetchFiles(),
      _tasksRepository.fetchTopics(),
      _tasksRepository.fetchTeam(),
    ).wait;
    if (generation < _fetchApplied) return;
    _fetchApplied = generation;
    // Only a read started after the request can have the new file.
    final pending = _pendingSelect;
    String? select;
    if (pending != null && generation >= pending.from) {
      select = pending.fileId;
      _pendingSelect = null;
    }
    bool visible(String? id) => id != null && files.any((f) => f.id == id);
    // A file that is no longer visible can't stay selected.
    final selected = visible(select) ? select : state.selectedFileId;
    final keep = visible(selected);
    emit(state.copyWith(
      status: TasksStatus.success,
      tasks: tasks,
      files: files,
      topics: topics,
      team: team,
      selectedFileId: () => keep ? selected : null,
    ));
  }

  Future<void> _onTaskCreated(TasksTaskCreated event, Emitter<TasksState> emit) async {
    final selected = state.selectedFileId;
    final searching = state.searchQuery.isNotEmpty;
    emit(state.copyWith(
      tab: TasksTab.tasks,
      selectedFileId: () => selected == null ? null : event.fileId,
      searchQuery: '',
      searchStatus: TasksSearchStatus.idle,
      searchIds: () => null,
      searchedTerm: '',
      searchResets: searching ? state.searchResets + 1 : null,
    ));
    try {
      await _fetch(emit);
    } catch (error, stackTrace) {
      log('Refreshing tasks failed', name: 'tasks', error: error, stackTrace: stackTrace);
    }
  }

  void _onTabSelected(TasksTabSelected event, Emitter<TasksState> emit) {
    emit(state.copyWith(tab: event.tab));
  }

  void _onFileSelected(TasksFileSelected event, Emitter<TasksState> emit) {
    emit(state.copyWith(selectedFileId: () => event.fileId));
  }

  void _onClosedToggled(TasksClosedToggled event, Emitter<TasksState> emit) {
    emit(state.copyWith(showClosed: !state.showClosed));
  }

  Future<void> _onSearchChanged(TasksSearchChanged event, Emitter<TasksState> emit) async {
    if (event.query.trim().length < TasksState.minSearchLength) {
      emit(state.copyWith(
        searchQuery: event.query,
        searchStatus: TasksSearchStatus.idle,
        searchIds: () => null,
        searchedTerm: '',
      ));
      return;
    }
    emit(state.copyWith(searchQuery: event.query, searchStatus: TasksSearchStatus.loading));
    await Future<void>.delayed(_searchDelay);
    // Typed again during the pause: that later event searches instead.
    if (state.searchQuery != event.query) return;
    await _search(emit);
  }

  /// Searches for the current term. A response that arrives after the term
  /// has changed is dropped.
  Future<void> _search(Emitter<TasksState> emit) async {
    final term = state.searchTerm;
    try {
      final ids = await _tasksRepository.searchTaskIds(term);
      if (state.searchTerm != term) return;
      final next = state.copyWith(
        searchStatus: TasksSearchStatus.success,
        searchIds: () => ids,
        searchedTerm: term,
      );
      // A new search with closed matches opens «المكتملة» (a re-run doesn't,
      // so a list the user collapsed stays collapsed).
      final opensClosed = term != state.searchedTerm && next.closed.isNotEmpty;
      emit(opensClosed ? next.copyWith(showClosed: true) : next);
    } catch (error, stackTrace) {
      log('Searching tasks failed', name: 'tasks', error: error, stackTrace: stackTrace);
      if (state.searchTerm != term) return;
      emit(state.copyWith(
        searchStatus: TasksSearchStatus.failure,
        searchIds: () => null,
        searchedTerm: '',
      ));
    }
  }

  /// After a reload a title may have changed, so an active search runs again.
  Future<void> _researchIfActive(Emitter<TasksState> emit) async {
    if (state.searchStatus == TasksSearchStatus.idle) return;
    await _search(emit);
  }
}
