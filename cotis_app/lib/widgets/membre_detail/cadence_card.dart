import 'package:flutter/material.dart';

/// Carte de cadence de paiement pour un membre.
///
/// Affiche un indicateur circulaire de progression avec le pourcentage
/// de cultes payés sur le total.
class CadenceCard extends StatelessWidget {
  final double percentage;
  final int paid;
  final int total;
  final bool isDark;

  const CadenceCard({
    super.key,
    required this.percentage,
    required this.paid,
    required this.total,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CustomPaint(
              painter: _ProgressPainter(percentage, colorScheme),
              child: Center(
                child: Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cadence',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$paid / $total cultes',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: total > 0 ? percentage / 100 : 0,
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: colorScheme
                      .onPrimaryContainer
                      .withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Peintre personnalisé pour l'indicateur circulaire de progression.
class _ProgressPainter extends CustomPainter {
  final double percentage;
  final ColorScheme colorScheme;

  _ProgressPainter(this.percentage, this.colorScheme);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = colorScheme.onPrimaryContainer.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

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
