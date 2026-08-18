import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/presentation/advance_on_salary/bloc/advance_on_salary_bloc.dart';
import 'package:hrms_demo/presentation/advance_on_salary/widgets/advance_on_salary_content.dart';

class AdvanceOnSalaryPage extends StatelessWidget {
  const AdvanceOnSalaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) => AdvanceOnSalaryBloc(
            usersRepo: context.read<UsersRepo>(),
            userBloc: context.read<UserBloc>(),
            advanceOnSalaryRepo: context.read<AdvanceOnSalaryRequestsRepo>(),
          ),
      child: const AdvanceOnSalaryContent(),
    );
  }
}
