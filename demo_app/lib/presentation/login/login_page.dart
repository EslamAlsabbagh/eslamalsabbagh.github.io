import 'package:hrms_demo/data/repos/auth/auth_repo.dart';
import 'package:hrms_demo/data/repos/storage/storage_repo.dart';
import 'package:hrms_demo/presentation/login/bloc/login_bloc.dart';
import 'package:hrms_demo/presentation/login/widgets/login_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LoginBloc>(
      create: (_) => LoginBloc(authRepo: context.read<AuthRepo>(), storage: context.read<StorageRepo>()),
      child: LoginContent(),
    );
  }
}
