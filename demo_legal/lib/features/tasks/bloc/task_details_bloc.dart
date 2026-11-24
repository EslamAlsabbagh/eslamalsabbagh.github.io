import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/task_status.dart';
import '../../../core/domain/user_role.dart';
import '../../../core/validation/task_text.dart';
import '../../auth/data/user_profile.dart';
import '../data/assignee_option.dart';
import '../data/live_changes.dart';
import '../data/task_activity_entry.dart';
import '../data/task_details.dart';
import '../data/task_list_item.dart';
import '../data/task_save_failure.dart';
import '../data/task_update_entry.dart';
import '../data/tasks_repository.dart';

part 'task_details_event.dart';
part 'task_details_state.dart';

/// The task drawer: loads one task, its updates, its history and (for managers
/// and admins) the people it can be assigned to, saves each change as it is
/// made, and posts updates.
///
/// A change is never applied locally first: after a save the task is read
/// back from `task_list`, so urgency, flag and due label stay the database's.
/// The drawer creates one per opening.
///
/// Changes made elsewhere to this task (or to the names it shows), heard from
/// [liveChanges], read it all again quietly.
class TaskDetailsBloc extends Bloc<TaskDetailsEvent, TaskDetailsState> {
  TaskDetailsBloc({
    required TaskListItem task,
    required UserProfile viewer,
    required this._tasksRepository,
    Stream<LiveChange> liveChanges = const Stream.empty(),
    this._liveDelay = const Duration(milliseconds: 500),
  }) : super(TaskDetailsState(item: task, viewer: viewer)) {
    on<TaskDetailsLoadRequested>(_onLoadRequested);
    on<TaskDetailsRefreshRequested>(_onRefreshRequested);
    on<TaskDetailsStatusPicked>((event, emit) async {
      if (event.status != state.item.status) await _save(emit, status: event.status);
    });
    on<TaskDetailsAssigneePicked>((event, emit) async {
      if (event.assigneeId != state.item.assigneeId) await _save(emit, assigneeId: event.assigneeId);
    });
    on<TaskDetailsDuePicked>((event, emit) async {
      if (!_sameDay(event.dueDate, state.item.dueDate)) await _save(emit, dueDate: event.dueDate);
    });
    on<TaskDetailsUrgentToggled>((event, emit) async {
      if (event.isManualUrgent != state.details?.isManualUrgent) {
        await _save(emit, isManualUrgent: event.isManualUrgent);
      }
    });
    on<TaskDetailsCancelConfirmed>((event, emit) => _save(emit, status: TaskStatus.cancelled));
    on<TaskDetailsEditStarted>((event, emit) {
      if (!state.canSave) return;
      emit(state.copyWith(
        editingText: true,
        failure: () => null,
        editBaseTitle: state.item.title,
        editBaseDescription: state.details?.description ?? '',
      ));
    });
    on<TaskDetailsEditCancelled>((event, emit) {
      emit(state.copyWith(editingText: false, editBaseTitle: '', editBaseDescription: '', failure: () => null));
    });
    on<TaskDetailsTextSaved>(_onTextSaved);
    on<TaskDetailsUpdatePosted>(_onUpdatePosted);
    _liveSubscription = liveChanges.where(_concernsThisTask).listen(_onLiveChange);
  }

  final TasksRepository _tasksRepository;

  /// How long a burst of changes is gathered into one read (see `TasksBloc`).
  final Duration _liveDelay;

  late final StreamSubscription<LiveChange> _liveSubscription;
  Timer? _liveTimer;

  /// Goes up when a save or a post starts, so a quiet read that was already
  /// on its way is dropped: that write's own read-back is newer.
  int _writes = 0;

  /// Goes up with every quiet read, so only the latest one lands.
  int _refreshes = 0;

  /// This task's row or updates; the names, topic and file it shows; or
  /// a rejoin, after which anything may have changed.
  bool _concernsThisTask(LiveChange change) => switch (change.table) {
        null => change.resync,
        LiveTable.tasks || LiveTable.taskUpdates => change.taskId == state.item.id,
        LiveTable.files || LiveTable.topics || LiveTable.profiles || LiveTable.fileMembers => true,
        // The bell's; a change it reports arrives as its own tasks change.
        LiveTable.notifications => false,
        // The «العقود» list's.
        LiveTable.contracts ||
        LiveTable.contractUnits ||
        LiveTable.contractItems ||
        LiveTable.parties ||
        LiveTable.units =>
          false,
      };

  void _onLiveChange(LiveChange _) {
    _liveTimer?.cancel();
    _liveTimer = Timer(_liveDelay, () {
      if (!isClosed) add(const TaskDetailsRefreshRequested());
    });
  }

  @override
  Future<void> close() async {
    _liveTimer?.cancel();
    await _liveSubscription.cancel();
    return super.close();
  }

  /// Everything the drawer shows, read together.
  Future<(TaskDetails, List<TaskUpdateEntry>, List<TaskActivityEntry>, List<AssigneeOption>)> _readAll() {
    final item = state.item;
    return (
      _tasksRepository.fetchTask(item.id),
      _tasksRepository.fetchUpdates(item.id),
      _tasksRepository.fetchActivity(item.id),
      state.canReassign
          ? _tasksRepository.fetchAssigneeOptions(
              fileId: item.fileId,
              viewerId: state.viewer.id,
              currentAssigneeId: item.assigneeId,
              currentAssigneeName: item.assigneeName,
            )
          : Future.value(const <AssigneeOption>[]),
    ).wait;
  }

  Future<void> _onLoadRequested(TaskDetailsLoadRequested event, Emitter<TaskDetailsState> emit) async {
    emit(state.copyWith(load: TaskDetailsLoad.loading));
    final item = state.item;
    try {
      final (details, updates, activity, assignees) = await _readAll();
      emit(state.copyWith(
        load: TaskDetailsLoad.success,
        item: details.item,
        details: () => details,
        updates: updates,
        activity: activity,
        assignees: assignees,
      ));
    } catch (error, stackTrace) {
      log('Loading task ${item.id} failed', name: 'tasks', error: error, stackTrace: stackTrace);
      emit(state.copyWith(load: TaskDetailsLoad.failure));
    }
  }

  /// Never shows loading, so the controls don't flicker. Skipped until the
  /// drawer has loaded (a failed one keeps its retry) and while a write is in
  /// flight (its read-back covers it, and its own echo reads again after).
  Future<void> _onRefreshRequested(TaskDetailsRefreshRequested event, Emitter<TaskDetailsState> emit) async {
    if (state.load != TaskDetailsLoad.success || state.saving || state.posting) return;
    final writes = _writes;
    final refresh = ++_refreshes;
    try {
      final (details, updates, activity, assignees) = await _readAll();
      if (writes != _writes || refresh != _refreshes) return;
      emit(state.copyWith(
        item: details.item,
        details: () => details,
        updates: updates,
        activity: activity,
        assignees: assignees,
      ));
    } catch (error, stackTrace) {
      // E.g. the task is no longer visible: the last copy stays.
      log('Refreshing task ${state.item.id} failed', name: 'tasks', error: error, stackTrace: stackTrace);
    }
  }

  /// Sends only the fields that changed. Nothing changed just closes the form;
  /// text over the limits is never sent (the form can't submit it either).
  Future<void> _onTextSaved(TaskDetailsTextSaved event, Emitter<TaskDetailsState> emit) async {
    final details = state.details;
    if (!state.editingText || details == null) return;
    final title = event.title.trim();
    final description = event.description.trim();
    if (!TaskText.isValidTitle(title) || !TaskText.isValidDescription(description)) return;
    // Against what the form opened with, so a change someone else made
    // meanwhile to the other field isn't sent back over theirs.
    final titleChanged = title != state.editBaseTitle;
    final descriptionChanged = description != state.editBaseDescription;
    if (!titleChanged && !descriptionChanged) {
      emit(state.copyWith(editingText: false, editBaseTitle: '', editBaseDescription: '', failure: () => null));
      return;
    }
    await _save(
      emit,
      title: titleChanged ? title : null,
      description: descriptionChanged ? description : null,
    );
  }

  /// Posts an update, then reads the updates back (never adds the row
  /// locally, so the author's name and time are the database's). Blank text
  /// or text over the limit is never sent; the box can't submit it either.
  Future<void> _onUpdatePosted(TaskDetailsUpdatePosted event, Emitter<TaskDetailsState> emit) async {
    final body = event.body.trim();
    if (!state.canPost || !TaskText.isValidUpdate(body)) return;
    _writes++;
    emit(state.copyWith(posting: true, postFailure: () => null));
    final id = state.item.id;
    try {
      await _tasksRepository.addUpdate(id, body);
    } on TaskSaveException catch (error) {
      // The typed text stays in the box.
      emit(state.copyWith(posting: false, postFailure: () => error.failure));
      return;
    }
    // Posted: the box clears even if the read-back fails, and the list behind
    // refreshes its update count either way.
    try {
      final updates = await _tasksRepository.fetchUpdates(id);
      emit(state.copyWith(
        posting: false,
        updates: updates,
        postedRevision: state.postedRevision + 1,
        savedRevision: state.savedRevision + 1,
      ));
    } catch (error, stackTrace) {
      log('Reading the updates of task $id back failed', name: 'tasks', error: error, stackTrace: stackTrace);
      emit(state.copyWith(
        posting: false,
        load: TaskDetailsLoad.failure,
        postedRevision: state.postedRevision + 1,
        savedRevision: state.savedRevision + 1,
      ));
    }
  }

  /// Saves one change, then reads the task back.
  Future<void> _save(
    Emitter<TaskDetailsState> emit, {
    TaskStatus? status,
    String? assigneeId,
    DateTime? dueDate,
    bool? isManualUrgent,
    String? title,
    String? description,
  }) async {
    if (!state.canSave) return;
    _writes++;
    emit(state.copyWith(saving: true, failure: () => null));
    final id = state.item.id;
    try {
      await _tasksRepository.updateTask(
        id,
        status: status,
        assigneeId: assigneeId,
        dueDate: dueDate,
        isManualUrgent: isManualUrgent,
        title: title,
        description: description,
      );
    } on TaskSaveException catch (error) {
      // A failed text save keeps the form open, with what was typed.
      emit(state.copyWith(saving: false, failure: () => error.failure));
      return;
    }
    // The text is saved: the form closes even if the read-back fails.
    final textSaved = title != null || description != null;
    try {
      // The history too, so the change just made is listed at once.
      final (details, activity) = await (_tasksRepository.fetchTask(id), _tasksRepository.fetchActivity(id)).wait;
      emit(state.copyWith(
        saving: false,
        item: details.item,
        details: () => details,
        activity: activity,
        savedRevision: state.savedRevision + 1,
        editingText: textSaved ? false : null,
        editBaseTitle: textSaved ? '' : null,
        editBaseDescription: textSaved ? '' : null,
      ));
    } catch (error, stackTrace) {
      // Saved, but the fresh copy didn't arrive: show the retry, still
      // refresh the list behind.
      log('Reading task $id back failed', name: 'tasks', error: error, stackTrace: stackTrace);
      emit(state.copyWith(
        saving: false,
        load: TaskDetailsLoad.failure,
        savedRevision: state.savedRevision + 1,
        editingText: textSaved ? false : null,
        editBaseTitle: textSaved ? '' : null,
        editBaseDescription: textSaved ? '' : null,
      ));
    }
  }
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
