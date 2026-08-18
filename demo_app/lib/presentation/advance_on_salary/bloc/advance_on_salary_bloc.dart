import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/core/constants/employee_type_selection.dart';
import 'package:hrms_demo/core/utils/search_filter_utils.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import 'package:hrms_demo/presentation/advance_on_salary/bloc/advance_on_salary_event.dart';
import 'package:hrms_demo/presentation/advance_on_salary/bloc/advance_on_salary_state.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:number_words_reader/number_words_reader.dart';

class ValidationResult {
  final Map<String, String> errors;
  final bool isValid;

  ValidationResult({required this.errors, required this.isValid});
}

class AdvanceOnSalaryBloc extends Bloc<AdvanceOnSalaryEvent, AdvanceOnSalaryState> {
  final UsersRepo usersRepo;
  final UserBloc userBloc;
  final AdvanceOnSalaryRequestsRepo advanceOnSalaryRepo;

  AdvanceOnSalaryBloc({required this.usersRepo, required this.userBloc, required this.advanceOnSalaryRepo})
    : super(AdvanceOnSalaryInitial()) {
    on<InitializeAdvanceOnSalaryForm>(_onInitializeForm);
    on<SearchEmployees>(_onSearchEmployees);
    on<SelectEmployee>(_onSelectEmployee);
    on<UpdateAmountRequested>(_onUpdateAmountRequested);
    on<UpdatePeriodInMonths>(_onUpdatePeriodInMonths);
    on<UpdatePaymentStartDate>(_onUpdatePaymentStartDate);
    on<CalculateFields>(_onCalculateFields);
    on<ClearSearchResults>(_onClearSearchResults);
    on<ResetForm>(_onResetForm);
    on<ValidateForm>(_onValidateForm);
    on<FetchServerDate>(_onFetchServerDate);
    on<FetchAllManagedEmployees>(_onFetchAllManagedEmployees);
    on<FetchAllIndirectEmployees>(_onFetchAllIndirectEmployees);
    on<FetchAllDeepSubordinates>(_onFetchAllDeepSubordinates);
    on<ToggleEmployeeType>(_onToggleEmployeeType);
    on<SubmitAdvanceOnSalaryRequest>(_onSubmitRequest);
    on<CheckPendingRequest>(_onCheckPendingRequest);
  }

  void _onInitializeForm(InitializeAdvanceOnSalaryForm event, Emitter<AdvanceOnSalaryState> emit) {
    emit(const AdvanceOnSalaryFormState());

    // Automatically fetch server date and all managed employees
    add(FetchServerDate());
    add(FetchAllManagedEmployees());
  }

  Future<void> _onSearchEmployees(SearchEmployees event, Emitter<AdvanceOnSalaryState> emit) async {
    final currentState = state;
    if (currentState is AdvanceOnSalaryFormState) {
      emit(currentState.copyWith(isSearching: true, searchQuery: event.searchTerm));

      try {
        // Get the current user's code from UserBloc
        final currentUser = userBloc.state.user;
        if (currentUser?.id == null) {
          emit(currentState.copyWith(employeeSearchResults: [], isSearching: false));
          return;
        }

        // Use different repository method based on employee type
        final List<UserModel> employees;
        switch (currentState.employeeType) {
          case EmployeeTypeSelection.direct:
            employees = await usersRepo.searchManagedEmployees(event.searchTerm, currentUser!.id!);
          case EmployeeTypeSelection.indirect:
            employees = await usersRepo.searchIndirectEmployees(event.searchTerm, currentUser!.id!);
          case EmployeeTypeSelection.allSubordinates:
            employees = await usersRepo.searchDeepSubordinates(event.searchTerm, currentUser!.id!);
        }
        SearchFilterUtils.sortByRelevance(employees, event.searchTerm);
        emit(currentState.copyWith(employeeSearchResults: employees.take(5).toList(), isSearching: false));
      } catch (e) {
        emit(currentState.copyWith(employeeSearchResults: [], isSearching: false));
      }
    }
  }

  void _onSelectEmployee(SelectEmployee event, Emitter<AdvanceOnSalaryState> emit) {
    final currentState = state;
    if (currentState is AdvanceOnSalaryFormState) {
      final touchedFields = Set<String>.from(currentState.touchedFields)..add('employee');
      final newState = currentState.copyWith(
        selectedEmployee: event.employee,
        hireDate: event.employee.hireDate,
        employeeSearchResults: [],
        searchQuery: '',
        touchedFields: touchedFields,
        hasPendingRequest: false,
      );

      final validationResult = _validateForm(newState);
      final filteredErrors = _filterErrorsByTouchedFields(validationResult.errors, touchedFields);
      emit(newState.copyWith(validationErrors: filteredErrors, isFormValid: validationResult.isValid));

      // Check for pending requests for the selected employee
      if (event.employee.id != null) {
        add(CheckPendingRequest(event.employee.id!));
      }
    }
  }

  void _onUpdateAmountRequested(UpdateAmountRequested event, Emitter<AdvanceOnSalaryState> emit) {
    final currentState = state;
    if (currentState is AdvanceOnSalaryFormState) {
      final amountInWordsArabic = _convertAmountToArabicWords(event.amount);
      final amountInWordsEnglish = _convertAmountToEnglishWords(event.amount);

      // Calculate monthly payment if period is available
      double? monthlyPayment;
      if (currentState.periodInMonths != null && currentState.periodInMonths! > 0) {
        monthlyPayment = event.amount / currentState.periodInMonths!;
      }

      final touchedFields = Set<String>.from(currentState.touchedFields)..add('amount');
      final newState = currentState.copyWith(
        amountRequested: event.amount,
        amountInLettersArabic: amountInWordsArabic,
        amountInLettersEnglish: amountInWordsEnglish,
        monthlyPayment: monthlyPayment,
        touchedFields: touchedFields,
      );

      final validationResult = _validateForm(newState);
      final filteredErrors = _filterErrorsByTouchedFields(validationResult.errors, touchedFields);
      emit(newState.copyWith(validationErrors: filteredErrors, isFormValid: validationResult.isValid));
    }
  }

  void _onUpdatePeriodInMonths(UpdatePeriodInMonths event, Emitter<AdvanceOnSalaryState> emit) {
    final currentState = state;
    if (currentState is AdvanceOnSalaryFormState) {
      // Calculate payment end date if start date is available
      DateTime? paymentEndDate;
      if (currentState.paymentStartDate != null) {
        paymentEndDate = DateTime(
          currentState.paymentStartDate!.year,
          currentState.paymentStartDate!.month + event.months - 1,
          currentState.paymentStartDate!.day,
        );
      }

      // Calculate monthly payment if amount is available
      double? monthlyPayment;
      if (currentState.amountRequested != null && event.months > 0) {
        monthlyPayment = currentState.amountRequested! / event.months;
      }

      final touchedFields = Set<String>.from(currentState.touchedFields)..add('period');
      final newState = currentState.copyWith(
        periodInMonths: event.months,
        paymentEndDate: paymentEndDate,
        monthlyPayment: monthlyPayment,
        touchedFields: touchedFields,
      );

      final validationResult = _validateForm(newState);
      final filteredErrors = _filterErrorsByTouchedFields(validationResult.errors, touchedFields);
      emit(newState.copyWith(validationErrors: filteredErrors, isFormValid: validationResult.isValid));
    }
  }

  void _onUpdatePaymentStartDate(UpdatePaymentStartDate event, Emitter<AdvanceOnSalaryState> emit) {
    final currentState = state;
    if (currentState is AdvanceOnSalaryFormState) {
      // Calculate payment end date if period is available
      DateTime? paymentEndDate;
      if (currentState.periodInMonths != null) {
        paymentEndDate = DateTime(
          event.startDate.year,
          event.startDate.month + currentState.periodInMonths! - 1,
          event.startDate.day,
        );
      }

      final touchedFields = Set<String>.from(currentState.touchedFields)..add('paymentStartDate');
      final newState = currentState.copyWith(
        paymentStartDate: event.startDate,
        paymentEndDate: paymentEndDate,
        touchedFields: touchedFields,
      );

      final validationResult = _validateForm(newState);
      final filteredErrors = _filterErrorsByTouchedFields(validationResult.errors, touchedFields);
      emit(newState.copyWith(validationErrors: filteredErrors, isFormValid: validationResult.isValid));
    }
  }

  void _onCalculateFields(CalculateFields event, Emitter<AdvanceOnSalaryState> emit) {
    final currentState = state;
    if (currentState is AdvanceOnSalaryFormState) {
      double? monthlyPayment;
      DateTime? paymentEndDate;

      // Calculate monthly payment
      if (currentState.amountRequested != null &&
          currentState.periodInMonths != null &&
          currentState.periodInMonths! > 0) {
        monthlyPayment = currentState.amountRequested! / currentState.periodInMonths!;
      }

      // Calculate payment end date
      if (currentState.paymentStartDate != null && currentState.periodInMonths != null) {
        paymentEndDate = DateTime(
          currentState.paymentStartDate!.year,
          currentState.paymentStartDate!.month + currentState.periodInMonths!,
          currentState.paymentStartDate!.day,
        );
      }

      emit(currentState.copyWith(monthlyPayment: monthlyPayment, paymentEndDate: paymentEndDate));
    }
  }

  void _onClearSearchResults(ClearSearchResults event, Emitter<AdvanceOnSalaryState> emit) {
    final currentState = state;
    if (currentState is AdvanceOnSalaryFormState) {
      emit(currentState.copyWith(employeeSearchResults: [], searchQuery: ''));
    }
  }

  void _onResetForm(ResetForm event, Emitter<AdvanceOnSalaryState> emit) {
    final currentState = state;
    if (currentState is AdvanceOnSalaryFormState) {
      emit(
        AdvanceOnSalaryFormState(
          serverDate: currentState.serverDate, // Preserve server date
          isLoadingServerDate: currentState.isLoadingServerDate,
          allManagedEmployees: currentState.allManagedEmployees, // Preserve managed employees
          isLoadingAllEmployees: currentState.isLoadingAllEmployees,
        ),
      );
    } else {
      emit(const AdvanceOnSalaryFormState());
    }
  }

  void _onValidateForm(ValidateForm event, Emitter<AdvanceOnSalaryState> emit) {
    final currentState = state;
    if (currentState is AdvanceOnSalaryFormState) {
      final validationResult = _validateForm(currentState);
      // When explicitly validating, mark all fields as touched and show all errors
      final allFields = {'employee', 'amount', 'period', 'paymentStartDate'};
      emit(
        currentState.copyWith(
          validationErrors: validationResult.errors,
          isFormValid: validationResult.isValid,
          touchedFields: allFields,
        ),
      );
    }
  }

  ValidationResult _validateForm(AdvanceOnSalaryFormState state) {
    final Map<String, String> errors = {};

    // Employee validation
    if (state.selectedEmployee == null) {
      errors['employee'] = 'Please select an employee';
    }

    // Amount validation
    if (state.amountRequested == null) {
      errors['amount'] = 'Please enter the requested amount';
    } else if (state.amountRequested! < 500) {
      errors['amount'] = 'Amount must be at least 500 EGP';
    } else if (state.amountRequested! > 20000) {
      errors['amount'] = 'Amount cannot exceed 20,000 EGP';
    }

    // Period validation
    if (state.periodInMonths == null) {
      errors['period'] = 'Please enter the period in months';
    } else if (state.periodInMonths! < 1) {
      errors['period'] = 'Period must be at least 1 month';
    } else if (state.periodInMonths! > 12) {
      errors['period'] = 'Period cannot exceed 12 months';
    }

    // Payment start date validation
    if (state.paymentStartDate == null) {
      errors['paymentStartDate'] = 'Please select a payment start date';
    } else {
      final now = DateTime.now();
      final oneMonthFromNow = DateTime(now.year, now.month + 1, 1);
      final twoMonthsFromNow = DateTime(now.year, now.month + 2, 1);

      if (state.paymentStartDate!.isBefore(oneMonthFromNow) || state.paymentStartDate!.isAfter(twoMonthsFromNow)) {
        errors['paymentStartDate'] = 'Start date must be 1 or 2 months from now on the 1st';
      }

      if (state.paymentStartDate!.day != 1) {
        errors['paymentStartDate'] = 'Payment must start on the 1st of the month';
      }
    }

    return ValidationResult(errors: errors, isValid: errors.isEmpty);
  }

  Map<String, String> _filterErrorsByTouchedFields(Map<String, String> allErrors, Set<String> touchedFields) {
    final filteredErrors = <String, String>{};
    for (final field in touchedFields) {
      if (allErrors.containsKey(field)) {
        filteredErrors[field] = allErrors[field]!;
      }
    }
    return filteredErrors;
  }

  String _convertAmountToArabicWords(double amount) {
    if (amount == 0) return 'صفر جنيه مصري';

    int intAmount = amount.toInt();
    String amountInWords = NumberWordsReader.convertToArabic(intAmount.toString());

    return '$amountInWords جنيه مصري';
  }

  String _convertAmountToEnglishWords(double amount) {
    if (amount == 0) return 'Zero Egyptian Pounds';

    int intAmount = amount.toInt();
    String amountInWords = NumberWordsReader.convertToEnglish(intAmount);

    // Capitalize first letter of each word
    amountInWords = amountInWords
        .split(' ')
        .map((word) => word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');

    return '$amountInWords Egyptian Pounds';
  }

  Future<void> _onFetchServerDate(FetchServerDate event, Emitter<AdvanceOnSalaryState> emit) async {
    if (state is AdvanceOnSalaryFormState) {
      final currentState = state as AdvanceOnSalaryFormState;
      emit(currentState.copyWith(isLoadingServerDate: true));

      try {
        // Get actual server date from Supabase
        final serverDate = await usersRepo.getCurrentServerDate();

        // Get the latest state at emission time
        if (state is AdvanceOnSalaryFormState) {
          final latestState = state as AdvanceOnSalaryFormState;
          final newState = latestState.copyWith(serverDate: serverDate, isLoadingServerDate: false);
          emit(newState);
        }
      } catch (e) {
        // If server date fetch fails, emit error state
        if (state is AdvanceOnSalaryFormState) {
          emit((state as AdvanceOnSalaryFormState).copyWith(serverDate: null, isLoadingServerDate: false));
        }
      }
    }
  }

  Future<void> _onFetchAllManagedEmployees(FetchAllManagedEmployees event, Emitter<AdvanceOnSalaryState> emit) async {
    if (state is AdvanceOnSalaryFormState) {
      final currentState = state as AdvanceOnSalaryFormState;
      emit(currentState.copyWith(isLoadingAllEmployees: true));

      try {
        // Get the current user's code from UserBloc
        final currentUser = userBloc.state.user;
        if (currentUser?.id == null) {
          if (state is AdvanceOnSalaryFormState) {
            emit((state as AdvanceOnSalaryFormState).copyWith(allManagedEmployees: [], isLoadingAllEmployees: false));
          }
          return;
        }

        final employees = await usersRepo.getAllManagedEmployees(currentUser!.id!);

        // Get the latest state at emission time
        if (state is AdvanceOnSalaryFormState) {
          final latestState = state as AdvanceOnSalaryFormState;
          final newState = latestState.copyWith(allManagedEmployees: employees, isLoadingAllEmployees: false);
          emit(newState);
        }
      } catch (e) {
        if (state is AdvanceOnSalaryFormState) {
          emit((state as AdvanceOnSalaryFormState).copyWith(allManagedEmployees: [], isLoadingAllEmployees: false));
        }
      }
    }
  }

  Future<void> _onFetchAllIndirectEmployees(FetchAllIndirectEmployees event, Emitter<AdvanceOnSalaryState> emit) async {
    if (state is AdvanceOnSalaryFormState) {
      final currentState = state as AdvanceOnSalaryFormState;
      emit(currentState.copyWith(isLoadingAllEmployees: true));

      try {
        // Get the current user's code from UserBloc
        final currentUser = userBloc.state.user;
        if (currentUser?.id == null) {
          if (state is AdvanceOnSalaryFormState) {
            emit((state as AdvanceOnSalaryFormState).copyWith(allIndirectEmployees: [], isLoadingAllEmployees: false));
          }
          return;
        }

        final employees = await usersRepo.getAllIndirectEmployees(currentUser!.id!);

        // Get the latest state at emission time
        if (state is AdvanceOnSalaryFormState) {
          final latestState = state as AdvanceOnSalaryFormState;
          final newState = latestState.copyWith(allIndirectEmployees: employees, isLoadingAllEmployees: false);
          emit(newState);
        }
      } catch (e) {
        if (state is AdvanceOnSalaryFormState) {
          emit((state as AdvanceOnSalaryFormState).copyWith(allIndirectEmployees: [], isLoadingAllEmployees: false));
        }
      }
    }
  }

  Future<void> _onFetchAllDeepSubordinates(FetchAllDeepSubordinates event, Emitter<AdvanceOnSalaryState> emit) async {
    if (state is AdvanceOnSalaryFormState) {
      final currentState = state as AdvanceOnSalaryFormState;
      emit(currentState.copyWith(isLoadingAllEmployees: true));

      try {
        // Get the current user's code from UserBloc
        final currentUser = userBloc.state.user;
        if (currentUser?.id == null) {
          if (state is AdvanceOnSalaryFormState) {
            emit((state as AdvanceOnSalaryFormState).copyWith(allDeepSubordinates: [], isLoadingAllEmployees: false));
          }
          return;
        }

        final employees = await usersRepo.getAllDeepSubordinates(currentUser!.id!);

        // Get the latest state at emission time
        if (state is AdvanceOnSalaryFormState) {
          final latestState = state as AdvanceOnSalaryFormState;
          final newState = latestState.copyWith(allDeepSubordinates: employees, isLoadingAllEmployees: false);
          emit(newState);
        }
      } catch (e) {
        if (state is AdvanceOnSalaryFormState) {
          emit((state as AdvanceOnSalaryFormState).copyWith(allDeepSubordinates: [], isLoadingAllEmployees: false));
        }
      }
    }
  }

  void _onToggleEmployeeType(ToggleEmployeeType event, Emitter<AdvanceOnSalaryState> emit) {
    final currentState = state;
    if (currentState is AdvanceOnSalaryFormState) {
      // Clear selection and search results when toggling
      emit(
        currentState.copyWith(
          employeeType: event.employeeType,
          selectedEmployee: null,
          hireDate: null,
          employeeSearchResults: [],
          searchQuery: '',
          validationErrors: {},
          hasPendingRequest: false,
          // Reset form fields
          amountRequested: null,
          amountInLettersArabic: '',
          amountInLettersEnglish: '',
          periodInMonths: null,
          paymentStartDate: null,
          paymentEndDate: null,
          monthlyPayment: null,
        ),
      );

      // Fetch the appropriate employee list
      switch (event.employeeType) {
        case EmployeeTypeSelection.direct:
          add(FetchAllManagedEmployees());
        case EmployeeTypeSelection.indirect:
          add(FetchAllIndirectEmployees());
        case EmployeeTypeSelection.allSubordinates:
          add(FetchAllDeepSubordinates());
      }
    }
  }

  Future<void> _onSubmitRequest(SubmitAdvanceOnSalaryRequest event, Emitter<AdvanceOnSalaryState> emit) async {
    final currentState = state;
    if (currentState is AdvanceOnSalaryFormState) {
      emit(currentState.copyWith(isSubmitting: true));

      try {
        await advanceOnSalaryRepo.submitAdvanceOnSalaryRequest(event.request);
        emit(currentState.copyWith(isSubmitting: false, isSubmissionSuccessful: true));
      } catch (e) {
        emit(currentState.copyWith(isSubmitting: false, submissionError: e.toString()));
      }
    }
  }

  Future<void> _onCheckPendingRequest(CheckPendingRequest event, Emitter<AdvanceOnSalaryState> emit) async {
    final currentState = state;
    if (currentState is AdvanceOnSalaryFormState) {
      emit(currentState.copyWith(isCheckingPendingRequest: true));

      try {
        final hasPending = await advanceOnSalaryRepo.hasPendingRequest(event.userCode);

        if (state is AdvanceOnSalaryFormState) {
          final latestState = state as AdvanceOnSalaryFormState;
          emit(latestState.copyWith(hasPendingRequest: hasPending, isCheckingPendingRequest: false));
        }
      } catch (e) {
        if (state is AdvanceOnSalaryFormState) {
          emit((state as AdvanceOnSalaryFormState).copyWith(hasPendingRequest: false, isCheckingPendingRequest: false));
        }
      }
    }
  }
}
