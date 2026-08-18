import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_request_repo.dart';
import 'package:hrms_demo/presentation/request_overtime/bloc/request_overtime_event.dart';
import 'package:hrms_demo/presentation/request_overtime/bloc/request_overtime_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class RequestOvertimeBloc extends Bloc<RequestOvertimeEvent, RequestOvertimeState> {
  RequestOvertimeBloc(this._overtimeRequestRepo) : super(const RequestOvertimeState()) {
    on<SubmitOvertimeRequest>(_onSubmitOvertimeRequest);
    // on<UpdateDateRange>(_onUpdateDateRange);
    on<ValidateForm>(_onValidateForm);
    on<ChangeOvertimeType>(_onChangeOvertimeType);
  }

  final OvertimeRequestRepo _overtimeRequestRepo;

  Future<void> _onSubmitOvertimeRequest(SubmitOvertimeRequest event, Emitter<RequestOvertimeState> emit) async {
    emit(state.copyWith(status: Status.loading, isSubmitting: true));
    try {
      await _overtimeRequestRepo.submitOvertimeRequest(event.request);
      emit(state.copyWith(status: Status.success, isSubmitting: false));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString()), isSubmitting: false));
    }
  }

  // void _onUpdateDateRange(
  //   UpdateDateRange event,
  //   Emitter<RequestOvertimeState> emit,
  // ) {
  //   if (event..isNotEmpty && event.toDate.isNotEmpty) {
  //     final fromDate = DateTime.tryParse(event.fromDate);
  //     final toDate = DateTime.tryParse(event.toDate);
  //     if (fromDate != null && toDate != null) {
  //       final dayCount = toDate.difference(fromDate).inDays + 1;
  //       emit(state.copyWith(dayCount: dayCount));
  //     } else {
  //       emit(state.copyWith(dayCount: 0));
  //     }
  //   } else {
  //     emit(state.copyWith(dayCount: 0));
  //   }
  // }

  void _onValidateForm(ValidateForm event, Emitter<RequestOvertimeState> emit) {
    String fromTime = event.fromTime.replaceAll('ص', 'AM').replaceAll('م', 'PM');
    String toTime = event.toTime.replaceAll('ص', 'AM').replaceAll('م', 'PM');

    final format = DateFormat("hh:mm a");
    bool isFormValid = false;
    try {
      isFormValid =
          event.date.isNotEmpty &&
          event.fromTime.isNotEmpty &&
          event.toTime.isNotEmpty &&
          event.reason.isNotEmpty &&
          format.parse(fromTime).isBefore(format.parse(toTime));
    } catch (_) {
      isFormValid = false;
    }
    final numOfHours =
        event.fromTime.isNotEmpty && event.toTime.isNotEmpty && format.parse(fromTime).isBefore(format.parse(toTime))
            ? format.parse(toTime).difference(format.parse(fromTime)).inMinutes / 60
            : 0;
    emit(state.copyWith(isFormValid: isFormValid, numOfHours: numOfHours));
  }

  void _onChangeOvertimeType(ChangeOvertimeType event, Emitter<RequestOvertimeState> emit) {
    emit(state.copyWith(overtimeType: event.overtimeType));
  }
}
