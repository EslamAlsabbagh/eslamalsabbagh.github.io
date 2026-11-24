part of 'notifications_bloc.dart';

enum NotificationsStatus { loading, success, failure }

final class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.loading,
    this.items = const [],
    this.unreadCount = 0,
    this.markingAll = false,
  });

  final NotificationsStatus status;

  /// The newest ones, newest first (see `NotificationsRepository.listLimit`).
  final List<AppNotification> items;

  /// Every unread one the viewer has, listed or not. The bell's badge.
  final int unreadCount;

  /// «تعليم الكل كمقروء» is in flight.
  final bool markingAll;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<AppNotification>? items,
    int? unreadCount,
    bool? markingAll,
  }) =>
      NotificationsState(
        status: status ?? this.status,
        items: items ?? this.items,
        unreadCount: unreadCount ?? this.unreadCount,
        markingAll: markingAll ?? this.markingAll,
      );

  @override
  List<Object?> get props => [status, items, unreadCount, markingAll];
}
