import 'package:hrms_demo/core/constants/business_trips.dart';
import 'package:hrms_demo/core/constants/request_constants.dart';
import 'package:hrms_demo/core/constants/sizes.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/navigation_helper.dart';
import 'package:hrms_demo/data/models/businesstrip_request_model.dart';
import 'package:hrms_demo/data/models/disabled_date_info.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_state.dart';
import 'package:hrms_demo/presentation/request_businesstrip/bloc/request_businesstrip_bloc.dart';
import 'package:hrms_demo/presentation/request_businesstrip/bloc/request_businesstrip_event.dart';
import 'package:hrms_demo/presentation/request_businesstrip/bloc/request_businesstrip_state.dart';
import 'package:hrms_demo/presentation/request_businesstrip/widgets/request_businesstrip_page.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/app_text_field.dart';
import 'package:hrms_demo/presentation/widgets/custom_date_picker.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

final class RequestBusinesstripContent extends StatefulWidget {
  const RequestBusinesstripContent({super.key});

  @override
  State<RequestBusinesstripContent> createState() => _RequestBusinesstripContentState();
}

class _RequestBusinesstripContentState extends State<RequestBusinesstripContent> {
  bool _isRefreshingProfile = false;
  int? _selectedHours;

  final TextEditingController _dateFromController = TextEditingController();
  final TextEditingController _dateToController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _otherLocationController = TextEditingController();
  final TextEditingController _feeAmountController = TextEditingController();

  /// Filters out missing_punch entries from disabled dates, since
  /// business trip is allowed on days with missing punch (with hours constraint).
  List<DisabledDateInfo> _getEffectiveDisabledDates(List<DisabledDateInfo> dates) {
    return dates.where((info) => info.type != 'missing_punch').toList();
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
    final requestBusinesstripState = context.read<RequestBusinesstripBloc>().state;
    final picked = await showCustomDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty ? DateTime.parse(controller.text) : DateTime.now(),
      firstDate: firstDate ?? DateTime.now().subtract(const Duration(days: kRequestBackWindowDays)),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
      disabledDates: _getEffectiveDisabledDates(requestBusinesstripState.disabledDates),
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  String _getEnglishLocationLabel(BuildContext context, String localizedText) {
    // Convert localized text back to English label for API submission
    for (BusinessTrips trip in BusinessTrips.values) {
      if (trip.localizedLabel(context) == localizedText) {
        return trip.label;
      }
    }
    // If no match found, return the text as-is (for "other" custom location)
    return localizedText;
  }

  Future<void> _submit(BuildContext context) async {
    final dateFrom = _dateFromController.text;
    final dateTo = _dateToController.text;
    final localizedLocation = _locationController.text;
    final location = _getEnglishLocationLabel(context, localizedLocation);
    final state = context.read<RequestBusinesstripBloc>().state;

    context.read<RequestBusinesstripBloc>().add(
      SubmitBusinesstripRequest(
        BusinesstripRequestModel(
          userId: (context.read<UserBloc>().state.user?.id ?? 0),
          dateFrom: dateFrom.isNotEmpty ? DateTime.parse(dateFrom) : null,
          dateTo: dateTo.isNotEmpty ? DateTime.parse(dateTo) : null,
          location: location,
          numberOfHours: state.numberOfHours,
          amPm: state.amPm,
          n1Code: (context.read<UserBloc>().state.user?.n1 ?? 0),
          n2Code: (context.read<UserBloc>().state.user?.n2 ?? 0),
          transportationFeeRequested: state.feeRequested,
          transportationFeeAmount: state.feeRequested ? state.feeAmount : null,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Load existing business trip requests when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userBloc = context.read<UserBloc>();
      final userId = userBloc.state.user?.id;
      if (userId != null) {
        context.read<RequestBusinesstripBloc>().add(LoadExistingBusinesstripRequests(userId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RequestBusinesstripBloc, RequestBusinesstripState>(
      listener: (context, state) {
        if (state.status == Status.success) {
          final userBloc = context.read<UserBloc>();
          final userId = userBloc.state.user?.id.toString();

          userBloc.add(MarkRequestsAvailable(hasBusinessTripRequests: true));
          if (userId != null) {
            userBloc.add(LoadUserProfile(userId));
          }

          setState(() {
            _isRefreshingProfile = false;
          });

          NavigationHelper.pushReplacementWithSidebarSync(
            context,
            routeName: '/businesstrip/new',
            page: const RequestBusinesstripPage(),
          );

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.businessTripSubmittedSuccessfully)));
        }

        if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.failure?.message ?? '')));
        }
      },
      builder: (context, state) {
        final wrappedFieldsSize = context.screenWidth < 600 ? kMaxInputWidth * 0.5 : context.maxInputWidth * 0.5 - 8;

        final unWrappedFieldsSize = context.screenWidth > 600 ? wrappedFieldsSize * 2 + 16 : wrappedFieldsSize;
        return Stack(
          children: [
            MainLayout(
              title: AppLocalizations.of(context)!.requestBusinesstrip,
              child: Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(minWidth: context.screenWidth * 0.8),
                        child: Align(
                          alignment: context.screenWidth < 500 ? Alignment.centerLeft : Alignment.center,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Wrap(
                                    spacing: 16,
                                    runSpacing: 16,
                                    alignment: WrapAlignment.center,
                                    children: [
                                      GestureDetector(
                                        onTap:
                                            state.disabledDatesLoaded
                                                ? () async {
                                                  // Calculate smart minimum date based on disabled dates
                                                  DateTime? smartMinDate;
                                                  DateTime? smartMaxDate;

                                                  if (_dateToController.text.isNotEmpty) {
                                                    final toDate = DateTime.parse(_dateToController.text);
                                                    final requestBusinesstripState =
                                                        context.read<RequestBusinesstripBloc>().state;

                                                    // Get the smart minimum from date
                                                    smartMinDate = _getEarliestAllowedFromDate(
                                                      toDate,
                                                      _getEffectiveDisabledDates(
                                                        requestBusinesstripState.disabledDates,
                                                      ),
                                                    );

                                                    // Max is the selected "to date"
                                                    smartMaxDate = toDate;
                                                  }

                                                  await _pickDate(
                                                    context,
                                                    _dateFromController,
                                                    smartMinDate,
                                                    smartMaxDate,
                                                  );

                                                  context.read<RequestBusinesstripBloc>().add(
                                                    ValidateForm(
                                                      dateFrom: _dateFromController.text,
                                                      dateTo: _dateToController.text,
                                                      location: _locationController.text,
                                                      numberOfDays: state.numberOfDays,
                                                    ),
                                                  );
                                                }
                                                : null,
                                        child: AbsorbPointer(
                                          child: AppTextField(
                                            width: wrappedFieldsSize,
                                            label: AppLocalizations.of(context)!.dateFrom,
                                            autofocus: false,
                                            controller: _dateFromController,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap:
                                            state.disabledDatesLoaded
                                                ? () async {
                                                  // Calculate smart maximum date based on disabled dates
                                                  DateTime? smartMinDate;
                                                  DateTime? smartMaxDate;

                                                  if (_dateFromController.text.isNotEmpty) {
                                                    final fromDate = DateTime.parse(_dateFromController.text);
                                                    final requestBusinesstripState =
                                                        context.read<RequestBusinesstripBloc>().state;

                                                    // Min is the selected "from date"
                                                    smartMinDate = fromDate;

                                                    // Get the smart maximum to date
                                                    smartMaxDate = _getLatestAllowedToDate(
                                                      fromDate,
                                                      _getEffectiveDisabledDates(
                                                        requestBusinesstripState.disabledDates,
                                                      ),
                                                    );
                                                  }

                                                  await _pickDate(
                                                    context,
                                                    _dateToController,
                                                    smartMinDate,
                                                    smartMaxDate,
                                                  );

                                                  context.read<RequestBusinesstripBloc>().add(
                                                    ValidateForm(
                                                      dateFrom: _dateFromController.text,
                                                      dateTo: _dateToController.text,
                                                      location: _locationController.text,
                                                      numberOfDays: state.numberOfDays,
                                                    ),
                                                  );
                                                }
                                                : null,
                                        child: AbsorbPointer(
                                          child: AppTextField(
                                            width: wrappedFieldsSize,
                                            label: AppLocalizations.of(context)!.dateTo,
                                            autofocus: false,
                                            controller: _dateToController,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Column(
                                    children: [
                                      DropdownMenu<BusinessTrips>(
                                        width: unWrappedFieldsSize,
                                        dropdownMenuEntries: [
                                          DropdownMenuEntry(
                                            label: AppLocalizations.of(context)!.riverside,
                                            value: BusinessTrips.riverside,
                                          ),
                                          DropdownMenuEntry(
                                            label: AppLocalizations.of(context)!.riversidePark,
                                            value: BusinessTrips.riversidePark,
                                          ),
                                          DropdownMenuEntry(
                                            label: AppLocalizations.of(context)!.northSquare,
                                            value: BusinessTrips.north,
                                          ),
                                          DropdownMenuEntry(
                                            label: AppLocalizations.of(context)!.other,
                                            value: BusinessTrips.other,
                                          ),
                                        ],
                                        hintText: AppLocalizations.of(context)!.location,
                                        controller: _locationController,
                                        onSelected: (value) {
                                          // Set the localized label in the controller
                                          _locationController.text = value!.localizedLabel(context);

                                          // Indicate whether this location is
                                          // eligible for transportation fees.
                                          context.read<RequestBusinesstripBloc>().add(
                                            SetLocationTransportationFee(
                                              locationDeservesTransportationFees(value.label),
                                            ),
                                          );

                                          if (value == BusinessTrips.other) {
                                            context.read<RequestBusinesstripBloc>().add(SetOtherLocation(true));
                                          } else {
                                            context.read<RequestBusinesstripBloc>().add(SetOtherLocation(false));
                                            context.read<RequestBusinesstripBloc>().add(
                                              ValidateForm(
                                                dateFrom: _dateFromController.text,
                                                dateTo: _dateToController.text,
                                                location: _locationController.text,
                                                numberOfDays: state.numberOfDays,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                      // If the location is "Other", show the text field
                                      BlocBuilder<RequestBusinesstripBloc, RequestBusinesstripState>(
                                        builder: (context, state) {
                                          return Column(
                                            children: [
                                              if (state.locationDeservesFee) ...[
                                                _buildTransportationFeeNote(context, unWrappedFieldsSize),
                                                const SizedBox(height: 16),
                                              ],
                                              if (state.other) ...[
                                                AppTextField(
                                                  width: unWrappedFieldsSize,
                                                  autofocus: true,
                                                  label: "",
                                                  hint: AppLocalizations.of(context)!.enterLocation,
                                                  controller: _otherLocationController,
                                                  onChanged: (value) {
                                                    context.read<RequestBusinesstripBloc>().add(
                                                      ValidateForm(
                                                        dateFrom: _dateFromController.text,
                                                        dateTo: _dateToController.text,
                                                        location: value,
                                                        numberOfDays: state.numberOfDays,
                                                      ),
                                                    );
                                                    // A custom-typed location may
                                                    // also be fee-eligible.
                                                    context.read<RequestBusinesstripBloc>().add(
                                                      SetLocationTransportationFee(
                                                        locationDeservesTransportationFees(value),
                                                      ),
                                                    );
                                                    _locationController.text = _otherLocationController.text;
                                                  },
                                                ),
                                                const SizedBox(height: 16),
                                              ],

                                              // Manual transportation fee request — hidden for
                                              // locations with a fixed, known fee (e.g. North
                                              // Square), which are auto-eligible instead.
                                              if (!state.locationDeservesFee) ...[
                                                _buildTransportationFeeRequest(context, state, unWrappedFieldsSize),
                                                const SizedBox(height: 16),
                                              ],

                                              // Show hour fields only for single day requests
                                              if (state.showHourFields) ...[
                                                // Hours dropdown
                                                BlocBuilder<UserBloc, UserState>(
                                                  builder: (context, userState) {
                                                    final shiftHours = userState.user?.shiftHours ?? 8;
                                                    return SizedBox(
                                                      width: unWrappedFieldsSize,
                                                      child: DropdownButtonFormField<int>(
                                                        value: _selectedHours,
                                                        decoration: InputDecoration(
                                                          labelText: AppLocalizations.of(context)!.numberOfHours,
                                                          border: OutlineInputBorder(
                                                            borderRadius: BorderRadius.circular(4),
                                                          ),
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

                                                                      context.read<RequestBusinesstripBloc>().add(
                                                                        SetNumberOfHours(null),
                                                                      );

                                                                      // Reset AM/PM selection
                                                                      context.read<RequestBusinesstripBloc>().add(
                                                                        SetAmPm(null),
                                                                      );

                                                                      // Trigger form validation
                                                                      context.read<RequestBusinesstripBloc>().add(
                                                                        ValidateForm(
                                                                          dateFrom: _dateFromController.text,
                                                                          dateTo: _dateToController.text,
                                                                          location: _locationController.text,
                                                                          numberOfDays:
                                                                              context
                                                                                  .read<RequestBusinesstripBloc>()
                                                                                  .state
                                                                                  .numberOfDays,
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
                                                            child: Text((index + 1).toString()),
                                                          ),
                                                        ),
                                                        onChanged: (value) {
                                                          setState(() {
                                                            _selectedHours = value;
                                                          });

                                                          context.read<RequestBusinesstripBloc>().add(
                                                            SetNumberOfHours(value),
                                                          );

                                                          // Trigger form validation
                                                          context.read<RequestBusinesstripBloc>().add(
                                                            ValidateForm(
                                                              dateFrom: _dateFromController.text,
                                                              dateTo: _dateToController.text,
                                                              location: _locationController.text,
                                                              numberOfDays:
                                                                  context
                                                                      .read<RequestBusinesstripBloc>()
                                                                      .state
                                                                      .numberOfDays,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                ),
                                                const SizedBox(height: 16),

                                                // AM/PM radio buttons - only show when hours is selected
                                                if (state.numberOfHours != null && _selectedHours != null) ...[
                                                  Wrap(
                                                    alignment: WrapAlignment.center,
                                                    children: [
                                                      SizedBox(
                                                        width: wrappedFieldsSize,
                                                        child: RadioListTile<String>(
                                                          title: Text(AppLocalizations.of(context)!.morning),
                                                          value: 'AM',
                                                          groupValue: state.amPm,
                                                          onChanged: (value) {
                                                            context.read<RequestBusinesstripBloc>().add(SetAmPm(value));
                                                            // Trigger form validation
                                                            context.read<RequestBusinesstripBloc>().add(
                                                              ValidateForm(
                                                                dateFrom: _dateFromController.text,
                                                                dateTo: _dateToController.text,
                                                                location: _locationController.text,
                                                                numberOfDays:
                                                                    context
                                                                        .read<RequestBusinesstripBloc>()
                                                                        .state
                                                                        .numberOfDays,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),

                                                      //const SizedBox(width: 20),
                                                      SizedBox(
                                                        width: wrappedFieldsSize,
                                                        child: RadioListTile<String>(
                                                          title: Text(AppLocalizations.of(context)!.evening),
                                                          value: 'PM',
                                                          groupValue: state.amPm,
                                                          onChanged: (value) {
                                                            context.read<RequestBusinesstripBloc>().add(SetAmPm(value));
                                                            // Trigger form validation
                                                            context.read<RequestBusinesstripBloc>().add(
                                                              ValidateForm(
                                                                dateFrom: _dateFromController.text,
                                                                dateTo: _dateToController.text,
                                                                location: _locationController.text,
                                                                numberOfDays:
                                                                    context
                                                                        .read<RequestBusinesstripBloc>()
                                                                        .state
                                                                        .numberOfDays,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 16),
                                                ],
                                              ],

                                              BlocBuilder<UserBloc, UserState>(
                                                builder: (context, userState) {
                                                  final shiftHours = userState.user?.shiftHours ?? 8;

                                                  // Display hours if hours are selected and less than a full day
                                                  final shouldDisplayHours =
                                                      state.numberOfHours != null &&
                                                      _selectedHours != null &&
                                                      state.numberOfHours! < shiftHours;

                                                  return Chip(
                                                    label: Text(
                                                      shouldDisplayHours
                                                          ? '${AppLocalizations.of(context)!.numberOfHours}: ${state.numberOfHours} ${state.numberOfHours! > 1 ? AppLocalizations.of(context)!.hoursLabel : AppLocalizations.of(context)!.hourLabel}'
                                                          : '${AppLocalizations.of(context)!.numberOfDays}: ${state.numberOfDays}',
                                                    ),
                                                  );
                                                },
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  AppButton(
                                    label:
                                        state.isSubmitting
                                            ? AppLocalizations.of(context)!.submitting
                                            : AppLocalizations.of(context)!.submit,
                                    onPressed:
                                        state.isSubmitting || !state.isFormValid
                                            ? null
                                            : () async {
                                              await _submit(context);
                                            },
                                    color: state.isFormValid ? Colors.blue : Colors.grey,
                                  ),
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
  }

  /// Checkbox letting the employee request a transportation fee, plus an amount
  /// field shown when checked. Independent of location-based eligibility.
  Widget _buildTransportationFeeRequest(BuildContext context, RequestBusinesstripState state, double width) {
    final l10n = AppLocalizations.of(context)!;
    // Keep the controller text in sync with state (e.g. when cleared on toggle-off).
    final currentText = state.feeAmount != null ? _formatAmount(state.feeAmount!) : '';
    if (_feeAmountController.text != currentText && !state.feeRequested) {
      _feeAmountController.text = currentText;
    }

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            value: state.feeRequested,
            title: Text(l10n.requestTransportationFees),
            onChanged: (value) {
              final requested = value ?? false;
              if (!requested) {
                _feeAmountController.clear();
              }
              context.read<RequestBusinesstripBloc>().add(SetRequestTransportationFee(requested));
            },
          ),
          if (state.feeRequested) ...[
            const SizedBox(height: 8),
            AppTextField(
              width: width,
              autofocus: false,
              controller: _feeAmountController,
              label: l10n.transportationFeeAmount,
              hint: l10n.egp,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              onChanged: (value) {
                final amount = double.tryParse(value.trim());
                context.read<RequestBusinesstripBloc>().add(SetTransportationFeeAmount(amount));
              },
            ),
          ],
        ],
      ),
    );
  }

  /// Formats a fee amount for display, dropping a trailing ".0".
  String _formatAmount(double amount) {
    return amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toString();
  }

  /// Info banner shown under the location field when the selected location is
  /// eligible for transportation fees.
  Widget _buildTransportationFeeNote(BuildContext context, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.blue.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.transportationFeesEligible,
              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
