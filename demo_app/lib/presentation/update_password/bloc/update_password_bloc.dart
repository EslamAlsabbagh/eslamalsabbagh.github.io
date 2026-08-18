import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/repos/auth/auth_repo.dart';
import 'package:hrms_demo/presentation/update_password/bloc/update_password_event.dart';
import 'package:hrms_demo/presentation/update_password/bloc/update_password_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpdatePasswordBloc extends Bloc<UpdatePasswordEvent, UpdatePasswordState> {
  UpdatePasswordBloc({required this.authRepo}) : super(const UpdatePasswordState()) {
    on<UpdatePasswordRequested>(onUpdatePasswordRequested);
  }

  final AuthRepo authRepo;

  Future<void> onUpdatePasswordRequested(UpdatePasswordRequested event, Emitter<UpdatePasswordState> emit) async {
    emit(state.copyWith(status: Status.loading));
    try {
      // Simulate a network call
      await authRepo.updatePassword(event.code, event.oldPassword, event.newPassword, event.confirmPassword);
      emit(state.copyWith(status: Status.success));
      await Future.delayed(Duration(seconds: 1));
      emit(state.copyWith(status: Status.initial));
    } catch (e) {
      emit(UpdatePasswordState(status: Status.failure, failure: Failure(e.toString())));
    }
  }
}
