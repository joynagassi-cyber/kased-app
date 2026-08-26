import 'package:flutter/material.dart';
import 'package:kased_app/core/services/stats_service.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/widgets/kased_card.dart';

class ProgressSectionWidget extends StatelessWidget {
  final DashboardStats stats;
  final double objectifMensuel;
  final VoidCallback onSetObjectif;

  const ProgressSectionWidget({
    super.key,
    required this.stats,
    required this.objectifMensuel,
    required this.onSetObjectif,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalExpected = stats.totalCollecte + stats.totalDu;
    final percentage = totalExpected > 0
        ? (stats.totalCollecte / totalExpected * 100).clamp(0.0, 100.0)
        : 0.0;
    final objectifPct = objectifMensuel > 0
        ? (stats.totalCollecte / objectifMensuel * 100).clamp(0.0, 100.0)
        : null;
    final trend = stats.collecteMoisPrecedent > 0
        ? ((stats.totalCollecte - stats.collecteMoisPrecedent) /
                stats.collecteMoisPrecedent *
                100)
            .round()
        : null;

    return KasedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progression du mois',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              if (objectifMensuel > 0)
                InkWell(
                  onTap: onSetObjectif,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.flag, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Modifier',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (objectifMensuel == 0)
                TextButton.icon(
                  onPressed: onSetObjectif,
                  icon: const Icon(Icons.flag, size: 14),
                  label: const Text('Définir objectif', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de progression
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 10,
              backgroundColor: isDark
                  ? AppColors.surface2Dark
                  : AppColors.surface2,
              valueColor: AlwaysStoppedAnimation(
                AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Ligne de valeurs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stats.totalCollecte.toInt()} F collecté',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                  if (trend != null)
                    Text(
                      trend > 0
                          ? '▲ +$trend% vs mois dernier'
                          : trend < 0
                              ? '▼ $trend% vs mois dernier'
                              : '— stable',
                      style: TextStyle(
                        fontSize: 11,
                        color: trend > 0
                            ? AppColors.success
                            : trend < 0
                                ? AppColors.danger
                                : isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                        fontWeight: trend != 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${totalExpected.toInt()} F attendu',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Objectif mensuel
          if (objectifMensuel > 0) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.emoji_events, size: 16, color: AppColors.warning),
                const SizedBox(width: 8),
                Text(
                  'Objectif : ${objectifMensuel.toInt()} F',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${objectifPct!.toStringAsFixed(0)}% atteint',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
