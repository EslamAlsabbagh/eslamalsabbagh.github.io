import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/constants/missingpunch_type.dart';
import 'package:hrms_demo/core/constants/request_constants.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/navigation_helper.dart';
import 'package:hrms_demo/data/models/missingpunching_request_model.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_state.dart';
import 'package:hrms_demo/presentation/request_missingpunching/bloc/request_missingpunching_bloc.dart';
import 'package:hrms_demo/presentation/request_missingpunching/bloc/request_missingpunching_event.dart';
import 'package:hrms_demo/presentation/request_missingpunching/bloc/request_missingpunching_state.dart';
import 'package:hrms_demo/presentation/request_missingpunching/widgets/request_missingpunching_page.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/app_text_field.dart';
import 'package:hrms_demo/presentation/widgets/custom_date_picker.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

final class RequestMissingpunchingContent extends StatefulWidget {
  RequestMissingpunchingContent({super.key});

  @override
  State<RequestMissingpunchingContent> createState() => _RequestMissingpunchingContentState();
}

class _RequestMissingpunchingContentState extends State<RequestMissingpunchingContent> {
  bool _isRefreshingProfile = false;

  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  // Source of truth for the submitted time; the controller only holds the
  // locale-formatted display text, which is not safe to parse back.
  TimeOfDay? _pickedTime;

  Future<void> _pickDate(
    BuildContext context,
    TextEditingController controller,
    DateTime? firstDate,
    DateTime? lastDate,
  ) async {
    // Get current state to access disabled dates
    final requestMissingpunchingState = context.read<RequestMissingpunchingBloc>().state;

    final picked = await showCustomDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty ? DateTime.parse(controller.text) : DateTime.now(),
      firstDate: firstDate ?? DateTime.now().subtract(const Duration(days: kRequestBackWindowDays)),
      lastDate: lastDate ?? DateTime.now(),
      disabledDates:
          requestMissingpunchingState.disabledDates
              // Business-trip days are intentionally allowed on a missing-punch day
              // (the overlap is surfaced to approvers, not blocked). Leaves and other
              // missing-punch days stay disabled.
              .where((info) => info.type != 'business_trip')
              .toList(),
    );

    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _submit(BuildContext context) async {
    final date = _dateController.text;
    final time = _pickedTime;

    context.read<RequestMissingpunchingBloc>().add(
      SubmitMissingPunchingRequest(
        MissingpunchingRequestModel(
          userId: (context.read<UserBloc>().state.user?.id ?? 0),
          date: date.isNotEmpty ? DateTime.parse(date) : null,
          // 1970-01-01 matches the placeholder date DateFormat.parse used to
          // produce, so the serialized payload is unchanged.
          time: time != null ? DateTime(1970, 1, 1, time.hour, time.minute) : null,
          type: context.read<RequestMissingpunchingBloc>().state.missingPunchType,
          n1Code: (context.read<UserBloc>().state.user?.n1 ?? 0),
          n2Code: (context.read<UserBloc>().state.user?.n2 ?? 0),
        ),
      ),
    );
  }

  Future<void> _pickTime(BuildContext context, TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _pickedTime ?? TimeOfDay.now(),
      initialEntryMode: TimePickerEntryMode.input,
    );

    if (picked != null) {
      _pickedTime = picked;
      if (context.mounted) {
        controller.text = picked.format(context);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Load existing missing punch requests when the widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userBloc = context.read<UserBloc>();
      final userId = userBloc.state.user?.id;
      if (userId != null) {
        context.read<RequestMissingpunchingBloc>().add(LoadExistingMissingpunchingRequests(userId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RequestMissingpunchingBloc, RequestMissingpunchingState>(
      listener: (context, state) {
        if (state.status == Status.success) {
          final userBloc = context.read<UserBloc>();
          final userId = userBloc.state.user?.id.toString();

          // Optimistic update so sidebar shows tile immediately
          userBloc.add(MarkRequestsAvailable(hasMissingPunchRequests: true));

          if (userId != null) {
            userBloc.add(LoadUserProfile(userId));
            // Navigation depends on updated balance from LoadUserProfile
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                setState(() {
                  _isRefreshingProfile = false;
                });
                if (context.read<UserBloc>().state.user!.missingPunchBalance! > 1) {
                  NavigationHelper.pushReplacementWithSidebarSync(
                    context,
                    routeName: '/missingpunch/new',
                    page: const RequestMissingpunchingPage(),
                  );
                } else {
                  Navigator.pop(context);
                }
              }
            });
          } else {
            setState(() {
              _isRefreshingProfile = false;
            });
            if (userBloc.state.user!.missingPunchBalance! > 1) {
              NavigationHelper.pushReplacementWithSidebarSync(
                context,
                routeName: '/missingpunch/new',
                page: const RequestMissingpunchingPage(),
              );
            } else {
              Navigator.pop(context);
            }
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.requestMissingPunchingSubmittedSuccessfully)),
          );
        }

        if (state.failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.failure?.message ?? '')));
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            MainLayout(
              title: AppLocalizations.of(context)!.requestMissingPunching,
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
                            BlocBuilder<UserBloc, UserState>(
                              builder: (context, userState) {
                                return Chip(
                                  label: Text(
                                    '${AppLocalizations.of(context)!.missingPunchBalance}: ${userState.user?.missingPunchBalance ?? 0}',
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap:
                                      state.disabledDatesLoaded
                                          ? () async {
                                            await _pickDate(context, _dateController, null, null);

                                            context.read<RequestMissingpunchingBloc>().add(
                                              ValidateForm(date: _dateController.text, time: _timeController.text),
                                            );
                                          }
                                          : null,
                                  child: AbsorbPointer(
                                    child: AppTextField(
                                      width: context.maxInputWidth,
                                      label: AppLocalizations.of(context)!.date,
                                      autofocus: false,
                                      controller: _dateController,
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
                                    await _pickTime(context, _timeController);

                                    context.read<RequestMissingpunchingBloc>().add(
                                      ValidateForm(date: _dateController.text, time: _timeController.text),
                                    );
                                  },
                                  child: AbsorbPointer(
                                    child: AppTextField(
                                      width: context.maxInputWidth,
                                      label: AppLocalizations.of(context)!.time,
                                      autofocus: false,
                                      controller: _timeController,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: context.maxInputWidth * 0.5,
                                  child: RadioListTile<String>(
                                    title: Text(AppLocalizations.of(context)!.inType),
                                    value: MissingPunchType.inType.label,
                                    groupValue: state.missingPunchType,
                                    onChanged: (value) {
                                      context.read<RequestMissingpunchingBloc>().add(ChangeMissingPunchType(value!));
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: context.maxInputWidth * 0.5,
                                  child: RadioListTile<String>(
                                    title: Text(AppLocalizations.of(context)!.outType),
                                    value: MissingPunchType.outType.label,
                                    groupValue: state.missingPunchType,
                                    onChanged: (value) {
                                      context.read<RequestMissingpunchingBloc>().add(ChangeMissingPunchType(value!));
                                    },
                                  ),
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
