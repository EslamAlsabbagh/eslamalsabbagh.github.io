import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/services/disabled_dates_service.dart';
import 'package:hrms_demo/presentation/request_leave/bloc/request_leave_bloc.dart';
import 'package:hrms_demo/presentation/request_leave/widgets/request_leave_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RequestLeavePage extends StatelessWidget {
  const RequestLeavePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RequestLeaveBloc>(
      create: (_) => RequestLeaveBloc(context.read<LeaveRequestsRepo>(), context.read<DisabledDatesService>()),
      child: RequestLeaveContent(),
    );
  }
}
