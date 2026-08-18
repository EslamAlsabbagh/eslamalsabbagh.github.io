import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/repos/auth/auth_repo.dart';
import 'package:hrms_demo/data/repos/storage/storage_keys.dart';
import 'package:hrms_demo/data/repos/storage/storage_repo.dart';
import 'package:hrms_demo/presentation/login/bloc/login_event.dart';
import 'package:hrms_demo/presentation/login/bloc/login_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({required this.authRepo, required this.storage}) : super(const LoginState()) {
    on<LoginRequested>(onLoginRequested);
  }

  final AuthRepo authRepo;
  final StorageRepo storage;

  bool _isWeakPassword(String password) {
    // Check if password is 123456
    return password == '123456';
  }

  Future<void> onLoginRequested(LoginRequested event, Emitter<LoginState> emit) async {
    emit(state.copyWith(status: Status.loading));

    try {
      // Validate that the code contains only numbers
      if (int.tryParse(event.code) == null) {
        emit(state.copyWith(status: Status.failure, failure: Failure('Employee code must contain only numbers')));
        await Future.delayed(Duration(seconds: 1));
        emit(state.copyWith(status: Status.initial));
        return;
      }

      final actualCode = await authRepo.login(event.code, event.password);

      if (actualCode != null) {
        // Check for weak password after successful login
        if (_isWeakPassword(event.password)) {
          await storage.write(StorageKeys.userCode.key, actualCode);
          await storage.write('weak_password_flag', 'true');
          emit(state.copyWith(status: Status.weakPassword, code: actualCode));
          return;
        }

        await storage.write(StorageKeys.userCode.key, actualCode);
        await storage.delete('weak_password_flag'); // Clear flag for strong passwords
        emit(state.copyWith(status: Status.success, code: actualCode));
      } else {
        emit(state.copyWith(status: Status.failure, failure: Failure('Invalid credentials')));
        await Future.delayed(Duration(seconds: 1));
        emit(state.copyWith(status: Status.initial));
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('suspended')) {
        emit(state.copyWith(status: Status.failure, failure: Failure('Employee is suspended')));
      } else {
        emit(state.copyWith(status: Status.failure, failure: Failure(errorMessage)));
      }
    }
  }
}
