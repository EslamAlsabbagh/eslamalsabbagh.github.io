import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../home/view/language_switch.dart';
import '../bloc/auth_cubit.dart';
import '../data/auth_repository.dart';

/// Login (`Login.dc.html`). Username and password; the router moves on once
/// [AuthCubit] is signed in.
///
/// Differs from the design: no counter name and no "server connected" badge
/// in the header (anon can't read counters; the health check comes with
/// offline mode, 2.8), and no version footer yet (6.4).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() => context.read<AuthCubit>().signIn(_username.text, _password.text);

  /// The fields are disabled while signing in, which drops keyboard focus.
  /// After a failure, focus goes back to the field to fix: the username if
  /// it's empty, otherwise the password, selected so typing replaces it.
  /// After the frame, because a field still disabled refuses focus.
  void _refocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_username.text.trim().isEmpty) {
        _usernameFocus.requestFocus();
      } else {
        _password.selection = TextSelection(baseOffset: 0, extentOffset: _password.text.length);
        _passwordFocus.requestFocus();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;

    return Scaffold(
      body: Column(
        children: [
          // Header: the switch at the end corner, as on the design.
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Align(alignment: AlignmentDirectional.centerEnd, child: LanguageSwitch()),
          ),
          Expanded(
            // Full width, so the scrollbar sits at the window edge; at least as
            // tall as the window, so the card stays centred.
            child: LayoutBuilder(
              builder: (context, viewport) => SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: viewport.maxHeight - 48),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: tokens.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(36),
                          child: BlocConsumer<AuthCubit, AuthState>(
                            listenWhen: (_, state) =>
                                state is AuthSignedOut && state.failure != null,
                            listener: (_, _) => _refocus(),
                            builder: (context, state) {
                              final busy = state is AuthSigningIn;
                              final failure = state is AuthSignedOut ? state.failure : null;
                              return AutofillGroup(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const _Heading(),
                                    const SizedBox(height: 20),
                                    _LabeledField(
                                      label: l10n.usernameLabel,
                                      child: TextField(
                                        controller: _username,
                                        focusNode: _usernameFocus,
                                        autofocus: true,
                                        enabled: !busy,
                                        autocorrect: false,
                                        enableSuggestions: false,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [AutofillHints.username],
                                        style: const TextStyle(fontSize: 17),
                                        decoration: _fieldDecoration,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    _LabeledField(
                                      label: l10n.passwordLabel,
                                      child: TextField(
                                        controller: _password,
                                        focusNode: _passwordFocus,
                                        enabled: !busy,
                                        obscureText: true,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [AutofillHints.password],
                                        style: const TextStyle(fontSize: 17),
                                        decoration: _fieldDecoration,
                                        onSubmitted: (_) => _submit(),
                                      ),
                                    ),
                                    if (failure != null) ...[
                                      const SizedBox(height: 20),
                                      _ErrorBox(message: _failureText(l10n, failure)),
                                    ],
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 56,
                                      child: FilledButton(
                                        onPressed: busy ? null : _submit,
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        child: busy
                                            ? const SizedBox.square(
                                                dimension: 24,
                                                child: CircularProgressIndicator(strokeWidth: 2.5),
                                              )
                                            : Text(l10n.signIn),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      l10n.forgotPasswordHint,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _fieldDecoration = InputDecoration(
    constraints: BoxConstraints(minHeight: 52),
    contentPadding: EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 14),
  );

  static String _failureText(AppLocalizations l10n, AuthFailureKind failure) => switch (failure) {
        AuthFailureKind.missingFields => l10n.loginErrorMissingFields,
        AuthFailureKind.invalidCredentials => l10n.loginErrorInvalidCredentials,
        AuthFailureKind.accountInactive => l10n.loginErrorAccountInactive,
        AuthFailureKind.serverUnreachable => l10n.loginErrorServerUnreachable,
        AuthFailureKind.sessionEnded => l10n.loginErrorSessionEnded,
        AuthFailureKind.unexpected => l10n.loginErrorUnexpected,
      };
}

/// Logo tile, app name and the line under it.
class _Heading extends StatelessWidget {
  const _Heading();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: tokens.primary,
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          ),
          child: Icon(Icons.confirmation_number_outlined, size: 30, color: tokens.surface),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.appTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.loginSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: tokens.textSecondary),
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: tokens.dangerBg,
          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
        ),
        child: Text(message, style: TextStyle(fontSize: 14, color: tokens.dangerText)),
      ),
    );
  }
}
