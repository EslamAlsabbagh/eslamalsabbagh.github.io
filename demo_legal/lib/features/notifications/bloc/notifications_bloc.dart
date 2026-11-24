import 'dart:async';
import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../tasks/data/live_changes.dart';
import '../data/app_notification.dart';
import '../data/notifications_repository.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

/// The bell and its panel. Provided by the shell, so it lives only while
/// someone is signed in.
///
/// It follows new notifications live: a `notifications` change or a rejoin
/// heard from [liveChanges] (or a burst of them) reads the list again
/// quietly, like the task lists (ADR-0007).
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({
    required this._repository,
    Stream<LiveChange> liveChanges = const Stream.empty(),
    this._liveDelay = const Duration(milliseconds: 500),
  }) : super(const NotificationsState()) {
    on<NotificationsLoadRequested>(_onLoadRequested);
    on<NotificationsRefreshRequested>(_onRefreshRequested);
    on<NotificationReadRequested>(_onReadRequested);
    on<NotificationsAllReadRequested>(_onAllReadRequested);
    _liveSubscription =
        liveChanges.where((change) => change.resync || change.table == LiveTable.notifications).listen(_onLiveChange);
  }

  final NotificationsRepository _repository;

  /// How long a burst of changes is gathered into one read: one save can
  /// notify a person twice (an assignee change tells the old assignee and
  /// the creator), and «تعليم الكل كمقروء» changes many rows at once.
  final Duration _liveDelay;

  late final StreamSubscription<LiveChange> _liveSubscription;
  Timer? _liveTimer;

  /// Reads are numbered, so an older one that lands after a newer one is
  /// dropped instead of putting stale rows back.
  int _fetchesStarted = 0;
  int _fetchApplied = 0;

  /// Nothing is read before the first load has landed: that load, or its
  /// retry, reads everything anyway.
  void _onLiveChange(LiveChange _) {
    _liveTimer?.cancel();
    _liveTimer = Timer(_liveDelay, () {
      if (!isClosed && state.status == NotificationsStatus.success) add(const NotificationsRefreshRequested());
    });
  }

  @override
  Future<void> close() async {
    _liveTimer?.cancel();
    await _liveSubscription.cancel();
    return super.close();
  }

  Future<void> _onLoadRequested(NotificationsLoadRequested event, Emitter<NotificationsState> emit) async {
    emit(state.copyWith(status: NotificationsStatus.loading));
    try {
      await _fetch(emit);
    } catch (error, stackTrace) {
      log('Loading notifications failed', name: 'notifications', error: error, stackTrace: stackTrace);
      emit(state.copyWith(status: NotificationsStatus.failure));
    }
  }

  /// Keeps the last list on a failure: the next change or rejoin reads again.
  Future<void> _onRefreshRequested(NotificationsRefreshRequested event, Emitter<NotificationsState> emit) async {
    try {
      await _fetch(emit);
    } catch (error, stackTrace) {
      log('Refreshing notifications failed', name: 'notifications', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> _fetch(Emitter<NotificationsState> emit) async {
    final generation = ++_fetchesStarted;
    final (items, unread) = await (_repository.fetchNotifications(), _repository.fetchUnreadCount()).wait;
    if (generation < _fetchApplied) return;
    _fetchApplied = generation;
    emit(state.copyWith(status: NotificationsStatus.success, items: items, unreadCount: unread));
  }

  /// Shown read once the server has it. A failure leaves it unread, so
  /// tapping it again tries again.
  Future<void> _onReadRequested(NotificationReadRequested event, Emitter<NotificationsState> emit) async {
    final item = state.items.where((n) => n.id == event.id).firstOrNull;
    if (item == null || item.isRead) return;
    try {
      await _repository.markRead(event.id);
    } catch (error, stackTrace) {
      log('Marking notification ${event.id} read failed', name: 'notifications', error: error, stackTrace: stackTrace);
      return;
    }
    // Looked up again: a read may have replaced the list meanwhile.
    final wasUnread = state.items.any((n) => n.id == event.id && !n.isRead);
    emit(state.copyWith(
      items: [for (final n in state.items) n.id == event.id ? n.copyWith(isRead: true) : n],
      unreadCount: wasUnread && state.unreadCount > 0 ? state.unreadCount - 1 : null,
    ));
  }

  Future<void> _onAllReadRequested(NotificationsAllReadRequested event, Emitter<NotificationsState> emit) async {
    if (state.markingAll || state.unreadCount == 0) return;
    emit(state.copyWith(markingAll: true));
    try {
      await _repository.markAllRead();
    } catch (error, stackTrace) {
      log('Marking all notifications read failed', name: 'notifications', error: error, stackTrace: stackTrace);
      emit(state.copyWith(markingAll: false));
      return;
    }
    emit(state.copyWith(
      markingAll: false,
      items: [for (final n in state.items) n.isRead ? n : n.copyWith(isRead: true)],
      unreadCount: 0,
    ));
  }
}
