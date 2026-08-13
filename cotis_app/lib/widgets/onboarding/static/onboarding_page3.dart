import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kased_app/core/theme/app_theme.dart';

/// Page 3: Transparence totale
/// Illustration vectorielle statique style Google - bouclier de confiance
class OnboardingPage3 extends StatelessWidget {
  const OnboardingPage3({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return SizedBox(
      width: 320,
      height: 300,
      child: Stack(
        children: [
          // Background glow
          Positioned(
            top: 50,
            left: 60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.success.withValues(alpha: isDark ? 0.08 : 0.06),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Shield illustration
                SizedBox(
                  width: 140,
                  height: 160,
                  child: Stack(
                    children: [
                      // Shield background
                      Positioned(
                        top: 0,
                        left: 20,
                        child: Container(
                          width: 100,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.success,
                                const Color(0xFF059669),
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(50),
                              top: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.success.withValues(alpha: 0.4),
                                blurRadius: 24,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Checkmark
                      const Positioned(
                        top: 35,
                        left: 35,
                        child: Icon(
                          Icons.check_rounded,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                      // People silhouettes around shield
                      _Person(offset: const Offset(-35, 60), color: AppColors.primary),
                      _Person(offset: const Offset(75, 60), color: const Color(0xFF7C4DFF)),
                      _Person(offset: const Offset(0, 90), color: AppColors.warning),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Trust badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Badge(icon: Icons.security, label: 'Sécurisé'),
                    const SizedBox(width: 12),
                    _Badge(icon: Icons.visibility, label: 'Transparent'),
                    const SizedBox(width: 12),
                    _Badge(icon: Icons.groups, label: 'Communauté'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  
  const _Badge({required this.icon, required this.label});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _Person extends StatelessWidget {
  final Offset offset;
  final Color color;
  
  const _Person({required this.offset, required this.color});
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Column(
        children: [
          // Head
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Body
          Container(
            width: 32,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}
