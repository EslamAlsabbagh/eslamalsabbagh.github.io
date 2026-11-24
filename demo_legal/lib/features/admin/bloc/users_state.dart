part of 'users_bloc.dart';

enum UsersStatus { loading, success, failure }

final class UsersState extends Equatable {
  const UsersState({this.status = UsersStatus.loading, this.users = const [], this.files = const []});

  final UsersStatus status;

  /// Oldest account first, as loaded.
  final List<ManagedUser> users;
  final List<TaskFile> files;

  /// The page's order: active accounts first, then deactivated ones, each
  /// oldest first, so a row never jumps unless its account is (re)activated.
  List<ManagedUser> get ordered => [...users.where((user) => user.isActive), ...users.where((user) => !user.isActive)];

  UsersState copyWith({UsersStatus? status}) => UsersState(status: status ?? this.status, users: users, files: files);

  @override
  List<Object?> get props => [status, users, files];
}
