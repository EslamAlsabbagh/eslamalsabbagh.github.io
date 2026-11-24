import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../clock.dart';

/// Whether this counter reaches the server (ADR-0015). [unknown] only until
/// the first check.
enum ServerStatus { unknown, online, offline }

/// The health check: online while the server answers, offline after
/// `offline_health_check_seconds` without an answer. The app sells print
/// first while online and charge first while offline.
///
/// Checks every [seconds] while the server answers. After a failed check it
/// checks again every 2 s, so a short blip doesn't switch modes but a dead
/// link is noticed soon, and a server back up is too.
class ServerStatusCubit extends Cubit<ServerStatus> {
  ServerStatusCubit({
    required this._ping,
    this._clock = const Clock(),
    this._seconds = 10,
    this._timer = Timer.new,
  }) : super(ServerStatus.unknown);

  final Future<bool> Function(Duration timeout) _ping;
  final Clock _clock;
  int _seconds;

  /// Makes the next check's timer; tests pass one they fire by hand.
  final Timer Function(Duration delay, void Function() callback) _timer;

  DateTime? _lastAnswer;
  Timer? _next;
  bool _running = false;
  bool _checking = false;
  final _answers = StreamController<void>.broadcast();

  /// Fires on every check the server answered: the upload and the pool
  /// top-up run on it (`OfflineSyncCubit`).
  Stream<void> get answers => _answers.stream;

  bool get isOffline => state == ServerStatus.offline;

  /// Starts checking. Safe to call again.
  void start() {
    if (_running || isClosed) return;
    _running = true;
    unawaited(check());
  }

  void stop() {
    _running = false;
    _next?.cancel();
    _next = null;
  }

  /// `offline_health_check_seconds`, once the settings are read.
  void configure(int seconds) {
    if (seconds <= 0 || seconds == _seconds) return;
    _seconds = seconds;
    if (_running && !_checking) _schedule();
  }

  /// A call in the sell flow found the server out of reach: check now
  /// rather than at the next tick.
  void reportUnreachable() {
    if (_running && !_checking) unawaited(check());
  }

  Future<void> check() async {
    if (_checking || isClosed) return;
    _checking = true;
    _next?.cancel();
    final bool answered;
    try {
      answered = await _ping(Duration(seconds: _seconds));
    } finally {
      _checking = false;
    }
    if (isClosed) return;
    final now = _clock.now();
    if (answered) {
      _lastAnswer = now;
      emit(ServerStatus.online);
      _answers.add(null);
    } else {
      final last = _lastAnswer;
      if (state != ServerStatus.online ||
          last == null ||
          now.difference(last) >= Duration(seconds: _seconds)) {
        emit(ServerStatus.offline);
      }
    }
    if (_running) _schedule(retry: !answered);
  }

  void _schedule({bool retry = false}) {
    _next?.cancel();
    final delay = retry || state != ServerStatus.online
        ? Duration(seconds: math.min(2, _seconds))
        : Duration(seconds: _seconds);
    _next = _timer(delay, () => unawaited(check()));
  }

  @override
  Future<void> close() async {
    stop();
    await _answers.close();
    return super.close();
  }
}
