import 'package:flutter/material.dart';

/// Version statique - pas d'animation
/// Le paramètre delay est ignoré pour compatibilité
class AnimatedAppear extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final bool reduceMotion;
  final Duration? delay;

  const AnimatedAppear({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.reduceMotion = false,
    this.delay,
  });

  @override
  Widget build(BuildContext context) => child;
}
