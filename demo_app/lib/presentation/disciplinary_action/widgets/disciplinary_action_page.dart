import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_action_request_repo.dart';
import 'package:hrms_demo/data/repos/investigation_request/investigation_request_repo.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/presentation/disciplinary_action/bloc/disciplinary_action_bloc.dart';
import 'package:hrms_demo/presentation/disciplinary_action/widgets/disciplinary_action_content.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';

class DisciplinaryActionPage extends StatelessWidget {
  const DisciplinaryActionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => DisciplinaryActionBloc(
            usersRepo: context.read<UsersRepo>(),
            userBloc: context.read<UserBloc>(),
            disciplinaryActionRepo: context.read<DisciplinaryActionRequestRepo>(),
            investigationRepo: context.read<InvestigationRequestRepo>(),
          ),
      child: const DisciplinaryActionContent(),
    );
  }
}
