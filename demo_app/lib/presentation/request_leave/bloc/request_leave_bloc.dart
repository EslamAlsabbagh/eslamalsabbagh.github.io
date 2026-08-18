import 'package:hrms_demo/core/bases/failure.dart';
import 'package:hrms_demo/core/constants/leave_type.dart';
import 'package:hrms_demo/core/constants/request_constants.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/services/disabled_dates_service.dart';
import 'package:hrms_demo/presentation/request_leave/bloc/request_leave_event.dart';
import 'package:hrms_demo/presentation/request_leave/bloc/request_leave_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RequestLeaveBloc extends Bloc<RequestLeaveEvent, RequestLeaveState> {
  final LeaveRequestsRepo repo;
  final DisabledDatesService _disabledDatesService;
  RequestLeaveBloc(this.repo, this._disabledDatesService) : super(RequestLeaveState()) {
    on<SubmitLeaveRequest>((event, emit) async {
      if (event.request.dateFrom == null || event.request.dateTo == null) {
        emit(RequestLeaveState(isSubmitting: false, status: Status.failure, failure: Failure('Dates are required')));
        return;
      }
      emit(state.copyWith(status: Status.loading, isSubmitting: true));
      try {
        final id = await repo.submitLeaveRequest(event.request);

        emit(state.copyWith(status: Status.success, isSubmitting: false, requestId: id));
        if (state.leaveType == LeaveType.sick) {
          add(UploadSickNoteFiles(state.sickNoteFiles, state.sickNoteFileNames, id));
        }
      } catch (e) {
        // Production prefers the clean server message (PostgrestException wraps
        // the RAISE EXCEPTION text from validate_leave_request). The demo has no
        // server, so every failure is a plain Dart exception.
        emit(
          state.copyWith(
            isSubmitting: false,
            status: Status.failure,
            failure: Failure(e.toString()),
          ),
        );
      }
    });
    on<UpdateDateRange>((event, emit) {
      if (event.fromDate != null && event.toDate != null && event.fromDate!.isNotEmpty && event.toDate!.isNotEmpty) {
        final fromDate = DateTime.tryParse(event.fromDate!);
        final toDate = DateTime.tryParse(event.toDate!);

        if (fromDate != null && toDate != null) {
          final baseDays = (toDate.difference(fromDate).inDays);
          final difference =
              event.leaveHours != null && event.leaveHours! > 0
                  ? baseDays + (event.leaveHours! / (event.shiftHours as num))
                  : baseDays + 1;
          emit(
            state.copyWith(
              status: Status.initial,
              dayCount: difference > 0 ? difference.toDouble() : 0,
              leaveType: null,
            ),
          );
        } else {
          emit(state.copyWith(status: Status.initial, dayCount: 0, leaveType: null));
        }
      } else {
        emit(state.copyWith(status: Status.initial, dayCount: 0, leaveType: null));
      }
    });

    on<ValidateForm>((event, emit) {
      final fromDate = DateTime.tryParse(event.fromDate) ?? DateTime.now();
      final toDate = DateTime.tryParse(event.toDate) ?? DateTime.now();
      var isFormValid =
          event.fromDate.isNotEmpty &&
          event.toDate.isNotEmpty &&
          event.leaveType.isNotEmpty &&
          event.leaveHours.toString().isNotEmpty &&
          (fromDate.isBefore(toDate.add(const Duration(days: 1))));
      if (state.leaveType == LeaveType.sick) {
        isFormValid = isFormValid && state.sickNoteFiles.isNotEmpty;
      }

      // Reset status so any inline submission error clears as soon as the
      // user edits a field (ValidateForm fires on every input change).
      emit(state.copyWith(status: Status.initial, isFormValid: isFormValid));
    });

    on<ResetLeaveType>((event, emit) {
      emit(state.copyWith(status: Status.initial, leaveType: null, isFormValid: false));
    });

    on<UploadSickNoteFiles>((event, emit) {
      repo.uploadSickNote(event.files, event.fileNames, event.requestId);
      emit(state.copyWith(sickNoteFiles: event.files));
    });

    on<UpdateSickNotes>((event, emit) {
      emit(
        state.copyWith(
          status: Status.initial,
          sickNoteFiles: event.sickNoteFiles,
          sickNoteFileNames: event.sickNoteFileNames,
        ),
      );
    });

    on<UpdateLeaveType>((event, emit) {
      emit(state.copyWith(status: Status.initial, leaveType: event.leaveType));
    });

    on<LoadExistingLeaveRequests>((event, emit) async {
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
    });
  }
}
