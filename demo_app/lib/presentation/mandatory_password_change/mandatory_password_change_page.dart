import 'package:hrms_demo/data/repos/auth/auth_repo.dart';
import 'package:hrms_demo/presentation/mandatory_password_change/widgets/mandatory_password_change_content.dart';
import 'package:hrms_demo/presentation/update_password/bloc/update_password_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MandatoryPasswordChangePage extends StatelessWidget {
  final String userCode;

  const MandatoryPasswordChangePage({super.key, required this.userCode});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: BlocProvider<UpdatePasswordBloc>(
        create: (_) => UpdatePasswordBloc(authRepo: context.read<AuthRepo>()),
        child: MandatoryPasswordChangeContent(userCode: userCode),
      ),
    );
  }
}
