import 'package:flutter/material.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/widgets/kased_card.dart';
import 'package:kased_app/models/culte.dart';

class CultesSectionWidget extends StatelessWidget {
  final List<Culte> cultes;

  const CultesSectionWidget({super.key, required this.cultes});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final future = cultes
        .where((c) => !c.isDeleted && c.dateCulte.isAfter(now))
        .take(3)
        .toList();
    if (future.isEmpty) return const SizedBox.shrink();

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
                Text(
                  'Prochains cultes',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                TextButton(
                  onPressed: () => {},
                  child: const Text('Tout voir', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          ...future.map((c) => CulteRowWidget(culte: c, isDark: isDark)),
        ],
      ),
    );
  }
}

class CulteRowWidget extends StatelessWidget {
  final Culte culte;
  final bool isDark;

  const CulteRowWidget({super.key, required this.culte, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = culte.dateCulte.year == now.year &&
        culte.dateCulte.month == now.month &&
        culte.dateCulte.day == now.day;
    final isTomorrow = culte.dateCulte.difference(now).inDays == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Date badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isToday
                  ? AppColors.success
                  : isTomorrow
                      ? AppColors.primary
                      : (isDark ? AppColors.surface2Dark : AppColors.background),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${culte.dateCulte.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isToday || isTomorrow
                        ? Colors.white
                        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                  ),
                ),
                Text(
                  culte.dateCulte.month.toString(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isToday || isTomorrow
                        ? Colors.white.withValues(alpha: 0.8)
                        : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Titre + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  culte.titre ?? 'Culte du ${culte.dateCulte.day}/${culte.dateCulte.month}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                Text(
                  culte.dateFormatee,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          // Montant
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surface2Dark : AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${culte.montantCotisation.toStringAsFixed(0)} F',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Badges
          if (isToday)
            const Chip(
              label: Text('Aujourd\'hui', style: TextStyle(fontSize: 10)),
              backgroundColor: AppColors.success,
              labelStyle: TextStyle(color: Colors.white, fontSize: 10),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
          if (isTomorrow)
            const Chip(
              label: Text('Demain', style: TextStyle(fontSize: 10)),
              backgroundColor: AppColors.primary,
              labelStyle: TextStyle(color: Colors.white, fontSize: 10),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            ),
        ],
      ),
    );
  }
}
