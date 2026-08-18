import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_action_request_repo.dart';
import 'package:hrms_demo/data/repos/investigation_request/investigation_request_repo.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/bloc/user_disciplinary_action_requests_bloc.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/bloc/user_disciplinary_action_requests_event.dart';
import 'package:hrms_demo/presentation/user_disciplinary_action_requests/widgets/user_disciplinary_action_requests_content.dart';

class TeamDisciplinaryActionRequestsPage extends StatelessWidget {
  const TeamDisciplinaryActionRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => UserDisciplinaryActionRequestsBloc(
            context.read<DisciplinaryActionRequestRepo>(),
            context.read<InvestigationRequestRepo>(),
          ),
      child: const UserDisciplinaryActionRequestsContent(sourceType: RequestSourceType.teamRequests),
    );
  }
}
