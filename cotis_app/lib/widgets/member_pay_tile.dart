import 'package:flutter/material.dart';
import 'package:kased_app/models/membre.dart';
import 'package:kased_app/models/cotisation.dart';
import 'package:kased_app/core/theme/app_theme.dart';
import 'package:kased_app/widgets/kased_avatar.dart';

class MemberPayTile extends StatelessWidget {
  final Membre membre;
  final StatutCotisation statut;
  final VoidCallback onToggle;
  final VoidCallback onMarkAbsent;
  final bool isLocked;

  const MemberPayTile({
    super.key,
    required this.membre,
    required this.statut,
    required this.onToggle,
    required this.onMarkAbsent,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark ? AppColors.surfaceDark : AppColors.surface;
    final cardBorderColor = isDark ? AppColors.borderDark : AppColors.border;

    // Déterminer la couleur et le texte selon le statut
    final (Color statusColor, String statusText, IconData statusIcon) = _getStatusInfo();

    final isPaymentLocked = isLocked && statut == StatutCotisation.paye;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorderColor),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: isPaymentLocked ? Colors.grey : statusColor,
              width: statut == StatutCotisation.paye ? 8.0 : 6.0,
            ),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: KasedAvatar(
            name: membre.nomComplet,
            size: 40,
          ),
          title: Text(
            membre.nomComplet,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          subtitle: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, -0.2),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              isPaymentLocked ? 'Payé - Verrouillé' : statusText,
              key: ValueKey(isPaymentLocked ? 'locked' : statusText),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isPaymentLocked ? Colors.grey : statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isPaymentLocked && statut != StatutCotisation.absent)
                IconButton(
                  onPressed: onMarkAbsent,
                  icon: const Icon(Icons.person_off),
                  tooltip: 'Marquer absent',
                  color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                ),
              if (isPaymentLocked)
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Icon(Icons.lock_outline, color: Colors.grey),
                )
              else
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: CurvedAnimation(
                        parent: animation,
                        curve: Curves.elasticOut,
                      ),
                      child: RotationTransition(
                        turns: Tween<double>(begin: 0.0, end: 0.05).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.elasticOut,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: IconButton(
                    key: ValueKey(statut),
                    onPressed: onToggle,
                    icon: Icon(statusIcon),
                    color: statusColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  (Color, String, IconData) _getStatusInfo() {
    switch (statut) {
      case StatutCotisation.paye:
        return (AppColors.success, 'Payé - À jour', Icons.check_circle);
      case StatutCotisation.nonPaye:
        return (AppColors.warning, 'Non payé - En attente', Icons.circle_outlined);
      case StatutCotisation.absent:
        return (Colors.grey, 'Absent', Icons.person_off);
      case StatutCotisation.enAvance:
        return (Colors.blue, 'En avance', Icons.flash_on);
    }
  }
}

