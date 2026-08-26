class _CadenceCard extends StatelessWidget {
  final double percentage;
  final int paid;
  final int total;
  final bool isDark;

  const _CadenceCard({
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
          // Circular progress indicator
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
                    color:
                        colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
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

