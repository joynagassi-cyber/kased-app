import 'package:flutter/material.dart';
import '../../core/theme/motion_tokens.dart';

/// Implémentation du pattern appear-fade-slide
/// Opacité 0→1 + glissement vertical 24px→0
class AnimatedAppear extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final bool? reduceMotion;

  const AnimatedAppear({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.reduceMotion,
  });

  @override
  State<AnimatedAppear> createState() => _AnimatedAppearState();
}

class _AnimatedAppearState extends State<AnimatedAppear>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    
    final bool reduce = widget.reduceMotion ?? false;

    _controller = AnimationController(
      vsync: this,
      duration: reduce ? Duration.zero : MotionDuration.standard,
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: MotionCurve.decelerate),
    );

    _offset = Tween<Offset>(
      begin: reduce ? Offset.zero : const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: MotionCurve.decelerate),
    );

    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
