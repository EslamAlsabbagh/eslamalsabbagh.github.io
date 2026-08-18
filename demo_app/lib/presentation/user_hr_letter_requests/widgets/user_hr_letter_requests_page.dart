import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_request_repo.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/user_hr_letter_requests/bloc/user_hr_letter_requests_bloc.dart';
import 'package:hrms_demo/presentation/user_hr_letter_requests/bloc/user_hr_letter_requests_event.dart';
import 'package:hrms_demo/presentation/user_hr_letter_requests/widgets/user_hr_letter_requests_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UserHrLetterRequestsPage extends StatelessWidget {
  const UserHrLetterRequestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.read<UserBloc>().state.user?.id ?? 0;
    return BlocProvider(
      create:
          (context) =>
              UserHrLetterRequestsBloc(context.read<HrLetterRequestRepo>())
                ..add(loadHrLetterRequestsEvent(userId, HrLetterRequestSourceType.myRequests)),
      child: const UserHrLetterRequestsContent(sourceType: HrLetterRequestSourceType.myRequests),
    );
  }
}
