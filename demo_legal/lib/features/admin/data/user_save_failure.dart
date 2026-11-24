
/// Why an admin's change to an account wasn't saved, in terms the users page
/// can show.
enum UserSaveFailure {
  /// Not an active admin (RLS, the guards, or the function's 403), or the
  /// row wasn't updatable (0 rows).
  notAllowed,

  /// Deactivating someone who still has open tasks (`profiles_open_tasks`).
  openTasks,

  /// Taking a lawyer off a file where they have open tasks
  /// (`file_members_open_tasks`).
  openTasksInFile,

  /// Making someone a lawyer while they have open tasks in files that
  /// aren't ticked (`profiles_open_tasks_outside_files`).
  openTasksOutsideFiles,

  /// Another account already has this email.
  emailTaken,

  /// GoTrue refused the password (shorter than 8).
  weakPassword,

  /// No response from the server.
  network,
  unknown;

  /// Maps an error from `admin_save_user`, a `profiles` update or the
  /// `admin-users` function. The function passes Postgres errors through as
  /// `{code, message}`, so both read the same. Guard errors share 23503 and
  /// are told apart by their message, as `TaskSaveFailure` does.
  static UserSaveFailure fromError(Object error) => switch (error) {
    UserSaveException(:final failure) => failure,
    _ => network,
  };
}

/// Thrown by `UsersRepository` writes.
class UserSaveException implements Exception {
  const UserSaveException(this.failure);

  final UserSaveFailure failure;

  @override
  String toString() => 'UserSaveException($failure)';
}
