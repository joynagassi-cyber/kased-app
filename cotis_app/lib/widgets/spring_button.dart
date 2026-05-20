import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:kased_app/core/animation_constants.dart';

class SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableHaptic;

  const SpringButton({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.enableHaptic = true,
  });

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _scale = _controller.drive(
      Tween<double>(begin: 1.0, end: 0.93),
    );
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    _controller.animateTo(
      1.0,
      duration: AppAnimDurations.fast,
      curve: Curves.easeOut,
    );
  }

  void _onTapUp(TapUpDetails _) {
    _springBack();
    widget.onTap?.call();
  }

  void _onTapCancel() => _springBack();

  void _springBack() {
    final simulation = SpringSimulation(
      AppSprings.button,
      _controller.value,
      0.0,
      -8.0,
    );
    _controller.animateWith(simulation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: IgnorePointer(
          ignoring: widget.onTap != null || widget.onLongPress != null,
          child: widget.child,
        ),
      ),
    );
  }
}
