import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../tasks/data/task_file.dart';
import '../data/managed_user.dart';
import '../data/users_repository.dart';

part 'users_event.dart';
part 'users_state.dart';

/// The admin users page: every account with its files, and the file list for
/// the membership checkboxes. A refresh after a save keeps the old list on
/// screen until the new one arrives.
class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc({required this._usersRepository}) : super(const UsersState()) {
    on<UsersLoadRequested>(_onLoad);
    on<UsersRefreshRequested>(_onLoad);
  }

  final UsersRepository _usersRepository;

  Future<void> _onLoad(UsersEvent event, Emitter<UsersState> emit) async {
    final quiet = event is UsersRefreshRequested && state.status == UsersStatus.success;
    if (!quiet) emit(state.copyWith(status: UsersStatus.loading));
    try {
      final (users, files) = await (_usersRepository.fetchUsers(), _usersRepository.fetchFiles()).wait;
      emit(UsersState(status: UsersStatus.success, users: users, files: files));
    } catch (error, stackTrace) {
      log('Loading users failed', name: 'admin', error: error, stackTrace: stackTrace);
      // A failed quiet refresh keeps the list; only a first load shows the error.
      if (!quiet) emit(state.copyWith(status: UsersStatus.failure));
    }
  }
}
