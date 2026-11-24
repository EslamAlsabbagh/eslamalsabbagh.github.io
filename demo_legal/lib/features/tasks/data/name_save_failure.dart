/// Why a file or topic wasn't saved or deleted, in terms the name modal can
/// show.
enum NameSaveFailure {
  /// The unique normalized name: another file (or topic in the same file)
  /// has the same name once أ/ا, ة/ه, ى/ي and tashkeel are ignored.
  duplicate,

  /// RLS refused: 0 rows renamed or deleted, or an insert the policy rejects.
  notAllowed,

  /// A delete the `on delete restrict` foreign keys refused: the file has a
  /// topic, or the topic a task, added since the modal opened.
  notEmpty,

  /// No response from the server.
  network,
  unknown;

  /// Maps an error from a `files` / `topics` write. Anything that
  /// isn't a PostgREST or [NameSaveException] error came from the HTTP layer,
  /// as in `TaskSaveFailure.fromError`.
  static NameSaveFailure fromError(Object error) => switch (error) {
        NameSaveException(:final failure) => failure,
        _ => network,
      };
}

/// Thrown by the `TasksRepository` file and topic writes.
class NameSaveException implements Exception {
  const NameSaveException(this.failure);

  final NameSaveFailure failure;

  @override
  String toString() => 'NameSaveException($failure)';
}
