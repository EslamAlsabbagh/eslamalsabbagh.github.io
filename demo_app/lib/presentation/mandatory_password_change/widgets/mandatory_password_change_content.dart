import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/constants/password_validation.dart';
import 'package:hrms_demo/presentation/widgets/logout_action.dart';
import 'package:hrms_demo/data/repos/storage/storage_repo.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:hrms_demo/presentation/update_password/bloc/update_password_bloc.dart';
import 'package:hrms_demo/presentation/update_password/bloc/update_password_event.dart';
import 'package:hrms_demo/presentation/update_password/bloc/update_password_state.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/app_text_field.dart';
import 'package:hrms_demo/presentation/widgets/language_toggle_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MandatoryPasswordChangeContent extends StatefulWidget {
  final String userCode;

  const MandatoryPasswordChangeContent({super.key, required this.userCode});

  @override
  State<MandatoryPasswordChangeContent> createState() => _MandatoryPasswordChangeContentState();
}

class _MandatoryPasswordChangeContentState extends State<MandatoryPasswordChangeContent> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late final StorageRepo storage = context.read<StorageRepo>();

  void _updatePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<UpdatePasswordBloc>().add(
        UpdatePasswordRequested(
          code: widget.userCode,
          oldPassword: _oldPasswordController.text,
          newPassword: _newPasswordController.text,
          confirmPassword: _confirmPasswordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.mandatoryPasswordChange),
        automaticallyImplyLeading: false, // Remove back button
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => logoutAndSurfaceLogin(context),
            icon: const Icon(Icons.logout),
            color: Colors.white,
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.blue[50],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.security, size: 48, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.mandatoryPasswordChange,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.weakPasswordMessage,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
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
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _newPasswordController,
                      label: AppLocalizations.of(context)!.newPassword,
                      obscureText: true,
                      onFieldSubmitted: (_) => _updatePassword(),
                      validator: (value) => PasswordValidation.validatePassword(context, value ?? ''),
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 20),
                    BlocListener<UpdatePasswordBloc, UpdatePasswordState>(
                      listener: (context, state) {
                        if (state.status == Status.failure) {
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

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
                        }
                        if (state.status == Status.success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(AppLocalizations.of(context)!.passwordUpdatedSuccessfully)),
                          );
                          // Clear the weak-password flag and reload the profile.
                          // AuthGate re-reads the (now-cleared) flag on the next
                          // UserBloc transition and renders the dashboard itself
                          // — we must NOT push a route here, or we'd replace the
                          // AuthGate root and reintroduce the redirect loop.
                          final userBloc = context.read<UserBloc>();
                          storage.delete('weak_password_flag').then((_) {
                            userBloc.add(LoadUserProfile(widget.userCode));
                          });
                        }
                      },
                      child: BlocBuilder<UpdatePasswordBloc, UpdatePasswordState>(
                        builder: (context, state) {
                          if (state.status == Status.loading) {
                            return const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()));
                          }
                          return SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              label: AppLocalizations.of(context)!.updatePassword,
                              onPressed: _updatePassword,
                              color: Colors.blue,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    const LanguageToggleWidget(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
