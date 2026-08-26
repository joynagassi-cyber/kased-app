import 'package:flutter/material.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/widgets/kased_card.dart';

class RetardsSectionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> topRetards;
  final int totalRetards;

  const RetardsSectionWidget({
    super.key,
    required this.topRetards,
    required this.totalRetards,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (topRetards.isEmpty && totalRetards == 0) return const SizedBox.shrink();

    return KasedCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Membres en retard',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (totalRetards > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalRetards',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (topRetards.isEmpty && totalRetards == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'Aucun membre en retard — tout est à jour !',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                ),
              ),
            ),
          ...topRetards.map((r) => RetardRowWidget(
                membre: r,
                isDark: isDark,
              )),
          if (topRetards.isNotEmpty && totalRetards > topRetards.length)
            TextButton(
              onPressed: () {},
              child: Text(
                'Voir les ${totalRetards - topRetards.length} autre(s)',
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class RetardRowWidget extends StatelessWidget {
  final Map<String, dynamic> membre;
  final bool isDark;

  const RetardRowWidget({super.key, required this.membre, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final nom = '${membre['prenom']} ${membre['nom']}';
    final montant = (membre['montant_du_fcfa'] as num?)?.toInt() ?? 0;
    final cultes = (membre['cultes_en_retard'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                nom.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warning,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Nom
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$cultes culte(s) en retard',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Montant
          Text(
            '${montant} F',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}
