import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/hr_tools/bloc/hr_tools_bloc.dart';
import 'package:hrms_demo/presentation/hr_tools/bloc/hr_tools_event.dart';
import 'package:hrms_demo/presentation/hr_tools/widgets/hr_tools_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HrToolsPage extends StatelessWidget {
  const HrToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => HrToolsBloc(
            usersRepo: context.read<UsersRepo>(),
            leaveRequestsRepo: context.read<LeaveRequestsRepo>(),
            userBloc: context.read<UserBloc>(),
          )..add(const HrToolsInitialized()),
      child: const HrToolsContent(),
    );
  }
}
