import 'package:flutter/material.dart';

import 'app.dart';
import 'core/format/app_formats.dart';
import 'core/web/register_output.dart';
import 'demo/demo_seed.dart';
import 'demo/demo_store.dart';
import 'features/admin/data/users_repository.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/contracts/data/contracts_repository.dart';
import 'features/notifications/data/notifications_repository.dart';
import 'features/tasks/data/live_changes.dart';
import 'features/tasks/data/tasks_repository.dart';

/// Demo build: every repository reads and writes the in-memory [DemoStore],
/// so there is no backend to initialise and no network call anywhere.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppFormats.init();

  final store = DemoStore.instance;
  // Deep links from the case study: `?as=lawyer` and `?lang=ar`.
  final params = Uri.base.queryParameters;
  final role = DemoSeed.roleAccounts.where((r) => r.$1.toLowerCase() == params['as']).firstOrNull;
  if (role != null) store.signInAs(role.$2);
  if (params['lang'] == 'ar') store.setLocale(const Locale('ar'));
  runApp(LegalTasksApp(
    authRepository: AuthRepository(store),
    tasksRepository: TasksRepository(store),
    usersRepository: UsersRepository(store),
    notificationsRepository: NotificationsRepository(store),
    contractsRepository: ContractsRepository(store),
    liveChanges: LiveChanges(store),
    registerOutput: RegisterOutput(),
  ));
}
