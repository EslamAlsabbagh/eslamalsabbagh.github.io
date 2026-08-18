import 'package:hrms_demo/core/bases/base_state.dart';
import 'package:hrms_demo/core/constants/status.dart';

final class LoginState extends BaseState {
  final String code;

  const LoginState({this.code = '', super.status = Status.initial, super.failure});

  LoginState copyWith({String? code, Status? status, dynamic failure}) {
    return LoginState(code: code ?? this.code, status: status ?? this.status, failure: failure ?? this.failure);
  }
}
