import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/constants/request_constants.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo.dart';
import 'package:hrms_demo/data/services/disabled_dates_service.dart';
import 'package:hrms_demo/presentation/request_businesstrip/bloc/request_businesstrip_event.dart';
import 'package:hrms_demo/presentation/request_businesstrip/bloc/request_businesstrip_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RequestBusinesstripBloc extends Bloc<RequestBusinesstripEvent, RequestBusinesstripState> {
  RequestBusinesstripBloc(this._BusinesstripRequestRepo, this._disabledDatesService)
    : super(const RequestBusinesstripState()) {
    on<SubmitBusinesstripRequest>(_onSubmitBusinesstripRequest);
    on<ValidateForm>(_onValidateForm);
    on<SetOtherLocation>(_onSetOtherLocation);
    on<SetLocationTransportationFee>(_onSetLocationTransportationFee);
    on<SetRequestTransportationFee>(_onSetRequestTransportationFee);
    on<SetTransportationFeeAmount>(_onSetTransportationFeeAmount);
    on<LoadExistingBusinesstripRequests>(_onLoadExistingBusinesstripRequests);
    on<SetNumberOfHours>(_onSetNumberOfHours);
    on<SetAmPm>(_onSetAmPm);
  }
  final BusinesstripRequestsRepo _BusinesstripRequestRepo;
  final DisabledDatesService _disabledDatesService;
  Future<void> _onSubmitBusinesstripRequest(
    SubmitBusinesstripRequest event,
    Emitter<RequestBusinesstripState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading, isSubmitting: true));
    try {
      await _BusinesstripRequestRepo.submitBusinesstripRequest(event.request);
      emit(state.copyWith(status: Status.success, isSubmitting: false));
    } catch (e) {
      emit(state.copyWith(status: Status.failure, failure: Failure(e.toString()), isSubmitting: false));
    }
  }

  void _onValidateForm(ValidateForm event, Emitter<RequestBusinesstripState> emit) {
    final fromDate = DateTime.tryParse(event.dateFrom);
    final toDate = DateTime.tryParse(event.dateTo);
    bool isFormValid = false;
    try {
      final numberOfDays = fromDate != null && toDate != null ? toDate.difference(fromDate).inDays + 1 : 0;
      final showHourFields = numberOfDays == 1;

      // Basic validation
      isFormValid =
          event.dateFrom.isNotEmpty &&
          event.dateTo.isNotEmpty &&
          event.location.isNotEmpty &&
          (fromDate != null && toDate != null ? (fromDate.isBefore(toDate.add(const Duration(days: 1)))) : false);

      // Additional validation for hour fields when single day.
      // Hours are optional (used to mark a partial-day trip); a same-day
      // missing-punch no longer forces them. Only constraint: if hours are
      // selected, AM/PM must be selected too.
      if (isFormValid && showHourFields) {
        if (state.numberOfHours != null && state.amPm == null) {
          isFormValid = false;
        }
      }

      // A requested transportation fee must have a positive amount.
      if (isFormValid && !_isFeeValid(state)) {
        isFormValid = false;
      }
    } catch (_) {
      isFormValid = false;
    }
    final numberOfDays = fromDate != null && toDate != null ? toDate.difference(fromDate).inDays + 1 : 0;
    final showHourFields = numberOfDays == 1;

    // Reset hour fields if not single day
    int? numberOfHours = state.numberOfHours;
    String? amPm = state.amPm;
    if (!showHourFields) {
      numberOfHours = null;
      amPm = null;
    }

    emit(
      state.copyWith(
        isFormValid: isFormValid,
        numberOfDays: numberOfDays,
        showHourFields: showHourFields,
        numberOfHours: numberOfHours,
        amPm: amPm,
      ),
    );
  }

  void _onSetOtherLocation(SetOtherLocation event, Emitter<RequestBusinesstripState> emit) {
    emit(state.copyWith(other: event.other));
  }

  void _onSetLocationTransportationFee(SetLocationTransportationFee event, Emitter<RequestBusinesstripState> emit) {
    // Locations with a fixed, known fee (e.g. North Square) are auto-eligible,
    // so the manual fee-request option is hidden and any pending manual request
    // is cleared to avoid submitting a redundant/blocking amount.
    if (event.deservesFee) {
      emit(state.copyWith(locationDeservesFee: true, feeRequested: false, feeAmount: null));
      _validateCurrentForm(emit);
    } else {
      emit(state.copyWith(locationDeservesFee: false));
    }
  }

  void _onSetRequestTransportationFee(SetRequestTransportationFee event, Emitter<RequestBusinesstripState> emit) {
    // Clear the amount when the fee request is turned off.
    emit(state.copyWith(feeRequested: event.requested, feeAmount: event.requested ? state.feeAmount : null));

    // Re-validate: a requested fee needs a valid (> 0) amount.
    _validateCurrentForm(emit);
  }

  void _onSetTransportationFeeAmount(SetTransportationFeeAmount event, Emitter<RequestBusinesstripState> emit) {
    emit(state.copyWith(feeAmount: event.amount));
    _validateCurrentForm(emit);
  }

  /// A requested transportation fee must have a positive amount.
  bool _isFeeValid(RequestBusinesstripState state) {
    if (!state.feeRequested) return true;
    return state.feeAmount != null && state.feeAmount! > 0;
  }

  Future<void> _onLoadExistingBusinesstripRequests(
    LoadExistingBusinesstripRequests event,
    Emitter<RequestBusinesstripState> emit,
  ) async {
    try {
      final now = DateTime.now();
      final disabledDates = await _disabledDatesService.getDisabledDates(
        userCode: event.userCode,
        calendarFirstDate: now.subtract(const Duration(days: kRequestBackWindowDays)),
        calendarLastDate: DateTime(2100),
      );
      emit(state.copyWith(disabledDates: disabledDates, disabledDatesLoaded: true));
    } catch (e) {
      // If loading fails, continue with empty disabled dates
      emit(state.copyWith(disabledDates: [], disabledDatesLoaded: true));
    }
  }

  void _onSetNumberOfHours(SetNumberOfHours event, Emitter<RequestBusinesstripState> emit) {
    // Reset AM/PM if hours is null
    String? amPm = state.amPm;
    if (event.numberOfHours == null) {
      amPm = null;
    }

    // Update state
    emit(state.copyWith(numberOfHours: event.numberOfHours, amPm: amPm));

    // Re-validate form to check if AM/PM is required
    _validateCurrentForm(emit);
  }

  void _onSetAmPm(SetAmPm event, Emitter<RequestBusinesstripState> emit) {
    emit(state.copyWith(amPm: event.amPm));

    // Re-validate form
    _validateCurrentForm(emit);
  }

  void _validateCurrentForm(Emitter<RequestBusinesstripState> emit) {
    bool isFormValid = false;

    try {
      // Check if we have the minimum required fields
      if (state.numberOfDays > 0) {
        final showHourFields = state.numberOfDays == 1;

        // Basic validation (this assumes dates and location are already validated)
        isFormValid = true;

        // Additional validation for hour fields when single day.
        // Hours are optional; only constraint is AM/PM required when hours set.
        if (showHourFields) {
          if (state.numberOfHours != null && state.amPm == null) {
            isFormValid = false;
          }
        }

        // A requested transportation fee must have a positive amount.
        if (isFormValid && !_isFeeValid(state)) {
          isFormValid = false;
        }
      }
    } catch (_) {
      isFormValid = false;
    }

    emit(state.copyWith(isFormValid: isFormValid));
  }
}
