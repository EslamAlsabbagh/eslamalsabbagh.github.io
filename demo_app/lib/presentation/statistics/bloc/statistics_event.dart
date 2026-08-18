import 'package:hrms_demo/data/repos/statistics/statistics_repo.dart';
import 'package:hrms_demo/presentation/statistics/bloc/statistics_state.dart';

abstract class StatisticsEvent {}

/// Load a perspective's data if it isn't already loaded/loading for the current
/// filter. Fired when a tab first becomes visible (lazy loading).
class StatsPerspectiveOpened extends StatisticsEvent {
  final StatsPerspective perspective;
  StatsPerspectiveOpened(this.perspective);
}

/// The filter bar changed. Invalidates every cached perspective and reloads the
/// one currently on screen.
class StatsFilterChanged extends StatisticsEvent {
  final StatsFilter filter;
  final StatsPerspective active;
  StatsFilterChanged(this.filter, this.active);
}

/// Force a refresh of one perspective (pull-to-refresh / retry after error).
class StatsPerspectiveRefreshed extends StatisticsEvent {
  final StatsPerspective perspective;
  StatsPerspectiveRefreshed(this.perspective);
}
