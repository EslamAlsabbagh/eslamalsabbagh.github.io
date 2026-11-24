part of 'name_dialog_bloc.dart';

sealed class NameDialogEvent extends Equatable {
  const NameDialogEvent();

  @override
  List<Object?> get props => [];
}

/// «حفظ» or Enter, with the field's text (trimmed by the bloc).
final class NameSubmitted extends NameDialogEvent {
  const NameSubmitted(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

/// «حذف» confirmed in the delete dialog (rename targets with `canDelete`).
final class NameDeleteRequested extends NameDialogEvent {
  const NameDeleteRequested();
}
