import 'package:hrms_demo/data/repos/schedule/schedule_repo.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/employee_schedule/employee_schedule_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum ScheduleHighlight { managerSwapPanel, selfSwapRows }

class EmployeeSchedulePage extends StatelessWidget {
  final ScheduleHighlight? highlight;

  const EmployeeSchedulePage({super.key, this.highlight});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScheduleBloc>(
      create: (_) => ScheduleBloc(context.read<ScheduleRepo>()),
      child: BlocBuilder<ScheduleBloc, ScheduleState>(
        buildWhen: (p, c) => p.publishState != c.publishState,
        builder:
            (context, state) => PopScope(
              canPop: state.publishState != PublishState.publishing,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context)!.schedulePublishingPleaseWait),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: EmployeeScheduleContent(highlight: highlight),
            ),
      ),
    );
  }
}
