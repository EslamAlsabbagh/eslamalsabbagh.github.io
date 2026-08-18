import 'package:hrms_demo/data/repos/leave_cancellation_request/leave_cancellation_request_repo.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/user_requests/bloc/user_requests_bloc.dart';
import 'package:hrms_demo/presentation/user_requests/bloc/user_requests_event.dart';
import 'package:hrms_demo/presentation/user_requests/widgets/user_requests_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserRequestsPage extends StatelessWidget {
  const UserRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserRequestsBloc>(
      create:
          (context) => UserRequestsBloc(
            context.read<LeaveRequestsRepo>(),
            context.read<LeaveCancellationRequestsRepo>(),
            context.read<UsersRepo>(),
            context.read<UserBloc>(),
          )..add(loadRequestsEvent(context.read<UserBloc>().state.user?.id ?? 0, RequestSourceType.myRequests)),
      child: UserRequestsContent(sourceType: RequestSourceType.myRequests),
    );
  }
}
