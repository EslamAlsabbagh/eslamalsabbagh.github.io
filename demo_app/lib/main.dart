import 'package:hrms_demo/core/di/app_dependencies.dart';
import 'package:hrms_demo/demo/demo_chrome.dart';
import 'package:hrms_demo/demo/demo_session.dart';
import 'package:hrms_demo/presentation/widgets/logout_action.dart';
import 'package:hrms_demo/core/utils/user_code_utils.dart';
import 'package:hrms_demo/data/repos/advance_on_salary_request/advance_on_salary_request_repo.dart';
import 'package:hrms_demo/data/repos/hr_letter_request/hr_letter_request_repo.dart';
import 'package:hrms_demo/data/repos/auth/auth_repo.dart';
import 'package:hrms_demo/data/repos/businesstrip_request/businesstrip_request_repo.dart';
import 'package:hrms_demo/data/repos/disciplinary_action_request/disciplinary_action_request_repo.dart';
import 'package:hrms_demo/data/repos/investigation_request/investigation_request_repo.dart';
import 'package:hrms_demo/data/repos/leave_request/leave_request_repo.dart';
import 'package:hrms_demo/data/repos/missingpunching_request/missingpunching_request_repo.dart';
import 'package:hrms_demo/data/repos/overtime_request/overtime_request_repo.dart';
import 'package:hrms_demo/data/repos/storage/storage_keys.dart';
import 'package:hrms_demo/data/repos/storage/storage_repo.dart';
import 'package:hrms_demo/data/repos/users/users_repo.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/l10n/locale_cubit.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_event.dart';
import 'package:hrms_demo/presentation/auth_gate.dart';
import 'package:hrms_demo/presentation/employees/bloc/employees_bloc.dart';
import 'package:hrms_demo/presentation/widgets/idle_watcher.dart';
import 'package:hrms_demo/presentation/widgets/sidebar_cubit.dart';
import 'package:hrms_demo/presentation/widgets/sidebar_navigation_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  // Initialize timezone database
  tz.initializeTimeZones();

  WidgetsFlutterBinding.ensureInitialized();

  // Safety net for a Flutter framework race condition where a Tooltip's hide
  // animation fires after its OverlayEntry has been removed (_zOrderIndex == null).
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    final msg = details.exceptionAsString();
    if (msg.contains('_zOrderIndex') && msg.contains('is not true')) {
      debugPrint('[SafeTooltip] suppressed overlay assertion: $msg');
      return;
    }
    originalOnError?.call(details);
  };

  // The demo graph is entirely in-memory, so there is no backend to initialise
  // and nothing to validate — building it reaches no network.
  runApp(MyApp(deps: AppDependencies.demo()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, required this.deps});

  /// The application's dependency graph. Injected rather than reached for, so
  /// tests can pump `MyApp` with fakes instead of needing a live Supabase.
  final AppDependencies deps;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    // Read straight off the graph rather than through context: initState runs
    // above the MultiRepositoryProvider this widget itself builds.
    final storage = widget.deps.storageRepo;
    storage.read(StorageKeys.language.key).then((value) {
      if (value == null) {
        storage.write(StorageKeys.language.key, "en");
      }
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: widget.deps.providers,
      child: _buildApp(context),
    );
  }

  Widget _buildApp(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => SidebarCubit()),
        BlocProvider(create: (context) => SidebarNavigationCubit()),
        BlocProvider(
          create: (context) => UserBloc(
            context.read<UsersRepo>(),
            context.read<AdvanceOnSalaryRequestsRepo>(),
            context.read<DisciplinaryActionRequestRepo>(),
            context.read<HrLetterRequestRepo>(),
            context.read<LeaveRequestsRepo>(),
            context.read<OvertimeRequestRepo>(),
            context.read<MissingpunchingRequestsRepo>(),
            context.read<BusinesstripRequestsRepo>(),
          ),
        ),
        BlocProvider(create: (context) => LocaleCubit(context.read<StorageRepo>())),
        BlocProvider(
          create:
              (context) => EmployeesBloc(
                businessTripRequestRepository: context.read<BusinesstripRequestsRepo>(),
                leaveRequestRepository: context.read<LeaveRequestsRepo>(),
                missingPunchingRequestRepository: context.read<MissingpunchingRequestsRepo>(),
                overtimeRequestRepository: context.read<OvertimeRequestRepo>(),
                advanceOnSalaryRequestRepository: context.read<AdvanceOnSalaryRequestsRepo>(),
                hrLetterRequestRepository: context.read<HrLetterRequestRepo>(),
                disciplinaryActionRequestRepository: context.read<DisciplinaryActionRequestRepo>(),
                investigationRequestRepository: context.read<InvestigationRequestRepo>(),
                employeeRepository: context.read<UsersRepo>(),
                authRepo: context.read<AuthRepo>(),
              ),
        ),
      ],
      // Refresh the loaded profile ONLY when the display locale actually
      // changes — not on every rebuild (which previously double-fired the
      // dashboard's heavy query set). The initial profile load is owned solely
      // by AuthGate, so there is no startup race here.
      child: BlocListener<LocaleCubit, Locale>(
        listenWhen: (previous, current) => previous.languageCode != current.languageCode,
        listener: (context, locale) {
          final code = extractUserCodeFromEmail(context.read<DemoSession>().email);
          if (code != null) {
            context.read<UserBloc>().add(RefreshUserProfileForLocale(code, locale.languageCode));
          }
        },
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return IdleWatcher(
              timeout: const Duration(minutes: 10),
              onIdle: () {
                // Use centralized AuthService with navigatorKey fallback
                logoutAndSurfaceLogin(null, navigatorKey: navigatorKey);
              },
              child: MaterialApp(
                builder: (context, child) {
                  return DemoChrome(child: child!);
                },
                navigatorKey: navigatorKey,
                navigatorObservers: [widget.deps.routeObserver],
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                locale: locale,
                supportedLocales: AppLocalizations.supportedLocales,
                debugShowCheckedModeBanner: false,
                theme: ThemeData(
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    iconTheme: IconThemeData(color: Colors.white),
                  ),
                  primaryColor: Colors.blueAccent,
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                ),
                home: const AuthGate(),
              ),
            );
          },
        ),
      ),
    );
  }
}
