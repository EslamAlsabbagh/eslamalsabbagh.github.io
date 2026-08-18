import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/core/utils/navigation_helper.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/hr_letter/bloc/hr_letter_bloc.dart';
import 'package:hrms_demo/presentation/hr_letter/bloc/hr_letter_event.dart';
import 'package:hrms_demo/presentation/hr_letter/bloc/hr_letter_state.dart';
import 'package:hrms_demo/presentation/hr_letter/widgets/hr_letter_page.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/custom_date_picker.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class HrLetterContent extends StatefulWidget {
  const HrLetterContent({super.key});

  @override
  State<HrLetterContent> createState() => _HrLetterContentState();
}

class _HrLetterContentState extends State<HrLetterContent> {
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<HrLetterBloc>().add(InitializeHrLetterForm());
  }

  @override
  void dispose() {
    _nationalIdController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      child: Align(
        alignment: Alignment.topLeft,
        child: SingleChildScrollView(
          child: BlocListener<HrLetterBloc, HrLetterState>(
            listener: (context, state) {
              if (state is HrLetterFormState) {
                if (state.isSubmissionSuccessful) {
                  final userBloc = context.read<UserBloc>();
                  final userId = userBloc.state.user?.id.toString();

                  userBloc.add(MarkRequestsAvailable(hasHrLetterRequests: true));
                  if (userId != null) {
                    userBloc.add(LoadUserProfile(userId));
                  }

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.hrLetterSubmittedSuccessfully)));
                  NavigationHelper.pushReplacementWithSidebarSync(
                    context,
                    routeName: '/hr-letter/new',
                    page: const HrLetterPage(),
                  );
                } else if (state.submissionError != null) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: ${state.submissionError}')));
                }
              }
            },
            child: BlocBuilder<HrLetterBloc, HrLetterState>(
              builder: (context, state) {
                if (state is HrLetterLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is HrLetterError) {
                  return Center(child: Text(state.message, style: TextStyle(color: Colors.red[600])));
                }
                if (state is HrLetterFormState) {
                  // Sync national ID controller on first load
                  if (_nationalIdController.text != state.nationalId && !state.isSubmitting) {
                    _nationalIdController.text = state.nationalId;
                  }
                  return _buildFormContent(context, state);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context, HrLetterFormState state) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: context.screenWidth < 600 ? 600 : context.screenWidth - 65,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Icon(Icons.article_outlined, color: Theme.of(context).primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context)!.hrLetterRequest,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              if (!state.isEligible) ...[
                _buildIneligibleBanner(context),
              ] else ...[
                _buildNationalIdField(context, state),
                const SizedBox(height: 16),
                _buildLetterPurposeField(context, state),
                const SizedBox(height: 16),
                if (state.letterPurpose == 'embassy') ...[
                  _buildTravelFromDateField(context, state),
                  const SizedBox(height: 16),
                  _buildTravelToDateField(context, state),
                  const SizedBox(height: 16),
                ],
                _buildDetailsField(context, state),
                const SizedBox(height: 24),
                SizedBox(
                  width: context.screenWidth < 600 ? context.screenWidth - 81 : context.screenWidth - 65,
                  child: AppButton(
                    label:
                        state.isSubmitting
                            ? AppLocalizations.of(context)!.submitting
                            : AppLocalizations.of(context)!.submit,
                    onPressed: state.isSubmitting ? null : () => _onSubmit(context, state),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIneligibleBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber[300]!, width: 1.5),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber[700], size: 48),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.notEligibleForHrLetter,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber[800]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.tenureLessThanThreeMonths,
            style: TextStyle(fontSize: 14, color: Colors.amber[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNationalIdField(BuildContext context, HrLetterFormState state) {
    final hasError = state.validationErrors.containsKey('nationalId');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${AppLocalizations.of(context)!.nationalId} *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasError ? Colors.red : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nationalIdController,
          keyboardType: TextInputType.number,
          readOnly: state.isNationalIdFromDb,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.nationalId,
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            filled: state.isNationalIdFromDb,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
                width: hasError ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hasError ? Colors.red : Theme.of(context).primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          onChanged: (value) {
            context.read<HrLetterBloc>().add(UpdateNationalId(value));
          },
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              AppLocalizations.of(context)!.hrLetterNationalIdRequired,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildLetterPurposeField(BuildContext context, HrLetterFormState state) {
    final hasError = state.validationErrors.containsKey('letterPurpose');
    final l10n = AppLocalizations.of(context)!;

    final purposeOptions = [
      DropdownMenuItem(value: 'bank', child: Text(l10n.letterPurposeBank)),
      DropdownMenuItem(value: 'embassy', child: Text(l10n.letterPurposeEmbassy)),
      DropdownMenuItem(value: 'other', child: Text(l10n.letterPurposeOther)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.letterPurpose} *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasError ? Colors.red : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: state.letterPurpose,
          items: purposeOptions,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.description_outlined, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
                width: hasError ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hasError ? Colors.red : Theme.of(context).primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          onChanged: (value) {
            if (value != null) {
              context.read<HrLetterBloc>().add(UpdateLetterPurpose(value));
            }
          },
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              AppLocalizations.of(context)!.hrLetterPurposeRequired,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildTravelFromDateField(BuildContext context, HrLetterFormState state) {
    final hasError = state.validationErrors.containsKey('travelFromDate');
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.travelFromDate} *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasError ? Colors.red : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        _buildDateTapField(
          context: context,
          value: state.travelFromDate,
          hasError: hasError,
          icon: Icons.flight_takeoff_outlined,
          onTap: () async {
            final bloc = context.read<HrLetterBloc>();
            final now = DateTime.now();
            final picked = await showCustomDatePicker(
              context: context,
              initialDate: state.travelFromDate ?? now,
              firstDate: now,
              lastDate: DateTime(now.year + 3),
            );
            if (picked != null) {
              bloc.add(UpdateTravelFromDate(picked));
            }
          },
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(l10n.hrLetterTravelFromRequired, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  Widget _buildTravelToDateField(BuildContext context, HrLetterFormState state) {
    final hasError = state.validationErrors.containsKey('travelToDate');
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.travelToDate} *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasError ? Colors.red : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        _buildDateTapField(
          context: context,
          value: state.travelToDate,
          hasError: hasError,
          icon: Icons.flight_land_outlined,
          onTap: () async {
            final bloc = context.read<HrLetterBloc>();
            final now = DateTime.now();
            final firstDate = state.travelFromDate ?? now;
            final picked = await showCustomDatePicker(
              context: context,
              initialDate: state.travelToDate ?? firstDate,
              firstDate: firstDate,
              lastDate: DateTime(now.year + 3),
            );
            if (picked != null) {
              bloc.add(UpdateTravelToDate(picked));
            }
          },
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              state.validationErrors['travelToDate'] == 'after_from'
                  ? l10n.hrLetterTravelToAfterFrom
                  : l10n.hrLetterTravelToRequired,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  /// Reusable tappable date display field.
  Widget _buildDateTapField({
    required BuildContext context,
    required DateTime? value,
    required bool hasError,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
            width: hasError ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              value != null ? DateFormat('dd/MM/yyyy').format(value) : AppLocalizations.of(context)!.selectDate,
              style: TextStyle(fontSize: 14, color: value != null ? Colors.black87 : Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsField(BuildContext context, HrLetterFormState state) {
    final l10n = AppLocalizations.of(context)!;
    final hasError = state.validationErrors.containsKey('details');
    final isRequired = state.letterPurpose == 'other';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isRequired ? '${l10n.hrLetterDetails} *' : l10n.hrLetterDetails,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: hasError ? Colors.red : Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _detailsController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: l10n.hrLetterDetailsHint,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: hasError ? Colors.red : Colors.grey.withValues(alpha: 0.3),
                width: hasError ? 2 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: hasError ? Colors.red : Theme.of(context).primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
          onChanged: (value) {
            context.read<HrLetterBloc>().add(UpdateDetails(value));
          },
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(l10n.hrLetterDetailsRequired, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
      ],
    );
  }

  void _onSubmit(BuildContext context, HrLetterFormState state) {
    context.read<HrLetterBloc>().add(SubmitHrLetterRequest());
  }
}
