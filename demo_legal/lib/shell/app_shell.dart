import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/web/register_output.dart';
import '../features/admin/view/users_page.dart';
import '../features/auth/bloc/auth_bloc.dart';
import '../features/contracts/bloc/contract_export_bloc.dart';
import '../features/contracts/bloc/contracts_bloc.dart';
import '../features/contracts/data/contracts_repository.dart';
import '../features/contracts/view/contract_drawer.dart';
import '../features/notifications/bloc/notifications_bloc.dart';
import '../features/notifications/data/notifications_repository.dart';
import '../features/notifications/view/notification_bell.dart';
import '../features/notifications/view/notifications_panel.dart';
import '../features/tasks/bloc/tasks_bloc.dart';
import '../features/tasks/data/live_changes.dart';
import '../features/tasks/data/tasks_repository.dart';
import '../features/tasks/view/new_task_modal.dart';
import '../features/tasks/view/tasks_home.dart';
import 'widgets/app_header.dart';
import 'widgets/content_frame.dart';
import 'widgets/header_counters.dart';

/// Page frame shared by every view: header on top, scrollable content below.
/// Shown only while signed in (see `app.dart`), so the tasks load per sign-in.
class AppShell extends StatelessWidget {
  const AppShell({super.key, this.clock = DateTime.now});

  /// Source of "now" for the header date and update times; injectable for tests.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final displayName =
        context.select((AuthBloc bloc) => bloc.state.profile?.displayName) ?? '';
    final managesUsers = context.select((AuthBloc bloc) => bloc.state.profile?.role.managesUsers ?? false);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TasksBloc(
            tasksRepository: context.read<TasksRepository>(),
            liveChanges: context.read<LiveChanges>().changes,
            clock: clock,
          )..add(const TasksLoadRequested()),
        ),
        BlocProvider(
          create: (context) => NotificationsBloc(
            repository: context.read<NotificationsRepository>(),
            liveChanges: context.read<LiveChanges>().changes,
          )..add(const NotificationsLoadRequested()),
        ),
        // Lazy: made, and loaded, the first time «العقود» opens.
        BlocProvider(
          create: (context) => ContractsBloc(
            repository: context.read<ContractsRepository>(),
            liveChanges: context.read<LiveChanges>().changes,
          )..add(const ContractsLoadRequested()),
        ),
        // «تصدير» on «العقود»; lazy too.
        BlocProvider(
          create: (context) => ContractExportBloc(
            repository: context.read<ContractsRepository>(),
            output: context.read<RegisterOutput>(),
          ),
        ),
      ],
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: BlocBuilder<TasksBloc, TasksState>(
                builder: (context, state) => AppHeader(
                  today: clock(),
                  displayName: displayName,
                  onSignOut: () => context.read<AuthBloc>().add(const AuthSignOutRequested()),
                  // The modals are built from the loaded files, topics and
                  // people. On «العقود» the button opens the contract form
                  // (chosen 2026-11-15), and needs a file to put it in.
                  onNewTask: state.status == TasksStatus.success && state.tab != TasksTab.contracts
                      ? () => openNewTaskModal(context, clock: clock)
                      : null,
                  onNewContract:
                      state.status == TasksStatus.success && state.tab == TasksTab.contracts && state.files.isNotEmpty
                          ? () => openNewContract(context, clock: clock)
                          : null,
                  notifications: BlocSelector<NotificationsBloc, NotificationsState, int>(
                    selector: (state) => state.unreadCount,
                    builder: (context, unread) => NotificationBell(
                      unreadCount: unread,
                      onPressed: (anchor) => openNotificationsPanel(context, anchor: anchor, clock: clock),
                    ),
                  ),
                  // Memberships and names may change there, so the lists
                  // reload quietly on the way back.
                  onOpenUsers: managesUsers
                      ? () async {
                          final tasksBloc = context.read<TasksBloc>();
                          await openUsersPage(context, clock: clock);
                          if (!tasksBloc.isClosed) tasksBloc.add(const TasksRefreshRequested());
                        }
                      : null,
                  // Counters appear with the first list, and follow the file filter.
                  counters: state.tasks.isEmpty && state.status != TasksStatus.success
                      ? null
                      : HeaderCounters(
                          urgent: state.urgentCount,
                          overdue: state.overdueCount,
                          open: state.openCount,
                        ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: ContentFrame(top: 18, bottom: 56, child: TasksHome(clock: clock)),
            ),
          ],
        ),
      ),
    );
  }
}
