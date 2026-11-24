import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/password_text.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../tasks/view/widgets/confirm_dialog.dart';
import '../../tasks/view/widgets/form_error_line.dart';
import '../../tasks/view/widgets/form_modal.dart';
import '../bloc/password_dialog_bloc.dart';
import '../data/managed_user.dart';
import '../data/user_save_failure.dart';
import '../data/users_repository.dart';
import 'widgets/password_field.dart';

/// Opens the password modal for [user]; true once a new password is set.
Future<bool> openPasswordModal(BuildContext context, {required ManagedUser user}) async {
  final repository = context.read<UsersRepository>();
  final saved = await showDialog<bool>(
    context: context,
    barrierColor: context.tokens.scrim,
    barrierLabel: AppLocalizations.of(context).drawerClose,
    builder: (_) => BlocProvider(
      create: (_) => PasswordDialogBloc(userId: user.id, usersRepository: repository),
      child: PasswordModal(user: user),
    ),
  );
  return saved ?? false;
}

/// A new password for one account (there is no outgoing email, so the admin
/// hands it over). One field, «حفظ» and «إلغاء»; Esc, the scrim and × close it
/// without asking, like the name modal, except while saving.
class PasswordModal extends StatefulWidget {
  const PasswordModal({super.key, required this.user});

  final ManagedUser user;

  @override
  State<PasswordModal> createState() => _PasswordModalState();
}

class _PasswordModalState extends State<PasswordModal> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _submit() => context.read<PasswordDialogBloc>().add(PasswordSubmitted(_password.text));

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);

    return BlocConsumer<PasswordDialogBloc, PasswordDialogState>(
      listenWhen: (previous, current) => current.status == PasswordDialogStatus.saved,
      listener: (context, state) => Navigator.of(context).pop(true),
      builder: (context, state) {
        final saving = state.status != PasswordDialogStatus.editing;
        final canSave = !saving && PasswordText.isValid(_password.text);
        final failure = state.failure;

        return PopScope<Object?>(
          canPop: !saving,
          child: FormModal(
            title: l10n.passwordModalTitle,
            actions: [
              FilledButton(
                key: const Key('password-save'),
                onPressed: canSave ? _submit : null,
                child: saving
                    ? SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: tokens.surface),
                      )
                    : Text(l10n.editSave),
              ),
              OutlinedButton(
                key: const Key('password-cancel'),
                onPressed: saving ? null : () => Navigator.of(context).maybePop(),
                style: quietOutlineButtonStyle(context),
                child: Text(l10n.editCancel),
              ),
            ],
            children: [
              Text(
                l10n.passwordModalUserLine(widget.user.displayName),
                style: AppTextStyles.meta.copyWith(color: tokens.textMuted),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 6,
                children: [
                  ExcludeSemantics(
                    child: Text(
                      l10n.passwordModalLabel,
                      style: AppTextStyles.fieldLabel.copyWith(color: tokens.textMuted),
                    ),
                  ),
                  PasswordField(
                    fieldKey: const Key('password-field'),
                    controller: _password,
                    label: l10n.passwordModalLabel,
                    autofocus: true,
                    readOnly: saving,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                  ),
                ],
              ),
              if (failure != null) FormErrorLine(_message(l10n, failure), key: const Key('password-error')),
            ],
          ),
        );
      },
    );
  }

  static String _message(AppLocalizations l10n, UserSaveFailure failure) => switch (failure) {
    UserSaveFailure.notAllowed => l10n.userErrorNotAllowed,
    UserSaveFailure.weakPassword => l10n.userErrorWeakPassword,
    UserSaveFailure.network => l10n.loginErrorNetwork,
    _ => l10n.nameErrorUnknown,
  };
}
