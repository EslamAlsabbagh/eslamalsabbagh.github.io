import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/core/extensions/context_extensions.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:hrms_demo/presentation/login/bloc/login_bloc.dart';
import 'package:hrms_demo/presentation/login/bloc/login_event.dart';
import 'package:hrms_demo/presentation/login/bloc/login_state.dart';
import 'package:hrms_demo/presentation/login/widgets/autofill_dom_reader_stub.dart'
    if (dart.library.js_interop) 'package:hrms_demo/presentation/login/widgets/autofill_dom_reader_web.dart';
import 'package:hrms_demo/presentation/widgets/app_button.dart';
import 'package:hrms_demo/presentation/widgets/app_text_field.dart';
import 'package:hrms_demo/presentation/widgets/language_toggle_widget.dart';
import 'package:hrms_demo/presentation/widgets/sidebar_cubit.dart';
import 'package:hrms_demo/presentation/widgets/sidebar_navigation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hrms_demo/demo/demo_session.dart';

class LoginContent extends StatefulWidget {
  const LoginContent({super.key});

  @override
  _LoginContentState createState() => _LoginContentState();
}

class _LoginContentState extends State<LoginContent> with WidgetsBindingObserver {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FocusNode _codeFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // SAFETY NET: Reset BLoC states if we're on login page after logout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentUser = context.read<DemoSession>().isSignedIn ? context.read<DemoSession>() : null;

      // If no current user (logged out), reset all BLoCs as safety net
      if (currentUser == null && mounted) {
        try {
          context.read<UserBloc>().add(ResetUserState());
          context.read<SidebarNavigationCubit>().resetState();
          context.read<SidebarCubit>().reset();
        } catch (e) {
          debugPrint('Safety net BLoC reset error: $e');
        }
      }
    });

    // Auto-navigation based on an existing session lives in AuthGate now. This
    // widget no longer pushes routes for an authenticated session — doing so
    // used to fight AuthGate and produce the recursive login redirect loop.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _codeController.dispose();
    _passwordController.dispose();
    _codeFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  int _resumeGeneration = 0;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // The Windows Hello dialog blurs the page, which closes Flutter's text
    // input connection and leaves the engine's autofill <form> dormant in the
    // DOM. The browser injects the picked credential into that dormant form,
    // so the values never reach our controllers — and injection timing after
    // the dialog varies, hence the escalating retries.
    final gen = ++_resumeGeneration;
    for (final ms in const [50, 250, 750, 1500, 3000]) {
      Future.delayed(Duration(milliseconds: ms), () {
        if (!mounted || gen != _resumeGeneration) return;
        _harvestBrowserAutofill();
      });
    }
  }

  void _harvestBrowserAutofill() {
    if (_codeController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      return;
    }
    final values = readBrowserAutofillValues();
    var changed = false;
    final code = values['username'];
    if (_codeController.text.isEmpty && code != null) {
      _codeController.text = code;
      changed = true;
    }
    final password = values['current-password'];
    if (_passwordController.text.isEmpty && password != null) {
      _passwordController.text = password;
      changed = true;
    }
    // Refocus only after the controllers hold the values: re-attaching the
    // input connection pushes controller state down to the DOM, which would
    // wipe a fill we hadn't harvested yet. If focus is already inside the
    // form the connection is live and syncs on its own.
    if (changed &&
        FocusManager.instance.primaryFocus != _codeFocusNode &&
        FocusManager.instance.primaryFocus != _passwordFocusNode) {
      (_codeController.text.isEmpty ? _codeFocusNode : _passwordFocusNode).requestFocus();
    }
  }

  void _submitLogin() {
    // Don't submit if already loading
    if (context.read<LoginBloc>().state.status == Status.loading) {
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      // Validate that the code contains only numbers
      if (_codeController.text.isNotEmpty && int.tryParse(_codeController.text) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.employeeCodeOnlyNumbers),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      String formatedCode = '1${_codeController.text.padLeft(7, '0')}';
      context.read<LoginBloc>().add(LoginRequested(code: formatedCode, password: _passwordController.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: BlocListener<LoginBloc, LoginState>(
            listenWhen: (previous, current) => previous.status != current.status,
            listener: (_, state) {
              if (state.status == Status.success) {
                TextInput.finishAutofillContext();
                // The session is now set. AuthGate observes the auth state
                // change, loads the profile and renders the dashboard. We must
                // NOT push a route here: doing so replaced the AuthGate root and
                // re-created the dual-authority loop.
              }

              // Status.weakPassword is handled by AuthGate via the
              // `weak_password_flag` it reads once the session exists, so there
              // is no navigation to perform here either.

              if (state.status == Status.failure) {
                String errorMessage = AppLocalizations.of(context)!.errorOccurred;

                if (state.failure != null) {
                  String failureMessage = state.failure!.message!.replaceAll('Exception: ', '');

                  if (failureMessage.contains('suspended')) {
                    errorMessage = AppLocalizations.of(context)!.accountSuspended;
                  } else if (failureMessage.contains('Employee code must contain only numbers')) {
                    errorMessage = AppLocalizations.of(context)!.employeeCodeOnlyNumbers;
                  } else {
                    switch (failureMessage) {
                      case 'invalidCredentials':
                        errorMessage = AppLocalizations.of(context)!.invalidCredentials;
                        break;
                      case 'emailNotConfirmed':
                        errorMessage = AppLocalizations.of(context)!.emailNotConfirmed;
                        break;
                      case 'tooManyRequests':
                        errorMessage = AppLocalizations.of(context)!.tooManyRequests;
                        break;
                      case 'loginFailed':
                        errorMessage = AppLocalizations.of(context)!.loginFailed;
                        break;
                      default:
                        errorMessage = state.failure!.message!;
                    }
                  }
                }

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(errorMessage), duration: Duration(seconds: 3)));
              }
            },
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/logo.png', height: context.screenHeight * 0.25),
                    SizedBox(height: 16),
                    AppTextField(
                      label: AppLocalizations.of(context)!.code,
                      controller: _codeController,
                      focusNode: _codeFocusNode,
                      // Text (not number) so engines that render number-typed
                      // DOM inputs don't get skipped by password managers.
                      keyboardType: TextInputType.text,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autofillHints: [AutofillHints.username],
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return AppLocalizations.of(context)!.fieldRequired;
                        }
                        if (int.tryParse(value) == null) {
                          return AppLocalizations.of(context)!.employeeCodeOnlyNumbers;
                        }
                        return null;
                      },
                      autofocus: true,
                    ),
                    SizedBox(height: 16),
                    AppTextField(
                      label: AppLocalizations.of(context)!.password,
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      obscureText: true,
                      autofillHints: [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitLogin(),
                      autofocus: false,
                    ),
                    SizedBox(height: 16),
                    BlocBuilder<LoginBloc, LoginState>(
                      builder: (context, state) {
                        return Column(
                          children: [
                            state.status == Status.loading
                                ? Container(
                                  height: 48, // Match button height
                                  width: 48,
                                  padding: EdgeInsets.all(8),
                                  child: CircularProgressIndicator(),
                                )
                                : AppButton(label: AppLocalizations.of(context)!.login, onPressed: _submitLogin),
                            if (state.status == Status.failure)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: Text(
                                  AppLocalizations.of(context)!.forgotPasswordHint,
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 16),
                    LanguageToggleWidget(
                      width: 100,
                      margin: EdgeInsets.all(8),
                      borderColor: Colors.grey[400],
                      textColor: Colors.grey[700],
                    ),
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
