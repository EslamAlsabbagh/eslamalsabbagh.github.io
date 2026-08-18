import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import 'package:hrms_demo/services/advance_request/advance_request_workflow_service.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/user_advance_on_salary_requests/bloc/user_advance_on_salary_requests_bloc.dart';
import 'package:hrms_demo/presentation/user_advance_on_salary_requests/bloc/user_advance_on_salary_requests_event.dart';
import 'package:hrms_demo/presentation/user_advance_on_salary_requests/widgets/user_advance_on_salary_requests_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeamAdvanceOnSalaryRequestsPage extends StatelessWidget {
  const TeamAdvanceOnSalaryRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserAdvanceOnSalaryRequestsBloc>(
      create: (context) {
        final advanceRepo = context.read<AdvanceOnSalaryRequestsRepo>();
        final workflowService = context.read<AdvanceRequestWorkflowService>();

        return UserAdvanceOnSalaryRequestsBloc(advanceRepo, workflowService: workflowService)
          ..add(loadAdvanceRequestsEvent(context.read<UserBloc>().state.user?.id ?? 0, RequestSourceType.teamRequests));
      },
      child: const UserAdvanceOnSalaryRequestsContent(sourceType: RequestSourceType.teamRequests),
    );
  }
}
