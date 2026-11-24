part of 'users_bloc.dart';

sealed class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object?> get props => [];
}

/// The page opened, or «إعادة المحاولة» after a failed load.
final class UsersLoadRequested extends UsersEvent {
  const UsersLoadRequested();
}

/// A modal saved something: reload without a spinner.
final class UsersRefreshRequested extends UsersEvent {
  const UsersRefreshRequested();
}
