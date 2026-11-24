import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/email.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shell/widgets/content_frame.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/login_bloc.dart';
import '../data/auth_repository.dart';
import '../data/sign_in_failure.dart';

/// Email + password sign-in. Not in the design canvas; layout recorded in
/// `docs/design/DESIGN_SPEC.md` §4 "Login".
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(authRepository: context.read<AuthRepository>()),
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const _TitleBand(),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSpacing.sidePadding,
                  40,
                  AppSpacing.sidePadding,
                  56,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: const _LoginCard(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The app header's dark band, title only.
class _TitleBand extends StatelessWidget {
  const _TitleBand();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.tokens.ink,
      child: ContentFrame(
        top: 20,
        bottom: 18,
        child: Semantics(
          header: true,
          child: Text(
            AppLocalizations.of(context).appTitle,
            style: AppTextStyles.appTitle.copyWith(color: context.tokens.bg),
          ),
        ),
      ),
    );
  }
}

class _LoginCard extends StatefulWidget {
  const _LoginCard();

  @override
  State<_LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<_LoginCard> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _emailFocus = FocusNode();
  late final _fields = Listenable.merge([_email, _password]);
  var _obscurePassword = true;

  /// Set by the first submit attempt; from then on the email format is
  /// re-checked as the user types.
  var _showEmailErrors = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  bool get _isFilled => _email.text.trim().isNotEmpty && _password.text.isNotEmpty;

  void _submit() {
    final bloc = context.read<LoginBloc>();
    if (!_isFilled || bloc.state.status == LoginStatus.submitting) return;
    if (!looksLikeEmail(_email.text)) {
      // Caught here, so a typo never costs a request.
      setState(() => _showEmailErrors = true);
      _emailFocus.requestFocus();
      // Focusing selects all on web; put the cursor at the end instead so the
      // next keystroke fixes the typo rather than wiping the address.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _email.selection = TextSelection.collapsed(offset: _email.text.length);
      });
      return;
    }
    bloc.add(LoginSubmitted(email: _email.text, password: _password.text));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);

    return BlocListener<LoginBloc, LoginState>(
      // Credentials were accepted: let the browser offer to save them.
      listenWhen: (previous, current) =>
          previous.status == LoginStatus.submitting && current.status == LoginStatus.idle,
      listener: (context, state) => TextInput.finishAutofillContext(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(AppRadii.modal),
          border: Border.all(color: tokens.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.modalPadding),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  header: true,
                  child: Text(l10n.loginTitle, style: AppTextStyles.fileGroupTitle),
                ),
                const SizedBox(height: AppSpacing.formGap),
                _LabeledField(
                  label: l10n.loginEmailLabel,
                  child: TextField(
                    key: const Key('login-email'),
                    controller: _email,
                    focusNode: _emailFocus,
                    // Emails and passwords are Latin text in an RTL form.
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: (_) {
                      if (_showEmailErrors) setState(() {});
                    },
                    decoration: InputDecoration(
                      errorText: _showEmailErrors && !looksLikeEmail(_email.text)
                          ? l10n.loginErrorInvalidEmail
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.formGap),
                _LabeledField(
                  label: l10n.loginPasswordLabel,
                  child: TextField(
                    key: const Key('login-password'),
                    controller: _password,
                    textDirection: TextDirection.ltr,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword ? l10n.loginShowPassword : l10n.loginHidePassword,
                        constraints: const BoxConstraints.tightFor(
                          width: AppSpacing.touchTarget,
                          height: AppSpacing.touchTarget,
                        ),
                        color: tokens.textMuted,
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                ),
                const _ErrorMessage(),
                const SizedBox(height: AppSpacing.formGap),
                BlocBuilder<LoginBloc, LoginState>(
                  buildWhen: (previous, current) => previous.status != current.status,
                  builder: (context, state) {
                    final submitting = state.status == LoginStatus.submitting;
                    return ListenableBuilder(
                      listenable: _fields,
                      builder: (context, _) => FilledButton(
                        key: const Key('login-submit'),
                        onPressed: _isFilled && !submitting ? _submit : null,
                        child: submitting
                            ? SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: tokens.surface,
                                ),
                              )
                            : Text(l10n.loginSubmit),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.loginForgotHelp,
                  style: AppTextStyles.meta.copyWith(color: tokens.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Merged so screen readers announce the label with the field.
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: AppTextStyles.fieldLabel.copyWith(color: context.tokens.textMuted)),
          const SizedBox(height: AppSpacing.labelGap),
          child,
        ],
      ),
    );
  }
}

/// The failed attempt's reason, else why `AuthBloc` signed the user out.
class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final login = context.watch<LoginBloc>().state;
    final notice = context.select((AuthBloc bloc) => bloc.state.notice);

    final message = switch (login.status) {
      LoginStatus.failure => _failureText(l10n, login.failure!),
      LoginStatus.submitting => null,
      LoginStatus.idle => notice == null ? null : _noticeText(l10n, notice),
    };
    if (message == null) return const SizedBox.shrink();

    final color = context.tokens.overdue;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 12),
      child: Semantics(
        liveRegion: true,
        child: Row(
          key: const Key('login-error'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: Icon(Icons.error_outline, size: 18, color: color),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.meta.copyWith(color: color, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _failureText(AppLocalizations l10n, SignInFailure failure) => switch (failure) {
        SignInFailure.invalidCredentials => l10n.loginErrorInvalidCredentials,
        SignInFailure.accountDisabled => l10n.authAccountDisabled,
        SignInFailure.rateLimited => l10n.loginErrorRateLimited,
        SignInFailure.network => l10n.loginErrorNetwork,
        SignInFailure.unknown => l10n.loginErrorUnknown,
      };

  static String _noticeText(AppLocalizations l10n, AuthNotice notice) => switch (notice) {
        AuthNotice.accountDisabled => l10n.authAccountDisabled,
        AuthNotice.serverUnreachable => l10n.loginErrorNetwork,
      };
}
