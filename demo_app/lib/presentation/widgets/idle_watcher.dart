import 'dart:async';
import 'package:flutter/material.dart';

class IdleWatcher extends StatefulWidget {
  final Duration timeout;
  final VoidCallback onIdle;
  final Widget child;

  const IdleWatcher({super.key, required this.timeout, required this.onIdle, required this.child});

  @override
  State<IdleWatcher> createState() => _IdleWatcherState();
}

class _IdleWatcherState extends State<IdleWatcher> {
  Timer? _idleTimer;

  void _resetTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(widget.timeout, widget.onIdle);
  }

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerHover: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}
