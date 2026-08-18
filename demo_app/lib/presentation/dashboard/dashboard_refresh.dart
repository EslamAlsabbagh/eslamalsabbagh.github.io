import 'package:hrms_demo/presentation/dashboard/bloc/my_requests_summary_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/my_requests_summary_event.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/pending_requests_summary_bloc.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/pending_requests_summary_event.dart';
import 'package:hrms_demo/presentation/dashboard/bloc/user_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Re-fetches the dashboard's summary blocs (Pending approvals + My
/// in-process/recently-processed) for the currently loaded user.
///
/// Shared by the two places that should refresh on returning Home:
/// `_DashboardContent.didPopNext` (returned from another page) and the sidebar
/// Home item when already on the dashboard (where `popUntil` is a no-op and
/// `didPopNext` doesn't fire). Summaries-only by design — the heavy `UserBloc`
/// profile/availability load is intentionally not re-run here.
///
/// Must be called from a context below `DashboardPage`'s providers (i.e. while
/// the dashboard is the visible route); otherwise the summary blocs are out of
/// scope.
void refreshDashboardSummaries(BuildContext context) {
  final user = context.read<UserBloc>().state.user;
  final userId = user?.id ?? 0;
  if (userId == 0) return;
  context.read<PendingRequestsSummaryBloc>().add(LoadPendingRequestsSummary(userId, userGroups: user!.groups));
  context.read<MyRequestsSummaryBloc>().add(LoadMyRequestsSummary(userId));
}
