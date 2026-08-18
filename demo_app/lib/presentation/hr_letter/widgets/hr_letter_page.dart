import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_request_repo.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/hr_letter/bloc/hr_letter_bloc.dart';
import 'package:hrms_demo/presentation/hr_letter/widgets/hr_letter_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HrLetterPage extends StatelessWidget {
  const HrLetterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create:
          (context) =>
              HrLetterBloc(userBloc: context.read<UserBloc>(), hrLetterRepo: context.read<HrLetterRequestRepo>()),
      child: const HrLetterContent(),
    );
  }
}
