import 'package:flutter/material.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/widgets/kased_card.dart';

class ActionButtonWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const ActionButtonWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isPrimary) {
      return SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.gradientStart.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: KasedCard(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, color: colorScheme.onSurfaceVariant, size: 14),
          ],
        ),
      ),
    );
  }
}
