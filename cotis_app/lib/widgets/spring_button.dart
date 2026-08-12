import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class _SpringButtonState extends State<SpringButton> {
  bool _isPressed = false;

  void _onTapDown(_) {
    if (widget.enableHaptic) {
      HapticFeedback.lightImpact();
    }
    setState(() => _isPressed = true);
  }

  void _onTapUp(_) {
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _onTapCancel() => setState(() => _isPressed = false);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null ? _onTapDown : null,
      onTapUp: widget.onTap != null ? _onTapUp : null,
      onTapCancel: widget.onTap != null ? _onTapCancel : null,
      onLongPress: widget.onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: _isPressed ? Colors.black.withAlpha(15) : Colors.transparent,
        child: IgnorePointer(
          ignoring: true,
          child: widget.child,
        ),
      ),
    );
  }
}
