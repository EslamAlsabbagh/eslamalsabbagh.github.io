import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shell/widgets/app_header.dart';
import '../../../shell/widgets/content_frame.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../tasks/view/widgets/confirm_dialog.dart';
import '../bloc/users_bloc.dart';
import '../data/users_repository.dart';
import 'user_modal.dart';
import 'widgets/user_row.dart';

/// Opens the users page over the shell (admins only, from the header).
Future<void> openUsersPage(BuildContext context, {required DateTime Function() clock}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => UsersPage(clock: clock)));

/// The admin users page (spec §4 "Users"): every account, active ones
/// first, each opening the user modal; «مستخدم جديد» creates one.
///
/// It sits over the shell, so it closes itself if the session ends (sign
/// out, or a refresh the token hook refused), and the login page shows.
class UsersPage extends StatelessWidget {
  const UsersPage({super.key, this.clock = DateTime.now});

  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final displayName = context.select((AuthBloc bloc) => bloc.state.profile?.displayName) ?? '';

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current.status != AuthStatus.authenticated,
      listener: (context, state) => Navigator.of(context).popUntil((route) => route.isFirst),
      child: BlocProvider(
        create: (context) =>
            UsersBloc(usersRepository: context.read<UsersRepository>())..add(const UsersLoadRequested()),
        child: Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: AppHeader(
                  today: clock(),
                  displayName: displayName,
                  onSignOut: () => context.read<AuthBloc>().add(const AuthSignOutRequested()),
                ),
              ),
              const SliverToBoxAdapter(child: ContentFrame(top: 18, bottom: 56, child: _UsersBody())),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersBody extends StatelessWidget {
  const _UsersBody();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    final state = context.watch<UsersBloc>().state;
    final viewerId = context.select((AuthBloc bloc) => bloc.state.profile?.id) ?? '';
    final loaded = state.status == UsersStatus.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 18,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 10,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                TextButton.icon(
                  key: const Key('users-back'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  // arrow_back follows the text direction: it points right in RTL.
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text(l10n.usersBack),
                  style: TextButton.styleFrom(
                    foregroundColor: tokens.ink,
                    textStyle: AppTextStyles.button,
                    minimumSize: const Size(AppSpacing.touchTarget, AppSpacing.touchTarget),
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
                  ),
                ),
                Semantics(
                  header: true,
                  child: Text(l10n.usersTitle, style: AppTextStyles.fileGroupTitle.copyWith(color: tokens.ink)),
                ),
              ],
            ),
            FilledButton.icon(
              key: const Key('users-new'),
              onPressed: loaded ? () => openUserModal(context, viewerId: viewerId) : null,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.usersNew),
            ),
          ],
        ),
        switch (state.status) {
          UsersStatus.loading => Padding(
            padding: const EdgeInsetsDirectional.only(top: 40),
            child: Center(
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: tokens.accent),
              ),
            ),
          ),
          UsersStatus.failure => const _LoadError(),
          UsersStatus.success => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.rowGap,
            children: [
              for (final user in state.ordered)
                UserRow(
                  key: ValueKey(user.id),
                  user: user,
                  onTap: () => openUserModal(context, user: user, viewerId: viewerId),
                ),
            ],
          ),
        },
      ],
    );
  }
}

/// «تعذّر تحميل المستخدمين.» and «إعادة المحاولة», like the tasks view's.
class _LoadError extends StatelessWidget {
  const _LoadError();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 24),
      child: Column(
        spacing: 12,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              Icon(Icons.error_outline, size: 18, color: tokens.overdue),
              Flexible(
                child: Text(l10n.usersLoadFailed, style: AppTextStyles.fieldLabel.copyWith(color: tokens.overdue)),
              ),
            ],
          ),
          OutlinedButton(
            key: const Key('users-retry'),
            onPressed: () => context.read<UsersBloc>().add(const UsersLoadRequested()),
            style: quietOutlineButtonStyle(context),
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
