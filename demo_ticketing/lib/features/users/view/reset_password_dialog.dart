import 'dart:convert' show utf8;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/users_cubit.dart';
import '../data/user_models.dart';
import '../data/users_repository.dart';
import 'users_messages.dart';

/// The Users page's text field look.
InputDecoration userInputDecoration(
  BuildContext context, {
  String? error,
  String? hint,
  Widget? suffix,
}) {
  final tokens = context.tokens;
  return InputDecoration(
    isDense: true,
    errorText: error,
    errorMaxLines: 2,
    hintText: hint,
    suffixIcon: suffix,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      borderSide: BorderSide(color: tokens.inputBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      borderSide: BorderSide(color: tokens.inputBorder),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}

/// Why [password] can't be used yet, once something is typed; null when it
/// can, or while both fields are empty.
String? passwordProblem(AppLocalizations l10n, String password) {
  if (password.isEmpty) return null;
  if (password.length < staffPasswordMin) return l10n.usersPasswordTooShort(staffPasswordMin);
  if (utf8.encode(password).length > staffPasswordMax) return l10n.usersPasswordTooLong;
  return null;
}

bool passwordUsable(String password, String confirm) =>
    password.length >= staffPasswordMin &&
    utf8.encode(password).length <= staffPasswordMax &&
    password == confirm;

/// A password with a show/hide button. Left to right in both languages.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.error,
    this.hint,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? error;
  final String? hint;
  final VoidCallback? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _shown = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TextField(
      controller: widget.controller,
      obscureText: !_shown,
      autocorrect: false,
      enableSuggestions: false,
      textDirection: TextDirection.ltr,
      inputFormatters: [LengthLimitingTextInputFormatter(staffPasswordMax)],
      onSubmitted: widget.onSubmitted == null ? null : (_) => widget.onSubmitted!(),
      decoration: userInputDecoration(
        context,
        error: widget.error,
        hint: widget.hint,
        suffix: IconButton(
          tooltip: _shown ? l10n.usersHidePassword : l10n.usersShowPassword,
          onPressed: () => setState(() => _shown = !_shown),
          icon: Icon(_shown ? Icons.visibility_off_outlined : Icons.visibility_outlined),
        ),
      ),
    );
  }
}

/// Sets [user]'s password (not in the design, which has only the button).
/// The admin types it twice and tells the user; their sessions end, so they
/// sign in again with it. Logged, never the password (ADR-0036).
Future<void> showResetPasswordDialog(
  BuildContext context, {
  required UsersCubit cubit,
  required AdminUser user,
}) => showDialog<void>(
  context: context,
  builder: (context) => _ResetPasswordDialog(cubit: cubit, user: user),
);

class _ResetPasswordDialog extends StatefulWidget {
  const _ResetPasswordDialog({required this.cubit, required this.user});

  final UsersCubit cubit;
  final AdminUser user;

  @override
  State<_ResetPasswordDialog> createState() => _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends State<_ResetPasswordDialog> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  UsersFailureKind? _failure;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    for (final c in [_password, _confirm]) {
      c.addListener(() => setState(() => _failure = null));
    }
  }

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  bool get _ready => passwordUsable(_password.text, _confirm.text);

  Future<void> _submit() async {
    if (!_ready || _saving) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    final failure = await widget.cubit.resetPassword(widget.user.id, _password.text);
    if (!mounted) return;
    if (failure == null) {
      navigator.pop();
      messenger?.showSnackBar(SnackBar(content: Text(l10n.usersResetDone)));
    } else {
      setState(() {
        _saving = false;
        _failure = failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final passwordError = passwordProblem(l10n, _password.text);
    final confirmError = _confirm.text.isNotEmpty && _confirm.text != _password.text
        ? l10n.usersPasswordMismatch
        : null;

    Widget field(String label, Widget input) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        input,
      ],
    );

    return AlertDialog(
      key: const ValueKey('reset-dialog'),
      title: Text(l10n.usersResetTitle(widget.user.fullName)),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              field(
                l10n.usersPassword,
                PasswordField(
                  key: const ValueKey('reset-password'),
                  controller: _password,
                  error: passwordError,
                  hint: l10n.usersPasswordHint(staffPasswordMin),
                ),
              ),
              const SizedBox(height: 12),
              field(
                l10n.usersPasswordConfirm,
                PasswordField(
                  key: const ValueKey('reset-confirm'),
                  controller: _confirm,
                  error: confirmError,
                  onSubmitted: _submit,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.usersResetNote,
                style: TextStyle(fontSize: 13, color: tokens.textSecondary),
              ),
              if (_failure != null) ...[
                const SizedBox(height: 14),
                Container(
                  key: const ValueKey('reset-failure'),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: tokens.dangerBg,
                    borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                  ),
                  child: Text(
                    usersFailureMessage(l10n, _failure!),
                    style: TextStyle(fontSize: 14, color: tokens.dangerText),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(l10n.typesLogNote, style: TextStyle(fontSize: 12, color: tokens.textSecondary)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.back),
        ),
        FilledButton(
          key: const ValueKey('reset-submit'),
          onPressed: _ready && !_saving ? _submit : null,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.usersResetConfirm),
        ),
      ],
    );
  }
}
