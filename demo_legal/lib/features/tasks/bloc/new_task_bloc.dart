import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/validation/task_text.dart';
import '../../auth/data/user_profile.dart';
import '../data/assignee_option.dart';
import '../data/task_file.dart';
import '../data/task_save_failure.dart';
import '../data/task_topic.dart';
import '../data/tasks_repository.dart';
import '../data/team_member.dart';

part 'new_task_event.dart';
part 'new_task_state.dart';

/// The new-task modal (spec §4 "New task modal"): file, topic, assignee, due
/// date and the urgent flag. The title and description stay in the modal's
/// fields; the bloc gets them on submit and trims them.
///
/// Built from the shell's loaded lists, so opening it sends nothing. A lawyer
/// is always the assignee (RLS allows nothing else); a manager or admin
/// starts with nobody picked and must choose. The modal creates one per
/// opening.
///
/// With a [preset] (a contract's follow-up) the file and topic are fixed and
/// the task is saved with the preset's contract.
class NewTaskBloc extends Bloc<NewTaskEvent, NewTaskState> {
  NewTaskBloc({
    required this.files,
    required List<TaskTopic> topics,
    required this.team,
    required this.viewer,
    required String? initialFileId,
    required DateTime today,
    required this._tasksRepository,
    this.preset,
  })  : _topics = [...topics],
        super(NewTaskState(
          draft: _initialDraft(files, topics, viewer, initialFileId: initialFileId, today: today, preset: preset),
        )) {
    initialDraft = state.draft;
    on<NewTaskFileChanged>(_onFileChanged);
    on<NewTaskTopicChanged>((event, emit) {
      if (preset == null) _edit(emit, state.draft.copyWith(topicId: () => event.topicId));
    });
    on<NewTaskTopicAdded>(_onTopicAdded);
    on<NewTaskAssigneeChanged>(
      (event, emit) => _edit(emit, state.draft.copyWith(assigneeId: () => event.assigneeId)),
    );
    on<NewTaskDueChanged>((event, emit) => _edit(emit, state.draft.copyWith(dueDate: event.dueDate)));
    on<NewTaskUrgentChanged>((event, emit) => _edit(emit, state.draft.copyWith(isManualUrgent: event.isManualUrgent)));
    on<NewTaskSubmitted>(_onSubmitted);
  }

  /// The files the viewer sees, in chip order (RLS: a lawyer's own files).
  final List<TaskFile> files;

  /// The loaded topics, plus any made from the modal since it opened.
  List<TaskTopic> get topics => List.unmodifiable(_topics);
  final List<TaskTopic> _topics;

  /// Active people with their memberships, for the assignee list.
  final List<TeamMember> team;
  final UserProfile viewer;
  final TasksRepository _tasksRepository;

  /// A follow-up's fixed file, brand and contract; null for a plain task.
  final NewTaskPreset? preset;

  /// The title the modal starts with: the preset's, or empty.
  String get initialTitle => preset?.title ?? '';

  /// The draft as the modal opened, for [isDirty].
  late final NewTaskDraft initialDraft;

  /// A lawyer may only assign a task to themselves.
  bool get assignsSelf => !viewer.role.managesFiles;

  /// The selected file's topics, oldest first.
  List<TaskTopic> get fileTopics => topicsIn(state.draft.fileId);

  List<TaskTopic> topicsIn(String? fileId) => [
        for (final t in _topics)
          if (t.fileId == fileId) t,
      ];

  /// Who a manager or admin may pick in the selected file (the drawer's
  /// rule); empty with no file.
  List<AssigneeOption> get assigneeOptions => optionsIn(state.draft.fileId);

  List<AssigneeOption> optionsIn(String? fileId) =>
      fileId == null ? const [] : AssigneeOption.fromTeam(team, fileId: fileId, viewerId: viewer.id);

  /// Whether the form may be saved with this [title] and [description].
  bool canSave(String title, String description) {
    final draft = state.draft;
    return state.status == NewTaskStatus.editing &&
        draft.topicId != null &&
        draft.assigneeId != null &&
        TaskText.isValidTitle(title) &&
        TaskText.isValidDescription(description);
  }

  /// Whether closing would lose something: any typed text (even spaces), a
  /// title changed from the one it started with, or a changed pick.
  bool isDirty(String title, String description) =>
      title != initialTitle || description.isNotEmpty || state.draft != initialDraft;

  static NewTaskDraft _initialDraft(
    List<TaskFile> files,
    List<TaskTopic> topics,
    UserProfile viewer, {
    required String? initialFileId,
    required DateTime today,
    required NewTaskPreset? preset,
  }) {
    final fileId = preset?.fileId ?? (files.any((f) => f.id == initialFileId) ? initialFileId : files.firstOrNull?.id);
    return NewTaskDraft(
      fileId: fileId,
      topicId: preset?.topicId ?? _firstTopic(topics, fileId),
      assigneeId: viewer.role.managesFiles ? null : viewer.id,
      dueDate: DateTime(today.year, today.month, today.day),
    );
  }

  static String? _firstTopic(List<TaskTopic> topics, String? fileId) =>
      topics.where((t) => t.fileId == fileId).firstOrNull?.id;

  void _edit(Emitter<NewTaskState> emit, NewTaskDraft draft) {
    if (state.status != NewTaskStatus.editing) return;
    emit(NewTaskState(draft: draft));
  }

  /// A new file resets the topic to its first one (as in the canvas) and
  /// drops a picked person who can't take a task there.
  void _onFileChanged(NewTaskFileChanged event, Emitter<NewTaskState> emit) {
    final draft = state.draft;
    if (preset != null || event.fileId == draft.fileId) return;
    final assigneeId = draft.assigneeId;
    final keeps = assignsSelf || optionsIn(event.fileId).any((o) => o.id == assigneeId);
    _edit(
      emit,
      draft.copyWith(
        fileId: () => event.fileId,
        topicId: () => _firstTopic(_topics, event.fileId),
        assigneeId: () => keeps ? assigneeId : null,
      ),
    );
  }

  /// A topic made with «+ موضوع جديد» joins the list and is picked, if its
  /// file is still the selected one.
  void _onTopicAdded(NewTaskTopicAdded event, Emitter<NewTaskState> emit) {
    if (state.status != NewTaskStatus.editing || preset != null) return;
    final topic = event.topic;
    if (!_topics.any((t) => t.id == topic.id)) _topics.add(topic);
    if (topic.fileId == state.draft.fileId) _edit(emit, state.draft.copyWith(topicId: () => topic.id));
  }

  Future<void> _onSubmitted(NewTaskSubmitted event, Emitter<NewTaskState> emit) async {
    if (!canSave(event.title, event.description)) return;
    final draft = state.draft;
    emit(NewTaskState(draft: draft, status: NewTaskStatus.saving));
    try {
      final id = await _tasksRepository.createTask(
        topicId: draft.topicId!,
        title: event.title.trim(),
        description: event.description.trim(),
        assigneeId: draft.assigneeId!,
        dueDate: draft.dueDate,
        isManualUrgent: draft.isManualUrgent,
        contractId: preset?.contractId,
      );
      emit(NewTaskState(draft: draft, status: NewTaskStatus.saved, savedId: id));
    } on TaskSaveException catch (error) {
      emit(NewTaskState(draft: draft, failure: error.failure));
    }
  }
}
