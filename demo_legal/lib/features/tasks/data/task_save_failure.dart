/// Why a change made in the task drawer, or a new task, wasn't saved, in terms
/// the form can show.
enum TaskSaveFailure {
  /// RLS refused: 0 rows updated, or a write the policy rejects.
  notAllowed,

  /// The assignee guard: the person is inactive, or a lawyer outside the file.
  assigneeRejected,

  /// No response from the server.
  network,
  unknown;

  /// Maps an error from a `tasks` insert or update.
  ///
  /// PostgREST errors carry the SQLSTATE but not the constraint name, so the
  /// guard is recognised by its message (`private.guard_task_assignee`).
  /// Anything that isn't a PostgREST or [TaskSaveException] error came from the
  /// HTTP layer (e.g. `ClientException` from `package:http`, which the app
  /// doesn't depend on directly), so it counts as [network].
  static TaskSaveFailure fromError(Object error) => switch (error) {
        TaskSaveException(:final failure) => failure,
        _ => network,
      };
}

/// Thrown by `TasksRepository.updateTask` and `createTask`.
class TaskSaveException implements Exception {
  const TaskSaveException(this.failure);

  final TaskSaveFailure failure;

  @override
  String toString() => 'TaskSaveException($failure)';
}
