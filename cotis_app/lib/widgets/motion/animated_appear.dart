import 'package:flutter/material.dart';

/// Version statique - pas d'animation
class AnimatedAppear extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final bool reduceMotion;

  const AnimatedAppear({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.reduceMotion = false,
  });

  @override
  Widget build(BuildContext context) => child;
}
