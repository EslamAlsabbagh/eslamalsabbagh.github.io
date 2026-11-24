import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/domain/user_role.dart';
import '../../../core/format/text_direction.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/validation/name_text.dart';
import '../../../core/validation/task_text.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../l10n/user_role_l10n.dart';
import '../../tasks/data/task_file.dart';
import '../../tasks/view/widgets/confirm_dialog.dart';
import '../../tasks/view/widgets/form_error_line.dart';
import '../../tasks/view/widgets/form_modal.dart';
import '../../tasks/view/widgets/labeled_field.dart';
import '../bloc/user_form_bloc.dart';
import '../bloc/users_bloc.dart';
import '../data/managed_user.dart';
import '../data/user_save_failure.dart';
import '../data/users_repository.dart';
import 'password_modal.dart';
import 'widgets/password_field.dart';
import 'widgets/role_choice.dart';

/// Opens the user modal for [user] (null: a new account) and, if anything
/// was written while it was open, reloads the list quietly.
Future<void> openUserModal(BuildContext context, {ManagedUser? user, required String viewerId}) async {
  final usersBloc = context.read<UsersBloc>();
  final repository = context.read<UsersRepository>();
  // Created here, not in the builder, so its state can be read after the
  // modal closes however it closed (×, scrim, Esc or a save).
  final bloc = UserFormBloc(user: user, viewerId: viewerId, usersRepository: repository);
  await showDialog<void>(
    context: context,
    barrierColor: context.tokens.scrim,
    barrierLabel: AppLocalizations.of(context).drawerClose,
    builder: (_) => RepositoryProvider.value(
      value: repository,
      child: BlocProvider.value(
        value: bloc,
        child: UserModal(files: usersBloc.state.files),
      ),
    ),
  );
  if (bloc.state.changed) usersBloc.add(const UsersRefreshRequested());
  await bloc.close();
}

/// Creates an account or edits one (spec §4 "Users"): name, email and first
/// password (new only), role, and a lawyer's files; then, on edit, the
/// account's password and deactivation. Leaving with unsaved changes asks
/// first.
class UserModal extends StatefulWidget {
  const UserModal({super.key, required this.files});

  /// Every file, for a lawyer's checkboxes.
  final List<TaskFile> files;

  @override
  State<UserModal> createState() => _UserModalState();
}

class _UserModalState extends State<UserModal> {
  late final UserFormBloc _bloc = context.read<UserFormBloc>();
  late final UserDraft _initial = _bloc.initialDraft;
  late final TextEditingController _name = TextEditingController(text: _initial.name);
  final _email = TextEditingController();
  final _password = TextEditingController();
  late UserRole _role = _initial.role;
  late Set<String> _fileIds = {..._initial.fileIds};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  UserDraft get _draft =>
      UserDraft(name: _name.text, email: _email.text, password: _password.text, role: _role, fileIds: _fileIds);

  void _submit() => _bloc.add(UserFormSubmitted(_draft));

  Future<void> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final discard = await showConfirmDialog(
      context,
      title: l10n.discardEditTitle,
      body: l10n.userDiscardBody,
      backLabel: l10n.discardEditBack,
      confirmLabel: l10n.discardEditConfirm,
      keyPrefix: 'user-discard',
    );
    if (discard && mounted) navigator.pop();
  }

  Future<void> _toggleActive(ManagedUser user) async {
    final l10n = AppLocalizations.of(context);
    if (_bloc.state.isActive) {
      final confirmed = await showConfirmDialog(
        context,
        title: l10n.userDeactivateTitle(user.displayName),
        body: l10n.userDeactivateBody,
        backLabel: l10n.cancelTaskBack,
        confirmLabel: l10n.userDeactivate,
        keyPrefix: 'deactivate',
      );
      if (!confirmed) return;
    }
    _bloc.add(const UserActiveToggled());
  }

  Future<void> _setPassword(ManagedUser user) async {
    final saved = await openPasswordModal(context, user: user);
    if (saved) _bloc.add(const UserPasswordChanged());
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final user = _bloc.user;

    return BlocConsumer<UserFormBloc, UserFormState>(
      listenWhen: (previous, current) => !previous.saved && current.saved,
      listener: (context, state) => Navigator.of(context).pop(),
      builder: (context, state) {
        final busy = state.busy;
        final draft = _draft;
        final dirty = _bloc.isDirty(draft);
        final canSave = !busy && _bloc.canSave(draft);
        final failure = state.failure;

        return PopScope<Object?>(
          canPop: !busy && !dirty,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !busy) _confirmDiscard();
          },
          child: FormModal(
            title: user == null ? l10n.userModalNew : l10n.userModalEdit,
            actions: [
              FilledButton(
                key: const Key('user-save'),
                onPressed: canSave ? _submit : null,
                child: state.busyWith == UserFormAction.save ? _Spinner(color: tokens.surface) : Text(l10n.editSave),
              ),
              OutlinedButton(
                key: const Key('user-cancel'),
                onPressed: busy ? null : () => Navigator.of(context).maybePop(),
                style: quietOutlineButtonStyle(context),
                child: Text(l10n.editCancel),
              ),
            ],
            children: [
              LabeledField(
                label: l10n.userNameLabel,
                child: TextField(
                  key: const Key('user-name'),
                  controller: _name,
                  autofocus: user == null,
                  readOnly: busy,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _submit(),
                  textDirection: textDirectionOf(_name.text),
                  textInputAction: TextInputAction.next,
                  style: AppTextStyles.body.copyWith(color: tokens.ink),
                  decoration: InputDecoration(hintText: l10n.userNameHint),
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'[\r\n]+'), replacementString: ' '),
                    const CodePointLimitFormatter(NameText.max),
                  ],
                ),
              ),
              if (user == null) ...[
                LabeledField(
                  label: l10n.loginEmailLabel,
                  child: TextField(
                    key: const Key('user-email'),
                    controller: _email,
                    readOnly: busy,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
                    style: AppTextStyles.body.copyWith(color: tokens.ink),
                  ),
                ),
                LabeledField(
                  label: l10n.loginPasswordLabel,
                  child: PasswordField(
                    fieldKey: const Key('user-password'),
                    controller: _password,
                    readOnly: busy,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
              ] else if (user.email != null)
                LabeledField(
                  label: l10n.loginEmailLabel,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      user.email!,
                      key: const Key('user-email-text'),
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.body.copyWith(color: tokens.ink),
                    ),
                  ),
                ),
              LabeledField(
                semantics: FieldLabelSemantics.group,
                label: l10n.userRoleLabel,
                child: _bloc.isSelf
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          Text(_role.label(l10n), style: AppTextStyles.body.copyWith(color: tokens.ink)),
                          Text(
                            l10n.userSelfNote,
                            key: const Key('user-self-note'),
                            style: AppTextStyles.meta.copyWith(color: tokens.textMuted),
                          ),
                        ],
                      )
                    : RoleChoice(selected: _role, onPicked: busy ? null : (role) => setState(() => _role = role)),
              ),
              LabeledField(
                semantics: FieldLabelSemantics.group,
                label: l10n.userFilesLabel,
                child: !_role.needsFiles
                    ? Text(l10n.userFilesAll, style: AppTextStyles.meta.copyWith(color: tokens.textMuted))
                    : widget.files.isEmpty
                    ? Text(l10n.userFilesNone, style: AppTextStyles.meta.copyWith(color: tokens.textMuted))
                    : Column(
                        children: [
                          for (final file in widget.files)
                            CheckboxListTile(
                              key: Key('user-file-${file.id}'),
                              value: _fileIds.contains(file.id),
                              onChanged: busy
                                  ? null
                                  : (checked) => setState(() {
                                      _fileIds = checked ?? false
                                          ? {..._fileIds, file.id}
                                          : ({..._fileIds}..remove(file.id));
                                    }),
                              title: Text(file.name, style: AppTextStyles.body.copyWith(color: tokens.ink)),
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsetsDirectional.zero,
                              dense: true,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
              ),
              if (user != null)
                _AccountSection(
                  user: user,
                  isSelf: _bloc.isSelf,
                  state: state,
                  onSetPassword: busy ? null : () => _setPassword(user),
                  onToggleActive: busy ? null : () => _toggleActive(user),
                ),
              if (failure != null) FormErrorLine(_message(l10n, failure), key: const Key('user-error')),
            ],
          ),
        );
      },
    );
  }

  static String _message(AppLocalizations l10n, UserSaveFailure failure) => switch (failure) {
    UserSaveFailure.notAllowed => l10n.userErrorNotAllowed,
    UserSaveFailure.openTasks => l10n.userErrorOpenTasks,
    UserSaveFailure.openTasksInFile => l10n.userErrorOpenTasksInFile,
    UserSaveFailure.openTasksOutsideFiles => l10n.userErrorOpenTasksOutsideFiles,
    UserSaveFailure.emailTaken => l10n.userErrorEmailTaken,
    UserSaveFailure.weakPassword => l10n.userErrorWeakPassword,
    UserSaveFailure.network => l10n.loginErrorNetwork,
    UserSaveFailure.unknown => l10n.nameErrorUnknown,
  };
}

/// Edit only: «الحساب», with a new password and (not for oneself)
/// deactivate or reactivate.
class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.user,
    required this.isSelf,
    required this.state,
    required this.onSetPassword,
    required this.onToggleActive,
  });

  final ManagedUser user;
  final bool isSelf;
  final UserFormState state;
  final VoidCallback? onSetPassword;
  final VoidCallback? onToggleActive;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Divider(height: 1, color: tokens.divider),
        Semantics(
          header: true,
          child: Text(l10n.userAccountLabel, style: AppTextStyles.fieldLabel.copyWith(color: tokens.textMuted)),
        ),
        if (!state.isActive)
          Text(
            l10n.userIsInactive,
            key: const Key('user-inactive-line'),
            style: AppTextStyles.meta.copyWith(color: tokens.textSoft),
          ),
        if (state.passwordSet)
          Semantics(
            liveRegion: true,
            child: Row(
              key: const Key('user-password-set'),
              spacing: 6,
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: tokens.textMuted),
                Expanded(
                  child: Text(l10n.userPasswordSet, style: AppTextStyles.meta.copyWith(color: tokens.textMuted)),
                ),
              ],
            ),
          ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              key: const Key('user-set-password'),
              onPressed: onSetPassword,
              style: quietOutlineButtonStyle(context),
              child: Text(l10n.userSetPassword),
            ),
            if (!isSelf)
              OutlinedButton(
                key: const Key('user-toggle-active'),
                onPressed: onToggleActive,
                style: quietOutlineButtonStyle(context),
                child: state.busyWith == UserFormAction.active
                    ? _Spinner(color: tokens.ink)
                    : Text(state.isActive ? l10n.userDeactivate : l10n.userReactivate),
              ),
          ],
        ),
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color));
}
