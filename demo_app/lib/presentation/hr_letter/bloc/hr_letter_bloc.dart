import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/data/models/hr_letter_request_model.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_request_repo.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/hr_letter/bloc/hr_letter_event.dart';
import 'package:hrms_demo/presentation/hr_letter/bloc/hr_letter_state.dart';

class _ValidationResult {
  final Map<String, String> errors;
  final bool isValid;
  _ValidationResult({required this.errors, required this.isValid});
}

class HrLetterBloc extends Bloc<HrLetterEvent, HrLetterState> {
  final UserBloc userBloc;
  final HrLetterRequestRepo hrLetterRepo;

  HrLetterBloc({required this.userBloc, required this.hrLetterRepo}) : super(HrLetterInitial()) {
    on<InitializeHrLetterForm>(_onInitializeForm);
    on<UpdateLetterPurpose>(_onUpdateLetterPurpose);
    on<UpdateTravelFromDate>(_onUpdateTravelFromDate);
    on<UpdateTravelToDate>(_onUpdateTravelToDate);
    on<UpdateDetails>(_onUpdateDetails);
    on<UpdateNationalId>(_onUpdateNationalId);
    on<ValidateHrLetterForm>(_onValidateForm);
    on<ResetHrLetterForm>(_onResetForm);
    on<SubmitHrLetterRequest>(_onSubmitRequest);
  }

  void _onInitializeForm(InitializeHrLetterForm event, Emitter<HrLetterState> emit) {
    final user = userBloc.state.user;
    final isEligible = _checkEligibility(user?.hireDate);
    final nationalId = user?.nationalId ?? '';

    emit(HrLetterFormState(isEligible: isEligible, nationalId: nationalId, isNationalIdFromDb: nationalId.isNotEmpty));
  }

  /// Checks if the employee has 3+ months tenure using the same multi-format
  /// date parser as advance_on_salary_content.dart's _isEligibleForAdvance.
  bool _checkEligibility(String? hireDate) {
    if (hireDate == null || hireDate.isEmpty) return false;

    try {
      DateTime hireDateParsed;

      if (hireDate.contains('/')) {
        final parts = hireDate.split('/');
        if (parts.length == 3) {
          hireDateParsed = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
        } else {
          return false;
        }
      } else if (hireDate.contains('-') && hireDate.split('-').length == 3) {
        final parts = hireDate.split('-');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final monthStr = parts[1];
          final year = int.tryParse(parts[2]);

          if (day == null || year == null) {
            // Try ISO format (YYYY-MM-DD)
            hireDateParsed = DateTime.parse(hireDate);
          } else {
            const monthMap = {
              'Jan': 1,
              'Feb': 2,
              'Mar': 3,
              'Apr': 4,
              'May': 5,
              'Jun': 6,
              'Jul': 7,
              'Aug': 8,
              'Sep': 9,
              'Oct': 10,
              'Nov': 11,
              'Dec': 12,
            };
            final month = monthMap[monthStr];
            if (month == null) {
              hireDateParsed = DateTime.parse(hireDate);
            } else {
              hireDateParsed = DateTime(year, month, day);
            }
          }
        } else {
          return false;
        }
      } else {
        hireDateParsed = DateTime.parse(hireDate);
      }

      final now = DateTime.now();
      final threeMonthsAgo = DateTime(now.year, now.month - 3, now.day);
      return hireDateParsed.isBefore(threeMonthsAgo) || hireDateParsed.isAtSameMomentAs(threeMonthsAgo);
    } catch (_) {
      return false;
    }
  }

  void _onUpdateLetterPurpose(UpdateLetterPurpose event, Emitter<HrLetterState> emit) {
    final currentState = state;
    if (currentState is HrLetterFormState) {
      // Clear travel dates when switching away from embassy
      if (event.purpose != 'embassy') {
        emit(currentState.copyWith(letterPurpose: event.purpose, clearTravelFromDate: true, clearTravelToDate: true));
      } else {
        emit(currentState.copyWith(letterPurpose: event.purpose));
      }
    }
  }

  void _onUpdateTravelFromDate(UpdateTravelFromDate event, Emitter<HrLetterState> emit) {
    final currentState = state;
    if (currentState is HrLetterFormState) {
      emit(currentState.copyWith(travelFromDate: event.date));
    }
  }

  void _onUpdateTravelToDate(UpdateTravelToDate event, Emitter<HrLetterState> emit) {
    final currentState = state;
    if (currentState is HrLetterFormState) {
      emit(currentState.copyWith(travelToDate: event.date));
    }
  }

  void _onUpdateDetails(UpdateDetails event, Emitter<HrLetterState> emit) {
    final currentState = state;
    if (currentState is HrLetterFormState) {
      emit(currentState.copyWith(details: event.details));
    }
  }

  void _onUpdateNationalId(UpdateNationalId event, Emitter<HrLetterState> emit) {
    final currentState = state;
    if (currentState is HrLetterFormState) {
      emit(currentState.copyWith(nationalId: event.nationalId));
    }
  }

  void _onValidateForm(ValidateHrLetterForm event, Emitter<HrLetterState> emit) {
    final currentState = state;
    if (currentState is HrLetterFormState) {
      final result = _validate(currentState);
      emit(currentState.copyWith(validationErrors: result.errors, isFormValid: result.isValid));
    }
  }

  _ValidationResult _validate(HrLetterFormState state) {
    final errors = <String, String>{};

    if (state.nationalId.trim().isEmpty) {
      errors['nationalId'] = 'required';
    }

    if (state.letterPurpose == null) {
      errors['letterPurpose'] = 'required';
    }

    if (state.letterPurpose == 'embassy') {
      if (state.travelFromDate == null) {
        errors['travelFromDate'] = 'required';
      }
      if (state.travelToDate == null) {
        errors['travelToDate'] = 'required';
      }
      if (state.travelFromDate != null && state.travelToDate != null) {
        if (!state.travelToDate!.isAfter(state.travelFromDate!)) {
          errors['travelToDate'] = 'after_from';
        }
      }
    }

    if (state.letterPurpose == 'other' && state.details.trim().isEmpty) {
      errors['details'] = 'required';
    }

    return _ValidationResult(errors: errors, isValid: errors.isEmpty);
  }

  void _onResetForm(ResetHrLetterForm event, Emitter<HrLetterState> emit) {
    add(InitializeHrLetterForm());
  }

  Future<void> _onSubmitRequest(SubmitHrLetterRequest event, Emitter<HrLetterState> emit) async {
    final currentState = state;
    if (currentState is! HrLetterFormState) return;

    // Validate first
    final result = _validate(currentState);
    if (!result.isValid) {
      emit(currentState.copyWith(validationErrors: result.errors, isFormValid: false));
      return;
    }

    emit(currentState.copyWith(isSubmitting: true, clearSubmissionError: true));

    try {
      final user = userBloc.state.user;
      final request = HrLetterRequestModel(
        employeeCode: user?.id,
        nationalId: currentState.nationalId.trim(),
        letterPurpose: currentState.letterPurpose,
        travelFromDate: currentState.travelFromDate,
        travelToDate: currentState.travelToDate,
        details: currentState.details.trim().isEmpty ? null : currentState.details.trim(),
        status: 'pending',
      );

      final requestId = await hrLetterRepo.submitHrLetterRequest(request);
      await hrLetterRepo.sendSubmissionNotification(requestId);

      emit(currentState.copyWith(isSubmitting: false, isSubmissionSuccessful: true));
    } catch (e) {
      emit(currentState.copyWith(isSubmitting: false, submissionError: e.toString()));
    }
  }
}
