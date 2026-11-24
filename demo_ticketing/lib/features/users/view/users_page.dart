import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/clock.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../auth/bloc/auth_cubit.dart';
import '../../auth/data/staff.dart';
import '../../home/view/app_header.dart' show roleName;
import '../../tickets/view/ticket_messages.dart' show dayTime;
import '../bloc/users_cubit.dart';
import '../data/user_models.dart';
import '../data/users_repository.dart';
import 'reset_password_dialog.dart';
import 'users_messages.dart';

/// Users (task 4.7, `Users.dc.html`): every staff member with their role, last
/// sign-in and status, an edit panel with the role's permissions, adding a
/// user (which makes their login, ADR-0021) and resetting a password. Admins
/// only. Each change is logged in the actions log (ADR-0036).
class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (context) => UsersCubit(context.read<UsersRepository>())..start(),
    child: const _UsersView(),
  );
}

class _UsersView extends StatelessWidget {
  const _UsersView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final state = context.watch<UsersCubit>().state;
    final cubit = context.read<UsersCubit>();
    final overview = state.overview;
    final auth = context.watch<AuthCubit>().state;
    final myId = auth is AuthSignedIn ? auth.staff.id : null;

    final Widget body;
    if (overview == null) {
      final failure = state.loadFailure;
      body = failure == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(l10n.usersLoading, style: TextStyle(color: tokens.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Text(
                    usersFailureMessage(l10n, failure),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (failure != UsersFailureKind.notAllowed)
                    FilledButton(onPressed: cubit.refresh, child: Text(l10n.retry)),
                ],
              ),
            );
    } else {
      // Rebuilt for another user, so its fields start from them.
      final panel = _EditPanel(
        key: ValueKey(state.creating ? 'users-panel-new' : 'users-panel-${state.selectedId}'),
        user: state.selected,
        myId: myId,
      );
      final table = _Table(overview: overview, state: state);
      body = LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [table, const SizedBox(height: 18), panel],
              ),
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: table,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: panel,
                ),
              ),
            ],
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.navUsers,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    l10n.usersSubtitle,
                    style: TextStyle(fontSize: 14, color: tokens.textSecondary),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: l10n.actionsRefresh,
                    onPressed: state.loading ? null : cubit.refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: AppSizes.touchTarget,
                    child: FilledButton.icon(
                      key: const ValueKey('users-new'),
                      onPressed: overview == null || state.creating ? null : cubit.startNew,
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(
                        l10n.usersNew,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// A role's pill, in the design's colours.
class RolePill extends StatelessWidget {
  const RolePill({super.key, required this.role});

  final StaffRole role;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final (bg, fg) = switch (role) {
      StaffRole.cashier => (tokens.primaryTint, tokens.onPrimaryTint),
      StaffRole.supervisor => (tokens.warningBg, tokens.warningText),
      StaffRole.admin => (tokens.adminRoleBg, tokens.adminRoleText),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        roleName(AppLocalizations.of(context), role),
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final (bg, fg) = active
        ? (tokens.successBg, tokens.successText)
        : (tokens.bg, tokens.textSecondary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(
        active ? l10n.usersStatusActive : l10n.usersStatusInactive,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

/// "اليوم 09:00 · شباك 1", or "لسه مدخلش".
String lastSignInText(AppLocalizations l10n, AdminUser user, DateTime now) {
  final at = user.lastSignInAt;
  if (at == null) return l10n.usersNeverSignedIn;
  return [dayTime(l10n, at, now), ?user.lastSignInCounter].join(' · ');
}

class _Table extends StatelessWidget {
  const _Table({required this.overview, required this.state});

  final UsersOverview overview;
  final UsersState state;

  static const _flex = [4, 2, 4, 2];

  static Widget cells(List<Widget> children) => Row(
    children: [
      for (var i = 0; i < children.length; i++)
        Expanded(
          flex: _flex[i],
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: children[i]),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final header = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: tokens.textSecondary,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: cells([
                Text(l10n.usersColName, style: header),
                Text(l10n.usersColRole, style: header),
                Text(l10n.usersColLastSignIn, style: header),
                Text(l10n.usersColStatus, style: header),
              ]),
            ),
            if (overview.users.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.usersEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: tokens.textSecondary),
                ),
              ),
            for (final user in overview.users) _row(context, user),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, AdminUser user) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final now = context.read<Clock>().now();
    final selected = !state.creating && state.selectedId == user.id;

    return DecoratedBox(
      key: ValueKey('user-row-${user.id}'),
      decoration: BoxDecoration(
        color: selected ? tokens.primaryTint : null,
        border: Border(top: BorderSide(color: tokens.rowDivider)),
      ),
      child: InkWell(
        onTap: () => context.read<UsersCubit>().select(user.id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: cells([
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    user.username,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                  ),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: RolePill(role: user.role),
              ),
              Text(
                lastSignInText(l10n, user, now),
                style: TextStyle(fontSize: 14, color: tokens.textMuted),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: _StatusChip(active: user.active),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// Lowercases what is typed: usernames are lowercase (ADR-0021).
class _LowerCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toLowerCase());
}

/// The edit panel. Its fields start from [user], or empty for a new one; the
/// page gives it a new key per user, so switching rows drops unsaved edits
/// (as the design).
class _EditPanel extends StatefulWidget {
  const _EditPanel({super.key, required this.user, required this.myId});

  /// Null for a new user.
  final AdminUser? user;

  /// The signed-in admin: their own role and active stay as they are.
  final String? myId;

  @override
  State<_EditPanel> createState() => _EditPanelState();
}

class _EditPanelState extends State<_EditPanel> {
  late final _name = TextEditingController(text: widget.user?.fullName ?? '');
  late final _username = TextEditingController(text: widget.user?.username ?? '');
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late StaffRole _role = widget.user?.role ?? StaffRole.cashier;
  late bool _active = widget.user?.active ?? true;

  /// The server's last refusal, shown on its field or in the banner.
  UsersFailureKind? _failure;

  List<TextEditingController> get _all => [_name, _username, _password, _confirm];

  @override
  void initState() {
    super.initState();
    for (final c in _all) {
      c.addListener(_changed);
    }
  }

  @override
  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
    super.dispose();
  }

  void _changed() => setState(() => _failure = null);

  bool get _self => widget.user != null && widget.user!.id == widget.myId;

  /// The panel's values, or null while one is missing or wrong.
  UserDraft? get _draft {
    final name = _name.text.trim();
    final username = _username.text.trim();
    if (name.isEmpty || !staffUsernamePattern.hasMatch(username)) return null;
    if (widget.user == null && !passwordUsable(_password.text, _confirm.text)) return null;
    return UserDraft(
      fullName: name,
      username: username,
      role: _role,
      active: _active,
      password: widget.user == null ? _password.text : null,
    );
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final adding = widget.user == null;
    final failure = await context.read<UsersCubit>().save(draft);
    if (!mounted) return;
    if (failure == null) {
      messenger?.showSnackBar(SnackBar(content: Text(adding ? l10n.usersAdded : l10n.typesSaved)));
    } else {
      setState(() => _failure = failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final saving = context.select((UsersCubit c) => c.state.saving);
    final user = widget.user;
    final draft = _draft;
    final changed = draft != null && (user == null || !draft.sameAs(user.draft));

    final failureText = _failure == null ? null : usersFailureMessage(l10n, _failure!);
    String? on(Set<UsersFailureKind> kinds) => kinds.contains(_failure) ? failureText : null;
    final nameFailure = on({UsersFailureKind.nameRequired});
    final usernameFailure = on({UsersFailureKind.usernameTaken, UsersFailureKind.invalidUsername});
    final passwordFailure = on({
      UsersFailureKind.passwordTooShort,
      UsersFailureKind.passwordTooLong,
    });
    final banner = nameFailure == null && usernameFailure == null && passwordFailure == null
        ? failureText
        : null;

    // Format errors only on something typed; an empty field just keeps Save off.
    final username = _username.text.trim();
    final usernameError = username.isNotEmpty && !staffUsernamePattern.hasMatch(username)
        ? l10n.usersInvalidUsername
        : usernameFailure;
    final passwordError = passwordProblem(l10n, _password.text) ?? passwordFailure;
    final confirmError = _confirm.text.isNotEmpty && _confirm.text != _password.text
        ? l10n.usersPasswordMismatch
        : null;

    // Off for one's own account, and switching off while their shift is open.
    final roleLocked = _self;
    final activeLocked = _self || (user != null && user.hasOpenShift && _active);
    final endsSessions = user != null && (_role != user.role || (user.active && !_active));

    Widget field(String label, Widget input) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        input,
      ],
    );

    Widget pair(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 12),
        Expanded(child: b),
      ],
    );

    Widget note(String text, Color bg, Color fg, {Key? key}) => Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      ),
      child: Text(text, style: TextStyle(fontSize: 14, color: fg)),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        border: Border.all(color: tokens.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              user == null ? l10n.usersNew : l10n.usersEditTitle(user.fullName),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            pair(
              field(
                l10n.usersName,
                TextField(
                  key: const ValueKey('users-name'),
                  controller: _name,
                  inputFormatters: [LengthLimitingTextInputFormatter(60)],
                  decoration: userInputDecoration(context, error: nameFailure),
                ),
              ),
              field(
                l10n.usersUsername,
                TextField(
                  key: const ValueKey('users-username'),
                  controller: _username,
                  textDirection: TextDirection.ltr,
                  autocorrect: false,
                  enableSuggestions: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._-]')),
                    _LowerCaseFormatter(),
                    LengthLimitingTextInputFormatter(32),
                  ],
                  decoration: userInputDecoration(
                    context,
                    error: usernameError,
                    hint: user == null ? 'm.ali' : null,
                  ),
                ),
              ),
            ),
            if (user == null) ...[
              const SizedBox(height: 4),
              Text(
                l10n.usersUsernameHint,
                style: TextStyle(fontSize: 12, color: tokens.textSecondary),
              ),
              const SizedBox(height: 12),
              pair(
                field(
                  l10n.usersPassword,
                  PasswordField(
                    key: const ValueKey('users-password'),
                    controller: _password,
                    error: passwordError,
                    hint: l10n.usersPasswordHint(staffPasswordMin),
                  ),
                ),
                field(
                  l10n.usersPasswordConfirm,
                  PasswordField(
                    key: const ValueKey('users-confirm'),
                    controller: _confirm,
                    error: confirmError,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            field(
              l10n.usersRole,
              SegmentedButton<StaffRole>(
                key: const ValueKey('users-role'),
                showSelectedIcon: false,
                segments: [
                  for (final r in StaffRole.values)
                    ButtonSegment(value: r, label: Text(roleName(l10n, r))),
                ],
                selected: {_role},
                onSelectionChanged: roleLocked
                    ? null
                    : (value) => setState(() {
                        _role = value.first;
                        _failure = null;
                      }),
              ),
            ),
            const SizedBox(height: 12),
            _Permissions(role: _role),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: tokens.inset,
                borderRadius: BorderRadius.circular(AppSizes.inputRadius),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.usersActiveLabel,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          l10n.usersActiveNote,
                          style: TextStyle(fontSize: 13, color: tokens.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    key: const ValueKey('users-active'),
                    value: _active,
                    onChanged: activeLocked
                        ? null
                        : (value) => setState(() {
                            _active = value;
                            _failure = null;
                          }),
                  ),
                ],
              ),
            ),
            if (_self) ...[
              const SizedBox(height: 12),
              note(
                l10n.usersSelfNote,
                tokens.inset,
                tokens.textSecondary,
                key: const ValueKey('users-self-note'),
              ),
            ] else if (user != null && user.hasOpenShift && user.active) ...[
              const SizedBox(height: 12),
              note(
                l10n.usersOpenShiftNote,
                tokens.warningBg,
                tokens.warningText,
                key: const ValueKey('users-open-shift-note'),
              ),
            ],
            if (endsSessions) ...[
              const SizedBox(height: 12),
              note(
                l10n.usersRoleSessionsNote,
                tokens.warningBg,
                tokens.warningText,
                key: const ValueKey('users-sessions-note'),
              ),
            ],
            if (banner != null) ...[
              const SizedBox(height: 12),
              note(
                banner,
                tokens.dangerBg,
                tokens.dangerText,
                key: const ValueKey('users-failure'),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (user != null) ...[
                  Expanded(
                    flex: 140,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        key: const ValueKey('users-reset'),
                        onPressed: saving
                            ? null
                            : () => showResetPasswordDialog(
                                context,
                                cubit: context.read<UsersCubit>(),
                                user: user,
                              ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: tokens.inputBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                          ),
                        ),
                        child: Text(
                          l10n.usersResetPassword,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 120,
                  child: SizedBox(
                    height: 48,
                    child: FilledButton(
                      key: const ValueKey('users-save'),
                      onPressed: changed && !saving ? _save : null,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSizes.inputRadius),
                        ),
                      ),
                      child: saving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              user == null ? l10n.usersAdd : l10n.usersSave,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.typesLogNote,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: tokens.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// The design's "يقدر يعمل" box: ✓ for what [role] has, — for the rest.
class _Permissions extends StatelessWidget {
  const _Permissions({required this.role});

  final StaffRole role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.tokens;
    final lines = permissionLines(l10n);
    return Container(
      key: const ValueKey('users-permissions'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: tokens.inset,
        borderRadius: BorderRadius.circular(AppSizes.inputRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.usersPermissionsTitle,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tokens.textMuted),
          ),
          const SizedBox(height: 6),
          for (var i = 0; i < lines.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                key: ValueKey('users-permission-$i-${roleCovers(role, lines[i].$2)}'),
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      roleCovers(role, lines[i].$2) ? '✓' : '—',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: roleCovers(role, lines[i].$2)
                            ? tokens.successText
                            : tokens.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(child: Text(lines[i].$1, style: const TextStyle(fontSize: 14))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
