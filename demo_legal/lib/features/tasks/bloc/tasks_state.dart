part of 'tasks_bloc.dart';

enum TasksStatus { loading, success, failure }

/// The view tabs (spec §4 "View tabs").
enum TasksTab { tasks, topics, people, contracts }

/// The search's request state. [idle] means there is no search.
enum TasksSearchStatus { idle, loading, success, failure }

/// Every visible task plus the views' tab, filter and search. Sections,
/// topic cards and counters are derived here, so the header and the views
/// always agree.
final class TasksState extends Equatable {
  const TasksState({
    this.status = TasksStatus.loading,
    this.tasks = const [],
    this.files = const [],
    this.topics = const [],
    this.team = const [],
    this.tab = TasksTab.tasks,
    this.selectedFileId,
    this.showClosed = false,
    this.searchQuery = '',
    this.searchStatus = TasksSearchStatus.idle,
    this.searchIds,
    this.searchedTerm = '',
    this.searchResets = 0,
    this.dayRevision = 0,
  });

  /// A search starts at this many letters (DESIGN_SPEC §4 "Search").
  static const int minSearchLength = 2;

  final TasksStatus status;

  /// In the repository's order: open tasks by section and due date first.
  final List<TaskListItem> tasks;
  final List<TaskFile> files;
  final List<TaskTopic> topics;

  /// Active people, oldest account first (the «الموظفون» cards' order).
  final List<TeamMember> team;
  final TasksTab tab;

  /// Null means «كل الملفات».
  final String? selectedFileId;
  final bool showClosed;

  /// What is in the search field, as typed.
  final String searchQuery;
  final TasksSearchStatus searchStatus;

  /// The matches for [searchedTerm], or null when no search result is shown.
  /// The previous result stays while the next one loads, so rows don't flicker.
  final Set<String>? searchIds;

  /// The term [searchIds] belong to; the result line quotes it.
  final String searchedTerm;

  /// Counts searches cleared by the app (a new task was created). The field
  /// is keyed by it, so it starts again empty.
  final int searchResets;

  /// Goes up when the date changes at midnight, so the header's date is
  /// rebuilt even when no row changed.
  final int dayRevision;

  /// The query the database is asked about.
  String get searchTerm => searchQuery.trim();

  /// Tasks in the selected file (all of them when none is selected). The
  /// header counters use this: the search never changes them.
  List<TaskListItem> get _fileScoped =>
      selectedFileId == null ? tasks : tasks.where((t) => t.fileId == selectedFileId).toList();

  /// [_fileScoped] narrowed to the search matches. The sections use this.
  List<TaskListItem> get _visible {
    final ids = searchIds;
    return ids == null ? _fileScoped : _fileScoped.where((t) => ids.contains(t.id)).toList();
  }

  /// «عاجلة — تُنجز اليوم»: overdue first, then due today or flagged.
  List<TaskListItem> get urgent => _visible.where((t) => t.sortGroup <= 1).toList();

  /// «القادمة»: open and not urgent, nearest due date first.
  List<TaskListItem> get upcoming => _visible.where((t) => t.sortGroup == 2).toList();

  /// «المكتملة»: done and cancelled, most recently closed first.
  List<TaskListItem> get closed {
    final list = _visible.where((t) => t.sortGroup == 3).toList();
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    list.sort((a, b) => (b.completedAt ?? epoch).compareTo(a.completedAt ?? epoch));
    return list;
  }

  /// «المواضيع»: a section per file (the selected one only), each with its
  /// topic cards. The search belongs to the tasks tab and never narrows it.
  List<FileTopics> get topicGroups => buildTopicGroups(
        files: selectedFileId == null ? files : files.where((f) => f.id == selectedFileId).toList(),
        topics: topics,
        tasks: tasks,
      );

  /// «الموظفون»: a card per member lawyer of the visible files (the selected
  /// one only) and per assignee of an open task there. Like the topics, the
  /// search never narrows it.
  List<PersonSummary> get personGroups => buildPersonGroups(
        team: team,
        fileIds: {
          for (final f in files)
            if (selectedFileId == null || f.id == selectedFileId) f.id,
        },
        tasks: _fileScoped,
      );

  /// Matches shown in the sections (the selected file only), or null when no
  /// search result is shown.
  int? get searchResultCount => searchIds == null ? null : _visible.length;

  /// Header counters. Urgent includes overdue, as in the design.
  int get urgentCount => _fileScoped.where((t) => t.isUrgentNow).length;
  int get overdueCount => _fileScoped.where((t) => t.isOverdue).length;
  int get openCount => _fileScoped.where((t) => t.isOpen).length;

  /// The Cairo date, as of the last load: any row's due date minus its
  /// `days_until_due`, both from the database. [fallback]'s date when there
  /// are no tasks (only a new task's default due date depends on it).
  DateTime cairoToday(DateTime fallback) {
    if (tasks.isEmpty) return DateTime(fallback.year, fallback.month, fallback.day);
    final t = tasks.first;
    return DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day - t.daysUntilDue);
  }

  /// Open tasks in [fileId], or in every file when null (the chip badges).
  int openCountFor(String? fileId) =>
      tasks.where((t) => t.isOpen && (fileId == null || t.fileId == fileId)).length;

  TasksState copyWith({
    TasksStatus? status,
    List<TaskListItem>? tasks,
    List<TaskFile>? files,
    List<TaskTopic>? topics,
    List<TeamMember>? team,
    TasksTab? tab,
    String? Function()? selectedFileId,
    bool? showClosed,
    String? searchQuery,
    TasksSearchStatus? searchStatus,
    Set<String>? Function()? searchIds,
    String? searchedTerm,
    int? searchResets,
    int? dayRevision,
  }) =>
      TasksState(
        status: status ?? this.status,
        tasks: tasks ?? this.tasks,
        files: files ?? this.files,
        topics: topics ?? this.topics,
        team: team ?? this.team,
        tab: tab ?? this.tab,
        selectedFileId: selectedFileId != null ? selectedFileId() : this.selectedFileId,
        showClosed: showClosed ?? this.showClosed,
        searchQuery: searchQuery ?? this.searchQuery,
        searchStatus: searchStatus ?? this.searchStatus,
        searchIds: searchIds != null ? searchIds() : this.searchIds,
        searchedTerm: searchedTerm ?? this.searchedTerm,
        searchResets: searchResets ?? this.searchResets,
        dayRevision: dayRevision ?? this.dayRevision,
      );

  @override
  List<Object?> get props => [
        status,
        tasks,
        files,
        topics,
        team,
        tab,
        selectedFileId,
        showClosed,
        searchQuery,
        searchStatus,
        searchIds,
        searchedTerm,
        searchResets,
        dayRevision,
      ];
}
