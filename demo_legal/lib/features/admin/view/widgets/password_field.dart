import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// A new password, left to right, with the login's show/hide eye (44px).
/// Autofill offers to generate one rather than fill the admin's own.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    this.fieldKey,
    required this.controller,
    this.label,
    this.readOnly = false,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
  });

  /// The inner [TextField]'s key, for tests.
  final Key? fieldKey;
  final TextEditingController controller;

  /// For screen readers, when the caller doesn't label the field itself;
  /// the visible label sits above it.
  final String? label;
  final bool readOnly;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  var _obscure = true;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final field = TextField(
      key: widget.fieldKey,
      controller: widget.controller,
      readOnly: widget.readOnly,
      autofocus: widget.autofocus,
      obscureText: _obscure,
      textDirection: TextDirection.ltr,
      autocorrect: false,
      enableSuggestions: false,
      autofillHints: const [AutofillHints.newPassword],
      textInputAction: TextInputAction.done,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: AppTextStyles.body.copyWith(color: tokens.ink),
      decoration: InputDecoration(
        hintText: l10n.userPasswordHint,
        suffixIcon: IconButton(
          tooltip: _obscure ? l10n.loginShowPassword : l10n.loginHidePassword,
          constraints: const BoxConstraints.tightFor(width: AppSpacing.touchTarget, height: AppSpacing.touchTarget),
          color: tokens.textMuted,
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
    final label = widget.label;
    return label == null ? field : Semantics(label: label, child: field);
  }
}
