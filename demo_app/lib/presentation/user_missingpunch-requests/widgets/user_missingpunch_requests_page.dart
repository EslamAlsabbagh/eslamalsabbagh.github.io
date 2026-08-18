import 'package:hrms_demo/data/repos/missingpunching_request/missingpunching_request_repo.dart';
import 'package:hrms_demo/data/services/same_day_conflict_service.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/user_missingpunch-requests/bloc/user_missingpunch_requests_bloc.dart';
import 'package:hrms_demo/presentation/user_missingpunch-requests/bloc/user_missingpunch_requests_event.dart';
import 'package:hrms_demo/presentation/user_missingpunch-requests/widgets/user_missingpunch_requests_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserMissingpunchRequestsPage extends StatelessWidget {
  const UserMissingpunchRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserMissingpunchRequestsBloc>(
      create:
          (context) => UserMissingpunchRequestsBloc(
            context.read<MissingpunchingRequestsRepo>(),
            context.read<UserBloc>(),
            context.read<SameDayConflictService>(),
          )..add(
            loadMissingpunchRequestsEvent(
              context.read<UserBloc>().state.user?.id ?? 0,
              RequestSourceType.myRequests,
            ),
          ),
      child: UserMissingpunchRequestsContent(sourceType: RequestSourceType.myRequests),
    );
  }
}
