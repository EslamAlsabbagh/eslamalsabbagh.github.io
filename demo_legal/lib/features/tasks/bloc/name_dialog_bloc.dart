import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/validation/name_text.dart';
import '../data/name_save_failure.dart';
import '../data/tasks_repository.dart';
import 'name_target.dart';

part 'name_dialog_event.dart';
part 'name_dialog_state.dart';

/// The name modal: creates or renames one file or topic ([NameTarget]), or
/// deletes an empty one.
///
/// The typed text stays in the field; the bloc gets it on submit, trims it,
/// and either ends [NameDialogStatus.saved] with the row's id and name or
/// goes back to editing with a [NameSaveFailure]. A delete ends
/// [NameDialogStatus.deleted] the same way. The modal creates one per opening.
class NameDialogBloc extends Bloc<NameDialogEvent, NameDialogState> {
  NameDialogBloc({required this.target, required this._tasksRepository}) : super(const NameDialogState()) {
    on<NameSubmitted>(_onSubmitted);
    on<NameDeleteRequested>(_onDeleteRequested);
  }

  final NameTarget target;
  final TasksRepository _tasksRepository;

  /// Whether [name] may be saved: valid, and on rename not the saved name.
  bool canSave(String name) {
    final trimmed = name.trim();
    return NameText.isValid(trimmed) && (target.isNew || trimmed != target.currentName);
  }

  Future<void> _onSubmitted(NameSubmitted event, Emitter<NameDialogState> emit) async {
    if (state.status != NameDialogStatus.editing || !canSave(event.name)) return;
    final name = event.name.trim();
    emit(const NameDialogState(status: NameDialogStatus.saving));
    try {
      final id = switch (target) {
        NewFile() => await _tasksRepository.createFile(name),
        RenameFile(:final file) => await _tasksRepository.renameFile(file.id, name).then((_) => file.id),
        NewTopic(:final file) => await _tasksRepository.createTopic(file.id, name),
        RenameTopic(:final topic) => await _tasksRepository.renameTopic(topic.id, name).then((_) => topic.id),
      };
      emit(NameDialogState(status: NameDialogStatus.saved, savedId: id, savedName: name));
    } on NameSaveException catch (error) {
      emit(NameDialogState(failure: error.failure));
    }
  }

  Future<void> _onDeleteRequested(NameDeleteRequested event, Emitter<NameDialogState> emit) async {
    if (state.status != NameDialogStatus.editing || !target.canDelete) return;
    emit(const NameDialogState(status: NameDialogStatus.deleting));
    try {
      final id = switch (target) {
        RenameFile(:final file) => await _tasksRepository.deleteFile(file.id).then((_) => file.id),
        RenameTopic(:final topic) => await _tasksRepository.deleteTopic(topic.id).then((_) => topic.id),
        NewFile() || NewTopic() => throw StateError('nothing to delete'),
      };
      emit(NameDialogState(status: NameDialogStatus.deleted, savedId: id, savedName: target.currentName));
    } on NameSaveException catch (error) {
      emit(NameDialogState(failure: error.failure));
    }
  }
}
