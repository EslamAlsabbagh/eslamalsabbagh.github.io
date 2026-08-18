import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo.dart';
import 'package:hrms_demo/data/repos/businesstrip_cancellation_request/businesstrip_cancellation_request_repo.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/data/services/same_day_conflict_service.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/services/businesstrip_request/businesstrip_approval_workflow_service.dart';
import 'package:hrms_demo/presentation/user_businesstrip_requests/bloc/user_businesstrip_requests_bloc.dart';
import 'package:hrms_demo/presentation/user_businesstrip_requests/bloc/user_businesstrip_requests_event.dart';
import 'package:hrms_demo/presentation/user_businesstrip_requests/widgets/user_businesstrip_requests_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeamBusinesstripRequestsPage extends StatelessWidget {
  const TeamBusinesstripRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserBusinesstripRequestsBloc>(
      create:
          (context) => UserBusinesstripRequestsBloc(
            context.read<BusinesstripRequestsRepo>(),
            context.read<BusinesstripCancellationRequestsRepo>(),
            context.read<UsersRepo>(),
            context.read<UserBloc>(),
            context.read<BusinesstripApprovalWorkflowService>(),
            context.read<SameDayConflictService>(),
          )..add(
            loadBusinesstripRequestsEvent(
              context.read<UserBloc>().state.user?.id ?? 0,
              RequestSourceType.teamRequests,
            ),
          ),
      child: UserBusinesstripRequestsContent(sourceType: RequestSourceType.teamRequests),
    );
  }
}
