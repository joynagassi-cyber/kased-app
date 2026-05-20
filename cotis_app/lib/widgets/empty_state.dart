import 'package:flutter/material.dart';
import 'package:kased_app/core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String? sousTitre;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.titre,
    this.sousTitre,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedIconColor = iconColor ?? AppColors.textTertiary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderStrong),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A1246C8),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(resolvedIconColor.withValues(alpha: 0.10), AppColors.surface),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 44, color: resolvedIconColor),
              ),
              const SizedBox(height: 20),
              Text(
                titre,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              if (sousTitre != null) ...[
                const SizedBox(height: 10),
                Text(
                  sousTitre!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

