import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/hr_tools/bloc/hr_tools_bloc.dart';
import 'package:hrms_demo/presentation/hr_tools/bloc/hr_tools_event.dart';
import 'package:hrms_demo/presentation/hr_tools/bloc/hr_tools_state.dart';
import 'package:hrms_demo/presentation/shared/form_styling.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BulkOvertimeTab extends StatefulWidget {
  const BulkOvertimeTab({super.key});

  @override
  State<BulkOvertimeTab> createState() => _BulkOvertimeTabState();
}

class _BulkOvertimeTabState extends State<BulkOvertimeTab> {
  final TextEditingController _deltaController = TextEditingController();

  @override
  void dispose() {
    _deltaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<HrToolsBloc, HrToolsState>(
      builder: (context, state) {
        // Clear field after successful submission
        if (state.overtimeDelta == 0 && _deltaController.text.isNotEmpty && state.successMessage == null) {
          _deltaController.clear();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormFieldWithLabel(
              label: l10n.daysToAdd,
              required: true,
              errorMessage: state.validationErrors.containsKey('overtimeDelta') ? l10n.invalidDaysToAdd : null,
              field: StyledTextField(
                controller: _deltaController,
                hintText: l10n.daysToAddHint,
                hasError: state.validationErrors.containsKey('overtimeDelta'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (value) {
                  final parsed = double.tryParse(value) ?? 0;
                  context.read<HrToolsBloc>().add(HrToolsOvertimeDeltaChanged(parsed));
                },
              ),
            ),
            const SizedBox(height: 28),

            AppButton(
              width: double.infinity,
              label: l10n.submit,
              isLoading: state.isSubmitting,
              onPressed:
                  state.isSubmitting
                      ? null
                      : () => context.read<HrToolsBloc>().add(const HrToolsBulkOvertimeSubmitted()),
            ),
          ],
        );
      },
    );
  }
}
