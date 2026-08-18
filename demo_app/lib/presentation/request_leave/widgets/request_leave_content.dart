import 'dart:typed_data';

import 'package:hrms_demo/core/constants/leave_type.dart';
import 'package:hrms_demo/core/constants/request_constants.dart';
import 'package:hrms_demo/core/tutorial/tutorial_keys.dart';
import 'package:hrms_demo/core/tutorial/tutorial_steps.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:hrms_demo/core/constants/sizes.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/leave_error_localizer.dart';
import 'package:hrms_demo/core/utils/navigation_helper.dart';
import 'package:hrms_demo/data/models/disabled_date_info.dart';
import 'package:hrms_demo/data/models/leave_request_model.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_state.dart';
import 'package:hrms_demo/presentation/request_leave/bloc/request_leave_bloc.dart';
import 'package:hrms_demo/presentation/request_leave/bloc/request_leave_event.dart';
import 'package:hrms_demo/presentation/request_leave/bloc/request_leave_state.dart';
import 'package:hrms_demo/presentation/request_leave/widgets/request_leave_page.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/app_text_field.dart';
import 'package:hrms_demo/presentation/widgets/custom_date_picker.dart';
import 'package:hrms_demo/presentation/widgets/form_message.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';

final class RequestLeaveContent extends StatefulWidget {
  const RequestLeaveContent({super.key});

  @override
  State<RequestLeaveContent> createState() => _RequestLeaveContentState();
}

class _RequestLeaveContentState extends State<RequestLeaveContent> {
  bool _isRefreshingProfile = false;
  int? _selectedHours;

  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _leaveTypeController = TextEditingController();
  final TextEditingController _leaveHoursController = TextEditingController();

  /// Starts the guided tour for the Request Leave page.
  ///
  /// Mirrors the dashboard's `_startTutorial`: defers a frame so all targets are
  /// laid out, then filters out steps whose keyed widget isn't currently in the
  /// tree (the hours dropdown is conditional, and the balances/day-count render
  /// only after data loads), and auto-scrolls each target into view.
  void _startLeaveTutorial(BuildContext ctx) {
    final l10n = AppLocalizations.of(ctx)!;
    Future.delayed(Duration.zero, () {
      if (!ctx.mounted) return;
      final steps =
          buildRequestLeaveSteps(l10n, ctx).where((step) {
            if (step.keyTarget == null) return true;
            return step.keyTarget!.currentContext != null;
          }).toList();
      TutorialCoachMark(
        targets: steps,
        colorShadow: Colors.black87,
        paddingFocus: 4,
        opacityShadow: 0.8,
        hideSkip: true,
        beforeFocus: (target) async {
          final targetCtx = target.keyTarget?.currentContext;
          if (targetCtx == null) return;
          await Scrollable.ensureVisible(
            targetCtx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.3,
          );
        },
      ).show(context: ctx, rootOverlay: true);
    });
  }

  /// Finds the first disabled date after the given date
  DateTime? _findNearestDisabledDateAfter(DateTime date, List<DisabledDateInfo> disabledDates) {
    if (disabledDates.isEmpty) return null;

    // Normalize date to midnight for comparison
    final dateOnly = DateTime(date.year, date.month, date.day);

    // Filter disabled dates that come after the given date and sort them
    final datesAfter =
        disabledDates.map((info) => info.date).where((disabledDate) {
            final disabledDateOnly = DateTime(disabledDate.year, disabledDate.month, disabledDate.day);
            return disabledDateOnly.isAfter(dateOnly);
          }).toList()
          ..sort();

    return datesAfter.isNotEmpty ? datesAfter.first : null;
  }

  /// Finds the first disabled date before the given date
  DateTime? _findNearestDisabledDateBefore(DateTime date, List<DisabledDateInfo> disabledDates) {
    if (disabledDates.isEmpty) return null;

    // Normalize date to midnight for comparison
    final dateOnly = DateTime(date.year, date.month, date.day);

    // Filter disabled dates that come before the given date and sort them descending
    final datesBefore =
        disabledDates.map((info) => info.date).where((disabledDate) {
            final disabledDateOnly = DateTime(disabledDate.year, disabledDate.month, disabledDate.day);
            return disabledDateOnly.isBefore(dateOnly);
          }).toList()
          ..sort((a, b) => b.compareTo(a)); // Sort descending

    return datesBefore.isNotEmpty ? datesBefore.first : null;
  }

  /// Calculates the latest allowed "to date" based on disabled dates
  /// If there are disabled dates after the from date, the max to date is the day before the nearest disabled date
  DateTime? _getLatestAllowedToDate(DateTime fromDate, List<DisabledDateInfo> disabledDates) {
    final nearestDisabledDate = _findNearestDisabledDateAfter(fromDate, disabledDates);

    if (nearestDisabledDate != null) {
      // Return the day before the nearest disabled date
      return nearestDisabledDate.subtract(const Duration(days: 1));
    }

    return null; // No constraint
  }

  /// Calculates the earliest allowed "from date" based on disabled dates
  /// If there are disabled dates before the to date, the min from date is the later of:
  /// - The day after the nearest disabled date
  /// - 7 days before today (existing minimum)
  DateTime? _getEarliestAllowedFromDate(DateTime toDate, List<DisabledDateInfo> disabledDates) {
    final defaultMinimum = DateTime.now().subtract(const Duration(days: kRequestBackWindowDays));

    final nearestDisabledDate = _findNearestDisabledDateBefore(toDate, disabledDates);

    if (nearestDisabledDate != null) {
      // Get the day after the nearest disabled date
      final dayAfterDisabled = nearestDisabledDate.add(const Duration(days: 1));

      // Return whichever is later: the day after disabled date or the default minimum
      return dayAfterDisabled.isAfter(defaultMinimum) ? dayAfterDisabled : defaultMinimum;
    }

    return defaultMinimum; // Use default minimum
  }

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller,
    DateTime? firstDate,
    DateTime? lastDate,
  ) async {
    final requestLeaveState = context.read<RequestLeaveBloc>().state;

    // Clamp the date range to the current calendar year: leave balances are
    // tracked per calendar year, so requests outside the current year would
    // be rejected by validate_leave_request anyway. This is a UX guard only.
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31);

    var effectiveFirst = firstDate ?? now.subtract(const Duration(days: kRequestBackWindowDays));
    var effectiveLast = lastDate ?? DateTime(2100);

    if (effectiveFirst.isBefore(yearStart)) effectiveFirst = yearStart;
    if (effectiveLast.isAfter(yearEnd)) effectiveLast = yearEnd;

    final picked = await showCustomDatePicker(
      context: context,
      initialDate: firstDate ?? (controller.text.isNotEmpty ? DateTime.parse(controller.text) : DateTime.now()),
      firstDate: effectiveFirst,
      lastDate: effectiveLast,
      disabledDates: requestLeaveState.disabledDates,
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _pickSickNotes(BuildContext context) async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true, // Required for web
    );

    if (result != null && result.files.isNotEmpty) {
      final List<Uint8List> sickNoteFiles = result.files.map((f) => f.bytes!).toList();
      final List<String> sickNoteFileNames = result.files.map((f) => f.name).toList();

      context.read<RequestLeaveBloc>().add(UpdateSickNotes(sickNoteFiles, sickNoteFileNames));

      context.read<RequestLeaveBloc>().add(
        ValidateForm(
          fromDate: _fromDateController.text,
          toDate: _toDateController.text,
          leaveType: _leaveTypeController.text,
          leaveHours: _leaveHoursController.text.isNotEmpty ? int.parse(_leaveHoursController.text.substring(0, 1)) : 0,

          shiftHours: context.read<UserBloc>().state.user?.shiftHours,
        ),
      );
    } else {
      // User canceled the picker
    }
  }

  Future<void> _submit(BuildContext context) async {
    final fromDate = _fromDateController.text;
    final toDate = _toDateController.text;
    final leaveTypeEnum = context.read<RequestLeaveBloc>().state.leaveType;
    final leaveType = leaveTypeEnum?.label ?? ''; // Use English label from enum
    final dayCount = context.read<RequestLeaveBloc>().state.dayCount;

    context.read<RequestLeaveBloc>().add(
      SubmitLeaveRequest(
        LeaveRequestModel(
          userId: (context.read<UserBloc>().state.user?.id ?? 0),
          dateFrom: fromDate.isNotEmpty ? DateTime.parse(fromDate) : null,
          dateTo: toDate.isNotEmpty ? DateTime.parse(toDate) : null,
          leaveType: leaveType,
          numberOfDays: dayCount,
          n1Code: (context.read<UserBloc>().state.user?.n1 ?? 0),
          n2Code: (context.read<UserBloc>().state.user?.n2 ?? 0),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Load existing leave requests when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userBloc = context.read<UserBloc>();
      final userId = userBloc.state.user?.id;
      if (userId != null) {
        context.read<RequestLeaveBloc>().add(LoadExistingLeaveRequests(userId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RequestLeaveBloc, RequestLeaveState>(
      listener: (context, state) {
        if (state.status == Status.success) {
          final userBloc = context.read<UserBloc>();
          final userId = userBloc.state.user?.id.toString();

          userBloc.add(MarkRequestsAvailable(hasLeaveRequests: true));
          if (userId != null) {
            userBloc.add(LoadUserProfile(userId));
          }

          setState(() {
            _isRefreshingProfile = false;
          });

          NavigationHelper.pushReplacementWithSidebarSync(
            context,
            routeName: '/leave/new',
            page: const RequestLeavePage(),
          );

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.lRSubmittedSuccessfully)));
        }
        // Submission errors are surfaced inline below the submit button via
        // [FormMessage] (see builder), not as a transient snackbar.
      },
      builder: (context, state) {
        return BlocBuilder<UserBloc, UserState>(
          builder: (context, userState) {
            final isEmergency = state.leaveType == LeaveType.emergency;
            final isEmergencyTooLong = state.dayCount > 1;
            final emergencyBalance = userState.user?.emergencyBalance ?? 0;
            final isEmergencyBalanceInsufficient = isEmergency && (state.dayCount > emergencyBalance);

            final shiftHours = userState.user?.shiftHours ?? 0;

            final leaveBalance = userState.user?.leaveBalance ?? 0;
            // annual_remaining_balance — "X days left of this year's allowance",
            // the familiar number from the old single-balance model (Rule: kept
            // for backward-compatible display alongside the unified "available now").
            final annualRemainingBalance = userState.user?.annualRemainingBalance;
            final carryForwardBalance = userState.user?.carryForwardBalance ?? 0;
            final overtimeCarryForwardBalance = userState.user?.overtimeCarryForwardBalance ?? 0;
            final overtimeBalance = userState.user?.overtimeBalance ?? 0;
            final overtimeBalanceDays = overtimeBalance.toInt();
            final overtimeBalanceHours = (overtimeBalance - overtimeBalanceDays) * shiftHours;

            final leaveBalnceDays = leaveBalance.toInt();
            final leaveBalanceHours = (leaveBalance - leaveBalnceDays) * shiftHours;
            final submitButtonFactor = context.screenWidth < 600 ? 0.5 : 1;

            // Rule: "Leave Balance" is now unified to mean "available to take right
            // now" and can go negative (a deficit that resolves as future monthly
            // loads land) — surface that with warning styling and a "catching up"
            // hint instead of letting a negative number look like a display bug.
            final availableNowLabel =
                leaveBalance < 0
                    ? '${AppLocalizations.of(context)!.availableNow}: ${leaveBalance.toStringAsFixed(1)} ${AppLocalizations.of(context)!.days} (${AppLocalizations.of(context)!.catchingUp})'
                    : leaveBalanceHours > 0
                    ? '${AppLocalizations.of(context)!.availableNow}: $leaveBalnceDays ${AppLocalizations.of(context)!.days} & ${leaveBalanceHours.toStringAsFixed(1)} ${AppLocalizations.of(context)!.hoursLabel}'
                    : '${AppLocalizations.of(context)!.availableNow}: $leaveBalnceDays ${AppLocalizations.of(context)!.days}';
            final overtimeExpiryNote =
                overtimeCarryForwardBalance > 0
                    ? ' (${overtimeCarryForwardBalance.toStringAsFixed(1)} ${AppLocalizations.of(context)!.expiresApr1})'
                    : '';
            final overtimeLabel =
                overtimeBalance >= 1 && overtimeBalanceHours >= 1
                    ? '${AppLocalizations.of(context)!.overTimeBalance}: $overtimeBalanceDays ${AppLocalizations.of(context)!.days} & ${overtimeBalanceHours.toStringAsFixed(1)} ${AppLocalizations.of(context)!.hoursLabel}$overtimeExpiryNote'
                    : overtimeBalance >= 1 && overtimeBalanceHours < 1
                    ? '${AppLocalizations.of(context)!.overTimeBalance}: ${overtimeBalance.toStringAsFixed(1)} ${AppLocalizations.of(context)!.days}$overtimeExpiryNote'
                    : '${AppLocalizations.of(context)!.overTimeBalance}: ${(overtimeBalance * shiftHours).toStringAsFixed(1)} ${AppLocalizations.of(context)!.hoursLabel}$overtimeExpiryNote';

            // Chip set: "available now" (can be negative), annual-allowance
            // figure, overtime (with Apr-1 expiry note), and carry-forward.
            final balanceChips = <Widget>[
              Chip(backgroundColor: leaveBalance < 0 ? Colors.orange.shade100 : null, label: Text(availableNowLabel)),
              if (annualRemainingBalance != null)
                Chip(
                  label: Text(
                    '${AppLocalizations.of(context)!.annualAllowanceRemaining}: ${annualRemainingBalance.toStringAsFixed(1)} ${AppLocalizations.of(context)!.days}',
                  ),
                ),
              Chip(label: Text(overtimeLabel)),
              if (carryForwardBalance > 0)
                Chip(
                  label: Text(
                    '${AppLocalizations.of(context)!.carryForward} (${AppLocalizations.of(context)!.expiresApr1}): ${carryForwardBalance.toStringAsFixed(1)} ${AppLocalizations.of(context)!.days}',
                  ),
                ),
            ];
            return Stack(
              children: [
                MainLayout(
                  title: AppLocalizations.of(context)!.requestLeave,
                  extraActions: [
                    Builder(
                      builder:
                          (ctx) => IconButton(
                            icon: const Icon(Icons.help_outline, color: Colors.white),
                            tooltip: AppLocalizations.of(ctx)!.tutHelpTooltip,
                            onPressed: () => _startLeaveTutorial(ctx),
                          ),
                    ),
                  ],
                  child: Align(
                    alignment: Alignment.center,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(minWidth: context.screenWidth * 0.9),
                            child: Align(
                              alignment: context.screenWidth < 500 ? Alignment.centerLeft : Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        key: TutorialKeys.leaveBalances,
                                        width:
                                            context.screenWidth > 600 ? kMaxInputWidth + 16 : context.screenWidth * 0.9,
                                        child: Wrap(
                                          alignment: WrapAlignment.center,
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: balanceChips,
                                        ),
                                      ),
                                      // Rule 2.6b — sets expectations for employees currently
                                      // in deficit: the dropdown no longer hard-blocks Annual
                                      // requests on today's balance alone (it may still be
                                      // covered by monthly loads landing before the leave
                                      // dates), so explain that validate_leave_request will
                                      // make the real determination on submit.
                                      if (leaveBalance < 0) ...[
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Text(
                                            AppLocalizations.of(context)!.negativeBalanceHint,
                                            textAlign: TextAlign.center,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(color: Colors.orange.shade800),
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 16,
                                        runSpacing: 16,
                                        alignment: WrapAlignment.center,
                                        children: [
                                          GestureDetector(
                                            key: TutorialKeys.leaveFromDate,
                                            onTap:
                                                state.disabledDatesLoaded
                                                    ? () async {
                                                      // Store previous values to compare
                                                      final previousFromDate = _fromDateController.text;
                                                      final previousToDate = _toDateController.text;

                                                      // Calculate smart minimum date based on disabled dates
                                                      DateTime? smartMinDate;
                                                      DateTime? smartMaxDate;

                                                      if (_toDateController.text.isNotEmpty) {
                                                        final toDate = DateTime.parse(_toDateController.text);
                                                        final requestLeaveState =
                                                            context.read<RequestLeaveBloc>().state;

                                                        // Get the smart minimum from date
                                                        smartMinDate = _getEarliestAllowedFromDate(
                                                          toDate,
                                                          requestLeaveState.disabledDates,
                                                        );

                                                        // Max is the selected "to date"
                                                        smartMaxDate = toDate;
                                                      }

                                                      await _pickDate(
                                                        context,
                                                        _fromDateController,
                                                        smartMinDate,
                                                        smartMaxDate,
                                                      );

                                                      context.read<RequestLeaveBloc>().add(
                                                        ValidateForm(
                                                          fromDate: _fromDateController.text,
                                                          toDate: _toDateController.text,
                                                          leaveType: _leaveTypeController.text,
                                                          leaveHours:
                                                              _leaveHoursController.text.isNotEmpty
                                                                  ? int.parse(
                                                                    _leaveHoursController.text.substring(0, 1),
                                                                  )
                                                                  : 0,

                                                          shiftHours: userState.user?.shiftHours,
                                                        ),
                                                      );

                                                      context.read<RequestLeaveBloc>().add(
                                                        UpdateDateRange(
                                                          fromDate: _fromDateController.text,
                                                          toDate: _toDateController.text,
                                                          leaveHours:
                                                              _leaveHoursController.text.isNotEmpty
                                                                  ? int.parse(
                                                                    _leaveHoursController.text.substring(0, 1),
                                                                  )
                                                                  : 0,
                                                          shiftHours: userState.user?.shiftHours,
                                                        ),
                                                      );

                                                      // Only reset leave type if date range actually changed
                                                      if (previousFromDate != _fromDateController.text ||
                                                          previousToDate != _toDateController.text) {
                                                        _leaveTypeController.clear();
                                                        context.read<RequestLeaveBloc>().add(ResetLeaveType());
                                                      }
                                                    }
                                                    : null,
                                            child: AbsorbPointer(
                                              child: AppTextField(
                                                width: 0.5 * kMaxInputWidth,
                                                label: AppLocalizations.of(context)!.dateFrom,
                                                autofocus: false,
                                                controller: _fromDateController,
                                              ),
                                            ),
                                          ),

                                          GestureDetector(
                                            key: TutorialKeys.leaveToDate,
                                            onTap:
                                                state.disabledDatesLoaded
                                                    ? () async {
                                                      // Store previous values to compare
                                                      final previousFromDate = _fromDateController.text;
                                                      final previousToDate = _toDateController.text;

                                                      // Calculate smart maximum date based on disabled dates
                                                      DateTime? smartMinDate;
                                                      DateTime? smartMaxDate;

                                                      if (_fromDateController.text.isNotEmpty) {
                                                        final fromDate = DateTime.parse(_fromDateController.text);
                                                        final requestLeaveState =
                                                            context.read<RequestLeaveBloc>().state;

                                                        // Min is the selected "from date"
                                                        smartMinDate = fromDate;

                                                        // Get the smart maximum to date
                                                        smartMaxDate = _getLatestAllowedToDate(
                                                          fromDate,
                                                          requestLeaveState.disabledDates,
                                                        );
                                                      }

                                                      await _pickDate(
                                                        context,
                                                        _toDateController,
                                                        smartMinDate,
                                                        smartMaxDate,
                                                      );

                                                      context.read<RequestLeaveBloc>().add(
                                                        ValidateForm(
                                                          fromDate: _fromDateController.text,
                                                          toDate: _toDateController.text,
                                                          leaveType: _leaveTypeController.text,
                                                          leaveHours:
                                                              _leaveHoursController.text.isNotEmpty
                                                                  ? int.parse(
                                                                    _leaveHoursController.text.substring(0, 1),
                                                                  )
                                                                  : 0,
                                                          shiftHours: userState.user?.shiftHours,
                                                        ),
                                                      );

                                                      context.read<RequestLeaveBloc>().add(
                                                        UpdateDateRange(
                                                          fromDate: _fromDateController.text,
                                                          toDate: _toDateController.text,
                                                          leaveHours:
                                                              _leaveHoursController.text.isNotEmpty
                                                                  ? int.parse(
                                                                    _leaveHoursController.text.substring(0, 1),
                                                                  )
                                                                  : 0,
                                                          shiftHours: userState.user?.shiftHours,
                                                        ),
                                                      );

                                                      // Only reset leave type if date range actually changed
                                                      if (previousFromDate != _fromDateController.text ||
                                                          previousToDate != _toDateController.text) {
                                                        _leaveTypeController.clear();
                                                        context.read<RequestLeaveBloc>().add(ResetLeaveType());
                                                      }
                                                    }
                                                    : null,
                                            child: AbsorbPointer(
                                              child: AppTextField(
                                                width: kMaxInputWidth * 0.5,
                                                label: AppLocalizations.of(context)!.dateTo,
                                                autofocus: false,
                                                controller: _toDateController,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Wrap(
                                        spacing: 16,
                                        runSpacing: 16,
                                        alignment: WrapAlignment.center,
                                        children: [
                                          // Dropdown for leave hours
                                          if (state.dayCount <= 1 && state.dayCount > 0)
                                            BlocListener<RequestLeaveBloc, RequestLeaveState>(
                                              key: TutorialKeys.leaveHours,
                                              listener: (context, state) {
                                                // Clear hours when day count is not 1
                                                if (state.dayCount >= 1 && _selectedHours != null) {
                                                  setState(() {
                                                    _selectedHours = null;
                                                  });
                                                  _leaveHoursController.clear();
                                                  // Also clear leave type when hours are cleared
                                                  _leaveTypeController.clear();
                                                  context.read<RequestLeaveBloc>().add(UpdateLeaveType(null));
                                                }
                                              },
                                              child: SizedBox(
                                                width: kMaxInputWidth * 0.5,
                                                child: DropdownButtonFormField<int>(
                                                  value: _selectedHours,
                                                  decoration: InputDecoration(
                                                    labelText: AppLocalizations.of(context)!.hours,

                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                                                    contentPadding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 16,
                                                    ),
                                                    suffixIcon:
                                                        _selectedHours != null
                                                            ? IconButton(
                                                              icon: const Icon(Icons.close, size: 18),
                                                              padding: EdgeInsets.zero,
                                                              constraints: const BoxConstraints(),
                                                              onPressed: () {
                                                                setState(() {
                                                                  _selectedHours = null;
                                                                });
                                                                // Clear the hours controller
                                                                _leaveHoursController.clear();

                                                                // Clear leave type
                                                                _leaveTypeController.clear();

                                                                // Reset leave type in state
                                                                context.read<RequestLeaveBloc>().add(
                                                                  UpdateLeaveType(null),
                                                                );

                                                                // Update date range with 0 hours
                                                                context.read<RequestLeaveBloc>().add(
                                                                  UpdateDateRange(
                                                                    fromDate: _fromDateController.text,
                                                                    toDate: _toDateController.text,
                                                                    leaveHours: 0,
                                                                    shiftHours: userState.user?.shiftHours,
                                                                  ),
                                                                );

                                                                // Validate form
                                                                context.read<RequestLeaveBloc>().add(
                                                                  ValidateForm(
                                                                    fromDate: _fromDateController.text,
                                                                    toDate: _toDateController.text,
                                                                    leaveType: _leaveTypeController.text,
                                                                    leaveHours: 0,
                                                                    shiftHours: userState.user?.shiftHours,
                                                                  ),
                                                                );
                                                              },
                                                            )
                                                            : null,
                                                  ),
                                                  items: List.generate(
                                                    shiftHours - 1,
                                                    (index) => DropdownMenuItem<int>(
                                                      value: index + 1,
                                                      child: Text(
                                                        '${index + 1} ${index + 1 > 1 ? AppLocalizations.of(context)!.hoursLabel : AppLocalizations.of(context)!.hourLabel}',
                                                      ),
                                                    ),
                                                  ),
                                                  onChanged:
                                                      state.dayCount <= 1
                                                          ? (value) {
                                                            setState(() {
                                                              _selectedHours = value;
                                                            });

                                                            if (value != null) {
                                                              _leaveHoursController.text = value.toString();
                                                            }

                                                            context.read<RequestLeaveBloc>().add(
                                                              UpdateDateRange(
                                                                fromDate: _fromDateController.text,
                                                                toDate: _toDateController.text,
                                                                leaveHours: value ?? 0,
                                                                shiftHours: userState.user?.shiftHours,
                                                              ),
                                                            );

                                                            // Auto-set leave type to emergency when hours are selected
                                                            // if (value != null &&
                                                            //     value > 0) {
                                                            //   _leaveTypeController
                                                            //       .text = LeaveType
                                                            //       .emergency
                                                            //       .localizedLabel(
                                                            //         context,
                                                            //       );
                                                            //   context
                                                            //       .read<
                                                            //         RequestLeaveBloc
                                                            //       >()
                                                            //       .add(
                                                            //         UpdateLeaveType(
                                                            //           LeaveType
                                                            //               .emergency,
                                                            //         ),
                                                            //       );
                                                            // }

                                                            if (value != null && value >= shiftHours) {
                                                              _leaveTypeController.clear();
                                                              context.read<RequestLeaveBloc>().add(ResetLeaveType());
                                                            }

                                                            context.read<RequestLeaveBloc>().add(
                                                              ValidateForm(
                                                                fromDate: _fromDateController.text,
                                                                toDate: _toDateController.text,
                                                                leaveType: _leaveTypeController.text,
                                                                leaveHours: value ?? 0,
                                                                shiftHours: userState.user?.shiftHours,
                                                              ),
                                                            );
                                                          }
                                                          : null,
                                                ),
                                              ),
                                            ),
                                          // Leave type dropdown
                                          DropdownMenu<LeaveType>(
                                            key: TutorialKeys.leaveTypeDropdown,
                                            width:
                                                state.dayCount <= 1 && state.dayCount > 0
                                                    ? kMaxInputWidth * 0.5
                                                    : context.screenWidth > 600
                                                    ? kMaxInputWidth + 16
                                                    : kMaxInputWidth * 0.5,
                                            // enabled:
                                            //     _leaveHoursController
                                            //         .text
                                            //         .isEmpty,
                                            dropdownMenuEntries:
                                                LeaveType.values.map((leaveType) {
                                                  if (leaveType == LeaveType.emergency) {
                                                    if (isEmergencyTooLong) {
                                                      return DropdownMenuEntry(
                                                        enabled: false,
                                                        value: LeaveType.emergency,
                                                        label:
                                                            '${AppLocalizations.of(context)!.emergency} (${AppLocalizations.of(context)!.emergencyMaxOneDay})',
                                                      );
                                                    }
                                                    final annualBalance = userState.user?.leaveBalance ?? 0;
                                                    // Allow Emergency while CF remains: it draws from the
                                                    // same Annual/Emergency pool, and carry-forward days are
                                                    // spendable (server validates the precise Mar-31 cutoff).
                                                    if (annualBalance == 0 && carryForwardBalance <= 0) {
                                                      return DropdownMenuEntry(
                                                        enabled: false,
                                                        value: LeaveType.emergency,
                                                        label:
                                                            '${AppLocalizations.of(context)!.emergency} (${AppLocalizations.of(context)!.emergencyRequiresAnnual})',
                                                      );
                                                    }
                                                  }
                                                  if (leaveType == LeaveType.annual) {
                                                    // Disable annual leave if hours are selected
                                                    if (_leaveHoursController.text.isNotEmpty) {
                                                      return DropdownMenuEntry(
                                                        enabled: false,
                                                        value: LeaveType.annual,
                                                        label: AppLocalizations.of(context)!.annual,
                                                      );
                                                    }
                                                    // Keep Annual selectable when carry-forward remains even
                                                    // if "Leave Balance" is 0 — CF days are spendable (the
                                                    // server enforces the exact Mar-31 expiry on submit).
                                                    if (userState.user?.leaveBalance == 0 && carryForwardBalance <= 0) {
                                                      return DropdownMenuEntry(
                                                        enabled: false,
                                                        value: LeaveType.annual,
                                                        label: '${AppLocalizations.of(context)!.annual} (0)',
                                                      );
                                                    }

                                                    final dayCount = context.read<RequestLeaveBloc>().state.dayCount;
                                                    final overtimeBalance = userState.user?.overtimeBalance ?? 0;
                                                    final daysTakenThisYear = userState.user?.daysTakenThisYear ?? 0;
                                                    final leavesEligibility = userState.user?.leavesEligibility ?? 0;

                                                    // Rule 2.1b #1 — overtime priority: formalizes the
                                                    // existing frontend-only check; validate_leave_request
                                                    // enforces the same rule server-side as the final gate.
                                                    if (overtimeBalance > 0.2) {
                                                      return DropdownMenuEntry(
                                                        enabled: false,
                                                        value: LeaveType.annual,
                                                        label: AppLocalizations.of(context)!.useCompensationFirst,
                                                      );
                                                    }
                                                    // Annual cap quick hint; validate_leave_request; quick hint, validate_leave_request
                                                    // re-checks this authoritatively (days_taken_this_year is
                                                    // ledger-derived server-side and may be more current).
                                                    // Carry-forward is a prior year's allowance, takeable on
                                                    // top of this year's cap, so raise the ceiling by it.
                                                    // (Quick hint only — validate_leave_request applies the
                                                    // precise date-aware CF cap server-side.)
                                                    if (dayCount > 0 &&
                                                        daysTakenThisYear + dayCount >
                                                            leavesEligibility + carryForwardBalance) {
                                                      return DropdownMenuEntry(
                                                        enabled: false,
                                                        value: LeaveType.annual,
                                                        label: AppLocalizations.of(context)!.annualCapReached,
                                                      );
                                                    }
                                                    // Rule 2.6b — the old `leaveBalance < dayCount` hard gate
                                                    // is intentionally NOT reinstated here: it would incorrectly
                                                    // block forward-planned requests that future monthly loads
                                                    // will cover by the requested dates (see worked examples in
                                                    // the plan). The option stays enabled; validate_leave_request
                                                    // runs the authoritative forward-projection check on submit,
                                                    // and negativeBalanceHint near the balance chips sets the
                                                    // expectation for employees currently in deficit.
                                                  }
                                                  if (leaveType == LeaveType.compensation) {
                                                    if (userState.user?.overtimeBalance == 0) {
                                                      return DropdownMenuEntry(
                                                        enabled: false,
                                                        value: LeaveType.compensation,
                                                        label: '${AppLocalizations.of(context)!.compensation} (0)',
                                                      );
                                                    }

                                                    final overTimeBalance = userState.user?.overtimeBalance ?? 0;
                                                    final dayCount = context.read<RequestLeaveBloc>().state.dayCount;

                                                    if (overTimeBalance < dayCount && dayCount > 0) {
                                                      return DropdownMenuEntry(
                                                        enabled: false,
                                                        value: LeaveType.compensation,
                                                        label:
                                                            AppLocalizations.of(context)!.compensationNotEnoughBalance,
                                                      );
                                                    }
                                                  }
                                                  // Disable sick leave if hours are selected
                                                  if (leaveType == LeaveType.sick &&
                                                      _leaveHoursController.text.isNotEmpty) {
                                                    return DropdownMenuEntry(
                                                      enabled: false,
                                                      value: LeaveType.sick,
                                                      label: AppLocalizations.of(context)!.sick,
                                                    );
                                                  }
                                                  // Disable unpaid leave if hours are selected
                                                  if (leaveType == LeaveType.unpaid &&
                                                      _leaveHoursController.text.isNotEmpty) {
                                                    return DropdownMenuEntry(
                                                      enabled: false,
                                                      value: LeaveType.unpaid,
                                                      label: LeaveType.unpaid.localizedLabel(context),
                                                    );
                                                  }
                                                  if (leaveType == LeaveType.unpaid &&
                                                      (userState.user!.leaveBalance! > 1 ||
                                                          userState.user!.overtimeBalance! > 1)) {
                                                    return DropdownMenuEntry(
                                                      enabled: false,
                                                      value: LeaveType.unpaid,
                                                      label: LeaveType.unpaid.localizedLabel(context),
                                                    );
                                                  }
                                                  return DropdownMenuEntry(
                                                    value: leaveType,
                                                    label: leaveType.localizedLabel(context),
                                                  );
                                                }).toList(),
                                            hintText: AppLocalizations.of(context)!.leaveType,
                                            controller: _leaveTypeController,
                                            onSelected: (value) async {
                                              _leaveTypeController.text = value!.localizedLabel(context);
                                              // Update the leaveType in the state
                                              context.read<RequestLeaveBloc>().add(UpdateLeaveType(value));
                                              context.read<RequestLeaveBloc>().add(
                                                ValidateForm(
                                                  fromDate: _fromDateController.text,
                                                  toDate: _toDateController.text,
                                                  leaveType: _leaveTypeController.text,
                                                  leaveHours:
                                                      _leaveHoursController.text.isNotEmpty
                                                          ? int.parse(_leaveHoursController.text.substring(0, 1))
                                                          : 0,
                                                  shiftHours: userState.user?.shiftHours,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 16),
                                      BlocBuilder<RequestLeaveBloc, RequestLeaveState>(
                                        key: TutorialKeys.leaveDayCount,
                                        builder: (context, state) {
                                          return Chip(
                                            padding: const EdgeInsets.all(8),
                                            labelStyle: TextStyle(fontSize: 16),
                                            label: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Text(
                                                state.dayCount < 1
                                                    ? '${AppLocalizations.of(context)!.youWillOff} ${(state.dayCount * shiftHours).toStringAsFixed(1)} ${AppLocalizations.of(context)!.hoursLabel}'
                                                    : '${AppLocalizations.of(context)!.youWillOff} ${state.dayCount} ${state.dayCount > 1 ? AppLocalizations.of(context)!.days : AppLocalizations.of(context)!.day}',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                      BlocConsumer<RequestLeaveBloc, RequestLeaveState>(
                                        listener: (context, state) {},
                                        builder: (context, state) {
                                          return Column(
                                            children: [
                                              if (state.leaveType == LeaveType.sick) ...[
                                                const SizedBox(height: 16),
                                                AppButton(
                                                  onPressed: () => _pickSickNotes(context),
                                                  label: AppLocalizations.of(context)!.upSicknote,
                                                ),
                                                if (state.sickNoteFileNames!.isNotEmpty)
                                                  Column(
                                                    children:
                                                        state.sickNoteFileNames!.map((name) => Text(name)).toList(),
                                                  ),
                                              ],
                                            ],
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 24),
                                      if (isEmergency && isEmergencyTooLong)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.emergencyMaxOneDay, // Add this key to your ARB files
                                            style: const TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      if (isEmergencyBalanceInsufficient)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.emergencyNotEnoughBalance, // Add this key to your ARB files
                                            style: const TextStyle(color: Colors.red),
                                          ),
                                        ),

                                      AppButton(
                                        key: TutorialKeys.leaveSubmit,
                                        width: submitButtonFactor * kMaxInputWidth + 16,
                                        label:
                                            state.isSubmitting
                                                ? AppLocalizations.of(context)!.submitting
                                                : AppLocalizations.of(context)!.submit,
                                        onPressed:
                                            state.isSubmitting ||
                                                    !state.isFormValid ||
                                                    (isEmergency && isEmergencyTooLong) ||
                                                    isEmergencyBalanceInsufficient
                                                ? null
                                                : () async {
                                                  await _submit(context);
                                                },

                                        color:
                                            state.isFormValid &&
                                                    !(isEmergency && isEmergencyTooLong) &&
                                                    !isEmergencyBalanceInsufficient
                                                ? Colors.blue
                                                : Colors.grey,
                                      ),
                                      if (state.status == Status.failure && state.failure?.message != null) ...[
                                        const SizedBox(height: 16),
                                        FormMessage(
                                          message: localizeLeaveError(
                                            AppLocalizations.of(context)!,
                                            state.failure!.message,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Loading overlay
                if (_isRefreshingProfile)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
