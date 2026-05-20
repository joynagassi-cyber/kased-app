import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:kased_app/core/animation_constants.dart';

class SpringNavIcon extends StatefulWidget {
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final String label;

  const SpringNavIcon({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.label,
    this.selectedColor = const Color(0xFF5C35D9),
    this.unselectedColor = const Color(0xFF9E9E9E),
  });

  @override
  State<SpringNavIcon> createState() => _SpringNavIconState();
}

class _SpringNavIconState extends State<SpringNavIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _rotation;
  bool _wasSelected = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppAnimDurations.normal);
    _scale = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _rotation = Tween<double>(begin: 0.0, end: 0.07).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _wasSelected = widget.isSelected;
    if (widget.isSelected) {
      _controller.value = 0.0; // Normal starting scale
    }
  }

  @override
  void didUpdateWidget(SpringNavIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !_wasSelected) {
      HapticFeedback.selectionClick();
      _triggerSpring();
    }
    _wasSelected = widget.isSelected;
  }

  void _triggerSpring() {
    _controller.forward(from: 0.0).then((_) {
      final sim = SpringSimulation(
        AppSprings.navIcon,
        1.0,
        0.0,
        -12.0,
      );
      _controller.animateWith(sim);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isSelected
        ? widget.selectedColor
        : widget.unselectedColor;

    return ScaleTransition(
      scale: _scale,
      child: RotationTransition(
        turns: _rotation,
        child: AnimatedSwitcher(
          duration: AppAnimDurations.fast,
          child: Icon(
            widget.isSelected ? widget.selectedIcon : widget.icon,
            key: ValueKey(widget.isSelected),
            color: color,
            size: 26,
          ),
        ),
      ),
    );
  }
}
