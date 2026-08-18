import 'dart:async';

import 'package:hrms_demo/core/constants/employee_type_selection.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/search_filter_utils.dart';
import 'package:hrms_demo/presentation/shared/employee_search_field.dart';
import 'package:hrms_demo/presentation/employees/widgets/reassign_and_suspend_dialog.dart';
import 'package:hrms_demo/presentation/employees/widgets/suspend_reason_dialog.dart';
import 'package:hrms_demo/presentation/employees/widgets/requests_report_content.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/custom_date_picker.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/data/models/user_model.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_bloc.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_event.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_state.dart';
import 'package:intl/intl.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/core/constants/department.dart';
import 'package:hrms_demo/core/constants/locations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_state.dart';

class EditEmployeePage extends StatefulWidget {
  final UserModel employee;

  /// When true, the page renders for embedding inside a dialog: it drops the
  /// [MainLayout] chrome (sidebar/app bar) and adds a close button instead. The
  /// inner [Scaffold] is kept so ScaffoldMessenger snackbars anchor in the
  /// dialog. Defaults to false — the full-page route behaviour is unchanged.
  final bool asDialog;

  const EditEmployeePage({super.key, required this.employee, this.asDialog = false});

  @override
  State<EditEmployeePage> createState() => _EditEmployeePageState();
}

class _EditEmployeePageState extends State<EditEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _arabicNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _arabicTitleController;
  late final TextEditingController _englishTitleController;
  late final TextEditingController _codeController;
  late final TextEditingController _loginCodeController;
  String? _selectedArabicDepartment;
  String? _selectedEnglishDepartment;
  String? _selectedCostCenter;
  late final TextEditingController _nPlus1Controller;
  late final TextEditingController _nPlus2Controller;
  late final TextEditingController _hireDateController;
  late final TextEditingController _nationalIdController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _arabicNicknameController;
  late final TextEditingController _englishNicknameController;
  String? _selectedLeavesEligibility;
  // Dropdown value for shift hours
  String? _selectedShiftHours;
  // Dropdown value for location
  String? _selectedLocation;
  // Dropdown value for working days
  String? _selectedWorkingDays;
  // Suspension fields — only shown on the edit form when non-null on load.
  String? _selectedSuspensionReason;
  DateTime? _selectedLastWorkingDate;
  late final TextEditingController _lastWorkingDateController;

  bool _isLoading = false;
  bool _hasChanges = false;
  bool _isInitializing = true;
  bool _isNavigatingToReport = false;
  bool _isLoadingRequests = false;
  bool _hasNavigatedToReport = false;
  bool _isSuspendLoading = false; // Add separate loading state for suspend operations
  bool _isResetPasswordLoading = false; // Loading state for password reset

  // Top Management group management
  String? _selectedGroup;
  bool _isUpdatingGroups = false;
  String? _lastGroupOperation; // Track last group operation for success message

  // Current employee data (updated from bloc)
  late UserModel _currentEmployee;

  // N+1 and N+2 user info
  UserModel? _nPlus1User;
  UserModel? _nPlus2User;
  bool _isLoadingN1 = false;
  bool _isLoadingN2 = false;

  // N+1 search layer — sits on top of _nPlus1Controller (which stays the code
  // source of truth driving _onN1Changed / _onN2Changed / save).
  final TextEditingController _n1SearchController = TextEditingController();
  List<UserModel> _n1SearchResults = [];
  bool _isSearchingN1 = false;
  Timer? _n1Debounce;
  final Map<String, String> _n1Errors = {};
  static const _kN1ValidationKey = 'n1';

  // Track intentional save to distinguish from refresh
  bool _isSavingChanges = false;

  // Users repository
  late final UsersRepo _usersRepo;

  @override
  void initState() {
    super.initState();
    _currentEmployee = widget.employee; // Initialize with widget data
    _usersRepo = context.read<UsersRepo>();
    _initializeControllers();
    _addListeners();
    // Check suspension status on page load
    context.read<EmployeesBloc>().add(isEmployeeSuspended(widget.employee.id!));
    // Load initial N+1 and N+2 user info
    _loadInitialNPlusInfo().then((_) {
      _isInitializing = false;
    });
  }

  Future<void> _loadInitialNPlusInfo() async {
    if (widget.employee.n1 != null) {
      await _onN1Changed();
    }
    if (widget.employee.n2 != null) {
      await _onN2Changed();
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.employee.englishName);
    _arabicNameController = TextEditingController(text: widget.employee.arabicName);
    _emailController = TextEditingController(text: widget.employee.email);
    _arabicTitleController = TextEditingController(text: widget.employee.title);
    _englishTitleController = TextEditingController(text: widget.employee.englishTitle);
    _codeController = TextEditingController(text: widget.employee.id.toString());
    _loginCodeController = TextEditingController(text: (widget.employee.loginCode ?? widget.employee.id).toString());
    _selectedCostCenter = widget.employee.costCenter;
    _nPlus1Controller = TextEditingController(text: widget.employee.n1.toString());
    _nPlus2Controller = TextEditingController(text: widget.employee.n2.toString());
    // Prefill the N+1 search box with the current manager's code so the field
    // shows the same value on load as the old code-entry field did.
    _n1SearchController.text = widget.employee.n1?.toString() ?? '';
    _hireDateController = TextEditingController(text: widget.employee.hireDate);
    _nationalIdController = TextEditingController(text: widget.employee.nationalId ?? '');
    _phoneController = TextEditingController(text: widget.employee.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.employee.address ?? '');
    _arabicNicknameController = TextEditingController(text: widget.employee.arabicNickname ?? '');
    _englishNicknameController = TextEditingController(text: widget.employee.englishNickname ?? '');
    _selectedLeavesEligibility = widget.employee.leavesEligibility.toString();
    // Initialize dropdown values
    _selectedShiftHours = widget.employee.shiftHours.toString();
    _selectedLocation = widget.employee.location.toString();
    _selectedWorkingDays = widget.employee.workingDays.toString();
    _selectedArabicDepartment = widget.employee.department;
    _selectedEnglishDepartment = widget.employee.englishDepartment;
    _selectedSuspensionReason = widget.employee.suspensionReason;
    _selectedLastWorkingDate = widget.employee.lastWorkingDate;
    _lastWorkingDateController = TextEditingController(
      text:
          widget.employee.lastWorkingDate != null
              ? DateFormat('d-MMM-yyyy').format(widget.employee.lastWorkingDate!)
              : '',
    );
  }

  void _addListeners() {
    _nameController.addListener(_checkForChanges);
    _arabicNameController.addListener(_checkForChanges);
    _emailController.addListener(_checkForChanges);
    _arabicTitleController.addListener(_checkForChanges);
    _englishTitleController.addListener(_checkForChanges);
    _codeController.addListener(_checkForChanges);
    _loginCodeController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
    _addressController.addListener(_checkForChanges);

    _nPlus1Controller.addListener(() {
      _checkForChanges();
      _onN1Changed();
      _onN2Changed();
    });
    _nPlus2Controller.addListener(() {
      _checkForChanges();
    });
    _hireDateController.addListener(_checkForChanges);
  }

  Future<void> _onN1Changed() async {
    final code = _nPlus1Controller.text.trim();
    if (code.isEmpty) {
      if (mounted) {
        setState(() {
          _nPlus1User = null;
        });
      }
      return;
    }

    final codeInt = int.tryParse(code);
    if (codeInt == null) {
      if (mounted) {
        setState(() {
          _nPlus1User = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingN1 = true;
      });
    }

    try {
      final user = await _usersRepo.getEmployeeById(codeInt);
      if (mounted) {
        setState(() {
          _nPlus1User = user;
          _isLoadingN1 = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nPlus1User = null;
          _isLoadingN1 = false;
        });
      }
    }
  }

  Future<void> _onN2Changed() async {
    final code = _nPlus1Controller.text.trim();
    if (code.isEmpty) {
      if (mounted) {
        setState(() {
          _nPlus2User = null;
        });
      }
      return;
    }

    final codeInt = int.tryParse(code);
    if (codeInt == null) {
      if (mounted) {
        setState(() {
          _nPlus2User = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingN2 = true;
      });
    }

    try {
      final user = await _usersRepo.getEmployeeById(codeInt);
      final usern2 = await _usersRepo.getEmployeeById(user.n1!);
      if (mounted) {
        setState(() {
          _nPlus2User = usern2;
          _isLoadingN2 = false;
          _nPlus2Controller.text = user.n1.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _nPlus2User = null;
          _isLoadingN2 = false;
        });
      }
    }
  }

  /// Debounced global active-employee search for the N+1 picker — same source
  /// the org-chart N+1 reassignment dialog uses.
  void _onN1SearchChanged(String value) {
    _n1Debounce?.cancel();
    final term = value.trim();
    if (term.isEmpty) {
      setState(() {
        _n1SearchResults = [];
        _isSearchingN1 = false;
      });
      return;
    }
    setState(() => _isSearchingN1 = true);
    _n1Debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final res = await _usersRepo.searchAllActiveEmployees(term);
        // Never offer the employee themselves as their own manager.
        final filtered = res.where((e) => e.id != widget.employee.id).toList();
        SearchFilterUtils.sortByRelevance(filtered, term);
        // Show only the 5 most relevant matches in the hover list.
        final topResults = filtered.take(5).toList();
        if (mounted) {
          setState(() {
            _n1SearchResults = topResults;
            _isSearchingN1 = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _n1SearchResults = [];
            _isSearchingN1 = false;
          });
        }
      }
    });
  }

  /// Show the picked manager's code in the box and feed it into the code source
  /// of truth (_nPlus1Controller), whose listener refreshes the green card and
  /// re-derives N+2.
  void _onN1EmployeeSelected(UserModel emp) {
    setState(() {
      _n1SearchResults = [];
      _n1Errors.remove(_kN1ValidationKey);
      _n1SearchController.text = emp.id?.toString() ?? '';
    });
    _nPlus1Controller.text = emp.id?.toString() ?? '';
  }

  /// Clear the N+1 selection entirely — empties the search box and the code
  /// source of truth, which clears the green card and N+2 via the listener.
  void _onClearN1() {
    _n1SearchController.clear();
    _n1SearchResults = [];
    _nPlus1Controller.text = '';
    setState(() {});
  }

  void _checkForChanges() {
    if (_isInitializing) return;
    final hasChanges =
        _nameController.text != widget.employee.englishName ||
        _arabicNameController.text != widget.employee.arabicName ||
        _nationalIdController.text != (widget.employee.nationalId ?? '') ||
        _phoneController.text != (widget.employee.phoneNumber ?? '') ||
        _addressController.text != (widget.employee.address ?? '') ||
        _arabicNicknameController.text != (widget.employee.arabicNickname ?? '') ||
        _englishNicknameController.text != (widget.employee.englishNickname ?? '') ||
        _emailController.text != widget.employee.email ||
        _arabicTitleController.text != widget.employee.title ||
        _englishTitleController.text != widget.employee.englishTitle ||
        _codeController.text != widget.employee.id.toString() ||
        _loginCodeController.text != (widget.employee.loginCode ?? widget.employee.id).toString() ||
        _selectedCostCenter != widget.employee.costCenter ||
        _nPlus1Controller.text != widget.employee.n1.toString() ||
        _nPlus2Controller.text != widget.employee.n2.toString() ||
        _hireDateController.text != widget.employee.hireDate ||
        _selectedLeavesEligibility != widget.employee.leavesEligibility.toString() ||
        _selectedShiftHours != widget.employee.shiftHours.toString() ||
        _selectedLocation != widget.employee.location.toString() ||
        _selectedWorkingDays != widget.employee.workingDays.toString() ||
        _selectedArabicDepartment != widget.employee.department ||
        _selectedEnglishDepartment != widget.employee.englishDepartment ||
        // Baseline against _currentEmployee: it's refreshed after suspend, so
        // the post-suspend re-sync doesn't spuriously enable Save, while a user
        // edit of the dropdown/date still does.
        _selectedSuspensionReason != _currentEmployee.suspensionReason ||
        _selectedLastWorkingDate != _currentEmployee.lastWorkingDate;

    if (_hasChanges != hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  String _extractNickname(String fullName) {
    final parts = fullName.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0];
    return '${parts.first} ${parts.last}';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _arabicNameController.dispose();
    _emailController.dispose();
    _arabicTitleController.dispose();
    _englishTitleController.dispose();
    _codeController.dispose();
    _loginCodeController.dispose();

    _nPlus1Controller.dispose();
    _nPlus2Controller.dispose();
    _n1Debounce?.cancel();
    _n1SearchController.dispose();
    _hireDateController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _arabicNicknameController.dispose();
    _englishNicknameController.dispose();
    _lastWorkingDateController.dispose();

    // No controller to dispose for  dropdown
    super.dispose();
  }

  String _getLocalizedName(UserModel employee) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    return employee.getLocalizedName(currentLocale);
  }

  String _getLocalizedTitle(UserModel employee) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    return employee.getLocalizedTitle(currentLocale);
  }

  String _getLocalizedDepartment(UserModel employee) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    return employee.getLocalizedDepartment(currentLocale);
  }

  String _getLocalizedMessage(String messageKey) {
    if (messageKey.startsWith('ADDED_TO_GROUP:')) {
      final group = messageKey.split(':')[1];
      return AppLocalizations.of(context)!.successfullyAddedUserToGroup(group);
    } else if (messageKey.startsWith('REMOVED_FROM_GROUP:')) {
      final group = messageKey.split(':')[1];
      return AppLocalizations.of(context)!.successfullyRemovedUserFromGroup(group);
    } else if (messageKey.startsWith('USER_ALREADY_IN_GROUP:')) {
      final group = messageKey.split(':')[1];
      return AppLocalizations.of(context)!.userAlreadyInGroup(group);
    } else if (messageKey.startsWith('USER_NOT_IN_GROUP:')) {
      final group = messageKey.split(':')[1];
      return AppLocalizations.of(context)!.userNotInGroup(group);
    } else if (messageKey.startsWith('FAILED_ADD_TO_GROUP:')) {
      final error = messageKey.split(':')[1];
      return AppLocalizations.of(context)!.failedToAddUserToGroup(error);
    } else if (messageKey.startsWith('FAILED_REMOVE_FROM_GROUP:')) {
      final error = messageKey.split(':')[1];
      return AppLocalizations.of(context)!.failedToRemoveUserFromGroup(error);
    }
    return messageKey; // Fallback to the original message
  }

  Widget _buildNicknameFieldWithAutoFill({
    required TextEditingController controller,
    required TextEditingController nameController,
    required String label,
    required bool readOnly,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildTextField(controller: controller, label: label, icon: Icons.badge_outlined, readOnly: readOnly),
        ),
        const SizedBox(width: 8),
        if (!readOnly)
          IconButton(
            icon: Icon(Icons.auto_awesome),
            tooltip: AppLocalizations.of(context)!.autoFillNicknameFromFullName,
            onPressed: () {
              setState(() {
                controller.text = _extractNickname(nameController.text);
              });
            },
          ),
      ],
    );
  }

  /// Wraps [child] in the full-page [MainLayout] chrome (sidebar + app bar), or
  /// returns it bare when the page is embedded in a dialog ([asDialog]). Keeping
  /// this a one-line helper lets the large build tree stay untouched.
  Widget _wrapWithChrome(BuildContext context, Widget child) {
    if (widget.asDialog) return child;
    return MainLayout(title: AppLocalizations.of(context)!.editEmployee, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final shouldLeave = await _showUnsavedChangesDialog();
          if (shouldLeave) {
            // User chose to discard changes, refresh before leaving
            if (!mounted) return true;
            context.read<EmployeesBloc>().add(const RefreshEmployees());
            return true;
          }
          return false; // User chose to stay
        }

        // No changes, safe to leave - trigger refresh
        context.read<EmployeesBloc>().add(const RefreshEmployees());
        return true;
      },
      child: _wrapWithChrome(
        context,
        // Keep this Scaffold in BOTH modes: it anchors ScaffoldMessenger
        // snackbars (save/group/password) INSIDE the dialog. Removing it would
        // make them render behind the dialog on the org-chart page.
        Scaffold(
          appBar:
              widget.asDialog
                  ? AppBar(
                    title: Text(AppLocalizations.of(context)!.editEmployee),
                    automaticallyImplyLeading: false,
                    leading: IconButton(icon: const Icon(Icons.close), onPressed: _isLoading ? null : _handleCancel),
                  )
                  : null,
          body: BlocListener<EmployeesBloc, EmployeesState>(
            listener: (context, state) {
              if (_isLoadingRequests) {
                context.read<EmployeesBloc>().add(isEmployeeSuspended(widget.employee.id!));
              }
              if (state.status == EmployeesStatus.updating || state.status == EmployeesStatus.deleting) {
                setState(() {
                  _isLoading = true;
                  _isUpdatingGroups = true;
                });
              } else if (state.status == EmployeesStatus.loading && _isLoadingRequests) {
                // Only handle loading state if it's specifically for requests
                // Do nothing here since _isLoadingRequests is already set when button is pressed
              } else if (state.status == EmployeesStatus.requestsLoaded &&
                  !_isNavigatingToReport &&
                  !_hasNavigatedToReport) {
                setState(() => _isLoadingRequests = false);

                setState(() {
                  _isNavigatingToReport = true;
                  _hasNavigatedToReport = true;
                });

                if (mounted) {
                  final requests = state.employeeRequests;

                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) => RequestsReportContent(requests: requests, initialUser: widget.employee),
                        ),
                      )
                      .then((_) {
                        if (mounted) {
                          setState(() => _isNavigatingToReport = false);
                        }
                      });
                }
              } else if (state.status == EmployeesStatus.loaded) {
                // CAPTURE STATES BEFORE RESETTING THEM!
                final isGroupOperationCompletion = _lastGroupOperation != null && _isUpdatingGroups;
                final wasPasswordResetInProgress = _isResetPasswordLoading;
                final wasSuspendInProgress = _isSuspendLoading;

                setState(() {
                  _isLoading = false;
                  _isSuspendLoading = false; // Reset suspend loading
                  _isUpdatingGroups = false; // Reset group updating
                  _isResetPasswordLoading = false; // Reset password reset loading
                  // Don't reset _isLoadingRequests here unless it was a form update
                  if (_hasChanges) {
                    _isLoadingRequests = false;
                  }
                });

                // Refresh _currentEmployee after suspend to reflect cleared
                // groups and the newly-saved suspension reason / last working
                // date, and re-sync the editable form state so those fields
                // render immediately with their persisted values.
                if (wasSuspendInProgress) {
                  final refreshed = state.employees.firstWhere(
                    (emp) => emp.id == _currentEmployee.id,
                    orElse: () => _currentEmployee,
                  );
                  if (refreshed.id == _currentEmployee.id) {
                    setState(() {
                      _currentEmployee = refreshed;
                      _selectedSuspensionReason = refreshed.suspensionReason;
                      _selectedLastWorkingDate = refreshed.lastWorkingDate;
                      _lastWorkingDateController.text =
                          refreshed.lastWorkingDate != null
                              ? DateFormat('d-MMM-yyyy').format(refreshed.lastWorkingDate!)
                              : '';
                    });
                  }
                }

                // Handle password reset success message FIRST
                if (wasPasswordResetInProgress) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.resetPasswordSuccess)));
                }

                // Handle group operation completion
                if (isGroupOperationCompletion) {
                  // Update current employee data after group operation
                  final updatedEmployee = state.employees.firstWhere(
                    (emp) => emp.id == _currentEmployee.id,
                    orElse: () => _currentEmployee,
                  );

                  if (updatedEmployee.id == _currentEmployee.id) {
                    setState(() {
                      _currentEmployee = updatedEmployee;
                    });

                    // Show success message only once
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(_getLocalizedMessage(_lastGroupOperation!))));

                    // Clear the operation tracker and refresh main employees list
                    setState(() {
                      _lastGroupOperation = null;
                    });

                    // Also refresh the main employees list to update search results
                    context.read<EmployeesBloc>().add(const RefreshEmployees());
                  }
                }

                // Only process this once when changes have been made (but not for group operations or password reset)
                if (_hasChanges && _isSavingChanges && _lastGroupOperation == null && !wasPasswordResetInProgress) {
                  // Set _hasChanges to false to prevent multiple executions
                  _hasChanges = false;
                  _isSavingChanges = false;

                  // Refresh the specific edited employee to show updated data
                  context.read<EmployeesBloc>().add(RefreshEditedEmployee(widget.employee.id!));

                  // Show success message
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.employeeUpdatedSuccessfully)));

                  // Trigger refresh and then navigate back
                  context.read<EmployeesBloc>().add(const RefreshEmployees());

                  // Wait a bit for the refresh to start processing, then navigate
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                }
              } else if (state.status == EmployeesStatus.error) {
                final wasPasswordResetInProgress = _isResetPasswordLoading;

                setState(() {
                  _isLoading = false;
                  _isSuspendLoading = false; // Reset suspend loading
                  _isUpdatingGroups = false; // Reset group updating
                  _isResetPasswordLoading = false; // Reset password reset loading
                  _isLoadingRequests = false;
                  _lastGroupOperation = null; // Clear group operation tracker
                  _isSavingChanges = false; // Reset save flag
                });

                // Handle password reset error specifically
                if (wasPasswordResetInProgress) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.errorMessage?.contains('passwordResetFailed') == true
                            ? AppLocalizations.of(context)!.resetPasswordFailed
                            : AppLocalizations.of(context)!.resetPasswordFailed,
                      ),
                    ),
                  );
                } else {
                  // Handle other errors (group operations, etc.)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        state.errorMessage != null &&
                                (state.errorMessage!.startsWith('USER_ALREADY_IN_GROUP:') ||
                                    state.errorMessage!.startsWith('USER_NOT_IN_GROUP:') ||
                                    state.errorMessage!.startsWith('FAILED_ADD_TO_GROUP:') ||
                                    state.errorMessage!.startsWith('FAILED_REMOVE_FROM_GROUP:'))
                            ? _getLocalizedMessage(state.errorMessage!)
                            : state.errorMessage ?? AppLocalizations.of(context)!.operationFailed,
                      ),
                    ),
                  );
                }
              }
            },
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: context.screenWidth < 750 ? 750 : context.screenWidth * 0.935,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Employee Info Header
                        Card(
                          color: Colors.blue[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Theme.of(context).primaryColor,
                                  child: Text(
                                    _getLocalizedName(widget.employee).isNotEmpty
                                        ? _getLocalizedName(widget.employee)[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${AppLocalizations.of(context)!.id}: ${widget.employee.id ?? 'N/A'}',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getLocalizedName(widget.employee),
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_getLocalizedTitle(widget.employee)} • ${_getLocalizedDepartment(widget.employee)}',
                                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  children: [
                                    AppButton(
                                      width: context.screenWidth > 750 ? context.screenWidth * 0.2 : 200,
                                      label:
                                          _isLoadingRequests
                                              ? AppLocalizations.of(context)!.loading
                                              : AppLocalizations.of(context)!.requestsReport,
                                      onPressed: () {
                                        setState(() {
                                          _hasNavigatedToReport = false;
                                          _isLoadingRequests = true; // Set loading immediately
                                        });

                                        final bloc = context.read<EmployeesBloc>();
                                        bloc.add(LoadEmployeeRequests(widget.employee.id.toString()));
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    BlocBuilder<EmployeesBloc, EmployeesState>(
                                      builder: (context, state) {
                                        final onPressed =
                                            _isSuspendLoading
                                                ? null
                                                : (state.isSuspended
                                                    ? () {
                                                      setState(() => _isSuspendLoading = true);
                                                      context.read<EmployeesBloc>().add(
                                                        UnsuspendEmployee(widget.employee.id!),
                                                      );
                                                    }
                                                    : () => _onSuspendPressed());

                                        return AppButton(
                                          width: context.screenWidth > 750 ? context.screenWidth * 0.2 : 200,
                                          label:
                                              state.isSuspended
                                                  ? AppLocalizations.of(context)!.unsuspendEmployee
                                                  : AppLocalizations.of(context)!.suspendEmployee,
                                          onPressed: onPressed,
                                          isLoading: _isSuspendLoading,
                                        );
                                      },
                                    ),
                                    // Reset Password Button for HR only
                                    BlocBuilder<UserBloc, UserState>(
                                      builder: (context, userState) {
                                        final currentUser = userState.user;
                                        final isHR =
                                            currentUser?.groups?.any((group) => group.toLowerCase() == 'hr') ?? false;

                                        if (!isHR) {
                                          return const SizedBox.shrink();
                                        }

                                        return Column(
                                          children: [
                                            const SizedBox(height: 8),
                                            AppButton(
                                              width: context.screenWidth > 750 ? context.screenWidth * 0.2 : 200,
                                              label: AppLocalizations.of(context)!.resetPassword,
                                              color: Colors.orange,
                                              onPressed:
                                                  _isResetPasswordLoading
                                                      ? null
                                                      : () => _showResetPasswordConfirmation(),
                                              isLoading: _isResetPasswordLoading,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        _EmployeeBalancesCard(employee: _currentEmployee, onBalanceUpdated: _onBalanceUpdated),

                        // Top Management Group Management Section
                        BlocBuilder<UserBloc, UserState>(
                          builder: (context, userState) {
                            final currentUser = userState.user;
                            final isTopManagementUser =
                                currentUser?.groups?.any((g) => g.toLowerCase() == 'top management') ??
                                false || currentUser?.englishTitle?.toUpperCase().trim() == 'COO';

                            if (!isTopManagementUser) {
                              return SizedBox.shrink();
                            }

                            return BlocBuilder<EmployeesBloc, EmployeesState>(
                              builder: (context, employeesState) {
                                final isSuspended = employeesState.isSuspended;
                                return SizedBox(
                                  width: context.screenWidth < 750 ? 750 : context.screenWidth * 0.935,
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 16),
                                      Card(
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          side: const BorderSide(color: Colors.blue, width: 1),
                                        ),
                                        color: Colors.white,
                                        child: IgnorePointer(
                                          ignoring: isSuspended,
                                          child: Opacity(
                                            opacity: isSuspended ? 0.5 : 1.0,
                                            child: Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        Icons.admin_panel_settings,
                                                        color: Colors.blue[700],
                                                        size: 24,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        AppLocalizations.of(context)!.groupManagement,
                                                        style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.bold,
                                                          color: Colors.blue[800],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),

                                                  // Current Groups Section
                                                  Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        AppLocalizations.of(context)!.currentGroups,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.grey[700],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Container(
                                                        width: double.infinity,
                                                        constraints: BoxConstraints(
                                                          maxHeight: 100, // Make it scrollable
                                                        ),
                                                        padding: const EdgeInsets.all(12),
                                                        decoration: BoxDecoration(
                                                          border: Border.all(color: Colors.blue[200]!),
                                                          borderRadius: BorderRadius.circular(8.0),
                                                          color: Colors.blue[25],
                                                        ),
                                                        child:
                                                            _currentEmployee.groups == null ||
                                                                    _currentEmployee.groups!.isEmpty
                                                                ? Text(
                                                                  AppLocalizations.of(context)!.none,
                                                                  style: TextStyle(
                                                                    color: Colors.grey[600],
                                                                    fontStyle: FontStyle.italic,
                                                                  ),
                                                                )
                                                                : SingleChildScrollView(
                                                                  scrollDirection: Axis.horizontal,
                                                                  child: Row(
                                                                    children:
                                                                        _currentEmployee.groups!.map((group) {
                                                                          return Padding(
                                                                            padding: const EdgeInsets.only(right: 8.0),
                                                                            child: Chip(
                                                                              label: Text(
                                                                                group.toUpperCase(),
                                                                                style: const TextStyle(
                                                                                  fontWeight: FontWeight.w500,
                                                                                  fontSize: 12,
                                                                                ),
                                                                              ),
                                                                              backgroundColor: Colors.blue[100],
                                                                              deleteIcon: Icon(
                                                                                Icons.remove_circle,
                                                                                color: Colors.red[600],
                                                                                size: 16,
                                                                              ),
                                                                              onDeleted:
                                                                                  () => _removeUserFromGroup(group),
                                                                              side: BorderSide(
                                                                                color: Colors.blue[300]!,
                                                                                width: 1,
                                                                              ),
                                                                            ),
                                                                          );
                                                                        }).toList(),
                                                                  ),
                                                                ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: DropdownButtonFormField<String>(
                                                          value: _selectedGroup,
                                                          decoration: InputDecoration(
                                                            labelText: AppLocalizations.of(context)!.addToGroup,
                                                            prefixIcon: Icon(Icons.group_add),
                                                            border: OutlineInputBorder(
                                                              borderRadius: BorderRadius.circular(8.0),
                                                            ),
                                                            filled: true,
                                                            fillColor: Colors.white,
                                                          ),
                                                          items: [
                                                            DropdownMenuItem<String>(
                                                              value: 'HR',
                                                              child: Text(AppLocalizations.of(context)!.groupHr),
                                                            ),
                                                            DropdownMenuItem<String>(
                                                              value: 'Finance',
                                                              child: Text(AppLocalizations.of(context)!.groupFinance),
                                                            ),
                                                            DropdownMenuItem<String>(
                                                              value: 'Legal',
                                                              child: Text(AppLocalizations.of(context)!.groupLegal),
                                                            ),
                                                            DropdownMenuItem<String>(
                                                              value: 'Top Management',
                                                              child: Text(
                                                                AppLocalizations.of(context)!.groupTopManagement,
                                                              ),
                                                            ),
                                                            DropdownMenuItem<String>(
                                                              value: 'IT',
                                                              child: Text(AppLocalizations.of(context)!.groupIt),
                                                            ),
                                                            DropdownMenuItem<String>(
                                                              value: 'Dashboard',
                                                              child: Text(AppLocalizations.of(context)!.groupDashboard),
                                                            ),
                                                          ],
                                                          onChanged: (newValue) {
                                                            setState(() {
                                                              _selectedGroup = newValue;
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      AppButton(
                                                        label: AppLocalizations.of(context)!.addToGroup,
                                                        onPressed:
                                                            (_selectedGroup == null || _isUpdatingGroups)
                                                                ? null
                                                                : _addUserToGroup,
                                                        isLoading: _isUpdatingGroups,
                                                        width: 150,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ), // Padding
                                          ), // Opacity
                                        ), // IgnorePointer
                                      ), // Card
                                    ],
                                  ), // Column
                                ); // SizedBox
                              },
                            ); // BlocBuilder<EmployeesBloc>
                          },
                        ),
                        const SizedBox(height: 24),
                        BlocBuilder<UserBloc, UserState>(
                          builder: (context, userState) {
                            final currentUser = userState.user;
                            final isTopManagement =
                                currentUser?.groups?.any((g) => g.toLowerCase() == 'top management') ??
                                false || currentUser?.englishTitle?.toUpperCase().trim() == 'COO';

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: context.screenWidth < 750 ? 350 : context.screenWidth * 0.455,
                                  child: Column(
                                    children: [
                                      _buildTextField(
                                        controller: _nameController,
                                        label: AppLocalizations.of(context)!.fullName,
                                        icon: Icons.person,
                                        readOnly: isTopManagement,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return AppLocalizations.of(context)!.pleaseEnterEmployeeName;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildNicknameFieldWithAutoFill(
                                        controller: _englishNicknameController,
                                        nameController: _nameController,
                                        label: AppLocalizations.of(context)!.englishNickname,
                                        readOnly: isTopManagement,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _arabicNameController,
                                        label: AppLocalizations.of(context)!.arabicName,
                                        icon: Icons.person_outline,
                                        readOnly: isTopManagement,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return AppLocalizations.of(context)!.pleaseEnterArabicName;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildNicknameFieldWithAutoFill(
                                        controller: _arabicNicknameController,
                                        nameController: _arabicNameController,
                                        label: AppLocalizations.of(context)!.arabicNickname,
                                        readOnly: isTopManagement,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _emailController,
                                        label: AppLocalizations.of(context)!.email,
                                        icon: Icons.email,
                                        keyboardType: TextInputType.emailAddress,
                                        readOnly: isTopManagement,
                                        validator: (value) {
                                          if (value != null &&
                                              value.isNotEmpty &&
                                              !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}').hasMatch(value)) {
                                            return AppLocalizations.of(context)!.pleaseEnterValidEmail;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _arabicTitleController,
                                        label: AppLocalizations.of(context)!.jobTitleInArabic,
                                        icon: Icons.work,
                                        readOnly: isTopManagement,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return AppLocalizations.of(context)!.pleaseEnterJobTitle;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _englishTitleController,
                                        label: AppLocalizations.of(context)!.jobTitleInEnglish,
                                        icon: Icons.work,
                                        readOnly: isTopManagement,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return AppLocalizations.of(context)!.pleaseEnterJobTitle;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildArabicDepartmentDropdown(readOnly: isTopManagement),
                                      const SizedBox(height: 16),
                                      _buildEnglishDepartmentDropdown(readOnly: isTopManagement),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _codeController,
                                        label: AppLocalizations.of(context)!.employeeCode,
                                        icon: Icons.badge,
                                        readOnly: true, // Always read-only (PK cannot be changed)
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _loginCodeController,
                                        label: AppLocalizations.of(context)!.loginCode,
                                        icon: Icons.vpn_key,
                                        readOnly: isTopManagement,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return AppLocalizations.of(context)!.pleaseEnterLoginCode;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _nationalIdController,
                                        label: AppLocalizations.of(context)!.nationalId,
                                        icon: Icons.credit_card,
                                        readOnly: isTopManagement,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _phoneController,
                                        label: AppLocalizations.of(context)!.phoneNumber,
                                        icon: Icons.phone_outlined,
                                        readOnly: isTopManagement,
                                        keyboardType: TextInputType.phone,
                                      ),
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: _addressController,
                                        label: AppLocalizations.of(context)!.address,
                                        icon: Icons.location_on_outlined,
                                        readOnly: isTopManagement,
                                      ),

                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _hireDateController,
                                        readOnly: true,
                                        style:
                                            isTopManagement
                                                ? TextStyle(color: Colors.grey[600], fontWeight: FontWeight.normal)
                                                : null,
                                        decoration: InputDecoration(
                                          labelText: AppLocalizations.of(context)!.hireDate,
                                          prefixIcon: Icon(Icons.calendar_today),
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                                          filled: true,
                                          fillColor: isTopManagement ? Colors.grey[200] : Colors.grey[50],
                                        ),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return AppLocalizations.of(context)!.pleaseEnterHireDate;
                                          }
                                          return null;
                                        },
                                        onTap:
                                            isTopManagement
                                                ? null
                                                : () async {
                                                  final DateTime? picked = await showCustomDatePicker(
                                                    context: context,
                                                    initialDate: DateTime.now(),
                                                    firstDate: DateTime(1950),
                                                    lastDate: DateTime.now(),
                                                  );
                                                  if (picked != null) {
                                                    final DateFormat format = DateFormat("d-MMM-yyyy");
                                                    setState(() {
                                                      _hireDateController.text = format.format(picked);
                                                      _checkForChanges();
                                                    });
                                                  }
                                                },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                SizedBox(
                                  width: context.screenWidth < 750 ? 350 : context.screenWidth * 0.455,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      _buildLocationDropdown(readOnly: isTopManagement),
                                      const SizedBox(height: 16),
                                      _buildCostCenterDropdown(readOnly: isTopManagement),
                                      const SizedBox(height: 16),
                                      _buildLeavesEligibilityDropdown(readOnly: isTopManagement),
                                      const SizedBox(height: 16),
                                      _buildWorkingDaysDropdown(readOnly: isTopManagement),
                                      const SizedBox(height: 16),
                                      _buildShiftHoursDropdown(readOnly: isTopManagement),
                                      const SizedBox(height: 16),
                                      // Top management keeps the read-only code
                                      // field; everyone else picks the N+1 via
                                      // employee search (results hover below).
                                      if (isTopManagement)
                                        _buildNPlusField(
                                          controller: _nPlus1Controller,
                                          label: 'N+1 (${AppLocalizations.of(context)!.directManager})',
                                          icon: Icons.supervisor_account,
                                          user: _nPlus1User,
                                          isLoading: _isLoadingN1,
                                          readOnly: true,
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return AppLocalizations.of(context)!.pleaseEnterN1Manager;
                                            }
                                            return null;
                                          },
                                        )
                                      else ...[
                                        EmployeeSearchField(
                                          searchController: _n1SearchController,
                                          labelText: 'N+1 (${AppLocalizations.of(context)!.directManager})',
                                          isSearching: _isSearchingN1,
                                          isLoadingAllEmployees: false,
                                          searchResults: _n1SearchResults,
                                          allManagedEmployees: const [],
                                          validationErrors: _n1Errors,
                                          validationKey: _kN1ValidationKey,
                                          employeeType: EmployeeTypeSelection.direct,
                                          onEmployeeTypeToggle: (_) {},
                                          onSearchChanged: _onN1SearchChanged,
                                          onClearSearch: _onClearN1,
                                          onEmployeeSelected: _onN1EmployeeSelected,
                                          showEmployeeTypeToggle: false,
                                          showBrowseDropdown: false,
                                          clearOnSelect: false,
                                        ),
                                        _buildResolvedUserCard(
                                          user: _nPlus1User,
                                          isLoading: _isLoadingN1,
                                          hasValue: _nPlus1Controller.text.isNotEmpty,
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      _buildNPlusField(
                                        controller: _nPlus2Controller,
                                        label: 'N+2 (${AppLocalizations.of(context)!.managersManager})',
                                        icon: Icons.business_center,
                                        user: _nPlus2User,
                                        isLoading: _isLoadingN2,
                                        readOnly: true,
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) {
                                            return AppLocalizations.of(context)!.pleaseEnterN2Manager;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.group, color: Colors.grey[600]),
                                              const SizedBox(width: 8),
                                              Text(
                                                AppLocalizations.of(context)!.groups,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey[300]!),
                                              borderRadius: BorderRadius.circular(8.0),
                                              color: Colors.grey[50],
                                            ),
                                            child:
                                                _currentEmployee.groups == null || _currentEmployee.groups!.isEmpty
                                                    ? Text(
                                                      AppLocalizations.of(context)!.none,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontStyle: FontStyle.italic,
                                                      ),
                                                    )
                                                    : BlocBuilder<UserBloc, UserState>(
                                                      builder: (context, userState) {
                                                        final currentUser = userState.user;
                                                        final isTopManagementUser =
                                                            currentUser?.groups?.any(
                                                              (g) => g.toLowerCase() == 'top management',
                                                            ) ??
                                                            false ||
                                                                currentUser?.englishTitle?.toUpperCase().trim() ==
                                                                    'COO';

                                                        final canManageGroups = isTopManagementUser;

                                                        return SingleChildScrollView(
                                                          scrollDirection: Axis.horizontal,
                                                          child: Row(
                                                            children:
                                                                _currentEmployee.groups!.map((group) {
                                                                  return Padding(
                                                                    padding: const EdgeInsets.only(right: 8.0),
                                                                    child: Chip(
                                                                      label: Text(
                                                                        group.toUpperCase(),
                                                                        style: const TextStyle(
                                                                          fontWeight: FontWeight.w500,
                                                                        ),
                                                                      ),
                                                                      backgroundColor: Colors.blue[100],
                                                                      deleteIcon:
                                                                          canManageGroups
                                                                              ? Icon(
                                                                                Icons.remove_circle,
                                                                                color: Colors.red[600],
                                                                                size: 18,
                                                                              )
                                                                              : null,
                                                                      onDeleted:
                                                                          canManageGroups
                                                                              ? () => _removeUserFromGroup(group)
                                                                              : null,
                                                                    ),
                                                                  );
                                                                }).toList(),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                          ),
                                        ],
                                      ),
                                      // Suspension fields — only for employees
                                      // that carry a suspension reason. Read off
                                      // _currentEmployee so they appear as soon
                                      // as the post-suspend refresh lands (not
                                      // just on reopen). Editable even while
                                      // suspended (outside the IgnorePointer
                                      // group-management wrapper).
                                      if (_currentEmployee.suspensionReason != null) ...[
                                        const SizedBox(height: 16),
                                        _buildSuspensionReasonField(readOnly: isTopManagement),
                                        if (SuspensionReasons.requiresLastWorkingDate(_selectedSuspensionReason)) ...[
                                          const SizedBox(height: 16),
                                          _buildLastWorkingDateField(readOnly: isTopManagement),
                                        ],
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        // Action Buttons
                        BlocBuilder<UserBloc, UserState>(
                          builder: (context, userState) {
                            final currentUser = userState.user;
                            final isTopManagement =
                                currentUser?.groups?.any((g) => g.toLowerCase() == 'top management') ??
                                false || currentUser?.englishTitle?.toUpperCase().trim() == 'COO';

                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppButton(
                                  label:
                                      isTopManagement
                                          ? AppLocalizations.of(context)!.back
                                          : AppLocalizations.of(context)!.cancel,
                                  onPressed: _isLoading ? null : _handleCancel,
                                  color: isTopManagement ? Colors.blue : Colors.red,
                                  width: context.screenWidth < 750 ? 250 : context.screenWidth * 0.3,
                                ),
                                if (!isTopManagement) ...[
                                  const SizedBox(width: 16),
                                  AppButton(
                                    color: _hasChanges ? Theme.of(context).primaryColor : Colors.grey,
                                    label: AppLocalizations.of(context)!.saveChanges,
                                    onPressed: (_isLoading || !_hasChanges) ? null : _saveEmployee,
                                    isLoading: _isLoading,
                                    width: context.screenWidth < 750 ? 250 : context.screenWidth * 0.3,
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: readOnly,
      style: readOnly ? TextStyle(color: Colors.grey[600], fontWeight: FontWeight.normal) : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.grey[50],
      ),
    );
  }

  Widget _buildNPlusField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required UserModel? user,
    required bool isLoading,
    required String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          readOnly: readOnly,
          controller: controller,
          keyboardType: TextInputType.number,
          validator: validator,
          style: readOnly ? TextStyle(color: Colors.grey[600], fontWeight: FontWeight.normal) : null,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            filled: true,
            fillColor: readOnly ? Colors.grey[200] : Colors.grey[50],
          ),
        ),
        _buildResolvedUserCard(user: user, isLoading: isLoading, hasValue: controller.text.isNotEmpty),
      ],
    );
  }

  /// The green "found" / red "not found" confirmation card shown under an N+1 or
  /// N+2 field. Shared by the N+2 code field and the N+1 search field so both
  /// look identical.
  Widget _buildResolvedUserCard({required UserModel? user, required bool isLoading, required bool hasValue}) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Row(
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.loading, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      );
    }
    if (user != null) {
      return Container(
        margin: const EdgeInsets.only(top: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.green[50],
          border: Border.all(color: Colors.green[200]!),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[600], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.englishName ?? '', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800])),
                  if (user.arabicName != null)
                    Text(user.arabicName!, style: TextStyle(color: Colors.green[700], fontSize: 12)),
                  if (user.title != null)
                    Text(
                      user.title!,
                      style: TextStyle(color: Colors.green[600], fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    if (hasValue) {
      return Container(
        margin: const EdgeInsets.only(top: 8.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red[200]!),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red[600], size: 20),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)!.noEmployeeFound, style: TextStyle(color: Colors.red[800], fontSize: 12)),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _handleCancel() async {
    if (_hasChanges) {
      final shouldPop = await _showUnsavedChangesDialog();
      if (shouldPop) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool> _showUnsavedChangesDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.unsavedChanges),
            content: Text(AppLocalizations.of(context)!.unsavedChangesMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.stay),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context)!.leave),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  Widget _buildShiftHoursDropdown({bool readOnly = false}) {
    return DropdownButtonFormField<String>(
      value: _selectedShiftHours,
      style: readOnly ? TextStyle(color: Colors.grey[600], fontWeight: FontWeight.normal) : null,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.shiftHours,
        prefixIcon: Icon(Icons.access_time),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.grey[50],
      ),
      items:
          ['8', '9', '12'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged:
          readOnly
              ? null
              : (newValue) {
                setState(() {
                  _selectedShiftHours = newValue;
                  _checkForChanges();
                });
              },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseSelectShiftHours;
        }
        return null;
      },
    );
  }

  Widget _buildArabicDepartmentDropdown({bool readOnly = false}) {
    return DropdownButtonFormField<String>(
      value: _selectedArabicDepartment,
      style: readOnly ? TextStyle(color: Colors.grey[600], fontWeight: FontWeight.normal) : null,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.departmentInArabic,
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.grey[50],
      ),
      items:
          Department.getAllArabicTextLabels().map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged:
          readOnly
              ? null
              : (newValue) {
                setState(() {
                  _selectedArabicDepartment = newValue;
                  // Automatically set corresponding English department
                  if (newValue != null) {
                    _selectedEnglishDepartment = Department.getEnglishFromArabic(newValue);
                  }
                  _checkForChanges();
                });
              },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseSelectDepartment;
        }
        return null;
      },
    );
  }

  Widget _buildEnglishDepartmentDropdown({bool readOnly = false}) {
    return DropdownButtonFormField<String>(
      value: _selectedEnglishDepartment,
      style: readOnly ? TextStyle(color: Colors.grey[600], fontWeight: FontWeight.normal) : null,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.departmentInEnglish,
        prefixIcon: Icon(Icons.business),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.grey[50],
      ),
      items:
          Department.getAllEnglishTextLabels().map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged:
          readOnly
              ? null
              : (newValue) {
                setState(() {
                  _selectedEnglishDepartment = newValue;
                  // Automatically set corresponding Arabic department
                  if (newValue != null) {
                    _selectedArabicDepartment = Department.getArabicFromEnglish(newValue);
                  }
                  _checkForChanges();
                });
              },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseSelectDepartment;
        }
        return null;
      },
    );
  }

  Widget _buildLocationDropdown({bool readOnly = false}) {
    return DropdownButtonFormField<String>(
      value: _selectedLocation,
      style: readOnly ? TextStyle(color: Colors.grey[600], fontWeight: FontWeight.normal) : null,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.location,
        prefixIcon: Icon(Icons.location_on),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.grey[50],
      ),
      items:
          kEmployeeLocations.map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged:
          readOnly
              ? null
              : (newValue) {
                setState(() {
                  _selectedLocation = newValue;
                  _checkForChanges();
                });
              },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseSelectLocation;
        }
        return null;
      },
    );
  }

  Widget _buildWorkingDaysDropdown({bool readOnly = false}) {
    return DropdownButtonFormField<String>(
      value: _selectedWorkingDays,
      style: readOnly ? TextStyle(color: Colors.grey[600], fontWeight: FontWeight.normal) : null,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.workingDays,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.grey[50],
      ),
      items:
          <String>['5', '6'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged:
          readOnly
              ? null
              : (newValue) {
                setState(() {
                  _selectedWorkingDays = newValue;
                  _checkForChanges();
                });
              },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseSelectWorkingDays;
        }
        return null;
      },
    );
  }

  Widget _buildLeavesEligibilityDropdown({bool readOnly = false}) {
    return DropdownButtonFormField<String>(
      value: _selectedLeavesEligibility,
      style: readOnly ? TextStyle(color: Colors.grey[600], fontWeight: FontWeight.normal) : null,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.leavesEligibility,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        contentPadding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.grey[50],
      ),
      items:
          <String>['15', '21', '30'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged:
          readOnly
              ? null
              : (newValue) {
                setState(() {
                  _selectedLeavesEligibility = newValue;
                  _checkForChanges();
                });
              },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseSelectLeavesEligibility;
        }
        return null;
      },
    );
  }

  Widget _buildCostCenterDropdown({bool readOnly = false}) {
    return DropdownButtonFormField<String>(
      value: _selectedCostCenter,
      style: readOnly ? TextStyle(color: Colors.grey[600], fontWeight: FontWeight.normal) : null,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.costCenter,
        prefixIcon: Icon(Icons.attach_money),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.grey[50],
      ),
      items:
          ['RIVERSIDE', 'HARBOUR', 'GATEWAY', 'Company', 'MARINA'].map((String value) {
            return DropdownMenuItem<String>(value: value, child: Text(value));
          }).toList(),
      onChanged:
          readOnly
              ? null
              : (newValue) {
                setState(() {
                  _selectedCostCenter = newValue;
                  _checkForChanges();
                });
              },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.pleaseSelectCostCenter;
        }
        return null;
      },
    );
  }

  void _saveEmployee() {
    if (_formKey.currentState!.validate()) {
      // The N+1 search field isn't a FormField, so validate its required-ness here.
      if (_nPlus1Controller.text.trim().isEmpty) {
        setState(() => _n1Errors[_kN1ValidationKey] = AppLocalizations.of(context)!.pleaseEnterN1Manager);
        return;
      }
      setState(() {
        _isSavingChanges = true; // Mark that we're intentionally saving
      });

      // Base off _currentEmployee (kept in sync with the latest balances from
      // both the balance dialog and bloc responses) rather than the original
      // widget.employee — otherwise a demographics-only save would carry stale
      // balances into apply_manual_balance_edit and log a spurious reversal.
      final updatedEmployee = _currentEmployee.copyWith(
        englishName: _nameController.text.trim(),
        arabicName: _arabicNameController.text.trim(),
        nationalId: _nationalIdController.text.trim().isEmpty ? null : _nationalIdController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        englishNickname: _englishNicknameController.text.trim().isEmpty ? null : _englishNicknameController.text.trim(),
        arabicNickname: _arabicNicknameController.text.trim().isEmpty ? null : _arabicNicknameController.text.trim(),
        email: _emailController.text.trim(),
        title: _arabicTitleController.text.trim(),
        englishTitle: _englishTitleController.text.trim(),
        department: _selectedArabicDepartment ?? '',
        englishDepartment: _selectedEnglishDepartment ?? '',
        hireDate: _hireDateController.text.trim(),
        id: int.tryParse(_codeController.text.trim()),
        location: _selectedLocation ?? '',
        n1: int.tryParse(_nPlus1Controller.text.trim()),
        n2: int.tryParse(_nPlus2Controller.text.trim()),
        costCenter: _selectedCostCenter ?? '',
        leavesEligibility: int.tryParse(_selectedLeavesEligibility ?? ''),
        workingDays: int.tryParse(_selectedWorkingDays ?? ''),
        shiftHours: int.tryParse(_selectedShiftHours ?? ''),
        loginCode: int.tryParse(_loginCodeController.text.trim()),
        suspensionReason: _selectedSuspensionReason,
        lastWorkingDate: _selectedLastWorkingDate,
      );

      context.read<EmployeesBloc>().add(
        UpdateEmployee(updatedEmployee, actorCode: context.read<UserBloc>().state.user?.id),
      );
    }
  }

  void _addUserToGroup() {
    if (_selectedGroup == null) return;

    final groupToAdd = _selectedGroup!;

    // Set tracking for success message
    setState(() {
      _lastGroupOperation = 'ADDED_TO_GROUP:$groupToAdd';
    });

    context.read<EmployeesBloc>().add(AddUserToGroup(employeeId: _currentEmployee.id!, group: groupToAdd));

    // Reset dropdown
    setState(() {
      _selectedGroup = null;
    });
  }

  void _removeUserFromGroup(String group) {
    // Set tracking for success message
    setState(() {
      _lastGroupOperation = 'REMOVED_FROM_GROUP:$group';
    });

    context.read<EmployeesBloc>().add(RemoveUserFromGroup(employeeId: _currentEmployee.id!, group: group));
  }

  void _onBalanceUpdated(UserModel updated) {
    setState(() => _currentEmployee = updated);
    context.read<EmployeesBloc>().add(UpdateEmployee(updated, actorCode: context.read<UserBloc>().state.user?.id));
  }

  Future<void> _showResetPasswordConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => Dialog(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              width: context.screenWidth < 600 ? context.screenWidth * 0.9 : 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.resetPasswordConfirmTitle,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.resetPasswordConfirmMessage),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(AppLocalizations.of(context)!.cancel),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text(AppLocalizations.of(context)!.resetPassword),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );

    if (confirmed == true) {
      _resetEmployeePassword();
    }
  }

  void _resetEmployeePassword() {
    setState(() {
      _isResetPasswordLoading = true;
    });

    context.read<EmployeesBloc>().add(ResetEmployeePassword(widget.employee.id.toString()));
  }

  Widget _buildSuspensionReasonField({bool readOnly = false}) {
    final l10n = AppLocalizations.of(context)!;
    String label(String reason) {
      switch (reason) {
        case SuspensionReasons.resignation:
          return l10n.reasonResignation;
        case SuspensionReasons.termination:
          return l10n.reasonTermination;
        default:
          return l10n.reasonOther;
      }
    }

    return DropdownButtonFormField<String>(
      value: _selectedSuspensionReason,
      style: readOnly ? TextStyle(color: Colors.grey[600], fontWeight: FontWeight.normal) : null,
      decoration: InputDecoration(
        labelText: l10n.suspensionReason,
        prefixIcon: const Icon(Icons.info_outline),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.grey[50],
      ),
      items:
          const [
            SuspensionReasons.resignation,
            SuspensionReasons.termination,
            SuspensionReasons.other,
          ].map((v) => DropdownMenuItem<String>(value: v, child: Text(label(v)))).toList(),
      onChanged:
          readOnly
              ? null
              : (value) {
                setState(() {
                  _selectedSuspensionReason = value;
                  // Switching to 'other' hides the date field; the stored value is kept.
                  _checkForChanges();
                });
              },
    );
  }

  Widget _buildLastWorkingDateField({bool readOnly = false}) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: _lastWorkingDateController,
      readOnly: true,
      style: readOnly ? TextStyle(color: Colors.grey[600], fontWeight: FontWeight.normal) : null,
      decoration: InputDecoration(
        labelText: l10n.lastWorkingDate,
        prefixIcon: const Icon(Icons.calendar_today),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        filled: true,
        fillColor: readOnly ? Colors.grey[200] : Colors.grey[50],
      ),
      onTap:
          readOnly
              ? null
              : () async {
                final DateTime? picked = await showCustomDatePicker(
                  context: context,
                  initialDate: _selectedLastWorkingDate ?? DateTime.now(),
                  // Any date allowed — supports future-dated notice periods.
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _selectedLastWorkingDate = picked;
                    _lastWorkingDateController.text = DateFormat('d-MMM-yyyy').format(picked);
                    _checkForChanges();
                  });
                }
              },
    );
  }

  Future<void> _onSuspendPressed() async {
    // Capture bloc before any async gap to avoid BuildContext-across-async-gap lint.
    final bloc = context.read<EmployeesBloc>();

    // Step 0: Ask for the suspension reason (and last working date for
    // resignation/termination). Cancelling aborts the whole flow.
    final reasonResult = await showDialog<SuspendReasonResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SuspendReasonDialog(),
    );
    if (reasonResult == null) return; // user cancelled

    // Show loading immediately so the user sees feedback during the network call.
    setState(() => _isSuspendLoading = true);

    // Step 1: Check for direct reports before suspending.
    List<UserModel> directReports;
    try {
      directReports = await _usersRepo.getAllManagedEmployees(widget.employee.id!);
    } catch (e) {
      if (mounted) {
        setState(() => _isSuspendLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.couldNotLoadDirectReports(e.toString()))));
      }
      return;
    }

    // Step 2: No direct reports — keep spinner; BlocListener resets it on completion.
    if (directReports.isEmpty) {
      bloc.add(
        SuspendEmployee(
          widget.employee.id!,
          suspensionReason: reasonResult.reason,
          lastWorkingDate: reasonResult.lastWorkingDate,
        ),
      );
      return;
    }

    // Has direct reports — clear spinner before opening dialog so the button
    // is re-enabled if the user cancels.
    setState(() => _isSuspendLoading = false);

    // Step 3: Has direct reports — open reassignment dialog.
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => BlocProvider.value(
            value: bloc,
            child: ReassignAndSuspendDialog(
              employeeBeingSuspended: widget.employee,
              directReports: directReports,
              suspensionReason: reasonResult.reason,
              lastWorkingDate: reasonResult.lastWorkingDate,
            ),
          ),
    );

    // Step 4: If confirmed, show loading — the SuspendWithReassignment event
    // was already dispatched inside the dialog's _onConfirm.
    if (confirmed == true && mounted) {
      setState(() => _isSuspendLoading = true);
    }
  }
}

Widget _formatBalance(BuildContext context, double? value, int? shiftHours) {
  if (value == null) return const Text('—');
  final l10n = AppLocalizations.of(context)!;
  final days = value.floor();
  final fracHours = ((value - days) * (shiftHours ?? 8)).round();
  return Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$days ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          const SizedBox(width: 2),
          Text('${l10n.dayAbbr}   ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      if (days != 0 && fracHours != 0) const SizedBox(width: 8),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('$fracHours ', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(width: 2),
          Text('${l10n.hourAbbr} ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    ],
  );
}

class _EmployeeBalancesCard extends StatelessWidget {
  final UserModel employee;
  final void Function(UserModel)? onBalanceUpdated;

  const _EmployeeBalancesCard({required this.employee, this.onBalanceUpdated});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, userState) {
        final isHR = userState.user?.groups?.any((g) => g.toLowerCase() == 'hr') ?? false;

        void editBalance({
          required String label,
          required double? currentValue,
          required UserModel Function(double) applyUpdate,
          bool isInt = false,
        }) async {
          final result = await _showEditBalanceDialog(context, label: label, currentValue: currentValue, isInt: isInt);
          if (result != null && onBalanceUpdated != null) {
            onBalanceUpdated!(applyUpdate(result));
          }
        }

        final tiles = [
          _BalanceTile(
            label: l10n.availableNow,
            value: _formatBalance(context, employee.leaveBalance, employee.shiftHours),
            color: Colors.green,
            onEdit:
                isHR && onBalanceUpdated != null
                    ? () => editBalance(
                      label: l10n.availableNow,
                      currentValue: employee.leaveBalance,
                      applyUpdate: (v) => employee.copyWith(leaveBalance: v),
                    )
                    : null,
          ),
          _BalanceTile(
            label: l10n.annualAllowanceRemaining,
            value: _formatBalance(context, employee.annualRemainingBalance, employee.shiftHours),
            color: Colors.blue,
            onEdit:
                isHR && onBalanceUpdated != null
                    ? () => editBalance(
                      label: l10n.annualAllowanceRemaining,
                      currentValue: employee.annualRemainingBalance,
                      applyUpdate: (v) => employee.copyWith(annualRemainingBalance: v),
                    )
                    : null,
          ),
          _BalanceTile(
            label: l10n.overtime,
            value: _formatBalance(context, employee.overtimeBalance, employee.shiftHours),
            color: Colors.teal,
            onEdit:
                isHR && onBalanceUpdated != null
                    ? () => editBalance(
                      label: l10n.overtime,
                      currentValue: employee.overtimeBalance,
                      applyUpdate: (v) => employee.copyWith(overtimeBalance: v),
                    )
                    : null,
          ),
          _BalanceTile(
            label: l10n.emergency,
            value: _formatBalance(context, employee.emergencyBalance, employee.shiftHours),
            color: Colors.amber[700]!,
            onEdit:
                isHR && onBalanceUpdated != null
                    ? () => editBalance(
                      label: l10n.emergency,
                      currentValue: employee.emergencyBalance,
                      applyUpdate: (v) => employee.copyWith(emergencyBalance: v),
                    )
                    : null,
          ),
          _BalanceTile(
            label: l10n.missingPunching,
            value:
                employee.missingPunchBalance != null
                    ? Text(
                      '${employee.missingPunchBalance}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                    )
                    : const Text('—'),
            color: Colors.blueGrey,
            onEdit:
                isHR && onBalanceUpdated != null
                    ? () => editBalance(
                      label: l10n.missingPunching,
                      currentValue: employee.missingPunchBalance?.toDouble(),
                      isInt: true,
                      applyUpdate: (v) => employee.copyWith(missingPunchBalance: v.round()),
                    )
                    : null,
          ),
        ];

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.employeeBalances, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Row(
                  children: tiles.expand((t) => [Expanded(child: t), const SizedBox(width: 8)]).toList()..removeLast(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BalanceTile extends StatelessWidget {
  final String label;
  final Widget value;
  final Color color;
  final VoidCallback? onEdit;

  const _BalanceTile({required this.label, required this.value, required this.color, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              value,
              const SizedBox(height: 2),
              Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
            ],
          ),
          if (onEdit != null)
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: onEdit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: Colors.grey[500],
                tooltip: AppLocalizations.of(context)!.edit,
              ),
            ),
        ],
      ),
    );
  }
}

Future<double?> _showEditBalanceDialog(
  BuildContext context, {
  required String label,
  double? currentValue,
  bool isInt = false,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(
    text: currentValue != null ? (isInt ? currentValue.round().toString() : currentValue.toString()) : '',
  );
  final formKey = GlobalKey<FormState>();

  return showDialog<double>(
    context: context,
    builder:
        (ctx) => AlertDialog(
          title: Text(label),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
              onFieldSubmitted: (_) {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, double.parse(controller.text.trim()));
                }
              },
              validator: (v) {
                if (v == null || v.trim().isEmpty) return l10n.required;
                final parsed = double.tryParse(v.trim());
                if (parsed == null || parsed < 0) return l10n.pleaseEnterValidNumber;
                return null;
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, double.parse(controller.text.trim()));
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
  );
}
