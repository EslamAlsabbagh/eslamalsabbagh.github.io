import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import '../core/clock.dart';
import '../core/config/app_config.dart';
import '../core/connectivity/server_status_cubit.dart';
import '../core/locale/locale_cubit.dart';
import '../core/locale/locale_store.dart';
import '../core/printer/print_service.dart';
import '../core/printer/printer_client.dart';
import '../core/theme/app_theme.dart';
import '../features/actions_log/data/actions_log_repository.dart';
import '../features/auth/bloc/auth_cubit.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/dashboard/data/dashboard_repository.dart';
import '../features/offline/bloc/offline_sync_cubit.dart';
import '../features/offline/data/offline_repository.dart';
import '../features/offline/data/offline_store.dart';
import '../features/reports/data/reports_repository.dart';
import '../features/sell/data/sell_repository.dart';
import '../features/shift/bloc/shift_cubit.dart';
import '../features/shift/data/shift_repository.dart';
import '../features/shifts/data/shifts_repository.dart';
import '../features/gates/data/gates_repository.dart';
import '../features/ticket_types/data/ticket_types_repository.dart';
import '../features/tickets/data/ticket_repository.dart';
import '../features/settings/data/settings_repository.dart';
import '../features/users/data/users_repository.dart';
import '../l10n/gen/app_localizations.dart';
import 'router.dart';
import '../demo/demo_chrome.dart';

class TurnstileApp extends StatefulWidget {
  const TurnstileApp({
    super.key,
    required this.config,
    required this.authRepository,
    required this.shiftRepository,
    required this.sellRepository,
    required this.ticketRepository,
    required this.dashboardRepository,
    required this.shiftsRepository,
    required this.actionsLogRepository,
    required this.reportsRepository,
    required this.ticketTypesRepository,
    required this.gatesRepository,
    required this.usersRepository,
    required this.settingsRepository,
    required this.offlineRepository,
    required this.offlineStore,
    this.printerClient = const PrinterClient(),
    this.printService,
    this.clock = const Clock(),
    this.localeStore,
    this.initialLocale = LocaleCubit.arabic,
  });

  /// Built in `main.dart` and passed in, so tests can supply their own.
  final AppConfig config;
  final AuthRepository authRepository;
  final ShiftRepository shiftRepository;
  final SellRepository sellRepository;
  final TicketRepository ticketRepository;

  /// The admin dashboard's figures and its Realtime channel (task 4.1).
  final DashboardRepository dashboardRepository;

  /// The Shifts page: reconciliation, approval, refusals (task 4.2).
  final ShiftsRepository shiftsRepository;

  /// The actions log: rows, review, the badge count (task 4.3).
  final ActionsLogRepository actionsLogRepository;

  /// The sales report (task 4.4).
  final ReportsRepository reportsRepository;

  /// Ticket types & prices (task 4.5).
  final TicketTypesRepository ticketTypesRepository;

  /// Gates & controllers, and the test open (task 4.6).
  final GatesRepository gatesRepository;

  /// Users, their logins and passwords (task 4.7).
  final UsersRepository usersRepository;

  /// Settings and counters (task 4.8).
  final SettingsRepository settingsRepository;

  /// Offline selling (ADR-0015): the health check, the pool and the upload,
  /// and the counter's own database.
  final OfflineRepository offlineRepository;
  final OfflineStore offlineStore;
  final PrinterClient printerClient;

  /// Defaults to one on [printerClient] that renders for real; widget tests
  /// pass one with a fake renderer.
  final PrintService? printService;
  final Clock clock;

  /// Last language on this PC; tests may leave it out.
  final LocaleStore? localeStore;
  final Locale initialLocale;

  @override
  State<TurnstileApp> createState() => _TurnstileAppState();
}

class _TurnstileAppState extends State<TurnstileApp> {
  late final PrintService _printService =
      widget.printService ?? PrintService(widget.printerClient);
  late final AuthCubit _auth = AuthCubit(widget.authRepository, store: widget.offlineStore);
  late final ShiftCubit _shift = ShiftCubit(
    widget.shiftRepository,
    counterId: widget.config.counterId,
    store: widget.offlineStore,
  );
  late final ServerStatusCubit _status = ServerStatusCubit(
    ping: (timeout) => widget.offlineRepository.ping(timeout: timeout),
    clock: widget.clock,
  );
  late final OfflineSyncCubit _sync = OfflineSyncCubit(
    store: widget.offlineStore,
    repository: widget.offlineRepository,
    status: _status,
    shift: _shift,
    refreshSession: widget.authRepository.refreshSession,
    clock: widget.clock,
  );
  late final RouterRefresh _refresh = RouterRefresh([_auth.stream, _shift.stream]);
  // Created once: rebuilding it on a language change would reset navigation.
  late final GoRouter _router = buildRouter(auth: _auth, shift: _shift, refresh: _refresh);
  late final StreamSubscription<void> _answers;

  @override
  void initState() {
    super.initState();
    _auth.restore();
    // Started from the copies with the server down: the first answer replaces
    // them (ADR-0026).
    _answers = _status.answers.listen((_) {
      unawaited(_auth.confirm());
      unawaited(_shift.confirm());
    });
    // From the start, so the mode is known before the first sale.
    _status.start();
  }

  @override
  void dispose() {
    unawaited(_answers.cancel());
    _router.dispose();
    _refresh.dispose();
    _sync.close();
    _status.close();
    _shift.close();
    // Only the one this app made: a service passed in belongs to its creator.
    if (widget.printService == null) _printService.dispose();
    _auth.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.config),
        RepositoryProvider.value(value: widget.authRepository),
        RepositoryProvider.value(value: widget.shiftRepository),
        RepositoryProvider.value(value: widget.sellRepository),
        RepositoryProvider.value(value: widget.ticketRepository),
        RepositoryProvider.value(value: widget.dashboardRepository),
        RepositoryProvider.value(value: widget.shiftsRepository),
        RepositoryProvider.value(value: widget.actionsLogRepository),
        RepositoryProvider.value(value: widget.reportsRepository),
        RepositoryProvider.value(value: widget.ticketTypesRepository),
        RepositoryProvider.value(value: widget.gatesRepository),
        RepositoryProvider.value(value: widget.usersRepository),
        RepositoryProvider.value(value: widget.settingsRepository),
        RepositoryProvider.value(value: widget.offlineStore),
        RepositoryProvider.value(value: widget.printerClient),
        RepositoryProvider.value(value: _printService),
        RepositoryProvider.value(value: widget.clock),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _auth),
          BlocProvider.value(value: _shift),
          BlocProvider.value(value: _status),
          BlocProvider.value(value: _sync),
          BlocProvider(
            create: (_) => LocaleCubit(initial: widget.initialLocale, store: widget.localeStore),
          ),
        ],
        child: MultiBlocListener(
          listeners: [
            // On login, the staff member's own language takes over, and their
            // open shift is loaded.
            BlocListener<AuthCubit, AuthState>(
              listenWhen: (previous, current) => previous is! AuthSignedIn && current is AuthSignedIn,
              listener: (context, state) {
                final signedIn = state as AuthSignedIn;
                final locale = LocaleCubit.fromCode(signedIn.staff.language);
                if (locale != null) context.read<LocaleCubit>().setLocale(locale);
                _shift.load(preferCopy: signedIn.fromCopy);
              },
            ),
            BlocListener<AuthCubit, AuthState>(
              listenWhen: (previous, current) => previous is AuthSignedIn && current is! AuthSignedIn,
              listener: (context, state) => _shift.clear(),
            ),
          ],
          child: BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) => MaterialApp.router(
              debugShowCheckedModeBanner: false,
              onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
              // Text direction follows the locale: Arabic RTL, English LTR.
              locale: locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: AppTheme.light(),
              routerConfig: _router,
              builder: (context, child) => DemoChrome(child: child!),
            ),
          ),
        ),
      ),
    );
  }
}
