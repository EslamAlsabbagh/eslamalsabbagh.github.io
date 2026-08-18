import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/constants/password_validation.dart';
import 'package:hrms_demo/data/repos/storage/storage_keys.dart';
import 'package:hrms_demo/data/repos/storage/storage_repo.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/update_password/bloc/update_password_bloc.dart';
import 'package:hrms_demo/presentation/update_password/bloc/update_password_event.dart';
import 'package:hrms_demo/presentation/update_password/bloc/update_password_state.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/app_text_field.dart';
import 'package:hrms_demo/presentation/widgets/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UpdatePasswordContent extends StatefulWidget {
  const UpdatePasswordContent({super.key});

  @override
  _UpdatePasswordContentState createState() => _UpdatePasswordContentState();
}

class _UpdatePasswordContentState extends State<UpdatePasswordContent> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  void _updatePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      final storage = context.read<StorageRepo>();
      // Call the update password event here
      context.read<UpdatePasswordBloc>().add(
        UpdatePasswordRequested(
          code: await storage.read(StorageKeys.userCode.key),
          oldPassword: _oldPasswordController.text,
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: AppLocalizations.of(context)!.updatePassword,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Center(
              heightFactor: 1.1,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppTextField(
                                controller: _oldPasswordController,
                                label: AppLocalizations.of(context)!.oldPassword,
                                onFieldSubmitted: (_) => _updatePassword(),
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(context)!.plsOldPassword;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _newPasswordController,
                                label: AppLocalizations.of(context)!.newPassword,
                                obscureText: true,
                                onFieldSubmitted: (_) => _updatePassword(),
                                validator: (value) => PasswordValidation.validatePassword(context, value ?? ''),
                              ),
                              const SizedBox(height: 16),
                              AppTextField(
                                controller: _confirmPasswordController,
                                label: AppLocalizations.of(context)!.confirmPassword,
                                obscureText: true,
                                onFieldSubmitted: (_) => _updatePassword(),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppLocalizations.of(context)!.confirmPassword;
                                  }
                                  if (value != _newPasswordController.text) {
                                    return AppLocalizations.of(context)!.passwordsDoNotMatch;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              BlocBuilder<UpdatePasswordBloc, UpdatePasswordState>(
                                builder: (context, state) {
                                  if (state.status == Status.loading) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (state.status == Status.failure) {
                                    // Show error message
                                    String errorMessage = 'Something went wrong';

                                    if (state.failure?.message != null) {
                                      switch (state.failure!.message!.replaceAll('Exception: ', '')) {
                                        case 'confirmPasswordDoesNotMatch':
                                          errorMessage = AppLocalizations.of(context)!.confirmPasswordDoesNotMatch;
                                          break;
                                        case 'oldPasswordIncorrect':
                                          errorMessage = AppLocalizations.of(context)!.oldPasswordIncorrect;
                                          break;
                                        case 'updatePasswordFailed':
                                          errorMessage = AppLocalizations.of(context)!.updatePasswordFailed;
                                          break;
                                        case 'weakPassword':
                                          errorMessage = AppLocalizations.of(context)!.weakPassword;
                                          break;
                                        case 'passwordTooShort':
                                          errorMessage = AppLocalizations.of(context)!.passwordTooShort;
                                          break;
                                        case 'passwordTooShortNew':
                                          errorMessage = AppLocalizations.of(context)!.passwordTooShortNew;
                                          break;
                                        case 'passwordMissingUppercase':
                                          errorMessage = AppLocalizations.of(context)!.passwordMissingUppercase;
                                          break;
                                        case 'passwordMissingLowercase':
                                          errorMessage = AppLocalizations.of(context)!.passwordMissingLowercase;
                                          break;
                                        case 'passwordMissingDigit':
                                          errorMessage = AppLocalizations.of(context)!.passwordMissingDigit;
                                          break;
                                        case 'passwordMissingSpecialChar':
                                          errorMessage = AppLocalizations.of(context)!.passwordMissingSpecialChar;
                                          break;
                                        case 'samePassword':
                                          errorMessage = AppLocalizations.of(context)!.samePassword;
                                          break;

                                        default:
                                          errorMessage = state.failure!.message!;
                                      }
                                    }
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
                                    });
                                  }
                                  if (state.status == Status.success) {
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(AppLocalizations.of(context)!.passwordUpdatedSuccessfully),
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    });
                                  }
                                  return AppButton(
                                    label: AppLocalizations.of(context)!.updatePassword,
                                    onPressed: _updatePassword,
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue[200]!),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                                    const SizedBox(height: 6),
                                    Text(
                                      AppLocalizations.of(context)!.passwordRequirements,
                                      style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
