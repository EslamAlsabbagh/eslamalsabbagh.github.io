import 'package:hrms_demo/core/bases/base_state.dart';
import 'package:hrms_demo/core/constants/status.dart';

final class UpdatePasswordState extends BaseState {
  const UpdatePasswordState({super.status = Status.initial, super.failure});

  UpdatePasswordState copyWith({Status? status, dynamic failure}) {
    return UpdatePasswordState(status: status ?? this.status, failure: failure ?? this.failure);
  }
}
