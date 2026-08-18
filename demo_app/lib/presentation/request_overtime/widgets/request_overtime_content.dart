import 'package:hrms_demo/core/constants/overtime_type.dart';
import 'package:hrms_demo/core/constants/request_constants.dart';
import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/navigation_helper.dart';
import 'package:hrms_demo/data/models/overtime_request_model.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:hrms_demo/presentation/request_overtime/bloc/request_overtime_bloc.dart';
import 'package:hrms_demo/presentation/request_overtime/bloc/request_overtime_event.dart';
import 'package:hrms_demo/presentation/request_overtime/bloc/request_overtime_state.dart';
import 'package:hrms_demo/presentation/request_overtime/request_overtime_page.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/app_text_field.dart';
import 'package:hrms_demo/presentation/widgets/custom_date_picker.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';

final class RequestOvertimeContent extends StatefulWidget {
  RequestOvertimeContent({super.key});

  @override
  State<RequestOvertimeContent> createState() => _RequestOvertimeContentState();
}

class _RequestOvertimeContentState extends State<RequestOvertimeContent> {
  bool _isRefreshingProfile = false;

  final TextEditingController _DateController = TextEditingController();
  final TextEditingController _timeFromController = TextEditingController();
  final TextEditingController _timeToController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  // Source of truth for the submitted times; the controllers only hold the
  // locale-formatted display text, which is not safe to parse back.
  TimeOfDay? _pickedTimeFrom;
  TimeOfDay? _pickedTimeTo;

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller,
    DateTime? firstDate,
    DateTime? lastDate,
  ) async {
    final picked = await showCustomDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty ? DateTime.parse(controller.text) : DateTime.now(),
      firstDate: firstDate ?? DateTime.now().subtract(const Duration(days: kRequestBackWindowDays)),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 7)),
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _submit(BuildContext context) async {
    final date = _DateController.text;
    final timeFrom = _pickedTimeFrom;
    final timeTo = _pickedTimeTo;
    final reason = _reasonController.text;

    context.read<RequestOvertimeBloc>().add(
      SubmitOvertimeRequest(
        OvertimeRequestModel(
          userId: (context.read<UserBloc>().state.user?.id ?? 0),
          date: date.isNotEmpty ? DateTime.parse(date) : null,
          // 1970-01-01 matches the placeholder date DateFormat.parse used to
          // produce, so the serialized payload is unchanged.
          timeFrom: timeFrom != null ? DateTime(1970, 1, 1, timeFrom.hour, timeFrom.minute) : null,
          timeTo: timeTo != null ? DateTime(1970, 1, 1, timeTo.hour, timeTo.minute) : null,
          n1Code: (context.read<UserBloc>().state.user?.n1 ?? 0),
          n2Code: (context.read<UserBloc>().state.user?.n2 ?? 0),
          reason: reason,
          overtimeType: context.read<RequestOvertimeBloc>().state.overtimeType.name,
          numberOfHours: context.read<RequestOvertimeBloc>().state.numOfHours.toDouble(),
        ),
      ),
    );
  }

  Future<TimeOfDay?> _pickTime(BuildContext context, TextEditingController controller, TimeOfDay? currentTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (picked != null && context.mounted) {
      controller.text = picked.format(context);
    }
    return picked;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RequestOvertimeBloc, RequestOvertimeState>(
      listener: (context, state) {
        if (state.status == Status.success) {
          final userBloc = context.read<UserBloc>();
          final userId = userBloc.state.user?.id.toString();

          userBloc.add(MarkRequestsAvailable(hasOvertimeRequests: true));
          if (userId != null) {
            userBloc.add(LoadUserProfile(userId));
          }

          setState(() {
            _isRefreshingProfile = false;
          });

          NavigationHelper.pushReplacementWithSidebarSync(
            context,
            routeName: '/overtime/new',
            page: const RequestOvertimePage(),
          );

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.oRSubmittedSuccessfully)));
        }

        if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.failure?.message ?? '')));
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            MainLayout(
              title: AppLocalizations.of(context)!.requestOvertime,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: context.screenWidth * 0.8),
                  child: Align(
                    alignment: context.screenWidth < 500 ? Alignment.centerLeft : Alignment.center,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    await _pickDate(context, _DateController, null, null);

                                    context.read<RequestOvertimeBloc>().add(
                                      ValidateForm(
                                        date: _DateController.text,
                                        fromTime: _timeFromController.text,
                                        toTime: _timeToController.text,
                                        reason: _reasonController.text,
                                      ),
                                    );
                                  },
                                  child: AbsorbPointer(
                                    child: AppTextField(
                                      width: context.maxInputWidth,
                                      label: AppLocalizations.of(context)!.date,
                                      autofocus: false,
                                      controller: _DateController,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () async {
                                    _pickedTimeFrom =
                                        await _pickTime(context, _timeFromController, _pickedTimeFrom) ??
                                        _pickedTimeFrom;

                                    context.read<RequestOvertimeBloc>().add(
                                      ValidateForm(
                                        date: _DateController.text,
                                        fromTime: _timeFromController.text,
                                        toTime: _timeToController.text,
                                        reason: _reasonController.text,
                                      ),
                                    );
                                  },
                                  child: AbsorbPointer(
                                    child: AppTextField(
                                      width: context.maxInputWidth * 0.5,
                                      label: AppLocalizations.of(context)!.timeFrom,
                                      autofocus: false,
                                      controller: _timeFromController,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () async {
                                    _pickedTimeTo =
                                        await _pickTime(context, _timeToController, _pickedTimeTo) ?? _pickedTimeTo;

                                    context.read<RequestOvertimeBloc>().add(
                                      ValidateForm(
                                        date: _DateController.text,
                                        fromTime: _timeFromController.text,
                                        toTime: _timeToController.text,
                                        reason: _reasonController.text,
                                      ),
                                    );
                                  },
                                  child: AbsorbPointer(
                                    child: AppTextField(
                                      width: context.maxInputWidth * 0.5,
                                      label: AppLocalizations.of(context)!.timeTo,
                                      autofocus: false,
                                      controller: _timeToController,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: context.maxInputWidth * 0.5,
                                  child: RadioListTile<OvertimeType>(
                                    title: Text(AppLocalizations.of(context)!.holidays),
                                    value: OvertimeType.holidays,
                                    groupValue: state.overtimeType,
                                    onChanged: (value) {
                                      context.read<RequestOvertimeBloc>().add(ChangeOvertimeType(value!));
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: context.maxInputWidth * 0.5,
                                  child: RadioListTile<OvertimeType>(
                                    title: Text(AppLocalizations.of(context)!.other),
                                    value: OvertimeType.other,
                                    groupValue: state.overtimeType,
                                    onChanged: (value) {
                                      context.read<RequestOvertimeBloc>().add(ChangeOvertimeType(value!));
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              width: context.maxInputWidth,
                              label: AppLocalizations.of(context)!.reason,
                              autofocus: false,
                              controller: _reasonController,
                              isReasonField: true,
                              onChanged: (value) {
                                context.read<RequestOvertimeBloc>().add(
                                  ValidateForm(
                                    date: _DateController.text,
                                    fromTime: _timeFromController.text,
                                    toTime: _timeToController.text,
                                    reason: _reasonController.text,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            BlocBuilder<RequestOvertimeBloc, RequestOvertimeState>(
                              builder: (context, state) {
                                final compensatedHours =
                                    state.overtimeType == OvertimeType.holidays
                                        ? double.parse(state.numOfHours.toStringAsFixed(2)) * 2
                                        : double.parse(state.numOfHours.toStringAsFixed(2)) * 1.5;
                                return Row(
                                  children: [
                                    Chip(
                                      padding: const EdgeInsets.all(8),
                                      labelStyle: TextStyle(fontSize: 18),
                                      label: Text(
                                        '${AppLocalizations.of(context)!.numOfHours}: ${state.numOfHours.toStringAsFixed(2)}',
                                      ),
                                    ),
                                    Chip(
                                      padding: const EdgeInsets.all(8),
                                      labelStyle: TextStyle(fontSize: 18),
                                      label: Text(
                                        '${AppLocalizations.of(context)!.compensatedHours}: ${compensatedHours.toStringAsFixed(2)}',
                                      ),
                                    ),
                                  ],
                                );
                              },
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
}
