import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/locale/locale_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/bloc/auth_cubit.dart';

/// Switches between Arabic and English. Shows the other language's short code
/// ("EN" / "AR"), as on the login design.
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    return Tooltip(
      message: l10n.switchLanguageHint,
      excludeFromSemantics: true,
      child: Semantics(
        label: l10n.switchLanguageHint,
        excludeSemantics: true,
        button: true,
        child: OutlinedButton(
          onPressed: () {
            final locale = context.read<LocaleCubit>()..toggle();
            // Signed in: also saved as the staff member's own language.
            context.read<AuthCubit>().saveLanguage(locale.state.languageCode);
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(AppSizes.touchTarget, AppSizes.touchTarget),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            backgroundColor: tokens.surface,
            side: BorderSide(color: tokens.border),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          child: Text(l10n.switchLanguage),
        ),
      ),
    );
  }
}
