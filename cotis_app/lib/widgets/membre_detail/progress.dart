import 'package:flutter/material.dart';
class _ProgressPainter extends CustomPainter {
  final double percentage;
  final ColorScheme colorScheme;

  _ProgressPainter(this.percentage, this.colorScheme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    // Background arc
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = colorScheme.onPrimaryContainer.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Progress arc
    if (percentage > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -90 * (3.14159265 / 180),
        (percentage / 100) * 2 * 3.14159265,
        false,
        Paint()
          ..color = colorScheme.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressPainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}
