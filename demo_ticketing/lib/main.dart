import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/locale/locale_cubit.dart';
import 'core/locale/locale_store.dart';
import 'demo/backend.dart';
import 'features/actions_log/data/actions_log_repository.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/dashboard/data/dashboard_repository.dart';
import 'features/gates/data/gates_repository.dart';
import 'features/offline/data/offline_repository.dart';
import 'features/offline/data/offline_store.dart';
import 'features/reports/data/reports_repository.dart';
import 'features/sell/data/sell_repository.dart';
import 'features/settings/data/settings_repository.dart';
import 'features/shift/data/shift_repository.dart';
import 'features/shifts/data/shifts_repository.dart';
import 'features/ticket_types/data/ticket_types_repository.dart';
import 'features/tickets/data/ticket_repository.dart';
import 'features/users/data/users_repository.dart';

/// Demo build: every repository is handed the in-memory [DemoBackend] in place
/// of the database client, so there is no server to reach and no network
/// call anywhere. The counter's own store lives in memory too.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final backend = DemoBackend.instance;

  // Deep links from the case study: `?as=cashier|supervisor|admin`, `?lang=ar`.
  final params = Uri.base.queryParameters;
  final account = demoAccounts.where((a) => a.$1.toLowerCase() == params['as']).firstOrNull;
  if (account != null) {
    await backend.signIn('${account.$2}@staff.local', DemoBackend.password);
    if (params['lang'] == 'ar') backend.staff.firstWhere((s) => s.username == account.$2).language = 'ar';
  }

  runApp(TurnstileApp(
    config: const AppConfig(env: AppEnv.prod, counterId: demoCounterId),
    authRepository: AuthRepository(backend),
    shiftRepository: ShiftRepository(backend),
    sellRepository: SellRepository(backend),
    ticketRepository: TicketRepository(backend),
    dashboardRepository: DashboardRepository(backend),
    shiftsRepository: ShiftsRepository(backend),
    actionsLogRepository: ActionsLogRepository(backend),
    reportsRepository: ReportsRepository(backend),
    ticketTypesRepository: TicketTypesRepository(backend),
    gatesRepository: GatesRepository(backend),
    usersRepository: UsersRepository(backend),
    settingsRepository: SettingsRepository(backend),
    offlineRepository: OfflineRepository(backend),
    offlineStore: OfflineStore.inMemory(),
    localeStore: LocaleStore(prefs),
    initialLocale: LocaleCubit.english,
  ));
}
