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
      child: ScaleTransition(
        scale: _scale,
        // Le child ne doit JAMAIS recevoir les taps lui-même : s'il contient
        // un bouton activé (onPressed non null), son InkWell gagne la gesture
        // arena de Flutter et bloque le onTap de SpringButton — les boutons
        // apparaissent alors "bloqués". IgnorePointer rend le contenu
        // transparent au hit-test : c'est le GestureDetector de SpringButton
        // qui reçoit tous les taps (comportement opaque ci-dessus).
        child: IgnorePointer(
          ignoring: true,
          child: widget.child,
        ),
      ),
    );
  }
}
