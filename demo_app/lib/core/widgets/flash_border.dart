import 'package:flutter/material.dart';

/// Wraps [child] in a border that flashes from [color] → transparent over
/// [duration] the first time [triggered] flips to true. Replaying (false → true
/// again) restarts the animation from the beginning.
///
/// [delay] pauses before starting the fade-out so the border stays fully
/// visible long enough for the user to notice it.
class FlashBorder extends StatefulWidget {
  final Widget child;
  final bool triggered;
  final Color color;
  final double borderRadius;
  final Duration duration;
  final Duration delay;

  const FlashBorder({
    super.key,
    required this.child,
    required this.triggered,
    this.color = const Color.fromARGB(255, 229, 212, 30),
    this.borderRadius = 10,
    this.duration = const Duration(milliseconds: 1400),
    this.delay = const Duration(seconds: 1),
  });

  @override
  State<FlashBorder> createState() => _FlashBorderState();
}

class _FlashBorderState extends State<FlashBorder> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration, value: 1.0);
    if (widget.triggered) _startWithDelay();
  }

  @override
  void didUpdateWidget(FlashBorder old) {
    super.didUpdateWidget(old);
    if (widget.triggered && !old.triggered) _startWithDelay();
  }

  Future<void> _startWithDelay() async {
    await Future.delayed(widget.delay);
    if (mounted) _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) => IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: widget.color.withValues(alpha: 1.0 - _ctrl.value),
                    width: 2.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
