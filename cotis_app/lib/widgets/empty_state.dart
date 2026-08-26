import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kased_app/core/theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String titre;
  final String? sousTitre;
  final Color? iconColor;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.titre,
    this.sousTitre,
    this.iconColor,
    this.action,
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
            boxShadow: [
              BoxShadow(
                color: const Color(0x0A1246C8),
                blurRadius: 24,
                offset: const Offset(0, 10),
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
              ).animate(
                onPlay: (controller) => controller.repeat(),
              ).shake(
                duration: 600.ms,
                curve: Curves.easeOutQuad,
                hz: 1,
              ).then().scale(
                duration: 400.ms,
                curve: Curves.easeOutCubic,
              ),
              const SizedBox(height: 20),
              Text(
                titre,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 400.ms).slideY(
                begin: 0.1,
                end: 0,
                duration: 400.ms,
                curve: Curves.easeOutCubic,
              ),
              if (sousTitre != null) ...[
                const SizedBox(height: 10),
                Text(
                  sousTitre!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ).animate(
                  delay: 200.ms,
                ).fadeIn(duration: 400.ms).slideY(
                  begin: 0.1,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 24),
                action!,
              ],
            ],
          ),
        ).animate(
          delay: 100.ms,
        ).fadeIn(duration: 500.ms).scale(
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }
}
