import 'package:hrms_demo/data/repos/overtime_request/overtime_request_repo.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/user_overtime_requests/bloc/user_overtime_requests_bloc.dart';
import 'package:hrms_demo/presentation/user_overtime_requests/bloc/user_overtime_requests_event.dart';
import 'package:hrms_demo/presentation/user_overtime_requests/widgets/user_overtime_requests_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeamOvertimeRequestsPage extends StatelessWidget {
  const TeamOvertimeRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserOvertimeRequestsBloc>(
      create:
          (_) => UserOvertimeRequestsBloc(context.read<OvertimeRequestRepo>())..add(
            loadOvertimeRequestsEvent(context.read<UserBloc>().state.user?.id ?? 0, RequestSourceType.teamRequests),
          ),
      child: UserOvertimeRequestsContent(sourceType: RequestSourceType.teamRequests),
    );
  }
}
