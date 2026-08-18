import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/constants/request_constants.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunching_request_repo.dart';
import 'package:hrms_demo/data/services/disabled_dates_service.dart';
import 'package:hrms_demo/presentation/request_missingpunching/bloc/request_missingpunching_event.dart';
import 'package:hrms_demo/presentation/request_missingpunching/bloc/request_missingpunching_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RequestMissingpunchingBloc extends Bloc<RequestMissingpunchingEvent, RequestMissingpunchingState> {
  RequestMissingpunchingBloc(this._MissingpunchingRequestRepo, this._disabledDatesService)
    : super(const RequestMissingpunchingState()) {
    on<SubmitMissingPunchingRequest>(_onSubmitMissingPunchingRequest);
    on<ValidateForm>(_onValidateForm);
    on<ChangeMissingPunchType>(_onChangeMissingPunchType);
    on<LoadExistingMissingpunchingRequests>(_onLoadExistingMissingpunchingRequests);
  }
  final MissingpunchingRequestsRepo _MissingpunchingRequestRepo;
  final DisabledDatesService _disabledDatesService;

  Future<void> _onSubmitMissingPunchingRequest(
    SubmitMissingPunchingRequest event,
    Emitter<RequestMissingpunchingState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading, isSubmitting: true));
    try {
      await _MissingpunchingRequestRepo.submitMissingpunchingRequest(event.request);
      emit(state.copyWith(status: Status.success, isSubmitting: false));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString()), isSubmitting: false));
    }
  }

  void _onValidateForm(ValidateForm event, Emitter<RequestMissingpunchingState> emit) {
    bool isFormValid = false;
    try {
      isFormValid = event.date.isNotEmpty && event.time.isNotEmpty;
    } catch (_) {
      isFormValid = false;
    }
    emit(state.copyWith(isFormValid: isFormValid));
  }

  void _onChangeMissingPunchType(ChangeMissingPunchType event, Emitter<RequestMissingpunchingState> emit) {
    emit(state.copyWith(missingPunchType: event.missingPunchType));
  }

  Future<void> _onLoadExistingMissingpunchingRequests(
    LoadExistingMissingpunchingRequests event,
    Emitter<RequestMissingpunchingState> emit,
  ) async {
    try {
      final now = DateTime.now();
      final disabledDates = await _disabledDatesService.getDisabledDates(
        userCode: event.userCode,
        calendarFirstDate: now.subtract(const Duration(days: kRequestBackWindowDays)),
        calendarLastDate: now,
      );
      emit(state.copyWith(disabledDates: disabledDates, disabledDatesLoaded: true));
    } catch (e) {
      // If loading fails, continue with empty disabled dates
      // This ensures the form is still usable even if the API fails
      emit(state.copyWith(disabledDates: [], disabledDatesLoaded: true));
    }
  }
}
