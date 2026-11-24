/// Task status. Names match the Postgres `task_status` enum values.
enum TaskStatus {
  todo,
  doing,
  waiting,
  done,
  cancelled;

  /// Parses the DB value; throws [ArgumentError] on an unknown name.
  static TaskStatus fromDb(String value) => TaskStatus.values.byName(value);

  /// Done or cancelled. Closed tasks are listed under «المكتملة».
  bool get isClosed => this == done || this == cancelled;
}
