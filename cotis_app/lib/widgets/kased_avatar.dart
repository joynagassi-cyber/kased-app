import 'package:flutter/material.dart';

class KasedAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const KasedAvatar({
    super.key,
    required this.name,
    this.size = 48.0,
    this.backgroundColor,
    this.textColor,
  });

  String _getInitials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.trim().substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }

  Color _getColorForName(String name) {
    // Generate a consistent color based on the name
    final colors = [
      const Color(0xFF2962FF), // Electric Blue
      const Color(0xFF7C4DFF), // Royal Purple
      const Color(0xFFFF4081), // Pink
      const Color(0xFFFF9100), // Orange
      const Color(0xFF651FFF), // Indigo
      const Color(0xFFD500F9), // Deep Magenta
      const Color(0xFF3D5AFE), // Indigo Accent
      const Color(0xFFFF1744), // Crimson
    ];
    int hash = 0;
    for (var i = 0; i < name.length; i++) {
      hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    }
    return colors[hash.abs() % colors.length]; // Excluding green index if it was there
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? _getColorForName(name).withValues(alpha: 0.15);
    final txtColor = textColor ?? _getColorForName(name);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(name),
          style: TextStyle(
            color: txtColor,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}
