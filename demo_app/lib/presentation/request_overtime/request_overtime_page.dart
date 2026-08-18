import 'package:hrms_demo/data/repos/overtime_request/overtime_request_repo.dart';
import 'package:hrms_demo/presentation/request_overtime/bloc/request_overtime_bloc.dart';
import 'package:hrms_demo/presentation/request_overtime/widgets/request_overtime_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RequestOvertimePage extends StatelessWidget {
  const RequestOvertimePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RequestOvertimeBloc>(
      create: (_) => RequestOvertimeBloc(context.read<OvertimeRequestRepo>()),
      child: RequestOvertimeContent(),
    );
  }
}
