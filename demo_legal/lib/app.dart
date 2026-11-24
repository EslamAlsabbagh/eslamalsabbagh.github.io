import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/web/register_output.dart';
import 'demo/demo_chrome.dart';
import 'demo/demo_store.dart';
import 'features/admin/data/users_repository.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/view/login_page.dart';
import 'features/auth/view/splash_page.dart';
import 'features/contracts/data/contracts_repository.dart';
import 'features/notifications/data/notifications_repository.dart';
import 'features/tasks/data/live_changes.dart';
import 'features/tasks/data/tasks_repository.dart';
import 'l10n/gen/app_localizations.dart';
import 'shell/app_shell.dart';

class LegalTasksApp extends StatelessWidget {
  const LegalTasksApp({
    super.key,
    required this.authRepository,
    required this.tasksRepository,
    required this.usersRepository,
    required this.notificationsRepository,
    required this.contractsRepository,
    required this.liveChanges,
    this.registerOutput,
    this.clock = DateTime.now,
  });

  /// Repositories are built in `main.dart` and passed in, so tests can fake them.
  final AuthRepository authRepository;
  final TasksRepository tasksRepository;
  final UsersRepository usersRepository;
  final NotificationsRepository notificationsRepository;
  final ContractsRepository contractsRepository;

  /// Other people's changes, followed by the lists and the drawer.
  final LiveChanges liveChanges;

  /// Where an exported register goes; the platform's when null (tests
  /// that don't export leave it out).
  final RegisterOutput? registerOutput;
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: tasksRepository),
        RepositoryProvider.value(value: usersRepository),
        RepositoryProvider.value(value: notificationsRepository),
        RepositoryProvider.value(value: contractsRepository),
        RepositoryProvider.value(value: liveChanges),
        RepositoryProvider<RegisterOutput>(create: (_) => registerOutput ?? RegisterOutput()),
      ],
      child: BlocProvider(
        // Eager: start checking the stored session at launch, not on first read.
        lazy: false,
        create: (_) =>
            AuthBloc(authRepository: authRepository)..add(const AuthSubscriptionRequested()),
        // The demo bar's EN / عربي toggle; the product itself is Arabic only.
        child: ValueListenableBuilder<Locale>(
          valueListenable: DemoStore.instance.locale,
          builder: (context, locale, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          locale: locale,
          builder: (context, child) => DemoChrome(child: child!),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(),
          home: BlocBuilder<AuthBloc, AuthState>(
            // A role switch in the demo bar changes the user without signing
            // out, so the shell is rebuilt per user as well as per status.
            buildWhen: (previous, current) =>
                previous.status != current.status || previous.user?.id != current.user?.id,
            builder: (context, state) => switch (state.status) {
              AuthStatus.unknown => const SplashPage(),
              AuthStatus.unauthenticated => const LoginPage(),
              AuthStatus.authenticated => AppShell(key: ValueKey(state.user!.id), clock: clock),
            },
          ),
          ),
        ),
      ),
    );
  }
}
