import 'package:flutter/material.dart';
import '../../core/theme/motion_tokens.dart';

/// Implémentation du pattern press-shrink
/// Scale 1.0 → 0.97 au tap, retour à 1.0 au relâchement
class AnimatedPress extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const AnimatedPress({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<AnimatedPress> createState() => _AnimatedPressState();
}

class _AnimatedPressState extends State<AnimatedPress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionDuration.instant,
      reverseDuration: MotionDuration.short,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: MotionScale.press,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: MotionCurve.accelerate,
      reverseCurve: MotionCurve.decelerate,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!reduceMotion) _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
