import 'package:flutter/material.dart';

/// Wrapper qui expose la préférence de mouvement réduit
class MotionAware extends StatelessWidget {
  final Widget Function(BuildContext context, bool reduceMotion) builder;

  const MotionAware({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return builder(context, reduceMotion);
  }
}

/// Extension utilitaire sur Duration
extension MotionDurationExtension on Duration {
  /// Retourne Duration.zero si reduceMotion est actif
  Duration reduced(bool reduceMotion) =>
      reduceMotion ? Duration.zero : this;
}
