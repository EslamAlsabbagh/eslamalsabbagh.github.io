import 'package:flutter/material.dart';

class LoadingLogo extends StatefulWidget {
  final double size;
  const LoadingLogo({super.key, this.size = 80});

  @override
  State<LoadingLogo> createState() => _LoadingLogoState();
}

class _LoadingLogoState extends State<LoadingLogo> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: -1.0).animate(_controller),
      child: Image.asset('assets/logo-circle.png', width: widget.size, height: widget.size),
    );
  }
}
