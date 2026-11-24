part of 'name_dialog_bloc.dart';

enum NameDialogStatus { editing, saving, saved, deleting, deleted }

final class NameDialogState extends Equatable {
  const NameDialogState({this.status = NameDialogStatus.editing, this.failure, this.savedId, this.savedName});

  final NameDialogStatus status;

  /// Why the last save or delete failed; cleared by the next attempt.
  final NameSaveFailure? failure;

  /// The created, renamed or deleted row's id, once [NameDialogStatus.saved]
  /// or [NameDialogStatus.deleted].
  final String? savedId;

  /// The name as saved (trimmed), or the deleted row's name, alongside
  /// [savedId]; the new-task modal selects a topic it just created by it.
  final String? savedName;

  @override
  List<Object?> get props => [status, failure, savedId, savedName];
}
