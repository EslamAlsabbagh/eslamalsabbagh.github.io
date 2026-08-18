import 'package:hrms_demo/core/constants/status.dart';
import 'package:hrms_demo/presentation/widgets/logout_action.dart';
import 'package:hrms_demo/l10n/app_localizations.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_bloc.dart';
import 'package:hrms_demo/presentation/employee_schedule/bloc/schedule_state.dart';
import 'package:hrms_demo/presentation/widgets/collapsible_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String? title;
  final AppBar? appBar;
  final List<Widget>? extraActions;
  // Optional keys passed down so only the calling page "owns" them.
  // Using parameters instead of static GlobalKeys prevents duplication
  // when two routes are alive on the navigator stack simultaneously.
  final Key? appBarKey;
  final Key? sidebarStripKey;

  const MainLayout({
    super.key,
    required this.child,
    this.title,
    this.appBar,
    this.extraActions,
    this.appBarKey,
    this.sidebarStripKey,
  });

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserBloc>().state;
    final userName =
        userState.status == Status.success && userState.user != null
            ? (Localizations.localeOf(context).languageCode == 'ar'
                ? userState.user!.arabicName ?? "User"
                : userState.user!.englishName ?? "User")
            : "User";

    return Scaffold(
      appBar:
          appBar ??
          AppBar(
            key: appBarKey,
            title: Text(title ?? "CM System", style: const TextStyle(color: Colors.white)),
            backgroundColor: Colors.blue,
            actions: [
              Text(userName.length > 15 ? "${userName.substring(0, 15)}..." : userName),
              if (extraActions != null) ...extraActions!,
              IconButton(
                onPressed: () {
                  try {
                    final bloc = context.read<ScheduleBloc>();
                    if (bloc.state.publishState == PublishState.publishing) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.schedulePublishingPleaseWait),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      return;
                    }
                  } catch (_) {
                    // Not inside a ScheduleBloc context — proceed normally
                  }
                  logoutAndSurfaceLogin(context);
                },
                icon: const Icon(Icons.logout),
                color: Colors.white,
              ),
            ],
          ),
      body: Stack(
        children: [
          // Main content is inset by the collapsed-rail width; the expanded
          // sidebar overlays it (so the chart doesn't shift), and hovering the
          // chart collapses the sidebar via the iframe signal.
          Padding(
            padding:
                Localizations.localeOf(context).languageCode == 'ar'
                    ? const EdgeInsets.only(right: 65)
                    : const EdgeInsets.only(left: 65),
            child: child,
          ),
          // Sidebar overlays on top
          CollapsibleSidebar(title: title, sidebarStripKey: sidebarStripKey),
        ],
      ),
    );
  }
}
