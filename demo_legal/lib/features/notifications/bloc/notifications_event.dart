part of 'notifications_bloc.dart';

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

/// The shell opened, or «إعادة المحاولة» after a failed load.
final class NotificationsLoadRequested extends NotificationsEvent {
  const NotificationsLoadRequested();
}

/// A live change: read again without a spinner.
final class NotificationsRefreshRequested extends NotificationsEvent {
  const NotificationsRefreshRequested();
}

/// A row was tapped.
final class NotificationReadRequested extends NotificationsEvent {
  const NotificationReadRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// «تعليم الكل كمقروء».
final class NotificationsAllReadRequested extends NotificationsEvent {
  const NotificationsAllReadRequested();
}
